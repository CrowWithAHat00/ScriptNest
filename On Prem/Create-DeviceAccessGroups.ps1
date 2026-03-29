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

    This script can be used to create access groups in Active Directory for clients and servers to support the Just Enough Administration model.


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The script is intended to be run as startup script in GPO.
    It is therefore executed in the SYSTEM context of the computer account.

    There a are several ways to provide the computer accounts with the needed permissions in Active Directory:
    1) Use the default group "Domain Computers"
    2) Use a custom group and let another script run regularly to add new computer accounts to this group

    The computer accounts need the following permissions for the OU(s) where the groups should be created in:
    - Create and manage groups
    - Read

    If the PowerShell script execution policy is set to a restrictive value, the script must be digitally signed.

    Author:     Benjamin Krah (CrowWithAHat@crowinthe.cloud)
    Date:       2026-03-29
    Change Log: v0.1 - 2026-03-12 - Initial script creation
                v1.0 - 2026-03-12 - Final release
                v1.1 - 2026-03-29 - Modified script to make it language-independent


#>

# This function is used to gather input needed for script execution
function GetInput
   {
   # EXAMPLE VALUES - MODIFY TO YOUR NEEDS
   $Script:ClientOUPath = 'OU=Workstations,OU=Roles,OU=Groups,OU=ADMINISTRATION,' 
   $Script:ServerOUPath = 'OU=Server,OU=Roles,OU=Groups,OU=ADMINISTRATION,' 
   $Script:AdminsGroup = 'ROL-SEC-' + $ENV:ComputerName + '-Admins'
   $Script:AdminsDesc = 'Members of this group are assigned administrative permissions for the given system'
   $Script:LocalAdmGroup = 'Administrators'
   $Script:RDUsersGroup = 'ROL-SEC-' + $ENV:computername + '-RD-Benutzer'
   $Script:RDUsersDesc= 'Members of this group are allowed to login to the given system via RDP'
   $Script:LocalRDGroup = 'Remote Desktop Users'

   # Summarize groups - add groups as needed
   $GroupNames = $AdminsGroup,$RDUsersGroup
   $GroupDescriptions = $AdminsDesc,$RDUsersDesc
   $LocalGroups = $LocalAdmGroup,$LocalRDGroup

   # Build table from variables
   $Script:AccessGroups = For ($i = 0;$i -lt $GroupNames.Count;$i++)
      {
       [PSCustomObject]@{
        GroupName = $GroupNames[$i]
        Description = $GroupDescriptions[$i]
        LocalGroup = $LocalGroups[$i]
        } 
      }
   }
   
### DO NOT MODIFY ANYTHING BEYOND THIS LINE ###

# Function to dynamically retrieve Active Directory values without AD PowerShell module
Function GetADInfo # Credits to http://www.yusufozturk.info/windows-server/getting-active-directory-information-with-powershell.html
   {
   $ADDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
   $ADDomainName = $ADDomain.Name
   $Netbios = $ADDomain.Name.Replace('.','')
   $ADServer = ($ADDomain.InfrastructureRoleOwner.Name.Split(".")[0])
   $FQDN = "DC=" + $ADDomain.Name -Replace("\.",",DC=")
 
   $Results = New-Object Psobject
   $Results | Add-Member Noteproperty Domain $ADDomainName
   $Results | Add-Member Noteproperty FQDN $FQDN
   $Results | Add-Member Noteproperty Server $ADServer
   $Results | Add-Member Noteproperty Netbios $Netbios
   Write-Output $Results
   }

# Function to build all necessary variables and get values
function DefineVariables
   {
   # Define global variables
   $Script:DomainNetBios = (GetADInfo).NetBios
   $Script:DomainFQDN = (GetADInfo).FQDN
 
   # Determine system type (1: client 2:server)
   $Script:Caption = (Get-WmiObject -class Win32_OperatingSystem | Select-Object Caption).Caption
   if ($Script:Caption -notlike '*Windows Server*'){$Script:Systemtype = 1}
   if ($Script:Caption -like '*Windows Server*'){$Script:Systemtype = 2}

   # Declare variables manually
   $Script:ClientOU = 'LDAP://' + $Script:ClientOUPath + $Script:DomainFQDN
   $Script:ClientTargetOU = [ADSI]$Script:ClientOU
   $Script:ServerOU = 'LDAP://' + $Script:ServerOUPath + $Script:DomainFQDN
   $Script:ServerTargetOU = [ADSI]$Script:ServerOU
   if ($Script:Systemtype -eq 1){$Script:TargetOU = $Script:ClientTargetOU}
   if ($Script:Systemtype -eq 2){$Script:TargetOU = $Script:ServerTargetOU}

   # Declare group types
   $Script:GroupType = @{
      Global      = 0x00000002
      DomainLocal = 0x00000004
      Universal   = 0x00000008
      Security    = 0x80000000
      }
   }

# Function to create groups in Active Directory
function CreateGroups
   {
   # Check existing groups and create if not existing
   ForEach ($AccessGroup in $Script:AccessGroups)
      {
      $searcher = [ADSISearcher] "(sAMAccountName=$Group)"
      if ( -not $searcher.FindOne() ) 
         {
         $NewGroup = $TargetOU.Create('group', $('cn=' + $GroupName))
         $NewGroup.put('grouptype',($GroupType.DomainLocal -bor $GroupType.Security))
         $NewGroup.put('samaccountname',$GroupName)
         $NewGroup.put('description', $Description)
         $NewGroup.SetInfo()
         }
      }
   }

# OPTIONAL - Directly nest newly created groups and do not wait for next group policy refresh
<#
function NestGroups
   {
   ForEach ($AccessGroup in $Script:AccessGroups)
      {
      # Add AD groups to local groups if not nested yet
      $AccountName = $Script:DomainNetBios + '\' + $Script:GroupName
      $LocalGroup = Get-LocalGroupMember $LocalGroup | Where-Object { $_.Objectclass -eq 'Group' } | Select-Object Name -ExpandProperty Name
      if ($LocalGroup -notcontains $AccountName){Add-LocalGroupMember -Group $LocalGroup -Member $AccountName}
      }
   }
#>

# Execute functions
GetInput
GetADInfo
DefineVariables
CreateGroups
#NestGroups - Remove hash and un-comment function if groups should be nested directly
