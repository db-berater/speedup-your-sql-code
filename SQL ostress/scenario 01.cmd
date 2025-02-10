@echo off
REM Define the SQL Server connection parameters
SET SERVER_NAME=SQLServer
SET DATABASE_NAME=ERP_Demo
SET USERNAME=YourUsername
SET PASSWORD=YourPassword

REM Define the SQL query to be executed
SET SQL_QUERY="EXEC dbo.get_customer_classification;"

REM Execute the SQL query using sqlcmd
REM sqlcmd -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -Q %SQL_QUERY%
ostress -E -S%SERVER_NAME% -d%DATABASE_NAME% -E -Q%SQL_QUERY% -r10000 -n8 -q


REM Wait for user input before closing the command prompt
PAUSE