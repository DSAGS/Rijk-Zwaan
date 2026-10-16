namespace dgs.rzw.abs;
xmlport 50101 "RZW ImportExportABSRecordTypes"
{
    Caption = 'Import/Export ABS Record Types';

    schema
    {
        textelement(ABSRecordTypes)
        {
            tableelement("ABS Record Type"; "RZW ABS Record Type")
            {
                XmlName = 'ABSRecordType';
                fieldelement(Code; "ABS Record Type".Code)
                {
                }
                fieldelement(Description; "ABS Record Type".Description)
                {
                }
                fieldelement(FileType; "ABS Record Type"."File Type")
                {
                }
                tableelement("ABS Record Type Setup"; "RZW ABS Record Type Setup")
                {
                    LinkFields = "ABS Record Type Code" = FIELD(Code);
                    LinkTable = "ABS Record Type";
                    XmlName = 'ABSRecordTypeSetup';
                    fieldelement(FieldNo; "ABS Record Type Setup"."Field No.")
                    {
                    }
                    fieldelement(FieldName; "ABS Record Type Setup"."Field Name")
                    {
                    }
                    fieldelement(DescriptiveField; "ABS Record Type Setup"."Descriptive Field")
                    {
                    }
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

