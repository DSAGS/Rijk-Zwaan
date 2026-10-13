namespace RZW;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 50103 "RZW ABS Recognition Setup"
{
    Caption = 'ABS Recognition Setup';
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;

    fields
    {
        field(1; "ABS Item Recognition Code"; Code[10])
        {
            Caption = 'ABS Item Recognition Code';
            TableRelation = "RZW ABS Item Recognition Code";
        }
        field(2; "ABS VAT Recognition Code"; Code[10])
        {
            Caption = 'ABS VAT Recognition Code';
            TableRelation = "RZW ABS VAT Recognition Code";
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item,Resource';
            OptionMembers = " ","G/L Account",Item,Resource;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account"
            else if (Type = const(Item)) Item
            else if (Type = const(Resource)) Resource;
        }
        field(5; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(6; "Gen. Prod. Posting Group"; Code[10])
        {
            Caption = 'Gen. Prod. Posting Group';
            NotBlank = true;
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."No." <> "No." then
                    if GenProdPostingGroup.ValidateVatProdPostingGroup(GenProdPostingGroup, "No.") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
            end;
        }
        field(7; "VAT Prod. Posting Group"; Code[10])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(9; "Payment Discount"; Boolean)
        {
            Caption = 'Payment Discount';
        }
        field(50; "Item Category Code"; Code[10])
        {
            Caption = 'Item Category Code';
            Description = 'RZWHU';
            TableRelation = "Item Category";
        }
        field(51; "Def. Costing Method"; Option)
        {
            Caption = 'Def. Costing Method';
            Description = 'RZWPT';
            OptionCaption = 'FIFO,LIFO,Specific,Average,Standard';
            OptionMembers = FIFO,LIFO,Specific,"Average",Standard;
        }
        field(52; "Def. Inventory Posting Group"; Code[10])
        {
            Caption = 'Def. Inventory Posting Group';
            Description = 'RZWPT';
            TableRelation = "Inventory Posting Group".Code;
        }
    }

    keys
    {
        key(Key1; "ABS Item Recognition Code", "ABS VAT Recognition Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
}

