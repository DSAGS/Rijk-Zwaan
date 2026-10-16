namespace dgs.rzw.abs;
page 50119 "RZW Outb. EDI Message Details"
{
    Caption = 'Outb. EDI Message Details';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "RZW EDI Message Line Detail";
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.")
                {
                    Visible = ShowFieldContent;
                }
                field("Field No."; Rec."Field No.")
                {
                    Visible = ShowFieldContent;
                }
                field(Content; Rec.Content)
                {
                    Caption = 'Content';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Toggle Show Contents")
            {
                Caption = 'Toggle Show Contents';

                trigger OnAction()
                begin
                    ShowComposedContent := NOT ShowComposedContent;
                    ShowFields;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowFields;
    end;

    var
        ShowComposedContent: Boolean;
        ShowFieldContent: Boolean;

    local procedure ShowFields()
    begin
        ShowFieldContent := NOT ShowComposedContent;
        rec.FILTERGROUP(2);
        IF ShowComposedContent THEN
            rec.SETRANGE("Field No.", 1)
        ELSE
            rec.SETRANGE("Field No.");
        rec.FILTERGROUP(0);
    end;
}

