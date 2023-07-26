function Get-SSLCertInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$HostName,

        [int]$Port = 443
    )
begin{
   # [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

process{
    foreach ($item in $HostName){
        $Certificate = $null
        $failed = $false
        $TcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
        try {
        $TcpClient.Connect($item, $Port)
        $TcpStream = $TcpClient.GetStream()
        $Callback = { param($sender, $cert, $chain, $errors) return $true }
        $SslStream = New-Object -TypeName System.Net.Security.SslStream -ArgumentList @($TcpStream, $true, $Callback)
        $SslStream.AuthenticateAsClient('')
        $Certificate = $SslStream.RemoteCertificate
        }catch{
            Write-Warning "Unable to retrieve cert for $item"
            $failed = $true
            }finally {
                $SslStream.Dispose()
                $TcpClient.Dispose()
                if ($failed){
                    $output = [PSCustomObject]@{
                    HostName = $item
                    CertStart = $null
                    CertEnd = $null
                    Issuer = $null
                    Subject = $null
                    }
                }else{
                    $output = [PSCustomObject]@{
                    HostName = $item
                    CertStart = $certificate.GetEffectiveDateString()
                    CertEnd = $certificate.GetExpirationDateString()
                    Issuer = ($certificate.GetIssuerName() -split "=")[-1]
                    Subject = $certificate.Subject
                    }
                }
                Write-Output $output
        }
    }
}
}