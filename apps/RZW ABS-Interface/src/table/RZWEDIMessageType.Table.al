namespace RZW;
using Microsoft.Foundation.NoSeries;
using System.Environment;
using System.Reflection;
table 50107 "RZW EDI Message Type"
{
    Caption = 'EDI Message Type';
    // LookupPageID = 90002;
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';

            trigger OnValidate()
            var
                NoSeriesSetup: Record "No. Series";
            begin
            end;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Source/Target Folder"; Text[250])
        {
            Caption = 'Source/Target Folder';

            trigger OnValidate()
            begin
                IF "Source/Target Folder" = '' THEN BEGIN
                    Blocked := TRUE;
                    EXIT;
                END;
                TestFolder("Source/Target Folder");
            end;
        }
        field(4; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = ' ,,,Report,,Codeunit,XMLPort';
            OptionMembers = " ",,,"Report",Dataport,"Codeunit","XMLPort";

            trigger OnValidate()
            begin
                "Object ID" := 0;
            end;
        }
        field(5; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = FIELD("Object Type"));

            trigger OnLookup()
            var
                TempObject: Record AllObjWithCaption temporary;
            begin
                CLEAR(TempObject);
                EDIMessageTypeMgt.SetupObjectNoList(TempObject);
                TempObject.SETRANGE(Type, "Object Type");
                IF PAGE.RUNMODAL(358, TempObject) = ACTION::LookupOK THEN BEGIN
                    "Object ID" := TempObject."Object ID";
                    VALIDATE("Object ID");
                END;
            end;

            trigger OnValidate()
            var
                TempObject: Record AllObjWithCaption temporary;
            begin
                EDIMessageTypeMgt.SetupObjectNoList(TempObject);
                TempObject.Type := "Object Type";
                TempObject.ID := "Object ID";
                IF NOT TempObject.FIND THEN
                    FIELDERROR("Object ID");
            end;
        }
        field(6; "Object Name"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = FIELD("Object Type"),
                                                                           "Object ID" = FIELD("Object ID")));
            Caption = 'Object Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Request Window"; Boolean)
        {
            Caption = 'Request Window';
        }
        field(8; "Message No. Series"; Code[10])
        {
            Caption = 'Message No. Series';
            TableRelation = "No. Series";
        }
        field(9; "Test Modus"; Boolean)
        {
            Caption = 'Test Modus';
            Description = 'EDIFACT Only';
        }
        field(12; "Qty. of Non-processed Files"; Integer)
        {
            BlankZero = true;
            Caption = 'Qty. of Non-processed Files';
            Editable = false;
            // TODO: Implement a retreival fucntion for the number of non-processed files.
        }
        field(15; "Company Filter"; Text[30])
        {
            FieldClass = FlowFilter;
            TableRelation = Company;
            ValidateTableRelation = false;
        }
        field(16; "Qty. of New Messages"; Decimal)
        {
            CalcFormula = Sum("RZW EDI Message Header"."Line Counter" WHERE("EDI Message Type" = FIELD(Code),
                                                                         Status = CONST(New),
                                                                         "Creation Date" = FIELD("Date Filter"),
                                                                         Company = FIELD("Company Filter")));
            Caption = 'Qty. of New Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Qty. of Rejected Messages"; Decimal)
        {
            CalcFormula = Sum("RZW EDI Message Header"."Line Counter" WHERE("EDI Message Type" = FIELD(Code),
                                                                         Status = CONST(Rejected),
                                                                         "Creation Date" = FIELD("Date Filter"),
                                                                         Company = FIELD("Company Filter")));
            Caption = 'Qty. of Rejected Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Qty. of Processed Messages"; Decimal)
        {
            CalcFormula = Sum("RZW EDI Message Header"."Line Counter" WHERE("EDI Message Type" = FIELD(Code),
                                                                         Status = CONST(Processed),
                                                                         "Creation Date" = FIELD("Date Filter"),
                                                                         Company = FIELD("Company Filter")));
            Caption = 'Qty. of Processed Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Qty. of Messages"; Decimal)
        {
            CalcFormula = Sum("RZW EDI Message Header"."Line Counter" WHERE("EDI Message Type" = FIELD(Code),
                                                                         Company = FIELD("Company Filter")));
            Caption = 'Qty. of Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Blocked; Boolean)
        {
            Caption = 'Blocked';
            InitValue = true;

            trigger OnValidate()
            begin
                IF NOT Blocked THEN BEGIN
                    TESTFIELD("Source/Target Folder");
                    TestFolder("Source/Target Folder");

                    IF "Save a File Copy" THEN BEGIN
                        TESTFIELD("Copy Folder");
                        TestFolder("Copy Folder");
                    END;
                END;
            end;
        }
        field(21; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Inbound,Outbound';
            OptionMembers = Inbound,Outbound;

            trigger OnValidate()
            begin
                CASE Direction OF
                    Direction::Inbound:
                        BEGIN
                            IF (Direction <> xRec.Direction) OR ("Sequence (Batch-proc. Only)" = 0) THEN
                                "Sequence (Batch-proc. Only)" := 1;
                        END;
                    Direction::Outbound:
                        BEGIN
                            "Auto-Process" := FALSE;
                            IF (Direction <> xRec.Direction) OR ("Sequence (Batch-proc. Only)" = 0) THEN
                                "Sequence (Batch-proc. Only)" := 2;
                        END;
                END;
            end;
        }
        field(22; "Save a File Copy"; Boolean)
        {
            Caption = 'Save a File Copy';

            trigger OnValidate()
            begin
                IF "Save a File Copy" THEN
                    VALIDATE("Copy Folder");
            end;
        }
        field(23; "Copy Folder"; Text[250])
        {
            Caption = 'Copy Folder';

            trigger OnValidate()
            begin
                IF "Copy Folder" = '' THEN BEGIN
                    IF "Save a File Copy" THEN
                        Blocked := TRUE;
                    EXIT;
                END;
                TestFolder("Copy Folder");
            end;
        }
        field(24; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(31; "Auto-Process"; Boolean)
        {
            Caption = 'Auto-Process';
        }
        field(32; "Run No. Order"; Boolean)
        {
            Caption = 'Run No. Order';
        }
        field(40; "Sequence (Batch-proc. Only)"; Integer)
        {
            Caption = 'Sequence (Batch-processing Only)';
        }
        field(42; "Fixed File Name"; Text[80])
        {
            Caption = 'Fixed File Name';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, Direction)
        {
        }
    }

    trigger OnDelete()
    var
        EDIMessageHeader: Record "RZW EDI Message Header";
    begin
        EDIMessageHeader.SETCURRENTKEY("EDI Message Type", Status);
        EDIMessageHeader.SETRANGE("EDI Message Type", Code);
        EDIMessageHeader.SETFILTER(Status, '%1|%2', EDIMessageHeader.Status::New, EDIMessageHeader.Status::Rejected);
        IF NOT EDIMessageHeader.ISEMPTY THEN
            ERROR(Text003, TABLECAPTION, Code);
    end;

    trigger OnInsert()
    begin
        VALIDATE(Direction);
    end;

    var
        Text001: Label 'Directory %1 does not exist.';
        Text002: Label 'No EDI messages of type %1 were made.';
        Text003: Label 'There are non-processed EDI Messages for %1 %2. You cannot delete it.';
        Text004: Label '%1 Inbound EDI Messages of type %2 were made.';
        Text005: Label '%1 Outbound EDI Messages of type %2 were made.';
    // EDIMessageTypeMgt: Codeunit "90010"; //TODO: create codeunit for managing EDI Message Types

    procedure TestFolder(var UseFolderName: Text[1024])
    var
    // FileMgt: Codeunit "File Management"; // TODO: build to check if the specified file location exists
    begin
        // UseFolderName := DELCHR(UseFolderName, '>', '\');
        // IF NOT FileMgt.ClientDirectoryExists(UseFolderName) THEN
        //     ERROR(Text001, UseFolderName);
    end;

    procedure OpenExplorer(FilePath: Text[1024])
    var
        ExplorerPath: Text[1024];
    begin
        HYPERLINK(FilePath);
    end;

    procedure StartEDIObject()
    var
        QtyBefore: Integer;
        QtyAfter: Integer;
    begin
        CALCFIELDS("Qty. of Messages");
        QtyBefore := "Qty. of Messages";

        CLEAR(EDIMessageTypeMgt);
        EDIMessageTypeMgt.RUN(Rec);

        CALCFIELDS("Qty. of Messages");
        QtyAfter := "Qty. of Messages";

        CASE Direction OF
            Direction::Inbound:
                MESSAGE(Text004, (QtyAfter - QtyBefore), Code);
            Direction::Outbound:
                MESSAGE(Text005, (QtyAfter - QtyBefore), Code);
        END;
    end;

    procedure GetStyle(): Text
    begin
        IF Blocked OR "Test Modus" THEN
            EXIT('UnFavorable');
        EXIT('Favorable');
    end;
}

