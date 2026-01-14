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

    This script adds synchronization rules for Entra Connect Sync to support attribute based synchronization.


.PARAMETER <Parameter>
    -

.OUTPUTS
    -

.NOTES
    The executing user must have the following permissions:
    - ADSyncAdmins (permission to modify synchronization rules)
    - Read access to Active Directory

    The script is intended to be run on the Entra Connect server.
    On other servers the PowerShell module will be missing and must be manually copied from the Entra Connect server.

    Author:     Benjamin Krah (CrowWithAHat@crowinthe.cloud)
    Date:       2025-08-19
    Change Log: v0.1 - Initial script creation
                v1.0 - Final release


#>

# Import ADSync module
Import-Module 'C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync'

# Define array of possible synchronization attributes
$SyncAttributes = 'info',$Script:SyncAttribute,'extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5',`
'extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','extensionAttribute10','extensionAttribute11',`
'extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','customAttribute1','customAttribute2',`
'customAttribute1','customAttribute3','customAttribute4','customAttribute5','customAttribute6','customAttribute7','customAttribute8',`
,'customAttribute9','customAttribute10','customAttribute11','customAttribute12','customAttribute13','customAttribute14','customAttribute15'

# Choose the sync attribute to be used
$Script:SyncAttribute = $SyncAttributes | Out-GridView -Title 'Please choose the synchronization attribute (MUST EXIST IN ACTIVE DIRECTORY!)' -OutputMode:Single

# Get customer shortcut
$Script:CustomerShortcut = Read-Host 'Provide customer shortcut'

# Get sync attribute value
$Script:SyncValue = Read-Host 'Provide sync value (i.e. cloud, entraid)'

# Get connector identifier
$ADSyncConnectorName = (Get-ADSyncConnector | Where-Object {$_.Name -notlike '*AAD*'}).Name
$Script:ConnectorGUID = (Get-ADSyncConnector -Name $ADSyncConnectorName).Identifier.Guid

