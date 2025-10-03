# Define connection parameters
$serverName = "NB-LENOVO-I\SQL_2022"
$databaseName = "demo_db"  # Replace with your actual database name
$tableName = "dbo.orders"

# Build the connection string
$connectionString = "Server=$serverName;Database=$databaseName;Integrated Security=True;TrustServerCertificate=True"

# Create and open the SQL connection
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

# Define the SQL query
$query = "SELECT TOP (1000) * FROM $tableName"

# Create the SQL command
$command = $connection.CreateCommand()
$command.CommandText = $query

# Execute the query and get the data reader
$reader = $command.ExecuteReader()

# Walk through each row with a delay
while ($reader.Read())
{
    # Example: Print each column value
    Write-Host "Now I am doing some stuff with the record inside the application"
    Start-Sleep -Seconds 1
}

# Clean up
$reader.Close()
$connection.Close()