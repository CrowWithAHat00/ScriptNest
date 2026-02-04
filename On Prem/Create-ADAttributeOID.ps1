
# Define prefix for OID
$Prefix="1.2.840.113556.1.8000.2554" 

# Generate random GUID
$GUID=[System.Guid]::NewGuid().ToString() 

# Create empty variable
$Parts=@() 

# Split GUID into parts with defined size
$Parts+=[UInt64]::Parse($guid.SubString(0,4),"AllowHexSpecifier") 
$Parts+=[UInt64]::Parse($guid.SubString(4,4),"AllowHexSpecifier") 
$Parts+=[UInt64]::Parse($guid.SubString(9,4),"AllowHexSpecifier") 
$Parts+=[UInt64]::Parse($guid.SubString(14,4),"AllowHexSpecifier") 
$Parts+=[UInt64]::Parse($guid.SubString(19,4),"AllowHexSpecifier") 
$Parts+=[UInt64]::Parse($guid.SubString(24,6),"AllowHexSpecifier") 
$Parts+=[UInt64]::Parse($guid.SubString(30,6),"AllowHexSpecifier") 

# Build OID from parts
$OID=[String]::Format("{0}.{1}.{2}.{3}.{4}.{5}.{6}.{7}",$prefix,$Parts[0],$Parts[1],$Parts[2],$Parts[3],$Parts[4],$Parts[5],$Parts[6]) 

# Output OID to console
Clear-Host
Write-Host ''
Write-Host 'New OID: $($IOD)' -ForegroundColor Yellow

# Prevent script from closing
Pause
