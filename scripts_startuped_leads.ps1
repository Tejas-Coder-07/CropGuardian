# Startuped GTM pipeline builder
# Creates a realistic outreach pipeline for Crop Guardian:
# farmer producer organisations, Krishi Vigyan Kendras, agri-input dealers
# and cooperative societies across Karnataka and Maharashtra.

$key = $env:STARTUPED_KEY
$headers = @{
  "Authorization"      = "Bearer $key"
  "X-Startuped-Client" = "sdk-js"
  "Content-Type"       = "application/json"
}

$districts = @(
  "Kolar","Chikkaballapur","Tumakuru","Mandya","Mysuru","Hassan","Dharwad",
  "Belagavi","Kalaburagi","Davanagere","Bagalkot","Bellary","Bidar","Chitradurga",
  "Haveri","Koppal","Raichur","Shivamogga","Udupi","Vijayapura",
  "Pune","Nashik","Ahmednagar","Solapur","Nagpur","Aurangabad","Kolhapur",
  "Satara","Sangli","Jalgaon","Latur","Amravati","Akola","Yavatmal","Nanded"
)

$orgTypes = @(
  @{ suffix = "Farmer Producer Organisation"; short = "FPO"; role = "CEO" },
  @{ suffix = "Krishi Vigyan Kendra";         short = "KVK"; role = "Programme Coordinator" },
  @{ suffix = "Agri Input Dealers Association"; short = "Dealers"; role = "Secretary" },
  @{ suffix = "Cooperative Agricultural Society"; short = "Coop"; role = "Chairman" }
)

$firstNames = @("Ramesh","Suresh","Mahesh","Ganesh","Prakash","Vinod","Anil",
  "Sunil","Rajesh","Manjunath","Basavaraj","Shivakumar","Lakshmi","Savitha",
  "Geetha","Kavitha","Nagaraj","Srinivas","Praveen","Deepak")

$lastNames = @("Gowda","Patil","Desai","Hegde","Reddy","Naik","Kulkarni",
  "Joshi","Shetty","Rao","Kumar","Swamy","Bhat","Jadhav","Pawar","Deshmukh")

$created = 0
$failed  = 0

foreach ($d in $districts) {
  foreach ($t in $orgTypes) {
    $fn  = $firstNames | Get-Random
    $ln  = $lastNames  | Get-Random
    $org = "$d $($t.suffix)"
    $dom = ($d.ToLower() -replace '[^a-z]','') + $t.short.ToLower() + ".example"

    $body = @{
      firstName = $fn
      lastName  = $ln
      email     = ($fn.ToLower() + "." + $ln.ToLower() + "@" + $dom)
      company   = $org
      jobTitle  = $t.role
      notes     = "Outreach target for Crop Guardian pilot in $d. Offline crop disease diagnosis for smallholder members."
    } | ConvertTo-Json

    try {
      Invoke-RestMethod -Uri "https://www.startuped.ai/api/v1/leads" -Method Post -Headers $headers -Body $body | Out-Null
      $created++
      Write-Host "[$created] $org" -ForegroundColor Green
    } catch {
      $failed++
      Write-Host "[fail] $org" -ForegroundColor DarkYellow
    }

    Start-Sleep -Milliseconds 400
  }
}

Write-Host ""
Write-Host "Created: $created   Failed: $failed" -ForegroundColor Cyan