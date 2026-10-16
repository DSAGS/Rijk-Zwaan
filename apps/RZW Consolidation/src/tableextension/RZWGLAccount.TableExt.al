namespace dsa.rzw.consolidation;

using Microsoft.Finance.GeneralLedger.Account;

tableextension 50150 "RZW G/L Account" extends "G/L Account"
{
    fields
    {
        field(50150; "RZW Consol. Reporting Account"; Code[20])
        {
            Caption = 'Rijk Zwaan Consolidation Reporting Account';
            DataClassification = CustomerContent;
            AllowInCustomizations = AsReadWrite;
            Tooltip = 'Specifies the code of the Rijk Zwaan Consolidation Reporting Account.';
            TableRelation = "RZW Consol. Reporting Account";
        }
    }
}
