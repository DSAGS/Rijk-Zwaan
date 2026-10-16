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
                SourceTableView = SORTING("EDI Message Type", "Run No.", "Line No.", "Field No.");
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
                    Identifier := FALSE;
                    EndOfLine := FALSE;
                    EDIMessageLineExists := FALSE;

                    WHILE NOT EndOfLine DO BEGIN
                        GetFieldContents(LineContent, FieldValue);

                        CASE NextFieldNo OF
                            1:
                                BEGIN
                                    ABSRecordType.GET(FieldValue);
                                    Identifier := ABSRecordType."File Type" <> ABSRecordType."File Type"::" ";
                                    IF Identifier THEN BEGIN
                                        IF NOT FileTypeHasBeenSet THEN BEGIN
                                            FileType := ABSRecordType."File Type";
                                            FileTypeHasBeenSet := TRUE;
                                        END;
                                        IF FileType <> ABSRecordType."File Type" THEN
                                            ERROR(Text003, currXMLport.FILENAME, FileType, ABSRecordType."File Type");
                                    END;
                                END;
                            2:
                                IF FileTypeHasBeenSet AND NOT CompanyHasBeenSet THEN BEGIN
                                    ABSCompanyCode := FieldValue;
                                    CompanyHasBeenSet := TRUE;
                                END ELSE
                                    IF Identifier THEN
                                        IF ABSCompanyCode <> FieldValue THEN
                                            ERROR(Text002, currXMLport.FILENAME, ABSCompanyCode, FieldValue);
                        END;

                        IF Identifier THEN
                            IF ABSRecordTypeSetup.GET(ABSRecordType.Code, NextFieldNo) THEN
                                IF ABSRecordTypeSetup."Descriptive Field" THEN BEGIN
                                    IF NOT EDIMessageLine.GET(EDIMessageHeader."EDI Message Type", EDIMessageHeader."Run No.", NextLineNo) THEN BEGIN
                                        EDIMessageLine.INIT;
                                        EDIMessageLine."EDI Message Type" := EDIMessageHeader."EDI Message Type";
                                        EDIMessageLine."Run No." := EDIMessageHeader."Run No.";
                                        EDIMessageLine."Line No." := NextLineNo;
                                        EDIMessageLine.INSERT;
                                    END;
                                    IdentifierDescr := STRSUBSTNO('%1: %2; ', ABSRecordTypeSetup."Field Name", AnsiToAsciiImport(FieldValue));
                                    IF STRLEN(EDIMessageLine.Description) + STRLEN(IdentifierDescr) < MAXSTRLEN(EDIMessageLine.Description) THEN
                                        EDIMessageLine.Description := EDIMessageLine.Description + IdentifierDescr;
                                    EDIMessageLine.MODIFY;

                                    EDIMessageLineExists := TRUE;
                                END;

                        EDIMessageLineDetail.INIT;
                        EDIMessageLineDetail."EDI Message Type" := EDIMessageHeader."EDI Message Type";
                        EDIMessageLineDetail."Run No." := EDIMessageHeader."Run No.";
                        EDIMessageLineDetail."Line No." := NextLineNo;
                        EDIMessageLineDetail."Record Type" := ABSRecordType.Code;
                        EDIMessageLineDetail."Field No." := NextFieldNo;
                        EDIMessageLineDetail.Content := AnsiToAsciiImport(FieldValue);
                        EDIMessageLineDetail.INSERT;
                    END;

                    IF EDIMessageLineExists THEN BEGIN
                        EDIMessageLine.Description := DELCHR(EDIMessageLine.Description, '>', '; ');
                        EDIMessageLine.MODIFY;
                    END;
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
        FileTypeHasBeenSet := FALSE;

        // ANSI-ASCII conversion init...
        MakeVariables;
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
        Position := STRPOS(UseContent, ';');
        IF Position > 1 THEN BEGIN
            Result := COPYSTR(UseContent, 1, Position - 1);
            UseContent := COPYSTR(UseContent, Position + 1);
        END ELSE BEGIN
            Result := UseContent;
            EndOfLine := TRUE;
        END;

        // Some applications sometimes export some characters at the beginning of a file
        // This function deletes them
        IF (NextLineNo = 1) AND (COPYSTR(Result, 1, 1) <> '"') THEN
            WHILE COPYSTR(Result, 1, 1) <> '"' DO
                Result := COPYSTR(Result, 2);
        IF NOT ((COPYSTR(Result, 1, 1) = '"') OR (COPYSTR(Result, STRLEN(Result), 1) = '"')) THEN
            ERROR(Text001, Result);

        IsValue := DELCHR(Result, '<>', '"');
        NextFieldNo := NextFieldNo + 1;
    end;

    internal procedure GetFileType(var NewFileType: Option " ","Sales Invoice","Purchase Invoice",Customer,Vendor; var NewTargetCompany: Text[30])
    var
        ABSInterfaceCompanySetup: Record "RZW ABS Interface Comp. Setup";
    begin
        IF NOT FileTypeHasBeenSet THEN
            ERROR(Text004, currXMLport.FILENAME);
        ABSInterfaceCompanySetup.GET(ABSCompanyCode);

        NewFileType := FileType;
        NewTargetCompany := ABSInterfaceCompanySetup.Company;
    end;

    internal procedure InitializeXMLport(EDIMessageHeader2: Record "RZW EDI Message Header")
    begin
        EDIMessageHeader.GET(EDIMessageHeader2."EDI Message Type", EDIMessageHeader2."Run No.");
    end;

    internal procedure AnsiToAsciiImport(InputTxt: Text[1024]): Text[1024]
    begin
        MakeVariables;
        // Convert non-breaking spaces (ASCII code 'A0' HEX) into normal spaces (ASCII Code '20' HEX) first.
        InputTxt := CONVERTSTR(InputTxt, ' ', ' ');
        // RZWHU - This conversion is not needed when property TextEncoding = WINDOWS
        // EXIT(CONVERTSTR(InputTxt,AnsiStr,AsciiStr));
        // RZWHU {*}
        EXIT(InputTxt);
    end;

    Internal procedure AsciiToAnsiExport(InputTxt: Text[1024]): Text[1024]
    begin
        MakeVariables;
        EXIT(CONVERTSTR(InputTxt, AsciiStr, AnsiStr));
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
        AnsiStr := 'Ã³ÚÔõÓÕþÛÙÞ´¯ý' + FORMAT(CharVar[1]) + FORMAT(CharVar[2]) + FORMAT(CharVar[3]) + 'µã¶÷' + FORMAT(CharVar[4]);
        AnsiStr := AnsiStr + '¹¨ Í' + FORMAT(CharVar[5]) + '°úÏÎâßÝ¾·±Ð¬' + FORMAT(CharVar[6]) + FORMAT(CharVar[7]);
        AnsiStr := AnsiStr + '«¼¢' + FORMAT(CharVar[8]) + 'í½' + FORMAT(CharVar[9]) + '___ªª' + FORMAT(CharVar[10]) + FORMAT(CharVar[11]);
        AnsiStr := AnsiStr + FORMAT(CharVar[12]) + '®ªª++óÑ++--+-+Ò' + FORMAT(CharVar[13]) + '++--ª-+ñ­ð';
        AnsiStr := AnsiStr + FORMAT(CharVar[14]) + FORMAT(CharVar[15]) + FORMAT(CharVar[16]) + 'i' + FORMAT(CharVar[17]) + FORMAT(CharVar[18]);
        AnsiStr := AnsiStr + '¤++__ª' + FORMAT(CharVar[19]) + FORMAT(CharVar[20]) + 'Ë' + FORMAT(CharVar[21]) + 'ÈÊ§';
        AnsiStr := AnsiStr + FORMAT(CharVar[22]) + 'Á' + FORMAT(CharVar[23]) + 'Ì' + FORMAT(CharVar[24]) + FORMAT(CharVar[25]);
        AnsiStr := AnsiStr + FORMAT(CharVar[26]) + '²¦»' + FORMAT(CharVar[27]) + '¡' + FORMAT(CharVar[28]) + '=¥Âº¸©' + FORMAT(CharVar[29]);
        AnsiStr := AnsiStr + '¿À' + FORMAT(CharVar[30]) + FORMAT(CharVar[31]) + FORMAT(CharVar[32]) + '_';
    end;
}

