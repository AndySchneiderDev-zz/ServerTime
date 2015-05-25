Import-Module $PSScriptRoot\ServerTime.psd1 -Force


describe Get-NetworkTime {

  It "Returns the proper time against time.windows.com within 1 sec" {
      $time = (Get-NetworkTime -NTPServer time.windows.com).Time
      $now = get-date
      ($time - $now) -lt (New-TimeSpan -Seconds 1)  | Should be True
  }

}

describe Set-W32TimeServer {

  It "Sets the NTP server using w32tm.exe" {
      $TimeServerValue = 'time.apple.com'
      $Setw32TimeServerOutput = Set-W32TimeServer -TimeServer $TimeServerValue
      $w32tmValue = w32tm.exe /query /source 
      $w32tmValue.trim() -eq $TimeServerValue | Should be True
  
  }

}

describe Get-W32TimeServer {

  It "Gets the current time source using w32tm.exe" {
      $TimeServerValue = 'time.windows.com'
      $Setw32TimeServerOutput = Set-W32TimeServer -TimeServer $TimeServerValue
      $w32tmValue = (w32tm.exe /query /source).trim()
      $GetTimeServerOutput = Get-W32TimeServer 
      $w32tmValue -eq $GetTimeServerOutput | Should be True
  
  }

}

describe Get-TimeServer {

 It "Gets the currently configured time server directly from the registry" {

      $w32tmValue = (w32tm.exe /query /source).trim()
      $GetTimeServerOutput = Get-TimeServer 
      $w32tmValue -eq $GetTimeServerOutput | Should be True
 }

}
