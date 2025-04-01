# Function: Generate Summary
function Generate-Summary {
    param (
        [string]$comparisonLogFilePath, # Path to the comparison log file
        [string]$summaryOutputPath, # Path to save the summary file
        [bool]$debugMode = $false, # Enable or disable debugging output
        [string]$logFilePath = $null    # Optional: Path to a log file
    )

    # Log the start of summary generation
    Log-Message -message "Starting summary generation from comparison log: $comparisonLogFilePath" -level "Information" -debugMode $debugMode -logFilePath $logFilePath

    try {
        # Ensure the summary output directory exists
        if (-not (Test-Path -Path $summaryOutputPath)) {
            New-Item -ItemType Directory -Path $summaryOutputPath -Force | Out-Null
        }

        # Load the comparison data using Load-CSV
        $comparisonData = Load-CSV -filePath $comparisonLogFilePath -debugMode $debugMode -logFilePath $logFilePath

        # Group the data by table using Group-Tables
        $groupedByTable = Group-Tables -csvData $comparisonData -debugMode $debugMode -logFilePath $logFilePath

        # Classify the tables using Classify-Tables
        $classifiedTables = Classify-Tables -tableGroups $groupedByTable -debugMode $debugMode -logFilePath $logFilePath

        # Initialize consolidated summary
        $consolidatedSummary = @()

        # Generate table-level statistics
        $tableAdded = ($classifiedTables | Where-Object { $_.ChangeType -eq "Added" }).Count
        $tableDeleted = ($classifiedTables | Where-Object { $_.ChangeType -eq "Deleted" }).Count
        $tableChanged = ($classifiedTables | Where-Object { $_.ChangeType -eq "Changed" }).Count
        $tableUnchanged = ($classifiedTables | Where-Object { $_.ChangeType -eq "Unchanged" }).Count

        $consolidatedSummary += [PSCustomObject]@{
            Action     = "Table Added"
            TableName  = "<Not Applicable>"
            ColumnName = "<Not Applicable>"
            Statistics = $tableAdded
        }
        $consolidatedSummary += [PSCustomObject]@{
            Action     = "Table Deleted"
            TableName  = "<Not Applicable>"
            ColumnName = "<Not Applicable>"
            Statistics = $tableDeleted
        }
        $consolidatedSummary += [PSCustomObject]@{
            Action     = "Table Changed"
            TableName  = "<Not Applicable>"
            ColumnName = "<Not Applicable>"
            Statistics = $tableChanged
        }
        $consolidatedSummary += [PSCustomObject]@{
            Action     = "Table Unchanged"
            TableName  = "<Not Applicable>"
            ColumnName = "<Not Applicable>"
            Statistics = $tableUnchanged
        }

        # Generate column-level statistics for each table
        foreach ($table in $classifiedTables) {
            $tableName = $table.FullTableName
            $changeType = $table.ChangeType

            # Skip column-level statistics for Added or Deleted tables
            if ($changeType -eq "Added" -or $changeType -eq "Deleted") {
                continue
            }

            # Calculate column-level statistics for Changed or Unchanged tables
            $columnsAdded = ($groupedByTable | Where-Object { $_.Name -eq $tableName }).Group | Where-Object { $_.Action -eq "Added" }
            $columnsDeleted = ($groupedByTable | Where-Object { $_.Name -eq $tableName }).Group | Where-Object { $_.Action -eq "Deleted" }
            $columnsChanged = ($groupedByTable | Where-Object { $_.Name -eq $tableName }).Group | Where-Object { $_.Action -eq "Changed" }
            $columnsUnchanged = ($groupedByTable | Where-Object { $_.Name -eq $tableName }).Group | Where-Object { $_.Action -eq "Unchanged" }

            $consolidatedSummary += [PSCustomObject]@{
                Action     = "Columns Added"
                TableName  = $tableName
                ColumnName = "<Not Applicable>"
                Statistics = $columnsAdded.Count
            }
            $consolidatedSummary += [PSCustomObject]@{
                Action     = "Columns Deleted"
                TableName  = $tableName
                ColumnName = "<Not Applicable>"
                Statistics = $columnsDeleted.Count
            }
            $consolidatedSummary += [PSCustomObject]@{
                Action     = "Columns Changed"
                TableName  = $tableName
                ColumnName = "<Not Applicable>"
                Statistics = $columnsChanged.Count
            }

            # Only add "Columns Unchanged" if there are actual unchanged columns
            if ($columnsUnchanged.Count -gt 0) {
                $consolidatedSummary += [PSCustomObject]@{
                    Action     = "Columns Unchanged"
                    TableName  = $tableName
                    ColumnName = "<Not Applicable>"
                    Statistics = $columnsUnchanged.Count
                }
            }

            # Add column-specific statistics for changed columns
            foreach ($column in $columnsChanged) {
                $columnName = ($column.FullFieldName -split '\.')[-1] # Extract only the column name
                $changedColumnsList = $column.ChangedColumns  # Get the ChangedColumns field for the specific column

                # Count the number of comma-separated values in ChangedColumns
                $changeCount = if ($changedColumnsList -is [string]) {
                    ($changedColumnsList -split ',').Count
                }
                else {
                    1 # Default to 1 if ChangedColumns is not a string
                }

                # Add the column-specific entry to the summary
                $consolidatedSummary += [PSCustomObject]@{
                    Action     = "Columns Changed"
                    TableName  = $tableName
                    ColumnName = $columnName
                    Statistics = $changeCount
                }
            }
        }

        # Save the consolidated summary to the output file
        $summaryOutputFile = Join-Path -Path $summaryOutputPath -ChildPath "Summary_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $consolidatedSummary | Export-Csv -Path $summaryOutputFile -NoTypeInformation

        # Log the successful completion of summary generation
        Log-Message -message "Consolidated summary generated successfully and saved to $summaryOutputFile" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    }
    catch {
        # Log any errors during summary generation
        Log-Message -message "Error generating summary: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw "Error generating summary: $($_.Exception.Message)"
    }
}

