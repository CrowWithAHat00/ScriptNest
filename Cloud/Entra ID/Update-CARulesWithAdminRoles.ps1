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


    This script checks Conditional Access policies and updates them to include all administrator roles.


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    If the script is executed interactively, the executing user must have the following permissions:
    - Conditional Access Administrator (to read and update Conditional Access policies)
    - Directory reader (to read all directory roles)

    Author:     Crow With a Hat (CrowWithAHat@crowinthe.cloud)
    Date:       2026-09-18
    Change Log: v0.1 - 2026-09-18 - Initial script creation
                v1.0 - 2026-09-18 - Final release
                v1.1 - 2026-09-26 - Small corrections; added exclusion for microsoft-managed policies and feature to exclude specific policies


#>

# Choose simulation mode: Set to $true to only simulate changes. Set to $false to apply changes live.
$Script:WhatIf = $false

# Choose authentication mode: Set to 'Interactive' for user prompt or 'Automated' for service principal authentication.
$Script:ExecutionMode = 'Automated'

# Choose policies to be excluded (add displayname). All Microsoft-managed rules will already be excluded.
$Script:ExcludedPolicies = 'Example policy displayname'

function CheckModules
   {
   # Check if needed modules are installed and install, if not. This is done only in interactive mode, as automated mode assumes the environment is pre-configured.
   if (!(Get-InstalledModule -Name Microsoft.Graph.Authentication))
      {
      Write-Host 'Module Microsoft.Graph.Authentication is not installed. Installing for current user...'
      Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Force
      }
   if (!(Get-InstalledModule -Name Microsoft.Graph.Identity.SignIns))
      {
      Write-Host 'Module Microsoft.Graph.Identity.SignIns is not installed. Installing for current user...'
      Install-Module -Name Microsoft.Graph.Identity.SignIns -Scope CurrentUser -Force
      }
   if (!(Get-InstalledModule -Name Microsoft.Graph.Identity.DirectoryManagement))
      {
      Write-Host 'Module Microsoft.Graph.Identity.DirectoryManagement is not installed. Installing for current user...'
      Install-Module -Name Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser -Force
      }
   }

function CheckAndUpdateCARules
   {
   if ($WhatIf) 
      {
      Write-Output  '=================================================='
      Write-Output ' RUNNING IN WHAT-IF MODE (SIMULATION ON)          '
      Write-Output  ' No live changes will be made to your policies.   '
      Write-Output  '=================================================='
      }

   # Connect to Microsoft Graph
   Write-Output 'Connecting to Microsoft Graph...'
   if ($ExecutionMode -eq 'Interactive'){Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess', 'RoleManagement.Read.Directory' -NoWelcome}
   if ($ExecutionMode -eq 'Automated'){Connect-MgGraph -Identity -NoWelcome}

   # Retrieve all directory roles containing "Administrator" in their name
   Write-Output 'Retrieving all directory roles with "Administrator" in the name...'
   $allAdminRoles = Get-MgDirectoryRoleTemplate | Where-Object { $_.DisplayName -like "*Administrator*" }

   if ($null -eq $allAdminRoles -or $allAdminRoles.Count -eq 0) 
      {
      Write-Error "No directory roles found containing the word 'Administrator' in the name."
      return
      }

   Write-Output "Total administrator roles found: $($allAdminRoles.Count)"

   # Retrieve all Conditional Access policies
   Write-Output "Retrieving all Conditional Access policies..."
   $caPolicies = Get-MgIdentityConditionalAccessPolicy

   ForEach ($policy in $caPolicies) 
      {
      # Only process rule, if not microsoft-managed or in excluded policies list
      if ($policy.DisplayName -notlike 'Microsoft-managed:*' -AND $ExcludedPolicies -notcontains $policy.DisplayName)
         {
         # Check if the policy targets specific roles
         $includedRoles = $policy.Conditions.Users.IncludeRoles
            
         if ($null -ne $includedRoles -and $includedRoles.Count -gt 0) 
            {
            # Check if at least one of the included roles is an administrator role
            $hasAdminRole = $false
            foreach ($roleId in $includedRoles) 
                {
                if ($roleId -in $allAdminRoles.Id) 
                {
                $hasAdminRole = $true
                break
                }
                }
                
            # If the policy applies to at least one administrator role
            if ($hasAdminRole) 
                {
                Write-Output '--------------------------------------------------'
                Write-Output "Policy matched: $($policy.DisplayName)"
                    
                # Identify missing administrator roles
                $missingRoles = @()
                foreach ($adminRole in $allAdminRoles) 
                {
                if ($adminRole.Id -notin $includedRoles) 
                    {
                    $missingRoles += $adminRole.Id
                    }
                }
                    
                if ($missingRoles.Count -gt 0) 
                {
                Write-Output "The following roles are missing in this policy: $($missingRoles.Count)"
                        
                # Create a new list of roles to include (Existing + Missing)
                $updatedRoles = $includedRoles + $missingRoles
                        
                # Prepare the update object
                $updateParams = @{
                    Conditions = @{
                        Users = @{
                            IncludeRoles = $updatedRoles
                            }
                    }
                }
                        
                # Update or simulate the policy update
                if ($WhatIf) {Write-Output "[WHAT-IF] Would update policy '$($policy.DisplayName)' to include all administrator roles."}
                else {
                    try {
                        Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id -BodyParameter $updateParams
                        Write-Output "Policy '$($policy.DisplayName)' successfully updated."
                        }
                    catch {
                            Write-Error "Failed to update policy '$($policy.DisplayName)': $_"
                            }
                        }
                }
                else {
                    Write-Output "Policy '$($policy.DisplayName)' already contains all administrator roles."
                    }
                }
            }    
        }
    }

    Write-Output '--------------------------------------------------'
    Write-Output  'Review and update process completed.'
   }

# Execute functions
if ($ExecutionMode -eq 'Interactive'){CheckModules}
CheckAndUpdateCARules
