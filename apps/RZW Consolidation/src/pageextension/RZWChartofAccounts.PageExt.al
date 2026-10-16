namespace dsa.rzw.consolidation;

using Microsoft.Finance.GeneralLedger.Account;

pageextension 50150 "RZW Chart of Accounts" extends "Chart of Accounts"
{
    layout
    {
        addlast(Control1)
        {
            field("RZW Consol. Reporting Account"; Rec."RZW Consol. Reporting Account")
            {
                ApplicationArea = All;
            }
        }
    }
}
