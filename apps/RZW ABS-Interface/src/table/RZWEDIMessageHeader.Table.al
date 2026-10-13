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
            CalcFormula = Sum("RZW EDI Message Line"."Line Counter" WHERE("EDI Message Type" = FIELD("EDI Message Type"),
                                                                       "Run No." = FIELD("Run No.")));
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
        EDIMessageLine: Record "90011";
        EDIMessageLineDetail: Record "90012";
    begin
        EDIMessageLine.SETRANGE("EDI Message Type", "EDI Message Type");
        EDIMessageLine.SETRANGE("Run No.", "Run No.");
        IF NOT EDIMessageLine.ISEMPTY THEN
            EDIMessageLine.DELETEALL(TRUE);

        EDIMessageLineDetail.SETRANGE("EDI Message Type", "EDI Message Type");
        EDIMessageLineDetail.SETRANGE("Run No.", "Run No.");
        IF NOT EDIMessageLineDetail.ISEMPTY THEN
            EDIMessageLineDetail.DELETEALL;

        IF EXISTS(Filename) THEN
            ERASE(Filename);
    end;

    trigger OnInsert()
    var
        NoSeriesMgt: Codeunit "No. Series";
    begin
        IF "Run No." = '' THEN BEGIN
            EDIMessageType.GET("EDI Message Type");
            EDIMessageType.TESTFIELD("Message No. Series");
            NoSeriesMgt.InitSeries(EDIMessageType."Message No. Series", xRec."No. Series", WORKDATE, "Run No.", "No. Series");
        END;
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
        EDIMessageHeader: Record "90010";
    begin
        EDIMessageHeader.GET("EDI Message Type", "Run No.");
        CASE Direction OF
            Direction::Inbound:
                CASE Status OF
                    Status::New:
                        PAGE.RUN(PAGE::"Inb. EDI Message - New", EDIMessageHeader);
                    Status::Rejected:
                        PAGE.RUN(PAGE::"Inb. EDI Message - Rejected", EDIMessageHeader);
                    Status::Processed:
                        PAGE.RUN(PAGE::"Inb. EDI Message - Processed", EDIMessageHeader);
                END;
            Direction::Outbound:
                CASE Status OF
                    Status::New:
                        PAGE.RUN(PAGE::"Outb. EDI Message - New", EDIMessageHeader);
                    Status::Rejected:
                        PAGE.RUN(PAGE::"Outb. EDI Message - Rejected", EDIMessageHeader);
                    Status::Processed:
                        PAGE.RUN(PAGE::"Outb. EDI Message - Processed", EDIMessageHeader);
                END;
        END;
    end;

    [Scope('Internal')]
    procedure ShowEDIMessageDetails()
    var
        EDIMessageLineDetails: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetails.SETRANGE("EDI Message Type", "EDI Message Type");
        EDIMessageLineDetails.SETRANGE("Run No.", "Run No.");

        CASE Direction OF
            Direction::Inbound:
                PAGE.RUN(PAGE::"Inb. EDI Message Details", EDIMessageLineDetails);
            Direction::Outbound:
                PAGE.RUN(PAGE::"RZW Outb. EDI Message Details", EDIMessageLineDetails);
        END;
    end;

    [Scope('Internal')]
    procedure ShowFile()
    begin
        HYPERLINK(Filename);
    end;

    [Scope('Internal')]
    procedure WriteDetailLine(UseFieldNo: Integer; UseFieldContents: Text)
    var
        EDIMessageLineDetail: Record "90012";
    begin
        // SCHRIJF DETAIL REGEL
        EDIMessageLineDetail.INIT;
        EDIMessageLineDetail."EDI Message Type" := "EDI Message Type";
        EDIMessageLineDetail."Run No." := "Run No.";
        EDIMessageLineDetail."Line No." := LineEntryNo;
        EDIMessageLineDetail."Field No." := UseFieldNo;
        EDIMessageLineDetail.Content := UseFieldContents;
        EDIMessageLineDetail.INSERT;
    end;

    procedure ReCreateTextFile()
    begin
        //TODO:  Delete existing file if necessary
        // IF EXISTS(Filename) THEN
        //     ERASE(Filename);
        CreateTextFile(TRUE);
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

        EDIMessageType.GET("EDI Message Type");

        EDIMessageType.TestFolder(EDIMessageType."Source/Target Folder");

        IF EDIMessageType."Fixed File Name" <> '' THEN
            TextFilename := STRSUBSTNO('%1\%2.txt', EDIMessageType."Source/Target Folder", EDIMessageType."Fixed File Name")
        ELSE
            TextFilename := STRSUBSTNO('%1\%2-%3.txt', EDIMessageType."Source/Target Folder", "EDI Message Type", "Run No.");

        IF EDIMessageType."Save a File Copy" THEN BEGIN
            EDIMessageType.TestFolder(EDIMessageType."Copy Folder");
            CopyFileName := STRSUBSTNO('%1\%2-%3.txt', EDIMessageType."Copy Folder", "EDI Message Type", "Run No.");
        END;

        IF GUIALLOWED THEN
            Window.OPEN(Text001);

        CLEAR(EDIExportFile);
        EDIExportFile.TEXTMODE(TRUE);
        EDIExportFile.WRITEMODE(TRUE);
        EDIExportFile.CREATE(TextFilename);

        EDIMessageLineDetail.SETRANGE("EDI Message Type", "EDI Message Type");
        EDIMessageLineDetail.SETRANGE("Run No.", "Run No.");
        IF EDIMessageLineDetail.FINDSET THEN
            REPEAT
                IF EDIMessageLineDetail."Line No." = OldLineNo THEN
                    Buffer := Buffer + EDIMessageLineDetail.Content
                ELSE BEGIN
                    // First write the Buffer
                    IF Buffer <> '' THEN
                        EDIExportFile.WRITE(STRSUBSTNO('%1%2', Buffer, LineEnd));
                    Buffer := EDIMessageLineDetail.Content;
                END;
                OldLineNo := EDIMessageLineDetail."Line No.";
            UNTIL EDIMessageLineDetail.NEXT = 0;

        // Write the last Line!
        IF Buffer <> '' THEN
            EDIExportFile.WRITE(STRSUBSTNO('%1%2', Buffer, LineEnd));
        EDIExportFile.CLOSE;

        Filename := TextFilename;
        MODIFY;

        // Save a Copy on another location
        IF EDIMessageType."Save a File Copy" THEN BEGIN
            FileManagement.CopyServerFile(TextFilename, CopyFileName, TRUE);
            IF FILE.EXISTS(CopyFileName) THEN
                FILE.ERASE(CopyFileName);
            FILE.COPY(TextFilename, CopyFileName);

            Filename := CopyFileName;
            MODIFY;
        END;

        IF GUIALLOWED THEN
            Window.CLOSE;

        IF ShowMessage THEN
            MESSAGE(Text004, Filename);
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
        EXIT(LineEntryNo);
    end;
}

