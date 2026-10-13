namespace RZW;

using RZW;

permissionset 50100 RZWPermissions
{
    Assignable = true;
    Permissions = table "RZW ABS Interface Comp. Setup" = X,
        tabledata "RZW ABS Interface Comp. Setup" = RIMD,
        table "RZW ABS Item Recognition Code" = X,
        tabledata "RZW ABS Item Recognition Code" = RIMD,
        table "RZW ABS Recognition Setup" = X,
        tabledata "RZW ABS Recognition Setup" = RIMD,
        table "RZW ABS Record Type" = X,
        tabledata "RZW ABS Record Type" = RIMD,
        table "RZW ABS Record Type Setup" = X,
        tabledata "RZW ABS Record Type Setup" = RIMD,
        table "RZW ABS VAT Recognition Code" = X,
        tabledata "RZW ABS VAT Recognition Code" = RIMD,
        table "RZW EDI Setup" = X,
        tabledata "RZW EDI Setup" = RIMD,
        tabledata "RZW EDI Message Header" = RIMD,
        tabledata "RZW EDI Message Line" = RIMD,
        tabledata "RZW EDI Message Line Detail" = RIMD,
        tabledata "RZW EDI Message Type" = RIMD,
        table "RZW EDI Message Header" = X,
        table "RZW EDI Message Line" = X,
        table "RZW EDI Message Line Detail" = X,
        table "RZW EDI Message Type" = X,
        codeunit "RZW EDI Message Type Mgt." = X,
        codeunit "RZW Outb. EDI Msg. Process" = X,
        page = X,
        page = X,
        page = X,
        page = X,
        page = X,
        page = X,
        page = X,
        page "RZW Inb. EDI Message Details" = X,
        page "RZW Outb. EDI Message Details" = X;
}