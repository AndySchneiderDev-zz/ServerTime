describe "Get-NetworkTime" {
  
  It "Returns the proper time against time.windows.com within 200 ms" {
      $time = (Get-NetworkTime -NTPServer time.windows.com).Time
      $now = get-date
      ($time - $now) -lt (New-TimeSpan -Seconds 1)  | Should be True
  }
  
  

  It "Testing Assert" {
    Assert - 1 -eq 2 -failureMessage 'hmmm'
  
  }
}