namespace dgs.rzw.abs;
table 50106 "RZW ABS Record Type Setup"
{
    Caption = 'ABS Record Type Setup';
    DataCaptionFields = "ABS Record Type Code";
    DataPerCompany = false;
    // DrillDownPageID = 90026;
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;

    fields
    {
        field(1; "ABS Record Type Code"; Code[10])
        {
            Caption = 'ABS Record Type Code';
            TableRelation = "RZW ABS Record Type";
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(3; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
        field(4; "Descriptive Field"; Boolean)
        {
            Caption = 'Descriptive Field';
        }
    }

    keys
    {
        key(Key1; "ABS Record Type Code", "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

