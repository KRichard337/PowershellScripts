param (
	<#
	.SYNOPSIS
		Builds the module manifest and module file from list of functions
	.DESCRIPTION
		This script will build out the psd & psm files for a folder of scripts/functions. It will publish to either a local repository, local share, or both. The module version can also be edited and reflected in the module manifest.
	.PARAMETER Path
		The path to the module
	.PARAMETER LocalRepo
		The Name of the local Nuget repository.
	.PARAMETER LocalShare
		The UNC path of the local share
	.PARAMETER StepVersion
		What type of version step are the changes
	.PARAMETER RunTests
		Run Pester tests before building the module.
	#>
	[Parameter(Mandatory)]
	[string]$Path,

	[string]$LocalRepo,

	[string]$LocalShare,
	
	[ValidateSet('Major', 'Minor', 'Build', 'Revision')]
	[string]$StepVersion = 'Build',
	
	[switch]$RunTests
)
if ((-not $LocalRepo) -and (-not $LocalShare)) {
	throw 'No LocalRepo or LocalShare has been entered.'
}

#region Establishing Variables
$FunctionPath = $Path + (Split-Path -Path $Path -Leaf)
$FunctionNames = (Get-ChildItem -Path "$FunctionPath\Public" -Filter *.ps1 | Select-Object -ExpandProperty Name).replace('.ps1', '')
$ModuleName = (Split-Path $Path -Leaf)
$TestsPath = $Path + 'Tests'
$ModuleManifestPath = "$FunctionPath\$ModuleName.psd1"
$PubFunctions = Get-ChildItem -Path "$FunctionPath\Public" | Get-Content
$PrivFunctions = Get-ChildItem -Path "$FunctionPath\Private" | Get-Content
#endregion Establishing Variables

if ($RunTests) {
	$TestModule = Invoke-Pester $TestsPath -Show All -PassThru
	if ($TestModule.Failed.Count -gt 0) {
		Throw 'Pester Tests Failed'
	}
}

#region Build psm and psd
$ModuleFunctions = $PubFunctions + $PrivFunctions
$ModuleFunctions | Out-File "$FunctionPath\$ModuleName.psm1" -Force

# Grabbing the Module Manifest
$ModuleManifest = Test-ModuleManifest $ModuleManifestPath

$major = $ModuleManifest.Version.Major
$minor = $ModuleManifest.Version.Minor
$build = $ModuleManifest.Version.Build
$revision = $ModuleManifest.Version.Revision

# Build the new Version based on what type of upgrade.
switch ($StepVersion) {
	Major {
		$major += 1
		$minor = 0
		$build = 0
		$revision = 0
	}
	Minor {
		$minor += 1
		$build = 0
		$revision = 0
	}
	Build {
		$build += 1
		$revision = 0
	}
	Revision {
		$revision += 1
	}
}

$NewVersion = "$major.$minor.$build.$revision"

#endregion Build psm and psd

# Update module manifest with new version and exported functions
Update-ModuleManifest -Path $ModuleManifestPath -ModuleVersion $NewVersion -FunctionsToExport $FunctionNames

if ($LocalRepo) {
	Publish-Module -Path $FunctionPath -Repository $LocalRepo
}

if ($LocalShare) {
	Copy-Item -Path $FunctionPath -Destination $LocalShare -Force -Recurse
}