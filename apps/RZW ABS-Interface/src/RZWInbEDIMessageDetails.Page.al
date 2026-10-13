namespace RZW;
page 50100 "RZW Inb. EDI Message Details"
{
    Caption = 'Inb. EDI Message Details';
    LinksAllowed = false;
    PageType = List;
    SourceTable = "RZW EDI Message Line Detail";
    ApplicationArea = All;
    usagecategory = none;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.")
                {
                    Editable = false;
                }
                field("Field No."; Rec."Field No.")
                {
                    Editable = false;
                }
                field(Content; Rec.Content)
                {
                    Caption = 'Content';
                }
                field("Record Type"; Rec."Record Type")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Field Name"; Rec."Field Name")
                {
                }
            }
        }
    }

    actions
    {
    }
}

