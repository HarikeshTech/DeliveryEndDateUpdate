pageextension 60004 JobTaskCard extends "Job Task Lines Subform"
{
    layout
    {
        modify("Job Task No.")
        {
            Caption = 'WBS No.';
        }
        modify("End Date")
        {
            Visible = false;
            Caption = 'Delivery Date';
        }

        modify("Start Date")
        {
            Caption = 'Created Date';
        }
        addafter("Start Date")
        {
            field("Delivery End Date"; Rec."Delivery End Date")
            {
                Editable = false;
                ApplicationArea = All;
            }
        }
        // Add changes to page layout here
        addafter("End Date")
        {
            field("Expected Milestone Compilation"; Rec."Expected Milestone Compilation")
            {
                ApplicationArea = All;
            }
            field("Estimated Date"; Rec."Estimated Date")
            {
                ApplicationArea = All;
            }
        }
    }
    var
        myInt: Integer;
}
