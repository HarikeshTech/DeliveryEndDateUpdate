pageextension 60005 JobPlanningLines extends "Job Planning Lines"
{
    layout
    {
        modify("Line Amount")
        {
            Caption = 'Total Price';
        }
        modify("Line Amount (LCY)")
        {
            Caption = 'Total Price (LCY)';
        }
        modify(Type)
        {
            Caption = 'WBS Type';
        }
        modify("No.")
        {
            Caption = 'Unique Code';
        }
        modify("Job Task No.")
        {
            Caption = 'WBS No.';
        }
        modify("Planned Delivery Date")
        {
            Caption = 'Project Delivery Date';
        }
        modify("Planning Date")
        {
            Caption = 'Created Date';
        }
        addafter("Planning Date")
        {
            field("Delivery End Date"; Rec."Delivery End Date")
            {
                ApplicationArea = All;
            }
        }
        modify("Unit Cost")
        {
            //  Editable = false;
            ApplicationArea = all;

            trigger OnAfterValidate()
            begin
                If Rec."Line Type" = rec."Line Type"::Budget then begin
                    If xrec."Unit Cost (LCY)" <> 0 then Error('Use Archive Job Planning Line for update "Unit Cost".');
                end;
            end;
        }
        modify("Unit Cost (LCY)")
        {
            //  Editable = false;
            ApplicationArea = all;

            trigger OnAfterValidate()
            var
            begin
                If Rec."Line Type" = rec."Line Type"::Budget then begin
                    If xrec."Unit Cost (LCY)" <> 0 then Error('Use Archive Job Planning Line for update "Unit Cost".');
                end;
            end;
        }
        // Add changes to page layout here
        addafter("Planned Delivery Date")
        {
            field("Planned date"; Rec."Planned date")
            {
                Caption = 'Indent Actual Date';
                ApplicationArea = All;
            }
            field(Buyer; Rec.Buyer)
            {
                Caption = 'Buyer';
                ApplicationArea = All;
            }
            field(Estimation; Rec.Estimation)
            {
                ApplicationArea = all;
            }
            field("Assemble to Order"; Rec."Assemble to Order")
            {
                ApplicationArea = All;
            }
        }
        addafter("Qty. to Assemble")
        {
            field("Qty. to Assemble (Base)"; Rec."Qty. to Assemble (Base)")
            {
                ApplicationArea = All;
            }
        }
        addafter("Planning Date")
        {
            field("Contract Signing Date"; Rec."Contract Signing Date")
            {
                ApplicationArea = All;
            }
            field("Invoice Date"; Rec."Invoice Date")
            {
                ApplicationArea = All;
            }
            field("Delivery Date"; Rec."Delivery Date")
            {
                ApplicationArea = All;
            }
            field("Submission Date"; Rec."Submission Date")
            {
                ApplicationArea = All;
            }
            field("Commisioning Date"; Rec."Commisioning Date")
            {
                ApplicationArea = All;
            }
            field("Completion Date"; Rec."Completion Date")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        // Add changes to page actions here
        addafter("Create Sales &Credit Memo")
        {
            action("Create Purchase Indent")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    JOB: Record Job;
                    JobTask: Record "Job Task";
                begin
                    CurrPage.SETSELECTIONFILTER(JobPlanLine);
                    IF JobPlanLine.FINDSET THEN
                        REPEAT
                            IndentLine2.Reset();
                            IndentLine2.SetRange("Job No.", JobPlanLine."Job No.");
                            IndentLine2.SetRange("Job Task No.", JobPlanLine."Job Task No.");
                            IndentLine2.SetRange("Job Planning Line No.", JobPlanLine."Line No.");
                            if IndentLine2.Find('-') then Error('Indent %1 already created', IndentLine2."Indent No.");
                            if headerCreated = false then begin
                                PurchasePaybleSetup.Get();
                                PurchasePaybleSetup.TestField("Purchase Indent Nos.");
                                IndentHeader.Init();
                                IndentHeader."Indent No." := NoseriesMgnt.GetNextNo(PurchasePaybleSetup."Purchase Indent Nos.", Today, true);
                                IndentHeader."Posting Date" := Today;
                                IndentHeader."Location Code" := JobPlanLine."Location Code";
                                IndentHeader.Estimation := rec.Estimation;
                                IndentHeader."Assign Buyer" := Rec.Buyer;
                                IndentHeader."Project No." := JobPlanLine."Job No.";
                                IndentHeader."Project Name" := JobPlanLine.Description;
                                IndentHeader."WBS No." := JobPlanLine."Job Task No.";
                                JobTask.reset;
                                JobTask.SetRange("Job No.", JobPlanLine."Job No.");
                                JobTask.SetRange("Job Task No.", JobPlanLine."Job Task No.");
                                IF JobTask.FindFirst then begin
                                    IndentHeader."WBS Description" := JobTask.Description;
                                    JobTask.CalcFields("Schedule (Total Cost)");
                                    IndentHeader."Budget (Total Cost)" := JobTask."Schedule (Total Cost)";
                                end;
                                if JOB.Get(Rec."Job No.") then begin
                                    IndentHeader."Planned date" := JOB."Planned Date";
                                    IndentHeader."Forecast Date" := JOB."Forecast Date";
                                    IndentHeader."Actual date" := JOB."Actual Date";
                                end;
                                IndentHeader."User Id" := UserId;
                                IndentHeader.Insert();
                                headerCreated := true;
                                Rec."Planned Date" := WorkDate;
                                rec.Modify;
                            end;
                            LineNo := LineNo + 10000;
                            IndentLine.init;
                            IndentLine."Indent No." := IndentHeader."Indent No.";
                            IndentLine."Line No." := LineNo;
                            IndentLine.Insert(true);
                            if JobPlanLine.Type = JobPlanLine.Type::"G/L Account" then
                                IndentLine.Validate(Type, indentLine.Type::"G/L Account")
                            else if JobPlanLine.Type = JobPlanLine.Type::Item then IndentLine.Validate(Type, indentLine.Type::Item);
                            IndentLine.Validate("No.", JobPlanLine."No.");
                            IndentLine.Quantity := JobPlanLine.Quantity;
                            // IndentLine.Validate("Direct Unit Cost", JobPlanLine."Unit Cost"); //DA-DP-030724
                            IndentLine."Job No." := JobPlanLine."Job No.";
                            IndentLine."Job Task No." := JobPlanLine."Job Task No.";
                            IndentLine."Project Name" := JOB.Description;
                            IndentLine."Job Planning Line No." := JobPlanLine."Line No.";
                            IndentLine."Unit of Measure Code" := JobPlanLine."Unit of Measure Code";
                            IndentLine.Modify(true);
                        until JobPlanLine.Next = 0;
                    NoseriesMgnt.SaveState();
                    Message('Indent %1 Created Successfully', IndentHeader."Indent No.");
                    //  IndentCard.SetRecord(IndentHeader);
                    //  IndentCard.Run();
                end;
            }
            action("Indent List")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    indents: Page "Purchase Indents";
                begin
                    indents.Run();
                end;
            }
            action("Budget Revision and Approval")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                //DA-DP-210624
                trigger OnAction()
                var
                    ArchiveLine: Record "JFE Job Planning Line Archive";
                    LastVersionNo: Integer;
                    ArchiveLinecopy: Record "JFE Job Planning Line Archive";
                    ArchiveLineApprove: Record "JFE Job Planning Line Archive";
                    ArchiveLineFilter: Record "JFE Job Planning Line Archive";
                    PageArchive: Page "JFE_Project Planning Line Arch";
                    item: page "Item List";
                begin
                    ArchiveLine.reset;
                    ArchiveLine.SetRange("Job No.", Rec."Job No.");
                    ArchiveLine.SetRange("Job Task No.", rec."Job Task No.");
                    ArchiveLine.SetRange("Line No.", Rec."Line No.");
                    ArchiveLine.Ascending;
                    IF ArchiveLine.Findlast Then
                        LastVersionNo := ArchiveLine."Version No." + 1
                    else
                        LastVersionNo := 1;
                    IF Rec."Job No." <> '' then begin
                        ArchiveLinecopy.Init();
                        ArchiveLinecopy.TransferFields(Rec);
                        ArchiveLinecopy."Version No." := LastVersionNo;
                        IF ArchiveLinecopy.Insert then begin
                            ArchiveLineApprove.reset;
                            ArchiveLineApprove.SetRange("Job Task No.", ArchiveLinecopy."Job Task No.");
                            ArchiveLineApprove.SetRange("Job No.", ArchiveLinecopy."Job No.");
                            ArchiveLineApprove.SetRange("Line No.", ArchiveLinecopy."Line No.");
                            ArchiveLineApprove.SetRange("Version No.", LastVersionNo - 1);
                            IF ArchiveLineApprove.FindFirst then begin
                                ArchiveLineApprove."Duplicate Line Approved" := True;
                                ArchiveLineApprove."Approved" := True;
                                ArchiveLineApprove.Modify;
                            end;
                            ArchiveLineFilter.SetRange("Job Task No.", ArchiveLinecopy."Job Task No.");
                            ArchiveLineFilter.SetRange("Job No.", ArchiveLinecopy."Job No.");
                            ArchiveLineFilter.SetRange("Line No.", ArchiveLinecopy."Line No.");
                            ArchiveLineFilter.SetRange("Version No.", ArchiveLinecopy."Version No.");
                            PageArchive.SetTableView(ArchiveLineFilter);
                            PageArchive.run();
                        end;
                    end;
                end;
            }
        }
    }
    var
        myInt: Integer;
        IndentHeader: Record "Purchase Indent Header";
        IndentLine: Record "Purchase Indent Line";
        IndentLine2: Record "Purchase Indent Line";
        PurchasePaybleSetup: Record "Purchases & Payables Setup";
        NoseriesMgnt: Codeunit "No. Series - Batch";
        LineNo: Integer;
        JobPlanLine: Record "Job Planning Line";
        headerCreated: Boolean;
        Indent: Record "Purchase Indent Header";
        IndentCard: Page "Purchase Indent Card";
}
