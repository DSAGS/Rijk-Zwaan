namespace RZW;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
table 50100 "RZW EDI Setup"
{
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;

    Caption = 'EDI Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(36; "Def. Customer Posting Group"; Code[20])
        {
            Caption = 'Def. Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(37; "Def. Vendor Posting Group"; Code[20])
        {
            Caption = 'Def. Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(38; "Def. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Def. Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(39; "Def. VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Def. VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(40; "VAT Correction Account G/L"; Code[20])
        {
            Caption = 'VAT Correction Account G/L';
            TableRelation = "G/L Account";
        }
        field(45; "Def. Item Recognition Code"; Code[10])
        {
            Caption = 'Def. Item Recognition Code';
            TableRelation = "RZW ABS Item Recognition Code";
        }
        field(46; "Def. VAT Recognition Code"; Code[10])
        {
            Caption = 'Def. VAT Recognition Code';
            TableRelation = "RZW ABS VAT Recognition Code";
        }
        field(47; "Remove Leading Zeros"; Boolean)
        {
            Caption = 'Remove Leading Zeros';
        }
        field(48; "Clear LCY from Currency Codes"; Boolean)
        {
            Caption = 'Clear LCY from Currency Codes';
        }
        field(49; "Skip Bank Data in Import"; Boolean)
        {
            Caption = 'Skip Bank Data in Import';
        }
        field(52; "Off-Line Text"; Code[10])
        {
            Caption = 'Off-Line Text';
        }
        field(53; "Default Payment Terms Code"; Code[10])
        {
            Caption = 'Default Payment Terms Code';
            TableRelation = "Payment Terms";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }


    internal procedure TestImportCust()
    begin
        TestField("Def. Customer Posting Group");
        TestField("Def. Gen. Bus. Posting Group");
        TestField("Def. VAT Bus. Posting Group");
    end;

    internal procedure TestImportVend()
    begin
        TestField("Def. Vendor Posting Group");
        TestField("Def. Gen. Bus. Posting Group");
        TestField("Def. VAT Bus. Posting Group");
    end;

    internal procedure TestImportSInv()
    begin
        TestField("Def. Gen. Bus. Posting Group");
        TestField("Def. VAT Bus. Posting Group");
        TestField("VAT Correction Account G/L");
        TestField("Def. Item Recognition Code");
        TestField("Def. VAT Recognition Code");
        TestField("Default Payment Terms Code");
    end;

    internal procedure TestImportPInv()
    begin
    end;
}
