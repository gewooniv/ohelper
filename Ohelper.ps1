# Ohelper.ps1
# Een eenvoudige tool voor het controleren of inlogpagina's van webapplicaties online zijn
# Compatibel met PowerShell 5.1

param (
    [Parameter(Mandatory=$false)]
    [switch]$help,
    
    [Parameter(Mandatory=$false)]
    [switch]$check,
    
    [Parameter(Mandatory=$false)]
    [switch]$soap,
    
    [Parameter(Mandatory=$false)]
    [switch]$ohw
)

# Certificaatvalidatie omzeilen voor interne servers met zelf-ondertekende certificaten
# WAARSCHUWING: Alleen gebruiken in vertrouwde interne omgevingen
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# TLS 1.2 forceren (meest gebruikte beveiligde protocol)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Functie om hulpinformatie weer te geven
function Show-Help {
    Write-Host "Ohelper - Een eenvoudige statuscontrole voor webapplicaties"
    Write-Host ""
    Write-Host "Gebruik:"
    Write-Host "  .\Ohelper.ps1 -help    : Toon deze hulpinformatie"
    Write-Host "  .\Ohelper.ps1 -check   : Controleer of webapplicaties online zijn"
    Write-Host "  .\Ohelper.ps1 -soap    : Maak SOAP-verzoeken naar webservices"
    Write-Host "  .\Ohelper.ps1 -ohw     : Voer alle controles uit (behalve help)"
    Write-Host ""
}

# Functie om URL's van configuratiebestand te lezen
function Get-WebApplications {
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "ohelper_config.txt"
    
    if (Test-Path $configPath) {
        $webApplications = Get-Content -Path $configPath
        return $webApplications
    } else {
        Write-Host "Configuratiebestand niet gevonden: $configPath" -ForegroundColor Red
        return @()
    }
}

# Functie om te controleren of webapplicaties online zijn
function Check-WebApplications {
    $webApplications = Get-WebApplications
    
    if ($webApplications.Count -eq 0) {
        Write-Host "Geen webapplicatie URL's gevonden om te controleren." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Controleren van webapplicatie status..." -ForegroundColor Yellow
    
    foreach ($url in $webApplications) {
        Write-Host "Controleren: $url" -ForegroundColor Cyan
        
        try {
            # Gebruik Invoke-WebRequest dat beter werkt met de certificaatomzeiling
            $response = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            
            Write-Host "Status: Online (HTTP $($response.StatusCode))" -ForegroundColor Green
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode) {
                # Als we een statuscode hebben, is de site up maar gaf een fout terug
                Write-Host "Status: Online maar gaf HTTP $statusCode terug - $($_.Exception.Message)" -ForegroundColor Yellow
            } else {
                # Geen statuscode betekent dat de verbinding mislukt is
                Write-Host "Status: Offline - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Status: Offline - $_" -ForegroundColor Red
        }
    }
    
    Write-Host "Controle voltooid." -ForegroundColor Yellow
}

# Functie om webservice URL's van configuratiebestand te lezen
function Get-WebServices {
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "webservices.txt"
    
    if (Test-Path $configPath) {
        $webServices = Get-Content -Path $configPath
        return $webServices
    } else {
        Write-Host "Webservices configuratiebestand niet gevonden: $configPath" -ForegroundColor Red
        return @()
    }
}

# Functie om SOAP-verzoeken naar webservices te doen
function Invoke-SoapRequests {
    $webServices = Get-WebServices
    
    if ($webServices.Count -eq 0) {
        Write-Host "Geen webservice URL's gevonden om te controleren." -ForegroundColor Yellow
        return
    }
    
    # Controleer of SOAP XML sjabloon bestaat
    $soapXmlPath = Join-Path -Path $PSScriptRoot -ChildPath "soap.xml"
    
    if (-not (Test-Path $soapXmlPath)) {
        Write-Host "SOAP XML sjabloon niet gevonden: $soapXmlPath" -ForegroundColor Red
        return
    }
    
    # Lees SOAP XML inhoud
    $soapXml = Get-Content -Path $soapXmlPath -Raw
    
    Write-Host "SOAP-verzoeken uitvoeren naar webservices..." -ForegroundColor Yellow
    
    foreach ($url in $webServices) {
        Write-Host "SOAP-verzoek verzenden naar: $url" -ForegroundColor Cyan
        
        try {
            # Gebruik Invoke-WebRequest met XML body in plaats van WebRequest
            $headers = @{
                "Content-Type" = "text/xml; charset=utf-8"
                "SOAPAction" = "http://tempuri.org/GetData"
            }
            
            $response = Invoke-WebRequest -Uri $url -Method Post -Body $soapXml -Headers $headers -UseBasicParsing -TimeoutSec 10
            
            Write-Host "Antwoord (eerste 200 tekens):" -ForegroundColor Green
            Write-Host ($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)) + "...") -ForegroundColor Green
        }
        catch [System.Net.WebException] {
            if ($_.Exception.Response) {
                # Probeer om foutdetails uit de response te halen
                try {
                    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                    $errorResponse = $reader.ReadToEnd()
                    $reader.Close()
                    
                    Write-Host "Fout (Status $([int]$_.Exception.Response.StatusCode)): $errorResponse" -ForegroundColor Red
                }
                catch {
                    Write-Host "Fout (Status $([int]$_.Exception.Response.StatusCode)): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Fout: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Fout: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "SOAP-verzoeken voltooid." -ForegroundColor Yellow
}

if ($help) {
    Show-Help
}
elseif ($ohw) {
    # Voer alle controles uit
    Write-Host "Alle controles uitvoeren..." -ForegroundColor Yellow
    Write-Host "---------------------------" -ForegroundColor Yellow
    Write-Host "Web applicatie controles:" -ForegroundColor Yellow
    Check-WebApplications
    Write-Host "---------------------------" -ForegroundColor Yellow
    Write-Host "SOAP controles:" -ForegroundColor Yellow
    Invoke-SoapRequests
    Write-Host "---------------------------" -ForegroundColor Yellow
    Write-Host "Alle controles voltooid." -ForegroundColor Yellow
}
elseif ($check) {
    # Voer webapplicatie controles uit
    Check-WebApplications
}
elseif ($soap) {
    # Roep functie aan om SOAP-verzoeken te doen
    Invoke-SoapRequests
}
else {
    Write-Host "Geen optie geselecteerd. Gebruik -help om beschikbare opties te zien." -ForegroundColor Yellow
}
