namespace dsa.rzw.consolidation;

page 50152 "RZW Consol. Reporting Periods"
{
    ApplicationArea = All;
    Caption = 'Rijk Zwaan Consolidation ReportingPeriods';
    PageType = Card;
    SourceTable = "RZW Consol. Reporting Period";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Starting Date"; Rec."Starting Date")
                {
                }
                field(Name; Rec.Name)
                {
                }
                field("New Fiscal Year Consol. Comp."; Rec."New Fiscal Year Consol. Comp.")
                {
                }
                field(Reported; Rec.Reported)
                {
                }
                field(Closed; Rec.Closed)
                {
                }
            }
        }
    }
}
