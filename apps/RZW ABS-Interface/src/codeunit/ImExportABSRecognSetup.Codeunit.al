namespace dgs.rzw.abs;

using System.IO;
codeunit 50118 "Im-/Export ABS Recogn. Setup"
{

    trigger OnRun()
    var
        Selection: Integer;
    begin
        Selection := STRMENU(Text001, 1);
        IF Selection = 0 THEN
            EXIT;
        CASE Selection OF
            1:
                ExportSetup;
            2:
                ImportSetup;
        END;
    end;

    var
        Text001: Label 'Export ABS Recognition Setup,Import ABS Recognition Setup';
        Text002: Label 'DYNAMICS NAV ABS Recognition Settings.xml';
        Text003: Label 'Select file to import';
        Text004: Label 'Import from XML File';
        Text005: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        Text006: Label 'This action will replace the current ABS Record Setup.\Are you sure you want to proceed?';
        Text007: Label 'Action cancelled.';

    internal procedure ExportSetup()
    var
        FileManagement: Codeunit "File Management";
        ExchangeABSData: XMLport "RZW ImportExportABSRecognSetup";
        CurrentDT: Text[30];
        OFile: File;
        DefaultFileName: Text[250];
        FileName: Text[250];
        Ostr: OutStream;
    begin
        // TODO: REwrite so this export process works with Azure BLOB storage.
        // FileName := FileManagement.ServerTempFileName('xml');

        // CurrentDT := DELCHR(FORMAT(CURRENTDATETIME), '=', '-:');
        // DefaultFileName := Text002;

        // OFile.CREATE(FileName);
        // OFile.CREATEOUTSTREAM(Ostr);
        // ExchangeABSData.SETDESTINATION(Ostr);
        // ExchangeABSData.EXPORT;
        // OFile.CLOSE;
        // CLEAR(Ostr);
        // CLEAR(ExchangeABSData);

        // DOWNLOAD(FileName, 'Export', TEMPORARYPATH, '', DefaultFileName);
    end;

    internal procedure ImportSetup()
    var
        ABSItemRecognitionCode: Record "RZW ABS Item Recognition Code";
        ABSVATRecognitionCode: Record "RZW ABS VAT Recognition Code";
        ABSRecognitionSetup: Record "RZW ABS Recognition Setup";
        ExchangeABSData: XMLport "RZW ImportExportABSRecognSetup";
        IFile: File;
        FileName: Text[250];
        StartFileName: Text[250];
        IStr: InStream;
    begin
        // TODO: REwrite so this import process works with Azure BLOB storage.
        //  IF NOT CONFIRM(Text006, FALSE) THEN
        //     ERROR(Text007);
        // IF NOT (UPLOAD(Text004, '', Text005, '', FileName)) THEN
        //     FileName := '';
        // IF FileName = '' THEN
        //     EXIT;

        // ABSItemRecognitionCode.DELETEALL(TRUE);
        // ABSVATRecognitionCode.DELETEALL(TRUE);
        // ABSRecognitionSetup.DELETEALL(TRUE);

        // IFile.OPEN(FileName);
        // IFile.CREATEINSTREAM(IStr);
        // ExchangeABSData.SETSOURCE(IStr);
        // ExchangeABSData.IMPORT;
        // IFile.CLOSE;
    end;
}

