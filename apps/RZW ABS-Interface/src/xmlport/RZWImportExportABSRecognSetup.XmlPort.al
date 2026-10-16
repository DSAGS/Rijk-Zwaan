namespace dgs.rzw.abs;
xmlport 50102 "RZW ImportExportABSRecognSetup"
{
    Caption = 'Import/Export ABS Recognition Setup';

    schema
    {
        textelement(ABSRecoginition)
        {
            tableelement("ABS Item Recognition Code"; "RZW ABS Item Recognition Code")
            {
                XmlName = 'ABSItemRecognition';
                fieldelement(Code; "ABS Item Recognition Code".Code)
                {
                }
                fieldelement(Description; "ABS Item Recognition Code".Description)
                {
                }
            }
            tableelement("ABS VAT Recognition Code"; "RZW ABS VAT Recognition Code")
            {
                XmlName = 'ABSVATRecognition';
                fieldelement(Code; "ABS VAT Recognition Code".Code)
                {
                }
                fieldelement(Description; "ABS VAT Recognition Code".Description)
                {
                }
            }
            tableelement("ABS Recognition Setup"; "RZW ABS Recognition Setup")
            {
                XmlName = 'ABSRecognitionSetup';
                fieldelement(ABSItemRecognitionCode; "ABS Recognition Setup"."ABS Item Recognition Code")
                {
                }
                fieldelement(ABSVATRecognitionCode; "ABS Recognition Setup"."ABS VAT Recognition Code")
                {
                }
                fieldelement(Type; "ABS Recognition Setup".Type)
                {
                }
                fieldelement(No; "ABS Recognition Setup"."No.")
                {
                }
                fieldelement(Description; "ABS Recognition Setup".Description)
                {
                }
                fieldelement(GenProdPostinGroup; "ABS Recognition Setup"."Gen. Prod. Posting Group")
                {
                }
                fieldelement(VATProdPostinGroup; "ABS Recognition Setup"."VAT Prod. Posting Group")
                {
                }
                fieldelement(Blocked; "ABS Recognition Setup".Blocked)
                {
                }
                fieldelement(PaymentDiscount; "ABS Recognition Setup"."Payment Discount")
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }
}

