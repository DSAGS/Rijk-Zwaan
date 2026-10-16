namespace dgs.rzw.abs;
codeunit 50115 "RZW ProcessAllEDIMessageTypes"
{

    trigger OnRun()
    var
        EDIMessageType: Record "RZW EDI Message Type";
    begin
        if not Confirm(Text010 + Text011) then
            Error('');

        ClearAll();
        EDIMessageType.SetCurrentKey("Sequence (Batch-proc. Only)");
        EDIMessageType.SetRange("Test Modus", false);
        EDIMessageType.SetRange(Blocked, false);
        if not EDIMessageType.FindSet() then
            Error(Text012);

        Window.Open(Text001);

        TotalCounter := EDIMessageType.Count;
        UpdateCounter := TotalCounter div 50;
        if UpdateCounter = 0 then
            UpdateCounter := 1;
        LineCounter := 0;

        repeat
            LineCounter := LineCounter + 1;
            if LineCounter mod UpdateCounter = 0 then
                Window.Update(2, Round(LineCounter / TotalCounter * 10000, 1));
            Window.Update(1, EDIMessageType.Code);

            case EDIMessageType.Direction of
                EDIMessageType.Direction::Inbound:
                    ProcessInbound(EDIMessageType);
                EDIMessageType.Direction::Outbound:
                    ProcessOutbound(EDIMessageType);
            end;
        until EDIMessageType.Next() = 0;

        Window.Close();

        Message(
          Text002 +
          Text003 +
          Text004, CounterOK, TotalCounter, MessageCounter[1], MessageCounter[2]);
    end;

    var
        EDIMessageTypeMgt: Codeunit "RZW EDI Message Type Mgt.";
        Window: Dialog;
        TotalCounter: Integer;
        UpdateCounter: Integer;
        LineCounter: Integer;
        Counter: Integer;
        CounterOK: Integer;
        MessageCounter: array[2] of Integer;
        Text001: Label 'Processing EDI Message Types #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 EDI Message Types out of a total of %2 have now been succesfully processed.\\';
        Text003: Label '%3 new inbound messages have been created.\\';
        Text004: Label '%4 new outbound messages have been created.';
        Text010: Label 'This batch will process all EDI Message Types which are not Blocked and are not running in Test Mode.\\EDI Message Types that will be ignored have been marked Red on the EDI Message Type List.\\';
        Text011: Label 'Do you want to continue?';
        Text012: Label 'There is nothing to process.';

    local procedure ProcessInbound(var EDIMessageType2: Record "RZW EDI Message Type")
    var
        QtyBefore: Integer;
        QtyAfter: Integer;
    begin
        Counter := Counter + 1;

        EDIMessageType2.CalcFields("Qty. of Messages");
        QtyBefore := EDIMessageType2."Qty. of Messages";

        CLEAR(EDIMessageTypeMgt);
        EDIMessageTypeMgt.SetHideDialog(true);
        if EDIMessageTypeMgt.RUN(EDIMessageType2) then begin
            EDIMessageType2.CalcFields("Qty. of Messages");
            QtyAfter := EDIMessageType2."Qty. of Messages";
            MessageCounter[EDIMessageType2.Direction + 1] := MessageCounter[EDIMessageType2.Direction + 1] + (QtyAfter - QtyBefore);

            CounterOK := CounterOK + 1;
        end;
    end;

    local procedure ProcessOutbound(var EDIMessageType2: Record "RZW EDI Message Type")
    var
        QtyBefore: Integer;
        QtyAfter: Integer;
    begin
        Counter := Counter + 1;

        EDIMessageType2.CalcFields("Qty. of Messages");
        QtyBefore := EDIMessageType2."Qty. of Messages";

        CLEAR(EDIMessageTypeMgt);
        EDIMessageTypeMgt.SetHideDialog(true);
        if EDIMessageTypeMgt.RUN(EDIMessageType2) then begin
            EDIMessageType2.CalcFields("Qty. of Messages");
            QtyAfter := EDIMessageType2."Qty. of Messages";
            MessageCounter[EDIMessageType2.Direction + 1] := MessageCounter[EDIMessageType2.Direction + 1] + (QtyAfter - QtyBefore);

            CounterOK := CounterOK + 1;
        end;
    end;
}

