<#
	.SYNOPSIS
		Adds Read, Write, or Full Access for a user or group to a folder path.

	.DESCRIPTION
		This command will grant access to a folder for a user or group. The information
		can be piped in from a CSV file provided it has a FolderPath, Group, and Access
		heading.

	.PARAMETER  FolderPath
		The UNC or Relative Path to the folder.

	.PARAMETER  Group
		The User or Group to add
	
	.PARAMETER Access
		The Access desired

	.PARAMETER NoInheritance
		Apply settings only to this folder

	.PARAMETER LogFailuresToPath
		UNC path for failed Folderpaths

	.EXAMPLE
		Add-FolderPermission -FolderPath $UNC -Group $Group -Access Read

	.EXAMPLE
		$Import-CSV $FilePathsandGroups | Add-FolderPermission

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

#>

function Add-FolderPermission {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,
			ValueFromPipelineByPropertyName)]
		[String]$FolderPath,
		
		[Parameter(Mandatory,
			ValueFromPipelineByPropertyName)]
		[String]$Group,
		
		[Parameter(Mandatory,
			ValueFromPipelineByPropertyName)]
		[ValidateSet('Read', 'Write', 'Full')]
		[String]$Access,
		
		[switch]$NoInheritance,
		
		[string]$LogFailuresToPath
	)
	
	BEGIN { }
	
	PROCESS {
		
		switch ($Access) {
			'Read' { $Rights = 'ReadandExecute', 'Traverse' }
			'Write' { $Rights = 'ReadandExecute', 'Traverse', 'Write' }
			'Full' { $Rights = 'FullControl' }
		}
		
		if ($PSBoundParameters.ContainsKey('NoInheritance')) {
			$Inheritance = 'None'
			$Propagation = 'InheritOnly'
		}
		else {
			$Inheritance = 'ContainerInherit,ObjectInherit'
			$Propagation = 'None'
		}
		try {
			if (-not (Test-Path $FolderPath)) {
				throw 'Folder path does not exist'
			}
			

			Write-Verbose "Adding $Access for $Group to $FolderPath"
			$ACERule = New-Object System.Security.AccessControl.FileSystemAccessRule($Group, $Rights, $Inheritance, $Propagation, 'Allow')
			$acl = Get-Acl $FolderPath
			$acl.SetAccessRule($ACERule)
			$acl | Set-Acl $FolderPath
			
			$props = @{
				'Group'       = $Group
				'Rights'      = $Rights
				'Inheritance' = $Inheritance
				'Propagation' = $Propagation
			}
			
			$obj = New-Object -TypeName System.Management.Automation.PSObject -Property $props
			
			Write-Output $obj
		} # TRY
		catch {
			if ($PSBoundParameters.ContainsKey('LogFailuresToPath')) {
				Write-Verbose "Logging to $LogFailuresToPath"
				$FolderPath | Out-File -FilePath $LogFailuresToPath -Encoding ascii -Append
			}
			
			else {
				Write-Verbose 'Output Error to console'
				Write-Error $_
			}
		} # CATCH
		
		
	}
	
	END { }
	
	
}