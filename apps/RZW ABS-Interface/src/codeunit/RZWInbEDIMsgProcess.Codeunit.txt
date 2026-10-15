namespace RZW;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
codeunit 50111 "RZW Inb. EDI Msg.-Process"
{
    TableNo = "RZW EDI Message Header";

    trigger OnRun()
    var
        EDIMessageHeader2: Record "RZW EDI Message Header";
    begin
        ClearAll();
        EDIMessageHeader := Rec;

        EDIMessageHeader.Status := EDIMessageHeader.Status::Rejected;
        EDIMessageHeader.Modify();
        Commit();
        // To prevent processing in a wrong company
        EDIMessageHeader.TestField(Company, CompanyName);

        GLSetup.Get();
        EDISetup.Get();

        EDIMessageType.Get(EDIMessageHeader."EDI Message Type");
        EDIMessageType.TestField(Direction, EDIMessageType.Direction::Inbound);
        // To prevent processing in a wrong sorting order
        if EDIMessageType."Run No. Order" then begin
            EDIMessageHeader2.SetCurrentKey(Company, "EDI Message Type", "Run No.", Status);
            EDIMessageHeader2.SetRange(Company, EDIMessageHeader.Company);
            EDIMessageHeader2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
            EDIMessageHeader2.SetFilter("Run No.", '<%1', EDIMessageHeader."Run No.");
            EDIMessageHeader2.SetFilter(Status, '%1|%2', EDIMessageHeader2.Status::New, EDIMessageHeader2.Status::Rejected);
            if not EDIMessageHeader2.IsEmpty() then
                Error(Text000, EDIMessageHeader."Run No.");
        end;

        Window.Open(
          '#1#################################\\' +
          Text002);
        Window.Update(1, StrSubstNo('%1 %2', EDIMessageHeader.TableCaption, EDIMessageHeader."Run No."));

        case EDIMessageHeader."File Type" of
            EDIMessageHeader."File Type"::"Sales Invoice":
                ProcessSalesDocument();
            EDIMessageHeader."File Type"::"Customer Master":
                ProcessCustomer();
            EDIMessageHeader."File Type"::"Vendor Master":
                ProcessVendor();
        end;

        EDIMessageHeader.Status := EDIMessageHeader.Status::Processed;
        EDIMessageHeader.Modify();
        Commit();
        Rec := EDIMessageHeader;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        EDISetup: Record "RZW EDI Setup";
        EDIMessageHeader: Record "RZW EDI Message Header";
        EDIMessageType: Record "RZW EDI Message Type";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Window: Dialog;
        LineCounter: Integer;
        CurrentEntryNo: Integer;
        CurrentFieldNo: Integer;
        NoOfDocuments: Integer;
        TestNoOfDocuments: Boolean;
        Text000: Label 'You cannot process EDI Message with Run No. %1, since earlier generated EDI Messages exist for the same company.';
        Text001: Label 'There is nothing to process.';
        Text002: Label 'Processing lines              #2######';
        Text010: Label 'A %1 with %2 %3 could not be found.';
        Text011: Label 'Multiple records of the type %1 have been found with %2 %3.';
        Text012: Label 'The Value %1 could not be converted into a Quantity.';
        Text013: Label 'An unknown Supplier Code has been used in message %1 (%2).';
        Text020: Label '%1 %2 does have %3 %4 as %5. This doens''t match the value of the NAD-IV record in %6 %7. Please check your settings.';
        Text021: Label '''';
        Text030: Label 'VAT correction';
        Text031: Label 'The total No. of Documents in the File does not match the quantity indicated in the file header.\\Please check the file.';
        EmptyTextLine: Label 'Bónus - Alínea b) do nº 6 do Art. 16º do CIVA';

    local procedure ProcessCustomer()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail.SetRange("Field No.", 1);
        if not EDIMessageLineDetail.FindSet() then
            Error(Text001);

        EDISetup.TestImportCust();

        repeat
            case EDIMessageLineDetail.Content of
                'LIN02':
                    ProcessLIN02(EDIMessageLineDetail);
                'LIN04':
                    ProcessLIN04(EDIMessageLineDetail);
                'LIN11':
                    ProcessLIN11(EDIMessageLineDetail);
            end;
        until EDIMessageLineDetail.Next() = 0;
    end;

    local procedure ProcessLIN02(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        Cust: Record Microsoft.Sales.Customer.Customer;
        CustRecRef: RecordRef;
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        CustRecRef.Open(Database::Customer, false, CompanyName);

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                3:
                    begin
                        if EDISetup."Remove Leading Zeros" then
                            EDIMessageLineDetail2.Content := DelChr(EDIMessageLineDetail2.Content, '<', '0');

                        if not Cust.Get(EDIMessageLineDetail2.Content) then begin
                            Cust.Init();
                            Cust."No." := EDIMessageLineDetail2.Content;
                            Cust.Insert();
                        end;
                    end;
                4:
                    Cust.Name := EDIMessageLineDetail2.Content;
                5:
                    Cust."Name 2" := EDIMessageLineDetail2.Content;
                6:
                    Cust."Search Name" := EDIMessageLineDetail2.Content;
                7:
                    Cust.Address := EDIMessageLineDetail2.Content;
                8:
                    Cust."Address 2" := EDIMessageLineDetail2.Content;
                9:
                    Cust."Post Code" := EDIMessageLineDetail2.Content;
                10:
                    Cust.City := EDIMessageLineDetail2.Content;
                11:
                    Cust.County := EDIMessageLineDetail2.Content;
                12:
                    Cust.Validate("Country/Region Code", EDIMessageLineDetail2.Content);
                13:
                    Cust.Contact := EDIMessageLineDetail2.Content;
                14:
                    Cust."Phone No." := EDIMessageLineDetail2.Content;
                15:
                    Cust."Fax No." := EDIMessageLineDetail2.Content;
                16:
                    Cust."Telex No." := EDIMessageLineDetail2.Content;
                17:
                    Cust."E-Mail" := EDIMessageLineDetail2.Content;
                18:
                    Cust."Home Page" := EDIMessageLineDetail2.Content;
                19:
                    Cust."Territory Code" := EDIMessageLineDetail2.Content;
                20:
                    Cust."Credit Limit (LCY)" := GetDecimal(EDIMessageLineDetail2.Content);
                21:
                    begin
                        Cust."Customer Posting Group" := EDIMessageLineDetail2.Content;
                        if Cust."Customer Posting Group" = '' then
                            Cust."Customer Posting Group" := EDISetup."Def. Customer Posting Group";
                        Cust.Validate("Customer Posting Group");
                    end;
                22:
                    begin
                        Cust."Currency Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Clear LCY from Currency Codes" and (Cust."Currency Code" = GLSetup."LCY Code") then
                            Cust."Currency Code" := '';
                        Cust.Validate("Currency Code");
                    end;
                23:
                    Cust.Validate("Language Code", EDIMessageLineDetail2.Content);
                24:
                    Cust.Validate("Payment Terms Code", EDIMessageLineDetail2.Content);
                25:
                    Cust.Validate("Shipment Method Code", EDIMessageLineDetail2.Content);
                26:
                    Cust.Validate("Payment Method Code", EDIMessageLineDetail2.Content);
                27:
                    Cust.Validate("Fin. Charge Terms Code", EDIMessageLineDetail2.Content);
                28:
                    Cust.Validate("Reminder Terms Code", EDIMessageLineDetail2.Content);
                29:
                    begin
                        Cust."Salesperson Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Remove Leading Zeros" then
                            Cust."Salesperson Code" := DelChr(Cust."Salesperson Code", '<', '0');
                        Cust.Validate("Salesperson Code");
                    end;
                30:
                    case GetInteger(EDIMessageLineDetail2.Content) of
                        0:
                            Cust.Blocked := Cust.Blocked::" ";
                        1:
                            Cust.Blocked := Cust.Blocked::All;
                    end;
                31:
                    Cust."VAT Registration No." := EDIMessageLineDetail2.Content;
                32:
                    begin
                        Cust."Gen. Bus. Posting Group" := EDIMessageLineDetail2.Content;
                        if Cust."Gen. Bus. Posting Group" = '' then
                            Cust."Gen. Bus. Posting Group" := EDISetup."Def. Gen. Bus. Posting Group";
                        Cust.Validate("Gen. Bus. Posting Group");
                    end;
                33:
                    begin
                        Cust."VAT Bus. Posting Group" := EDIMessageLineDetail2.Content;
                        if Cust."VAT Bus. Posting Group" = '' then
                            Cust."VAT Bus. Posting Group" := EDISetup."Def. VAT Bus. Posting Group";
                        Cust.Validate("VAT Bus. Posting Group");
                    end;
                36:
                    begin
                        Cust."Last Date Modified" := Today;
                        Cust.Modify();

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            CustRecRef.GetTable(Cust);
                            EDIMessageLine."Record-ID" := CustRecRef.RecordId;
                            EDIMessageLine.Modify();
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;

        CustRecRef.Close();
    end;

    local procedure ProcessLIN04(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        CustBankAccount: Record "Customer Bank Account";
        CustBankRecRef: RecordRef;
        TempCustNo: Code[20];
        TempBankCode: Code[10];
    begin
        if EDISetup."Skip Bank Data in Import" then
            exit;

        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        CustBankRecRef.Open(Database::"Customer Bank Account", false, CompanyName);

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                3:
                    begin
                        if EDISetup."Remove Leading Zeros" then
                            EDIMessageLineDetail2.Content := DelChr(EDIMessageLineDetail2.Content, '<', '0');
                        TempCustNo := EDIMessageLineDetail2.Content;
                    end;
                4:
                    begin
                        TempBankCode := CopyStr(EDIMessageLineDetail2.Content, 1, MaxStrLen(CustBankAccount.Code));
                        if not CustBankAccount.Get(TempCustNo, TempBankCode) then begin
                            CustBankAccount.Init();
                            CustBankAccount."Customer No." := TempCustNo;
                            CustBankAccount.Code := TempBankCode;
                            CustBankAccount.Insert();
                            CustBankAccount."Bank Account No." := EDIMessageLineDetail2.Content;
                        end;
                    end;
                6:
                    CustBankAccount.Name := EDIMessageLineDetail2.Content;
                7:
                    CustBankAccount.Address := EDIMessageLineDetail2.Content;
                8:
                    CustBankAccount."Post Code" := EDIMessageLineDetail2.Content;
                9:
                    CustBankAccount.City := EDIMessageLineDetail2.Content;
                10:
                    CustBankAccount.County := EDIMessageLineDetail2.Content;
                11:
                    CustBankAccount."Country/Region Code" := EDIMessageLineDetail2.Content;
                12:// Bank Account Bank (ES and PT)
                   // RZWPT
                    begin
                        CustBankAccount."IBAN - Bank Account No." := CopyStr(EDIMessageLineDetail2.Content, 1, 4);
                        CustBankAccount."IBAN - Bank Branch No." := CopyStr(EDIMessageLineDetail2.Content, 5, 4);
                        CustBankAccount."IBAN - Check Digits" := CopyStr(EDIMessageLineDetail2.Content, 9, 2);
                        CustBankAccount."NIB - Bank Identification No." :=
                          CopyStr(EDIMessageLineDetail2.Content, 1, 10) + COPYSTR(CustBankAccount."IBAN - Bank Account No.", 1, 10);
                        // Save bank account record
                        CustBankAccount.Modify();

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            CustBankRecRef.GetTable(CustBankAccount);
                            EDIMessageLine."Record-ID" := CustBankRecRef.RecordId;
                            EDIMessageLine.Modify();
                        end;
                    end;
                // RZWPT {*}
                13:
                    ;// Transit
                14:
                    ;
            // Bank Branch office No. (IT = ABI/CAB Nos.)
            end;
        until EDIMessageLineDetail2.Next() = 0;
        CustBankRecRef.Close();
    end;

    local procedure ProcessLIN11(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        Cust: Record Customer;
        CustRecRef: RecordRef;
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        CustRecRef.Open(Database::Customer, false, CompanyName);

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                3:
                    begin
                        if EDISetup."Remove Leading Zeros" then
                            EDIMessageLineDetail2.Content := DelChr(EDIMessageLineDetail2.Content, '<', '0');

                        if not Cust.Get(EDIMessageLineDetail2.Content) then begin
                            Cust.Init();
                            Cust."No." := EDIMessageLineDetail2.Content;
                            Cust.Insert();
                        end;
                    end;
                4:
                    Cust.Name := EDIMessageLineDetail2.Content;
                5:
                    Cust."Name 2" := EDIMessageLineDetail2.Content;
                6:
                    Cust."Search Name" := EDIMessageLineDetail2.Content;
                7:
                    Cust.Address := EDIMessageLineDetail2.Content;
                8:
                    Cust."Address 2" := EDIMessageLineDetail2.Content;
                9:
                    Cust."Post Code" := EDIMessageLineDetail2.Content;
                10:
                    Cust.City := EDIMessageLineDetail2.Content;
                11:
                    Cust.County := EDIMessageLineDetail2.Content;
                12:
                    Cust.Validate("Country/Region Code", EDIMessageLineDetail2.Content);
                13:
                    Cust.Contact := EDIMessageLineDetail2.Content;
                14:
                    Cust."Phone No." := EDIMessageLineDetail2.Content;
                15:
                    Cust."Fax No." := EDIMessageLineDetail2.Content;
                16:
                    Cust."Telex No." := EDIMessageLineDetail2.Content;
                17:
                    Cust."E-Mail" := EDIMessageLineDetail2.Content;
                18:
                    Cust."Home Page" := EDIMessageLineDetail2.Content;
                19:
                    Cust."Territory Code" := EDIMessageLineDetail2.Content;
                20:
                    Cust."Credit Limit (LCY)" := GetDecimal(EDIMessageLineDetail2.Content);
                21:
                    begin
                        Cust."Customer Posting Group" := EDIMessageLineDetail2.Content;
                        if Cust."Customer Posting Group" = '' then
                            Cust."Customer Posting Group" := EDISetup."Def. Customer Posting Group";
                        Cust.Validate("Customer Posting Group");
                    end;
                22:
                    begin
                        Cust."Currency Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Clear LCY from Currency Codes" and (Cust."Currency Code" = GLSetup."LCY Code") then
                            Cust."Currency Code" := '';
                        Cust.Validate("Currency Code");
                    end;
                23:
                    Cust.Validate("Language Code", EDIMessageLineDetail2.Content);
                24:
                    Cust.Validate("Payment Terms Code", EDIMessageLineDetail2.Content);
                25:
                    Cust.Validate("Shipment Method Code", EDIMessageLineDetail2.Content);
                26:
                    Cust.Validate("Payment Method Code", EDIMessageLineDetail2.Content);
                27:
                    Cust.Validate("Fin. Charge Terms Code", EDIMessageLineDetail2.Content);
                28:
                    Cust.Validate("Reminder Terms Code", EDIMessageLineDetail2.Content);
                29:
                    begin
                        Cust."Salesperson Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Remove Leading Zeros" then
                            Cust."Salesperson Code" := DelChr(Cust."Salesperson Code", '<', '0');
                        Cust.Validate("Salesperson Code");
                    end;
                30:
                    case GetInteger(EDIMessageLineDetail2.Content) of
                        0:
                            Cust.Blocked := Cust.Blocked::" ";
                        1:
                            Cust.Blocked := Cust.Blocked::All;
                    end;
                31:
                    Cust."VAT Registration No." := EDIMessageLineDetail2.Content;
                32:
                    begin
                        Cust."Gen. Bus. Posting Group" := EDIMessageLineDetail2.Content;
                        if Cust."Gen. Bus. Posting Group" = '' then
                            Cust."Gen. Bus. Posting Group" := EDISetup."Def. Gen. Bus. Posting Group";
                        Cust.Validate("Gen. Bus. Posting Group");
                    end;
                33:
                    begin
                        Cust."VAT Bus. Posting Group" := EDIMessageLineDetail2.Content;
                        if Cust."VAT Bus. Posting Group" = '' then
                            Cust."VAT Bus. Posting Group" := EDISetup."Def. VAT Bus. Posting Group";
                        Cust.Validate("VAT Bus. Posting Group");
                    end;

                34:
                    ;
                35:
                    ;
                36:
                    ;
                37:
                    ;
                38:
                    ;
                39:
                    ;
                40:
                    begin
                        Cust."Tax Liable" := true;
                        Cust."Last Date Modified" := Today;
                        Cust.Modify();

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            CustRecRef.GetTable(Cust);
                            EDIMessageLine."Record-ID" := CustRecRef.RecordId;
                            EDIMessageLine.Modify();
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;

        CustRecRef.Close();
    end;

    local procedure ProcessVendor()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail.SetRange("Field No.", 1);
        if not EDIMessageLineDetail.FindSet() then
            Error(Text001);

        EDISetup.TestImportVend();

        repeat
            case EDIMessageLineDetail.Content of
                'LIN03':
                    ProcessLIN03(EDIMessageLineDetail);
                'LIN05':
                    ProcessLIN05(EDIMessageLineDetail);
            end;
        until EDIMessageLineDetail.Next() = 0;
    end;

    local procedure ProcessLIN03(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        Vend: Record Vendor;
        VendRecRef: RecordRef;
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        VendRecRef.Open(Database::Vendor, false, CompanyName);

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                3:
                    begin
                        if EDISetup."Remove Leading Zeros" then
                            EDIMessageLineDetail2.Content := DelChr(EDIMessageLineDetail2.Content, '<', '0');

                        if not Vend.Get(EDIMessageLineDetail2.Content) then begin
                            Vend.Init();
                            Vend."No." := EDIMessageLineDetail2.Content;
                            Vend.Insert();
                        end;
                    end;
                4:
                    Vend.Name := EDIMessageLineDetail2.Content;
                5:
                    Vend."Name 2" := EDIMessageLineDetail2.Content;
                6:
                    Vend."Search Name" := EDIMessageLineDetail2.Content;
                7:
                    Vend.Address := EDIMessageLineDetail2.Content;
                8:
                    Vend."Address 2" := EDIMessageLineDetail2.Content;
                9:
                    Vend."Post Code" := EDIMessageLineDetail2.Content;
                10:
                    Vend.City := EDIMessageLineDetail2.Content;
                11:
                    Vend.County := EDIMessageLineDetail2.Content;
                12:
                    Vend.Validate("Country/Region Code", EDIMessageLineDetail2.Content);
                13:
                    Vend.Contact := EDIMessageLineDetail2.Content;
                14:
                    Vend."Phone No." := EDIMessageLineDetail2.Content;
                15:
                    Vend."Fax No." := EDIMessageLineDetail2.Content;
                16:
                    Vend."Telex No." := EDIMessageLineDetail2.Content;
                17:
                    Vend."E-Mail" := EDIMessageLineDetail2.Content;
                18:
                    Vend."Home Page" := EDIMessageLineDetail2.Content;
                19:
                    Vend."Territory Code" := EDIMessageLineDetail2.Content;
                20:
                    begin
                        Vend."Vendor Posting Group" := EDIMessageLineDetail2.Content;
                        if Vend."Vendor Posting Group" = '' then
                            Vend."Vendor Posting Group" := EDISetup."Def. Vendor Posting Group";
                        Vend.Validate("Vendor Posting Group");
                    end;
                21:
                    begin
                        Vend."Currency Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Clear LCY from Currency Codes" and (Vend."Currency Code" = GLSetup."LCY Code") then
                            Vend."Currency Code" := '';
                        Vend.Validate("Currency Code");
                    end;
                22:
                    Vend.Validate("Language Code", EDIMessageLineDetail2.Content);
                23:
                    Vend.Validate("Payment Terms Code", EDIMessageLineDetail2.Content);
                24:
                    Vend.Validate("Shipment Method Code", EDIMessageLineDetail2.Content);
                25:
                    Vend.Validate("Payment Method Code", EDIMessageLineDetail2.Content);
                26:
                    Vend.Validate("Fin. Charge Terms Code", EDIMessageLineDetail2.Content);
                27:
                    begin
                        Vend."Purchaser Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Remove Leading Zeros" then
                            Vend."Purchaser Code" := DelChr(Vend."Purchaser Code", '<', '0');
                        Vend.Validate("Purchaser Code");
                    end;
                28:
                    case GetInteger(EDIMessageLineDetail2.Content) of
                        0:
                            Vend.Blocked := Vend.Blocked::" ";
                        1:
                            Vend.Blocked := Vend.Blocked::All;
                    end;
                29:
                    Vend."VAT Registration No." := EDIMessageLineDetail2.Content;
                30:
                    begin
                        Vend."Gen. Bus. Posting Group" := EDIMessageLineDetail2.Content;
                        if Vend."Gen. Bus. Posting Group" = '' then
                            Vend."Gen. Bus. Posting Group" := EDISetup."Def. Gen. Bus. Posting Group";
                        Vend.Validate("Gen. Bus. Posting Group");
                    end;
                31:
                    begin
                        Vend."VAT Bus. Posting Group" := EDIMessageLineDetail2.Content;
                        if Vend."VAT Bus. Posting Group" = '' then
                            Vend."VAT Bus. Posting Group" := EDISetup."Def. VAT Bus. Posting Group";
                        Vend.Validate("VAT Bus. Posting Group");
                    end;
                33:
                    begin
                        Vend."Our Account No." := EDIMessageLineDetail2.Content;
                        Vend."Last Date Modified" := Today;
                        Vend.Modify();

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            VendRecRef.GetTable(Vend);
                            EDIMessageLine."Record-ID" := VendRecRef.RecordId;
                            EDIMessageLine.Modify();
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;

        VendRecRef.Close();
    end;

    local procedure ProcessLIN05(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        VendBankAccount: Record "Vendor Bank Account";
        VendBankRecRef: RecordRef;
        TempVendNo: Code[20];
        TempBankCode: Code[10];
    begin
        if EDISetup."Skip Bank Data in Import" then
            exit;

        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        VendBankRecRef.Open(Database::"Vendor Bank Account", false, CompanyName);

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                3:
                    begin
                        if EDISetup."Remove Leading Zeros" then
                            EDIMessageLineDetail2.Content := DelChr(EDIMessageLineDetail2.Content, '<', '0');
                        TempVendNo := EDIMessageLineDetail2.Content;
                    end;
                4:
                    begin
                        TempBankCode := CopyStr(EDIMessageLineDetail2.Content, 1, MaxStrLen(VendBankAccount.Code));
                        if not VendBankAccount.Get(TempVendNo, TempBankCode) then begin
                            VendBankAccount.Init();
                            VendBankAccount."Vendor No." := TempVendNo;
                            VendBankAccount.Code := TempBankCode;
                            VendBankAccount.Insert();
                            VendBankAccount."Bank Account No." := EDIMessageLineDetail2.Content;
                        end;
                    end;
                6:
                    VendBankAccount.Name := EDIMessageLineDetail2.Content;
                7:
                    VendBankAccount.Address := EDIMessageLineDetail2.Content;
                8:
                    VendBankAccount."Post Code" := EDIMessageLineDetail2.Content;
                9:
                    VendBankAccount.City := EDIMessageLineDetail2.Content;
                10:
                    VendBankAccount.County := EDIMessageLineDetail2.Content;
                11:
                    begin
                        VendBankAccount."Country/Region Code" := EDIMessageLineDetail2.Content;
                        VendBankAccount.Modify();

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            VendBankRecRef.GetTable(VendBankAccount);
                            EDIMessageLine."Record-ID" := VendBankRecRef.RecordId;
                            EDIMessageLine.Modify();
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;

        VendBankRecRef.Close();
    end;

    local procedure ProcessSalesDocument()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail.SetRange("Field No.", 1);
        if not EDIMessageLineDetail.FindSet() then
            Error(Text001);

        EDISetup.TestImportSInv();

        repeat
            case EDIMessageLineDetail.Content of
                'TOT01':
                    ProcessTOT01(EDIMessageLineDetail);
                'HDR01':
                    ProcessHDR01(EDIMessageLineDetail);
                'HDR03':
                    ProcessHDR03(EDIMessageLineDetail);
                'LIN01':
                    ProcessLIN01(EDIMessageLineDetail);
                'LIN06':
                    ProcessLIN06(EDIMessageLineDetail);
                'LIN08':
                    ProcessLIN08(EDIMessageLineDetail);
                'FTR01':
                    ProcessFTR01(EDIMessageLineDetail);
            end;
        until EDIMessageLineDetail.Next() = 0;
        // Check for correct number of documents
        if TestNoOfDocuments then
            if NoOfDocuments <> 0 then
                Error(Text031);
    end;

    local procedure ProcessTOT01(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                2:
                    begin
                        NoOfDocuments := GetInteger(EDIMessageLineDetail2.Content);
                        TestNoOfDocuments := true;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;
    end;

    local procedure ProcessHDR01(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        TempSalesHeader: Record "Sales Header" temporary;
        SalesHeaderRecRef: RecordRef;
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        SalesHeaderRecRef.Open(Database::"Sales Header", false, CompanyName);

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                3:
                    begin
                        Clear(TempSalesHeader);
                        TempSalesHeader."Posting Date" := GetDate(EDIMessageLineDetail2.Content);
                    end;
                4:
                    TempSalesHeader."Document Type" := GetInteger(EDIMessageLineDetail2.Content) + 1;
                5:
                    begin
                        TempSalesHeader."No." := EDIMessageLineDetail2.Content;
                        TempSalesHeader."Posting No." := EDIMessageLineDetail2.Content;
                    end;
                6:
                    begin
                        if EDISetup."Remove Leading Zeros" then
                            EDIMessageLineDetail2.Content := DelChr(EDIMessageLineDetail2.Content, '<', '0');
                        TempSalesHeader."Sell-to Customer No." := EDIMessageLineDetail2.Content;
                    end;
                7:
                    TempSalesHeader."Your Reference" := EDIMessageLineDetail2.Content;
                8:
                    begin
                        TempSalesHeader."Currency Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Clear LCY from Currency Codes" and (TempSalesHeader."Currency Code" = GLSetup."LCY Code") then
                            TempSalesHeader."Currency Code" := '';
                    end;
                10:
                    begin
                        TempSalesHeader."Salesperson Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Remove Leading Zeros" then
                            TempSalesHeader."Salesperson Code" := DelChr(TempSalesHeader."Salesperson Code", '<', '0');
                    end;
                11:
                    TempSalesHeader."Due Date" := GetDate(EDIMessageLineDetail2.Content);
                12:
                    TempSalesHeader."Pmt. Discount Date" := GetDate(EDIMessageLineDetail2.Content);
                13:
                    TempSalesHeader."Payment Discount %" := GetDecimal(EDIMessageLineDetail2.Content);
                14:
                    TempSalesHeader."Document Date" := GetDate(EDIMessageLineDetail2.Content);
                15:
                    begin
                        TempSalesHeader."Payment Method Code" := EDIMessageLineDetail2.Content;
                        // All necessary fields are populated, create Sales Header
                        Clear(SalesHeader);
                        SalesHeader.SetHideValidationDialog(true);

                        SalesHeader."Document Type" := TempSalesHeader."Document Type";
                        SalesHeader.Validate("No.", TempSalesHeader."No.");
                        SalesHeader.Insert(true);

                        SalesHeader.Validate("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");
                        SalesHeader.Validate("Posting Date", TempSalesHeader."Posting Date");
                        if TempSalesHeader."Payment Terms Code" = '' then
                            TempSalesHeader."Payment Terms Code" := EDISetup."Default Payment Terms Code";
                        SalesHeader.Validate("Payment Terms Code");

                        SalesHeader.Validate("Payment Method Code", TempSalesHeader."Payment Method Code");
                        SalesHeader.Validate("Due Date", TempSalesHeader."Due Date");

                        if TempSalesHeader."Document Type" = TempSalesHeader."Document Type"::Invoice then begin
                            SalesHeader.Validate("Pmt. Discount Date", TempSalesHeader."Pmt. Discount Date");
                            SalesHeader.Validate("Payment Discount %", TempSalesHeader."Payment Discount %")
                        end;
                        SalesHeader.Validate("Currency Code", TempSalesHeader."Currency Code");

                        SalesHeader.Validate("Salesperson Code", TempSalesHeader."Salesperson Code");
                        SalesHeader."Your Reference" := TempSalesHeader."Your Reference";
                        SalesHeader."Posting No." := TempSalesHeader."Posting No.";
                        SalesHeader.Modify(true);

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            SalesHeaderRecRef.GetTable(SalesHeader);
                            EDIMessageLine."Record-ID" := SalesHeaderRecRef.RecordId;
                            EDIMessageLine."Document Status" := EDIMessageLine."Document Status"::Processed;
                            EDIMessageLine.Modify();
                        end;

                        NoOfDocuments := NoOfDocuments - 1;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;

        SalesHeaderRecRef.Close();
    end;

    local procedure ProcessHDR03(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        TempSalesHeader: Record "Sales Header" temporary;
        ShipToAddress: Record "Ship-to Address";
        TempShipToAddress: Record "Ship-to Address" temporary;
        SalesHeaderRecRef: RecordRef;
        ImportDocumentType: Option " ","Order","Return Order";
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        SalesHeaderRecRef.Open(Database::"Sales Header", false, CompanyName);

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                3:
                    begin
                        Clear(TempSalesHeader);
                        TempSalesHeader."Posting Date" := GetDate(EDIMessageLineDetail2.Content);
                    end;
                4:
                    begin
                        // RZWPT - Create Orders or Return Orders...
                        //TmpSalesHeader."Document Type" := GetInteger(Content) + 1;
                        ImportDocumentType := GetInteger(EDIMessageLineDetail2.Content);
                        case ImportDocumentType of
                            ImportDocumentType::Order:
                                TempSalesHeader."Document Type" := TempSalesHeader."Document Type"::Order;
                            ImportDocumentType::"Return Order":
                                TempSalesHeader."Document Type" := TempSalesHeader."Document Type"::"Return Order";
                        end;
                        //RZWPT {*}
                    end;

                5:
                    begin
                        TempSalesHeader."No." := EDIMessageLineDetail2.Content;
                        TempSalesHeader."Posting No." := EDIMessageLineDetail2.Content;
                    end;
                6:
                    begin
                        if EDISetup."Remove Leading Zeros" then
                            EDIMessageLineDetail2.Content := DelChr(EDIMessageLineDetail2.Content, '<', '0');
                        TempSalesHeader."Sell-to Customer No." := EDIMessageLineDetail2.Content;
                    end;
                7:
                    TempSalesHeader."Your Reference" := EDIMessageLineDetail2.Content;
                8:
                    begin
                        TempSalesHeader."Currency Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Clear LCY from Currency Codes" and (TempSalesHeader."Currency Code" = GLSetup."LCY Code") then
                            TempSalesHeader."Currency Code" := '';
                    end;
                10:
                    begin
                        TempSalesHeader."Salesperson Code" := EDIMessageLineDetail2.Content;
                        if EDISetup."Remove Leading Zeros" then
                            TempSalesHeader."Salesperson Code" := DelChr(TempSalesHeader."Salesperson Code", '<', '0');
                    end;
                11:
                    TempSalesHeader."Due Date" := GetDate(EDIMessageLineDetail2.Content);
                12:
                    TempSalesHeader."Pmt. Discount Date" := GetDate(EDIMessageLineDetail2.Content);
                13:
                    TempSalesHeader."Payment Discount %" := GetDecimal(EDIMessageLineDetail2.Content);
                14:
                    TempSalesHeader."Document Date" := GetDate(EDIMessageLineDetail2.Content);
                15:
                    TempSalesHeader."Payment Method Code" := EDIMessageLineDetail2.Content;
                16:
                    TempSalesHeader."ABS Order Reference" := EDIMessageLineDetail2.Content;
                17:
                    begin
                        TempSalesHeader."Ship-to Name" := EDIMessageLineDetail2.Content;
                        TempShipToAddress.Name := TempSalesHeader."Ship-to Name";
                    end;
                18:
                    begin
                        TempSalesHeader."Ship-to Name 2" := EDIMessageLineDetail2.Content;
                        TempShipToAddress."Name 2" := TempSalesHeader."Ship-to Name 2";
                    end;
                19:
                    begin
                        TempSalesHeader."Ship-to Address" := EDIMessageLineDetail2.Content;
                        TempShipToAddress.Address := TempSalesHeader."Ship-to Address";
                    end;
                20:
                    begin
                        TempSalesHeader."Ship-to Address 2" := EDIMessageLineDetail2.Content;
                        TempShipToAddress."Address 2" := TempSalesHeader."Ship-to Address 2";
                    end;
                21:
                    begin
                        TempSalesHeader."Ship-to Post Code" := EDIMessageLineDetail2.Content;
                        TempShipToAddress."Post Code" := TempSalesHeader."Ship-to Post Code";
                    end;
                22:
                    begin
                        TempSalesHeader."Ship-to City" := EDIMessageLineDetail2.Content;
                        TempShipToAddress.City := TempSalesHeader."Ship-to City";
                    end;
                23:
                    ;
                // no longer in use
                24:
                    ;
                // no longer in use
                25:
                    TempSalesHeader."Location Code" := EDIMessageLineDetail2.Content;
                // ???
                26:
                    TempSalesHeader."Payment Terms Code" := EDIMessageLineDetail2.Content;
                27:
                    TempSalesHeader."Shipment Method Code" := EDIMessageLineDetail2.Content;
                28:
                    begin
                        TempSalesHeader."Shipping Agent Code" := EDIMessageLineDetail2.Content;
                        TempShipToAddress."Shipping Agent Code" := TempSalesHeader."Shipping Agent Code";
                    end;

                29:
                    begin
                        // finalize shipping data
                        if EDIMessageLineDetail2.Content <> '' then begin
                            TempSalesHeader."Ship-to Code" := EDIMessageLineDetail2.Content;
                            TempShipToAddress."Customer No." := TempSalesHeader."Sell-to Customer No.";
                            TempShipToAddress.Code := TempSalesHeader."Ship-to Code";
                            if not ShipToAddress.Get(TempShipToAddress."Customer No.", TempShipToAddress.Code) then begin
                                ShipToAddress := TempShipToAddress;
                                ShipToAddress."Tax Liable" := true;
                                ShipToAddress.Insert();
                            end else begin
                                ShipToAddress.Name := TempShipToAddress.Name;
                                ShipToAddress."Name 2" := TempShipToAddress."Name 2";
                                ShipToAddress.Address := TempShipToAddress.Address;
                                ShipToAddress."Address 2" := TempShipToAddress."Address 2";
                                ShipToAddress.City := TempShipToAddress.City;
                                ShipToAddress."Post Code" := TempShipToAddress."Post Code";
                                ShipToAddress."Shipment Method Code" := TempShipToAddress."Shipment Method Code";
                                ShipToAddress."Shipping Agent Code" := TempShipToAddress."Shipping Agent Code";
                                ShipToAddress.Modify();
                            end;
                        end;
                        // All necessary fields are populated, create Sales Header
                        SalesHeader.SetHideValidationDialog(true);

                        Clear(SalesHeader);
                        SalesHeader."Document Type" := TempSalesHeader."Document Type";
                        SalesHeader.Validate("No.", TempSalesHeader."No.");
                        SalesHeader.Insert(true);

                        SalesHeader.SetHideValidationDialog(true);
                        SalesHeader.Validate("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");
                        SalesHeader.Validate("Posting Date", TempSalesHeader."Posting Date");
                        SalesHeader.Validate("Document Date", TempSalesHeader."Document Date");
                        SalesHeader.Validate("Payment Method Code", TempSalesHeader."Payment Method Code");
                        SalesHeader.Validate("Due Date", TempSalesHeader."Due Date");
                        SalesHeader."Prices Including VAT" := false;

                        if TempSalesHeader."Document Type" = TempSalesHeader."Document Type"::Order then begin
                            SalesHeader.Validate("Pmt. Discount Date", TempSalesHeader."Pmt. Discount Date");
                            SalesHeader.Validate("Payment Discount %", TempSalesHeader."Payment Discount %")
                        end;
                        SalesHeader.Validate("Currency Code", TempSalesHeader."Currency Code");
                        SalesHeader.Validate("Salesperson Code", TempSalesHeader."Salesperson Code");
                        SalesHeader."Your Reference" := TempSalesHeader."Your Reference";
                        SalesHeader."Posting No." := TempSalesHeader."Posting No.";

                        SalesHeader."ABS Order Reference" := "ABS Order Reference";

                        if TempSalesHeader."Ship-to Code" <> '' then
                            SalesHeader.Validate("Ship-to Code", TempSalesHeader."Ship-to Code")
                        else begin
                            if TempSalesHeader."Ship-to Name" <> '' then
                                SalesHeader."Ship-to Name" := TempSalesHeader."Ship-to Name";
                            if TempSalesHeader."Ship-to Name 2" <> '' then
                                SalesHeader."Ship-to Name 2" := TempSalesHeader."Ship-to Name 2";
                            if TempSalesHeader."Ship-to Address" <> '' then
                                SalesHeader."Ship-to Address" := TempSalesHeader."Ship-to Address";
                            if TempSalesHeader."Ship-to Address 2" <> '' then
                                SalesHeader."Ship-to Address 2" := TempSalesHeader."Ship-to Address 2";
                            if TempSalesHeader."Ship-to Post Code" <> '' then
                                SalesHeader."Ship-to Post Code" := TempSalesHeader."Ship-to Post Code";
                            if TempSalesHeader."Ship-to City" <> '' then
                                SalesHeader."Ship-to City" := TempSalesHeader."Ship-to City";
                        end;
                        //IF "Location Code" <> '' THEN
                        //  SalesHeader.VALIDATE("Location Code","Location Code"); // ???
                        if TempSalesHeader."Payment Terms Code" = '' then
                            TempSalesHeader."Payment Terms Code" := EDISetup."Default Payment Terms Code";
                        SalesHeader.Validate("Payment Terms Code");

                        if TempSalesHeader."Shipment Method Code" <> '' then
                            SalesHeader.Validate("Shipment Method Code", TempSalesHeader."Shipment Method Code");

                        SalesHeader.Modify(true);

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            SalesHeaderRecRef.GetTable(SalesHeader);
                            EDIMessageLine."Record-ID" := SalesHeaderRecRef.RecordId;
                            EDIMessageLine."Document Status" := EDIMessageLine."Document Status"::Processed;
                            EDIMessageLine.Modify();
                        end;

                        NoOfDocuments := NoOfDocuments - 1;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;

        SalesHeaderRecRef.Close();
    end;

    local procedure ProcessLIN01(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
        TempSalesLine: Record "Sales Line" temporary;
        TmpItemRecognitionCode: Code[10];
        TmpVATRecognitionCode: Code[10];
        Sign: Integer;
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                2:
                    begin
                        TmpItemRecognitionCode := EDIMessageLineDetail2.Content;
                        if TmpItemRecognitionCode = '' then
                            TmpItemRecognitionCode := EDISetup."Def. Item Recognition Code";
                    end;
                3:
                    begin
                        TmpVATRecognitionCode := EDIMessageLineDetail2.Content;
                        if TmpVATRecognitionCode = '' then
                            TmpVATRecognitionCode := EDISetup."Def. VAT Recognition Code";
                    end;
                4:
                    TempSalesLine.Description := EDIMessageLineDetail2.Content;
                5:
                    begin
                        Sign := 1;
                        if EDIMessageLineDetail2.Content = '-' then
                            Sign := -1;
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                            Sign := -Sign;
                    end;
                6:
                    TempSalesLine."Unit Price" := GetDecimal(EDIMessageLineDetail2.Content);
                7:
                    begin
                        ABSRecognitionSetup.Get(TmpItemRecognitionCode, TmpVATRecognitionCode);
                        if ABSRecognitionSetup."Payment Discount" then begin
                            SalesHeader.TestField("Payment Discount %");
                        end else begin
                            Clear(SalesLine);
                            SalesLine."Document Type" := SalesHeader."Document Type";
                            SalesLine."Document No." := SalesHeader."No.";
                            SalesLine."Line No." := GetNextLineNo();
                            SalesLine.Insert();

                            SalesLine.Validate(Type, ABSRecognitionSetup.Type);
                            SalesLine.Validate("No.", ABSRecognitionSetup."No.");
                            SalesLine.Validate(Quantity, 1);
                            SalesLine.Description := TempSalesLine.Description;
                            SalesLine.Validate("Unit Price", Sign * TempSalesLine."Unit Price");
                            SalesLine.Validate("Gen. Prod. Posting Group", ABSRecognitionSetup."Gen. Prod. Posting Group");
                            SalesLine.Validate("VAT Prod. Posting Group", ABSRecognitionSetup."VAT Prod. Posting Group");
                            SalesLine.Modify();
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;
    end;

    local procedure ProcessLIN06(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
        TempSalesLine: Record "Sales Line" temporary;
        TempItemRecognitionCode: Code[10];
        TempVATRecognitionCode: Code[10];
        Sign: Integer;
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                2:
                    begin
                        TempItemRecognitionCode := EDIMessageLineDetail2.Content;
                        if TempItemRecognitionCode = '' then
                            TempItemRecognitionCode := EDISetup."Def. Item Recognition Code";
                    end;
                3:
                    begin
                        TempVATRecognitionCode := EDIMessageLineDetail2.Content;
                        if TempVATRecognitionCode = '' then
                            TempVATRecognitionCode := EDISetup."Def. VAT Recognition Code";
                    end;
                4:
                    TempSalesLine.Description := EDIMessageLineDetail2.Content;
                5:
                    begin
                        Sign := 1;
                        if EDIMessageLineDetail2.Content = '-' then
                            Sign := -1;
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                            Sign := -Sign;
                    end;
                6:
                    TempSalesLine."Unit Price" := GetDecimal(EDIMessageLineDetail2.Content);
                7:
                    begin
                        ABSRecognitionSetup.Get(TempItemRecognitionCode, TempVATRecognitionCode);
                        if ABSRecognitionSetup."Payment Discount" then begin
                            SalesHeader.TestField("Payment Discount %");
                        end else begin
                            Clear(SalesLine);
                            SalesLine."Document Type" := SalesHeader."Document Type";
                            SalesLine."Document No." := SalesHeader."No.";
                            SalesLine."Line No." := GetNextLineNo();
                            SalesLine.Insert();

                            SalesLine.Validate(Type, ABSRecognitionSetup.Type);
                            SalesLine.Validate("No.", ABSRecognitionSetup."No.");
                            SalesLine.Validate(Quantity, 1);
                            if TempSalesLine.Description <> '' then
                                SalesLine.Description := TempSalesLine.Description;
                            SalesLine.Validate("Unit Price", Sign * TempSalesLine."Unit Price");
                            SalesLine.Validate("Gen. Prod. Posting Group", ABSRecognitionSetup."Gen. Prod. Posting Group");
                            SalesLine.Validate("VAT Prod. Posting Group", ABSRecognitionSetup."VAT Prod. Posting Group");
                            SalesLine.Modify();
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;
    end;

    local procedure ProcessLIN08(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
        TempSalesLine: Record "Sales Line" temporary;
        TmpItemRecognitionCode: Code[10];
        TmpVATRecognitionCode: Code[10];
        CountryOfOriginCode: Code[10];
        TempDescription: array[2] of Text;
        Sign: Integer;
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        Clear(TempDescription);

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                2:
                    begin
                        TmpItemRecognitionCode := EDIMessageLineDetail2.Content;
                        if TmpItemRecognitionCode = '' then
                            TmpItemRecognitionCode := EDISetup."Def. Item Recognition Code";
                    end;
                3:
                    begin
                        TmpVATRecognitionCode := EDIMessageLineDetail2.Content;
                        if TmpVATRecognitionCode = '' then
                            TmpVATRecognitionCode := EDISetup."Def. VAT Recognition Code";
                    end;
                5:
                    begin
                        Sign := 1;
                        if EDIMessageLineDetail2.Content = '-' then
                            Sign := -1;
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                            Sign := -Sign;
                    end;
                6:
                    TempSalesLine.Amount := GetDecimal(EDIMessageLineDetail2.Content);
                7:
                    ;
                8:
                    TempSalesLine.Quantity := GetDecimal(EDIMessageLineDetail2.Content);
                9:
                    TempSalesLine."Unit of Measure Code" := EDIMessageLineDetail2.Content;
                10:
                    TempSalesLine."Unit Price" := GetDecimal(EDIMessageLineDetail2.Content);
                11:
                    TempDescription[1] := EDIMessageLineDetail2.Content;
                12:
                    CountryOfOriginCode := EDIMessageLineDetail2.Content;
                13:
                    ;
                14:
                    TempSalesLine."Lot No." := EDIMessageLineDetail2.Content;
                // TempDescription[2] := Content;
                15:
                    begin
                        TempSalesLine."No." := EDIMessageLineDetail2.Content;
                        if TempDescription[1] <> '' then
                            TempSalesLine.Description := CopyStr(TempDescription[1], 1, MaxStrLen(TempSalesLine.Description));
                        if TempDescription[2] <> '' then
                            TempSalesLine."Description 2" := CopyStr(TempDescription[2], 1, MaxStrLen(TempSalesLine."Description 2"));

                        ABSRecognitionSetup.Get(TmpItemRecognitionCode, TmpVATRecognitionCode);
                        UpdateItem(TempSalesLine, ABSRecognitionSetup, CountryOfOriginCode);

                        if ABSRecognitionSetup."Payment Discount" then
                            SalesHeader.TestField("Payment Discount %")
                        else begin
                            Clear(SalesLine);
                            SalesLine."Document Type" := SalesHeader."Document Type";
                            SalesLine."Document No." := SalesHeader."No.";
                            SalesLine."Line No." := GetNextLineNo();
                            SalesLine.Insert();

                            if TempSalesLine."No." = '' then begin
                                SalesLine.Validate(Type, ABSRecognitionSetup.Type);
                                SalesLine.Validate("No.", ABSRecognitionSetup."No.");
                            end else begin
                                SalesLine.Validate(Type, SalesLine.Type::Item);
                                SalesLine.Validate("No.", TempSalesLine."No.");
                                if ABSRecognitionSetup.Type = ABSRecognitionSetup.Type::"G/L Account" then
                                    SalesLine."ABS Sales Account" := ABSRecognitionSetup."No.";
                            end;

                            if SalesLine.Type = SalesLine.Type::Item then begin
                                if (TempSalesLine.Quantity = 0) and (TempSalesLine."Unit Price" = 0) and (TempSalesLine.Amount <> 0) then begin
                                    TempSalesLine.Quantity := 1;
                                    TempSalesLine."Unit Price" := TempSalesLine.Amount;
                                end;
                                SalesLine.Validate(Quantity, TempSalesLine.Quantity);
                                SalesLine.Validate("Unit of Measure Code", TempSalesLine."Unit of Measure Code");
                            end else
                                SalesLine.Validate(Quantity, 1);

                            SalesLine.Description := TempSalesLine.Description;
                            if TempSalesLine."Description 2" <> '' then
                                SalesLine."Description 2" := TempSalesLine."Description 2";

                            SalesLine.Validate("Unit Price", Sign * TempSalesLine."Unit Price");
                            if TempSalesLine.Amount <> 0 then
                                SalesLine.Validate(Amount, TempSalesLine.Amount);

                            SalesLine.Validate("Gen. Prod. Posting Group", ABSRecognitionSetup."Gen. Prod. Posting Group");
                            SalesLine.Validate("VAT Prod. Posting Group", ABSRecognitionSetup."VAT Prod. Posting Group");

                            SalesLine."Lot No." := "Lot No.";
                            SalesLine."ABS Delivery No." := "ABS Delivery No.";
                            SalesLine."ABS Shipment Date" := "ABS Shipment Date";
                            SalesLine.Modify();
                            // If Line Amount is zero for an Item Line, then create an additonal text line
                            if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."No." <> '') and (TempSalesLine.Amount = 0) then
                                CreateAdditonalLine(SalesLine."Line No.", EmptyTextLine);
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;
    end;

    local procedure ProcessFTR01(var EDIMessageLineDetail: Record "RZW EDI Message Line")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line";
        EDIMessageLine: Record "RZW EDI Message Line";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        TotalAmtExclVAT: Decimal;
        TotalAmtInclVAT: Decimal;
        Sign: Integer;
    begin
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        repeat
            CurrentEntryNo := EDIMessageLineDetail2."Line No.";
            CurrentFieldNo := "Field No.";

            case "Field No." of
                2:
                    begin
                        Sign := 1;
                        if Content = '-' then
                            Sign := -1;
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                            Sign := -Sign;
                    end;
                3:
                    TotalAmtExclVAT := GetDecimal(Content);
                4:
                    begin
                        // Create a correction line when VAT calculation differences occur
                        TotalAmtInclVAT := GetDecimal(Content);

                        ReleaseSalesDocument.Run(SalesHeader);
                        SalesHeader.CalcFields("Amount Including VAT");
                        if Round(SalesHeader."Amount Including VAT", 0.01) <> Round(TotalAmtInclVAT, 0.01) then begin
                            SalesLine.Init();
                            SalesLine."Document Type" := SalesHeader."Document Type";
                            SalesLine."Document No." := SalesHeader."No.";
                            SalesLine."Line No." := GetNextLineNo();
                            SalesLine.Insert();

                            SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
                            SalesLine.Validate("No.", EDISetup."VAT Correction Account G/L");
                            SalesLine.Description := Text030;
                            SalesLine.Validate(Quantity, 1);
                            SalesLine.Validate("Unit Price", TotalAmtInclVAT - SalesHeader."Amount Including VAT");
                            SalesLine.Modify();
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;
    end;

    local procedure GetDate(UseText: Text): Date
    var
        D: Integer;
        M: Integer;
        Y: Integer;
        OK: Boolean;
    begin
        if (UseText = '00000000') or (UseText = '') then
            exit(0D);

        Evaluate(D, CopyStr(UseText, 1, 2));
        Evaluate(M, CopyStr(UseText, 3, 2));
        Evaluate(Y, CopyStr(UseText, 5, 4));
        exit(DMY2Date(D, M, Y));
    end;

    local procedure GetDateTimeFromText(DateTimeText: Text; DateFormat: Code[3]): DateTime
    begin
    end;

    local procedure GetDateTime(DateTimeText: Text; DateTimeFormat: Code[3]): DateTime
    var
        Y: Integer;
        M: Integer;
        D: Integer;
        NewDate: Date;
        NewTime: Time;
    begin
        case DateTimeFormat of
            '102':
                begin
                    Evaluate(Y, CopyStr(DateTimeText, 1, 4));
                    Evaluate(M, CopyStr(DateTimeText, 5, 2));
                    Evaluate(D, CopyStr(DateTimeText, 7, 2));
                    NewDate := DMY2Date(D, M, Y);
                    NewTime := 0T;
                    exit(CreateDateTime(NewDate, NewTime));
                end;
        end;
    end;

    local procedure GetInteger(IntegerText: Text) ReturnInteger: Integer
    begin
        Evaluate(ReturnInteger, IntegerText);
    end;

    local procedure GetDecimal(DecimalText: Text) ReturnDecimal: Decimal
    var
        Fraction: Decimal;
        Position: Integer;
    begin
        DecimalText := ConvertStr(DecimalText, '.', ',');
        Evaluate(ReturnDecimal, DecimalText);
    end;

    internal procedure GetLastError(var NewCurrentEntryNo: Integer; var NewCurrentFieldNo: Integer)
    begin
        NewCurrentEntryNo := CurrentEntryNo;
        NewCurrentFieldNo := CurrentFieldNo;
    end;

    local procedure GetNextLineNo(): Integer
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader."No.");
        if SalesLine2.FindLast() then
            exit(SalesLine2."Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure UpdateItem(var TempSalesLine: Record "Sales Line"; ABSRecognitionSetup: Record "RZW ABS Recognition Setup"; CountryOfOriginCode: Code[10])
    var
        Item: Record Item;
        UOM: Record "Unit of Measure";
        ItemUOM: Record "Item Unit of Measure";
        ItemCat: Record "Item Category";
        NewItem: Boolean;
    begin
        if TempSalesLine."No." = '' then
            exit;

        if not UOM.Get(TempSalesLine."Unit of Measure Code") then begin
            UOM.Init();
            UOM.Code := TempSalesLine."Unit of Measure Code";
            UOM.Description := UOM.Code;
            UOM.Insert();
        end;

        if not ItemUOM.Get(TempSalesLine."No.", UOM.Code) then begin
            ItemUOM.Init();
            ItemUOM."Item No." := TempSalesLine."No.";
            ItemUOM.Code := UOM.Code;
            ItemUOM."Qty. per Unit of Measure" := 1;
            ItemUOM.Insert();
        end;

        if not Item.Get(TempSalesLine."No.") then begin
            Item.Init();
            NewItem := true;
            Item."No." := TempSalesLine."No.";
            Item."Base Unit of Measure" := UOM.Code;
            Item."Sales Unit of Measure" := Item."Base Unit of Measure";
            Item."Purch. Unit of Measure" := Item."Base Unit of Measure";
            Item.Type := Item.Type::Service;
            Item.Insert();
        end;
        // RZWPT - When item fields are validated, a check is executed which prevents any modifications when entries are present...
        //VALIDATE(Description,COPYSTR(TempSalesLine.Description,1,MAXSTRLEN(Description)));
        Item.Description := CopyStr(TempSalesLine.Description, 1, MaxStrLen(Item.Description));
        if NewItem then
            Item.Validate(Description);
        // RZWPT {*}
        Item."Description 2" := CopyStr(TempSalesLine.Description, MaxStrLen(Item.Description) + 1, MaxStrLen(Item."Description 2"));

        if Item."Gen. Prod. Posting Group" = '' then
            Item."Gen. Prod. Posting Group" := ABSRecognitionSetup."Gen. Prod. Posting Group";
        if Item."VAT Prod. Posting Group" = '' then
            Item."VAT Prod. Posting Group" := ABSRecognitionSetup."VAT Prod. Posting Group";
        // RZWPT
        if NewItem then begin
            Item."Costing Method" := ABSRecognitionSetup."Def. Costing Method";
            Item."Inventory Posting Group" := ABSRecognitionSetup."Def. Inventory Posting Group";
        end;
        if CountryOfOriginCode <> '' then
            Item."Country/Region of Origin Code" := CountryOfOriginCode;
        // RZWPT {*}
        Item.Modify();
    end;

    internal procedure ChangeSalesDocStatus(SalesHeader: Record "Sales Header"; NewDocumentStatus: Option " ,Processed,Posted,Deleted")
    var
        EDIMessageLine: Record "RZW EDI Message Line";
        SalesHeaderRecRef: RecordRef;
    begin
        SalesHeaderRecRef.GetTable(SalesHeader);

        EDIMessageLine.SetCurrentKey("Document Status", "Record-ID");
        EDIMessageLine.SetRange("Document Status", EDIMessageLine."Document Status"::Processed);
        EDIMessageLine.SetRange("Record-ID", SalesHeaderRecRef.RecordId);
        if not EDIMessageLine.FindFirst() then
            exit;
        EDIMessageLine."Document Status" := NewDocumentStatus;
        EDIMessageLine.Modify();
    end;

    internal procedure CreateAdditonalLine(AttachedToLineNo: Integer; UseText: Text[50])
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := GetNextLineNo();
        SalesLine.Description := UseText;
        SalesLine."Attached to Line No." := AttachedToLineNo;
        SalesLine.Insert();
    end;
}

