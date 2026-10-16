namespace dsa.rzw.consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;
using System.IO;
using System.Utilities;
page 50150 "RZW Consolidation Setup"
{
    ApplicationArea = All;
    Caption = 'Rijk Zwaan Consolidation Setup';
    PageType = Card;
    SourceTable = "RZW Consol. Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Organizational Code"; Rec."Organizational Code")
                {

                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(CreateFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create File';
                Tooltip = 'Creates a consolidation export file.';
                trigger OnAction()
                var
                    GLAccount: Record "G/L Account";
                    TempBLOB: codeunit "Temp BLOB";
                    FileManagement: Codeunit "File Management";
                    OutStream: OutStream;
                    ExportValue: Text;
                    Lf: Text;
                    Cr: Char;
                begin
                    TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);

                    Cr := 13;
                    Lf[1] := Cr;
                    Cr := 10;
                    Lf[2] := Cr;

                    GLAccount.FindSet();
                    Repeat
                        GLAccount.CalcFields("Net Change");
                        ExportValue := FORMAT(GLAccount."Net Change", 0, '<Sign><Integer><Decimals>');
                        ExportValue := CONVERTSTR(ExportValue, ',', '.');

                        OutStream.WriteText(STRSUBSTNO('%1;%2%3', GLAccount."No.", ExportValue, Lf));
                    Until GLAccount.Next() = 0;

                    FileManagement.BLOBExport(TempBlob, 'Consol. Export.txt', true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
