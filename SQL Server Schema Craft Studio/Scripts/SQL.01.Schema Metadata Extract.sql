--:SETVAR OutputPath "C:\..."

IF OBJECT_ID('tempdb..#AllDBObjectsExtendedMetadata') IS NOT NULL DROP TABLE #AllDBObjectsExtendedMetadata
SELECT
    @@SERVERNAME AS server_name,
	DB_NAME() AS database_name,
    SCHEMA_NAME(tab.schema_id) AS schema_name,
    tab.name AS table_name,
    col.name AS column_name,
    col.column_id AS column_order,
    t.name AS data_type,
    CASE 
        WHEN t.name IN ('char', 'varchar', 'nchar', 'nvarchar') THEN t.name + '(' + CASE WHEN col.max_length = -1 THEN 'max' ELSE CONVERT(VARCHAR(10), col.max_length) END + ')'
        WHEN t.name IN ('decimal', 'numeric') THEN t.name + '(' + CONVERT(VARCHAR(10), col.precision) + ',' + CONVERT(VARCHAR(10), col.scale) + ')'
        ELSE t.name
        END AS data_type_with_size,
    CASE WHEN col.is_nullable = 1 THEN 'YES' ELSE 'NO' END AS is_nullable,
    CASE WHEN idx.index_id IS NOT NULL THEN 'YES' ELSE 'NO' END AS is_unique,
        CASE WHEN tab.type = '1' THEN 'SYSTEM_TABLE'
         WHEN tab.type = 'U' THEN 'USER_TABLE'
         WHEN tab.type = 'V' THEN 'VIEW'
         ELSE tab.type + '- is UNKNOWN'
        END AS table_type,
    CASE WHEN pk.index_id IS NOT NULL AND ref_tab.schema_id IS NULL THEN '<Primary Key>' ELSE SCHEMA_NAME(ref_tab.schema_id) END AS referenced_schema_name,
    CASE WHEN pk.index_id IS NOT NULL AND ref_tab.name IS NULL THEN '<Primary Key>' ELSE ref_tab.name END AS referenced_table_name,
    CASE WHEN pk.index_id IS NOT NULL AND ref_col.name IS NULL THEN '<Primary Key>' ELSE ref_col.name END AS referenced_column_name,
    fk.name AS foreign_key_name,
    JSON_QUERY(
		(
			SELECT 
				ep.name AS property_name,
				ep.value AS property_value
			FROM sys.extended_properties ep
			WHERE ep.major_id = col.object_id 
				AND ep.minor_id = col.column_id
			FOR JSON PATH
		)) AS extended_properties,
    obj.create_date AS table_created_timestamp,
    obj.modify_date AS table_last_updated_timestamp,
    GETDATE() AS last_accessed_timestamp
INTO #AllDBObjectsExtendedMetadata
FROM sys.tables tab
INNER JOIN sys.columns col
    ON tab.object_id = col.object_id
INNER JOIN sys.types t 
    ON col.system_type_id = t.system_type_id 
    AND col.user_type_id = t.user_type_id
LEFT JOIN (
    SELECT object_id, index_id
    FROM sys.indexes
    WHERE is_primary_key = 1
) idx 
    ON tab.object_id = idx.object_id
    AND col.column_id IN (
        SELECT column_id 
        FROM sys.index_columns
        WHERE object_id = idx.object_id 
        AND index_id = idx.index_id
    )
LEFT JOIN sys.foreign_key_columns fk_col
    ON col.object_id = fk_col.parent_object_id 
    AND col.column_id = fk_col.parent_column_id
LEFT JOIN sys.foreign_keys fk
    ON fk_col.constraint_object_id = fk.object_id
LEFT JOIN sys.tables ref_tab
    ON fk_col.referenced_object_id = ref_tab.object_id
LEFT JOIN sys.columns ref_col
    ON fk_col.referenced_object_id = ref_col.object_id 
    AND fk_col.referenced_column_id = ref_col.column_id
LEFT JOIN sys.objects obj
    ON tab.object_id = obj.object_id
LEFT JOIN (
    SELECT object_id, index_id
    FROM sys.indexes
    WHERE is_primary_key = 1
) pk
    ON tab.object_id = pk.object_id
    AND col.column_id IN (
        SELECT column_id 
        FROM sys.index_columns
        WHERE object_id = pk.object_id 
            AND index_id = pk.index_id
    )
WHERE 1 = 1
    AND SCHEMA_NAME(tab.schema_id) NOT IN ('dbo', 'cdc')
    -- AND tab.name IN ('')
    -- AND col.name IN ('')
ORDER BY schema_name, table_name, col.column_id;

-- Generate JSON output for each table
IF OBJECT_ID('tempdb..#MetadataSQLDB_JSON') IS NOT NULL DROP TABLE #MetadataSQLDB_JSON;
SELECT 
    schema_name,
    table_name,
    JSON_QUERY(
        (
            SELECT 
				schema_name,
                table_name,
                JSON_QUERY(
                    (
                        SELECT 
                            column_name,
                            column_order,
                            data_type,
                            data_type_with_size,
                            is_nullable,
                            is_unique,
                            table_type,
                            referenced_schema_name,
                            referenced_table_name,
                            referenced_column_name,
                            foreign_key_name,
                            JSON_QUERY(extended_properties) AS extended_properties,
                            table_created_timestamp,
                            table_last_updated_timestamp,
                            last_accessed_timestamp,
                            '[' + schema_name + '].[' + table_name + '].[' + column_name + ']' AS FullFieldName,
                            HASHBYTES('SHA2_256', 
                                ISNULL(CAST(schema_name AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(table_name AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(column_name AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(column_order AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(data_type_with_size AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(is_nullable AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(is_unique AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(table_type AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(referenced_schema_name AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(referenced_table_name AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(referenced_column_name AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(foreign_key_name AS NVARCHAR(MAX)), '') + 
                                ISNULL(CAST(extended_properties AS NVARCHAR(MAX)), '')
                            ) AS SHA256Hash
                        FROM #AllDBObjectsExtendedMetadata AS col
                        WHERE col.schema_name = tab.schema_name AND col.table_name = tab.table_name
                        ORDER BY col.column_order
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    )
                ) AS Columns
            FROM #AllDBObjectsExtendedMetadata AS tab
            WHERE tab.schema_name = meta.schema_name AND tab.table_name = meta.table_name
            ORDER BY tab.table_name
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        )
    ) AS table_metadata
INTO #MetadataSQLDB_JSON
FROM #AllDBObjectsExtendedMetadata AS meta
GROUP BY schema_name, table_name
ORDER BY schema_name, table_name;

--:OUT "$(OutputPath)\00.rawSchemaMetadataOutput.dat"
SELECT table_metadata FROM #MetadataSQLDB_JSON