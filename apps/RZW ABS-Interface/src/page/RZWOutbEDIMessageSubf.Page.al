namespace dgs.rzw.abs;
page 50118 "RZW Outb. EDI Message Subf."
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "RZW EDI Message Line";
    ApplicationArea = All;
    UsageCategory = None;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Description; Rec.Description)
                {
                }
                field("Record-ID"; FORMAT(Rec."Record-ID"))
                {
                    Caption = 'Record-ID';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Show)
            {
                Caption = 'Show Document';

                trigger OnAction()
                begin
                    Rec.ShowDocument;
                end;
            }
        }
    }
}

