<#	
	.NOTES
	.DESCRIPTION
		This script is used to check the last write time on a particular file that gets updated regularly for the 724 machines. 
		If this file is unreachable or out of date by an hour, it will notify the 724 admins that something is wrong.
	#>
param(
	[Parameter(Mandatory)]
	[string] $CSVPath = 'C:\temp\724devices.csv',

	[Parameter(Mandatory)]
	[string]$ToAddress,

	[Parameter(Mandatory)]
	[string]$FromAddress,

	[Parameter(Mandatory)]
	[string]$SMTPServer
)

Import-Csv -Path $CSVPath

foreach ($computer in $CSVPath) {
	$date = (Get-Date).AddHours(-1)
	$name = $computer.name
	$path = "\\$name\C$\724Access\724AccessDB\data\ibdata1" 
	$testpath = Test-Path $path
	$target = (Get-ChildItem $path).LastWriteTime
	
	# Check to see if target machine is reachable by using the Test-Path. This will also fail if the file does not exist, but it is more likely the machine isn't reachable
	if ($testpath -eq $false) {
		Send-MailMessage -To $ToAddress `
			-From $FromAddress `
			-Subject "$name failed connectivity check" `
			-Body "$name failed connectivity check. Check if powered on." `
			-SmtpServer $SMTPServer
		
		$computer.status = 'Failed connectivity check. Check if powered on.'
	}
	
	# Check to see if the file write time is more than an hour ago.
	
	elseif ($target -le $date) {
		
		Send-MailMessage -To $ToAddress `
			-From $FromAddress `
			-Subject "$name failed write check" `
			-Body "$name information out of sync. Last write time is $target"`
			-SmtpServer $SMTPServer
		
		$computer.status = "Information out of sync. Last write time is $target"
	}
	
	# If both tests are passed, then the 724 machine is good
	
	else {
		$computer.status = "Success at $(Get-Date)"
	}
}

# Exporting results so they can be manually checked if someone chooses to look.

$CSVPath | Export-Csv 'C:\temp\724status.csv' -NoTypeInformation -Force 