# Function: Load CSV
function Load-CSV {
    param (
        [string]$filePath, # Path to the CSV file
        [bool]$debugMode = $false, # Enable or disable debugging output
        [string]$logFilePath = $null # Optional: Path to a log file
    )

    try {
        # Load the CSV file
        $csvData = Import-Csv -Path $filePath -ErrorAction Stop

        # Debugging: Log the number of rows loaded
        if ($debugMode) {
            $itemCount = $csvData.Count
            Log-Message -message "Loaded $itemCount rows from CSV file: $filePath" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
        }

        return $csvData
    }
    catch {
        # Log any errors during CSV loading
        Log-Message -message "Error loading CSV file: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw "Error loading CSV file: $($_.Exception.Message)"
    }
}

# Function: Group Tables
function Group-Tables {
    param (
        [array]$csvData, # The loaded CSV data
        [bool]$debugMode = $false, # Enable or disable debugging output
        [string]$logFilePath = $null # Optional: Path to a log file
    )

    try {
        # Group data by table name
        $tableGroups = $csvData | Group-Object {
            ($_.'FullFieldName' -split '\.')[0..1] -join '.' # Extract table name (e.g., [schema].[table])
        }

        # Debugging: Log the number of groups created
        if ($debugMode) {
            $groupCount = $tableGroups.Count
            Log-Message -message "Grouped data into $groupCount tables." -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
        }

        return $tableGroups
    }
    catch {
        # Log any errors during grouping
        Log-Message -message "Error grouping tables: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw "Error grouping tables: $($_.Exception.Message)"
    }
}

