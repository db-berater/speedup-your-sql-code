@echo off
REM Define the SQL Server connection parameters
SET SERVER_NAME=SQLServer
SET DATABASE_NAME=ERP_Demo
SET USERNAME=YourUsername
SET PASSWORD=YourPassword

REM Define the SQL query to be executed
SET SQL_QUERY="EXEC dbo.get_statistics_per_time_range @date_from = '2023-01-01, @date_to = '2023-01-31';"

REM Execute the SQL query using sqlcmd
ostress -E -S%SERVER_NAME% -d%DATABASE_NAME% -E -Q%SQL_QUERY% -r10000 -n4


REM Wait for user input before closing the command prompt
PAUSE