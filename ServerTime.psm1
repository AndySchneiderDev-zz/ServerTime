
Function Get-TimeServer 
{

  $timeservers = (get-itemproperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name ntpServer).NtpServer
  @($timeservers -split ' ')

}


Function Set-TimeServer 
{
    param(
        [Parameter(Mandatory)]
        [Alias("Server")]
        [Alias("NTPServer")]
        $TimeServer
    )
    Try 
        {
            Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name ntpServer -Value $TimeServer
        }

    Catch 
        {
            # To DO
        }
}

Function Set-TimeServerConfiguration 
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('WindowsDefault','ReliableTimeServer')]
        
        [Alias("Flags")]
        $AnnounceFlags
    )

    if     ($AnnounceFlags = 'WindowsDefault')     {$flag = 5}
    elseif ($AnnounceFlags = 'ReliableTimeServer') {$flag = 10 }

    Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name AnnounceFlags -Value $flag

}

Function Get-TimeServerConfiguration 
{

    $flags = (get-itemproperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name AnnounceFlags).AnnounceFlags
    $flags

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

