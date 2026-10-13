namespace RZW;
table 50105 "RZW ABS Record Type"
{
    Caption = 'ABS Record Type';
    DataCaptionFields = "Code", Description;
    DataPerCompany = false;
    // DrillDownPageID = 90025;
    // LookupPageID = 90025;
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
        field(3; "File Type"; Option)
        {
            Caption = 'File Type';
            OptionCaption = ' ,Sales Invoice,Purchase Invoice,Customer Master,Vendor Master';
            OptionMembers = " ","Sales Invoice","Purchase Invoice","Customer Master","Vendor Master";
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
        ABSRecordTypeSetup.SetRange("ABS Record Type Code", Code);
        if not ABSRecordTypeSetup.IsEmpty then
            ABSRecordTypeSetup.DeleteAll();
    end;

    var
        ABSRecordTypeSetup: Record "RZW ABS Record Type Setup";
}
