namespace RZW;

using Microsoft.Foundation.NoSeries;
using System.Environment;
table 50108 "RZW EDI Message Header"
{
    Caption = 'EDI Message Header';
    DataPerCompany = false;
    // DrillDownPageID = 90003;
    // LookupPageID = 90003;
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;

    fields
    {
        field(1; "EDI Message Type"; Code[20])
        {
            Caption = 'EDI Message Type';
            TableRelation = "RZW EDI Message Type";
        }
        field(2; "Run No."; Code[20])
        {
            Caption = 'Run No.';
            Editable = false;
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(5; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            Editable = false;
        }
        field(9; Filename; Text[240])
        {
            Caption = 'Filename';
            Editable = false;
        }
        field(10; "Qty. of Documents"; Decimal)
        {
            CalcFormula = sum("RZW EDI Message Line"."Line Counter" where("EDI Message Type" = field("EDI Message Type"),
                                                                       "Run No." = field("Run No.")));
            Caption = 'Qty. of Documents';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "No. Series"; Code[10])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(12; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'New,Rejected,Processed';
            OptionMembers = New,Rejected,Processed;
        }
        field(13; "Line Counter"; Decimal)
        {
            InitValue = 1;
        }
        field(21; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Inbound,Outbound';
            OptionMembers = Inbound,Outbound;
        }
        field(24; "File Type"; Option)
        {
            Caption = 'File Type';
            OptionCaption = ' ,Sales Invoice,Purchase Invoice,Customer Master,Vendor Master,Customer Balance';
            OptionMembers = " ","Sales Invoice","Purchase Invoice","Customer Master","Vendor Master","Customer Balance";
        }
        field(30; Company; Text[30])
        {
            Caption = 'Company';
            TableRelation = Company;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "EDI Message Type", "Run No.")
        {
            Clustered = true;
            SumIndexFields = "Line Counter";
        }
        key(Key2; Company)
        {
        }
        key(Key3; Status)
        {
            SumIndexFields = "Line Counter";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        EDIMessageLine: Record "RZW EDI Message Line";
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLine.SETRANGE("EDI Message Type", "EDI Message Type");
        EDIMessageLine.SETRANGE("Run No.", "Run No.");
        if not EDIMessageLine.ISEMPTY then
            EDIMessageLine.DELETEALL(true);

        EDIMessageLineDetail.SETRANGE("EDI Message Type", "EDI Message Type");
        EDIMessageLineDetail.SETRANGE("Run No.", "Run No.");
        if not EDIMessageLineDetail.ISEMPTY then
            EDIMessageLineDetail.DELETEALL;

        if EXISTS(Filename) then
            ERASE(Filename);
    end;

    trigger OnInsert()
    var
        NoSeriesMgt: Codeunit "No. Series";
    begin
        if "Run No." = '' then begin
            EDIMessageType.GET("EDI Message Type");
            EDIMessageType.TESTFIELD("Message No. Series");
            NoSeriesMgt.InitSeries(EDIMessageType."Message No. Series", xRec."No. Series", WorkDate(), "Run No.", "No. Series");
        end;
    end;

    var
        EDIMessageType: Record "90009";
        FileManagement: Codeunit "File Management";
        EDIExportFile: File;
        LineEntryNo: Integer;
        Text001: Label 'The data is being written to a file...';
        Text002: Label 'No lines found...';
        Text004: Label 'File %1 is created. ';
        Text006: Label 'A file with name %1 already exists.';
        Text007: Label '%1 %2 for %3 %4 contains lines for which the %5 is less than %6 ago. It cannot be deleted.';
        LineEnd: ;

    [Scope('Internal')]
    procedure ShowCard()
    var
        EDIMessageHeader: Record "RZW EDI Message Header";
    begin
        EDIMessageHeader.GET("EDI Message Type", "Run No.");
        case Direction of
            Direction::Inbound:
                case Status of
                    Status::New:
                        Page.RUN(Page::"RZW Inb. EDI Message-New", EDIMessageHeader);
                    Status::Rejected:
                        Page.RUN(Page::"Inb. EDI Message - Rejected", EDIMessageHeader);
                    Status::Processed:
                        Page.RUN(Page::"RZW Inb. EDI Message-Processed", EDIMessageHeader);
                end;
            Direction::Outbound:
                case Status of
                    Status::New:
                        Page.RUN(Page::"Outb. EDI Message - New", EDIMessageHeader);
                    Status::Rejected:
                        Page.RUN(Page::"Outb. EDI Message - Rejected", EDIMessageHeader);
                    Status::Processed:
                        Page.RUN(Page::"Outb. EDI Message - Processed", EDIMessageHeader);
                end;
        end;
    end;

    [Scope('Internal')]
    procedure ShowEDIMessageDetails()
    var
        EDIMessageLineDetails: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetails.SetRange("EDI Message Type", "EDI Message Type");
        EDIMessageLineDetails.SetRange("Run No.", "Run No.");

        case Direction of
            Direction::Inbound:
                Page.Run(Page::"RZW Inb. EDI Message Details", EDIMessageLineDetails);
            Direction::Outbound:
                Page.Run(Page::"RZW Outb. EDI Message Details", EDIMessageLineDetails);
        end;
    end;

    procedure ShowFile()
    begin
        Hyperlink(Filename);
    end;

    procedure WriteDetailLine(UseFieldNo: Integer; UseFieldContents: Text)
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        // SCHRIJF DETAIL REGEL
        EDIMessageLineDetail.Init();
        EDIMessageLineDetail."EDI Message Type" := "EDI Message Type";
        EDIMessageLineDetail."Run No." := "Run No.";
        EDIMessageLineDetail."Line No." := LineEntryNo;
        EDIMessageLineDetail."Field No." := UseFieldNo;
        EDIMessageLineDetail.Content := copystr(UseFieldContents, 1, maxstrlen(EDIMessageLineDetail.Content));
        EDIMessageLineDetail.Insert();
    end;

    procedure ReCreateTextFile()
    begin
        //TODO:  Delete existing file if necessary
        // IF EXISTS(Filename) THEN
        //     ERASE(Filename);
        CreateTextFile(true);
    end;

    procedure CreateTextFile(ShowMessage: Boolean)
    var
        EDIMessageType: Record "RZW EDI Message Type";
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
        OldLineNo: Integer;
        Buffer: Text[250];
        TextFilename: Text[250];
        CopyFileName: Text[250];
        Window: Dialog;
    begin
        //TODO:  Delete existing file if necessary
        // IF Filename <> '' THEN BEGIN
        //     IF EXISTS(Filename) THEN
        //         ERROR(Text006, Filename);
        // END;

        EDIMessageType.Get("EDI Message Type");

        EDIMessageType.TestFolder(EDIMessageType."Source/Target Folder");

        if EDIMessageType."Fixed File Name" <> '' then
            TextFilename := StrSubstNo('%1\%2.txt', EDIMessageType."Source/Target Folder", EDIMessageType."Fixed File Name")
        else
            TextFilename := StrSubstNo('%1\%2-%3.txt', EDIMessageType."Source/Target Folder", "EDI Message Type", "Run No.");

        if EDIMessageType."Save a File Copy" then begin
            EDIMessageType.TestFolder(EDIMessageType."Copy Folder");
            CopyFileName := StrSubstNo('%1\%2-%3.txt', EDIMessageType."Copy Folder", "EDI Message Type", "Run No.");
        end;

        if GuiAllowed then
            Window.Open(Text001);

        Clear(EDIExportFile);
        EDIExportFile.TEXTMODE(true);
        EDIExportFile.WRITEMODE(true);
        EDIExportFile.CREATE(TextFilename);

        EDIMessageLineDetail.SetRange("EDI Message Type", "EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", "Run No.");
        if EDIMessageLineDetail.FindSet() then
            repeat
                if EDIMessageLineDetail."Line No." = OldLineNo then
                    Buffer := Buffer + EDIMessageLineDetail.Content
                else begin
                    // First write the Buffer
                    if Buffer <> '' then
                        EDIExportFile.WRITE(STRSUBSTNO('%1%2', Buffer, LineEnd));
                    Buffer := EDIMessageLineDetail.Content;
                end;
                OldLineNo := EDIMessageLineDetail."Line No.";
            until EDIMessageLineDetail.Next() = 0;

        // Write the last Line!
        if Buffer <> '' then
            EDIExportFile.WRITE(STRSUBSTNO('%1%2', Buffer, LineEnd));
        EDIExportFile.CLOSE;

        Filename := TextFilename;
        Modify();

        // Save a Copy on another location
        if EDIMessageType."Save a File Copy" then begin
            FileManagement.CopyServerFile(TextFilename, CopyFileName, true);
            if File.EXISTS(CopyFileName) then
                File.ERASE(CopyFileName);
            File.COPY(TextFilename, CopyFileName);

            Filename := CopyFileName;
            Modify();
        end;

        if GuiAllowed then
            Window.Close();

        if ShowMessage then
            Message(Text004, Filename);
    end;

    [Scope('Internal')]
    procedure InitLineEntryNo()
    begin
        LineEntryNo := 1;
    end;

    [Scope('Internal')]
    procedure IncrLineEntryNo()
    begin
        LineEntryNo := LineEntryNo + 1;
    end;

    [Scope('Internal')]
    procedure GetLineEntryNo(): Integer
    begin
        exit(LineEntryNo);
    end;
}

