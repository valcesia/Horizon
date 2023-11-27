 <#
.SYNOPSIS
Script to get License Information from VMware Horizon Connection Servers - Version 2303 or higher
	
.NOTES
  Version:        1.0
  Author:         Thiago Valcesia - tvalcesia@vmware.com
                  
  Creation Date:  11/27/2023
      
  Purpose/Change: Developed to help a customer to validate information
                  

  This script used VMware Horizon Server API 2303 or higher - https://developer.vmware.com/apis/1574/
  
 #>

# Declarations
# Avoid Invalid Certificate
add-type @"
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
# For Windows Server 2012 Security Protocol 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# End of Declarations

Function HorizonLogin {

# Define Variables
$script:CS = Read-Host -Prompt 'Enter Connection Server FQDN'
$username = Read-Host -Prompt 'Enter the Username'
$password = Read-Host -Prompt 'Enter the Password' -AsSecureString
$domain = Read-Host -Prompt 'Enter Domain (FQDN)'

#Secure Password

$BinStr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BinStr)

# Horizon Login 
$hvServer = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$hvServer.Add("Content-Type", "application/json")

$body = "{
`n	`"username`": `"$username`",
`n    `"password`": `"$UnsecurePassword`",
`n    `"domain`": `"$domain`"
`n}"

# Get a web session variable
$loginuri = "https://" + $CS + "/rest/login"

# Get an access token and refresh token
$script:response = Invoke-RestMethod $loginuri -Method 'POST' -Headers $hvServer -Body $body
$script:access_token = $response.access_token
$script:refresh_token = $response.refresh_token

}

#Execute Function

HorizonLogin

Function Get-License{

# Get License Usage Metrics
$hvServer = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$hvServer.Add("Authorization", "Bearer $access_token")

$loginuri = "https://" + $CS + "/rest/monitor/v1/licenses/usage-metrics"

# Get License
$Get_License = Invoke-RestMethod $loginuri -Method 'GET' -Headers $hvServer

ConvertTo-Json $Get_License
}

#Execute Get-License function

Get-License 