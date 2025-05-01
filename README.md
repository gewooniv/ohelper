# Ohelper

A simple PowerShell tool for checking if web applications and services are online. Designed for internal environments with self-signed certificates.

## Overview

Ohelper is a lightweight PowerShell tool that can:
- Check if web application login pages are online
- Make SOAP requests to web services
- Handle internal servers with self-signed certificates

Compatible with PowerShell 5.1 and can be run from PowerShell ISE.

## Requirements

- PowerShell 5.1 or higher
- Three configuration files (described below)

## Installation

1. Clone or download this repository
2. Create the required configuration files in the same directory as the script
3. Run the script from PowerShell ISE or command line

## Configuration Files

### ohelper_config.txt
Contains a list of web application URLs to check (one per line):
```
https://example.com/login
https://test.com/login
192.168.1.100/app/login
```

### webservices.txt
Contains a list of web service URLs for SOAP requests (one per line):
```
http://example.com/service1
http://test.com/service2
http://192.168.1.100/api/service
```

### soap.xml
Contains the SOAP XML template to send to each web service:
```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <GetData xmlns="http://tempuri.org/">
      <value>123</value>
    </GetData>
  </soap:Body>
</soap:Envelope>
```

## Usage

### View Help Information
```powershell
.\Ohelper.ps1 -help
```

### Check Web Applications
Checks if web applications listed in `ohelper_config.txt` are online:
```powershell
.\Ohelper.ps1 -check
```

### Make SOAP Requests
Sends SOAP requests to web services listed in `webservices.txt`:
```powershell
.\Ohelper.ps1 -soap
```

### Run All Checks
Executes both web application checks and SOAP requests:
```powershell
.\Ohelper.ps1 -ohw
```

## Security Note

This tool is designed for internal environments with self-signed certificates. It bypasses certificate validation, which is appropriate for internal testing but should not be used for public-facing services.

## Adding New Commands

The parameter-based structure makes it easy to add more commands:

1. Add a new switch parameter at the top of the script
2. Create a function that implements the command functionality
3. Add a condition in the main logic section that calls your function

## License

[MIT License](LICENSE)
