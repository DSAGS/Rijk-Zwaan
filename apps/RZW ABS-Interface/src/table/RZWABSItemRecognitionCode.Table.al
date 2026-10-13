namespace RZW;
table 50101 "RZW ABS Item Recognition Code"
{
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;

    Caption = 'ABS Item Recognition Code';
    // DrillDownPageID = 90022;
    // LookupPageID = 90022;

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
        ABSRecognitionSetup.SetCurrentKey("ABS Item Recognition Code");
        ABSRecognitionSetup.SetRange("ABS Item Recognition Code", Code);
        ABSRecognitionSetup.DeleteAll();
    end;

    var
        ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
}

