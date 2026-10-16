namespace dgs.rzw.abs;
codeunit 50112 "RZW Inb. EDI Msg-Process Y/N"
{
    TableNo = "RZW EDI Message Header";

    trigger OnRun()
    begin
        EDIMessageHeader := Rec;
        Code();
        Rec := EDIMessageHeader;
    end;

    var
        EDIMessageHeader: Record "RZW EDI Message Header";
        InbEDIMessageProcess: Codeunit "RZW Inb. EDI Msg.-Process";

    internal procedure "Code"()
    var
        EDIMessageHeader2: Record "RZW EDI Message Header";
        MySessionID: Integer;
        MaxWaitingTime: Integer;
        i: Integer;
        Continue: Boolean;
        CurrentEntryNo: Integer;
        CurrentFieldNo: Integer;
        ProcessConfirmationQst: Label 'Do you want to process %1 %2 for %3 %4?', Comment = '%1=FieldCaption , %2=Run No., %3=FieldCaption, %4="EDI Message Type"';
        RejectedEdiMessageProcessingErr: Label 'Rejected EDI Messages can only be processed in the target company.';
        ProcessingLineFieldErr: Label 'An error occured processing Line No. %1, Field No. %2 :\\ %3', Comment = '%1=Line No., %2=Field No., %3=Error Text';
        StatusUpdateMsg: Label 'Processing completed. The status of EDI Message %1, %2 is now %3.', Comment = '%1=EDI Message Type, %2=Run No., %3=Status';
    begin
        if not Confirm(ProcessConfirmationQst, false, EDIMessageHeader.FieldCaption("Run No."), EDIMessageHeader."Run No.", EDIMessageHeader.FieldCaption("EDI Message Type"), EDIMessageHeader."EDI Message Type") then
            exit;

        EDIMessageHeader2 := EDIMessageHeader;
        if (EDIMessageHeader.Status = EDIMessageHeader.Status::Rejected) or (EDIMessageHeader.Company = CompanyName) then begin
            if EDIMessageHeader.Company <> CompanyName then
                Error(RejectedEdiMessageProcessingErr);
            Clear(InbEDIMessageProcess);
            if not InbEDIMessageProcess.Run(EDIMessageHeader2) then begin
                InbEDIMessageProcess.GetLastError(CurrentEntryNo, CurrentFieldNo);
                Error(ProcessingLineFieldErr, CurrentEntryNo, CurrentFieldNo, GetLastErrorText);
            end;
        end else begin
            MySessionID := 0;
            StartSession(MySessionID, Codeunit::"RZW Inb. EDI Msg.-Process", EDIMessageHeader.Company, EDIMessageHeader2);

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
        EDIMessageHeader := EDIMessageHeader2;

        Message(StatusUpdateMsg, EDIMessageHeader."EDI Message Type", EDIMessageHeader."Run No.", EDIMessageHeader.Status);
    end;
}
