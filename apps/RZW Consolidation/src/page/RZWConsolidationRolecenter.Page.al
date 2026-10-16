namespace dsa.rzw.consolidation;

page 50153 "RZW Consolidation Rolecenter"
{
    ApplicationArea = All;
    Caption = 'Rijk Zwaan Consolidation';
    PageType = RoleCenter;
    layout
    {
        area(rolecenter)
        {


        }
    }
    actions
    {
        area(Processing)
        {
            group(PeriodicActivities)
            {
                Caption = 'Periodic Activities';
                action("Create Consolidated Data File")
                {
                    Caption = 'Create Consolidated Data File';
                    RunObject = report "RZW Consol. Reporting Export";
                    ToolTip = 'Export the consolidated data file.';
                    Image = Setup;
                }
            }
            group(Setup)
            {
                Caption = 'Setup';
                action("Consolidation Setup")
                {
                    Caption = 'Consolidation Setup';
                    RunObject = page "RZW Consolidation Setup";
                    ToolTip = 'View or edit the consolidation setup.';
                    Image = Setup;
                }
                action("Consolidation Reporting Accounts")
                {
                    Caption = 'Consolidation Reporting Accounts';
                    RunObject = page "RZW Consol. Reporting Accounts";
                    ToolTip = 'View or edit the consolidation reporting accounts.';
                    Image = Setup;
                }
                action("Consolidation Reporting Periods")
                {
                    Caption = 'Consolidation Reporting Periods';
                    RunObject = page "RZW Consol. Reporting Periods";
                    ToolTip = 'View or edit the consolidation reporting periods.';
                    Image = Setup;
                }
            }
        }
    }
}
