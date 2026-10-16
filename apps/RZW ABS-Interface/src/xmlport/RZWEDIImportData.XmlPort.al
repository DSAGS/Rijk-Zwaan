namespace dgs.rzw.abs;
xmlport 50100 "RZW EDI Import Data"
{
    Caption = 'EDI-Import Data';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '<None>';
    Format = VariableText;
    TextEncoding = WINDOWS;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement("RZW EDI Message Line Detail"; "RZW EDI Message Line Detail")
            {
                AutoSave = false;
                XmlName = 'Integer';
                SourceTableView = sorting("EDI Message Type", "Run No.", "Line No.", "Field No.");
                textelement(linecontent)
                {
                    XmlName = 'EDIMessageContent';
                }

                trigger OnBeforeInsertRecord()
                var
                    FieldValue: Text;
                    IdentifierDescr: Text;
                    EDIMessageLineExists: Boolean;
                begin
                    NextLineNo := NextLineNo + 1;
                    NextFieldNo := 0;
                    Identifier := false;
                    EndOfLine := false;
                    EDIMessageLineExists := false;

                    while not EndOfLine do begin
                        GetFieldContents(linecontent, FieldValue);

                        case NextFieldNo of
                            1:
                                begin
                                    ABSRecordType.Get(FieldValue);
                                    Identifier := ABSRecordType."File Type" <> ABSRecordType."File Type"::" ";
                                    if Identifier then begin
                                        if not FileTypeHasBeenSet then begin
                                            FileType := ABSRecordType."File Type";
                                            FileTypeHasBeenSet := true;
                                        end;
                                        if FileType <> ABSRecordType."File Type" then
                                            Error(Text003, currXMLport.Filename, FileType, ABSRecordType."File Type");
                                    end;
                                end;
                            2:
                                if FileTypeHasBeenSet and not CompanyHasBeenSet then begin
                                    ABSCompanyCode := FieldValue;
                                    CompanyHasBeenSet := true;
                                end else
                                    if Identifier then
                                        if ABSCompanyCode <> FieldValue then
                                            Error(Text002, currXMLport.Filename, ABSCompanyCode, FieldValue);
                        end;

                        if Identifier then
                            if ABSRecordTypeSetup.Get(ABSRecordType.Code, NextFieldNo) then
                                if ABSRecordTypeSetup."Descriptive Field" then begin
                                    if not EDIMessageLine.Get(EDIMessageHeader."EDI Message Type", EDIMessageHeader."Run No.", NextLineNo) then begin
                                        EDIMessageLine.Init();
                                        EDIMessageLine."EDI Message Type" := EDIMessageHeader."EDI Message Type";
                                        EDIMessageLine."Run No." := EDIMessageHeader."Run No.";
                                        EDIMessageLine."Line No." := NextLineNo;
                                        EDIMessageLine.Insert();
                                    end;
                                    IdentifierDescr := StrSubstNo('%1: %2; ', ABSRecordTypeSetup."Field Name", AnsiToAsciiImport(FieldValue));
                                    if StrLen(EDIMessageLine.Description) + StrLen(IdentifierDescr) < MaxStrLen(EDIMessageLine.Description) then
                                        EDIMessageLine.Description := EDIMessageLine.Description + IdentifierDescr;
                                    EDIMessageLine.Modify();

                                    EDIMessageLineExists := true;
                                end;

                        EDIMessageLineDetail.Init();
                        EDIMessageLineDetail."EDI Message Type" := EDIMessageHeader."EDI Message Type";
                        EDIMessageLineDetail."Run No." := EDIMessageHeader."Run No.";
                        EDIMessageLineDetail."Line No." := NextLineNo;
                        EDIMessageLineDetail."Record Type" := ABSRecordType.Code;
                        EDIMessageLineDetail."Field No." := NextFieldNo;
                        EDIMessageLineDetail.Content := AnsiToAsciiImport(FieldValue);
                        EDIMessageLineDetail.Insert();
                    end;

                    if EDIMessageLineExists then begin
                        EDIMessageLine.Description := DelChr(EDIMessageLine.Description, '>', '; ');
                        EDIMessageLine.Modify();
                    end;
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPreXmlPort()
    begin
        FileType := FileType::" ";
        FileTypeHasBeenSet := false;

        // ANSI-ASCII conversion init...
        MakeVariables();
    end;

    var
        EDIMessageHeader: Record "RZW EDI Message Header";
        EDIMessageLine: Record "RZW EDI Message Line";
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
        ABSRecordType: Record "RZW ABS Record Type";
        ABSRecordTypeSetup: Record "RZW ABS Record Type Setup";
        EDIMessageType: Code[20];
        EDIMessageNo: Code[20];
        NextLineNo: Integer;
        NextFieldNo: Integer;
        FileType: Option " ","Sales Invoice","Purchase Invoice",Customer,Vendor;
        FileTypeHasBeenSet: Boolean;
        CompanyHasBeenSet: Boolean;
        ABSCompanyCode: Code[3];
        Text001: Label '%1 cannot be interpreted as a valid Field Value.';
        EndOfLine: Boolean;
        Text002: Label 'File %1 contains records for multiple companies (%2 and %3). This is not allowed.';
        Identifier: Boolean;
        Text003: Label 'File %1 contains records with multiple data types (%2 and %3). This is not allowed.';
        Text004: Label 'File %1 contains not data with which the file type could be determined. This is not allowed.';
        "// ASCII-ANSI Conv. Variables": Integer;
        AsciiStr: Text[250];
        AnsiStr: Text[250];
        CharVar: array[32] of Char;

    internal procedure GetFieldContents(var UseContent: Text; var IsValue: Text)
    var
        Position: Integer;
        Result: Text;
    begin
        Position := StrPos(UseContent, ';');
        if Position > 1 then begin
            Result := CopyStr(UseContent, 1, Position - 1);
            UseContent := CopyStr(UseContent, Position + 1);
        end else begin
            Result := UseContent;
            EndOfLine := true;
        end;

        // Some applications sometimes export some characters at the beginning of a file
        // This function deletes them
        if (NextLineNo = 1) and (CopyStr(Result, 1, 1) <> '"') then
            while CopyStr(Result, 1, 1) <> '"' do
                Result := CopyStr(Result, 2);
        if not ((CopyStr(Result, 1, 1) = '"') or (CopyStr(Result, StrLen(Result), 1) = '"')) then
            Error(Text001, Result);

        IsValue := DelChr(Result, '<>', '"');
        NextFieldNo := NextFieldNo + 1;
    end;

    internal procedure GetFileType(var NewFileType: Option " ","Sales Invoice","Purchase Invoice",Customer,Vendor; var NewTargetCompany: Text[30])
    var
        ABSInterfaceCompanySetup: Record "RZW ABS Interface Comp. Setup";
    begin
        if not FileTypeHasBeenSet then
            Error(Text004, currXMLport.Filename);
        ABSInterfaceCompanySetup.Get(ABSCompanyCode);

        NewFileType := FileType;
        NewTargetCompany := ABSInterfaceCompanySetup.Company;
    end;

    internal procedure InitializeXMLport(EDIMessageHeader2: Record "RZW EDI Message Header")
    begin
        EDIMessageHeader.Get(EDIMessageHeader2."EDI Message Type", EDIMessageHeader2."Run No.");
    end;

    internal procedure AnsiToAsciiImport(InputTxt: Text[1024]): Text[1024]
    begin
        MakeVariables();
        // Convert non-breaking spaces (ASCII code 'A0' HEX) into normal spaces (ASCII Code '20' HEX) first.
        InputTxt := ConvertStr(InputTxt, ' ', ' ');
        // RZWHU - This conversion is not needed when property TextEncoding = WINDOWS
        // EXIT(CONVERTSTR(InputTxt,AnsiStr,AsciiStr));
        // RZWHU {*}
        exit(InputTxt);
    end;

    internal procedure AsciiToAnsiExport(InputTxt: Text[1024]): Text[1024]
    begin
        MakeVariables();
        exit(ConvertStr(InputTxt, AsciiStr, AnsiStr));
    end;

    internal procedure MakeVariables()
    begin
        AsciiStr := 'ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜø£Ø×ƒáíóúñÑªº¿®¬½¼¡«»¦¦¦¦¦ÁÂÀ©¦¦++¢¥++--+-+ãÃ++--¦-+';
        AsciiStr := AsciiStr + '¤ðÐÊËÈiÍÎÏ++¦_¦Ì¯ÓßÔÒõÕµþÞÚÛÙýÝ¯´­±=¾¶§÷¸°¨·¹³²¦';
        CharVar[1] := 196;
        CharVar[2] := 197;
        CharVar[3] := 201;
        CharVar[4] := 242;
        CharVar[5] := 220;
        CharVar[6] := 186;
        CharVar[7] := 191;
        CharVar[8] := 188;
        CharVar[9] := 187;
        CharVar[10] := 193;
        CharVar[11] := 194;
        CharVar[12] := 192;
        CharVar[13] := 195;
        CharVar[14] := 202;
        CharVar[15] := 203;
        CharVar[16] := 200;
        CharVar[17] := 205;
        CharVar[18] := 206;
        CharVar[19] := 204;
        CharVar[20] := 175;
        CharVar[21] := 223;
        CharVar[22] := 213;
        CharVar[23] := 254;
        CharVar[24] := 218;
        CharVar[25] := 219;
        CharVar[26] := 217;
        CharVar[27] := 180;
        CharVar[28] := 177;
        CharVar[29] := 176;
        CharVar[30] := 185;
        CharVar[31] := 179;
        CharVar[32] := 178;
        AnsiStr := 'Ã³ÚÔõÓÕþÛÙÞ´¯ý' + Format(CharVar[1]) + Format(CharVar[2]) + Format(CharVar[3]) + 'µã¶÷' + Format(CharVar[4]);
        AnsiStr := AnsiStr + '¹¨ Í' + Format(CharVar[5]) + '°úÏÎâßÝ¾·±Ð¬' + Format(CharVar[6]) + Format(CharVar[7]);
        AnsiStr := AnsiStr + '«¼¢' + Format(CharVar[8]) + 'í½' + Format(CharVar[9]) + '___ªª' + Format(CharVar[10]) + Format(CharVar[11]);
        AnsiStr := AnsiStr + Format(CharVar[12]) + '®ªª++óÑ++--+-+Ò' + Format(CharVar[13]) + '++--ª-+ñ­ð';
        AnsiStr := AnsiStr + Format(CharVar[14]) + Format(CharVar[15]) + Format(CharVar[16]) + 'i' + Format(CharVar[17]) + Format(CharVar[18]);
        AnsiStr := AnsiStr + '¤++__ª' + Format(CharVar[19]) + Format(CharVar[20]) + 'Ë' + Format(CharVar[21]) + 'ÈÊ§';
        AnsiStr := AnsiStr + Format(CharVar[22]) + 'Á' + Format(CharVar[23]) + 'Ì' + Format(CharVar[24]) + Format(CharVar[25]);
        AnsiStr := AnsiStr + Format(CharVar[26]) + '²¦»' + Format(CharVar[27]) + '¡' + Format(CharVar[28]) + '=¥Âº¸©' + Format(CharVar[29]);
        AnsiStr := AnsiStr + '¿À' + Format(CharVar[30]) + Format(CharVar[31]) + Format(CharVar[32]) + '_';
    end;
}

