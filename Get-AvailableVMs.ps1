<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.174
	 Created on:   	2/4/2021 2:23 PM
	 Created by:   	Kevin Richard
	 Organization: 	
	 Filename:     	Get-AvailableVMs
	===========================================================================
	.DESCRIPTION
		Gets a count of available VMs for a designated VmWare pool. Alerts if
		count falls below threshold.
	
	TODO:
	Tier our alerting with a WARN/CRITICAL Interval. Base it off of Timing (if email was sent within the last 10 mins, skip).
#>

#Set the Thresholds for available VMs.
$WarnThreshold = 30
$CriticalThreshold = 15

#HV Helper Module is required for this script Located here: https://github.com/vmware/PowerCLI-Example-Scripts/tree/master/Modules/VMware.Hv.Helper
$HelperModulePath = 'C:\Scripts\Modules\VMware.Hv.Helper\VMware.HV.Helper.psd1'
$hvserver = #Horizon View Server
$pool = #Desktop Pool to monitor

$ScriptAdmin = #Email address for admin managing the script
$MailTo = #Email address for who receives the alerts
$MailFrom = #Sending email Address
$SMTPServer = #SMTP Server

$VDIUser = #Vmware admin account
$VDIPass = #UNC to password file
#Pulled from securefile. Needed to authenticate against VDI.'
$VDICred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VDIUser, (Get-Content $VDIPass | ConvertTo-SecureString)

try
{
	Import-Module $HelperModulePath
	Connect-HVServer -Server $hvserver -Credential $credentials
	$VMs = Get-HVMachineSummary -PoolName $pool | Select-Object -ExpandProperty Base | Select-Object -property name, basicstate
}
Catch
{
	$params = @{
		
		From	   = $MailFrom;
		To		   = $ScriptAdmin;
		Subject    = "Crtical: Get-AvailableVMs Script failing to run";
		Body	   = $Error
		SmtpServer = $SMTPServer
		
	} #PARAMS
	Send-MailMessage @params
	
}
$AvailableVMs = ($VMs | Where-Object { $_.basicstate -eq "Available" }).count
if ($AvailableVMs -lt $CriticalThreshold)
{
	$Severity = "Critical"
	$Priority = "High"
}

elseif ($AvailableVMs -lt $WarnThreshold)
{
	$Severity = "Warning"
	$Priority = "Normal"
}

if ($AvailableVMs -lt $WarnThreshold)
{
	$params = @{
		
		From    = $MailFrom;
		To	    = $MailTo;
		Subject = "$Severity : $pool is running low on desktops";
		Body    = "Current available desktop count: $AvailableVMs."
		SmtpServer = $SMTPServer
		Priority = $Priority
		
	} #PARAMS
	Send-MailMessage @params
} #IF