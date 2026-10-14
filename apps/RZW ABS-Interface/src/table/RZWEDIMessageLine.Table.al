namespace RZW;
table 50109 "RZW EDI Message Line"
{
    Caption = 'EDI Message Line';
    DataPerCompany = false;
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;

    fields
    {
        field(1; "EDI Message Type"; Code[20])
        {
            Caption = 'EDI Message Type';
            TableRelation = "RZW EDI Message Type";
        }
        field(2; "Run No."; Code[20])
        {
            Caption = 'Run No.';
            TableRelation = "RZW EDI Message Header"."Run No." WHERE("EDI Message" Type=FIELD("EDI Message Type"));
        }
        field(3;"Line No.";Integer)
        {
            Caption = 'Line No.';
        }
        field(4;Description;Text[250])
        {
            Caption = 'Description';
        }
        field(5;"Line Counter";Decimal)
        {
            Caption = 'Line Counter';
            Editable = false;
            InitValue = 1;
        }
        field(10;"Record-ID";RecordID)
        {
            Caption = 'Record-ID';
        }
        field(20;"Document Status";Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = ' ,Processed,Posted,Deleted';
            OptionMembers = " ",Processed,Posted,Deleted;
        }
    }

    keys
    {
        key(Key1;"EDI Message Type","Run No.","Line No.")
        {
            Clustered = true;
            SumIndexFields = "Line Counter";
        }
    }

    fieldgroups
    {
    }

    var
        EDIMessageHeader: Record "90010";
        Text001: Label 'The corresponding record cannot be shown.';

    [Scope('Internal')]
    procedure ShowDocument()
    var
        EDIMessageHeader: Record "90010";
        Cust: Record "Customer";
        Vend: Record "Vendor";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustBankAccount: Record "Customer Bank Account";
        VendBankAccount: Record "Vendor Bank Account";
        RecRef: RecordRef;
        FldRef: FieldRef;
        LineType: Text;
        DocNo: Code[20];
    begin
        TESTFIELD("EDI Message Type");
        TESTFIELD("Run No.");
        EDIMessageHeader.GET("EDI Message Type","Run No.");

        TESTFIELD("Record-ID");
        // IF RecRef.GET("Record-ID") THEN BEGIN
        //   CASE RecRef.NUMBER OF
        //     DATABASE::Customer :
        //       BEGIN
        //         RecRef.SETTABLE(Cust);
        //         HYPERLINK(GETURL(CLIENTTYPE::Current,EDIMessageHeader.Company,OBJECTTYPE::Page, 21, Cust));
        //       END;
        //     DATABASE::Vendor :
        //       BEGIN
        //         RecRef.SETTABLE(Vend);
        //         HYPERLINK(GETURL(CLIENTTYPE::Current,EDIMessageHeader.Company,OBJECTTYPE::Page, 26, Vend));
        //       END;
        //     DATABASE::"Sales Header":
        //       BEGIN
        //         RecRef.SETTABLE(SalesHeader);
        //         HYPERLINK(GETURL(CLIENTTYPE::Current,EDIMessageHeader.Company,OBJECTTYPE::Page, 45, SalesHeader));
        //       END;
        //     DATABASE::"Customer Bank Account":
        //       BEGIN
        //         RecRef.SETTABLE(CustBankAccount);
        //         HYPERLINK(GETURL(CLIENTTYPE::Current,EDIMessageHeader.Company,OBJECTTYPE::Page, 423, CustBankAccount));
        //       END;
        //     DATABASE::"Vendor Bank Account":
        //       BEGIN
        //         RecRef.SETTABLE(VendBankAccount);
        //         HYPERLINK(GETURL(CLIENTTYPE::Current,EDIMessageHeader.Company,OBJECTTYPE::Page, 425, VendBankAccount));
        //       END;
        //   END;
        // END ELSE BEGIN
        //   LineType := FORMAT("Record-ID");
        //   CASE TRUE OF
        //     STRPOS(LineType,'Invoice') <> 0 :
        //       BEGIN
        //         DocNo := COPYSTR(LineType,STRPOS(LineType,'Invoice') + 8);
        //         IF NOT SalesInvoiceHeader.GET(DocNo) THEN
        //           ERROR(Text001);
        //         HYPERLINK(GETURL(CLIENTTYPE::Current,EDIMessageHeader.Company,OBJECTTYPE::Page, 132, SalesInvoiceHeader));
        //       END;
        //     STRPOS(LineType,'Credit Memo') <> 0 :
        //       BEGIN
        //         DocNo := COPYSTR(LineType,STRPOS(LineType,'Credit Memo') + 12);
        //         IF NOT SalesCrMemoHeader.GET(DocNo) THEN
        //           ERROR(Text001);
        //         HYPERLINK(GETURL(CLIENTTYPE::Current,EDIMessageHeader.Company,OBJECTTYPE::Page, 134, SalesCrMemoHeader));
        //       END;
        //     ELSE
        //       ERROR(Text001);
        //   END;
        // END;
    end;

    local procedure GetMessageHeader()
    begin
        IF (EDIMessageHeader."EDI Message Type" <> "EDI Message Type") OR (EDIMessageHeader."Run No." <> "Run No.") THEN
          EDIMessageHeader.GET("EDI Message Type","Run No.");
    end;
}

