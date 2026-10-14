namespace RZW;

using Microsoft.Finance.GeneralLedger.Setup;
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

        CustRecRef.OPEN(Database::Customer, false, CompanyName);

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

        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            CustBankRecRef.OPEN(Database::"Customer Bank Account", false, CompanyName);

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    3:
                        begin
                            if EDISetup."Remove Leading Zeros" then
                                Content := DELCHR(Content, '<', '0');
                            TempCustNo := Content;
                        end;
                    4:
                        begin
                            TempBankCode := COPYSTR(Content, 1, MAXSTRLEN(CustBankAccount.Code));
                            if not CustBankAccount.GET(TempCustNo, TempBankCode) then begin
                                CustBankAccount.INIT;
                                CustBankAccount."Customer No." := TempCustNo;
                                CustBankAccount.Code := TempBankCode;
                                CustBankAccount.INSERT;
                                CustBankAccount."Bank Account No." := Content;
                            end;
                        end;
                    6:
                        CustBankAccount.Name := Content;
                    7:
                        CustBankAccount.Address := Content;
                    8:
                        CustBankAccount."Post Code" := Content;
                    9:
                        CustBankAccount.City := Content;
                    10:
                        CustBankAccount.County := Content;
                    11:
                        CustBankAccount."Country/Region Code" := Content;
                    12:// Bank Account Bank (ES and PT)
                       // RZWPT
                        begin
                            CustBankAccount."IBAN - Bank Account No." := COPYSTR(Content, 1, 4);
                            CustBankAccount."IBAN - Bank Branch No." := COPYSTR(Content, 5, 4);
                            CustBankAccount."IBAN - Check Digits" := COPYSTR(Content, 9, 2);
                            CustBankAccount."NIB - Bank Identification No." :=
                              COPYSTR(Content, 1, 10) + COPYSTR(CustBankAccount."IBAN - Bank Account No.", 1, 10);

                            // Save bank account record
                            CustBankAccount.MODIFY;

                            if EDIMessageLine.GET("EDI Message Type", "Run No.", "Line No.") then begin
                                CustBankRecRef.GETTABLE(CustBankAccount);
                                EDIMessageLine."Record-ID" := CustBankRecRef.RecordId;
                                EDIMessageLine.MODIFY;
                            end;
                        end;
                    // RZWPT {*}
                    13:
                        ;// Transit
                    14:
                        ; // Bank Branch office No. (IT = ABI/CAB Nos.)
                end;
            until NEXT = 0;
            CustBankRecRef.Close();
        end;
    end;

    local procedure ProcessLIN11(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        Cust: Record "Customer";
        CustRecRef: RecordRef;
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            CustRecRef.OPEN(Database::Customer, false, CompanyName);

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    3:
                        begin
                            if EDISetup."Remove Leading Zeros" then
                                Content := DELCHR(Content, '<', '0');

                            if not Cust.GET(Content) then begin
                                Cust.INIT;
                                Cust."No." := Content;
                                Cust.INSERT;
                            end;
                        end;
                    4:
                        Cust.Name := Content;
                    5:
                        Cust."Name 2" := Content;
                    6:
                        Cust."Search Name" := Content;
                    7:
                        Cust.Address := Content;
                    8:
                        Cust."Address 2" := Content;
                    9:
                        Cust."Post Code" := Content;
                    10:
                        Cust.City := Content;
                    11:
                        Cust.County := Content;
                    12:
                        Cust.VALIDATE("Country/Region Code", Content);
                    13:
                        Cust.Contact := Content;
                    14:
                        Cust."Phone No." := Content;
                    15:
                        Cust."Fax No." := Content;
                    16:
                        Cust."Telex No." := Content;
                    17:
                        Cust."E-Mail" := Content;
                    18:
                        Cust."Home Page" := Content;
                    19:
                        Cust."Territory Code" := Content;
                    20:
                        Cust."Credit Limit (LCY)" := GetDecimal(Content);
                    21:
                        begin
                            Cust."Customer Posting Group" := Content;
                            if Cust."Customer Posting Group" = '' then
                                Cust."Customer Posting Group" := EDISetup."Def. Customer Posting Group";
                            Cust.VALIDATE("Customer Posting Group");
                        end;
                    22:
                        begin
                            Cust."Currency Code" := Content;
                            if EDISetup."Clear LCY from Currency Codes" and (Cust."Currency Code" = GLSetup."LCY Code") then
                                Cust."Currency Code" := '';
                            Cust.VALIDATE("Currency Code");
                        end;
                    23:
                        Cust.VALIDATE("Language Code", Content);
                    24:
                        Cust.VALIDATE("Payment Terms Code", Content);
                    25:
                        Cust.VALIDATE("Shipment Method Code", Content);
                    26:
                        Cust.VALIDATE("Payment Method Code", Content);
                    27:
                        Cust.VALIDATE("Fin. Charge Terms Code", Content);
                    28:
                        Cust.VALIDATE("Reminder Terms Code", Content);
                    29:
                        begin
                            Cust."Salesperson Code" := Content;
                            if EDISetup."Remove Leading Zeros" then
                                Cust."Salesperson Code" := DELCHR(Cust."Salesperson Code", '<', '0');
                            Cust.VALIDATE("Salesperson Code");
                        end;
                    30:
                        case GetInteger(Content) of
                            0:
                                Cust.Blocked := Cust.Blocked::" ";
                            1:
                                Cust.Blocked := Cust.Blocked::All;
                        end;
                    31:
                        Cust."VAT Registration No." := Content;
                    32:
                        begin
                            Cust."Gen. Bus. Posting Group" := Content;
                            if Cust."Gen. Bus. Posting Group" = '' then
                                Cust."Gen. Bus. Posting Group" := EDISetup."Def. Gen. Bus. Posting Group";
                            Cust.VALIDATE("Gen. Bus. Posting Group");
                        end;
                    33:
                        begin
                            Cust."VAT Bus. Posting Group" := Content;
                            if Cust."VAT Bus. Posting Group" = '' then
                                Cust."VAT Bus. Posting Group" := EDISetup."Def. VAT Bus. Posting Group";
                            Cust.VALIDATE("VAT Bus. Posting Group");
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
                            Cust.MODIFY;

                            if EDIMessageLine.GET("EDI Message Type", "Run No.", "Line No.") then begin
                                CustRecRef.GETTABLE(Cust);
                                EDIMessageLine."Record-ID" := CustRecRef.RecordId;
                                EDIMessageLine.MODIFY;
                            end;
                        end;
                end;
            until NEXT = 0;

            CustRecRef.Close();
        end;
    end;

    local procedure ProcessVendor()
    var
        EDIMessageLineDetail: Record "90012";
    begin
        with EDIMessageLineDetail do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Field No.", 1);
            if not FINDSET then
                Error(Text001);

            EDISetup.TestImportVend();

            repeat
                case Content of
                    'LIN03':
                        ProcessLIN03(EDIMessageLineDetail);
                    'LIN05':
                        ProcessLIN05(EDIMessageLineDetail);
                end;
            until NEXT = 0;
        end;
    end;

    local procedure ProcessLIN03(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        Vend: Record "Vendor";
        VendRecRef: RecordRef;
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            VendRecRef.OPEN(Database::Vendor, false, CompanyName);

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    3:
                        begin
                            if EDISetup."Remove Leading Zeros" then
                                Content := DELCHR(Content, '<', '0');

                            if not Vend.GET(Content) then begin
                                Vend.INIT;
                                Vend."No." := Content;
                                Vend.INSERT;
                            end;
                        end;
                    4:
                        Vend.Name := Content;
                    5:
                        Vend."Name 2" := Content;
                    6:
                        Vend."Search Name" := Content;
                    7:
                        Vend.Address := Content;
                    8:
                        Vend."Address 2" := Content;
                    9:
                        Vend."Post Code" := Content;
                    10:
                        Vend.City := Content;
                    11:
                        Vend.County := Content;
                    12:
                        Vend.VALIDATE("Country/Region Code", Content);
                    13:
                        Vend.Contact := Content;
                    14:
                        Vend."Phone No." := Content;
                    15:
                        Vend."Fax No." := Content;
                    16:
                        Vend."Telex No." := Content;
                    17:
                        Vend."E-Mail" := Content;
                    18:
                        Vend."Home Page" := Content;
                    19:
                        Vend."Territory Code" := Content;
                    20:
                        begin
                            Vend."Vendor Posting Group" := Content;
                            if Vend."Vendor Posting Group" = '' then
                                Vend."Vendor Posting Group" := EDISetup."Def. Vendor Posting Group";
                            Vend.VALIDATE("Vendor Posting Group");
                        end;
                    21:
                        begin
                            Vend."Currency Code" := Content;
                            if EDISetup."Clear LCY from Currency Codes" and (Vend."Currency Code" = GLSetup."LCY Code") then
                                Vend."Currency Code" := '';
                            Vend.VALIDATE("Currency Code");
                        end;
                    22:
                        Vend.VALIDATE("Language Code", Content);
                    23:
                        Vend.VALIDATE("Payment Terms Code", Content);
                    24:
                        Vend.VALIDATE("Shipment Method Code", Content);
                    25:
                        Vend.VALIDATE("Payment Method Code", Content);
                    26:
                        Vend.VALIDATE("Fin. Charge Terms Code", Content);
                    27:
                        begin
                            Vend."Purchaser Code" := Content;
                            if EDISetup."Remove Leading Zeros" then
                                Vend."Purchaser Code" := DELCHR(Vend."Purchaser Code", '<', '0');
                            Vend.VALIDATE("Purchaser Code");
                        end;
                    28:
                        case GetInteger(Content) of
                            0:
                                Vend.Blocked := Vend.Blocked::" ";
                            1:
                                Vend.Blocked := Vend.Blocked::All;
                        end;
                    29:
                        Vend."VAT Registration No." := Content;
                    30:
                        begin
                            Vend."Gen. Bus. Posting Group" := Content;
                            if Vend."Gen. Bus. Posting Group" = '' then
                                Vend."Gen. Bus. Posting Group" := EDISetup."Def. Gen. Bus. Posting Group";
                            Vend.VALIDATE("Gen. Bus. Posting Group");
                        end;
                    31:
                        begin
                            Vend."VAT Bus. Posting Group" := Content;
                            if Vend."VAT Bus. Posting Group" = '' then
                                Vend."VAT Bus. Posting Group" := EDISetup."Def. VAT Bus. Posting Group";
                            Vend.VALIDATE("VAT Bus. Posting Group");
                        end;
                    33:
                        begin
                            Vend."Our Account No." := Content;
                            Vend."Last Date Modified" := Today;
                            Vend.MODIFY;

                            if EDIMessageLine.GET("EDI Message Type", "Run No.", "Line No.") then begin
                                VendRecRef.GETTABLE(Vend);
                                EDIMessageLine."Record-ID" := VendRecRef.RecordId;
                                EDIMessageLine.MODIFY;
                            end;
                        end;
                end;
            until NEXT = 0;

            VendRecRef.Close();
        end;
    end;

    local procedure ProcessLIN05(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        VendBankAccount: Record "Vendor Bank Account";
        VendBankRecRef: RecordRef;
        TempVendNo: Code[20];
        TempBankCode: Code[10];
    begin
        if EDISetup."Skip Bank Data in Import" then
            exit;

        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            VendBankRecRef.OPEN(Database::"Vendor Bank Account", false, CompanyName);

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    3:
                        begin
                            if EDISetup."Remove Leading Zeros" then
                                Content := DELCHR(Content, '<', '0');
                            TempVendNo := Content;
                        end;
                    4:
                        begin
                            TempBankCode := COPYSTR(Content, 1, MAXSTRLEN(VendBankAccount.Code));
                            if not VendBankAccount.GET(TempVendNo, TempBankCode) then begin
                                VendBankAccount.INIT;
                                VendBankAccount."Vendor No." := TempVendNo;
                                VendBankAccount.Code := TempBankCode;
                                VendBankAccount.INSERT;
                                VendBankAccount."Bank Account No." := Content;
                            end;
                        end;
                    6:
                        VendBankAccount.Name := Content;
                    7:
                        VendBankAccount.Address := Content;
                    8:
                        VendBankAccount."Post Code" := Content;
                    9:
                        VendBankAccount.City := Content;
                    10:
                        VendBankAccount.County := Content;
                    11:
                        begin
                            VendBankAccount."Country/Region Code" := Content;
                            VendBankAccount.MODIFY;

                            if EDIMessageLine.GET("EDI Message Type", "Run No.", "Line No.") then begin
                                VendBankRecRef.GETTABLE(VendBankAccount);
                                EDIMessageLine."Record-ID" := VendBankRecRef.RecordId;
                                EDIMessageLine.MODIFY;
                            end;
                        end;
                end;
            until NEXT = 0;

            VendBankRecRef.Close();
        end;
    end;

    local procedure ProcessSalesDocument()
    var
        EDIMessageLine: Record "90011";
        EDIMessageLineDetail: Record "90012";
    begin
        with EDIMessageLineDetail do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Field No.", 1);
            if not FINDSET then
                Error(Text001);

            EDISetup.TestImportSInv();

            repeat
                case Content of
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
            until NEXT = 0;

            // Check for correct number of documents
            if TestNoOfDocuments then
                if NoOfDocuments <> 0 then
                    Error(Text031);
        end;
    end;

    local procedure ProcessTOT01(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    2:
                        begin
                            NoOfDocuments := GetInteger(Content);
                            TestNoOfDocuments := true;
                        end;
                end;
            until NEXT = 0;
        end;
    end;

    local procedure ProcessHDR01(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        TmpSalesHeader: Record "Sales Header" temporary;
        SalesHeaderRecRef: RecordRef;
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            SalesHeaderRecRef.Open(Database::"Sales Header", false, CompanyName);

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    3:
                        begin
                            Clear(TmpSalesHeader);
                            TmpSalesHeader."Posting Date" := GetDate(Content);
                        end;
                    4:
                        TmpSalesHeader."Document Type" := GetInteger(Content) + 1;
                    5:
                        begin
                            TmpSalesHeader."No." := Content;
                            TmpSalesHeader."Posting No." := Content;
                        end;
                    6:
                        begin
                            if EDISetup."Remove Leading Zeros" then
                                Content := DELCHR(Content, '<', '0');
                            TmpSalesHeader."Sell-to Customer No." := Content;
                        end;
                    7:
                        TmpSalesHeader."Your Reference" := Content;
                    8:
                        begin
                            TmpSalesHeader."Currency Code" := Content;
                            if EDISetup."Clear LCY from Currency Codes" and (TmpSalesHeader."Currency Code" = GLSetup."LCY Code") then
                                TmpSalesHeader."Currency Code" := '';
                        end;
                    10:
                        begin
                            TmpSalesHeader."Salesperson Code" := Content;
                            if EDISetup."Remove Leading Zeros" then
                                TmpSalesHeader."Salesperson Code" := DelChr(TmpSalesHeader."Salesperson Code", '<', '0');
                        end;
                    11:
                        TmpSalesHeader."Due Date" := GetDate(Content);
                    12:
                        TmpSalesHeader."Pmt. Discount Date" := GetDate(Content);
                    13:
                        TmpSalesHeader."Payment Discount %" := GetDecimal(Content);
                    14:
                        TmpSalesHeader."Document Date" := GetDate(Content);
                    15:
                        begin
                            TmpSalesHeader."Payment Method Code" := Content;

                            // All necessary fields are populated, create Sales Header
                            with TmpSalesHeader do begin
                                Clear(SalesHeader);
                                SalesHeader.SetHideValidationDialog(true);

                                SalesHeader."Document Type" := "Document Type";
                                SalesHeader.Validate("No.", "No.");
                                SalesHeader.Insert(true);

                                SalesHeader.Validate("Sell-to Customer No.", "Sell-to Customer No.");
                                SalesHeader.Validate("Posting Date", "Posting Date");
                                if "Payment Terms Code" = '' then
                                    "Payment Terms Code" := EDISetup."Default Payment Terms Code";
                                SalesHeader.Validate("Payment Terms Code");

                                SalesHeader.Validate("Payment Method Code", "Payment Method Code");
                                SalesHeader.Validate("Due Date", "Due Date");

                                if "Document Type" = "Document Type"::Invoice then begin
                                    SalesHeader.Validate("Pmt. Discount Date", "Pmt. Discount Date");
                                    SalesHeader.Validate("Payment Discount %", "Payment Discount %")
                                end;
                                SalesHeader.Validate("Currency Code", "Currency Code");

                                SalesHeader.Validate("Salesperson Code", "Salesperson Code");
                                SalesHeader."Your Reference" := "Your Reference";
                                SalesHeader."Posting No." := TmpSalesHeader."Posting No.";
                                SalesHeader.Modify(true);

                                if EDIMessageLine.GET("EDI Message Type", "Run No.", "Line No.") then begin
                                    SalesHeaderRecRef.GetTable(SalesHeader);
                                    EDIMessageLine."Record-ID" := SalesHeaderRecRef.RecordId;
                                    EDIMessageLine."Document Status" := EDIMessageLine."Document Status"::Processed;
                                    EDIMessageLine.MODIFY;
                                end;

                                NoOfDocuments := NoOfDocuments - 1;
                            end;
                        end;
                end;
            until NEXT = 0;

            SalesHeaderRecRef.Close();
        end;
    end;

    local procedure ProcessHDR03(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        TmpSalesHeader: Record "Sales Header" temporary;
        ShipToAddress: Record "Ship-to Address";
        TempShipToAddress: Record "Ship-to Address";
        SalesHeaderRecRef: RecordRef;
        ImportDocumentType: Option " ","Order","Return Order";
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            SalesHeaderRecRef.Open(Database::"Sales Header", false, CompanyName);

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    3:
                        begin
                            Clear(TmpSalesHeader);
                            TmpSalesHeader."Posting Date" := GetDate(Content);
                        end;
                    4:
                        begin
                            // RZWPT - Create Orders or Return Orders...
                            //TmpSalesHeader."Document Type" := GetInteger(Content) + 1;
                            ImportDocumentType := GetInteger(Content);
                            case ImportDocumentType of
                                ImportDocumentType::Order:
                                    TmpSalesHeader."Document Type" := TmpSalesHeader."Document Type"::Order;
                                ImportDocumentType::"Return Order":
                                    TmpSalesHeader."Document Type" := TmpSalesHeader."Document Type"::"Return Order";
                            end;
                            //RZWPT {*}
                        end;

                    5:
                        begin
                            TmpSalesHeader."No." := Content;
                            TmpSalesHeader."Posting No." := Content;
                        end;
                    6:
                        begin
                            if EDISetup."Remove Leading Zeros" then
                                Content := DELCHR(Content, '<', '0');
                            TmpSalesHeader."Sell-to Customer No." := Content;
                        end;
                    7:
                        TmpSalesHeader."Your Reference" := Content;
                    8:
                        begin
                            TmpSalesHeader."Currency Code" := Content;
                            if EDISetup."Clear LCY from Currency Codes" and (TmpSalesHeader."Currency Code" = GLSetup."LCY Code") then
                                TmpSalesHeader."Currency Code" := '';
                        end;
                    10:
                        begin
                            TmpSalesHeader."Salesperson Code" := Content;
                            if EDISetup."Remove Leading Zeros" then
                                TmpSalesHeader."Salesperson Code" := DelChr(TmpSalesHeader."Salesperson Code", '<', '0');
                        end;
                    11:
                        TmpSalesHeader."Due Date" := GetDate(Content);
                    12:
                        TmpSalesHeader."Pmt. Discount Date" := GetDate(Content);
                    13:
                        TmpSalesHeader."Payment Discount %" := GetDecimal(Content);
                    14:
                        TmpSalesHeader."Document Date" := GetDate(Content);
                    15:
                        TmpSalesHeader."Payment Method Code" := Content;
                    16:
                        TmpSalesHeader."ABS Order Reference" := Content;
                    17:
                        begin
                            TmpSalesHeader."Ship-to Name" := Content;
                            TempShipToAddress.Name := TmpSalesHeader."Ship-to Name";
                        end;
                    18:
                        begin
                            TmpSalesHeader."Ship-to Name 2" := Content;
                            TempShipToAddress."Name 2" := TmpSalesHeader."Ship-to Name 2";
                        end;
                    19:
                        begin
                            TmpSalesHeader."Ship-to Address" := Content;
                            TempShipToAddress.Address := TmpSalesHeader."Ship-to Address";
                        end;
                    20:
                        begin
                            TmpSalesHeader."Ship-to Address 2" := Content;
                            TempShipToAddress."Address 2" := TmpSalesHeader."Ship-to Address 2";
                        end;
                    21:
                        begin
                            TmpSalesHeader."Ship-to Post Code" := Content;
                            TempShipToAddress."Post Code" := TmpSalesHeader."Ship-to Post Code";
                        end;
                    22:
                        begin
                            TmpSalesHeader."Ship-to City" := Content;
                            TempShipToAddress.City := TmpSalesHeader."Ship-to City";
                        end;
                    23:
                        ; // no longer in use
                    24:
                        ; // no longer in use
                    25:
                        TmpSalesHeader."Location Code" := Content; // ???
                    26:
                        TmpSalesHeader."Payment Terms Code" := Content;
                    27:
                        TmpSalesHeader."Shipment Method Code" := Content;
                    28:
                        begin
                            TmpSalesHeader."Shipping Agent Code" := Content;
                            TempShipToAddress."Shipping Agent Code" := TmpSalesHeader."Shipping Agent Code";
                        end;

                    29:
                        begin
                            // finalize shipping data
                            if Content <> '' then begin
                                TmpSalesHeader."Ship-to Code" := Content;
                                TempShipToAddress."Customer No." := TmpSalesHeader."Sell-to Customer No.";
                                TempShipToAddress.Code := TmpSalesHeader."Ship-to Code";
                                if not ShipToAddress.GET(TempShipToAddress."Customer No.", TempShipToAddress.Code) then begin
                                    ShipToAddress := TempShipToAddress;
                                    ShipToAddress."Tax Liable" := true;
                                    ShipToAddress.INSERT;
                                end else begin
                                    ShipToAddress.Name := TempShipToAddress.Name;
                                    ShipToAddress."Name 2" := TempShipToAddress."Name 2";
                                    ShipToAddress.Address := TempShipToAddress.Address;
                                    ShipToAddress."Address 2" := TempShipToAddress."Address 2";
                                    ShipToAddress.City := TempShipToAddress.City;
                                    ShipToAddress."Post Code" := TempShipToAddress."Post Code";
                                    ShipToAddress."Shipment Method Code" := TempShipToAddress."Shipment Method Code";
                                    ShipToAddress."Shipping Agent Code" := TempShipToAddress."Shipping Agent Code";
                                    ShipToAddress.MODIFY;
                                end;
                            end;

                            // All necessary fields are populated, create Sales Header
                            with TmpSalesHeader do begin
                                SalesHeader.SetHideValidationDialog(true);

                                Clear(SalesHeader);
                                SalesHeader."Document Type" := "Document Type";
                                SalesHeader.Validate("No.", "No.");
                                SalesHeader.Insert(true);

                                SalesHeader.SetHideValidationDialog(true);
                                SalesHeader.Validate("Sell-to Customer No.", "Sell-to Customer No.");
                                SalesHeader.Validate("Posting Date", "Posting Date");
                                SalesHeader.Validate("Document Date", "Document Date");
                                SalesHeader.Validate("Payment Method Code", "Payment Method Code");
                                SalesHeader.Validate("Due Date", "Due Date");
                                SalesHeader."Prices Including VAT" := false;

                                if "Document Type" = "Document Type"::Order then begin
                                    SalesHeader.Validate("Pmt. Discount Date", "Pmt. Discount Date");
                                    SalesHeader.Validate("Payment Discount %", "Payment Discount %")
                                end;
                                SalesHeader.Validate("Currency Code", "Currency Code");
                                SalesHeader.Validate("Salesperson Code", "Salesperson Code");
                                SalesHeader."Your Reference" := "Your Reference";
                                SalesHeader."Posting No." := TmpSalesHeader."Posting No.";

                                SalesHeader."ABS Order Reference" := "ABS Order Reference";

                                if "Ship-to Code" <> '' then
                                    SalesHeader.Validate("Ship-to Code", "Ship-to Code")
                                else begin
                                    if "Ship-to Name" <> '' then
                                        SalesHeader."Ship-to Name" := "Ship-to Name";
                                    if "Ship-to Name 2" <> '' then
                                        SalesHeader."Ship-to Name 2" := "Ship-to Name 2";
                                    if "Ship-to Address" <> '' then
                                        SalesHeader."Ship-to Address" := "Ship-to Address";
                                    if "Ship-to Address 2" <> '' then
                                        SalesHeader."Ship-to Address 2" := "Ship-to Address 2";
                                    if "Ship-to Post Code" <> '' then
                                        SalesHeader."Ship-to Post Code" := "Ship-to Post Code";
                                    if "Ship-to City" <> '' then
                                        SalesHeader."Ship-to City" := "Ship-to City";
                                end;

                                //IF "Location Code" <> '' THEN
                                //  SalesHeader.VALIDATE("Location Code","Location Code"); // ???
                                if "Payment Terms Code" = '' then
                                    "Payment Terms Code" := EDISetup."Default Payment Terms Code";
                                SalesHeader.Validate("Payment Terms Code");

                                if "Shipment Method Code" <> '' then
                                    SalesHeader.Validate("Shipment Method Code", "Shipment Method Code");

                                SalesHeader.Modify(true);

                                if EDIMessageLine.GET("EDI Message Type", "Run No.", "Line No.") then begin
                                    SalesHeaderRecRef.GetTable(SalesHeader);
                                    EDIMessageLine."Record-ID" := SalesHeaderRecRef.RecordId;
                                    EDIMessageLine."Document Status" := EDIMessageLine."Document Status"::Processed;
                                    EDIMessageLine.MODIFY;
                                end;

                                NoOfDocuments := NoOfDocuments - 1;
                            end;
                        end;
                end;
            until NEXT = 0;

            SalesHeaderRecRef.Close();
        end;
    end;

    local procedure ProcessLIN01(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        ABSRecognitionSetup: Record "90016";
        TmpSalesLine: Record "Sales Line" temporary;
        TmpItemRecognitionCode: Code[10];
        TmpVATRecognitionCode: Code[10];
        Sign: Integer;
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    2:
                        begin
                            TmpItemRecognitionCode := Content;
                            if TmpItemRecognitionCode = '' then
                                TmpItemRecognitionCode := EDISetup."Def. Item Recognition Code";
                        end;
                    3:
                        begin
                            TmpVATRecognitionCode := Content;
                            if TmpVATRecognitionCode = '' then
                                TmpVATRecognitionCode := EDISetup."Def. VAT Recognition Code";
                        end;
                    4:
                        TmpSalesLine.Description := Content;
                    5:
                        begin
                            Sign := 1;
                            if Content = '-' then
                                Sign := -1;
                            if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                                Sign := -Sign;
                        end;
                    6:
                        TmpSalesLine."Unit Price" := GetDecimal(Content);
                    7:
                        begin
                            ABSRecognitionSetup.GET(TmpItemRecognitionCode, TmpVATRecognitionCode);
                            if ABSRecognitionSetup."Payment Discount" then begin
                                SalesHeader.TestField("Payment Discount %");
                            end else
                                with TmpSalesLine do begin
                                    Clear(SalesLine);
                                    SalesLine."Document Type" := SalesHeader."Document Type";
                                    SalesLine."Document No." := SalesHeader."No.";
                                    SalesLine."Line No." := GetNextLineNo();
                                    SalesLine.Insert();

                                    SalesLine.VALIDATE(Type, ABSRecognitionSetup.Type);
                                    SalesLine.VALIDATE("No.", ABSRecognitionSetup."No.");
                                    SalesLine.Validate(Quantity, 1);
                                    SalesLine.Description := Description;
                                    SalesLine.Validate("Unit Price", Sign * "Unit Price");
                                    SalesLine.VALIDATE("Gen. Prod. Posting Group", ABSRecognitionSetup."Gen. Prod. Posting Group");
                                    SalesLine.VALIDATE("VAT Prod. Posting Group", ABSRecognitionSetup."VAT Prod. Posting Group");
                                    SalesLine.Modify();
                                end;
                        end;
                end;
            until NEXT = 0;
        end;
    end;

    local procedure ProcessLIN06(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        ABSRecognitionSetup: Record "90016";
        TmpSalesLine: Record "Sales Line" temporary;
        TmpItemRecognitionCode: Code[10];
        TmpVATRecognitionCode: Code[10];
        Sign: Integer;
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    2:
                        begin
                            TmpItemRecognitionCode := Content;
                            if TmpItemRecognitionCode = '' then
                                TmpItemRecognitionCode := EDISetup."Def. Item Recognition Code";
                        end;
                    3:
                        begin
                            TmpVATRecognitionCode := Content;
                            if TmpVATRecognitionCode = '' then
                                TmpVATRecognitionCode := EDISetup."Def. VAT Recognition Code";
                        end;
                    4:
                        TmpSalesLine.Description := Content;
                    5:
                        begin
                            Sign := 1;
                            if Content = '-' then
                                Sign := -1;
                            if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                                Sign := -Sign;
                        end;
                    6:
                        TmpSalesLine."Unit Price" := GetDecimal(Content);
                    7:
                        begin
                            ABSRecognitionSetup.GET(TmpItemRecognitionCode, TmpVATRecognitionCode);
                            if ABSRecognitionSetup."Payment Discount" then begin
                                SalesHeader.TestField("Payment Discount %");
                            end else
                                with TmpSalesLine do begin
                                    Clear(SalesLine);
                                    SalesLine."Document Type" := SalesHeader."Document Type";
                                    SalesLine."Document No." := SalesHeader."No.";
                                    SalesLine."Line No." := GetNextLineNo();
                                    SalesLine.Insert();

                                    SalesLine.VALIDATE(Type, ABSRecognitionSetup.Type);
                                    SalesLine.VALIDATE("No.", ABSRecognitionSetup."No.");
                                    SalesLine.Validate(Quantity, 1);
                                    if Description <> '' then
                                        SalesLine.Description := Description;
                                    SalesLine.Validate("Unit Price", Sign * "Unit Price");
                                    SalesLine.VALIDATE("Gen. Prod. Posting Group", ABSRecognitionSetup."Gen. Prod. Posting Group");
                                    SalesLine.VALIDATE("VAT Prod. Posting Group", ABSRecognitionSetup."VAT Prod. Posting Group");
                                    SalesLine.Modify();
                                end;
                        end;
                end;
            until NEXT = 0;
        end;
    end;

    local procedure ProcessLIN08(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        ABSRecognitionSetup: Record "90016";
        TmpSalesLine: Record "Sales Line" temporary;
        TmpItemRecognitionCode: Code[10];
        TmpVATRecognitionCode: Code[10];
        CountryOfOriginCode: Code[10];
        TempDescription: array[2] of Text;
        Sign: Integer;
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            Clear(TempDescription);

            repeat
                CurrentEntryNo := "Line No.";
                CurrentFieldNo := "Field No.";

                case "Field No." of
                    2:
                        begin
                            TmpItemRecognitionCode := Content;
                            if TmpItemRecognitionCode = '' then
                                TmpItemRecognitionCode := EDISetup."Def. Item Recognition Code";
                        end;
                    3:
                        begin
                            TmpVATRecognitionCode := Content;
                            if TmpVATRecognitionCode = '' then
                                TmpVATRecognitionCode := EDISetup."Def. VAT Recognition Code";
                        end;
                    5:
                        begin
                            Sign := 1;
                            if Content = '-' then
                                Sign := -1;
                            if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                                Sign := -Sign;
                        end;
                    6:
                        TmpSalesLine.Amount := GetDecimal(Content);
                    7:
                        ;
                    8:
                        TmpSalesLine.Quantity := GetDecimal(Content);
                    9:
                        TmpSalesLine."Unit of Measure Code" := Content;
                    10:
                        TmpSalesLine."Unit Price" := GetDecimal(Content);
                    11:
                        TempDescription[1] := Content;
                    12:
                        CountryOfOriginCode := Content;
                    13:
                        ;
                    14:
                        TmpSalesLine."Lot No." := Content; // TempDescription[2] := Content;

                    15:
                        begin
                            TmpSalesLine."No." := Content;
                            if TempDescription[1] <> '' then
                                TmpSalesLine.Description := CopyStr(TempDescription[1], 1, MaxStrLen(TmpSalesLine.Description));
                            if TempDescription[2] <> '' then
                                TmpSalesLine."Description 2" := CopyStr(TempDescription[2], 1, MaxStrLen(TmpSalesLine."Description 2"));

                            ABSRecognitionSetup.GET(TmpItemRecognitionCode, TmpVATRecognitionCode);
                            UpdateItem(TmpSalesLine, ABSRecognitionSetup, CountryOfOriginCode);

                            if ABSRecognitionSetup."Payment Discount" then
                                SalesHeader.TestField("Payment Discount %")
                            else
                                with TmpSalesLine do begin
                                    Clear(SalesLine);
                                    SalesLine."Document Type" := SalesHeader."Document Type";
                                    SalesLine."Document No." := SalesHeader."No.";
                                    SalesLine."Line No." := GetNextLineNo();
                                    SalesLine.Insert();

                                    if "No." = '' then begin
                                        SalesLine.VALIDATE(Type, ABSRecognitionSetup.Type);
                                        SalesLine.VALIDATE("No.", ABSRecognitionSetup."No.");
                                    end else begin
                                        SalesLine.Validate(Type, SalesLine.Type::Item);
                                        SalesLine.Validate("No.", "No.");
                                        if ABSRecognitionSetup.Type = ABSRecognitionSetup.Type::"G/L Account" then
                                            SalesLine."ABS Sales Account" := ABSRecognitionSetup."No.";
                                    end;

                                    if SalesLine.Type = SalesLine.Type::Item then begin
                                        if (Quantity = 0) and ("Unit Price" = 0) and (Amount <> 0) then begin
                                            Quantity := 1;
                                            "Unit Price" := Amount;
                                        end;
                                        SalesLine.Validate(Quantity, Quantity);
                                        SalesLine.Validate("Unit of Measure Code", "Unit of Measure Code");
                                    end else
                                        SalesLine.Validate(Quantity, 1);

                                    SalesLine.Description := Description;
                                    if "Description 2" <> '' then
                                        SalesLine."Description 2" := "Description 2";

                                    SalesLine.Validate("Unit Price", Sign * "Unit Price");
                                    if Amount <> 0 then
                                        SalesLine.Validate(Amount, Amount);

                                    SalesLine.VALIDATE("Gen. Prod. Posting Group", ABSRecognitionSetup."Gen. Prod. Posting Group");
                                    SalesLine.VALIDATE("VAT Prod. Posting Group", ABSRecognitionSetup."VAT Prod. Posting Group");

                                    SalesLine."Lot No." := "Lot No.";
                                    SalesLine."ABS Delivery No." := "ABS Delivery No.";
                                    SalesLine."ABS Shipment Date" := "ABS Shipment Date";
                                    SalesLine.Modify();

                                    // If Line Amount is zero for an Item Line, then create an additonal text line
                                    if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."No." <> '') and (Amount = 0) then
                                        CreateAdditonalLine(SalesLine."Line No.", EmptyTextLine);
                                end;
                        end;
                end;
            until NEXT = 0;
        end;
    end;

    local procedure ProcessFTR01(var EDIMessageLineDetail: Record "90012")
    var
        EDIMessageLineDetail2: Record "90012";
        EDIMessageLine: Record "90011";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        TotalAmtExclVAT: Decimal;
        TotalAmtInclVAT: Decimal;
        Sign: Integer;
    begin
        with EDIMessageLineDetail2 do begin
            SETRANGE("EDI Message Type", EDIMessageHeader."EDI Message Type");
            SETRANGE("Run No.", EDIMessageHeader."Run No.");
            SETRANGE("Line No.", EDIMessageLineDetail."Line No.");

            repeat
                CurrentEntryNo := "Line No.";
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
            until NEXT = 0;
        end;
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
        with SalesLine2 do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            if FindLast() then
                exit("Line No." + 10000)
            else
                exit(10000);
        end;
    end;

    local procedure UpdateItem(var TempSalesLine: Record "Sales Line"; ABSRecognitionSetup: Record "90016"; CountryOfOriginCode: Code[10])
    var
        Item: Record "Item";
        UOM: Record "Unit of Measure";
        ItemUOM: Record "Item Unit of Measure";
        ItemCat: Record "Item Category";
        NewItem: Boolean;
    begin
        if TempSalesLine."No." = '' then
            exit;

        with UOM do
            if not GET(TempSalesLine."Unit of Measure Code") then begin
                INIT;
                UOM.Code := TempSalesLine."Unit of Measure Code";
                UOM.Description := UOM.Code;
                INSERT;
            end;

        with ItemUOM do
            if not GET(TempSalesLine."No.", UOM.Code) then begin
                INIT;
                "Item No." := TempSalesLine."No.";
                Code := UOM.Code;
                "Qty. per Unit of Measure" := 1;
                INSERT;
            end;

        with Item do begin
            if not GET(TempSalesLine."No.") then begin
                INIT;
                NewItem := true;
                "No." := TempSalesLine."No.";
                "Base Unit of Measure" := UOM.Code;
                "Sales Unit of Measure" := "Base Unit of Measure";
                "Purch. Unit of Measure" := "Base Unit of Measure";
                Type := Type::Service;
                INSERT;
            end;
            // RZWPT - When item fields are validated, a check is executed which prevents any modifications when entries are present...
            //VALIDATE(Description,COPYSTR(TempSalesLine.Description,1,MAXSTRLEN(Description)));
            Description := CopyStr(TempSalesLine.Description, 1, MAXSTRLEN(Description));
            if NewItem then
                VALIDATE(Description);
            // RZWPT {*}
            "Description 2" := COPYSTR(TempSalesLine.Description, MAXSTRLEN(Description) + 1, MAXSTRLEN("Description 2"));

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
            MODIFY;
        end;
    end;

    internal procedure ChangeSalesDocStatus(SalesHeader: Record "Sales Header"; NewDocumentStatus: Option " ",Processed,Posted,Deleted)
    var
        EDIMessageLine: Record "90011";
        SalesHeaderRecRef: RecordRef;
    begin
        with SalesHeader do begin
            SalesHeaderRecRef.GetTable(SalesHeader);

            EDIMessageLine.SETCURRENTKEY("Document Status", "Record-ID");
            EDIMessageLine.SETRANGE("Document Status", EDIMessageLine."Document Status"::Processed);
            EDIMessageLine.SETRANGE("Record-ID", SalesHeaderRecRef.RecordId);
            if not EDIMessageLine.FINDFIRST then
                exit;
            EDIMessageLine."Document Status" := NewDocumentStatus;
            EDIMessageLine.MODIFY;
        end;
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

