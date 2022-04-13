# Define Variables
$CS = "cs.virtual.lab"
$username = "username"
$password = "password"
$domain = "domain.local"

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
$headers.Add("Authorization", "Bearer $access_token")

$loginuri = "https://" + $CS + "/rest/inventory/v1/farms"

# Get Application ID

$loginuri = "https://" + $CS + "/rest/inventory/v1/application-pools"
$App_ID = Invoke-RestMethod $loginuri -Method 'GET' -Headers $headers
$Ammount = $App_ID.Count

# Delete App ID

for($n = 0; $n -le ($Ammount-1); $n++){
    
    $loginuri = "https://" + $CS + "/rest/inventory/v1/application-pools/" + $App_ID[$n].id+""
    $Delete_App = Invoke-RestMethod $loginuri -Method 'DELETE' -Headers $headers -Body $body
    write-host -BackgroundColor DarkRed "Application Deleted: "$App_ID[$n].name"" 
}
