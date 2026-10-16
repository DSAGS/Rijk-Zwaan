namespace dgs.rzw.abs;
page 50110 "RZW Inb. EDI Message Subf."
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
                field("Document Status"; Rec."Document Status")
                {
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

