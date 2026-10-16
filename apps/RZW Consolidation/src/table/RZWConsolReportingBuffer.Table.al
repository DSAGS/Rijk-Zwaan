namespace dsa.rzw.consolidation;
table 50152 "RZW Consol. Reporting Buffer"
{
    Caption = 'Consolidation Reporting Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Consolidation Code"; Code[20])
        {
            Caption = 'Consolidation Code';
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(3; "Debet/Credit"; Option)
        {
            Caption = 'Debit/Credit';
            OptionCaption = ' ,Debit,Credit';
            OptionMembers = ,Debit,Credit;
        }
    }
    keys
    {
        key(PK; "Consolidation Code")
        {
            Clustered = true;
        }
        key(Key2; "Debet/Credit")
        {
            SumIndexFields = Amount;
        }
    }
}
