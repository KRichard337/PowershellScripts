<#	
.SYNOPSIS
	Builds a Department folder for each User Group in an OU

.DESCRIPTION
	This script will check Active Directory for a list of groups, then check a share path to see if the folder exists. If not, it will create one.

.PARAMETER Searchbase
	The OU Path to search for AD Groups

.PARAMETER DeptFolderPath
	The UNC Share path for the Department folders.


#>

params(
	[Parameter(Mandatory)]
	[string]$DeptOU,

	[Parameter(Mandatory)]
	[string]$DeptFolderPath
)
$ADGroups = Get-ADGroup -filter * -searchbase $DeptOU

foreach ($Group in $ADGroups) {
	if ((Test-Path "$DeptFolderPath\$($group.name)") -eq $false) {
		New-Item -Name $group.name -Path $DeptFolderPath -ItemType 'Directory'
		
		$FolderPath = "$DeptFolderPath\$($Group.name)"
		$ACLGroup = $Group.name
		$Rights = 'ReadandExecute', 'Traverse', 'Write'
		$Inheritance = 'ContainerInherit,ObjectInherit'
		$Propagation = 'None'
		$ACERule = New-Object System.Security.AccessControl.FileSystemAccessRule($ACLGroup, $Rights, $Inheritance, $Propagation, 'Allow')
		$acl = Get-Acl $FolderPath
		$acl.SetAccessRule($ACERule)
		
		$acl | Set-Acl $FolderPath
		
		$NewFolders += "$($Group.name)`n"
	}
	
}
Write-Output $NewFolders



