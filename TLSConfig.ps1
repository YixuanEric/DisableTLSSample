$regkeys = @(
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0",
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client",
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server", #2
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1",
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client", #4
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server",
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2",        #6
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client",
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
)

Function Set-CryptoSetting {
  param (
    $keyindex,
    $value,
    $valuedata,
    $valuetype,
    $restart
  )

  # Check for existence of registry key, and create if it does not exist
  If (!(Test-Path -Path $regkeys[$keyindex])) {
    New-Item $regkeys[$keyindex] | Out-Null
  }

  # Get data of registry value, or null if it does not exist
  $val = (Get-ItemProperty -Path $regkeys[$keyindex] -Name $value -ErrorAction SilentlyContinue).$value

  If ($val -eq $null) {
    # Value does not exist - create and set to desired value
    New-ItemProperty -Path $regkeys[$keyindex] -Name $value -Value $valuedata -PropertyType $valuetype | Out-Null
    $restart = $True
  } Else {
    # Value does exist - if not equal to desired value, change it
    If ($val -ne $valuedata) {
      Set-ItemProperty -Path $regkeys[$keyindex] -Name $value -Value $valuedata
      $restart = $True
    }
  }

  $restart
}


# DON'T DISABLE 1.0 and 1.1 without testing whether your clients would be able connect to your service/other dependencies or not.
# Ensure TLS 1.0 Key exists
If (!(Test-Path -Path $regkeys[0])) {
	New-Item $regkeys[0] | Out-Null
}

# Ensure TLS 1.0 disabled for client
$reboot = Set-CryptoSetting 1 Enabled 0 DWord $reboot

# Ensure TLS 1.0 disabled for server
$reboot = Set-CryptoSetting 2 Enabled 0 DWord $reboot

# Ensure TLS 1.1 Key exists
If (!(Test-Path -Path $regkeys[3])) {
   New-Item $regkeys[3] | Out-Null
}

# Ensure TLS 1.1 disabled for client
$reboot = Set-CryptoSetting 4 Enabled 0 DWord $reboot

# Ensure TLS 1.1 disabled for client
$reboot = Set-CryptoSetting 5 Enabled 0 DWord $reboot

If (Test-Path -Path $regkeys[8]) {
  # Ensure TLS 1.2 enabled for server for older version of windows if the settings has been changed
  $reboot = Set-CryptoSetting 8 Enabled 1 DWord $reboot
}


# If any settings were changed, reboot
If ($reboot) {
  # Randomize the reboot timing since it could be run in a large cluster.
  $tick = [System.Int32]([System.DateTime]::Now.Ticks % [System.Int32]::MaxValue)
  $rand = [System.Random]::new($tick)
  $sec = $rand.Next(30, 600)
  Write-Host "Rebooting after", $sec, " second(s)..."
  Write-Host  shutdown.exe /r /t $sec /c "TLS settings changed" /f /d p:2:4
} Else {
  Write-Host "Nothing get updated."
}