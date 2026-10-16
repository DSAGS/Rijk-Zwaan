namespace dgs.rzw.abs;
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
        ABSItemRecognitionCode: Record "RZW ABS Item Recognition Code";
        ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FromSalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        SuggestAmount: Codeunit "Item Charge Assgnt. (Sales)";
        TmpItemRecognitionCode: Code[10];
        TmpVATRecognitionCode: Code[10];
        TempDescription: array[2] of Text;
        NextLineNo: Integer;
        Sign: Integer;
        IsItemLine: Boolean;
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
                    TempSalesLine."RZW BR Ctry/Reg.of Origin Code" := EDIMessageLineDetail2.Content;
                13:
                    ;
                14:
                    TempSalesLine."RZW BR Batch No." := EDIMessageLineDetail2.Content;
                15:
                    begin
                        TempSalesLine."RZW BR ABS Item No." := EDIMessageLineDetail2.Content;
                        if TempDescription[1] <> '' then
                            TempSalesLine.Description := CopyStr(TempDescription[1], 1, MaxStrLen(TempSalesLine.Description));
                        if TempDescription[2] <> '' then
                            TempSalesLine."Description 2" := CopyStr(TempDescription[2], 1, MaxStrLen(TempSalesLine."Description 2"));
                        ABSItemRecognitionCode.Get(TmpItemRecognitionCode);
                        if ABSItemRecognitionCode."RZW BR ProcessAsFreightCharge" then
                            TempSalesLine."RZW BR ABS Item No." := '';

                        ABSRecognitionSetup.Get(TmpItemRecognitionCode, TmpVATRecognitionCode);
                        IsItemLine := UpdateItem(TempSalesLine, ABSRecognitionSetup, TempSalesLine."RZW BR Ctry/Reg.of Origin Code");

                        if ABSRecognitionSetup."Payment Discount" then
                            SalesHeader.TestField("Payment Discount %")
                        else begin
                            Clear(SalesLine);
                            SalesLine."Document Type" := SalesHeader."Document Type";
                            SalesLine."Document No." := SalesHeader."No.";
                            SalesLine."Line No." := InbEDIMsgProcess.GetNextLineNo();
                            SalesLine.Insert();

                            if IsItemLine then begin
                                SalesLine.Validate(Type, SalesLine.Type::Item);
                                SalesLine.Validate("No.", TempSalesLine."RZW BR ABS Item No.");
                            end else begin
                                SalesLine.Validate(Type, ABSRecognitionSetup.Type);
                                SalesLine.Validate("No.", ABSRecognitionSetup."No.");
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

                            SalesLine.Modify();
                            //  If Line Amount is zero for an Item Line, then create an additonal text line
                            // if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."No." <> '') and (TempSalesLine.Amount = 0) then
                            //     CreateAdditonalLine(SalesLine."Line No.", EmptyTextLine);

                            IF ABSRecognitionSetup.Type = ABSRecognitionSetup.Type::"Charge (Item)" THEN
                                IF SalesLine.Quantity <> 0 THEN BEGIN
                                    ItemChargeAssgntSales.RESET;
                                    ItemChargeAssgntSales.SETRANGE("Document Type", SalesLine."Document Type");
                                    ItemChargeAssgntSales.SETRANGE("Document No.", SalesLine."Document No.");
                                    ItemChargeAssgntSales.SETRANGE("Document Line No.", SalesLine."Line No.");
                                    ItemChargeAssgntSales.SETRANGE("Item Charge No.", SalesLine."No.");

                                    IF NOT ItemChargeAssgntSales.FINDLAST THEN BEGIN
                                        FromSalesLine.RESET;
                                        FromSalesLine.SETRANGE("Document Type", SalesLine."Document Type");
                                        FromSalesLine.SETRANGE("Document No.", SalesLine."Document No.");
                                        FromSalesLine.SETRANGE(Type, FromSalesLine.Type::Item);

                                        IF FromSalesLine.FIND('-') THEN
                                            REPEAT
                                                NextLineNo := NextLineNo + 10000;
                                                ItemChargeAssgntSales2.INIT;
                                                ItemChargeAssgntSales2."Document Type" := SalesLine."Document Type";
                                                ItemChargeAssgntSales2."Document No." := SalesLine."Document No.";
                                                ItemChargeAssgntSales2."Document Line No." := SalesLine."Line No.";
                                                ItemChargeAssgntSales2."Line No." := NextLineNo;
                                                ItemChargeAssgntSales2."Applies-to Doc. Type" := SalesLine."Document Type";
                                                ItemChargeAssgntSales2."Applies-to Doc. No." := SalesLine."Document No.";
                                                ItemChargeAssgntSales2."Applies-to Doc. Line No." := NextLineNo;
                                                ItemChargeAssgntSales2."Item No." := FromSalesLine."No.";
                                                ItemChargeAssgntSales2.Description := FromSalesLine.Description;
                                                ItemChargeAssgntSales2.VALIDATE("Unit Cost", ROUND(SalesLine."Line Amount", 0.0001));
                                                ItemChargeAssgntSales2."Item Charge No." := SalesLine."No.";
                                                ItemChargeAssgntSales2.INSERT;
                                                SuggestAmount.SuggestAssignment2(SalesLine, SalesLine.Quantity, 2);
                                                FromSalesLine.CALCFIELDS("Qty. to Assign", "Qty. Assigned");
                                                SalesLine.CALCFIELDS("Qty. to Assign", "Qty. Assigned");

                                            UNTIL FromSalesLine.NEXT = 0;
                                    END;
                                end;
                        end;
                    end;
            end;
        until EDIMessageLineDetail2.Next() = 0;
#pragma warning restore AA0139
    end;

    local procedure UpdateItem(var
                                   TempSalesLine: Record "Sales Line";
                                   ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
                                   CountryOfOriginCode: Code[10]): Boolean
    var
        Item: Record Item;
        UOM: Record "Unit of Measure";
        ItemUOM: Record "Item Unit of Measure";
        NewItem: Boolean;
    begin
        if TempSalesLine."RZW BR ABS Item No." = '' then
            exit(false);

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
            exit(true);
        end;

        // When item fields are validated, a check is executed which prevents any modifications when entries are present...
        Item.Description := CopyStr(TempSalesLine.Description, 1, MaxStrLen(Item.Description));
        if NewItem then
            Item.Validate(Description);

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
