describe "Get-NetworkTime" {
  
  It "Returns the proper time against time.windows.com within 1 sec" {
      $time = (Get-NetworkTime -NTPServer time.windows.com).Time
      $now = get-date
      ($time - $now) -lt (New-TimeSpan -Seconds 1)  | Should be True
  }
  
  
}