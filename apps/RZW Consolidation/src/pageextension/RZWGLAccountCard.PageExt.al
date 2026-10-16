namespace dsa.rzw.consolidation;

using Microsoft.Finance.GeneralLedger.Account;

pageextension 50151 "RZW G/L Account Card" extends "G/L Account Card"
{
    layout
    {
        addlast(Consolidation)
        {
            field("RZW Consol. Reporting Account"; Rec."RZW Consol. Reporting Account")
            {
                ApplicationArea = All;
            }
        }
    }
}
