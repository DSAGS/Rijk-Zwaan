namespace dsa.rzw.consolidation;
table 50153 "RZW Consol. Period"
{
    Caption = 'Consol. Period';
    DataClassification = CustomerContent;
    LookupPageId = "RZW Consol. Periods";

    fields
    {
        field(1; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;
            ToolTip = 'Specifies the date that the reporting period will begin.';

            trigger OnValidate()
            begin
                Name := Format("Starting Date", 0, MonthTxt);
            end;
        }
        field(2; Name; Text[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the reporting period.';
        }
        field(3; "New Fiscal Year Consol. Comp."; Boolean)
        {
            Caption = 'New Fiscal Year Consol. Company';
            ToolTip = 'Indicates whether the reporting period belongs to a new fiscal year for the consolidation company.';
            Editable = false;
        }
        field(4; Reported; Boolean)
        {
            Caption = 'Reported';
            ToolTip = 'Specifies if the reporting period has been reported.';
        }
        field(5; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
            ToolTip = 'Specifies if the reporting period belongs to a closed fiscal year.';
        }
    }
    keys
    {
        key(PK; "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "New Fiscal Year Consol. Comp.")
        {

        }
        key(Key3; Reported)
        {

        }
    }

    var
        MonthTxt: Label '<Month Text>', Locked = true;
}
