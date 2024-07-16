tableextension 60010 JobPlanningLine extends "Job Planning Line"
{
    fields
    {
        // Add changes to table fields here
        field(60000; "Planned Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(60002; Estimation; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        modify("Unit Cost")
        {
            trigger OnBeforeValidate()
            var
            begin
                CheckBudget();
            end;
        }
        modify(Quantity)
        {
            trigger OnBeforeValidate()
            begin
                CheckBudget();
            end;
        }
        modify("Planning Date")
        {
            trigger OnBeforeValidate()
            begin
                CheckBudget();
            end;
        }
        modify("No.")
        {
            trigger OnBeforeValidate()
            begin
                CheckBudget();
            end;
        }
        field(70000; "Contract Signing Date"; Date)
        {
        }
        field(70001; "Invoice Date"; Date)
        {
        }
        field(70002; "Delivery Date"; Date)
        {
        }
        field(70003; "Submission Date"; Date)
        {
        }
        field(70004; "Commisioning Date"; Date)
        {
        }
        field(70005; "Completion Date"; Date)
        {
        }
        Field(110; "Buyer"; Code[20])
        {
            TableRelation = "Salesperson/Purchaser".Code;
        }
        field(70006; "Delivery End Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        // Add changes to keys here
    }
    fieldgroups
    {
        // Add changes to field groups here
    }
    var
        myInt: Integer;
        JobPlanLines: Record "Job Planning Line";
        job: Record Job;

    local procedure CheckBudget()
    var
        myInt: Integer;
        NewPostingDate: Date;
        LastPostingDate: Date;
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        DimensionSetEntry: Record "Dimension Set Entry";
        Amt: Decimal;
        Amt2: Decimal;
        Items: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        jobs: record job;
        JobPlanLines2: record "Job Planning Line";
        EMailMessage: Codeunit "Email Message";
        Email: Codeunit Email;
        JobSetup: Record "Jobs Setup";
        ToReceipt, CCMailList, BCCMailList : list of [Text];
    begin
        NewPostingDate := CalcDate('CM+1d-1M', "Planning Date");
        LastPostingDate := CALCDATE('CM', "Planning Date");
        if "Line Type" = "Line Type"::Billable then begin
            Amt := "Unit Cost" * Quantity;
            JobPlanLines.Reset();
            JobPlanLines.SetRange("Line Type", JobPlanLines."Line Type"::Billable);
            JobPlanLines.SetRange("Job Task No.", "Job Task No.");
            JobPlanLines.SetRange("Job No.", "Job No.");
            if JobPlanLines.Find('-') then
                repeat
                    Amt := Amt + JobPlanLines."Total Cost";
                until JobPlanLines.next = 0;
            JobPlanLines2.Reset();
            JobPlanLines2.SetRange("Line Type", JobPlanLines2."Line Type"::Budget);
            JobPlanLines2.SetRange("Job Task No.", "Job Task No.");
            JobPlanLines2.SetRange("Job No.", "Job No.");
            if JobPlanLines2.Find('-') then
                repeat
                    Amt2 := Amt2 + JobPlanLines2."Total Cost";
                until JobPlanLines2.next = 0;
            if Amt2 < Amt then begin
                // Error('Budget Amount for GL %1 exceeding', "No.");
                If Rec."Line Type" = rec."Line Type"::Billable then begin
                    JobSetup.Get;
                    IF JobSetup."E-Mail" <> '' Then begin
                        ToReceipt.add(JobSetup."E-Mail");
                        CCMailList.add(JobSetup."CC-Mail");
                        EMailMessage.Create(ToReceipt, 'Project Planning Line Changes: ' + Format(Rec."Job No."), '', true, CCMailList, BCCMailList);
                        EMailMessage.AppendToBody('Project Planning Line Budget Changes');
                        EMailMessage.AppendToBody('</br>');
                        EMailMessage.AppendToBody('Project No.: ' + Format(Rec."Job No."));
                        EMailMessage.AppendToBody('<br>');
                        EMailMessage.AppendToBody('Project Task No.: ' + Format(Rec."Job Task No."));
                        EMailMessage.AppendToBody('<br>');
                        EMailMessage.AppendToBody('Item No.: ' + Format(Rec."No."));
                        EMailMessage.AppendToBody('<br>');
                        EMailMessage.AppendToBody('Old Budget: ' + Format(xRec."Unit Cost"));
                        EMailMessage.AppendToBody('<br>');
                        EMailMessage.AppendToBody('New Budget: ' + Format(Rec."Unit Cost"));
                        EMailMessage.AppendToBody('<br>');
                        EMailMessage.AppendToBody('User :' + Format(UserId));
                        EMailMessage.AppendToBody('<br>');
                        EMailMessage.AppendToBody('<br><br>');
                        Email.Send(EMailMessage);
                    end
                    else begin
                        Error('Specify Email Id in Project Setup');
                    end;
                end;
            end;
        End;
    end;

    trigger OnAfterInsert()
    var
        myInt: Integer;
    begin
        job.Reset();
        job.SetRange("No.", Rec."Job No.");
        if job.Find('-') then begin
            Rec.Estimation := job.Estimation;
        end;
    end;
}
