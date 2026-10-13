namespace RZW;

permissionset 50100 RZWPermissions
{
    Assignable = true;
    Permissions = tabledata "RZW ABS Item Recognition Code" = RIMD,
        tabledata "RZW EDI Setup" = RIMD,
        table "RZW ABS Item Recognition Code" = X,
        table "RZW EDI Setup" = X,
        tabledata "RZW ABS Recognition Setup" = RIMD,
        tabledata "RZW ABS VAT Recognition Code" = RIMD,
        table "RZW ABS Recognition Setup" = X,
        table "RZW ABS VAT Recognition Code" = X;

}