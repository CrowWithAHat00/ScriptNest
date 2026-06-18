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


    This script adds connectors in Exchange Online to allow secure mail flow to and from ForcePoint.
    The necessary IP ranges can be retrieved from the ForcePoint Admin Portal under "Email > Settings > DNS Records & Service IPs"


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The executing user must have the following permissions:                                             
    - Management role 'Mail Flow' or higher

    Author:     Benjamin Krah (CrowWithAHat@crowinthe.cloud)
    Date:       2026-06-18
    Change Log: v0.1 - 2026-06-18 - Initial script creation
                v1.0 - 2026-06-18 - Final release


#>


# Define variables
$ForcePointIPRanges = '85.115.32.0/24','85.115.33.0/24','85.115.34.0/24','85.115.35.0/24','85.115.36.0/24','85.115.37.0/24','85.115.38.0/24',`
 '85.115.39.0/24','85.115.40.0/24','85.115.41.0/24','85.115.42.0/24','85.115.43.0/24','85.115.44.0/24','85.115.45.0/24','85.115.46.0/24','85.115.47.0/24',`
 '85.115.48.0/24','85.115.49.0/24','85.115.50.0/24','85.115.51.0/24','85.115.52.0/24','85.115.53.0/24','85.115.54.0/24','85.115.55.0/24','85.115.56.0/24',`
 '85.115.57.0/24','85.115.58.0/24','85.115.59.0/24','85.115.60.0/24','85.115.61.0/24','85.115.62.0/24','85.115.63.0/24','86.111.216.0/24','86.111.217.0/24',`
 '116.50.56.0/24','116.50.57.0/24','116.50.58.0/24','116.50.59.0/24','116.50.60.0/24','116.50.61.0/24','116.50.62.0/24','116.50.63.0/24','208.87.232.0/24',`
 '208.87.233.0/24','208.87.234.0/24','208.87.235.0/24','208.87.236.0/24','208.87.237.0/24','208.87.238.0/24','208.87.239.0/24','86.111.220.0/24',`
 '86.111.221.0/24','86.111.222.0/24','86.111.223.0/24','103.1.196.0/24','103.1.197.0/24','103.1.198.0/24','103.1.199.0/24','177.39.96.0/24','177.39.97.0/24',`
 '177.39.98.0/24','177.39.99.0/24','196.216.238.0/24','196.216.239.0/24'
 $InboundConnectorName = 'CON-PTN-EXO-Allow inbound mails from ForcePoint'
 $OutboundConnectorName = 'CON-EXO-PTN-Route outbound mails via ForcePoint'
 $SmartHosts = 'cust5390-s.out.mailcontrol.com'

# Create inbound connector
Write-Host "Creating inbound connector $InboundConnectorName..." -ForegroundColor Yellow
New-InboundConnector -Name $InboundConnectorName -Enabled $True -ConnectorType 'Partner' -SenderIPAddresses $ForcePointIPRanges -SenderDomains '*' -RequireTls $True -RestrictDomainsToIPAddresses $True

# Check if inbound connector has been created successfully
if (Get-InboundConnector -Identity $InboundConnectorName)
   {
   Write-Host "SUCCESS: Inbound connector $InboundConnectorName created!" -ForegroundColor Green
   } else {Write-Host "ERROR: Inbound connector $InboundConnectorName could not be created!" -ForegroundColor Red}

# Create outbound connector
New-OutboundConnector -Name $OutboundConnectorName -Enabled $True -ConnectorType 'Partner' -SmartHosts $SmartHosts -RequireTls $True -TlsSettings CertificateValidation

# Check if outbound connector has been created successfully
if (Get-OutboundConnector -Identity $OutboundConnectorName)
   {
   Write-Host "SUCCESS: Outbound connector $OutboundConnectorName created!" -ForegroundColor Green
   } else {Write-Host "ERROR: Outbound connector $OutboundConnectorName could not be created!" -ForegroundColor Red}
