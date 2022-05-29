<#	
	.DESCRIPTION
		This script will remove files based on How old and the file type. 
#>
param (
	[Parameter(Mandatory)]
	[int]$OlderThanDays = 90,

	[Parameter(Mandatory)]
	[string]$Path,
	
	[string]$FileType = '.*'
)

$TargetDate = (Get-Date).AddDays(-$OlderThanDays)
$FilesToDelete = Get-ChildItem -Path $Path | Where-Object -FilterScript { $_.CreationTime -le $TargetDate -and $_.Extension -like $FileType }
$FilesToDelete | Remove-Item -Confirm:$false