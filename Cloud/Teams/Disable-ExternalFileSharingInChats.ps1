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


    This script checks and disables the setting for sharing files in external chats.


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The executing user must have the following permissions:
    - Teams Administrator

    Author:     Crow With a Hat (CrowWithAHat@crowinthe.cloud)
    Date:       2026-09-29
    Change Log: v0.1 - 2029-09-29 - Initial script creation
                v1.0 - 2029-09-29 - Final release


#>

# This function is used to check for required PowerShell modules
function CheckRequiredModules
   {
   # Check needed module and install, if not existing yet
   if (!(Get-InstalledModule 'MicrosoftTeams'))
      {
      Write-Host 'Module not installed, installing for current user...' -ForegroundColor Yellow
   
      # Try installing module
      try {
          Install-Module -Name MicrosoftTeams -Scope CurrentUser
          Write-Host 'Module installed successfully!' -ForegroundColor Green
          }
      catch {
            Write-Host 'ERROR: Module could not be installed! Please try again. Exiting script...' -Foreground Red
            Exit 1
            }
      }
   }

# This function is used to check and disable the setting for external chats
function CheckAndDisableExternalFileSharingInChats
   {
   # Connect to Microsoft Teams
   Write-Host 'Connecting to Microsoft Teams...' -ForegroundColor Yellow
   Connect-MicrosoftTeams

   # Retrieving all policies where external file sharing is enabled - using Where-Object, as -Filter always returns no results
   Write-Host 'Retrieving all policies where setting is enabled...' -ForegroundColor Yellow
   $Policies = Get-CsTeamsFilesPolicy | Where-Object {$_.FileSharingInChatswithExternalUsers -eq 'Disabled'}
   if ($Policies.Count -ge 1)
      {
      Write-Host "Found $($Policies.Count) policies" -ForegroundColor DarkYellow
      } else {Write-Host 'No policies found. Exiting script...' -ForegroundColor DarkGray;Start-Sleep 2;Exit}
   
   if ($Policies.Count -ge 2)
      {
      # Only continue if either D or C is entered
      do {
         $Choice = Read-Host '(D)isable setting for all policies or (C)hoose from found policies?'
         }
      while ($Choice -ne 'D' -AND $Choice -ne 'C'}

      # If D is chosen, disable setting for all policies
      if ($Choice -eq 'D')
         {
         # Iterate through all policies found
         ForEach ($Policy in $Policies)
            {
            # Disable setting for policy
            Write-Host "Disable setting for $($Policy.Identity)..." -ForegroundColor Yellow
            
            try {
                Set-CsTeamsFilesPolicy -Identity $Policy.Identity -FileSharingInChatsWithExternalUsers Disabled
                Write-Host "Setting disabled successfully for policy $($Policy.Identity)!" -ForegroundColor Green
                }
            catch {Write-Host "ERROR: Setting could not be disabled for policy $($Policy.Identity)!" -ForegroundColor Red}
            }
         }

      # If C is chosen, show list of policies and let user decide which to disable
      if ($Choice -eq 'C')
         {
         # Show list
         $Selection = $Policies | Out-GridView -Title 'Please choose policy(ies)' -OutputMode:Multiple

         # Iterate through all policies found
         ForEach ($Policy in $Selection)
            {
            # Disable setting for policy
            Write-Host "Disable setting for $($Policy.Identity)..." -ForegroundColor Yellow
            
            try {
                Set-CsTeamsFilesPolicy -Identity $Policy.Identity -FileSharingInChatsWithExternalUsers Disabled
                Write-Host "Setting disabled successfully for policy $($Policy.Identity)!" -ForegroundColor Green
                }
            catch {Write-Host "ERROR: Setting could not be disabled for policy $($Policy.Identity)!" -ForegroundColor Red}
            }
         }
      }
   }

# Execute functions
CheckRequiredModules
CheckAndDisableExternalFileSharingInChats
