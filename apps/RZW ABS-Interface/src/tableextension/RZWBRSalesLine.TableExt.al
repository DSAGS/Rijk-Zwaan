namespace dgs.rzw.abs;

using Microsoft.Foundation.Address;
using Microsoft.Sales.Document;

tableextension 50101 "RZW BR Sales Line" extends "Sales Line"
{
    fields
    {
        field(50100; "RZW BR Ctry/Reg.of Origin Code"; code[10])
        {
            Caption = 'Country/Region of Origin Code';
            DataClassification = CustomerContent;
            AllowInCustomizations = AsReadWrite;
            TableRelation = "Country/Region";
        }
        field(50101; "RZW BR ABS Item No."; code[20])
        {
            Caption = 'RZW BR ABS Item No.';
            DataClassification = CustomerContent;
            AllowInCustomizations = AsReadWrite;
        }
        field(50103; "RZW BR Batch No."; code[20])
        {
            Caption = 'RZW BR Batch No.';
            DataClassification = CustomerContent;
            AllowInCustomizations = AsReadWrite;
        }
    }
}
