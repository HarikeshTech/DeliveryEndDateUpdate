tableextension 60009 MyExtension extends "Job Task"
{
    fields
    {
        // Add changes to table fields here
        field(60000; "Expected Milestone Compilation"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(60001; "Estimated Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(60002; "Delivery End Date"; Date)
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
}
