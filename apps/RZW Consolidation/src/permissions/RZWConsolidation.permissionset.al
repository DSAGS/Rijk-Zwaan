namespace dsa.rzw.consolidation;

permissionset 50150 RZWConsolidation
{
    Assignable = true;
    Permissions = tabledata "RZW Consol. Setup" = RIMD,
        table "RZW Consol. Setup" = X,
        tabledata "RZW Consol. Reporting Account" = RIMD,
        table "RZW Consol. Reporting Account" = X,
        page "RZW Consolidation Setup" = X,
        tabledata "RZW Consol. Reporting Buffer" = RIMD,
        table "RZW Consol. Reporting Buffer" = X,
        tabledata "RZW Consol. Reporting Period" = RIMD,
        table "RZW Consol. Reporting Period" = X;
}