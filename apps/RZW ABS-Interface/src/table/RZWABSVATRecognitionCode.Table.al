
namespace dgs.rzw.abs;

table 50102 "RZW ABS VAT Recognition Code"
{
    Caption = 'ABS VAT Recognition Code';
    // DrillDownPageID = 90023;
    // LookupPageID = 90023;
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ABSRecognitionSetup.SetCurrentKey("ABS VAT Recognition Code");
        ABSRecognitionSetup.SetRange("ABS VAT Recognition Code", Code);
        ABSRecognitionSetup.DeleteAll();
    end;

    var
        ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
}