# Function: Classify Tables
function Classify-Tables {
    param (
        [array]$tableGroups, # The grouped table data
        [bool]$debugMode = $false, # Enable or disable debugging output
        [string]$logFilePath = $null # Optional: Path to a log file
    )

    $classifiedTables = @()

    foreach ($tableGroup in $tableGroups) {
        $tableName = $tableGroup.Name
        $schemaName, $tableNameOnly = $tableName -replace '\[|\]' -split '\.'

        # Determine the change type for the table
        $actions = $tableGroup.Group | Select-Object -ExpandProperty Action
        $changeType = if (($actions | Where-Object { $_ -ne "Added" } | Measure-Object).Count -eq 0) {
            "Added"
        }
        elseif (($actions | Where-Object { $_ -ne "Deleted" } | Measure-Object).Count -eq 0) {
            "Deleted"
        }
        elseif (($actions | Where-Object { $_ -ne "Unchanged" } | Measure-Object).Count -eq 0) {
            "Unchanged"
        }
        else {
            "Changed"
        }

        # Append the Timestamps from the Schema Metadata
        $TableCreatedOn = ($tableGroup.Group | Select-Object -ExpandProperty TableCreatedOn -First 1)
        $TableUpdatedOn = ($tableGroup.Group | Select-Object -ExpandProperty TableUpdatedOn -First 1)
        $MetadataExtractedOn = ($tableGroup.Group | Select-Object -ExpandProperty MetadataExtractedOn -First 1)

        # Get the list of changed columns for the table (extract only column names)
        $changedColumns = $tableGroup.Group | Where-Object { $_.Action -eq "Changed" } | ForEach-Object {
            ($_.'FullFieldName' -split '\.')[-1] # Extract only the column name (last part of FullFieldName)
        }
        $changedColumnsList = $changedColumns -join ", " # Comma-separated list of changed column names

        # Add the table-level classification
        $classifiedTables += [PSCustomObject]@{
            FullTableName       = $tableName
            SchemaName          = $schemaName
            TableName           = $tableNameOnly
            ChangeType          = $changeType
            TableCreatedOn      = $TableCreatedOn
            TableUpdatedOn      = $TableUpdatedOn
            MetadataExtractedOn = $MetadataExtractedOn
            ChangedColumns      = if ($changedColumnsList) { $changedColumnsList } else { "N/A" }
        }
    }

    # Debugging: Log the number of classified tables
    if ($debugMode) {
        $classifiedCount = $classifiedTables.Count
        Log-Message -message "Classified $classifiedCount tables." -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
    }

    return $classifiedTables
}

# Function: Generate Detailed Summary
function Generate-DetailedSummary {
    param (
        [string]$comparisonLogFilePath, # Path to the comparison log file
        [string]$detailedOutputPath, # Path to save the detailed summary file
        [bool]$debugMode = $false, # Enable or disable debugging output
        [string]$logFilePath = $null # Optional: Path to a log file
    )

    # Log the start of detailed summary generation
    Log-Message -message "Starting detailed summary generation from comparison log: $comparisonLogFilePath" -level "Information" -debugMode $debugMode -logFilePath $logFilePath

    try {
        # Ensure the detailed summary output directory exists
        if (-not (Test-Path -Path $detailedOutputPath)) {
            New-Item -ItemType Directory -Path $detailedOutputPath -Force | Out-Null
        }

        # Load the comparison data
        $comparisonData = Load-CSV -filePath $comparisonLogFilePath -debugMode $debugMode -logFilePath $logFilePath

        # Group the data by table
        $groupedByTable = Group-Tables -csvData $comparisonData -debugMode $debugMode -logFilePath $logFilePath

        # Classify the tables
        $classifiedTables = Classify-Tables -tableGroups $groupedByTable -debugMode $debugMode -logFilePath $logFilePath

        # Save the detailed summary to the output file
        $detailedOutputFile = Join-Path -Path $detailedOutputPath -ChildPath "DetailedSummary_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $classifiedTables | Export-Csv -Path $detailedOutputFile -NoTypeInformation

        # Log the successful completion of detailed summary generation
        Log-Message -message "Detailed summary generated successfully and saved to $detailedOutputFile" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    }
    catch {
        # Log any errors during detailed summary generation
        Log-Message -message "Error generating detailed summary: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw "Error generating detailed summary: $($_.Exception.Message)"
    }
}
