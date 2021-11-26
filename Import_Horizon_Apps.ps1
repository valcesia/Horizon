# Define Variablees
$CS = "cs.virtual.lab"
$username = "username"
$password = "password"
$domain = "domain.local"
$TemplatePath = "C:\VMW\Apps_Template.csv"

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

# Get Farm ID
$App_Pools = Invoke-RestMethod $loginuri -Method 'GET' -Headers $headers
$Farm_Id = $App_Pools[0].id
$Farm_Id

# Getting data from CSV Template
$Data = Import-Csv $TemplatePath -Delimiter ";"

foreach($line in $Data){
    
    # App Variables
    $App_Description = $line.description
    $Display_Name = $line.display_name
    $App_Path = $line.executable_path
    $App_Name = $line.name
    $Param = $line.parameters.Replace('"','')
    $Start_Folder = $line.start_folder

    # Convert to JSON
    $App_jsonPath = ConvertTo-Json $App_Path
    $Start_jsonPath = ConvertTo-Json $Start_Folder
    $Param_json = ConvertTo-Json $Param

    # Create App

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $access_token")
    $headers.Add("Content-Type", "application/json")

    $body = @"
    {
      "category_folder_name": "Virtual Apps",
      "description": "$App_Description",
      "display_name": "$Display_Name",
      "enable_client_restrictions": false,
      "enable_pre_launch": false,
      "enabled": true,
      "executable_path": $App_jsonPath,
      "farm_id": "$Farm_Id",
      "max_multi_sessions": 5,
      "multi_session_mode": "DISABLED",
      "name": "$App_Name",
      "parameters": $Param_json,
      "start_folder": $Start_jsonPath,
      "shortcut_locations": [
        "START_MENU",
        "DESKTOP"
      ]
    }
"@

    $loginuri = "https://" + $CS + "/rest/inventory/v1/application-pools"
    $Create_App = Invoke-RestMethod $loginuri -Method 'POST' -Headers $headers -Body $body
    write-host -BackgroundColor Green "Application Created: "$App_Name 
}