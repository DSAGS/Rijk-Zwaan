namespace dgs.rzw.abs;

using Microsoft.Foundation.NoSeries;
table 50110 "RZW EDI Message Line Detail"
{
    Caption = 'EDI Message Line Detail';
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
            Editable = false;
            TableRelation = "RZW EDI Message Header"."Run No." WHERE("EDI Message Type" = FIELD("EDI Message Type"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(8; Content; Text[250])
        {
            Caption = 'Content';
        }
        field(20; "Record Type"; Code[10])
        {
            Caption = 'Record Type';
        }
        field(21; "Field Name"; Text[30])
        {
            CalcFormula = Lookup("RZW ABS Record Type Setup"."Field Name" WHERE("ABS Record Type Code" = FIELD("Record Type"),
                                                                             "Field No." = FIELD("Field No.")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "EDI Message Type", "Run No.", "Line No.", "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

