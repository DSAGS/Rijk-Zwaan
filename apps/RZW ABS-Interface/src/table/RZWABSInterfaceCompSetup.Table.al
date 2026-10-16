namespace dgs.rzw.abs;

using System.Environment;
table 50104 "RZW ABS Interface Comp. Setup"
{
    Caption = 'ABS Interface Company Setup';
    DataPerCompany = false;
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;
    fields
    {
        field(1; "ABS Company Code"; Code[10])
        {
            Caption = 'ABS Company Code';
        }
        field(2; Company; Text[30])
        {
            Caption = 'Company';
            TableRelation = Company;

            trigger OnValidate()
            var
                ABSInterfaceCompany: Record "RZW ABS Interface Comp. Setup";
            begin
                ABSInterfaceCompany.SetCurrentKey(Company);
                ABSInterfaceCompany.SetRange(Company, Company);
                ABSInterfaceCompany.SetFilter("ABS Company Code", '<>%1', "ABS Company Code");
                if ABSInterfaceCompany.FindFirst() then
                    Error(
                      AlreadyAttachedErr, ABSInterfaceCompany.FieldCaption("ABS Company Code"),
                      ABSInterfaceCompany."ABS Company Code", ABSInterfaceCompany.Company);
            end;
        }
        field(16; "Qty. of New Messages"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("RZW EDI Message Header"."Line Counter" where(Status = const(New),
                                                                         Company = field(Company),
                                                                         "EDI Message Type" = field("EDI Message Type Filter")));
            Caption = 'Qty. of New Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Qty. of Rejected Messages"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("RZW EDI Message Header"."Line Counter" where(Status = const(Rejected),
                                                                         Company = field(Company),
                                                                         "EDI Message Type" = field("EDI Message Type Filter")));
            Caption = 'Qty. of Rejected Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Qty. of Processed Messages"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("RZW EDI Message Header"."Line Counter" where(Status = const(Processed),
                                                                         Company = field(Company),
                                                                         "EDI Message Type" = field("EDI Message Type Filter")));
            Caption = 'Qty. of Processed Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "EDI Message Type Filter"; Code[250])
        {
            Caption = 'EDI Message Type Filter';
            FieldClass = FlowFilter;
            TableRelation = "RZW EDI Message Type";
        }
    }

    keys
    {
        key(Key1; "ABS Company Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        AlreadyAttachedErr: Label '%1 %2 is already attached to %3. Check if the setup is OK.', Comment = '%1=Table Name, %2=Field Name, %3=Existing Value';
}
