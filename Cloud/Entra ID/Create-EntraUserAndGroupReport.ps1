<#
.SYNOPSIS

  ⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⡀⡄⢠⡀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀ ⠀⠀⠀⠀⡀⣄⣶⣷⣿⣿⣿⣿⣿⣷⣾⣤⣆⣠⣀⠀⠀⠀⠀⠀⠀⠀
  ⠀ ⠀⠀⠲⠰⡶⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠠⣦⣄⣀⠀⠀
  ⠀⠀ ⠀⠀⠀⠈⠁⠘⣿⡿⣏⣷⡄⢐⢈⡻⢿⣿⣿⣿⣿⣿⡇⢻⢿⠛⠟⠐
  ⠀ ⠀⠀⠀⠀⠀⠀⢰⡮⢋⡁⣰⣶⣿⣭⣿⣿⣿⣿⣿⣿⡿⢧⠈⡀⠀⠀⠀
   ⠀⠀⣀⡠⠤⢎⣻⠛⣛⣷⣿⣿⣿⣶⣾⣿⠛⠻⣿⣿⣿⣯⢨⠀⢃⠀⠀⠀
   ⢀⣴⣀⣤⣤⣤⣅⣈⣹⣆⣿⣿⡿⠿⢋⠹⡡⣰⣿⣿⣿⣷⢼⠀⢈⠀⠀⠀
   ⠖⠉⠉⠛⠛⠿⠿⠿⣿⣿⣿⣿⣿⣧⣤⣄⣮⢪⣿⣿⣿⣿⣿⣢⡤⠀⠀⠀
  ⠀ ⠀⠀⠀⠀⠀⠐⠾⢿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀
   ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⠛⣿⠣⡱⠽⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀
   ⠀⠀⠀⠀⠀⠀⠀⠀⣸⢟⠟⠛⡧⡾⣃⠔⠑⢜⣼⣿⣿⣿⣿⣿⣿⣿⣦⡀
  
    (C) Crow in the Cloud, 2026.


    This script can be used to create a basic report of all Entra users and groups and send
    an export file to a specified email address.


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The script is intended to be run in an Azure Automation Runbook with a managed identity assigned to it. 
    The managed identity must have the following permissions: 
    (see https://praveenkumarsreeram.com/2024/12/29/azure-assign-api-permissions-to-managed-identity-using-powershell/ for details how to configure this)
    - User.Read.All
    - Group.Read.All
    - Mail.Send

    IMPORTANT: The Mail.Send permission gives permissions to all mailboxes in Exchange Online by default. 
               If you want to restrict the access to a specific mailbox, you can use App RBAC (https://learn.microsoft.com/en-us/exchange/permissions-exo/application-rbac).

    Author:     Benjamin Krah (CrowWithAHat@crowinthe.cliud
    Date:       2026-08-26
    Change Log: v0.1 - 2026-08-26 - Initial script creation
                v1.0 - 2026-08-26 - Final release


#>


# Create variables
$CurrentDate = ($(Get-Date -Format 'dd.MM.yyyy'))
$SmtpSenderMail  = '<Sender address, must be assigned to a mailbox in Exchange Online>'
$RecipientMail   = '<Recipient address>'
$Subject         = "Entra User and Group Report - $CurrentDate"

# Create export file variables (TEMP because no storage account is used)
$UserCsvPath     = "$env:TEMP\Entra_Users_Export_$CurrentDate.csv"
$GroupCsvPath    = "$env:TEMP\Entra_Groups_Export_$CurrentDate.csv"

# Connect to Microsoft Graph
Write-Output 'Connect to Microsoft Graph using managed identity...'
try {
    # Connect using managed identity
    Connect-MgGraph -Identity
} catch {
    Write-Error "Connecting to Microsoft Graph failed: $_"
    throw
}

# Get all users
Write-Output 'Retrieving Entra ID users...'
$AllUsers = Get-MgUser -All -Property 'Id','DisplayName','UserPrincipalName','Mail','JobTitle','Department','AccountEnabled' | 
    Select-Object Id, DisplayName, UserPrincipalName, Mail, JobTitle, Department, AccountEnabled

# Export users to CSV file
$AllUsers | Export-Csv -Path $UserCsvPath -NoTypeInformation -Encoding utf8
Write-Output "Users exported successfully ($( ($AllUsers | Measure-Object).Count ) rows)."

# Get all groups
Write-Output 'Retrieving Entra ID groups...'
$AllGroups = Get-MgGroup -All -Property 'Id','DisplayName','MailEnabled','SecurityEnabled','GroupTypes','Description' | 
    Select-Object Id, DisplayName, MailEnabled, SecurityEnabled, @{Name='GroupType'; Expression={$_.GroupTypes -join ';'}},'Description'

# Export groups to CSV file
$AllGroups | Export-Csv -Path $GroupCsvPath -NoTypeInformation -Encoding utf8
Write-Output "Groups exported successfully ($( ($AllGroups | Measure-Object).Count ) rows)."

# Convert CSV files to Base64 (Graph requirement)
Write-Output 'Preparing email attachments...'
$UserCsvBytes  = [System.IO.File]::ReadAllBytes($UserCsvPath)
$UserCsvBase64 = [System.Convert]::ToBase64String($UserCsvBytes)

$GroupCsvBytes  = [System.IO.File]::ReadAllBytes($GroupCsvPath)
$GroupCsvBase64 = [System.Convert]::ToBase64String($GroupCsvBytes)

# Create mail body based on JSON format
$MailBody = @{
    Message = @{
        Subject = $Subject
        Body = @{
            ContentType = 'HTML'
            Content = 'Greetings,<br><br>please find attached the current report of all Entra ID users and groups.<br><br>Best regards,<br>Entra Report Automation'
        }
        ToRecipients = @(
            @{ EmailAddress = @{ Address = $RecipientMail } }
        )
        
        Attachments = @(
            @{
                '@odata.type' = '#microsoft.graph.fileAttachment'
                Name = "Entra_Users_Export_$CurrentDate.csv"
                ContentType = 'text/csv'
                ContentBytes = $UserCsvBase64
            },
            @{
                '@odata.type' = '#microsoft.graph.fileAttachment'
                Name = "Entra_Groups_Export_$CurrentDate.csv"
                ContentType = 'text/csv'
                ContentBytes = $GroupCsvBase64
            }
        )
    }
}

# Send mail via Graph API
Write-Output "Sending mail to $RecipientMail via Graph API..."
try {
    # Send mail
    Send-MgUserMail -UserId $SmtpSenderMail -BodyParameter $MailBody
    Write-Output 'Email sent successfully!'
} catch {
    Write-Error "Error sending mail: $_"
}

# Cleanup temporary files in sandbox
Remove-Item -Path $UserCsvPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $GroupCsvPath -Force -ErrorAction SilentlyContinue

# Disconnect from Microsoft Graph
Disconnect-MgGraph | Out-Null
