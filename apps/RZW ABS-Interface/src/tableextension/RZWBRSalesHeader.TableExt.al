namespace RZW;

using Microsoft.Sales.Document;

tableextension 50100 "RZW BR Sales Header" extends "Sales Header"
{
    fields
    {
        field(50100; "RZW BR ABS Order Reference"; code[20])
        {
            Caption = 'ABS Order Reference';
            DataClassification = CustomerContent;
            AllowInCustomizations = AsReadWrite;
        }
    }
}
