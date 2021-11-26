# Define Variablees
$CS = "cs.virtual.lab"
$username = "username"
$password = "password"
$domain = "domain.local"
$TemplatePath = "C:\VMW\Assign.csv"

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

# Getting data from CSV Template
$Data = Import-Csv $TemplatePath -Delimiter ";"

foreach($line in $Data){
    
    $APPID = $line.Apps_ID
    $AppName = $line.name
    $ID = $line.Group
    $SID = (New-Object System.Security.Principal.NTAccount($Test)).Translate([System.Security.Principal.SecurityIdentifier]).value

    $body = "[ { `"ad_user_or_group_ids`": [ `"$SID`"], `"id`": `"$APPID`" }]"
    
    # Entitle Group into App ID
    $loginuri = "https://" + $CS + "/rest/entitlements/v1/application-pools"
    $Assign_App = Invoke-RestMethod $loginuri -Method 'POST' -Headers $headers -Body $body

    write-host -BackgroundColor DarkGreen "Assigment Done for: "$AppName"" 
}