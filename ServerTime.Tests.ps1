Import-Module $PSScriptRoot\ServerTime.psd1
$timeServers = 'time.windows.com'
Write-Host "Looking at current time source"
w32tm.exe /query /source
Set-TimeServer -TimeServer $timeServers
Set-TimeServerConfiguration -AnnounceFlags ReliableTimeServer
Restart-Service W32Time
w32tm.exe /query /source

describe "Get-NetworkTime" {

  It "Returns the proper time against time.windows.com within 1 sec" {
      $time = (Get-NetworkTime -NTPServer time.windows.com).Time
      $now = get-date
      ($time - $now) -lt (New-TimeSpan -Seconds 1)  | Should be True
  }

}

describe "Get-TimeServer" {

  It "Returns the current time server being used" {
      $w32tmValue = w32tm.exe /query /source 
      $GetTimeServerValue = Get-TimeServer
      $w32tmValue -eq $GetTimeServerValue | Should be True
  
  }

}

