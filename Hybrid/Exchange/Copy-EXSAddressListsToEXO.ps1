<#
.SYNOPSIS

    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⡄⢠⡀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⡀⣄⣶⣷⣿⣿⣿⣿⣿⣷⣾⣤⣆⣠⣀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠲⠰⡶⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠠⣦⣄⣀⠀⠀
    ⠀⠀⠀⠀⠀⠈⠁⠘⣿⡿⣏⣷⡄⢐⢈⡻⢿⣿⣿⣿⣿⣿⡇⢻⢿⠛⠟⠐
    ⠀⠀⠀⠀⠀⠀⠀⢰⡮⢋⡁⣰⣶⣿⣭⣿⣿⣿⣿⣿⣿⡿⢧⠈⡀⠀⠀⠀
    ⠀⠀⣀⡠⠤⢎⣻⠛⣛⣷⣿⣿⣿⣶⣾⣿⠛⠻⣿⣿⣿⣯⢨⠀⢃⠀⠀⠀
    ⢀⣴⣀⣤⣤⣤⣅⣈⣹⣆⣿⣿⡿⠿⢋⠹⡡⣰⣿⣿⣿⣷⢼⠀⢈⠀⠀⠀
    ⠖⠉⠉⠛⠛⠿⠿⠿⣿⣿⣿⣿⣿⣧⣤⣄⣮⢪⣿⣿⣿⣿⣿⣢⡤⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠐⠾⢿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⠛⣿⠣⡱⠽⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⣸⢟⠟⠛⡧⡾⣃⠔⠑⢜⣼⣿⣿⣿⣿⣿⣿⣿⣦⡀

    (C) Crow in the Cloud.

    This script copies Exchange Server address lists to Exchange Online.
    Background: 
    - Exchange Server address lists are not synchronized to Exchange Online. 
    - Migrated users do not have access to address lists hosted on premises.
    - Address lists must be created and maintained for Exchange Online independently.


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The executing user must have the following permissions:
    - View-Only Organization Management role in Exchange Server
    - Address Lists permission in Exchange Online - this permission is not enabled by default, a specific role must be created for this as follows:
      - Connect to Exchange Online with Organization Management/Exchange Administrator permissions
      - New-RoleGroup -Name 'Address Lists Management' -Description 'Members of this group are allowed to manage address lists'
      - New-ManagementRoleAssignment -Name 'Address Lists Management' -Role 'Address Lists'
      - Add-RoleGroupMember -Identity 'Address Lists Management' -Member '<YOUR USER>'
    - Exchange Administrator for creating role groups

    The script is intended to be run on the Entra Connect server.
    On other servers the PowerShell module will be missing and must be manually copied from the Entra Connect server.

    Author:     Benjamin Krah (CrowWithAHat@crowinthe.cloud)
    Date:       2026-02-16
    Change Log: v0.1 - 2026-02-16 - Initial script creation
                v1.0 - 2026-02-16 - Final release



#>
function GetInput
   {
   # Ask for input
   do {$Script:ScriptMode = Read-Host 'Export lists, import lists or both? (E/I/B)'}
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

   # Check if needed CMDlet is available
   if (!(Get-Command Get-Addresslists -ErrorAction SilentlyContinue))
      {
      Write-Host ''
      Write-Host 'ERROR: CMDlets for address lists are not available!' -ForegroundColor DarkYellow
      Write-Host 'If the role group has just been assigned, please wait a few hours and try again' -ForegroundColor Yellow
      Write-Host 'If the role group has not been created yet, do this first and then retry the script' -ForegroundColor Yellow
      Start-Sleep 5
      }
      
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
