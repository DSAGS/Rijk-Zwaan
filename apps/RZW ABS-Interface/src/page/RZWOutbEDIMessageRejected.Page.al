namespace RZW;
page 50116 "RZW Outb.EDI Message-Rejected"
{
    Caption = 'Outbound EDI Message - Rejected';
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "RZW EDI Message Header";
    SourceTableView = sorting(Direction, "Run No.")
                      WHERE(Direction = FILTER(Outbound),
                            Status = FILTER(Rejected));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("EDI Message Type"; Rec."EDI Message Type")
                {
                }
                field("Run No."; Rec."Run No.")
                {
                }
                field("File Type"; Rec."File Type")
                {
                }
                field(Company; Rec.Company)
                {
                    Caption = 'Source Company';
                }
            }
            part(EDIMessageLines; "RZW Outb. EDI Message Subf.")
            {
                SubPageLink = "EDI Message Type" = field("EDI Message Type"),
                              "Run No." = field("Run No.");
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Creation Date"; Rec."Creation Date")
                {
                    Importance = Promoted;
                }
                field("Creation Time"; Rec."Creation Time")
                {
                }
                field(Filename; Rec.Filename)
                {
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links)
            {
                Visible = false;
            }
            systempart(Notes; Notes)
            {
                Visible = true;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            // TODO: action("EDI Message Type")
            // {
            //     Caption = 'EDI Message Type';
            //     Image = "Event";
            //     RunObject = page 90001;
            //     RunPageLink = Code = field("EDI Message Type");
            // }
            group("M&essage")
            {
                Caption = 'M&essage';
                Image = "Order";
                action(MessageDetails)
                {
                    Caption = 'Message Details';
                    Image = Log;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortcutKey = 'Shift+Ctrl+L';

                    trigger OnAction()
                    begin
                        Rec.ShowEDIMessageDetails();
                    end;
                }
            }
        }
        area(Processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                // TODO: action("Pr&ocess")
                // {
                //     Caption = 'Pr&ocess';
                //     Image = PostOrder;
                //     Promoted = true;
                //     PromotedCategory = Process;
                //     PromotedIsBig = true;
                //     ShortcutKey = 'F9';

                //     trigger OnAction()
                //     begin
                //         Codeunit.RUN(Codeunit::"Outb. EDI Msg.-Process (Y/N)", Rec);
                //     end;
                // }
            }
        }
    }
}

