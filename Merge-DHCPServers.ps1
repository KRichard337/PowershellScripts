<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.174
	 Created on:   	4/27/2021 9:36 AM
	 Created by:   	Kevin Richard
	 Organization: 	
	 Filename:     	Merge-DHCPServers.ps1
	===========================================================================
	.DESCRIPTION
		Merges DHCP scopes from one server to an existing server with other scopes
		already configured.
#>

param (
	[Parameter(Mandatory = $true)]
	[string]$OldServer,
	
	[Parameter(Mandatory = $true)]
	[string]$NewServer,
	
	[Parameter(Mandatory = $true)]
	[pscredential]$Credential
)

#Checks if Powershell 7 to import DHCP module
if ($PSVersionTable.psversion -like "7.*")
{
	Import-Module DhcpServer -ErrorAction Stop -skipeditioncheck
}

#Establish admin sessions with both DHCP Servers
$OldDHCPCimSession = New-CimSession -Credential $Credential -ComputerName $OldServer
$NewDHCPCimSession = New-CimSession -Credential $Credential -ComputerName $NewServer

#Gather all the scopes in a variable
$Scopes = Get-DhcpServerv4Scope -CimSession $OldDHCPCimSession

#Pipe all the scopes to Add to new DHCP Server
$Scopes | Add-DhcpServerv4Scope -CimSession $NewDHCPCimSession

#Iterate through each scope to grab lease, options, and reservation info and add to new server scope
foreach ($Scope in $Scopes)
{
	Get-DhcpServerv4OptionValue -ScopeId $Scope.ScopeID.IPAddressToString -CimSession $OldDHCPCimSession |
	Set-DhcpServerv4OptionValue -ScopeId $Scope.ScopeID.IPAddressToString -CimSession $NewDHCPCimSession
	
	Get-DhcpServerv4Reservation -ScopeId $Scope.ScopeID.IPAddressToString -CimSession $OldDHCPCimSession |
	Add-DhcpServerv4Reservation -ScopeId $Scope.ScopeID.IPAddressToString -CimSession $NewDHCPCimSession
	
	Get-DhcpServerv4Lease -ScopeId $Scope.ScopeId.IPAddressToString -CimSession $OldDHCPCimSession |
	Where-Object -Property AddressState -EQ 'Active'|
	Add-DhcpServerv4Lease -ScopeId $Scope.ScopeId.IpaddressToString -CimSession $NewDHCPCimSession
	
	$LeasesMoved = Get-DhcpServerv4Lease -ScopeId $Scope.ScopeID.IPAddressToString -CimSession $NewDHCPCimSession
	Write-Output "Migrated $($LeasesMoved.Count) addresses from scope $($Scope.ScopeID.IPaddressToString)"
}
