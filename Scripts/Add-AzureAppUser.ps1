	<#
	.SYNOPSIS
		Adds an Azure AD user to an Azure app role
	
	.DESCRIPTION
		This script adds an AD User to the designated Azure Application

	.PARAMETER Username
		The UPN of the Azure AD User

	.PARAMETER Application
		The display name of the Azure Application

	.PARAMETER Role
		The desired role for the user
	#>
	param (
		[Parameter(Mandatory)]
		[string]$Username,
		
		[Parameter(Mandatory)]
		[string]$Application,
		
		[string]$Role = 'msiam_access'
		
	)
	
	$User = Get-AzureADUser -ObjectID "$Username"
	$App = Get-AzureADServicePrincipal -filter "displayname eq '$Application'"
	$AppRoleName = $App.AppRoles | Where-Object { $_.DisplayName -eq $Role}
	
	New-AzureADUserAppRoleAssignment -ObjectID $User.ObjectID -PrincipalId $User.ObjectID -ResourceID $App.ObjectID -Id $AppRoleName.Id
	