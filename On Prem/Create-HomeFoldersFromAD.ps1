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


    This script reads all users from a specified OU and creates home folders, if not existing yet.


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The executing user must have the following permissions:
    - Read access to Active Directory (recommended: use gMSA or dMSA)
    - Create subfolders in home directory

    Author:     Benjamin Krah (CrowWithAHat@crowinthe.cloud)
    Date:       2026-05-02
    Change Log: v0.1 - 2026-05-02 - Initial script creation
                v1.0 - 2026-05-02 - Final release


#>

# This function is used to retrieve required input for script
function GetInput
   {
   # Define variables
   $Script:OUPath = '<Please provide OU path in DN format, e.g. OU=Users,DC=MICROWSOFT,DC=DE'
   $Script:SearchMethod = '<Please choose search method by either setting 1 (ADSISearcher) or 2 (AD PowerShell)'  
   $Script:HomeFolderPath = '<Please provide path to root folder for home directories, e.g. D:\HOMES'

   # Configure permissions for users - modify as required or leave default values which add the user with modify permissions
   $Script:FileSystemRight = 'Modify'
   $Script:Propagation = 'None'
   $Script:Inheritance = 'ContainerInherit, ObjectInherit'
   $Sript:RuleType = 'Allow'
   }

# This function is used to retrieve all user accounts from the specified OU
function GetUsersFromAD
   {
   if ($SearchMethod -eq 1)
      {
      # Create new ADSI-based search and set filter to user objects only
      $SearchPath = 'LDAP://' + $OUPath
      $UserSearch = [adsisearcher]::new()
      $UserSearch.SearchRoot = [ADSI]$SearchPath
      $UserSearch.Filter = 'objectClass=user'
      $Script:Users = $UserSearch.FindAll() | % { $_.Properties.samaccountname }
      }
   if ($SearchMethod -eq 2)
      {
      # Check if AD PowerShell is installed and return error, if not
      if ((Get-WindowsFeature RSAT-AD-PowerShell).Installed) -eq 'True')
         {
         # Get users from Active Directory
         $Script:Users = Get-ADUser -SearchBase $OUPath -Filter * | Select-Object sAMAccountName
         } else {
                Write-Host 'ERROR: AD PowerShell not installed! Either set search method to ADSI or install AD PowerShell first' -ForegroundColor Red
                Write-Host 'Command: Install-WindowsFeature RSAT-AD-PowerShell (may require reboot)' -ForegroundColor Yellow
                Write-Host Start-Sleep 5
                Exit
                } 
      }
   }

# This function is used to create home folders which do not exist yet
function CreateMissingHomeFolders
   {
   # Iterate through all users
   ForEach ($User in $Users)
      {
      #Define variable for full folder path
      $FullPath = $HomeFolderPath + '\' + $User

      if (!(Test-Path $FullPath))
         {
         # Output info to console
         Write-Host 'User folder does not exist, will be created...' -ForegroundColor Yellow

         # Create subfolder
         New-Item -Path $HomeFolderPath -Name $User -ItemType Directory

         # Configure permissions
         $ACL = Get-Acl -Path $FullPath
         $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($User,$FileSystemRight,$Inheritance,$Propagation,$RuleType)
         $ACL.SetAccessRule($AccessRule)
         $ACL | Set-Acl -Path $FullPath
         }
      }
   }