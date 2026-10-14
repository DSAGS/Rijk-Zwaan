page 50109 "RZW Inb. EDI Message-Processed"
{
    Caption = 'Inbound EDI Message- Processed';
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = Table90010;
    SourceTableView = SORTING(Direction, Run No.)
                      WHERE(Direction = FILTER(Inbound),
                            Status = FILTER(Processed));

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
    }
}

