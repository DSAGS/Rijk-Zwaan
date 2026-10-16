namespace dsa.rzw.consolidation;
table 50151 "RZW Consol. Reporting Account"
{
    Caption = 'Cons. Reporting Account';
    DataClassification = CustomerContent;
    LookupPageId = "RZW Consol. Reporting Accounts";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            AllowInCustomizations = AsReadWrite;
            ToolTip = 'Specifies a unique code to identify this reporting account.';
        }
        field(2; Name; Text[80])
        {
            Caption = 'Name';
            AllowInCustomizations = AsReadWrite;
            ToolTip = 'Specifies the name of this reporting account.';
        }
        field(3; "Debet/Credit"; Option)
        {
            Caption = 'Debit/Credit';
            OptionCaption = ' ,Debit,Credit';
            OptionMembers = ,Debit,Credit;
            AllowInCustomizations = AsReadWrite;
            ToolTip = 'Specifies whether this reporting account is a debit or credit account.';
        }
        field(4; "Worldwide Name"; Text[80])
        {
            Caption = 'Worldwide Name';
            AllowInCustomizations = AsReadWrite;
            ToolTip = 'Specifies the worldwide name of this reporting account.';
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
