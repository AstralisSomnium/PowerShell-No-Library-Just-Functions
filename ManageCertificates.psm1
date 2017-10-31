# Remove-Certificate -Certificate $myCertificate -Verbose
function Remove-Certificate {
[CmdletBinding()]
    param(
        [System.Security.Cryptography.X509Certificates.X509Certificate]$certificate
    )
    if(-not (Test-Path -Path $certificate.PSPath)) {
        throw "Certificate does not exist $certificate"
    }
    $certLocation = Get-CertificateLocation -Certificate $certificate
    $store = New-Object System.Security.Cryptography.X509certificates.X509Store($certLocation.StoreName, $certLocation.StoreLocation)
    try {
        $store.Open('ReadWrite')
        Write-Verbose -Message "Removing $certificate"
        $store.Remove($certificate)
    } catch {
        Write-Verbose -Message "Failed to remove $($certificate.GetName()): $_"
    } finally {
        $store.close() 
    }
}

# Get-CertificateLocation -Certificate $myCertificate
function Get-CertificateLocation {
    param(
        [System.Security.Cryptography.X509Certificates.X509Certificate]$certificate
    )
    $segments = $certificate.PSParentPath -split "\\"
    return New-Object -TypeName PSObject -Property @{
        "StoreName" = ([System.Enum]::Parse([System.Security.Cryptography.X509Certificates.StoreName], $segments[2], $true))
        "StoreLocation" = [System.Security.Cryptography.X509Certificates.StoreLocation]($segments[1] -replace "Certificate::", "")
    }    
}