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

    This script adds an exclusion group to all MDO policies to remove licensing requirements for the members.


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The executing user must have the following permissions:
    - Exchange Administrator (or higher)
    - Security Administrator (or higher)

    Author:     Benjamin Krah (CrowWithAHat@crowinthe.cloud)
    Date:       2026-02-10
    Change Log: v0.1 - 2026-02-10 - Initial script creation
                v1.0 - 2026-02-10 - Final release


#>

# Function to gather required input
function GetInput
   {
   Write-Host ''
   $Script:NewExclusionGroupName = 'Please provide name for new e-mail enabled security group' 

   # Show list of mailboxes and offer selection
   $Script:Selection = (Get-Mailbox -ResultSize Unlimited | Select-Object name,alias,primarysmtpaddress | Sort-Object name |`
    Out-GridView -Title 'Please choose members for exclusion group (close to skip)' -OutputMode:Multiple).PrimarySmtpAddress 
   }

# Function to configure Defender for Office 365 policies
function ConfigureMDOPolicies
   {
   # Install required PowerShell module if not installed yet
   if (!(Get-InstalledModule ExchangeOnlineManagement -ErrorAction SilentlyContinue)){Install-Module ExchangeOnlineManagement -Scope CurrentUser}
   
   # Connect to Exchange Online
   Write-Host ''
   Write-Host 'Connecting to Exchange Online...' -ForegroundColor Yellow
   Connect-ExchangeOnline -CommandName Get-SafeLinksRule,Get-SafeAttachmentRule,Set-SafeLinksRule,Set-SafeAttachmentRule -ShowBanner:$False
   
   # Create new group
   Write-Host ''
   Write-Host 'Creating new exclusion group...' -ForegroundColor Yellow
   New-DistributionGroup -Name $NewExclusionGroupName -Type Security

   # Add members if mailboxes have been selected
   if ($Selection)
      {
      Write-Host ''
      Write-Host 'Adding members to group...' -ForegroundColor Yellow
      ForEach ($Member in $Selection)
         {
         Add-DistributionGroupMember -Identity $NewExclusionGroupName -Member $Member -BypassSecurityGroupManagerCheck
         }
      }

   # Get all safe MDO-related policies
   Write-Host ''
   Write-Host 'Retrieving all safe links and safe attachments policy rules...' -ForegroundColor Yellow
   $SafeLinksPolicyRules = Get-SafeLinksRule
   $SafeAttachmentPolicyRules = Get-SafeAttachmentRule

   # Modify each safe links policy rule
   ForEach ($SafeLinksPolicyRule in $SafeLinksPolicyRules)
      {
      Write-Host ''
      Write-Host "Adding new group to policy $($SafeLinksPolicy.Name)..." -ForegroundColor Yellow

      # Retrieve current configuration for group exclusions
      $ExcludedGroups = $SafeLinksPolicyRule.ExceptIfSentToMemberOf

      # Add new group to exclusion list
      $ExcludedGroups+=$NewExclusionGroupName
      
      # Update rule
      Set-SafeLinksRule $SafeLinksPolicyRule.Name -ExceptIfSentToMemberOf $ExcludedGroups
      }

   # Modify each rule
   ForEach ($SafeAttachmentPolicyRule in $SafeAttachmentPolicyRules)
      {
      Write-Host ''
      Write-Host "Adding new group to policy $($SafeAttachmentPolicyRule.Name)..." -ForegroundColor Yellow

      # Retrieve current configuration for group exclusions
      $ExcludedGroups = $SafeAttachmentPolicyRule.ExceptIfSentToMemberOf

      # Add new group to exclusion list
      $ExcludedGroups+=$NewExclusionGroupName
      
      # Update rule
      Set-SafeAttachmentRule $SafeAttachmentPolicyRule.Name -ExceptIfSentToMemberOf $ExcludedGroups
      } 

   # Disconnect from Exchange Online
   Disconnect-ExchangeOnline -Confirm:$False
   }

# Execute functions
GetInput
ConfigureMDOPolicies
