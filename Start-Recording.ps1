#region - Script Setup
    #Bypass Execution Policy
        Set-ExecutionPolicy 'Bypass' -Scope 'Process' -Force
    #Run As Admin
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
    #Enable TLS 1.2
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    #Disable Defualt Proxy
		[System.Net.HttpWebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($null)
    #Make Downloads Faster
        $ProgressPreference = 'SilentlyContinue'
    #Write-Host Functions
        Function WHG($Text){Write-Host("$Text")-ForegroundColor("Green")};Function WHGL($Text){Write-Host("$Text")-ForegroundColor("Green")-NoNewline}
        Function WHR($Text){Write-Host("$Text")-ForegroundColor("Red")};Function WHRL($Text){Write-Host("$Text")-ForegroundColor("Red")-NoNewline}
        Function WHY($Text){Write-Host("$Text")-ForegroundColor("Yellow")};Function WHYL($Text){Write-Host("$Text")-ForegroundColor("Yellow")-NoNewline}
        Function WHB($Text){Write-Host("$Text")-ForegroundColor("Cyan")};Function WHBL($Text){Write-Host("$Text")-ForegroundColor("Cyan")-NoNewline}
        Function WH($Text){Write-Host("$Text")};Function WHL($Text){Write-Host("$Text")-NoNewline};Function WS{Write-Host("`n")}
    #Disable QuickEdit
        Add-Type -Language "CSharp" -TypeDefinition 'using System;using System.Collections.Generic;using System.Linq;using System.Text;using System.Threading.Tasks;using System.Runtime.InteropServices; public static class DisableConsoleQuickEdit{const uint ENABLE_QUICK_EDIT = 0x0040;const int STD_INPUT_HANDLE = -10;[DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr GetStdHandle(int nStdHandle);[DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);[DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode); public static bool SetQuickEdit(bool SetEnabled){IntPtr consoleHandle = GetStdHandle(STD_INPUT_HANDLE);uint consoleMode;if (!GetConsoleMode(consoleHandle, out consoleMode)){return false;}if (SetEnabled){consoleMode &= ~ENABLE_QUICK_EDIT;} else {consoleMode |= ENABLE_QUICK_EDIT;} if (!SetConsoleMode(consoleHandle, consoleMode)) {return false;} return true;}}';[DisableConsoleQuickEdit]::SetQuickEdit($true)
    #Snap To Left
        Add-Type -Name Window -Namespace ConsolePos -MemberDefinition '[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();[DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int W, int H); '; $consolePosHWND = [ConsolePos.Window]::GetConsoleWindow();$consolePosHWND = [ConsolePos.Window]::MoveWindow($consolePosHWND, -6, 0, 600, 650)
    #Set Color
        $host.ui.rawui.backgroundcolor = "black"
    #Variables For Window Size
        $ConsoleBuffer = $Host.UI.RawUI.BufferSize; $ConsoleWindow = $Host.UI.RawUI.WindowSize
    #Set Parameters For Window Size
        $ErrorActionPreference= 'silentlycontinue';$ConsoleWindow.Height=(15);$ConsoleBuffer.Height=(15);$ConsoleWindow.Width=(60); $ConsoleBuffer.Width=(60)
    #Apply Window Size
        $host.UI.RawUI.set_bufferSize($ConsoleBuffer);$host.UI.RawUI.set_windowSize($ConsoleWindow);$host.UI.RawUI.BufferSize=($ConsoleBuffer);$ErrorActionPreference= 'continue'
    #PowerShell Console View
        Add-Type -Name Window -Namespace ConsoleState -MemberDefinition '[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'; $ConsoleStatePtr = [ConsoleState.Window]::GetConsoleWindow(); [ConsoleState.Window]::ShowWindow($ConsoleStatePtr, 4)
    #Set Window Title
        $host.ui.RawUI.WindowTitle = "Kick.com-Livestream-Recorder"
#endregion Script Setup

#region - Customizable Settings
    $KickChannel = "xqc"           #Change this to the kick.com channel you want to record. EX: "kick.com/xqc" would be "xqc"
    $DownloadFolder = "Z:\Kick"    #Change this to the directory you want to store the live streams.
#endregion

#region - Static Settings
    $KickAPIUrl = "https://kick.com/api/v2/channels/$KickChannel"
    $Module1Name = 'Selenium'
    $Module1MinVer = '3.0.1'
    $DriverBuild = 'chromedriver_win32'
    $DriverExe = 'chromedriver.exe'
    $DriverUrl = 'https://chromedriver.storage.googleapis.com/'
#endregion

#region - Display Settings
    Clear-Host;WHBL("Starting Script");WHY('...');WS;WHBL("Script Settings");WHY(":");WHBL(" Channel");WHY(": $KickChannel");WHBL(" Download Folder");WHY(": $DownloadFolder");WS
#endregion

#region - Setup Selenium module to use Chrome for accessing Kick's API Webpage
    if (!(Get-PackageProvider -ListAvailable -Name 'NuGet')){Install-PackageProvider -Name 'NuGet' -Force -Confirm:$false}
    if (!(Get-Module -ListAvailable -Name $Module1Name)) {Install-Module -Name $Module1Name -Force -Confirm:$false -MinimumVersion $Module1MinVer; $Module1Dir = ((Get-Item((Get-Module -ListAvailable -Name $Module1Name).Path)).Directory.FullName); Import-Module $Module1Name}else{$Module1Dir = ((Get-Item((Get-Module -ListAvailable -Name $Module1Name).Path)).Directory.FullName); Import-Module $Module1Name}
    $LatestChromeStableRelease = Invoke-WebRequest ("$($DriverUrl)"+"LATEST_RELEASE") | Select-Object -ExpandProperty 'Content'
    $Build = $DriverBuild
    $AssembliesDir = "$Module1Dir\assemblies"
    $BinaryFileName = $DriverExe
    $BuildFileName = "$Build.zip"
    Invoke-WebRequest -OutFile "$($AssembliesDir+'/'+$BuildFileName)" "$DriverUrl$LatestChromeStableRelease/$BuildFileName"
    Expand-Archive -Path "$($AssembliesDir+'/'+$BuildFileName)" -DestinationPath "$($AssembliesDir+'/'+$Build)" -Force
    $SeleniumChromeExeNew = (Get-ChildItem("$($AssembliesDir+'\'+$Build+'\*.*')") -include $DriverExe).FullName
    $SeleniumChromeExeOld = (Get-ChildItem($AssembliesDir+'\*.*') -include $DriverExe).FullName
    $SeleniumChromeExeNewHash = Get-FileHash -Algorithm 'SHA256' -Path $SeleniumChromeExeNew
    $SeleniumChromeExeOldHash = Get-FileHash -Algorithm 'SHA256' -Path $SeleniumChromeExeOld
    if ($SeleniumChromeExeNewHash.Hash -ne $SeleniumChromeExeOldHash.Hash){Copy-Item -Path $SeleniumChromeExeNew -Destination $SeleniumChromeExeOld -Force -ErrorAction 'Continue'}
#endregion

#region - Download and Install Chrome if not already installed.
    if ((Get-Package -Name('Google Chrome')-ErrorAction('SilentlyContinue')) -eq $null) {
        Winget Install 'Google.Chrome'
    }
#endregion

#region - Download and Install ffmpeg if not already installed.
    if ((Get-Package -Name('FFmpeg')-ErrorAction('SilentlyContinue')) -eq $null) {
        Winget Install 'Gyan.FFmpeg'
        $FFMPEGFindExe = 'ffmpeg.exe'; $FFMPEGInstallDir = ((Get-Package -Name('FFmpeg')-ErrorAction('SilentlyContinue')).SwidTagText|findstr('InstallLocation=')|%{[regex]::match($_,'(?<=")(.+)(?=")')}).value; $FFMPEGexe = (Get-ChildItem($FFMPEGInstallDir+'\*.*') -recurse -include $FFMPEGFindExe).FullName
        setx /M path "%path%;$FFMPEGexe"
    }
#endregion

#region - Function for accessing Kick's API Webpage
    Function Get-KickStream($InputUrl)
    {
        #Window Position Argument is only used since "-Headless" will not work with Kick.com
        $SeleniumChrome = Start-SeChrome -Minimized -Quiet -Arguments "--window-position=$([Math]::Pow(9,9)),$([Math]::Pow(9,9))"
        $SeleniumChrome.Url = $InputUrl
        $SeleniumChrome.PageSource
        $SeleniumChrome.Quit()
        Start-Sleep('1')
    }
#endregion

#region - Use "try" and "finally" to make sure that any jobs that are started are closed.
try{
    #region - Start Continuous Loop
        while($true){
        #Check Kick.com for stream info and Format Results From Kick.com
            $KickGet = ((((Get-KickStream($KickAPIUrl))-replace'<[^>]+>').Split(',')))
            $KickAPIResponse = ($KickGet | Select-String "livestream")-replace('"livestream":')
        #If livestream is offline, Check back in 50 seconds.
            if($KickAPIResponse -eq 'null'){
                Clear-Host;WHBL("Channel");WHY(": $KickChannel");WHBL("Time of Log");WHY(": "+(Get-Date -F "MM.dd.yyyy @ hh:mmtt"));WHBL("Log");WHYL(": ");WHR("Stream Offline");WS
                Start-Sleep('60')
            }
        #If livestream is online, Start recording.
            else{
                WHBL("Channel");WHY(": $KickChannel");WHBL("Time of Log");WHY(": "+(Get-Date -F "MM.dd.yyyy @ hh:mmtt"));WHBL("Log");WHYL(": ");WHG("Stream Online!");WS
            #Get M3U8 Url from API Page.
                $KickGet = ((((Get-KickStream($KickAPIUrl))-replace'<[^>]+>').Split(',')))
                $KickStreamUrl = (($KickGet | Select-String "playback_url")-replace('"')-replace('playback_url:')-replace('[\\]'))
            #Get current time for output file.
                $StartDateTime = (Get-Date -F "MM.dd.yyyy_hh.mm.tt")
                $RecordingOutputFile = "${KickChannel}_${StartDateTime}.ts"
            #Start FFMPEG as Job.
                $job = Start-Job -ScriptBlock { param($KickStreamUrl, $KickChannel, $StartDateTime, $DownloadFolder, $RecordingOutputFile)
                    Push-Location($DownloadFolder)
                    ffmpeg -i "$KickStreamUrl" -map '0' -tune 'zerolatency' -y -c:v copy "$RecordingOutputFile" 2>&1 
                } -ArgumentList $KickStreamUrl, $KickChannel, $StartDateTime, $DownloadFolder, $RecordingOutputFile
            #While Job is running, Show info from FFMPEG in a readable format.
                while($job.State -eq 'Running') {
                    Start-Sleep('5');Clear-Host;$ErrorActionPreference= 'silentlycontinue';WHBL("Channel");WHY(": $KickChannel");WHBL("Time of Log");WHY(": "+(Get-Date -F "MM.dd.yyyy @ hh:mmtt"));WHBL("Output File");WHY(": $DownloadFolder\$RecordingOutputFile");WHBL("`nFFMPEG Status");WHY(':');((((Receive-Job -Job $job -Keep | Select-String 'frame')[-1]-replace('q=-...')-replace("\s")-replace("frame=","`nframe=")-replace("fps=","`nfps=")-replace("size=","`nsize=")-replace("time=","`ntime=")-replace("bitrate=","`nbitrate=")-replace("speed=","`nspeed=")).TrimStart()).Split("`n").replace('fps','fps ') | sort { $_.length } | % {$Log = $_-split('='); WHBL($Log[0]);WHL("`t= "); WHY($Log[1])});WS;$ErrorActionPreference= 'continue';Start-Sleep('25')
                }
            #After Job is finished, Remove the Job, and Start the proccess over again!
                Clear-Host;WHBL("Channel");WHY(": $KickChannel");WHBL("Time of Log");WHY(": "+(Get-Date -F "MM.dd.yyyy @ hh:mmtt"));WHBL("Output File");WHY(": $DownloadFolder\$RecordingOutputFile");WHBL("Log");WHY(": FFMPEG Job is finished, This usally means the stream is offline or ffmpeg has been closed.");WS
                Stop-Job -Job $job -ErrorAction 'SilentlyContinue';Remove-Job -Job $job; $job = $null
                Start-Sleep('10')
            }
            Start-Sleep('60')
        }
    #endregion
}
#After Script is finished, Remove the Job, and Close the script!
finally{
    WHBL("Channel");WHY(": $KickChannel");WHBL("Time of Log");WHY(": "+(Get-Date -F "MM.dd.yyyy @ hh:mmtt"));WHBL("Output File");WHY(": $DownloadFolder\$RecordingOutputFile");WHBL("Log");WHYL(": ");WHR("Stop Requested By User.");WS
    Stop-Job -Job $job -ErrorAction('SilentlyContinue');Remove-Job -Job $job -ErrorAction('SilentlyContinue'); $job = $null
    WHR("Script Exiting...")
    Start-Sleep("1");Write-Host -NoNewLine 'Press any key to continue...';$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
#endregion
