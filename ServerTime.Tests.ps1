Import-Module $PSScriptRoot\ServerTime.psd1 -Force

describe Get-NetworkTime {

  It "Returns the proper time against time.windows.com within 1 sec" {
      $time = (Get-NetworkTime -NTPServer time.windows.com).Time
      $now = get-date
      ($time - $now) -lt (New-TimeSpan -Seconds 1)  | Should be True
  }

  It "Has examples in the comment based help" {
    $help = get-help Get-NetworkTime -Examples
    $help.examples |  Should Not BeNullOrEmpty 
  }

}

describe Set-TimeServer {

  It "Sets the NTP server using w32tm.exe" {
      $TimeServerValue = 'time.apple.com'
      $Setw32TimeServerOutput = Set-TimeServer -TimeServer $TimeServerValue  -confirm:$false
      $w32tmValue = w32tm.exe /query /source 
      $w32tmValue.trim() -eq $TimeServerValue | Should be True
  
  }

  It "Has examples in the comment based help" {
    $help = get-help Set-TimeServer -Examples
    $help.examples | Should Not BeNullOrEmpty 
  }

}

describe Get-TimeServer {

  It "Gets the current time source using w32tm.exe" {
      $TimeServerValue = 'time.windows.com'
      $Setw32TimeServerOutput = Set-TimeServer -TimeServer $TimeServerValue -confirm:$false
      $w32tmValue = (w32tm.exe /query /source).trim()
      $GetTimeServerOutput = Get-TimeServer -TimeServer $TimeServerValue
      $w32tmValue -eq $GetTimeServerOutput | Should be True
  }

  It "Has examples in the comment based help" {
    $help = get-help Get-TimeServer -Examples
    $help.examples |  Should Not BeNullOrEmpty 
  }

}
