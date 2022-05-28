<#	
	.SYNOPSIS
		Creates user folder for each user in an Active Directory OU
	
	.DESCRIPTION
		This script will query AD for a list of users and then check if the folder exists on the share. If not, it will create one with the approriate permissions

	.PARAMETER UserDirectory
		The UNC Path for the User folders

	.PARAMETER UserOU
		The OU for the user accounts

	.Parameter LookBackDays
		The amount of days to look back for when a user was created. This is to prevent a large list of users being returned.
#>

param(
	[Parameter(Mandatory)]
	[string]$UserOU,

	[Parameter(Mandatory)]
	[string]$UserDirectory,

	[int]$LookBackDays = 3650
)

$date = (Get-Date).AddDays(-$LookBackDays)
$Users = get-aduser -filter { (enabled -eq 'true') -and (whencreated -ge $date) } -searchbase $UserOU

foreach ($user in $users) {
	$UserFolderPath = "$UserDirectory\$($User.samaccountname)"

	if ((Test-Path $UserFolderPath ) -eq $false) {
		New-Item -Name $user.samaccountname -ItemType 'Directory' -Path $UserDirectory
		$ACLGroup = $user.samaccountname
		$Rights = 'FullControl'
		$Inheritance = 'ContainerInherit,ObjectInherit'
		$Propagation = 'None'
		$ACERule = New-Object System.Security.AccessControl.FileSystemAccessRule($ACLGroup, $Rights, $Inheritance, $Propagation, 'Allow')
		$acl = Get-Acl $UserFolderPath
		$acl.SetAccessRule($ACERule)
		$acl | Set-Acl $UserFolderPath
	}
}