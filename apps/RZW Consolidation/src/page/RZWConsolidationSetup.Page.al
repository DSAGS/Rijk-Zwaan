namespace dsa.rzw.consolidation;
page 50150 "RZW Consolidation Setup"
{
    ApplicationArea = All;
    Caption = 'Rijk Zwaan Consolidation Setup';
    PageType = Card;
    SourceTable = "RZW Consol. Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Organizational Code"; Rec."Organizational Code")
                {

                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
