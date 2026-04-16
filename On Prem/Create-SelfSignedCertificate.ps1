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


    This script can be used to create a self-signed certificate.                                                           


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The executing user must have the following permissions:                                             
    - Local administrator

    Author:     Benjamin Krah (CrowWithAHat@crowinthe.cloud)
    Date:       2026-03-26
    Change Log: v0.1 - 2026-03-26 - Initial script creation
                v1.0 - 2026-03-26 - Final release


#>


# Function to create randomized passwords
function GeneratePassword
   {
   param (
         [int]$length,
         [string]$pattern # optional
         )
 
   # Define scheme
   # Standard: L - Lowercase, U - Uppercase, N - Numeric, S - Special
   $pattern_class = @("L", "U", "N", "S")
 
   # Character pools
   $charpool = @{ 
                "L" = "abcdefghijklmnopqrstuvwxyz";
                "U" = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
                "N" = "1234567890";
                "S" = "!#%&$&/()="
                }
 
   # Define random generation variable
   $rnd = New-Object System.Random
 
   # Random delay for multiple runs
   Start-Sleep -milliseconds $rnd.Next(500) 
 
   # Password creation
   # If password is empty or shorter than minimal length define random password
   if (!$pattern -or $pattern.length -lt $length) 
      {
      if (!$pattern)
         {
         $pattern = ""
         $start = 0
         }
      else {$start = $pattern.length - 1}
 
   # Fill random password until minimal length is reached
      for ($i=$start; $i -lt $length; $i++){$pattern += $pattern_class[$rnd.Next($pattern_class.length)]}
      }
 
   # Create random password
   for ($i=0; $i -lt $length; $i++)
       {   
       $wpool = $charpool[[string]$pattern[$i]]      
       $Password += $wpool[$rnd.Next($wpool.length)]    
       }                
 
   # Return password to variable
   return $Password
   }

# This function is used to get all input for script execution
function GetInput
   {
   # Manual input
   $Script:Lifetime = Read-Host 'Please enter lifetime in years (i.e. 1)'
   $Script:Name = Read-Host 'Please enter certificate name (i.e. EXO-Automation)'
   $Script:EncryptionChoice = Read-Host 'Please choose encryption (1:RSA 2:ECC)'
   $Script:ExportChoice = Read-Host 'Do you need exports? (1:Public 2:Private 3:Both 4:No)'
   $Script:ExecChoice = Read-Host 'Do users need access to the private key? (1:Yes 2:No)'
   $Script:KeyUsage = 'DigitalSignature'

   # Additional choices
   $Purposes = 'Generic','Code Signing'
   $Stores = 'User','Computer'
   $Script:Purpose = $Purposes | Out-GridView -Title 'Please choose certificate purpose' -OutputMode:Single
   $Script:Store = $Stores | Out-GridView -Title 'Please choose certificate store' -OutputMode:Single
   }

