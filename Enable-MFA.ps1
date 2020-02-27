<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.166
	 Created on:   	2/6/2020 1:00 PM
	 Created by:   	Kevin Richard
	 Organization: 	
	 Filename:      Enable-MFA.ps1
	===========================================================================
	.DESCRIPTION
		This script will enable MFA for users in 365 that do not currently have it enabled.
#>

# Requires MSOL Module from PSRepository

<#To generate a password file to automate the 365 login, use this command:

"365password" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "Whatever\File\Path\textdoc.txt"

The txt file can only be read by the  user account that created it, so this script will only work under the user account that created the encrypted text file.

#>
#Generate PSCredential for Office 365
$user = "Put the email address of the admin user"
$file = "Path to secure txt file of admin password"
$Admin = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $file | ConvertTo-SecureString)

#List exempt email accounts from MFA
$exempt = 'comma delimited list of user accounts you do not want to turn MFA on. Can leave blank if there are none'

Connect-MSOLService -credential $Admin

#Create the StrongAuthenticationRequirement object and insert required settings
$mf = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$mf.RelyingParty = "*"
$mfa = @($mf)

#Get all enabled users that are licensed, but do not have MFA turned on, and aren't part of the exemption list
$users = get-msoluser -enabledfilter EnabledOnly -all |
Select-Object DisplayName, IsLicensed, @{ N = 'Email'; E = { $_.UserPrincipalName } }, @{ N = 'StrongAuthenticationRequirements'; E = { ($_ | Select-Object -ExpandProperty StrongAuthenticationRequirements) } } |
Where-Object { $_.islicensed -eq $true -and $_.StrongAuthenticationRequirements -eq $null -and $_.email -notin $exempt }

#Set MFA for all users in the list
foreach ($user in $users)
{
	Set-MsolUser -UserPrincipalName $user.email -StrongAuthenticationRequirements $mfa
}