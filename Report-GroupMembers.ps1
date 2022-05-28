<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.174
	 Created on:   	11/9/2020 10:49 AM
	 Created by:   	Kevin Richard
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Email a user membership report for an AD Group.
#>

param (
	
	[Parameter(Mandatory = $true)]
	[string[]]$Group,
	
	[Parameter(Mandatory = $true)]
	[ValidatePattern('[\w-]+@\w+.\w+')]
	[string[]]$EmailTo,
	
	[Parameter(Mandatory = $true)]
	[ValidatePattern('[\w-]+@\w+.\w+')]
	[string]$EmailFrom,
	
	[Parameter(Mandatory = $true)]
	[string]$SMTPServer
	
)
$Output = foreach ($Name in $Group) {
	$item = Get-ADGroupMember $Name | Select-Object -ExpandProperty name | Sort-Object
	Write-Output "$name`n==============`n" $item "`n"
}

if ($Output.count -lt 1) {
	Write-Error "No users found for $Group"
}
else {
	
	Send-MailMessage -From $EmailFrom -To $EmailTo -Subject 'User Membership Report' -Body ($Output | Out-String) -SmtpServer $SMTPServer
}
