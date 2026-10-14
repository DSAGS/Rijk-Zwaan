page 50107 "RZW Inb. EDI Message-New"
{
    Caption = 'Inbound EDI Message - New';
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "RZW EDI Message Header";
    SourceTableView = SORTING(Direction, "Run No.")
                      WHERE(Direction = FILTER(Inbound),
                            Status = FILTER(New));

    layout
    {
        area(content)
        {
            group()
            {
                field("EDI Message Type"; "EDI Message Type")
                {
                }
                field("Run No."; "Run No.")
                {
                }
                field("File Type"; "File Type")
                {
                }
                field(Company; Company)
                {
                    Caption = 'Target Company';
                }
            }
            part(EDIMessageLines; 90010)
            {
                SubPageLink = EDI Message Type=FIELD(EDI Message Type),
                              Run No.=FIELD(Run No.);
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Creation Date"; "Creation Date")
                {
                    Importance = Promoted;
                }
                field("Creation Time"; "Creation Time")
                {
                }
                field(Filename; Filename)
                {
                }
            }
        }
        area(factboxes)
        {
            systempart(; Links)
            {
                Visible = false;
            }
            systempart(; Notes)
            {
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("EDI Message Type")
            {
                Caption = 'EDI Message Type';
                Image = "Event";
                RunObject = Page 90001;
                RunPageLink = Code = FIELD(EDI Message Type);
            }
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
                    ShortCutKey = 'Shift+Ctrl+L';

                    trigger OnAction()
                    begin
                        ShowEDIMessageDetails;
                    end;
                }
                action("Show File")
                {
                    Caption = 'Sh&ow File';
                    Image = MakeOrder;

                    trigger OnAction()
                    begin
                        ShowFile;
                    end;
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Pr&ocess")
                {
                    Caption = 'Pr&ocess';
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        CODEUNIT.RUN(CODEUNIT::"Inb. EDI Msg.-Process (Y/N)", Rec);
                    end;
                }
            }
        }
    }
}

