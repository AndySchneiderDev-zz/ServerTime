Function Set-TimeServer
{
<#
.Synopsis
   Sets the NTP server on a server. 

.Description
   Set-TimeServer sets the NTP server on a server. It is typically used on the PDC Emulator

.Example
   Set-TimeServer -TimeServer time.windows.com

.Example
   "time.windows.com" | Set-TimeServer 

#>
[CmdletBinding(SupportsShouldProcess,
               ConfirmImpact='High')]
param(
[string[]]
$TimeServer
)
  # flatten the array to a string, if there is more than one entry
  $servers = [string]$TimeServer

  # Need to add a check for Hyper-V here.. otherwise, we don't need to set this key
  $ConfirmationMessage = "NTP Server Setting"
  $Caption = "Updating NTP Server to $servers"
    
  if ($PSCmdlet.ShouldProcess($ConfirmationMessage,$Caption))
  {
    Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider -Name Enabled -Value 0
    w32tm.exe /config /manualpeerlist:`"$servers`" /syncfromflags:manual /reliable:yes /update
    Restart-Service W32Time
    $result = w32tm.exe /resync /force
}
  

}

Function Get-TimeServer
{
<#
.Synopsis
   Gets the current time server 

.Description
   Gets the current time server

.Example
    Get-TimeServer
#>
  $result = w32tm.exe /query /source
  return $result.trim()
}

Function Update-Endianness 
{

  param(
    [UInt64]
    $n
  )
  $result =  (($n -band 0x000000ff) -shl 24) +
             (($n -band 0x0000ff00) -shl 8) +
             (($n -band 0x00ff0000) -shr 8) +
             (($n -band 0xff000000) -shr 24)
  
     
  [Uint32]$result

}

Function Get-NetworkTime 
{
 <#
.Synopsis
   Query's an NTP Server 

.Description
   Builds an NTP request and sends it via a socket to an NTP Server and gets a response.
   This code was translated from C# from this page on Stackoverflow -
   http://stackoverflow.com/questions/1193955/how-to-query-an-ntp-server-using-c

.Example
   Get-NetworkTime -NTPServer time.windows.com | fl 

  NTPServer   : time.windows.com
  Time        : 5/26/2015 2:09:17 AM
  Miliseconds : 3641594957172.46

#>
param
    (
    [Parameter(Mandatory,
               ValueFromPipeline,
               ValueFromPipelineByPropertyName)]
    $NTPServer
    )
    PROCESS 
    {
    $ntpData = New-Object Byte[] 48
    $ntpData[0] = 0x1B # LeapIndicator = 0 (no warning), VersionNum = 3 (IPv4 only), Mode = 3 (Client Mode)

    Try 
        {
            $IpAddress = [System.Net.Dns]::GetHostEntry($NTPServer).AddressList[0]
        }

    Catch 
        {
            Throw "Cannot Resolve $NTPServer"
        }

    $addressFamily = [System.Net.Sockets.AddressFamily]::InterNetwork
    $socketType    = [System.Net.Sockets.SocketType]::Dgram
    $protocolType  = [System.Net.Sockets.ProtocolType]::Udp
    $socket        = New-object System.Net.Sockets.Socket($addressFamily,$socketType,$protocolType)
    $IPEndPoint    = New-Object System.Net.IPEndPoint($IpAddress,123) #NTP uses port 123

    Try 
        {
          $socket.ReceiveTimeout = 1000
          $socket.Connect($IPEndPoint) 
          $socket.Send($ntpData) | Out-Null
          $socket.Receive($ntpData) | Out-Null
          $socket.Close()
        }
    Catch [System.Net.Sockets.SocketException]
    {
        Write-Warning "Timed out connecting to $NTPServer"
        return;
    }

    $ReplyTime = [byte]40
    $intPart =   [BitConverter]::ToUInt32($ntpData,$ReplyTime)
    $fracPart =  [BitConverter]::ToUInt32($ntpData,$ReplyTime + 4)

    $intPart =   Update-Endianness -n $intPart
    $fracPart =  Update-Endianness -n $fracPart

    $miliSeconds = ($intPart * 1000) + (($fracPart * 1000) / 0x100000000L)
    $networkDateTime = (new-object System.DateTime(1900, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).
                       AddMilliseconds([long]$miliseconds)

    [PSCustomObject]@{
                    'NTPServer'=$NTPServer ; 
                    'Time' = $networkDateTime.ToLocalTime();
                    'Miliseconds' = $miliSeconds
                    }
    }
}

