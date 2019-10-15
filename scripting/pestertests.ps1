param(

  [Parameter(Mandatory)]

  [ValidateNotNullOrEmpty()]

  [string]$port
  )

  

  describe "website is running" {

  it  "website is online" {
    $req = Invoke-WebRequest -Uri "http://localhost:$port/weatherforecast" -UseDefaultCredentials
    $data = $req.Content |ConvertFrom-Json
    $data.Length |Should be 5  
  }
}