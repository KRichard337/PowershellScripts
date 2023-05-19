function Get-IpAddressArray {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^(?:\d{1,3}\.){3}\d{1,3}$')]
        [string]$StartIP,

        [ValidatePattern('^(?:\d{1,3}\.){3}\d{1,3}$')]
        [string]$EndIP,

        [int]$NumIPs
    )
    
    $start = [int[]]($StartIP.split('.'))
    $end = [int[]]($EndIP.split('.'))
    
    # Calculate the number of IP addresses between start and end
    if (!($NumIPs)){
    $NumIPs = 0
    for ($i = 0; $i -lt 4; $i++) {
        $NumIPs += ($end[$i] - $start[$i]) * [Math]::Pow(256, (3 - $i))
    }
    } else {
        $NumIPs -= 1
    }
    $ipList = @()
    for ($i = 0; $i -le $NumIPs; $i++){
        $ip = [int[]]$StartIP.split('.')
        $octet = 3
        $ip[$octet] += $i
        while (($ip[$octet] -ge 256)-or ($octet -lt 0)){
            $carryover = [Math]::Floor($ip[$octet] / 256)
            $ip[$octet] %= 256
            $octet -= 1
            $ip[$octet] += $carryover
            }
        $iplist += $ip -join '.'
        }
        Write-Output $ipList

    }