# This function configures variables based on user input
function ConfigureVariables
   {
   # Define encryption variables based on choice
   if ($EncryptionChoice -eq 1)
      {
      $KeyLength = '2048'
      $KeyAlgorithm = 'RSA'
      $HashAlgorithm = 'SHA256'
      }
   if ($EncryptionChoice -eq 2)
      {
      $KeyLength = '256'
      $KeyAlgorithm = 'secP256r1'
      $HashAlgorithm = 'SHA256'
      }
   
   # Set global parameters
   if ($Store -eq 'User'){$Script:CertStoreLocation = 'Cert:\CurrentUser\My'}
   if ($Store -eq 'Computer'){$Script:CertStoreLocation = 'Cert:\LocalMachine\My'}
   
   # Build parameters list   
   $Script:Params = @{
      KeyUsage = $KeyUsage
      KeyLength = $KeyLength
      KeyAlgorithm = $KeyAlgorithm
      HashAlgorithm = $HashAlgorithm
      CertStoreLocation = $CertStoreLocation
      NotAfter = ((Get-Date).AddYears($Lifetime))
      DnsName = $Name
      Subject = $Name
      }
   
   # If certificate should be used for code signing, add text extension
   if ($Script:Purpose = 'Code Signing'){$Params['TextExtension'] = @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")}
   
   # If certificate is exported including private key, generate password and output to screen
   if ($Script:ExportChoice -eq 2 -OR $Script:ExportChoice -eq 3)
      {
      # Set password for export
      $Script:PfxPassword = GeneratePassword -Length 20 -pattern LUNS
      $Script:SecurePassword = ConvertTo-SecureString $PfxPassword -AsPlainText -Force

      # Output password to screen
      Write-Host ''
      Write-Host '***********************************************************************************' -ForegroundColor Yellow
      Write-Host 'Please save PFX password to password safe or ignore if you do not need the PFX file' -ForegroundColor Yellow
      Write-Host "Password: $PfxPassword" -ForegroundColor Yellow
      Write-Host '***********************************************************************************' -ForegroundColor Yellow
      Pause
      }
   }

# This function creates the certificate based on the variables
function CreateCertificate
   {
   # Create certificate
   Write-Host ''
   Write-Host "Creating certificate under $CertStoreLocation..." -ForegroundColor Yellow
   $Cert = New-SelfSignedCertificate @Params
   
   #$Cert = New-SelfSignedCertificate -KeyLength $Script:KeyLength -KeyAlgorithm $Script:KeyAlgorithm -NotAfter ((Get-Date).AddYears($Script:Lifetime))`
   # -DnsName $Script:Name -Subject $Script:Usage -CertStoreLocation $Script:CertStoreLocation -HashAlgorithm $Script:HashAlgorithm `
   # -KeyUsage $Script:KeyUsage
   
   # If certificate is used locally, add permissions for accessing the private key
   if ($ExecChoice -eq 1)
      {
      # Define local permission groups for accessing the private key
      if ((Get-Culture).Displayname -like 'English*'){$UserGroup = 'Users'}
      if ((Get-Culture).Displayname -like 'Deutsch*'){$UserGroup = 'Benutzer'}
      
      # Allow users to read the private key
      $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert)
      $fileName = $rsaCert.key.UniqueName
      $path = "$env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$fileName"
      $permissions = Get-Acl -Path $path
      $rule = new-object security.accesscontrol.filesystemaccessrule $UserGroup, 'read', allow
      $permissions.AddAccessRule($rule)
      Set-Acl -Path $path -AclObject $permissions
      }
   
   # If certificate should be used on other systems, export the needed part
   if ($ExportChoice -eq 1 -OR $ExportChoice -eq 2 -OR $ExportChoice -eq 3)
      {
      # Check export path availability
      if (!(Test-Path $env:USERPROFILE\Desktop)){$ExportPath = "$env:USERPROFILE\Downloads"}
      else {$ExportPath = "$env:USERPROFILE\Desktop"}

      # Export certificate
      Write-Host ''
      Write-Host "Exporting certificate(s) to $ExportPath..."
      if ($ExportChoice -eq 1 -OR $ExportChoice -eq 3)
         {
         Export-Certificate -Cert $Cert -FilePath $ExportPath\$Usage.cer
         if (Test-Path "$ExportPath\$Name.cer"){Write-Host 'Public key has successfully been exported!' -ForegroundColor Green}
         else {Write-Host 'Error exporting public key - please check script and export path!' -ForegroundColor Red}
         }
      if ($ExportChoice -eq 2 -OR $ExportChoice -eq 3)
         {
         Export-PfxCertificate -Cert $Cert -FilePath $ExportPath\$Usage.pfx -Password $SecurePassword
         if (Test-Path "$ExportPath\$Name.pfx"){Write-Host 'Private key has successfully been exported!' -ForegroundColor Green}
         else {Write-Host 'Error exporting private key - please check script and export path!' -ForegroundColor Red}
         }
      }
   }

# Execute functions
GetInput
ConfigureVariables
CreateCertificate
