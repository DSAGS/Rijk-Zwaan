namespace RZW;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 50105 "RZW BR Inb. EDI Msg.-Process"
{
    var
        InbEDIMsgProcess: codeunit "RZW Inb. EDI Msg.-Process";

    local procedure ProcessLIN11(EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; var CurrentEntryNo: Integer; var CurrentFieldNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        EDISetup: Record "RZW EDI Setup";
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        Cust: Record Customer;
        CustRecRef: RecordRef;
    begin
#pragma warning disable AA0139
        GLSetup.Get();
        EDISetup.Get();
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageLineDetail."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageLineDetail."Run No.");
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
                    Cust."Credit Limit (LCY)" := InbEDIMsgProcess.GetDecimal(EDIMessageLineDetail2.Content);
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
                    case InbEDIMsgProcess.GetInteger(EDIMessageLineDetail2.Content) of
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
#pragma warning restore AA0139
    end;

    local procedure ProcessHDR03(EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; var NewCurrentEntryNo: Integer; var NewCurrentFieldNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        EDISetup: Record "RZW EDI Setup";
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        EDIMessageLine: Record "RZW EDI Message Line";
        SalesHeader: Record "Sales Header";
        TempSalesHeader: Record "Sales Header" temporary;
        ShipToAddress: Record "Ship-to Address";
        TempShipToAddress: Record "Ship-to Address" temporary;
        SalesHeaderRecRef: RecordRef;
        ImportDocumentType: Option " ","Order","Return Order";
    begin
#pragma warning disable AA0139
        GLSetup.Get();
        EDISetup.Get();
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageLineDetail."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageLineDetail."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        SalesHeaderRecRef.Open(Database::"Sales Header", false, CompanyName);

        repeat
            NewCurrentEntryNo := EDIMessageLineDetail2."Line No.";
            NewCurrentFieldNo := EDIMessageLineDetail2."Field No.";

            case EDIMessageLineDetail2."Field No." of
                3:
                    begin
                        Clear(TempSalesHeader);
                        TempSalesHeader."Posting Date" := InbEDIMsgProcess.GetDate(EDIMessageLineDetail2.Content);
                    end;
                4:
                    begin
                        // RZWPT - Create Orders or Return Orders...
                        //TmpSalesHeader."Document Type" := GetInteger(Content) + 1;
                        ImportDocumentType := InbEDIMsgProcess.GetInteger(EDIMessageLineDetail2.Content);
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
                    TempSalesHeader."Due Date" := InbEDIMsgProcess.GetDate(EDIMessageLineDetail2.Content);
                12:
                    TempSalesHeader."Pmt. Discount Date" := InbEDIMsgProcess.GetDate(EDIMessageLineDetail2.Content);
                13:
                    TempSalesHeader."Payment Discount %" := InbEDIMsgProcess.GetDecimal(EDIMessageLineDetail2.Content);
                14:
                    TempSalesHeader."Document Date" := InbEDIMsgProcess.GetDate(EDIMessageLineDetail2.Content);
                15:
                    TempSalesHeader."Payment Method Code" := EDIMessageLineDetail2.Content;
                16:
                    TempSalesHeader."RZW BR ABS Order Reference" := EDIMessageLineDetail2.Content;
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

                        SalesHeader."RZW BR ABS Order Reference" := TempSalesHeader."RZW BR ABS Order Reference";

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
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;

        SalesHeaderRecRef.Close();
#pragma warning restore AA0139
    end;

    local procedure ProcessLIN08(var EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; UseDocType: enum "Sales Document Type"; UseDocNo: Code[20]; var NewCurrentEntryNo: Integer; var NewCurrentFieldNo: Integer)
    var
        EDISetup: Record "RZW EDI Setup";
        EDIMessageLineDetail2: Record "RZW EDI Message Line Detail";
        ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TmpItemRecognitionCode: Code[10];
        TmpVATRecognitionCode: Code[10];
        CountryOfOriginCode: Code[10];
        TempDescription: array[2] of Text;
        Sign: Integer;
    begin
#pragma warning disable AA0139
        EDISetup.Get();
        SalesHeader.Get(UseDocType, UseDocNo);
        EDIMessageLineDetail2.SetRange("EDI Message Type", EDIMessageLineDetail."EDI Message Type");
        EDIMessageLineDetail2.SetRange("Run No.", EDIMessageLineDetail."Run No.");
        EDIMessageLineDetail2.SetRange("Line No.", EDIMessageLineDetail."Line No.");

        Clear(TempDescription);

        repeat
            NewCurrentEntryNo := EDIMessageLineDetail2."Line No.";
            NewCurrentFieldNo := EDIMessageLineDetail2."Field No.";

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
                    TempSalesLine.Amount := InbEDIMsgProcess.GetDecimal(EDIMessageLineDetail2.Content);
                7:
                    ;
                8:
                    TempSalesLine.Quantity := InbEDIMsgProcess.GetDecimal(EDIMessageLineDetail2.Content);
                9:
                    TempSalesLine."Unit of Measure Code" := EDIMessageLineDetail2.Content;
                10:
                    TempSalesLine."Unit Price" := InbEDIMsgProcess.GetDecimal(EDIMessageLineDetail2.Content);
                11:
                    TempDescription[1] := EDIMessageLineDetail2.Content;
                12:
                    CountryOfOriginCode := EDIMessageLineDetail2.Content;
                13:
                    ;
                14:
                    ;
#pragma warning disable AL0132 // TODO: - add fields in Sales Line Extension
                // TempSalesLine."Lot No." := EDIMessageLineDetail2.Content;
#pragma warning restore AL0132 // TODO: - add fields in Sales Line Extension
                // TempDescription[2] := Content;
                15:
                    begin
                        TempSalesLine."No." := EDIMessageLineDetail2.Content;
                        if TempDescription[1] <> '' then
                            TempSalesLine.Description := CopyStr(TempDescription[1], 1, MaxStrLen(TempSalesLine.Description));
                        if TempDescription[2] <> '' then
                            TempSalesLine."Description 2" := CopyStr(TempDescription[2], 1, MaxStrLen(TempSalesLine."Description 2"));

                        ABSRecognitionSetup.Get(TmpItemRecognitionCode, TmpVATRecognitionCode);
                        // TODO:
                        // UpdateItem(TempSalesLine, ABSRecognitionSetup, CountryOfOriginCode);

                        if ABSRecognitionSetup."Payment Discount" then
                            SalesHeader.TestField("Payment Discount %")
                        else begin
                            Clear(SalesLine);
                            SalesLine."Document Type" := SalesHeader."Document Type";
                            SalesLine."Document No." := SalesHeader."No.";
                            // TODO:

                            // SalesLine."Line No." := GetNextLineNo();
                            SalesLine.Insert();

                            if TempSalesLine."No." = '' then begin
                                SalesLine.Validate(Type, ABSRecognitionSetup.Type);
                                SalesLine.Validate("No.", ABSRecognitionSetup."No.");
                            end else begin
                                SalesLine.Validate(Type, SalesLine.Type::Item);
                                SalesLine.Validate("No.", TempSalesLine."No.");
                                // TODO:
                                // if ABSRecognitionSetup.Type = ABSRecognitionSetup.Type::"G/L Account" then
                                //     SalesLine."ABS Sales Account" := ABSRecognitionSetup."No.";
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

#pragma warning disable AL0132 // TODO: - add fields in Sales Line Extension
                            // SalesLine."Lot No." := "Lot No.";
                            // SalesLine."ABS Delivery No." := "ABS Delivery No.";
                            // SalesLine."ABS Shipment Date" := "ABS Shipment Date";
                            // SalesLine.Modify();
                            // // If Line Amount is zero for an Item Line, then create an additonal text line
                            // if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."No." <> '') and (TempSalesLine.Amount = 0) then
                            //     CreateAdditonalLine(SalesLine."Line No.", EmptyTextLine);
#pragma warning restore AL0132 // TODO: - add fields in Sales Line Extension
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;
#pragma warning restore AA0139
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"RZW Inb. EDI Msg.-Process", OnProcessAdditionalCustomerLineTypes, '', false, false)]
    local procedure InbEDIMsgProcess_OnProcessAdditionalCustomerLineTypes(EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; var NewCurrentEntryNo: Integer; var NewCurrentFieldNo: Integer)
    begin
        case EDIMessageLineDetail.Content of
            'LIN11':
                ProcessLIN11(EDIMessageLineDetail, NewCurrentEntryNo, NewCurrentFieldNo);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"RZW Inb. EDI Msg.-Process", OnProcessAdditionalSalesDocContentTypes, '', false, false)]
    local procedure InbEDIMsgProcess_OnProcessAdditionalSalesDocContentTypes(EDIMessageLineDetail: Record "RZW EDI Message Line Detail"; UseDocType: enum "Sales Document Type"; UseDocNo: Code[20]; var NewCurrentEntryNo: Integer; var NewCurrentFieldNo: Integer)
    begin
        case EDIMessageLineDetail.Content of
            'HDR03':
                ProcessHDR03(EDIMessageLineDetail, NewCurrentEntryNo, NewCurrentFieldNo);
            'LIN06', 'LIN08':
                ProcessLIN08(EDIMessageLineDetail, UseDocType, UseDocNo, NewCurrentEntryNo, NewCurrentFieldNo);
        end;
    end;

}
