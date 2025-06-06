# Function to extract valid JSON content from a raw file
function Extract-ValidJsonContent {
    param (
        [string]$rawFilePath, # Path to the raw JSON file
        [string]$startPattern, # Pattern for the starting line
        [string]$endPattern, # Pattern for the ending line
        [string]$logFilePath = $null, # Optional: Path to a log file
        [bool]$debugMode = $false      # Enable or disable debugging output
    )

    # Log the start of JSON extraction
    Log-Message -message "Extracting valid JSON content from file: $rawFilePath" -level "Information" -debugMode $debugMode -logFilePath $logFilePath

    try {
        # Read the raw file content
        $lines = Get-Content -Path $rawFilePath -ErrorAction Stop

        # Debugging: Log the raw file content
        if ($debugMode) {
            if ($lines.Count -eq 0) {
                Log-Message -message "Raw File Content: The file [$rawFilePath] is empty." -level "Warning" -debugMode $debugMode -logFilePath $logFilePath
            }
            else {
                Log-Message -message "Raw File Content: The file [$rawFilePath] contains $($lines.Count) lines." -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
            }
        }

        # Find the starting line (first line matching the start pattern)
        $startMatch = Select-String -Path $rawFilePath -Pattern $startPattern -SimpleMatch | Select-Object -First 1
        if ($null -eq $startMatch) {
            Log-Message -message "Error: Could not find a line matching the start pattern '$startPattern' in the file [$rawFilePath]." -level "Error" -logFilePath $logFilePath
            throw "Could not find a line matching the start pattern '$startPattern'."
        }
        $startIndex = $startMatch.LineNumber - 1  # Convert to zero-based index
        Log-Message -message "Starting Line Number: $($startIndex + 1)" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath

        # Find the ending line (last line matching the end pattern)
        $endMatch = Select-String -Path $rawFilePath -Pattern $endPattern | Select-Object -Last 1
        if ($null -eq $endMatch) {
            Log-Message -message "Error: Could not find a line matching the end pattern '$endPattern' in the file [$rawFilePath]." -level "Error" -logFilePath $logFilePath
            throw "Could not find a line matching the end pattern '$endPattern'."
        }
        $endIndex = $endMatch.LineNumber - 1  # Convert to zero-based index
        Log-Message -message "Ending Line Number: $($endIndex + 1)" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath

        # Validate indices
        if ($startIndex -eq -1 -or $endIndex -eq -1) {
            Log-Message -message "Error: Could not find valid JSON start or end markers in the file [$rawFilePath]." -level "Error" -logFilePath $logFilePath
            throw "Could not find valid JSON start or end markers."
        }

        # Extract the valid JSON lines
        $validJsonLines = $lines[$startIndex..$endIndex]

        # Combine the lines into a single JSON string
        $validJsonContent = $validJsonLines -join "`n"

        # Fix improperly joined JSON objects by wrapping them in an array and adding commas
        if ($validJsonContent -notmatch '^\s*\[') {
            $jsonFixedContent = "[`n" + ($validJsonContent -replace "}\s*{", "},{") + "`n]"
        }
        else {
            $jsonFixedContent = $validJsonContent
        }

        # Debugging: Log the extracted JSON content
        if ($debugMode) {
            if ([string]::IsNullOrWhiteSpace($jsonFixedContent)) {
                Log-Message -message "Extracted JSON Content: The extracted JSON is empty." -level "Warning" -debugMode $debugMode -logFilePath $logFilePath
            }
            else {
                try {
                    # Parse the JSON content to count the number of items
                    $parsedJson = $jsonFixedContent | ConvertFrom-Json -ErrorAction Stop

                    # Check if it's an array or a single object
                    if ($parsedJson -is [System.Collections.IEnumerable]) {
                        $itemCount = $parsedJson.Count
                        Log-Message -message "Extracted JSON Content: The extracted JSON contains $itemCount items." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
                    }
                    else {
                        Log-Message -message "Extracted JSON Content: The extracted JSON contains 1 item." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
                    }
                }
                catch {
                    Log-Message -message "Error parsing JSON: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
                    throw "Error parsing JSON: $($_.Exception.Message)"
                }
            }
        }

        return $jsonFixedContent
    }
    catch {
        # Log any errors during JSON extraction
        Log-Message -message "Error extracting valid JSON content: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw "Error extracting valid JSON content: $($_.Exception.Message)"
    }
}

