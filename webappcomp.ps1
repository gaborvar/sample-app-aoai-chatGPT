# Function to compare app settings between two web apps
param (
    [string]$WebApp1 = "jogimuki-teszt2",        # Default web app 1 name
    [string]$WebApp2 = "0a906ffd-32a5-505d-b623-b1451380ad2b",  # Default web app 2 name (previously "csakteszt")
    [string]$ResourceGroup = "rg-gaborvarai"      # Default resource group
)

# Helper function to truncate long strings
function Truncate {
    param (
        [string]$Text,
        [int]$MaxLength = 40
    )
    if ($Text.Length -gt $MaxLength) {
        return $Text.Substring(0, $MaxLength) + "..."
    } else {
        return $Text
    }
}

# Step 1: Get App Settings from the first web app
$webapp1_settings = az webapp config appsettings list --name $WebApp1 --resource-group $ResourceGroup | ConvertFrom-Json

# Step 2: Get App Settings from the second web app
$webapp2_settings = az webapp config appsettings list --name $WebApp2 --resource-group $ResourceGroup | ConvertFrom-Json

# Step 3: Convert the settings into hash tables for easy comparison
$webapp1_dict = @{}
$webapp2_dict = @{}

foreach ($setting in $webapp1_settings) {
    $webapp1_dict[$setting.name] = $setting.value
}

foreach ($setting in $webapp2_settings) {
    $webapp2_dict[$setting.name] = $setting.value
}

# Step 4: Compare the two sets of settings
$diff_settings = @()
$missing_in_webapp1 = @()
$missing_in_webapp2 = @()

# Find settings that are different or only present in one web app
foreach ($key in $webapp1_dict.Keys) {
    if ($webapp2_dict.ContainsKey($key)) {
        if ($webapp1_dict[$key] -ne $webapp2_dict[$key]) {
            $diff_settings += [PSCustomObject]@{
                Setting = $key
                $WebApp1 = Truncate $webapp1_dict[$key] 40
                $WebApp2 = Truncate $webapp2_dict[$key] 40
            }
        }
    } else {
        $missing_in_webapp2 += [PSCustomObject]@{
            Setting = $key
            Value = Truncate $webapp1_dict[$key] 40
        }
    }
}

foreach ($key in $webapp2_dict.Keys) {
    if (-not $webapp1_dict.ContainsKey($key)) {
        $missing_in_webapp1 += [PSCustomObject]@{
            Setting = $key
            Value = Truncate $webapp2_dict[$key] 40
        }
    }
}

# Step 5: Output the differences in a table format with 3 columns (truncated values)
if ($diff_settings.Count -gt 0) {
    Write-Host "`n=== Differences in setting values ==="
    $diff_settings | Format-Table -Property "Setting", $WebApp1, $WebApp2 -AutoSize
} else {
    Write-Host "No differences in setting values."
}

# Step 6: Output the sorted missing settings with their values
if ($missing_in_webapp2.Count -gt 0) {
    Write-Host "`n=== Settings present in $WebApp1 but not in $WebApp2 ==="
    $missing_in_webapp2 | Sort-Object Setting | Format-Table -Property "Setting", "Value" -AutoSize
} else {
    Write-Host "No settings missing in $WebApp2."
}

if ($missing_in_webapp1.Count -gt 0) {
    Write-Host "`n=== Settings present in $WebApp2 but not in $WebApp1 ==="
    $missing_in_webapp1 | Sort-Object Setting | Format-Table -Property "Setting", "Value" -AutoSize
} else {
    Write-Host "No settings missing in $WebApp1."
}
