namespace dgs.rzw.abs;

using System.IO;
codeunit 50117 "RZWIm-/Export ABS Record Types"
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
        Text001: Label 'Export ABS Record Setup,Import ABS Record Setup';
        Text002: Label 'DYNAMICS NAV ABS Record Settings.xml';
        Text003: Label 'Select file to import';
        Text004: Label 'Import from XML File';
        Text005: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        Text006: Label 'This action will replace the current ABS Record Setup.\Are you sure you want to proceed?';
        Text007: Label 'Action cancelled.';

    internal procedure ExportSetup()
    var
        FileManagement: Codeunit "File Management";
        ExchangeABSData: XMLport "RZW ImportExportABSRecordTypes";
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
        ABSRecordType: Record "RZW ABS Record Type";
        ExchangeABSData: XMLport "RZW ImportExportABSRecordTypes";
        IFile: File;
        FileName: Text[250];
        StartFileName: Text[250];
        IStr: InStream;
    begin
        //TODO: REwrite so this export process works with Azure BLOB storage.
        // IF NOT CONFIRM(Text006, FALSE) THEN
        //     ERROR(Text007);
        // IF NOT (UPLOAD(Text004, '', Text005, '', FileName)) THEN
        //     FileName := '';
        // IF FileName = '' THEN
        //     EXIT;

        // ABSRecordType.DELETEALL(TRUE);

        // IFile.OPEN(FileName);
        // IFile.CREATEINSTREAM(IStr);
        // ExchangeABSData.SETSOURCE(IStr);
        // ExchangeABSData.IMPORT;
        // IFile.CLOSE;
    end;
}

