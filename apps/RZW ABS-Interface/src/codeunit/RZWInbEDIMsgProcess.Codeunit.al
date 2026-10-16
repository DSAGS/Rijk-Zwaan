namespace RZW;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 50111 "RZW Inb. EDI Msg.-Process"
{
    TableNo = "RZW EDI Message Header";

    trigger OnRun()
    var
        EDIMessageType: Record "RZW EDI Message Type";
        EDIMessageHeader2: Record "RZW EDI Message Header";
        Window: Dialog;
        EDIMessageProcessingErr: Label 'You cannot process EDI Message with Run No. %1, since earlier generated EDI Messages exist for the same company.', comment = '%1 = Run No.';
    // Text002: Label 'Processing lines              #2######'; is kept for future use.

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
                Error(EDIMessageProcessingErr, EDIMessageHeader."Run No.");
        end;

        Window.Open('#1#################################\\');
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
        GlobalSalesHeader: Record "Sales Header";
        GlobalSalesLine: Record "Sales Line";
        CurrentEntryNo: Integer;
        CurrentFieldNo: Integer;
        NothingToProcessErr: Label 'There is nothing to process.';
        DocCountMismatchErr: Label 'The total No. of Documents in the File does not match the quantity indicated in the file header.\\Please check the file.';

    local procedure ProcessCustomer()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail.SetRange("Field No.", 1);
        if not EDIMessageLineDetail.FindSet() then
            Error(NothingToProcessErr);

        EDISetup.TestImportCust();

        repeat
            case EDIMessageLineDetail.Content of
                'LIN02':
                    ProcessLIN02(EDIMessageLineDetail);
                'LIN04':
                    ProcessLIN04(EDIMessageLineDetail);
                else
                    //add publisher event here for other Customer line types
                    OnProcessAdditionalCustomerLineTypes(EDIMessageLineDetail, CurrentEntryNo, CurrentFieldNo);
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
#pragma warning disable AA0139
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
                else
                    OnProcessadditionalCustomerFields(EDIMessageLineDetail2, Cust);
            end;
        until EDIMessageLineDetail2.Next() = 0;

        CustRecRef.Close();
#pragma warning restore AA0139
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
#pragma warning disable AA0139
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
                    begin
                        CustBankAccount."Country/Region Code" := EDIMessageLineDetail2.Content;
                        CustBankAccount.Modify();

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            CustBankRecRef.GetTable(CustBankAccount);
                            EDIMessageLine."Record-ID" := CustBankRecRef.RecordId;
                            EDIMessageLine.Modify();
                        end;
                    end;
                //publisher event for handling additonal field numbers in differeent extensions
                else
                    OnProcessAdditonalCustomerBankAccountFields(EDIMessageLineDetail, CustBankAccount);

            end;
        until EDIMessageLineDetail2.Next() = 0;
        CustBankRecRef.Close();
#pragma warning restore AA0139
    end;

    local procedure ProcessVendor()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail.SetRange("Field No.", 1);
        if not EDIMessageLineDetail.FindSet() then
            Error(NothingToProcessErr);

        EDISetup.TestImportVend();

        repeat
            case EDIMessageLineDetail.Content of
                'LIN03':
                    ProcessLIN03(EDIMessageLineDetail);
                'LIN05':
                    ProcessLIN05(EDIMessageLineDetail);
                else
                    OnProcessAdditionalVendorLineTypes(EDIMessageLineDetail);
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
#pragma warning disable AA0139
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
                else
                    OnProcessAdditionalVendorFields(EDIMessageLineDetail2, Vend);
            end;
        until EDIMessageLineDetail2.Next() = 0;

        VendRecRef.Close();
#pragma warning restore AA0139
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
#pragma warning disable AA0139
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
                else
                    OnProcessAdditionalVendorBankAccountFields(EDIMessageLineDetail2, VendBankAccount);
            end;
        until EDIMessageLineDetail2.Next() = 0;

        VendBankRecRef.Close();
#pragma warning restore AA0139
    end;

    local procedure ProcessSalesDocument()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
        UseDocType: enum "Sales Document Type";
        UseDocNo: Code[20];
        NoOfDocuments: Integer;
        IsSalesFile: Boolean;
    begin
        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail.SetRange("Field No.", 1);
        if not EDIMessageLineDetail.FindSet() then
            Error(NothingToProcessErr);

        EDISetup.TestImportSInv();
        if GlobalSalesHeader."No." <> '' then begin
            UseDocType := GlobalSalesHeader."Document Type";
            UseDocNo := GlobalSalesHeader."No.";
        end;

        repeat
            case EDIMessageLineDetail.Content of
                'TOT01':
                    begin
                        ProcessTOT01(EDIMessageLineDetail, NoOfDocuments);
                        if NoOfDocuments > 0 then
                            IsSalesFile := true;
                    end;
                'HDR01':
                    begin
                        ProcessHDR01(EDIMessageLineDetail);
                        NoOfDocuments := NoOfDocuments - 1;
                    end;
                'LIN01':
                    ProcessLIN01(EDIMessageLineDetail);

                'FTR01':
                    ProcessFTR01(EDIMessageLineDetail);
                else
                    OnProcessAdditionalSalesDocContentTypes(EDIMessageLineDetail, UseDocType, UseDocNo, CurrentEntryNo, CurrentFieldNo);

            end;
        until EDIMessageLineDetail.Next() = 0;
        // Check for correct number of documents
        if IsSalesFile then
            if NoOfDocuments <> 0 then
                Error(DocCountMismatchErr);
    end;

    local procedure ProcessTOT01(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; var NoOfDocuments: Integer)
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
                    NoOfDocuments := GetInteger(EDIMessageLineDetail2.Content);
                else
                    OnProcessAddtionalSalesDocTotalFields(EDIMessageLineDetail2);
            end;
        until EDIMessageLineDetail2.Next() = 0;
    end;

    local procedure ProcessHDR01(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        TempSalesHeader: Record "Sales Header" temporary;
        SalesHeaderRecRef: RecordRef;
        TempDocType: Integer;
    begin
#pragma warning disable AA0139
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
                        TempDocType := GetInteger(EDIMessageLineDetail2.Content) + 1;
                        TempSalesHeader."Document Type" := Enum::"Sales Document Type".FromInteger(TempDocType);
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
                    begin
                        TempSalesHeader."Payment Method Code" := EDIMessageLineDetail2.Content;
                        // All necessary fields are populated, create Sales Header
                        Clear(GlobalSalesHeader);
                        GlobalSalesHeader.SetHideValidationDialog(true);

                        GlobalSalesHeader."Document Type" := TempSalesHeader."Document Type";
                        GlobalSalesHeader.Validate("No.", TempSalesHeader."No.");
                        GlobalSalesHeader.Insert(true);

                        GlobalSalesHeader.Validate("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");
                        GlobalSalesHeader.Validate("Posting Date", TempSalesHeader."Posting Date");
                        if TempSalesHeader."Payment Terms Code" = '' then
                            TempSalesHeader."Payment Terms Code" := EDISetup."Default Payment Terms Code";
                        GlobalSalesHeader.Validate("Payment Terms Code");

                        GlobalSalesHeader.Validate("Payment Method Code", TempSalesHeader."Payment Method Code");
                        GlobalSalesHeader.Validate("Due Date", TempSalesHeader."Due Date");

                        if TempSalesHeader."Document Type" = TempSalesHeader."Document Type"::Invoice then begin
                            GlobalSalesHeader.Validate("Pmt. Discount Date", TempSalesHeader."Pmt. Discount Date");
                            GlobalSalesHeader.Validate("Payment Discount %", TempSalesHeader."Payment Discount %")
                        end;
                        GlobalSalesHeader.Validate("Currency Code", TempSalesHeader."Currency Code");

                        GlobalSalesHeader.Validate("Salesperson Code", TempSalesHeader."Salesperson Code");
                        GlobalSalesHeader."Your Reference" := TempSalesHeader."Your Reference";
                        GlobalSalesHeader."Posting No." := TempSalesHeader."Posting No.";
                        GlobalSalesHeader.Modify(true);

                        if EDIMessageLine.Get(EDIMessageLineDetail2."EDI Message Type", EDIMessageLineDetail2."Run No.", EDIMessageLineDetail2."Line No.") then begin
                            SalesHeaderRecRef.GetTable(GlobalSalesHeader);
                            EDIMessageLine."Record-ID" := SalesHeaderRecRef.RecordId;
                            EDIMessageLine."Document Status" := EDIMessageLine."Document Status"::Processed;
                            EDIMessageLine.Modify();
                        end;
                    end;
                else
                    OnProcessAdditionalSalesDocHeaderFields(EDIMessageLineDetail2, GlobalSalesHeader);
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
                        if GlobalSalesHeader."Document Type" = GlobalSalesHeader."Document Type"::"Credit Memo" then
                            Sign := -Sign;
                    end;
                6:
                    TempSalesLine."Unit Price" := GetDecimal(EDIMessageLineDetail2.Content);
                7:
                    begin
                        ABSRecognitionSetup.Get(TmpItemRecognitionCode, TmpVATRecognitionCode);
                        if ABSRecognitionSetup."Payment Discount" then
                            GlobalSalesHeader.TestField("Payment Discount %")
                        else begin
                            Clear(GlobalSalesLine);
                            GlobalSalesLine."Document Type" := GlobalSalesHeader."Document Type";
                            GlobalSalesLine."Document No." := GlobalSalesHeader."No.";
                            GlobalSalesLine."Line No." := GetNextLineNo();
                            GlobalSalesLine.Insert();

                            GlobalSalesLine.Validate(Type, ABSRecognitionSetup.Type);
                            GlobalSalesLine.Validate("No.", ABSRecognitionSetup."No.");
                            GlobalSalesLine.Validate(Quantity, 1);
                            GlobalSalesLine.Description := TempSalesLine.Description;
                            GlobalSalesLine.Validate("Unit Price", Sign * TempSalesLine."Unit Price");
                            GlobalSalesLine.Validate("Gen. Prod. Posting Group", ABSRecognitionSetup."Gen. Prod. Posting Group");
                            GlobalSalesLine.Validate("VAT Prod. Posting Group", ABSRecognitionSetup."VAT Prod. Posting Group");
                            GlobalSalesLine.Modify();
                        end;
                    end;
                else
                    OnProcessAdditionalSalesDocLineFields(EDIMessageLineDetail2, GlobalSalesLine);
            end;
        until EDIMessageLineDetail2.Next() = 0;
#pragma warning restore AA0139
    end;

    local procedure ProcessFTR01(var EDIMessageLineDetail: Record "RZW EDI Message Line detail")
    var
        EDIMessageLineDetail2: Record "RZW EDI Message Line detail";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        TotalAmtExclVAT: Decimal;
        TotalAmtInclVAT: Decimal;
        Sign: Integer;
        VatCorrectionLbl: Label 'VAT correction';

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
                        Sign := 1;
                        if EDIMessageLineDetail2.Content = '-' then
                            Sign := -1;
                        if GlobalSalesHeader."Document Type" = GlobalSalesHeader."Document Type"::"Credit Memo" then
                            Sign := -Sign;
                    end;
                3:
                    TotalAmtExclVAT := GetDecimal(EDIMessageLineDetail2.Content);
                4:
                    begin
                        // Create a correction line when VAT calculation differences occur
                        TotalAmtInclVAT := GetDecimal(EDIMessageLineDetail2.Content);

                        ReleaseSalesDocument.Run(GlobalSalesHeader);
                        GlobalSalesHeader.CalcFields("Amount Including VAT");
                        if EDISetup."VAT calculation" = EDISetup."VAT calculation"::"Imported Amounts Leading" then
                            if Round(GlobalSalesHeader."Amount Including VAT", 0.01) <> Round(TotalAmtInclVAT, 0.01) then begin
                                GlobalSalesLine.Init();
                                GlobalSalesLine."Document Type" := GlobalSalesHeader."Document Type";
                                GlobalSalesLine."Document No." := GlobalSalesHeader."No.";
                                GlobalSalesLine."Line No." := GetNextLineNo();
                                GlobalSalesLine.Insert();

                                GlobalSalesLine.Validate(Type, GlobalSalesLine.Type::"G/L Account");
                                GlobalSalesLine.Validate("No.", EDISetup."VAT Correction Account G/L");
                                GlobalSalesLine.Description := VatCorrectionLbl;
                                GlobalSalesLine.Validate(Quantity, 1);
                                GlobalSalesLine.Validate("Unit Price", TotalAmtInclVAT - GlobalSalesHeader."Amount Including VAT");
                                GlobalSalesLine.Modify();
                            end;
                    end;
                else
                    OnProcessAdditionalSalesDocFooterFields(EDIMessageLineDetail2, GlobalSalesHeader, GlobalSalesLine);
            end;
        until EDIMessageLineDetail2.Next() = 0;
    end;

    procedure GetDate(UseText: Text): Date
    var
        D: Integer;
        M: Integer;
        Y: Integer;
    begin
        if (UseText = '00000000') or (UseText = '') then
            exit(0D);

        Evaluate(D, CopyStr(UseText, 1, 2));
        Evaluate(M, CopyStr(UseText, 3, 2));
        Evaluate(Y, CopyStr(UseText, 5, 4));
        exit(DMY2Date(D, M, Y));
    end;

    procedure GetInteger(IntegerText: Text) ReturnInteger: Integer
    begin
        Evaluate(ReturnInteger, IntegerText);
    end;

    procedure GetDecimal(DecimalText: Text) ReturnDecimal: Decimal
    begin
        DecimalText := ConvertStr(DecimalText, '.', ',');
        Evaluate(ReturnDecimal, DecimalText);
    end;

    internal procedure GetLastError(var NewCurrentEntryNo: Integer; var NewCurrentFieldNo: Integer)
    begin
        NewCurrentEntryNo := CurrentEntryNo;
        NewCurrentFieldNo := CurrentFieldNo;
    end;

    internal procedure GetNextLineNo(): Integer
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2.SetRange("Document Type", GlobalSalesHeader."Document Type");
        SalesLine2.SetRange("Document No.", GlobalSalesHeader."No.");
        if SalesLine2.FindLast() then
            exit(SalesLine2."Line No." + 10000)
        else
            exit(10000);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAdditionalCustomerLineTypes(EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; var NewCurrentEntryNo: Integer; var NewCurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessadditionalCustomerFields(EDIMessageLineDetail2: Record "RZW EDI Message Line Detail"; var Cust: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAdditonalCustomerBankAccountFields(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; var CustBankAccount: Record "Customer Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAdditionalVendorLineTypes(EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessadditionalVendorFields(EDIMessageLineDetail2: Record "RZW EDI Message Line Detail"; var Vend: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAdditionalVendorBankAccountFields(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; var VendBankAccount: Record "Vendor Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAdditionalSalesDocContentTypes(EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; UseDocType: enum "Sales Document Type"; UseDocNo: Code[20]; var NewCurrentEntryNo: Integer; var NewCurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAddtionalSalesDocTotalFields(EDIMessageLineDetail2: Record "RZW EDI Message Line Detail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAdditionalSalesDocHeaderFields(EDIMessageLineDetail2: Record "RZW EDI Message Line Detail"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAdditionalSalesDocLineFields(EDIMessageLineDetail2: Record "RZW EDI Message Line Detail"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAdditionalSalesDocFooterFields(EDIMessageLineDetail2: Record "RZW EDI Message Line Detail"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;
}
