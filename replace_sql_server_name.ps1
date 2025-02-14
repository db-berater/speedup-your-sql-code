# PowerShell script to replace text in all .json files in the current folder and subfolders

# Define the directory to search (current directory)
$directory = Get-Location

# Define the search and replace strings
$searchText = "NB-LENOVO-I\SQL_2022"
$replaceText = "SQLServer"

# Get all .json files in the directory and subdirectories
$jsonFiles = Get-ChildItem -Path $directory -Recurse -Filter *.json

foreach ($file in $jsonFiles) {
    # Read the content of the file
    $content = Get-Content -Path $file.FullName -Raw

    # Replace the search text with the replace text
    $content = $content -replace [regex]::Escape($searchText), [regex]::Escape($replaceText)

    # Write the updated content back to the file
    Set-Content -Path $file.FullName -Value $content -Force -Encoding UTF8
}

Write-Host "Text replacement complete."
