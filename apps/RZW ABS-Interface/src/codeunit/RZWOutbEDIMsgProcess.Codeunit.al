codeunit 50101 "RZW Outb. EDI Msg. Process"
{
    TableNo = "RZW EDI Message Header";

    trigger OnRun()
    var
        EDIMessageHeader2: Record "RZW EDI Message Header";
    begin
        CLEARALL;
        EDIMessageHeader := Rec;

        WITH EDIMessageHeader DO BEGIN
            Status := Status::Rejected;
            MODIFY;
            COMMIT;

            // To prevent processing in a wrong company
            TESTFIELD(Company, COMPANYNAME);

            EDIMessageType.GET("EDI Message Type");
            EDIMessageType.TESTFIELD(Direction, EDIMessageType.Direction::Outbound);

            // To prevent processing in a wrong sorting order
            IF EDIMessageType."Run No. Order" THEN BEGIN
                EDIMessageHeader2.SETCURRENTKEY(Company, "EDI Message Type", "Run No.", Status);
                EDIMessageHeader2.SETRANGE(Company, Company);
                EDIMessageHeader2.SETRANGE("EDI Message Type", "EDI Message Type");
                EDIMessageHeader2.SETFILTER("Run No.", '<%1', "Run No.");
                EDIMessageHeader2.SETFILTER(Status, '%1|%2', EDIMessageHeader2.Status::New, EDIMessageHeader2.Status::Rejected);
                IF EDIMessageHeader2.FINDFIRST THEN
                    ERROR(Text000, "Run No.");
            END;

            EDIMessageLineDetail.SETRANGE("EDI Message Type", "EDI Message Type");
            EDIMessageLineDetail.SETRANGE("Run No.", "Run No.");
            IF NOT EDIMessageLineDetail.FINDSET THEN
                ERROR(Text001);

            Window.OPEN(
              '#1#################################');

            Window.UPDATE(1, STRSUBSTNO('%1 %2', TABLECAPTION, "Run No."));

            CreateTextFile(FALSE);

            Status := Status::Processed;
            MODIFY;
        END;
        Rec := EDIMessageHeader;
    end;

    var
        EDIMessageHeader: Record "RZW EDI Message Header";
        EDIMessageType: Record "RZW EDI Message Type";
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
        Window: Dialog;
        LineCounter: Integer;
        NextLineNo: Integer;
        Text000: Label 'You cannot process EDI Message with Run No. %1, since earlier generated EDI Messages exist for the same company.';
        Text001: Label 'There is nothing to process.';
        Text002: Label 'Processing lines              #2######';
}

