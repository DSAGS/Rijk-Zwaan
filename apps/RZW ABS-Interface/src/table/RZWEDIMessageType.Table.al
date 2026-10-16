namespace dgs.rzw.abs;
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
                if "Source/Target Folder" = '' then begin
                    Blocked := true;
                    exit;
                end;
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
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = field("Object Type"));

            trigger OnLookup()
            var
                TempObject: Record AllObjWithCaption temporary;
            begin
                Clear(TempObject);
                EDIMessageTypeMgt.SetupObjectNoList(TempObject);
                TempObject.SetRange("Object Type", "Object Type");
                if Page.RunModal(Page::Objects, TempObject) = Action::LookupOK then begin
                    "Object ID" := TempObject."Object ID";
                    Validate("Object ID");
                end;
            end;

            trigger OnValidate()
            var
                TempObject: Record AllObjWithCaption temporary;
            begin
                EDIMessageTypeMgt.SetupObjectNoList(TempObject);
                TempObject."Object Type" := "Object Type";
                TempObject."Object ID" := "Object ID";
                if TempObject.IsEmpty then
                    FieldError("Object ID");
            end;
        }
        field(6; "Object Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = field("Object Type"),
                                                                           "Object ID" = field("Object ID")));
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
            CalcFormula = sum("RZW EDI Message Header"."Line Counter" where("EDI Message Type" = field(Code),
                                                                         Status = const(New),
                                                                         "Creation Date" = field("Date Filter"),
                                                                         Company = field("Company Filter")));
            Caption = 'Qty. of New Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Qty. of Rejected Messages"; Decimal)
        {
            CalcFormula = sum("RZW EDI Message Header"."Line Counter" where("EDI Message Type" = field(Code),
                                                                         Status = const(Rejected),
                                                                         "Creation Date" = field("Date Filter"),
                                                                         Company = field("Company Filter")));
            Caption = 'Qty. of Rejected Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Qty. of Processed Messages"; Decimal)
        {
            CalcFormula = sum("RZW EDI Message Header"."Line Counter" where("EDI Message Type" = field(Code),
                                                                         Status = const(Processed),
                                                                         "Creation Date" = field("Date Filter"),
                                                                         Company = field("Company Filter")));
            Caption = 'Qty. of Processed Messages';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Qty. of Messages"; Decimal)
        {
            CalcFormula = sum("RZW EDI Message Header"."Line Counter" where("EDI Message Type" = field(Code),
                                                                         Company = field("Company Filter")));
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
                if not Blocked then begin
                    TestField("Source/Target Folder");
                    TestFolder("Source/Target Folder");

                    if "Save a File Copy" then begin
                        TestField("Copy Folder");
                        TestFolder("Copy Folder");
                    end;
                end;
            end;
        }
        field(21; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Inbound,Outbound';
            OptionMembers = Inbound,Outbound;

            trigger OnValidate()
            begin
                case Direction of
                    Direction::Inbound:
                        begin
                            if (Direction <> xRec.Direction) or ("Sequence (Batch-proc. Only)" = 0) then
                                "Sequence (Batch-proc. Only)" := 1;
                        end;
                    Direction::Outbound:
                        begin
                            "Auto-Process" := false;
                            if (Direction <> xRec.Direction) or ("Sequence (Batch-proc. Only)" = 0) then
                                "Sequence (Batch-proc. Only)" := 2;
                        end;
                end;
            end;
        }
        field(22; "Save a File Copy"; Boolean)
        {
            Caption = 'Save a File Copy';

            trigger OnValidate()
            begin
                if "Save a File Copy" then
                    Validate("Copy Folder");
            end;
        }
        field(23; "Copy Folder"; Text[250])
        {
            Caption = 'Copy Folder';

            trigger OnValidate()
            begin
                if "Copy Folder" = '' then begin
                    if "Save a File Copy" then
                        Blocked := true;
                    exit;
                end;
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
        EDIMessageHeader.SetCurrentKey("EDI Message Type", Status);
        EDIMessageHeader.SetRange("EDI Message Type", Code);
        EDIMessageHeader.SetFilter(Status, '%1|%2', EDIMessageHeader.Status::New, EDIMessageHeader.Status::Rejected);
        if not EDIMessageHeader.IsEmpty then
            Error(Text003, TableCaption, Code);
    end;

    trigger OnInsert()
    begin
        Validate(Direction);
    end;

    var
        Text001: Label 'Directory %1 does not exist.';
        Text002: Label 'No EDI messages of type %1 were made.';
        Text003: Label 'There are non-processed EDI Messages for %1 %2. You cannot delete it.';
        Text004: Label '%1 Inbound EDI Messages of type %2 were made.';
        Text005: Label '%1 Outbound EDI Messages of type %2 were made.';
        EDIMessageTypeMgt: Codeunit "RZW EDI Message Type Mgt."; //TODO: create codeunit for managing EDI Message Types

    internal procedure TestFolder(var UseFolderName: Text[250])
    var
    // FileMgt: Codeunit "File Management"; // TODO: build to check if the specified file location exists
    begin
        // UseFolderName := DELCHR(UseFolderName, '>', '\');
        // IF NOT FileMgt.ClientDirectoryExists(UseFolderName) THEN
        //     ERROR(Text001, UseFolderName);
    end;

    internal procedure OpenExplorer(FilePath: Text[1024])
    var
        ExplorerPath: Text[1024];
    begin
        Hyperlink(FilePath);
    end;

    internal procedure StartEDIObject()
    var
        QtyBefore: Integer;
        QtyAfter: Integer;
    begin
        CalcFields("Qty. of Messages");
        QtyBefore := "Qty. of Messages";

        Clear(EDIMessageTypeMgt);
        EDIMessageTypeMgt.Run(Rec);

        CalcFields("Qty. of Messages");
        QtyAfter := "Qty. of Messages";

        case Direction of
            Direction::Inbound:
                Message(Text004, (QtyAfter - QtyBefore), Code);
            Direction::Outbound:
                Message(Text005, (QtyAfter - QtyBefore), Code);
        end;
    end;

    internal procedure GetStyle(): Text
    begin
        if Blocked or "Test Modus" then
            exit('UnFavorable');
        exit('Favorable');
    end;
}

