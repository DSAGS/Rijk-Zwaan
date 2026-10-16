namespace dsa.rzw.consolidation;

permissionset 50150 RZWConsolidation
{
    Assignable = true;
    Permissions = tabledata "RZW Consol. Setup" = RIMD,
        table "RZW Consol. Setup" = X,
        tabledata "RZW Consol. Reporting Account" = RIMD,
        table "RZW Consol. Reporting Account" = X,
        page "RZW Consolidation Setup" = X,
        tabledata "RZW Consol. Buffer" = RIMD,
        table "RZW Consol. Buffer" = X,
        tabledata "RZW Consol. Period" = RIMD,
        table "RZW Consol. Period" = X;
}