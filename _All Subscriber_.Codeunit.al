codeunit 50002 "All Subscriber"
{
    //Table Gen Journal Line Start
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetVendorAccount', '', true, true)]
    local procedure OnAfterAccountNoOnValidateGetVendorAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; CallingFieldNo: Integer)
    var
        RecVendBank: Record "Vendor Bank Account";
    begin
        //WIN409
        RecVendBank.RESET;
        RecVendBank.SETFILTER("Vendor No.", GenJournalLine."Account No.");
        IF RecVendBank.FINDFIRST THEN GenJournalLine."Vendor Bank Account" := RecVendBank.Code;
        //WIN409
    end;
    //Table Gen Journal Line End
    //Table Cust. Ledger Entry Start
    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterCopyCustLedgerEntryFromGenJnlLine', '', true, true)]
    local procedure OnAfterCopyCustLedgerEntryFromGenJnlLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        //JFE Sales Header Flow Field// WIN409+++
        CustLedgerEntry."Customer PO No." := GenJournalLine."Customer PO No.";
        CustLedgerEntry."Customer PO Date" := GenJournalLine."Customer PO Date";
        //WIN409---
    end;
    //Table Cust. Ledger Entry End
    //Table GL Entry Start
    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', true, true)]
    local procedure OnAfterCopyGLEntryFromGenJnlLine(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."JV Doc Type" := GenJournalLine."JV Doc Type"; //WIN472
    end;
    //Table GL Entry End
    //Table Reversal Entry Sart
    [EventSubscriber(ObjectType::Table, Database::"Reversal Entry", 'OnCheckGLAccOnBeforeTestFields', '', true, true)]
    local procedure OnCheckGLAccOnBeforeTestFields(GLAcc: Record "G/L Account"; GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        GLAcc.TestField(Blocked, false);
    end;
    //Table Reversal Entry End
    //Table Sales Header Start
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateLocationCode', '', true, true)]
    local procedure OnBeforeValidateLocationCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
    //Table Sales Header End
    //Table Vend Ledger Entry Start
    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterCopyVendLedgerEntryFromGenJnlLine', '', true, true)]
    local procedure OnAfterCopyVendLedgerEntryFromGenJnlLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry."Vendor Bank Account" := GenJournalLine."Vendor Bank Account";
    end;
    //Table Vend Ledger Entry End
    //Codeunit 12 Start
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterPostGLAcc', '', true, true)]
    local procedure OnAfterPostGLAcc(var GenJnlLine: Record "Gen. Journal Line"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer; Balancing: Boolean; var GLEntry: Record "G/L Entry"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GLEntry.COPYLINKS(GenJnlLine); //Win472 14-07-2020
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeVendLedgEntryInsert', '', true, true)]
    local procedure OnBeforeVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
        //WIN409++
        VendorLedgerEntry."Vendor Bank Account" := GenJournalLine."Vendor Bank Account";
        //WIN409--
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterPostVend', '', true, true)]
    local procedure OnAfterPostVend(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
        //MPA BEGIN
        // IF HASLINKS THEN
        // VendLedgEntry.COPYLINKS(GenJnlLine);
        //MPA END-WIN472
        // VendLedgEntry.COPYLINKS(GenJournalLine);//Win472 14-07-2020 aks check
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitVendLedgEntry', '', true, true)]
    local procedure OnAfterInitVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var GLRegister: Record "G/L Register")
    begin
        VendorLedgerEntry."Prepared By" := GenJournalLine."Prepared By"; //WIN401 JFE Prepared By Customisation for Bank Payment Voucher
    end;
    //CodeUnit 12 End
    //CodeUnit 80 Start
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesLines', '', true, true)]
    local procedure OnBeforePostSalesLines(var SalesHeader: Record "Sales Header"; var TempSalesLineGlobal: Record "Sales Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; var EverythingInvoiced: Boolean)
    var
        Customer: Record customer;
        CurrencyRate: Record "Currency Exchange Rate";
    begin
        EverythingInvoiced := FALSE; //WIN472
        IF Customer.Get(SalesHeader."Bill-to Customer No.") then; //DA-DP-180624
        If Customer."GST Customer Type" = Customer."GST Customer Type"::Export then begin
            IF SalesHeader."Currency Code" = '' then Error('Currency code is mandatory for customers');
            If SalesHeader."Currency Code" <> '' then begin //DA-DP-190624
                CurrencyRate.reset;
                CurrencyRate.SetRange("Currency Code", SalesHeader."Currency Code");
                CurrencyRate.SetRange("Starting Date", SalesHeader."Posting Date");
                IF not CurrencyRate.FindFirst then Error('Please update the Currency Exchange rate for %1', SalesHeader."Posting Date");
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostCustomerEntry', '', true, true)]
    local procedure OnBeforePostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        //WIN409++++ //JFE Sales Header fliw field upto CLE
        GenJnlLine."Customer PO No." := SalesHeader."Customer PO No.";
        GenJnlLine."Customer PO Date" := SalesHeader."Customer PO Date";
        //WIN409----
    end;
    //CodeUnit 80 End
    //CodeUnit 90 Start
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnRunOnBeforePostInvoice', '', true, true)]
    local procedure OnRunOnBeforePostInvoice(PurchaseHeader: Record "Purchase Header"; var EverythingInvoiced: Boolean)
    begin
        EverythingInvoiced := FALSE; //WIN472
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostVendorEntry', '', true, true)] //AKS Check
    local procedure OnAfterPostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        // GLEntry.COPYLINKS(GenJnlLine);//Win472 14-07-2020 aks check
    end;
    //CodeUnit //90 End
    //CodeUnit //231 Start  //AKS CHECK
    PROCEDURE Preview1(VAR GenJournalLine: Record "Gen. Journal Line");
    VAR
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PreviewMode: Boolean;
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
    BEGIN
        // PreviewMode := TRUE;
        // GenJnlPostBatch.SetPreviewMode(FALSE);
        // GenJnlLine.COPY(GenJournalLine);
        // GenJnlPostPreview.Start;
        // IF NOT GenJnlPost.Code THEN BEGIN
        //     GenJnlPostPreview.Finish;
        //     IF GETLASTERRORTEXT <> GenJnlPostPreview.GetPreviewModeErrMessage THEN
        //         ERROR(GETLASTERRORTEXT);
        //     GenJnlPostPreview.ShowAllEntries;
        //     ERROR('');
        // END;
    END;
    //CodeUnit 231 End
    //Purchase AmountToVendor
    procedure AmountToVendor(PurcHeader: Record "Purchase Header"): Decimal
    var
        AmountToVendor: Decimal;
        PurcLine: Record "Purchase Line";
    begin
        Clear(AmountToVendor);
        PurcLine.Reset;
        PurcLine.SetRange("Document Type", PurcHeader."Document Type");
        PurcLine.SetRange("Document No.", PurcHeader."No.");
        PurcLine.SetFilter(Type, '<>%1', PurcLine.Type::" ");
        if PurcLine.FindSet then
            repeat
                AmountToVendor += LineAmountToVendor(PurcLine);
            until PurcLine.Next = 0;
        exit(AmountToVendor);
    end;

    procedure LineAmountToVendor(PurcLine: Record "Purchase Line"): Decimal
    var
        TaxTypeObjHelper: Codeunit "Tax Type Object Helper";
        ComponentAmt: Decimal;
        TCS_Amount: Decimal;
        TaxInfomation: Record "Tax Transaction Value";
        Totalgst: Decimal;
        LineAmountToVendor: Decimal;
    begin
        Clear(LineAmountToVendor);
        Clear(Totalgst);
        TaxInfomation.Reset();
        TaxInfomation.SetFilter("Tax Record ID", '%1', PurcLine.RecordId);
        TaxInfomation.SetFilter("Value Type", '%1', TaxInfomation."Value Type"::COMPONENT);
        TaxInfomation.SetRange("Visible on Interface", true);
        if TaxInfomation.FindFirst() then
            repeat
                ComponentAmt := TaxTypeObjHelper.GetComponentAmountFrmTransValue(TaxInfomation);
                if TaxInfomation.GetAttributeColumName = 'CGST' then begin
                    Totalgst += ComponentAmt;
                end;
                if TaxInfomation.GetAttributeColumName = 'SGST' then begin
                    Totalgst += ComponentAmt;
                end;
                if TaxInfomation.GetAttributeColumName = 'IGST' then begin
                    Totalgst += ComponentAmt;
                end;
                if TaxInfomation.GetAttributeColumName = 'TDS' then begin
                    Totalgst -= ComponentAmt;
                end;
            until TaxInfomation.Next() = 0;
        LineAmountToVendor := PurcLine."Line Amount" + Totalgst;
    end;
    //Amt In Word
    Var
        Text16526: Label 'ZERO';
        Text16527: Label 'HUNDRED';
        Text16528: Label 'AND';
        Text16529: Label '%1 results in a written number that is too long.';
        Text16532: Label 'ONE';
        Text16533: Label 'TWO';
        Text16534: Label 'THREE';
        Text16535: Label 'FOUR';
        Text16536: Label 'FIVE';
        Text16537: Label 'SIX';
        Text16538: Label 'SEVEN';
        Text16539: Label 'EIGHT';
        Text16540: Label 'NINE';
        Text16541: Label 'TEN';
        Text16542: Label 'ELEVEN';
        Text16543: Label 'TWELVE';
        Text16544: Label 'THIRTEEN';
        Text16545: Label 'FOURTEEN';
        Text16546: Label 'FIFTEEN';
        Text16547: Label 'SIXTEEN';
        Text16548: Label 'SEVENTEEN';
        Text16549: Label 'EIGHTEEN';
        Text16550: Label 'NINETEEN';
        Text16551: Label 'TWENTY';
        Text16552: Label 'THIRTY';
        Text16553: Label 'FORTY';
        Text16554: Label 'FIFTY';
        Text16555: Label 'SIXTY';
        Text16556: Label 'SEVENTY';
        Text16557: Label 'EIGHTY';
        Text16558: Label 'NINETY';
        Text16559: Label 'THOUSAND';
        Text16562: Label 'LAKH';
        Text16563: Label 'CRORE';
        OnesText: array[20] of Text[30];
        TensText: array[10] of Text[30];
        ExponentText: array[5] of Text[30];

    procedure FormatNoText(var NoText: array[2] of Text[200]; No: Decimal; CurrencyCode: Code[10])
    var
        PrintExponent: Boolean;
        Ones: Integer;
        Tens: Integer;
        Hundreds: Integer;
        Exponent: Integer;
        NoTextIndex: Integer;
        Currency: Record 4;
        TensDec: Integer;
        OnesDec: Integer;
    begin
        CLEAR(NoText);
        NoTextIndex := 1;
        NoText[1] := '';
        IF No < 1 THEN
            AddToNoText(NoText, NoTextIndex, PrintExponent, Text16526)
        ELSE BEGIN
            FOR Exponent := 4 DOWNTO 1 DO BEGIN
                PrintExponent := FALSE;
                IF No > 99999 THEN BEGIN
                    Ones := No DIV (POWER(100, Exponent - 1) * 10);
                    Hundreds := 0;
                END
                ELSE BEGIN
                    Ones := No DIV POWER(1000, Exponent - 1);
                    Hundreds := Ones DIV 100;
                END;
                Tens := (Ones MOD 100) DIV 10;
                Ones := Ones MOD 10;
                IF Hundreds > 0 THEN BEGIN
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Hundreds]);
                    AddToNoText(NoText, NoTextIndex, PrintExponent, Text16527);
                END;
                IF Tens >= 2 THEN BEGIN
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[Tens]);
                    IF Ones > 0 THEN AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones]);
                END
                ELSE IF (Tens * 10 + Ones) > 0 THEN AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Tens * 10 + Ones]);
                IF PrintExponent AND (Exponent > 1) THEN AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent]);
                IF No > 99999 THEN
                    No := No - (Hundreds * 100 + Tens * 10 + Ones) * POWER(100, Exponent - 1) * 10
                ELSE
                    No := No - (Hundreds * 100 + Tens * 10 + Ones) * POWER(1000, Exponent - 1);
            END;
        END;
        IF CurrencyCode <> '' THEN BEGIN
            Currency.GET(CurrencyCode);
            AddToNoText(NoText, NoTextIndex, PrintExponent, ' ');
        END
        ELSE
            AddToNoText(NoText, NoTextIndex, PrintExponent, 'RUPEES');
        AddToNoText(NoText, NoTextIndex, PrintExponent, Text16528);
        TensDec := ((No * 100) MOD 100) DIV 10;
        OnesDec := (No * 100) MOD 10;
        IF TensDec >= 2 THEN BEGIN
            AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[TensDec]);
            IF OnesDec > 0 THEN AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[OnesDec]);
        END
        ELSE IF (TensDec * 10 + OnesDec) > 0 THEN
            AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[TensDec * 10 + OnesDec])
        ELSE
            AddToNoText(NoText, NoTextIndex, PrintExponent, Text16526);
        IF (CurrencyCode <> '') THEN
            AddToNoText(NoText, NoTextIndex, PrintExponent, ' ' + '' + ' ONLY')
        ELSE
            AddToNoText(NoText, NoTextIndex, PrintExponent, ' PAISA ONLY');
    end;

    local procedure AddToNoText(var NoText: array[2] of Text[100]; var NoTextIndex: Integer; var PrintExponent: Boolean; AddText: Text[30])
    begin
        PrintExponent := TRUE;
        WHILE STRLEN(NoText[NoTextIndex] + ' ' + AddText) > MAXSTRLEN(NoText[1]) DO BEGIN
            NoTextIndex := NoTextIndex + 1;
            IF NoTextIndex > ARRAYLEN(NoText) THEN ERROR(Text16529, AddText);
        END;
        NoText[NoTextIndex] := DELCHR(NoText[NoTextIndex] + ' ' + AddText, '<');
    end;

    procedure InitTextVariable()
    begin
        OnesText[1] := Text16532;
        OnesText[2] := Text16533;
        OnesText[3] := Text16534;
        OnesText[4] := Text16535;
        OnesText[5] := Text16536;
        OnesText[6] := Text16537;
        OnesText[7] := Text16538;
        OnesText[8] := Text16539;
        OnesText[9] := Text16540;
        OnesText[10] := Text16541;
        OnesText[11] := Text16542;
        OnesText[12] := Text16543;
        OnesText[13] := Text16544;
        OnesText[14] := Text16545;
        OnesText[15] := Text16546;
        OnesText[16] := Text16547;
        OnesText[17] := Text16548;
        OnesText[18] := Text16549;
        OnesText[19] := Text16550;
        TensText[1] := '';
        TensText[2] := Text16551;
        TensText[3] := Text16552;
        TensText[4] := Text16553;
        TensText[5] := Text16554;
        TensText[6] := Text16555;
        TensText[7] := Text16556;
        TensText[8] := Text16557;
        TensText[9] := Text16558;
        ExponentText[1] := '';
        ExponentText[2] := Text16559;
        ExponentText[3] := Text16562;
        ExponentText[4] := Text16563;
    end;
    //Amt In Word
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ArchiveManagement, 'OnAfterStorePurchDocument', '', true, true)] //AKS Check
    local procedure OnAfterStorePurchDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeaderArchive: Record "Purchase Header Archive")
    var
        Attachment: Record "Document Attachment";
        Attachment2: Record "Document Attachment";
    begin
        Attachment.Reset();
        Attachment.SetRange("Table ID", 38);
        Attachment.SetRange("No.", PurchaseHeader."No.");
        Attachment.SetRange("Document Type", PurchaseHeader."Document Type");
        if Attachment.Find('-') then
            repeat
                Attachment2.Init();
                Attachment2.TransferFields(Attachment);
                Attachment2."Table ID" := Database::"Purchase Header Archive";
                Attachment2."Line No." := PurchaseHeaderArchive."Version No.";
                Attachment2."Version No." := PurchaseHeaderArchive."Version No.";
                Attachment2.Insert();
            until Attachment.Next = 0;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Factbox", 'OnBeforeDrillDown', '', true, true)] //AKS Check
    local procedure OnBeforeDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        case DocumentAttachment."Table ID" of
            0:
                exit;
            Database::"Purchase Header Archive":
                begin
                    RecRef.Open(Database::"Purchase Header Archive");
                    if PurchaseHeaderArchive.Get(DocumentAttachment."Document Type", DocumentAttachment."No.", 1, DocumentAttachment."Line No.") then RecRef.GetTable(PurchaseHeaderArchive);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment factbox", 'OnBeforeDocumentAttachmentDetailsRunModal', '', true, true)] //AKS Check
    local procedure OnBeforeDocumentAttachmentDetailsRunModal(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var DocumentAttachmentDetails: Page "Document Attachment Details")
    var
        PHarchive: Record "Purchase Header Archive";
    begin
        if RecRef.Number = Database::"Purchase Header Archive" then begin
            RecRef.SetTable(PHarchive);
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Document Type", PHarchive."Document Type");
            DocumentAttachment.SetRange("No.", PHarchive."No.");
            DocumentAttachment.SetRange("Line No.", PHarchive."Version No.");
            if DocumentAttachment.FindSet() then DocumentAttachmentDetails.SetTableView(DocumentAttachment);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Sales Inv. - Update", 'OnAfterRecordChanged', '', true, true)] //AKS Check
    local procedure OnAfterRecordChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged := (SalesInvoiceHeader."Distance (Km)" <> xSalesInvoiceHeader."Distance (Km)") or (SalesInvoiceHeader."Shipping Agent Code" <> xSalesInvoiceHeader."Shipping Agent Code") Or (SalesInvoiceHeader."Vehicle No." <> xSalesInvoiceHeader."Vehicle No.") or (SalesInvoiceHeader."Vehicle Type" <> xSalesInvoiceHeader."Vehicle Type") or (SalesInvoiceHeader."Transport Method" <> xSalesInvoiceHeader."Transport Method") or (SalesInvoiceHeader."LR/RR No." <> xSalesInvoiceHeader."LR/RR No.") or (SalesInvoiceHeader."LR/RR Date" <> xSalesInvoiceHeader."LR/RR Date")
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Inv. Header - Edit", 'OnRunOnBeforeAssignValues', '', true, true)] //AKS Check
    local procedure OnRunOnBeforeAssignValues(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."Distance (Km)" := SalesInvoiceHeaderRec."Distance (Km)";
        SalesInvoiceHeader."Shipping Agent Code" := SalesInvoiceHeaderRec."Shipping Agent Code";
        SalesInvoiceHeader."Vehicle Type" := SalesInvoiceHeaderRec."Vehicle Type";
        SalesInvoiceHeader."Vehicle No." := SalesInvoiceHeaderRec."Vehicle No.";
        SalesInvoiceHeader."Transport Method" := SalesInvoiceHeaderRec."Transport Method";
        SalesInvoiceHeader."LR/RR No." := SalesInvoiceHeaderRec."LR/RR No.";
        SalesInvoiceHeader."LR/RR Date" := SalesInvoiceHeaderRec."LR/RR Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", OnBeforeModifySalesHeader, '', false, false)]
    local procedure "Job Create-Invoice_OnBeforeModifySalesHeader"(var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin
        SalesHeader."Contract Signing Date" := JobPlanningLine."Contract Signing Date";
        SalesHeader."Invoice Date" := JobPlanningLine."Invoice Date";
        SalesHeader."Delivery Date" := JobPlanningLine."Delivery Date";
        SalesHeader."Submission Date" := JobPlanningLine."Submission Date";
        SalesHeader."Commisioning Date" := JobPlanningLine."Commisioning Date";
        SalesHeader."Completion Date" := JobPlanningLine."Completion Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Quote to Order", OnBeforeInsertPurchOrderLine, '', false, false)]
    local procedure "Purch.-Quote to Order_OnBeforeInsertPurchOrderLine"(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; PurchQuoteLine: Record "Purchase Line"; PurchQuoteHeader: Record "Purchase Header")
    begin
        if PurchQuoteHeader."Quote Stage" = PurchQuoteHeader."Quote Stage"::"Negotiation Policy" then if PurchQuoteLine."Agreed Unit cost" <> 0 then PurchOrderLine.Validate("Direct Unit Cost", PurchQuoteLine."Agreed Unit cost");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Factbox", OnBeforeDrillDown, '', false, false)]
    local procedure "Document Attachment Factbox_OnBeforeDrillDown"(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        PIH: Record "Purchase Indent Header";
        NPH: Record "Negotiation Policy Header";
        TEH: Record "Technical Evaluation Header";
    begin
        case DocumentAttachment."Table ID" of
            0:
                exit;
            Database::"Purchase Indent Header":
                begin
                    RecRef.Open(Database::"Purchase Indent Header");
                    if PIH.Get(DocumentAttachment."No.") then RecRef.GetTable(PIH);
                end;
            Database::"Technical Evaluation Header":
                begin
                    RecRef.Open(Database::"Technical Evaluation Header");
                    if TEH.Get(DocumentAttachment."No.") then RecRef.GetTable(TEH);
                end;
            Database::"Negotiation Policy Header":
                begin
                    RecRef.Open(Database::"Negotiation Policy Header");
                    if NPH.Get(DocumentAttachment."No.") then RecRef.GetTable(NPH);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Details", 'OnAfterOpenForRecRef', '', true, true)]
    local procedure OnAfterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FlowFieldsEditable: Boolean)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        LineNo: Integer;
    begin
        case RecRef.Number of
            database::"Purchase Indent Header":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment.SetRange("No.", RecNo);
                end;
            database::"Technical Evaluation Header":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment.SetRange("No.", RecNo);
                end;
            database::"Negotiation Policy Header":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment.SetRange("No.", RecNo);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterTableHasNumberFieldPrimaryKey, '', false, false)]
    local procedure "Document Attachment Mgmt_OnAfterTableHasNumberFieldPrimaryKey"(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        case TableNo of
            Database::"Purchase Indent Header", Database::"Technical Evaluation Header", Database::"Negotiation Policy Header":
                begin
                    FieldNo := 1;
                    Result := (true);
                end;
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', true, true)]
    procedure OnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PurchRcpHdrNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
    begin
        if PurchRcpHdrNo <> '' then begin
            JobPlanningLine.Reset();
            JobPlanningLine.SetRange("Job No.", PurchaseHeader."Project No.");
            JobPlanningLine.SetRange("Job Task No.", PurchaseHeader."WBS No.");
            if JobPlanningLine.FindSet() then
                repeat
                    JobPlanningLine.Validate("Delivery End Date", PurchaseHeader."Posting Date");
                    JobPlanningLine.Modify();
                until JobPlanningLine.Next() = 0;
            JobTask.Reset();
            JobTask.SetRange("Job No.", PurchaseHeader."Project No.");
            JobTask.SetRange("Job Task No.", PurchaseHeader."WBS No.");
            if JobTask.FindSet() then
                repeat
                    JobTask.Validate("Delivery End Date", PurchaseHeader."Posting Date");
                    JobTask.Modify();
                until JobTask.Next() = 0;
        end;
    end;
}
