namespace dgs.rzw.abs;

using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.IO;
using System.Reflection;
using System.Utilities;
codeunit 50110 "RZW EDI Message Type Mgt."
{
    TableNo = "RZW EDI Message Type";

    trigger OnRun()
    begin
        ClearAll();
        EDIMessageType := Rec;

        with EDIMessageType do begin
            if not HideDialog then
                Window.Open(Text001);

            TestField(Blocked, false);

            TestField("Object Type");
            TestField("Object ID");
            TestField("Source/Target Folder");

            TestFolder("Source/Target Folder");
            if "Save a File Copy" then begin
                TestField("Copy Folder");
                TestFolder("Copy Folder");
            end;

            case Direction of
                Direction::Inbound:
                    ProcessInbound();
                Direction::Outbound:
                    ProcessOutbound();
            end;

            if not HideDialog then
                Window.Close();
            Commit();
        end;
        Rec := EDIMessageType;
    end;

    var
        EDIMessageType: Record "RZW EDI Message Type";
        EDIMessageHeader: Record "RZW EDI Message Header";
        Cust: Record Customer;
        TempObjectGlobal: Record AllObjWithCaption temporary;
        Window: Dialog;
        HideDialog: Boolean;
        Text001: Label 'One moment please....';
        Text002: Label 'Source file deleted.';

    local procedure ProcessInbound()
    var
        EDIMessageHeader2: Record "RZW EDI Message Header";
        //  EDIInputFile: Record "File"; // TODO: list  of files that are to be processed
        // EDIImportData: XmlPort "90000";
        FileMgt: Codeunit "File Management";
        // InbEDIMessageProcess: Codeunit "RZW Inb. EDI Msg.-Process";
        ServerFileName: Text;
        TempBlob: Codeunit "Temp Blob";
        NVInstream: InStream;
        MySessionID: Integer;
        MaxWaitingTime: Integer;
        i: Integer;
        Continue: Boolean;
    begin
        // EDIInputFile.SETCURRENTKEY(Date, Time);
        // EDIInputFile.SETRANGE(Path, DELCHR("Source/Target Folder", '>', '\'));
        // EDIInputFile.SETRANGE("Is a file", TRUE);
        // IF NOT EDIInputFile.FINDFIRST THEN
        //     EXIT;
        repeat
            Clear(EDIMessageHeader);

            case EDIMessageType."Object Type" of
                EDIMessageType."Object Type"::XMLPort:
                    case EDIMessageType."Object ID" of
                        90000:
                            // Import All Files
                            begin
                                CreateEDIMessage(EDIMessageHeader, EDIMessageType.Code, 0);

                                TempBlob.CreateInStream(NVInstream);

                                // EDIImportData.SETSOURCE(NVInstream);
                                // EDIImportData.InitializeXMLport(EDIMessageHeader);
                                // EDIImportData.IMPORT;

                                // EDIImportData.GetFileType(EDIMessageHeader."File Type", EDIMessageHeader.Company);

                                if EDIMessageType."Save a File Copy" then begin
                                    EDIMessageHeader.Filename :=
                                      StrSubstNo('%1\%2.%3', DelChr(EDIMessageType."Copy Folder", '>', '\'), EDIMessageHeader."Run No.", 'txt');
                                    // if File.EXISTS(EDIMessageHeader.Filename) then
                                    //     File.ERASE(EDIMessageHeader.Filename);
                                    // File.RENAME(EDIInputFile.Path + '\' + EDIInputFile.Name, EDIMessageHeader.Filename);
                                end else begin
                                    EDIMessageHeader.Filename := Text002;
                                    // File.ERASE(EDIInputFile.Path + '\' + EDIInputFile.Name);
                                end;
                                FinalizeEDIMessage(EDIMessageHeader);

                                // CLEAR(EDIImportData);
                            end;
                    end;
            end;
        until true; // TODO: replace with actual file iteration logic, e.g., EDIInputFile.NEXT = 0;
        Commit();

        // Verify whether inbound messages may be processed automatically
        if not EDIMessageType."Auto-Process" then
            exit;

        EDIMessageHeader.SetCurrentKey(Status, Direction);
        EDIMessageHeader.SetRange(Status, EDIMessageHeader.Status::New);
        EDIMessageHeader.SetRange(Direction, EDIMessageHeader.Direction::Inbound);
        if not EDIMessageHeader.FindSet() then
            exit;

        MaxWaitingTime := 5000;
        repeat
            EDIMessageHeader2 := EDIMessageHeader;

            if (EDIMessageHeader.Company = CompanyName) then begin
                // if InbEDIMessageProcess.RUN(EDIMessageHeader2) then;
            end else begin
                MySessionID := 0;
                // STARTSESSION(MySessionID, Codeunit::"RZW Inb. EDI Msg.-Process", EDIMessageHeader.Company, EDIMessageHeader2);

                Continue := false;
                i := 0;
                repeat
                    EDIMessageHeader2.Get(EDIMessageHeader."EDI Message Type", EDIMessageHeader."Run No.");
                    if EDIMessageHeader2.Status = EDIMessageHeader2.Status::Processed then begin
                        StopSession(MySessionID);
                        Continue := true;
                    end;
                    if i > MaxWaitingTime then
                        Continue := true;
                    if not Continue then begin
                        i := i + 1;
                        Sleep(1000);
                    end;
                until Continue;
            end;
        until EDIMessageHeader.Next() = 0;
    end;

    local procedure ProcessOutbound()
    var
        EDIMessageHeader2: Record "RZW EDI Message Header";
        // ExportABSCustBalance: Report "90001";
        OutbEDIMessageProcess: Codeunit "RZW Outb. EDI Msg. Process";
        MySessionID: Integer;
        MaxWaitingTime: Integer;
        i: Integer;
        Continue: Boolean;
    begin
        case EDIMessageType."Object Type" of
            EDIMessageType."Object Type"::Report:
                case EDIMessageType."Object ID" of
                    90001:
                        // Export Customer Balance
                        begin
                            // ExportABSCustBalance.InitializeReport(EDIMessageType);
                            // ExportABSCustBalance.USEREQUESTPAGE("Request Window");
                            // ExportABSCustBalance.RUNMODAL;
                        end;
                end;
        end;
        Commit();

        // Verify whether outbound messages may be processed automatically
        if not EDIMessageType."Auto-Process" then
            exit;

        EDIMessageHeader.SetCurrentKey(Status, Direction);
        EDIMessageHeader.SetRange(Status, EDIMessageHeader.Status::New);
        EDIMessageHeader.SetRange(Direction, EDIMessageHeader.Direction::Outbound);
        if not EDIMessageHeader.FindSet() then
            exit;

        MaxWaitingTime := 5000;
        repeat
            EDIMessageHeader2 := EDIMessageHeader;

            if (EDIMessageHeader.Company = CompanyName) then begin
                if OutbEDIMessageProcess.RUN(EDIMessageHeader2) then;
            end else begin
                MySessionID := 0;
                StartSession(MySessionID, Codeunit::"RZW Outb. EDI Msg. Process", EDIMessageHeader.Company, EDIMessageHeader2);

                Continue := false;
                i := 0;
                repeat
                    EDIMessageHeader2.Get(EDIMessageHeader."EDI Message Type", EDIMessageHeader."Run No.");
                    if EDIMessageHeader2.Status = EDIMessageHeader2.Status::Processed then begin
                        StopSession(MySessionID);
                        Continue := true;
                    end;
                    if i > MaxWaitingTime then
                        Continue := true;
                    if not Continue then begin
                        i := i + 1;
                        Sleep(1000);
                    end;
                until Continue;
            end;
        until EDIMessageHeader.Next() = 0;
    end;

    internal procedure CreateEDIMessage(var EDIMessageHeader2: Record "RZW EDI Message Header"; UseCode: Code[10]; UseDirection: Option Inbound,Outbound)
    begin
        EDIMessageHeader2.Init();
        EDIMessageHeader2."EDI Message Type" := UseCode;
        EDIMessageHeader2.Direction := UseDirection;
        EDIMessageHeader2."Creation Date" := Today;
        EDIMessageHeader2."Creation Time" := Time;
        EDIMessageHeader2.Insert(true);
    end;

    internal procedure FinalizeEDIMessage(var EDIMessageHeader2: Record "RZW EDI Message Header")
    begin
        EDIMessageHeader2.Modify();
    end;

    internal procedure SetupObjectNoList(var TempObject: Record AllObjWithCaption temporary)
    var
        Object: Record AllObjWithCaption;
    begin
        TempObjectGlobal.DeleteAll();

        SetupTempObject(Object."Object Type"::Report, 90001);
        SetupTempObject(Object."Object Type"::XMLport, 90000);

        if TempObjectGlobal.FindSet() then
            repeat
                TempObject.TransferFields(TempObjectGlobal);
                TempObject.Insert();
            until TempObjectGlobal.Next() = 0;
    end;

    local procedure SetupTempObject(ObjectType: Integer; ObjectID: Integer)
    var
        Object: Record AllObjWithCaption;
    begin
        Object.SetRange("Object Type", ObjectType);
        Object.SetRange("Object ID", ObjectID);
        if not Object.FindFirst() then
            exit;

        TempObjectGlobal.Init();
        TempObjectGlobal."Object Type" := ObjectType;
        TempObjectGlobal."Object ID" := ObjectID;
        TempObjectGlobal.Insert();
    end;

    internal procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
    // InbEDIMsgProcess: Codeunit "RZW Inb. EDI Msg.-Process";

    begin
        // InbEDIMsgProcess.ChangeSalesDocStatus(Rec, 3);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    var
    // InbEDIMsgProcess: Codeunit "RZW Inb. EDI Msg.-Process";
    begin
        // InbEDIMsgProcess.ChangeSalesDocStatus(SalesHeader, 2);
    end;
}

