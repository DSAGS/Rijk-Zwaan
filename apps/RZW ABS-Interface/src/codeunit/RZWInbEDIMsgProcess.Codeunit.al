namespace RZW;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 50111 "RZW Inb. EDI Msg.-Process"
{
    TableNo = "RZW EDI Message Header";

    trigger OnRun()
    var
        GLSetup: Record "General Ledger Setup";
        EDIMessageType: Record "RZW EDI Message Type";
        EDIMessageHeader2: Record "RZW EDI Message Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Window: Dialog;
        LineCounter: Integer;
        CurrentEntryNo: Integer;
        CurrentFieldNo: Integer;
        Text000: Label 'You cannot process EDI Message with Run No. %1, since earlier generated EDI Messages exist for the same company.';
        Text002: Label 'Processing lines              #2######';
        Text010: Label 'A %1 with %2 %3 could not be found.';
        Text011: Label 'Multiple records of the type %1 have been found with %2 %3.';
        Text012: Label 'The Value %1 could not be converted into a Quantity.';
        Text013: Label 'An unknown Supplier Code has been used in message %1 (%2).';
        Text020: Label '%1 %2 does have %3 %4 as %5. This doens''t match the value of the NAD-IV record in %6 %7. Please check your settings.';
        Text021: Label '''';
        Text030: Label 'VAT correction';
        EmptyTextLine: Label 'Bónus - Alínea b) do nº 6 do Art. 16º do CIVA';

    begin
        ClearAll();
        EDIMessageHeader := Rec;

        EDIMessageHeader.Status := EDIMessageHeader.Status::Rejected;
        EDIMessageHeader.Modify();
        Commit();
        // To prevent processing in a wrong company
        EDIMessageHeader.TestField(Company, CompanyName);

        GLSetup.Get();
        EDISetup.Get();

        EDIMessageType.Get(EDIMessageHeader."EDI Message Type");
        EDIMessageType.TestField(Direction, EDIMessageType.Direction::Inbound);
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

        Window.Open(
          '#1#################################\\' +
          Text002);
        Window.Update(1, StrSubstNo('%1 %2', EDIMessageHeader.TableCaption, EDIMessageHeader."Run No."));

        case EDIMessageHeader."File Type" of
            EDIMessageHeader."File Type"::"Sales Invoice":
                ProcessSalesDocument();
            EDIMessageHeader."File Type"::"Customer Master":
                ProcessCustomer();
            EDIMessageHeader."File Type"::"Vendor Master":
                ProcessVendor();
        end;

        EDIMessageHeader.Status := EDIMessageHeader.Status::Processed;
        EDIMessageHeader.Modify();
        Commit();
        Rec := EDIMessageHeader;
    end;

    var
        EDIMessageHeader: Record "RZW EDI Message Header";
        EDISetup: Record "RZW EDI Setup";
        NoOfDocuments: Integer;
        TestNoOfDocuments: Boolean;
        Text001: Label 'There is nothing to process.';
        Text031: Label 'The total No. of Documents in the File does not match the quantity indicated in the file header.\\Please check the file.';


    local procedure ProcessSalesDocument()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail.SetRange("Field No.", 1);
        if not EDIMessageLineDetail.FindSet() then
            Error(Text001);

        EDISetup.TestImportSInv();

        repeat
            case EDIMessageLineDetail.Content of
                'TOT01':
                    ProcessTOT01(EDIMessageLineDetail);
                'HDR01':
                    ProcessHDR01(EDIMessageLineDetail);
                // 'HDR03':
                //     ProcessHDR03(EDIMessageLineDetail);
                'LIN01':
                    ProcessLIN01(EDIMessageLineDetail);
                // 'LIN06':
                //     ProcessLIN06(EDIMessageLineDetail); 
                // 'LIN08':
                //     ProcessLIN08(EDIMessageLineDetail);
                'FTR01':
                    ProcessFTR01(EDIMessageLineDetail);
                else begin
                    //add publisher event here for other content types. the calls above need to be moved to a separate extension.

                end;
            end
        until EDIMessageLineDetail.Next() = 0;
        // Check for correct number of documents
        if TestNoOfDocuments then
            if NoOfDocuments <> 0 then
                Error(Text031);
    end;

    local procedure ProcessCustomer()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        EDIMessageLineDetail.SetRange("EDI Message Type", EDIMessageHeader."EDI Message Type");
        EDIMessageLineDetail.SetRange("Run No.", EDIMessageHeader."Run No.");
        EDIMessageLineDetail.SetRange("Field No.", 1);
        if not EDIMessageLineDetail.FindSet() then
            Error(Text001);

        EDISetup.TestImportCust();

        repeat
            case EDIMessageLineDetail.Content of
                'LIN02':
                    ProcessLIN02(EDIMessageLineDetail);
                'LIN04':
                    ProcessLIN04(EDIMessageLineDetail);
                // 'LIN11':
                //     ProcessLIN11(EDIMessageLineDetail); this needs to be moved to a separate extension.
                else begin
                    //add publisher event here for other content types
                end
            end;
        until EDIMessageLineDetail.Next() = 0;

    end;

    local procedure ProcessVendor()
    var
        EDIMessageLineDetail: Record "RZW EDI Message Line Detail";
    begin
        Error('TODO: Implement ProcessVendor procedure here.');
    end;

    local procedure ProcessTOT01(EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    begin
        Error('TODO: Procedure ProcessTOT01 not implemented.');
    end;

    local procedure ProcessHDR01(EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    begin
        Error('TODO: Procedure ProcessHDR01 not implemented.');
    end;

    local procedure ProcessLIN01(EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    begin
        Error('TODO: Procedure ProcessLIN01 not implemented.');
    end;

    local procedure ProcessFTR01(EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    begin
        Error('TODO: Procedure ProcessFTR01 not implemented.');
    end;

    local procedure ProcessLIN02(EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    begin
        Error('TODO: Procedure ProcessLIN02 not implemented.');
    end;

    local procedure ProcessLIN04(EDIMessageLineDetail: Record "RZW EDI Message Line Detail")
    begin
        Error('TODO: Procedure ProcessLIN04 not implemented.');
    end;
}
