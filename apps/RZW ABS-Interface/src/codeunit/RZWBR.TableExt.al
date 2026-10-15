namespace RZW;

using Microsoft.Sales.Document;

tableextension 50100 "RZW BR " extends "Sales Header"
{
    fields
    {
        field(50103; "RZW BR ABS Order Reference"; code[20])
        {
            Caption = 'RZW BR ABS';
            DataClassification = CustomerContent;
            AllowInCustomizations = AsReadWrite;
        }
    }
}
