function Get-ActiveHost {
    <#
        .SYNOPSIS
        Tests the connectivity of a list of IP addresses.

        .DESCRIPTION
        This function tests the connectivity of a list of IP addresses using the ICMP protocol (ping). The function 
        takes a list of IP addresses and pings each IP address and returns an array of IPs that were successful.

        .PARAMETER IPAddress
        Specifies the IP address to use for the ping tests. The IP address should be specified as an IP address in dotted-quad notation (e.g., 192.168.1.0).

        .EXAMPLE
        Get-ActiveHost -IPAddress $IPList
        Tests connectivity to IP addresses in the $IPList array.

        .EXAMPLE
        Get-ActiveHost -IPAddress '8.8.8.8','1.1.1.1'
        Tests connectivity to IP addresses 8.8.8.8 and 1.1.1.1.

        .NOTES
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]] $IPAddress
    )
    $Results = $IPAddress | ForEach-Object {
        [System.Net.NetworkInformation.Ping]::new().SendPingAsync($_)
    }

    [Threading.Tasks.Task]::WaitAll($Results)

    $activeEndpoints = ($Results | Where-Object {$_.Result.Status -eq "Success"})

    Write-Output ($activeEndpoints.result | Select-Object -ExpandProperty Address).IPAddressToString
}
