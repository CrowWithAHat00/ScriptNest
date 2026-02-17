
function GetInput
   {
   # Ask for input
   do {$Script:ScriptMode = Read-Host 'Export lsits, import lists or both? (E/I/B)'}
   while ($ScriptMode -ne 'E' -AND $CopyChoice -ne 'I')

   # If export mode is chosen, ask for further steps
   if ($ScriptMode -eq 'E' -OR $ScriptMode -eq 'B')
      {
      do {$Script:CopyChoice = Read-Host 'Copy groups directly or create export for another server? (D/E)'}
      while ($CopyChoice -ne 'D' -AND $CopyChoice -ne 'E')
      }
   }

function ExportAddressLists
   {
   # Connect to Exchange Server
   Write-Host ''
   Write-Host 'Connecting to Exchange Server...' -ForegroundColor Yellow
   C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -noexit -command ". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto -ClientApplication:ManagementShell "

   # Export all non-default address list from Exchange Server
   Write-Host ''
   Write-Host 'Retrieving all non-default address lists...' -ForegroundColor Yellow

   # Export address lists
   # The command works for English and German environments - other languages must be inserted manually
   
   # Write address lists into variable
   $Script:AddressLists = Get-AddressList | Where-Object {$_.Name -ne 'All Contacts' -AND $_.Name -ne 'All Distribution Lists'`
    -AND $_.Name -ne 'All Rooms' -AND $_.Name -ne 'Public Folders' -AND $_.Name -notlike 'Alle Kontakte'`
    -AND $_.Name -ne 'Alle Verteilerlisten' -AND $_.Name -ne 'Alle Räume' -AND $_.Name -ne 'Öffentliche Ordner'}`
    | Select-Object Name,DisplayName,@{n='ConditionalCompany';e={$_.ConditionalCompany}},`
    @{n='ConditionalDepartment';e={$_.ConditionalDepartment}},Container
   
   # Export address lists to file if chosen
   if ($CopyChoice -eq 'E')
      {
      Write-Host ''
      Write-Host 'Exporting lists to personal desktop - please copy the file from there' -ForegroundColor Yellow
      $AddressLists | Export-Csv $Env:USERPROFILE\Desktop\AddressLists.csv -Delimiter ";" -NoTypeInformation -Encoding Default
      }
   }

function ImportAddressLists
   {
   # Check if variable $AddressLists is already populated and use the content for important
   if ($AddressLists)
      {
      Write-Host ''
      Write-Host 'Pre-filled variable for address lists found!' -ForegroundColor Green
      Write-Host 'Using this variable for import...' -ForegroundColor Yellow  
      }
   # If variable is not populated the script is likely executed/continued on another server
   # Check for CSV file in this case
   if (!($AddressLists))
      {
      if (Test-Path $Env:USERPROFILE\Desktop\AddressLists.csv)
         {
         Write-Host ''
         Write-Host 'CSV file "AdressLists.csv" found on desktop! Importing...' -ForegroundColor Green 
         $AddressLists = Import-Csv $env:USERPROFILE\Desktop\AddressLists.csv -Delimiter ";" -Encoding UTF8 
         }
      } else {
             Write-Host ''
             Write-Host 'ERROR: Variable not populated and file not found on desktop!' -ForegroundColor DarkYellow
             Write-Host 'Please copy CSV file to desktop and try again'
             Start-Sleep 5
             Exit
             }

   # Check if needed module is already installed and install, if not
   if (!(Get-InstalledModule ExchangeOnlineManagement -ErrorAction SilentlyContinue)){Install-Module ExchangeOnlineManagement -Scope CurrentUser}
   
   # Connect to Exchange Online
   Write-Host ''
   Write-Host 'Connecting to Exchange Online...' -ForegroundColor Yellow
   Connect-ExchangeOnline -ShowBanner $False

   # Iterate through each row in imported list
   ForEach ($AddressList in $AddressLists)
      {
      # Build parameters for command
      $ListParams = @{
         Name = $AddressList.Name
         DisplayName = $AddressList.Name
         ConditionalCompany = $AddressList.ConditionalCompany
         Container = $AddressList.Container
         }
   
      # Add parameter for ConditionalDepartment if existing
      if ($AddressList.ConditionalDepartment){$ListParams['ConditionalDepartment'] = $AddressList.ConditionalDepartment}
   
      # Create new address list
      Write-Host ''
      Write-Host "Creating address list $($AddressList.Name)..." -ForegroundColor Yellow
      New-AddressList @ListParams -IncludedRecipients AllRecipients -ErrorAction SilentlyContinue
      }

    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$False
    }

# Execute functions based on choices
GetInput
if ($ScriptMode -eq 'E' -OR $ScriptMode -eq 'B'){ExportAddressLists}
if ($ScriptMode -eq 'I'){ImportAddressLists}
