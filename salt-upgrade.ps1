function Setup-Upgrade
{
    $tempDir = 'C:\temp-salt-upgrade'
    New-Item $tempDir -itemtype directory

    $curlReq = "api/call"
    $curlOut = "$tempDir\latest_version.txt"
    curl $curlReq -Output $curlOut
    
    $fileName = Get-Contents $curlOut
    $url = "https://repo.saltstack.com/windows/$fileName"
    $output = "$tempDir\$fileName"
}

fuction Uninstall-And-Install
{
    Move-Item c:\salt\conf c:\temp-salt-upgrade\conf
    (Get-WmiObject Win32_Service -filter "name='salt-minion'").Delete()
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    iex ' $tempDir\$fileName /S /minion-name=%computername% /master=10.0.1.10 /start-service=0'
}

function Move-And-Delete
{
    Move-Item c:\salt\conf c:\salt\conf.bak
    Move-Item c:\temp-salt-upgrade\conf c:\salt\conf
    Remove-Item c:\temp-salt-upgrade -recurse
}

function Main 
{
   try {
        Setup-Upgrade
	Uninstall-And-Install
	Move-And-Delete
    } 
    catch {
        $exception = $_.Exception | format-list -force
        $exception > "SaltUpgradeException.txt"
    }

}

Main
