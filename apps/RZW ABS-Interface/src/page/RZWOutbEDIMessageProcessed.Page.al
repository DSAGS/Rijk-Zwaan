namespace dgs.rzw.abs;
page 50117 "RZW Outb.EDI Message-Processed"
{
    Caption = 'Outbound EDI Message - Processed';
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "RZW EDI Message Header";
    SourceTableView = sorting(Direction, "Run No.")
                      WHERE(Direction = FILTER(Outbound),
                            Status = FILTER(Processed));
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
                action("Show File")
                {
                    Caption = 'Sh&ow File';
                    Image = MakeOrder;

                    trigger OnAction()
                    begin
                        Rec.ShowFile();
                    end;
                }
            }
        }
        area(Processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = Post;
                action("Re-send Message")
                {
                    Caption = 'Re-send Message';
                    Image = NewStatusChange;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        Rec.ReCreateTextFile();
                    end;
                }
            }
        }
    }
}