# Function to Process JSON Files
function Process-JSON {
    param (
        [string]$jsonRawContent, # Input the valid JSON content from the raw file
        [string]$outputFolder, # Output folder for processed files
        [string]$logFilePath = $null, # Optional: Path to a log file
        [bool]$debugMode = $false # Enable or disable debugging output
    )

    # Log the start of JSON processing
    Log-Message -message "Processing JSON files..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    Log-Message -message "Output Folder: $outputFolder" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath

    try {
        
        # Validate the extracted JSON content
        if (($null -eq $jsonRawContent) -or ($jsonRawContent -eq "")) {
            Log-Message -message "Error: Failed to extract valid JSON content from the raw file." -level "Error" -logFilePath $logFilePath
            throw "Failed to extract valid JSON content from the raw file."
        }

        # Parse the JSON content
        try {
            $jsonContent = $jsonRawContent | ConvertFrom-Json -ErrorAction Stop
            Log-Message -message "Items read from the input JSON Data: $($jsonContent.count)" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
        }
        catch {
            Log-Message -message "Error parsing JSON: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
            throw "Error parsing JSON: $($_.Exception.Message)"
        }

        # Iterate through each object in the JSON array
        $jsonContent | ForEach-Object {
            # Extract schema_name and table_name for the current object
            $schemaName = $_.schema_name
            $tableName = $_.table_name

            # Handle missing or empty table_name
            if (-not $tableName) {
                $tableName = "UnknownTable"
                Log-Message -message "Warning: 'table_name' is missing or empty for schema: $schemaName. Using fallback value 'UnknownTable'." -level "Warning" -debugMode $debugMode -logFilePath $logFilePath
            }

            # Construct the output file name
            $fileName = "$schemaName.$tableName.json"
            $outputFile = Join-Path -Path $outputFolder -ChildPath $fileName

            # Serialize the object to JSON using Newtonsoft.Json
            try {
                # Convert the PowerShell object back to a JSON string
                $rawJsonString = $_ | ConvertTo-Json -Depth 10 -Compress

                # Deserialize the JSON string into a .NET object for proper serialization
                $dotNetObject = [Newtonsoft.Json.JsonConvert]::DeserializeObject($rawJsonString)

                # Serialize the .NET object back to JSON with proper formatting
                $jsonString = [Newtonsoft.Json.JsonConvert]::SerializeObject($dotNetObject, [Newtonsoft.Json.Formatting]::Indented)
            }
            catch {
                Log-Message -message "Error serializing JSON for $($schemaName.$tableName): $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
                return
            }

            # Save the JSON string to the output file
            Set-Content -Path $outputFile -Value $jsonString
        }

        # Log the successful completion of JSON processing
        Log-Message -message "JSON objects have been split and saved to $outputFolder" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    }
    catch {
        # Log errors during JSON processing
        Log-Message -message "Error processing JSON files: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw "Error processing JSON files: $($_.Exception.Message)"
    }
}

# Function to Merge any 2 JSON Files
function Merge-JsonFiles {
    param (
        [string]$folderPathA, # Folder path for subfolder A
        [string]$folderPathB, # Folder path for subfolder B
        [string]$outputFolder, # Folder path to save merged JSON files
        [string]$logFilePath = $null, # Optional: Path to a log file
        [bool]$debugMode = $false      # Enable or disable debugging output
    )

    # Log the start of the merge process
    Log-Message -message "Starting JSON merge process..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    Log-Message -message "Folder A: $folderPathA" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
    Log-Message -message "Folder B: $folderPathB" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
    Log-Message -message "Output Folder: $outputFolder" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath

    try {
        # Ensure the output folder exists
        if (-not (Test-Path -Path $outputFolder)) {
            New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
        }

        # Get all JSON files from both folders
        $filesA = Get-ChildItem -Path $folderPathA -Filter "*.json" -File

        # Iterate through files in folder A
        foreach ($fileA in $filesA) {
            $fileName = $fileA.Name
            $filePathB = Join-Path -Path $folderPathB -ChildPath $fileName

            try {
                # Check if a matching file exists in folder B
                if (Test-Path -Path $filePathB) {
                    # Read and deserialize both JSON files using Newtonsoft.Json
                    $jsonA = [Newtonsoft.Json.JsonConvert]::DeserializeObject((Get-Content -Path $fileA.FullName -Raw))
                    $jsonB = [Newtonsoft.Json.JsonConvert]::DeserializeObject((Get-Content -Path $filePathB -Raw))

                    # Manually add Hierarchy properties from jsonB to jsonA
                    $jsonA.FullTableName = $jsonB.FullTableName
                    $jsonA.schema_priority = $jsonB.schema_priority
                    $jsonA.section_level = $jsonB.section_level
                    $jsonA.table_level = $jsonB.table_level
                    $jsonA.Hierarchy = $jsonB.Hierarchy
                    $jsonString = [Newtonsoft.Json.JsonConvert]::SerializeObject($jsonA, [Newtonsoft.Json.Formatting]::Indented)

                    # Debugging output to inspect item counts
                    if ($debugMode) {
                        $mergedJson = $jsonString | ConvertFrom-Json -ErrorAction Stop
                        Log-Message -message "Merged JSON item counts:\nFullTableName = $($mergedJson.FullTableName)\nAvailable metadata for Columns = $($mergedJson.Columns.Count)\nschema_priority = $($mergedJson.schema_priority)\nsection_level = $($mergedJson.section_level)\ntable_level = $($mergedJson.table_level)\nHierarchy = $($mergedJson.Hierarchy)" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
                    }

                    # Save the merged JSON to the output folder
                    $outputFile = Join-Path -Path $outputFolder -ChildPath $fileName
                    Set-Content -Path $outputFile -Value $jsonString

                    if ($debugMode) {
                        Log-Message -message "Merged file saved: $outputFile" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
                    }
                }
                else {
                    Log-Message -message "No matching file found for $fileName in folder B." -level "Warning" -debugMode $debugMode -logFilePath $logFilePath
                }
            }
            catch {
                Log-Message -message "Error merging file $($fileName): $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
            }
        }

        Log-Message -message "JSON merge process completed successfully." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    }
    catch {
        # Log any errors during the merge process
        Log-Message -message "Error during JSON merge: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw "Error during JSON merge: $($_.Exception.Message)"
    }
}
