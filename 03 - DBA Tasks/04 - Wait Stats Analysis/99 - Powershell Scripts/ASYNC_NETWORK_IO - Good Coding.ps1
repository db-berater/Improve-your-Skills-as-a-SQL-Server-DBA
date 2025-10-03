# Define connection parameters
$serverName = "NB-LENOVO-I\SQL_2022"
$databaseName = "demo_db"  # Replace with your actual DB name
$tableName = "dbo.orders"
$connectionString = "Server=$serverName;Database=$databaseName;Integrated Security=True"

# Initialize variables
$connection = $null
$command = $null
$dataTable = New-Object System.Data.DataTable

try {
    # Connect and fetch all data
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $connection.Open()
    Write-Host "Connected to SQL Server '$serverName'."

    $query = "SELECT TOP (1000) * FROM $tableName"
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $adapter.Fill($dataTable) | Out-Null

    Write-Host "Fetched $($dataTable.Rows.Count) rows into memory."
}
catch {
    Write-Error "Error during SQL operation: $_"
}
finally {
    # Clean up SQL connection
    if ($connection.State -eq 'Open') {
        $connection.Close()
        Write-Host "Disconnected from SQL Server."
    }
}

# Process rows with latency
foreach ($row in $dataTable.Rows)
{
    try
    {
        # Example: Print each column value
        Write-Host "Now I am doing some stuff with the record inside the application"
        Start-Sleep -Seconds 1
    }
    catch
    {
        Write-Warning "Error processing row: $_"
    }
}
