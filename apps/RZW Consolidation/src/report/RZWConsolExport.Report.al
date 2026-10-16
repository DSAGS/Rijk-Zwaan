namespace dsa.rzw.consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;

report 50150 "RZW Consol. Export"
{
    ApplicationArea = All;
    Caption = 'Rijk Zwaan Consolidation Export';
    UsageCategory = Tasks;

    dataset
    {
        dataitem(GLAccount; "G/L Account")
        {
            trigger OnAfterGetRecord()
            begin
                Window.UPDATE(1, "No.");

                CASE ReportIncomeStatement OF
                    ReportIncomeStatement::"Current Period":
                        CASE "Income/Balance" OF
                            "Income/Balance"::"Income Statement":
                                BEGIN
                                    AccountingPeriod.SETRANGE("Starting Date", ConsolidStartDate, ConsolidEndDate);
                                    AccountingPeriod.SETRANGE("New Fiscal Year", TRUE);
                                    IF AccountingPeriod.FIND('-') THEN
                                        REPEAT
                                            SETFILTER("Date Filter", AccountingPeriod.GETFILTER("Starting Date") + '&<>%1',
                                                CLOSINGDATE(AccountingPeriod."Starting Date" - 1));
                                        UNTIL AccountingPeriod.NEXT() = 0
                                    ELSE
                                        SETRANGE("Date Filter", ConsolidStartDate, ConsolidEndDate);
                                END;
                            "Income/Balance"::"Balance Sheet":
                                SETRANGE("Date Filter", 0D, ConsolidEndDate);
                        END;
                    ReportIncomeStatement::All:
                        SETRANGE("Date Filter", 0D, ConsolidEndDate);
                END;

                CALCFIELDS("Net Change");

                IF "Net Change" <> 0 THEN BEGIN
                    TESTFIELD("RZW Consol. Reporting Account");
                    ConsolReportingAccount.GET("RZW Consol. Reporting Account");

                    IF NOT this.TestConsolReportingCode("RZW Consol. Reporting Account") THEN
                        ERROR(
                          Text014,
                          FIELDCAPTION("RZW Consol. Reporting Account"),
                          "RZW Consol. Reporting Account",
                          TABLECAPTION,
                          "No.");

                    TempConsolBuffer."Consolidation Code" := "RZW Consol. Reporting Account";
                    FillConsolBuffer(TempConsolBuffer, "Net Change");
                END;
            end;

            trigger OnPreDataItem()
            begin
                // Custom logic before retrieving each GL Account record can be added here.
            end;

            trigger OnPostDataItem()
            begin
                // Custom logic after processing each GL Account data item can be added here.
            end;
        }
        dataitem(ConsolBuffer; "RZW Consol. Buffer")
        {
            trigger OnAfterGetRecord()
            begin
            end;

            trigger OnPreDataItem()
            begin
                // Custom logic before retrieving each GL Account record can be added here.
            end;

            trigger OnPostDataItem()
            begin
                // Custom logic after processing each GL Account data item can be added here.
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDateReq; ConsolidStartDate)
                    {
                        Caption = 'Period Starting Date';
                        ToolTip = 'Specifies the period starting date.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            if not ConsolReportingPeriod.Get(ConsolidStartDate) then
                                Error(
                                  Text005,
                                    ConsolidStartDate, ConsolReportingPeriod.FieldCaption("Starting Date"))
                            else
                                ConsolReportingPeriod.TestField("New Fiscal Year Consol. Comp.", true);

                            if ConsolidStartDate <> 0D then
                                ConsolidEndDate := 0D;
                        end;
                    }
                    field(EndingDateReq; ConsolidEndDate)
                    {
                        Caption = 'Period Ending Date';
                        ToolTip = 'Specifies the period ending date.';
                        ApplicationArea = All;
                        trigger OnValidate()
                        begin

                            ConsolReportingPeriod.Reset();
                            if not ConsolReportingPeriod.Get(CalcDate('<+1D>', ConsolidEndDate)) then
                                Error(
                                  Text006, ConsolidEndDate);

                            if (ConsolidStartDate <> 0D) and (ConsolidEndDate <> 0D) then begin
                                if ConsolidEndDate <= ConsolidStartDate then
                                    Error(Text007);

                                ConsolReportingPeriod.Reset();
                                ConsolReportingPeriod.SetRange("Starting Date", ConsolidStartDate, ConsolidEndDate);
                                ConsolReportingPeriod.SetRange(ConsolReportingPeriod."New Fiscal Year Consol. Comp.", true);
                                if ConsolReportingPeriod.Count > 1 then
                                    Error(Text008);

                                ConsolReportingPeriod.Reset();
                                ConsolReportingPeriod.SetFilter("Starting Date", '<%1', ConsolidEndDate);
                                if ConsolReportingPeriod.Find('+') then
                                    if ConsolReportingPeriod.Reported then begin
                                        ConsolReportingPeriod.Reset();
                                        ConsolReportingPeriod.SetRange("Starting Date", ConsolidStartDate, ConsolidEndDate);
                                        ReportingPeriod := Format(ConsolReportingPeriod.Count);
                                        Message(Text009, ReportingPeriod);
                                    end;
                            end;
                        end;
                    }
                }
            }
        }
        trigger OnOpenPage()
        begin
            ConsolReportingPeriod.Reset();
            if not ConsolReportingPeriod.Find('-') then
                Error(
                  PeriodTableIsMissingErr, ConsolReportingPeriod.TableCaption);

            ConsolReportingPeriod.SetRange("New Fiscal Year Consol. Comp.", true);
            ConsolReportingPeriod.SetRange(Closed, false);
            if ConsolReportingPeriod.Find('-') then
                ConsolidStartDate := ConsolReportingPeriod."Starting Date";

            ConsolReportingPeriod.Reset();
            ConsolReportingPeriod.SetRange(Reported, false);
            if ConsolReportingPeriod.Find('-') then
                if ConsolReportingPeriod.Next() <> 0 then
                    ConsolidEndDate := CalcDate('<-1D>', ConsolReportingPeriod."Starting Date");

        end;
    }

    trigger OnPreReport()
    begin
        this.ConsolSetup.Get();
        this.ConsolSetup.TestField("Organizational Code");

        if StrLen(this.ConsolSetup."Organizational Code") <> 4 then
            Error(this.WrongOrganizationCodeErr, this.ConsolSetup.FieldCaption("Organizational Code"), this.ConsolSetup."Organizational Code");
        if (this.ConsolidStartDate = 0D) or (this.ConsolidEndDate = 0D) then
            Error(this.MissingDateErr);


        // Define Reporting Period
        this.ReportingPeriod := Format(this.ConsolidEndDate, 0, '<year,2>') + Format(this.ConsolidEndDate, 0, '<month,2>');

        this.TempConsolBuffer.DeleteAll();

        Window.Open(
          Dialog1WindowLbl +
          Dialog2WindowLbl);
    end;

    var
        ConsolSetup: Record "RZW Consol. Setup";
        TempConsolBuffer: Record "RZW Consol. Buffer";
        TempConsolReportingBuffer2: Record "RZW Consol. Buffer";
        ConsolReportingPeriod: Record "RZW Consol. Period";
        ConsolReportingAccount: Record "RZW Consol. Reporting Account";
        AccountingPeriod: Record "Accounting Period";
        ExportValue: Code[20];
        Window: Dialog;
        GLEntryFile: File;
        FilePath: Text[250];
        ReportingPeriod: Code[4];
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        AccPeriodNr: Integer;
        DebAmount: Decimal;
        CreAmount: Decimal;
        ReportIncomeStatement: Option "Current Period",All;

        PeriodTableIsMissingErr: Label 'The table %1 is empty. Reporting cannot be executed.', Locked = true;
        Dialog1WindowLbl: Label ' Processing the chart of accounts...\\', Locked = true;
        Dialog2WindowLbl: Label ' No.             #1##########', Locked = true;
        Text004: Label ' %1 must be specified for %2 %3.';
        Text005: Label ' %1 is not a valid %2.';
        Text006: Label ' %1 is not the last date of a reporting period.';
        Text007: Label ' Reporting period Ending Date must be later than Starting Date.';
        Text008: Label 'Reporting period Ending Date must belong to the same Fiscal year as the Starting Date.';
        Text009: Label 'Period %1 has already been reported to the consolidation company.\Please check Reporting period Ending Date.';
        Text010: Label 'Please enter a valid file path.';
        MissingDateErr: Label 'Please enter both the starting date and ending dates for the Reporting Period.';
        WrongOrganizationCodeErr: Label 'The length of the %1 must be 4 (%2).', Locked = true;
        Text014: Label '%1 "%2" is not correct for %3 %4.';
        Text015: Label 'An inconsistency has occurred within the G/L entries.\Please check the amounts.';
        Text016: Label 'The Debit Amount must be equal to the Credit Amount.\Please check whether field %1 was filled in correctly in table %2.';


    local procedure FillConsolBuffer(var BufferRec: Record "RZW Consol. Buffer"; Amount: Decimal)
    begin
        if BufferRec.FIND then begin
            BufferRec.Amount := BufferRec.Amount + Amount;
            BufferRec.MODIFY;
        end else begin
            BufferRec.Amount := Amount;
            BufferRec."Debet/Credit" := ConsolReportingAccount."Debet/Credit";
            BufferRec.INSERT;
        end;
    end;

    local procedure TestConsolReportingCode(CORACode: Code[20]): Boolean
    begin
        if ConsolReportingAccount."Debet/Credit" = 0 then
            ERROR(
              Text004,
                ConsolReportingAccount.FIELDCAPTION("Debet/Credit"), ConsolReportingAccount.TABLECAPTION,
                ConsolReportingAccount.Code);
        exit(true);
    end;

    local procedure CheckSumRequired(): Boolean
    var
        AccountingPeriod2: Record "Accounting Period";
        ConsolReportingPeriod2: Record "RZW Consol. Period";
    begin
        AccountingPeriod2.SETFILTER("Starting Date", '<=%1', ConsolidEndDate);
        AccountingPeriod2.SETRANGE("New Fiscal Year", true);
        AccountingPeriod2.FINDLast();

        ConsolReportingPeriod2.SETFILTER("Starting Date", '<=%1', ConsolidEndDate);
        ConsolReportingPeriod2.SETRANGE("New Fiscal Year Consol. Comp.", true);
        ConsolReportingPeriod2.FINDLast();

        exit(AccountingPeriod2."Starting Date" = ConsolReportingPeriod2."Starting Date");
    end;
}
