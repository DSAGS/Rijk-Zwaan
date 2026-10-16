namespace dgs.rzw.abs;
page 50100 "RZW EDI Setup"
{
    Caption = 'EDI Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "RZW EDI Setup";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group("Import Settings")
            {
                Caption = 'Import Settings';
                field("Remove Leading Zeros"; Rec."Remove Leading Zeros") { }
                field("Clear LCY from Currency Codes"; Rec."Clear LCY from Currency Codes") { }
                field("Skip Bank Data in Import"; Rec."Skip Bank Data in Import") { }
                field("Off-Line Text"; Rec."Off-Line Text") { }
                field("VAT calculation"; Rec."VAT calculation") { }
                field("VAT Correction Account G/L"; Rec."VAT Correction Account G/L")
                {
                    Caption = 'VAT Correction Account G/L';
                    Enabled = CorrectionAccountEnabled;
                    ShowMandatory = CorrectionAccountEnabled;
                }
            }
            group(Defaults)
            {
                Caption = 'Defaults';
                group(Default)
                {
                    Caption = 'Default';
                    field("Def. Customer Posting Group"; Rec."Def. Customer Posting Group")
                    {
                        Caption = 'Customer Posting Group';
                    }
                    field("Def. Vendor Posting Group"; Rec."Def. Vendor Posting Group")
                    {
                        Caption = 'Vendor Posting Group';
                    }
                    field("Def. Gen. Bus. Posting Group"; Rec."Def. Gen. Bus. Posting Group")
                    {
                        Caption = 'Gen. Bus. Posting Group';
                    }
                    field("Def. VAT Bus. Posting Group"; Rec."Def. VAT Bus. Posting Group")
                    {
                        Caption = 'VAT Bus. Posting Group';
                    }
                    field("Def. Item Recognition Code"; Rec."Def. Item Recognition Code")
                    {
                        Caption = 'Item Recognition Code';
                    }
                    field("Def. VAT Recognition Code"; Rec."Def. VAT Recognition Code")
                    {
                        Caption = 'VAT Recognition Code';
                    }
                    field("Default Payment Terms Code"; Rec."Default Payment Terms Code")
                    {
                        Caption = 'Payment Terms Code';
                    }
                }
            }
        }
    }

    actions { }

    var
        CorrectionAccountEnabled: Boolean;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        CorrectionAccountEnabled := Rec."VAT calculation" = Rec."VAT calculation"::"Imported From Source";
    end;
}
