# Function: Load JSON Data
function Load-JsonData {
    param (
        [string]$folderPath,
        [string]$rawFileNameToIgnore,
        [bool]$debugMode = $false,
        [string]$logFilePath = $null
    )

    $dataTable = @{}

    # Get all JSON files in the folder, excluding the raw file
    Get-ChildItem -Path $folderPath -Filter "*.json" | Where-Object { $_.Name -ne $rawFileNameToIgnore } | ForEach-Object {
        $filePath = $_.FullName
        $fileName = $_.Name

        try {
            # Log the file being processed
            Log-Message -message "Processing file: $filePath" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath

            # Load the JSON content
            $jsonContent = Get-Content -Path $filePath -Raw | ConvertFrom-Json -ErrorAction Stop

            # Iterate through each column and extract FullFieldName and other details
            foreach ($column in $jsonContent.Columns) {
                $fullFieldName = $column.FullFieldName

                if ($null -ne $fullFieldName) {
                    # Store all properties of the column in the hashtable
                    $dataTable["$fullFieldName|$fileName"] = $column
                }
            }
        }
        catch {
            Log-Message -message "Error processing file: $filePath. Exception: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        }
    }

    return $dataTable
}

# Function: Compare Data
function Compare-Data {
    param (
        [hashtable]$dataN,
        [hashtable]$dataNMinus1,
        [bool]$debugMode = $false,
        [string]$logFilePath = $null
    )

    $comparisonResults = @()

    # Full outer join logic based on FullFieldName and FileName
    $allKeys = ($dataN.Keys + $dataNMinus1.Keys) | Sort-Object -Unique

    foreach ($key in $allKeys) {
        try {
            # Split the key into FullFieldName and FileName
            $keyParts = $key -split '\|'
            $fullFieldName = $keyParts[0]
            $fileName = $keyParts[1]

            # Log the key being processed
            Log-Message -message "Processing key: $key (FullFieldName: $fullFieldName, FileName: $fileName)" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath

            # Retrieve records for the current FullFieldName and FileName
            $recordN = $dataN[$key]
            $recordNMinus1 = $dataNMinus1[$key]

            $action = ""
            $additionalRemark = ""
            $table_created_timestamp = "" 
            $table_last_updated_timestamp = ""
            $last_accessed_timestamp = ""
            $changedColumns = @()

            # Retrieve SHA256Hash values
            $sha256HashN = if ($recordN -and $recordN.SHA256Hash) { $recordN.SHA256Hash.ToLower() } else { "Missing" }
            $sha256HashNMinus1 = if ($recordNMinus1 -and $recordNMinus1.SHA256Hash) { $recordNMinus1.SHA256Hash.ToLower() } else { "Missing" }

            # Determine the action and additional remarks
            if ($null -eq $recordN) {
                $action = "Deleted"
                $additionalRemark = "Deleted from version (n-1)"
                $table_created_timestamp = $($recordNMinus1.table_created_timestamp) 
                $table_last_updated_timestamp = $($recordNMinus1.table_last_updated_timestamp)
                $last_accessed_timestamp = $($recordNMinus1.last_accessed_timestamp)
            }
            elseif ($null -eq $recordNMinus1) {
                $action = "Added"
                $additionalRemark = "Added in version (n)"
                $table_created_timestamp = $($recordN.table_created_timestamp) 
                $table_last_updated_timestamp = $($recordN.table_last_updated_timestamp)
                $last_accessed_timestamp = $($recordN.last_accessed_timestamp)
            }
            else {
                # Compare SHA256Hash values
                if ($sha256HashN -ne $sha256HashNMinus1) {
                    if ($changedColumns -notcontains "SHA256Hash") {
                        $changedColumns += "SHA256Hash"
                    }
                }

                # Compare individual properties
                $excludedColumns = @("table_created_timestamp", "table_last_updated_timestamp", "last_accessed_timestamp")
                foreach ($property in $recordN.PSObject.Properties) {
                    $propertyName = $property.Name
                    if ($excludedColumns -notcontains $propertyName) {
                        $valueN = $recordN.$propertyName
                        $valueNMinus1 = $recordNMinus1.$propertyName

                        # Add property to ChangedColumns if values differ
                        if ($valueN -ne $valueNMinus1) {
                            if ($changedColumns -notcontains $propertyName) {
                                $changedColumns += $propertyName
                            }
                        }
                    }
                }

                # Determine the action based on changes
                if ($changedColumns.Count -gt 0) {
                    $action = "Changed"
                    $additionalRemark = "Differences detected in columns: $($changedColumns -join ', ')"
                    $table_created_timestamp = $($recordN.table_created_timestamp) 
                    $table_last_updated_timestamp = $($recordN.table_last_updated_timestamp)
                    $last_accessed_timestamp = $($recordN.last_accessed_timestamp)
                }
                else {
                    $action = "Unchanged"
                    $additionalRemark = "No changes detected"
                    $table_created_timestamp = $($recordN.table_created_timestamp) 
                    $table_last_updated_timestamp = $($recordN.table_last_updated_timestamp)
                    $last_accessed_timestamp = $($recordN.last_accessed_timestamp)
                }
            }

            # Add the result as a custom object
            $comparisonResults += [PSCustomObject]@{
                FullFieldName             = $fullFieldName
                FileName                  = $fileName
                Action                    = $action
                SHA256Hash_from_n         = $sha256HashN
                SHA256Hash_from_n_minus_1 = $sha256HashNMinus1
                AdditionalRemark          = $additionalRemark
                ChangedColumns            = if ($changedColumns.Count -gt 0) {
                    '[' + ($changedColumns -join '], [') + ']'
                }
                else {
                    $null
                }
                TableCreatedOn            = $table_created_timestamp
                TableUpdatedOn            = $table_last_updated_timestamp
                MetadataExtractedOn       = $last_accessed_timestamp
            }
        }
        catch {
            Log-Message -message "Error processing key: $key. Exception: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        }
    }

    return $comparisonResults
}

# Function: Export Error Log
function Export-ErrorLog {
    param (
        [array]$errors,
        [string]$logFilePath
    )

    $errors | Out-File -FilePath $logFilePath -Encoding UTF8
    Log-Message -message "Error log saved to $logFilePath." -level "Information" -logFilePath $logFilePath
}