# A - FUNCTIONS FOR SYNC RULES
function CreateUserSyncRule
   {
   ## 1 - User objects
   ## Create GUID for new rule
   $UserRuleGUID = [guid]::newguid()

   # Build sync rule
   New-ADSyncRule  `
   -Name "$CustomerShortcut - In from AD - extensionAttribute1 (users)" `
   -Identifier $UserRuleGUID `
   -Description '' `
   -Direction 'Inbound' `
   -Precedence 50 `
   -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
   -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
   -SourceObjectType 'user' `
   -TargetObjectType 'person' `
   -Connector $ConnectorGUID `
   -LinkType 'Provision' `
   -SoftDeleteExpiryInterval 0 `
   -ImmutableTag '' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('False') `
   -Destination 'cloudFiltered' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(IsPresent([isCriticalSystemObject]) || IsPresent([sAMAccountName]) = False || [sAMAccountName] = "SUPPORT_388945a0" || Left([mailNickname], 14) = "SystemMailbox{" || Left([sAMAccountName], 4) = "AAD_" || (Left([mailNickname], 4) = "CAS_" && (InStr([mailNickname], "}") > 0)) || (Left([sAMAccountName], 4) = "CAS_" && (InStr([sAMAccountName], "}") > 0)) || Left([sAMAccountName], 5) = "MSOL_" || CBool(IIF(IsPresent([msExchRecipientTypeDetails]),BitAnd([msExchRecipientTypeDetails],&H21C07000) > 0,NULL)) || CBool(InStr(DNComponent(CRef([dn]),1),"\\0ACNF:")>0), True, False)' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'sourceAnchorBinary' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(IsPresent([mS-DS-ConsistencyGuid]),[mS-DS-ConsistencyGuid],[objectGUID])' `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
   -ArgumentList 'isCriticalSystemObject','TRUE','NOTEQUAL' `
   -OutVariable condition0

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
   -ArgumentList 'adminDescription','User_','NOTSTARTSWITH' `
   -OutVariable condition1

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
   -ArgumentList $Script:SyncAttribute,$Script:SyncValue,'EQUAL' `
   -OutVariable condition2

   Add-ADSyncScopeConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -ScopeConditions @($condition0[0],$condition1[0],$condition2[0]) `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition' `
   -ArgumentList 'mS-DS-ConsistencyGuid','sourceAnchorBinary',$false `
   -OutVariable condition0

   Add-ADSyncJoinConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -JoinConditions @($condition0[0]) `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition' `
   -ArgumentList 'objectGUID','sourceAnchorBinary',$false `
   -OutVariable condition0

   Add-ADSyncJoinConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -JoinConditions @($condition0[0]) `
   -OutVariable syncRule

   Add-ADSyncRule  `
   -SynchronizationRule $syncRule[0]
   }

function CreateGroupSyncRule
   {
   ## 2 - Group objects
   ## Create GUID for new rule
   $GroupRuleGUID = [guid]::newguid()

   # Build sync rule
   New-ADSyncRule  `
   -Name "$Script:CustomerShortcut - In from AD - extensionAttribute1 (groups)" `
   -Identifier $GroupRuleGUID `
   -Description '' `
   -Direction 'Inbound' `
   -Precedence 51 `
   -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
   -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
   -SourceObjectType 'group' `
   -TargetObjectType 'group' `
   -Connector $ConnectorGUID `
   -LinkType 'Provision' `
   -SoftDeleteExpiryInterval 0 `
   -ImmutableTag '' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'cloudFiltered' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(IsPresent([isCriticalSystemObject]) || [sAMAccountName] = "MSOL_AD_Sync_RichCoexistence" || CBool(IIF(IsPresent([msExchRecipientTypeDetails]),BitAnd([msExchRecipientTypeDetails],&H40000000) > 0,NULL))  || CBool(InStr(DNComponent(CRef([dn]),1),"\\0ACNF:")>0), True, False)' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'mailEnabled' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(( (IsPresent([proxyAddresses]) = True) && (Contains([proxyAddresses], "SMTP:") > 0) && (InStr(Item([proxyAddresses], Contains([proxyAddresses], "SMTP:")), "@") > 0)) ||  (IsPresent([mail]) = True && (InStr([mail], "@") > 0)), True, False)' `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
   -ArgumentList 'isCriticalSystemObject','True','NOTEQUAL' `
   -OutVariable condition0

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
   -ArgumentList 'adminDescription','Group_','NOTSTARTSWITH' `
   -OutVariable condition1

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
   -ArgumentList $Script:SyncAttribute,$Script:SyncValue,'EQUAL' `
   -OutVariable condition2

   Add-ADSyncScopeConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -ScopeConditions @($condition0[0],$condition1[0],$condition2[0]) `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition' `
   -ArgumentList 'mS-DS-ConsistencyGuid','sourceAnchorBinary',$false `
   -OutVariable condition0

   Add-ADSyncJoinConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -JoinConditions @($condition0[0]) `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition' `
   -ArgumentList 'objectGUID','sourceAnchorBinary',$false `
   -OutVariable condition0

   Add-ADSyncJoinConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -JoinConditions @($condition0[0]) `
   -OutVariable syncRule

   Add-ADSyncRule  `
   -SynchronizationRule $syncRule[0]
   }

function CreateContactSyncRule
   {
   ## 3 - Contact objects
   ## Create GUID for new rule
   $ContactRuleGUID = [guid]::newguid()

   # Build sync rule
   New-ADSyncRule  `
   -Name "$Script:CustomerShortcut - In from AD - extensionAttribute1 (contacts)" `
   -Identifier $ContactRuleGUID `
   -Description '' `
   -Direction 'Inbound' `
   -Precedence 52 `
   -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
   -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
   -SourceObjectType 'contact' `
   -TargetObjectType 'person' `
   -Connector $ConnectorGUID `
   -LinkType 'Provision' `
   -SoftDeleteExpiryInterval 0 `
   -ImmutableTag '' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'cloudFiltered' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(IsPresent([isCriticalSystemObject]) || ( (InStr([displayName], "(MSOL)") > 0) && (CBool([msExchHideFromAddressLists]))) || (Left([mailNickname], 4) = "CAS_" && (InStr([mailNickname], "}") > 0)) || CBool(InStr(DNComponent(CRef([dn]),1),"\\0ACNF:")>0), True, False)' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'mailEnabled' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(( (IsPresent([proxyAddresses]) = True) && (Contains([proxyAddresses], "SMTP:") > 0) && (InStr(Item([proxyAddresses], Contains([proxyAddresses], "SMTP:")), "@") > 0)) ||  (IsPresent([mail]) = True && (InStr([mail], "@") > 0)), True, False)' `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
   -ArgumentList $Script:SyncAttribute,$Script:SyncValue,'EQUAL' `
   -OutVariable condition0

   Add-ADSyncScopeConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -ScopeConditions @($condition0[0]) `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition' `
   -ArgumentList 'mail','mail',$false `
   -OutVariable condition0

   Add-ADSyncJoinConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -JoinConditions @($condition0[0]) `
   -OutVariable syncRule

   Add-ADSyncRule  `
   -SynchronizationRule $syncRule[0]
   }

function CreateComputerSyncRule
   {
   ## 4 - Computer objects
   ## Create GUID for new rule
   $ComputerRuleGUID = [guid]::newguid()

   # Build sync rule
   New-ADSyncRule  `
   -Name "$Script:CustomerShortcut - In from AD - extensionAttribute1 (computers)" `
   -Identifier $ComputerRuleGUID `
   -Description '' `
   -Direction 'Inbound' `
   -Precedence 53 `
   -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
   -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
   -SourceObjectType 'computer' `
   -TargetObjectType 'device' `
   -Connector $ConnectorGUID `
   -LinkType 'Provision' `
   -SoftDeleteExpiryInterval 0 `
   -ImmutableTag '' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('dn') `
   -Destination 'distinguishedName' `
   -FlowType 'Direct' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'accountEnabled' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(BitAnd([userAccountControl],2)=0,True,False)' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('objectGUID') `
   -Destination 'deviceId' `
   -FlowType 'Direct' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'sourceAnchor' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'ConvertToBase64([objectGUID])' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'displayName' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(IsNullOrEmpty([displayName]),Word([dNSHostName],1,"."),[displayName])' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('objectSid') `
   -Destination 'objectSid' `
   -FlowType 'Direct' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('Computer') `
   -Destination 'sourceObjectType' `
   -FlowType 'Constant' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('operatingSystemVersion') `
   -Destination 'deviceOSVersion' `
   -FlowType 'Direct' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'deviceOSType' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(InStr([operatingSystem],"Windows") > 0,"Windows",[operatingSystem])' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('ServerAd') `
   -Destination 'deviceTrustType' `
   -FlowType 'Constant' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('False') `
   -Destination 'cloudCreated' `
   -FlowType 'Constant' `
   -ValueMergeType 'Update' `
   -ExecuteOnce  `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('userCertificate') `
   -Destination 'userCertificate' `
   -FlowType 'Direct' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('mS-DS-CreatorSID') `
   -Destination 'registeredOwnerReference' `
   -FlowType 'Direct' `
   -ValueMergeType 'Update' `
   -ExecuteOnce  `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Destination 'cloudFiltered' `
   -FlowType 'Expression' `
   -ValueMergeType 'Update' `
   -Expression 'IIF(IsNullOrEmpty([userCertificate]) || ((InStr(UCase([operatingSystem]),"WINDOWS") > 0) && (Left([operatingSystemVersion],2) = "6.")),True,False)' `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
   -ArgumentList $Script:SyncAttribute,$Script:SyncValue,'EQUAL' `
   -OutVariable condition0

   Add-ADSyncScopeConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -ScopeConditions @($condition0[0]) `
   -OutVariable syncRule

   New-Object  `
   -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition' `
   -ArgumentList 'objectGUID','deviceId',$false `
   -OutVariable condition0

   Add-ADSyncJoinConditionGroup  `
   -SynchronizationRule $syncRule[0] `
   -JoinConditions @($condition0[0]) `
   -OutVariable syncRule

   Add-ADSyncRule  `
   -SynchronizationRule $syncRule[0]
   }

# B - FUNCTIONS FOR FILTER RULES
function CreateUserFilterRule
   {
   ## 1 - User objects

   ## Create GUID for new rule
   $UserFilterRuleGUID = [guid]::newguid()

   # Build sync rule
   New-ADSyncRule  `
   -Name "$Script:CustomerShortcut - In from AD - Catchall (users)" `
   -Identifier $UserFilterRuleGUID `
   -Description '' `
   -Direction 'Inbound' `
   -Precedence 90 `
   -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
   -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
   -SourceObjectType 'user' `
   -TargetObjectType 'person' `
   -Connector $ConnectorGUID `
   -LinkType 'Join' `
   -SoftDeleteExpiryInterval 0 `
   -ImmutableTag '' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('True') `
   -Destination 'cloudFiltered' `
   -FlowType 'Constant' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncRule  `
   -SynchronizationRule $syncRule[0]
   }

function CreateGroupFilterRule
   {
   ## 2 - Group objects

   ## Create GUID for new rule
   $GroupFilterRuleGUID = [guid]::newguid()

   # Build sync rule
   New-ADSyncRule  `
   -Name "$Script:CustomerShortcut - In from AD - Catchall (groups)" `
   -Identifier $GroupFilterRuleGUID `
   -Description '' `
   -Direction 'Inbound' `
   -Precedence 91 `
   -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
   -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
   -SourceObjectType 'group' `
   -TargetObjectType 'group' `
   -Connector $ConnectorGUID `
   -LinkType 'Join' `
   -SoftDeleteExpiryInterval 0 `
   -ImmutableTag '' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('True') `
   -Destination 'cloudFiltered' `
   -FlowType 'Constant' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncRule  `
   -SynchronizationRule $syncRule[0]
   }

function CreateContactFilterRule
   {
   ## 3 - Contact objects

   ## Create GUID for new rule
   $ContactFilterRuleGUID = [guid]::newguid()

   # Build sync rule
   New-ADSyncRule  `
   -Name "$Script:CustomerShortcut - In from AD - Catchall (contacts)" `
   -Identifier $ContactFilterRuleGUID `
   -Description '' `
   -Direction 'Inbound' `
   -Precedence 92 `
   -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
   -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
   -SourceObjectType 'contact' `
   -TargetObjectType 'person' `
   -Connector $ConnectorGUID `
   -LinkType 'Join' `
   -SoftDeleteExpiryInterval 0 `
   -ImmutableTag '' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('True') `
   -Destination 'cloudFiltered' `
   -FlowType 'Constant' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncRule  `
   -SynchronizationRule $syncRule[0]
   }

function CreateComputerFilterRule
   {
   ## 4 - Computer objects

   ## Create GUID for new rule
   $ComputerFilterRuleGUID = [guid]::newguid()

   # Build sync rule
   New-ADSyncRule  `
   -Name "$Script:CustomerShortcut - In from AD - Catchall (computers)" `
   -Identifier $ComputerFilterRuleGUID `
   -Description '' `
   -Direction 'Inbound' `
   -Precedence 93 `
   -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
   -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
   -SourceObjectType 'computer' `
   -TargetObjectType 'device' `
   -Connector $ConnectorGUID `
   -LinkType 'Join' `
   -SoftDeleteExpiryInterval 0 `
   -ImmutableTag '' `
   -OutVariable syncRule

   Add-ADSyncAttributeFlowMapping  `
   -SynchronizationRule $syncRule[0] `
   -Source @('True') `
   -Destination 'cloudFiltered' `
   -FlowType 'Constant' `
   -ValueMergeType 'Update' `
   -OutVariable syncRule

   Add-ADSyncRule  `
   -SynchronizationRule $syncRule[0]
   }

# Execute sync rule creation
CreateUserSyncRule
CreateGroupSyncRule
CreateContactSyncRule
CreateComputerSyncRule

# Execute filter rule creation
CreateUserFilterRule
CreateGroupFilterRule
CreateContactFilterRule

CreateComputerFilterRule
