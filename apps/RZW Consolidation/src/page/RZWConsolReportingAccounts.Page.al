namespace dsa.rzw.consolidation;

page 50151 "RZW Consol. Reporting Accounts"
{
    ApplicationArea = All;
    Caption = 'Rijk Zwaan Consolidation Reporting Accounts';
    PageType = List;
    SourceTable = "RZW Consol. Reporting Account";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code")
                {
                }
                field(Name; Rec.Name)
                {
                }
                field("Debet/Credit"; Rec."Debet/Credit")
                {
                }
                field("Worldwide Name"; Rec."Worldwide Name")
                {

                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.EDITABLE(NOT CurrPage.LOOKUPMODE());
    end;
}
