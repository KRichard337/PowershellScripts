<#
	.SYNOPSIS
		Removes Access for a User or Group from a Folder

	.DESCRIPTION
		This command will remove a user or group ACL from a folder.

	.PARAMETER  FolderPath
		The UNC Path to the folder to remove permissions

	.PARAMETER  Groups
		The Users or Groups that need to be removed. Can be an array of users or groups

	.PARAMETER  LogFailuresToPath
		Log Folder Path of Failed Removals

	.EXAMPLE
		Remove-FolderPermission -FolderPath $Path -Groups $IdentityToRemove

	.EXAMPLE
		Import-CSV $FoldersToRemove | Remove-FolderPermission -Groups $IdentityToRemove

	.NOTES
		Additional information about the function go here.

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

#>

function Remove-FolderPermission
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[System.String]$FolderPath,
		
		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromPipeline = $true)]
		[System.String[]]$Group,
		
		[string]$LogFailuresToPath
		
	)
	
	BEGIN { }
	
	PROCESS
	{
		try
		{
			Write-Verbose 'Checking if Folder Path is valid'
			if (-not (Test-Path $FolderPath))
			{
				Write-Error "Folder path does not exist"
			}
			foreach ($Identity in $group)
			{
				Write-Verbose 'Removing $Identity from $FolderPath'
				
				$acl = Get-Acl $FolderPath
				$ACERule = New-Object System.Security.AccessControl.FilesystemAccessRule($Identity,'Read',,,'Allow')
				$acl.RemoveAccessRuleAll($ACERule)
				$acl | Set-Acl $FolderPath
				
				$props = @{
					'Group' = $Identity
					'Path' = $FolderPath
				}
				
				$obj = New-Object -TypeName System.Management.Automation.PSObject -Property $props
				
				Write-Output $obj
			} #FOREACH
			
		} #TRY
		
		catch
		{
			if ($PSBoundParameters.ContainsKey('LogFailuresToPath'))
			{
				Write-Verbose "Logging to $LogFailuresToPath"
				$FolderPath | Out-File -FilePath $LogFailuresToPath -Encoding ascii -Append
			}
			else
			{
				Write-Verbose "Passing error to console"
				Write-Error $_
			}
		} #CATCH
	} #PROCESS
	
	END { }
} #FUNCTION