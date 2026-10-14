codeunit 50113 "RZW Outb. EDI Msg. Process"
{
    TableNo = "RZW EDI Message Header";

    trigger OnRun()
    var
        EDIMessageHeader2: Record "RZW EDI Message Header";
    begin
        ClearAll();
        EDIMessageHeader := Rec;

        EDIMessageHeader.Status := EDIMessageHeader.Status::Rejected;
        EDIMessageHeader.Modify();
        Commit();
        // To prevent processing in a wrong company
        EDIMessageHeader.TestField(Company, CompanyName);

        EDIMessageType.Get(EDIMessageHeader."EDI Message Type");
        EDIMessageType.TestField(Direction, EDIMessageType.Direction::Outbound);
        // To prevent processing in a wrong sorting order
        if EDIMessageType."Run No. Order" then begin
            EDIMessageHeader2.SetCurrentKey(Company, "EDI Message Type", "Run No.", Status);
            EDIMessageHeader2.SetRange(Company, EDIMessageHeader.Company);
            EDIMessageHeader2.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
            EDIMessageHeader2.SetFilter("Run No.", '<%1', EDIMessageHeader."Run No.");
            EDIMessageHeader2.SetFilter(Status, '%1|%2', EDIMessageHeader2.Status::New, EDIMessageHeader2.Status::Rejected);
            if not EDIMessageHeader2.IsEmpty() then
                Error(Text000, EDIMessageHeader."Run No.");
        end;

        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        if not EDIMessageLineDetail.FindSet() then
            Error(Text001);

        Window.Open(
          '#1#################################');

        Window.Update(1, StrSubstNo('%1 %2', EDIMessageHeader.TableCaption, EDIMessageHeader."Run No."));

        EDIMessageHeader.CreateTextFile(false);

        EDIMessageHeader.Status := EDIMessageHeader.Status::Processed;
        EDIMessageHeader.Modify();
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

