# Define Variablees
$CS = "cs.virtual.lab"
$username = "username"
$password = "password"
$domain = "domain.local"
$ExportPath = "C:\VMW\Apps_ID.csv"

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

# Horizon Login 
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

$body = "{
`n	`"username`": `"$username`",
`n    `"password`": `"$password`",
`n    `"domain`": `"$domain`"
`n}"

# Get a web session variable
$loginuri = "https://" + $CS + "/rest/login"

# Get an access token and refresh token
$response = Invoke-RestMethod $loginuri -Method 'POST' -Headers $headers -Body $body
$access_token = $response.access_token
$refresh_token = $response.refresh_token

# Get Applications Pools
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("accept", "*/*")
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Bearer $access_token")

$loginuri = "https://" + $CS + "/rest/inventory/v1/farms"

# Get Farm ID
$App_Pools = Invoke-RestMethod $loginuri -Method 'GET' -Headers $headers
$Farm_Id = $App_Pools[0].id

# Get Application ID

$loginuri = "https://" + $CS + "/rest/inventory/v1/application-pools"
$App_ID = Invoke-RestMethod $loginuri -Method 'GET' -Headers $headers
$Ammount = $App_ID.Count

# Get Entitlement 
$loginuri = "https://" + $CS + "/rest/entitlements/v1/application-pools"
$Entitle_AppID = Invoke-RestMethod $loginuri -Method 'GET' -Headers $headers

for($n = 0; $n -le ($Ammount-1); $n++){

  $APPNAME = $App_ID[$n].name
  $APPID = $App_ID[$n].id

  New-Object -TypeName PSCustomObject -Property @{
  App_ID = $APPID
  App_Name = $APPNAME
  } | Export-Csv -Path $ExportPath -NoTypeInformation -Append
   
}