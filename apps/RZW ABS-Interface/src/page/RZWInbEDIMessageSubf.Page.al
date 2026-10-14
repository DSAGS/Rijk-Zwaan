page 50110 "RZW Inb. EDI Message Subf."
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = Table90011;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Description; Description)
                {
                }
                field(FORMAT("Record-ID"); FORMAT("Record-ID"))
                {
                    Caption = 'Record-ID';
                }
                field("Document Status"; "Document Status")
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
                Caption = 'Show';

                trigger OnAction()
                begin
                    Rec.ShowDocument;
                end;
            }
        }
    }
}

