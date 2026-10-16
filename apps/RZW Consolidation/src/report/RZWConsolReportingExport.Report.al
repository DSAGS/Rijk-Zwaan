namespace dsa.rzw.consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;
using System.IO;
using System.Utilities;

report 50150 "RZW Consol. Reporting Export"
{
    ApplicationArea = All;
    Caption = 'Rijk Zwaan Consolidation Reporting Export';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    dataset
    {
        dataitem(GLAccount; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Account Type" = const(Posting));
            trigger OnPreDataItem()
            begin
                this.Window.Open(
                    this.Dialog1WindowLbl +
                    this.Dialog2WindowLbl);
            end;

            trigger OnAfterGetRecord()
            var
                AccountingPeriod: Record "Accounting Period";
            begin
                this.Window.Update(1, "No.");

                case this.ReportIncomeStatement of
                    this.ReportIncomeStatement::"Current Period":
                        case "Income/Balance" of
                            "Income/Balance"::"Income Statement":
                                begin
                                    AccountingPeriod.SetRange("Starting Date", this.ConsolidStartDate, this.ConsolidEndDate);
                                    AccountingPeriod.SetRange("New Fiscal Year", true);
                                    if AccountingPeriod.Find('-') then
                                        repeat
                                            SetFilter("Date Filter", AccountingPeriod.GetFilter("Starting Date") + '&<>%1',
                                                ClosingDate(AccountingPeriod."Starting Date" - 1));
                                        until AccountingPeriod.Next() = 0
                                    else
                                        SetRange("Date Filter", this.ConsolidStartDate, this.ConsolidEndDate);
                                end;
                            "Income/Balance"::"Balance Sheet":
                                SetRange("Date Filter", 0D, this.ConsolidEndDate);
                        end;
                    this.ReportIncomeStatement::All:
                        SetRange("Date Filter", 0D, this.ConsolidEndDate);
                end;

                CalcFields("Net Change");

                if "Net Change" <> 0 then begin
                    TestField("RZW Consol. Reporting Account");
                    this.ConsolReportingAccount.Get("RZW Consol. Reporting Account");

                    if not this.TestConsolReportingCode("RZW Consol. Reporting Account") then
                        Error(
                          this.Text014,
                          FieldCaption("RZW Consol. Reporting Account"),
                          "RZW Consol. Reporting Account",
                          TableCaption,
                          "No.");

                    this.TempConsolBuffer."Consolidation Code" := "RZW Consol. Reporting Account";
                    this.FillConsolidationBuffer(this.TempConsolBuffer, "Net Change");
                end;
            end;



            trigger OnPostDataItem()
            begin
                this.Window.Close();
            end;
        }
        dataitem(ConsolBuffer; "RZW Consol. Reporting Buffer")
        {


            trigger OnPreDataItem()
            var
                Cr: Char;
            begin
                // IF CheckSumRequired THEN BEGIN
                //     // If the New Fiscal Year for the Accounting Periods match the Consolidation Periods then
                //     // check the totals! This is the case when the Fiscal Year for this company matches the
                //     // Fiscal Year from the Dutch affiliates.

                //     // Test if Total Amount = 0!
                //     ConsReportingBuffer2.SETCURRENTKEY("Debit/Credit");
                //     ConsReportingBuffer2.CALCSUMS(Amount);
                //     IF ConsReportingBuffer2.Amount <> 0 THEN
                //         ERROR(Text015);

                //     // Test if Debet = Credit!
                //     ConsReportingBuffer2.SETFILTER("Debit/Credit", '%1', ConsReportingBuffer2."Debit/Credit"::Debit);
                //     ConsReportingBuffer2.CALCSUMS(Amount);
                //     DebAmount := ConsReportingBuffer2.Amount;

                //     ConsReportingBuffer2.SETFILTER("Debit/Credit", '%1', ConsReportingBuffer2."Debit/Credit"::Credit);
                //     ConsReportingBuffer2.CALCSUMS(Amount);
                //     CreAmount := ConsReportingBuffer2.Amount;

                //     IF DebAmount <> -CreAmount THEN
                //         ERROR(Text016,
                //             ConsReportingBuffer2.FIELDCAPTION("Debit/Credit"), ConsReportingBuffer2.TABLECAPTION);
                // END;

                this.TempBLOB.CreateOutStream(this.OutStream, TextEncoding::UTF8);

                Cr := 13;
                this.LineFeed[1] := Cr;
                Cr := 10;
                this.LineFeed[2] := Cr;
            end;

            trigger OnAfterGetRecord()
            var
                ExportValue: Text;
            begin
                ExportValue := Format(Amount, 0, '<Sign><Integer><Decimals>');
                ExportValue := ConvertStr(ExportValue, ',', '.');

                this.OutStream.WriteText(StrSubstNo('%1;%2%3', "Consolidation Code", ExportValue, this.LineFeed));
            end;

            trigger OnPostDataItem()
            var
                FileManagement: Codeunit "File Management";
                FileNameLbl: Label 'Consoli%1 %2.txt', Locked = true;
            begin
                FileManagement.BLOBExport(this.TempBLOB, StrSubstNo(FileNameLbl, this.ConsolidStartDate, this.ConsolidEndDate), true);

                this.ConsolReportingPeriod.SetRange("Starting Date", 0D, this.ConsolidEndDate);
                this.ConsolReportingPeriod.FindLast();
                this.ConsolReportingPeriod."Reported" := true;
                this.ConsolReportingPeriod.Modify(false);
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
            if ConsolReportingPeriod.IsEmpty() then
                Error(PeriodTableIsMissingErr, ConsolReportingPeriod.TableCaption);

            ConsolReportingPeriod.SetRange("New Fiscal Year Consol. Comp.", true);
            ConsolReportingPeriod.SetRange(Closed, false);
            if ConsolReportingPeriod.FindFirst() then
                ConsolidStartDate := ConsolReportingPeriod."Starting Date";

            ConsolReportingPeriod.Reset();
            ConsolReportingPeriod.SetRange(Reported, false);
            if ConsolReportingPeriod.FindFirst() then
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
    end;

    var
        ConsolSetup: Record "RZW Consol. Setup";
        TempConsolBuffer: Record "RZW Consol. Reporting Buffer";
        TempConsolReportingBuffer2: Record "RZW Consol. Reporting Buffer";
        ConsolReportingPeriod: Record "RZW Consol. Reporting Period";
        ConsolReportingAccount: Record "RZW Consol. Reporting Account";
        TempBLOB: Codeunit "Temp Blob";
        LineFeed: Text;

        Window: Dialog;
        OutStream: OutStream;
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


    local procedure FillConsolidationBuffer(var ConsolBuffer2: Record "RZW Consol. Reporting Buffer"; Amount: Decimal)
    begin
        if ConsolBuffer2.Find() then begin
            ConsolBuffer2.Amount := ConsolBuffer2.Amount + Amount;
            ConsolBuffer2.Modify();
        end else begin
            ConsolBuffer2.Amount := Amount;
            ConsolBuffer2."Debet/Credit" := this.ConsolReportingAccount."Debet/Credit";
            ConsolBuffer2.Insert();
        end;
    end;

    local procedure TestConsolReportingCode(CORACode: Code[20]): Boolean
    begin
        if this.ConsolReportingAccount."Debet/Credit" = 0 then
            Error(
              this.Text004,
                this.ConsolReportingAccount.FieldCaption("Debet/Credit"), this.ConsolReportingAccount.TableCaption,
                this.ConsolReportingAccount.Code);
        exit(true);
    end;

    local procedure CheckSumRequired(): Boolean
    var
        AccountingPeriod2: Record "Accounting Period";
        ConsolReportingPeriod2: Record "RZW Consol. Reporting Period";
    begin
        AccountingPeriod2.SetFilter("Starting Date", '<=%1', this.ConsolidEndDate);
        AccountingPeriod2.SetRange("New Fiscal Year", true);
        AccountingPeriod2.FindLast();

        ConsolReportingPeriod2.SetFilter("Starting Date", '<=%1', this.ConsolidEndDate);
        ConsolReportingPeriod2.SetRange("New Fiscal Year Consol. Comp.", true);
        ConsolReportingPeriod2.FindLast();

        exit(AccountingPeriod2."Starting Date" = ConsolReportingPeriod2."Starting Date");
    end;
}
