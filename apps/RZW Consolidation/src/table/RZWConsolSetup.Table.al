namespace dsa.rzw.consolidation;

table 50150 "RZW Consol. Setup"
{
    Caption = 'Consolidation Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            AllowInCustomizations = AsReadWrite;
        }
        field(2; "Organizational Code"; Code[10])
        {
            Caption = 'Organizational Code';
            ToolTip = 'Specifies a unique number that will be assigned to the exported data, as to distinguish between different organizations.';
            AllowInCustomizations = AsReadWrite;
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
