<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.174
	 Created on:   	4/12/2021 8:17 AM
	 Created by:   	Kevin Richard
	 Organization: 	
	 Filename:     	Remove-StaleDHCPLeases
	===========================================================================
	.DESCRIPTION
		Pings a scope and removes the IP Lease if there is no reply. This script assumes you can ping all endpoints
		in the scope.
#>


param (
	
	[string]$DHCPServer,
	
	[pscredential]$Credential,
	
	[string]$Scope,
	
	[switch]$DisplayStaleLeases
)

#Splatting parameters for Test-Connection
$TestConnectionParams = @{
	Quiet = $true
	Count = 1
}

#Checks if Powershell 7 to import dhcp module and add extra functions specific to PS7 version of Test-Connection
if ($PSVersionTable.psversion -like "7.*"){
	Import-Module DhcpServer -ErrorAction Stop -skipeditioncheck
	$TestConnectionParams.TimeoutSeconds = 1
}

$DHCPCimSession = New-CimSession -Credential $Credential -ComputerName $DHCPServer

$Leases = Get-DhcpServerv4Lease -Cimsession $DHCPCimSession -ScopeId $Scope

$StaleLeases = @()

$Count = 1
foreach ($Lease in $Leases)
{
	$Count ++ 
	Write-Progress -Activity 'Deleting Stale Leases' -PercentComplete ($Count/$Leases.Count * 100)
	$Connected = Test-Connection -ComputerName $Lease.ipaddress @TestConnectionParams
	
	if ($Connected -eq $false)
	{
		$StaleLeases += $Lease
		Remove-DhcpServerv4Lease -CimSession $DHCPCimSession -IPAddress $Lease.ipaddress
	}
} #FOREACH 
Write-Output "Removed $($StaleLeases.count)"

if ($DisplayStaleLeases)
{
	$StaleLeases | Out-GridView
}