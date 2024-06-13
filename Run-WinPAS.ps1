### CONFIGS

<#
    All Prompted variables are set with default values but are set later with console prompts.
    Once prompted values are set, the script will continuously loop using whatever you set.
    If you need to change the parameters, you must restart the script.

    IntervalInMinutes - Interval in Minutes(if OnTheMark = True, valid values are 5,10,15,20,30,60).
                        Otherwise, recommended values range from 5 to 600
    OnTheMark         - If true, script will take the IntervalInMinutes and perform MOD math to determine time.
                        This makes script execute (for example) every hour on the hour, or every 30 minutes on the hour/half hour mark.
    Log Files
        Each log file name is based on the date and time (down to the second).
        If you start, stop and restart the script, you will have 2 log files.
#>


### Working Directories for Speedtest program and logs 
    [String]$Messages         = "$PSScriptRoot\Messages.ps1";
    [String]$WorkingDirectory = "$PSScriptRoot\#ookla";
    [String]$LoggingDirectory = "$PSScriptRoot\#logs";
    [String]$SpeedTestExe     = "$WorkingDirectory\Speedtest.exe"
    [String]$SpeedTestMd      = "$WorkingDirectory\speedtest.md"
    [String]$VersionFile      = "$WorkingDirectory\Version.txt"

### Log file naming convention
    [String]$LogStartDateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss";
    [String]$LogFileName      = "$LoggingDirectory\SpeedTestLog_$($LogStartDateTime).csv";

### Speedtest.exe default argument. Arguments get prepended based on SpecifyServer boolean value.
    [String]$ExeArgs          = "--accept-license --format=json";

### PlaceHolder
    [datetime]$NextRunTime    = Get-Date;
    [bool]$exeMissing = $false;
    [bool]$VersionFileExists  = $false;
    [String]$CurrentVersion   = [String]::Empty;
    [Char]$NL                 = [Environment]::NewLine;

### Prompt-Set Variables
    [Int]$IntervalInMinutes   = 5;
    [Int]$ServerID            = 0;
    [bool]$OnTheMark          = $true;
    
### Imports
    . $Messages;

### Functions
    function Print-Message(){
        param(
            [Parameter(Mandatory=$true)][String[]]$Text,
            [Parameter(Mandatory=$false)][Switch]$PrependLines = $false,
            [Parameter(Mandatory=$false)][Switch]$AppendLines = $false
        );
        if($PrependLines){ Write-Host "--------------------------------"; }
        foreach($Message in $Text){
            Write-Host $Message;
        };
        if($AppendLines){ Write-Host "--------------------------------"; }
    };

### CODE START

    ### EULA & Terms
    Clear-Host;
    if (!(Test-Path -Path "$env:APPDATA\Ookla\Speedtest CLI\speedtest-cli.ini")) {
        Print-Message -Text $MsgEULA;
        Print-Message -Text $PromptEULA;
        [String]$result = Read-Host; 
        switch($result.ToUpper()){
            "N" { return; }
            default { }
        };
    };

    ### Prerequisites Check
    Clear-Host;
    Print-Message -Text "Speed test will be conducted once all prompts are answered." -PrependLines -AppendLines;
    
    ### Setting up Directories
    Write-Warning "Verifying Directories...";
    if (!(Test-Path -Path $WorkingDirectory)) { New-Item -Path $WorkingDirectory -ItemType Directory | Out-Null; };
    if (!(Test-Path -Path $LoggingDirectory)) { New-Item -Path $LoggingDirectory -ItemType Directory | Out-Null; };
    
    ### Verifying Files
    Write-Warning "Verifying Files...";
    if (!(Test-Path -Path $SpeedTestExe)) { $exeMissing = $true; } else { $exeMissing = $false; };
    if (!(Test-Path -Path $VersionFile)) { $VersionFileExists = $false; } else { $VersionFileExists = $true; };
    if ((Test-Path -Path $SpeedTestExe) -and $VersionFileExists) { $CurrentVersion = Get-Content -Path $VersionFile; };

    ### Checking Version
    Write-Warning "Verifying Version...";
    $HTML = Invoke-WebRequest -Uri "https://www.speedtest.net/apps/cli"; $LatestVersion = [String]::Empty;
    foreach($Line in $HTML.Links) { if($Line.href.ToString().Contains("win64")) { $Line.href -match "[0-9].[0-9].[0-9]"; $LatestVersion = $Matches[0]; break;}; };

    if($exeMissing -or ($CurrentVersion -ne $LatestVersion)){
        Print-Message -Text @("Missing Speedtest.exe in $WorkingDirectory","Or existing version could not be verified.") -PrependLines -AppendLines;
        [String]$result = Read-Host -Prompt "Would you like to download the newest version now? y/n";
        switch($result.ToUpper()) {
            "Y"{
                foreach($Line in $HTML.Links){
                    if($Line.href.ToString().Contains("win64")){
                        try{ Remove-Item -Path $WorkingDirectory -Recurse -Force | Out-Null; } catch { return; }
                        try{ New-Item -Path $WorkingDirectory -ItemType Directory | Out-Null; } catch { return; }
                        Invoke-WebRequest -Uri $Line.href -Method Get -OutFile $WorkingDirectory\temp.zip;
                        Expand-Archive -Path $WorkingDirectory\temp.zip -DestinationPath $WorkingDirectory -Force;
                        Remove-Item -Path $WorkingDirectory\temp.zip;
                        Set-Content -Path $VersionFile -Value $LatestVersion;
                        switch((Test-Path -Path $SpeedTestExe) -and (Test-Path -Path $SpeedTestMd) -and (Test-Path -Path $VersionFile)){
                            $true { Write-Warning "Speedtest files have been downloaded and unpacked."; }
                            $false { Write-Warning "Failed to locate Speedtest files... Quitting script."; return; }
                        };
                    };
                };
            }
            "N" { Write-Warning "Quitting, you no download needed files :("; if(!(Test-Path $SpeedTestExe)){ return; }; }
            default{ Write-Warning "Your input was invalid."; return; }
        };
    };

    Clear-Host;
    Print-Message -Text $OnTheMarkQuestion -PrependLines -AppendLines;
    [String]$result = Read-Host;
    switch($result.ToUpper()){
        "Y"{ $OnTheMark = $true; }
        "N"{ $OnTheMark = $false; }
        default{ Write-Warning "Your input was invalid."; return; }
    };

    switch($OnTheMark){
        $true { 
            Write-Warning "Valid values are: 5,10,15,30 and 60 Minutes";
            if ($OnTheMark -and !(5,10,15,20,30,60).Contains($IntervalInMinutes)) { 
                Write-Warning "Script only supports OnTheMark option for intervals 5, 10, 15, 20, 30 & 60"; return; 
            };
        }
        $false { 
            Write-Warning "Recommended value range: 15-600 minutes (whole numbers):"; 
        }
    };
    $IntervalInMinutes = Read-Host;

    Clear-Host;
    [String]$result = Read-Host -Prompt "Would you like to specify a server to use for speed testing? y/n";
    switch($result.ToUpper()){
        "Y" {
            Invoke-Expression -Command "$SpeedTestExe --servers";
            Print-Message -Text $ServerSelectMsg -PrependLines -AppendLines;
            $ServerID = Read-Host;
            if($ServerID -ne "" -and $ServerID -and $null -and $ServerID -ne 0){ $ExeArgs += " --server-id=$ServerID"; };
        }
        "N" {}
        default{ Write-Warning "Your input was invalid."; return; }
    };

    Write-Warning "Please confirm these settings before proceeding."
    Write-Warning "Options Set | IntervalInMinutes = $IntervalInMinutes | OnTheMark = $OnTheMark | SpecifyServer = $ServerID | Executing Speedtest.exe $ExeArgs"
    [String]$Confirm = Read-Host -Prompt "Are these correct? y/n";
    switch($Confirm.ToUpper()){
        "N" {
            Write-Warning "Please restart the script.";
        }
        default{}
    }

### Set CSV Headers
    Write-Host "Setting Log File Headers...";
    Set-Content -Path $LogFileName -Value "DateTime,Jitter.ms,Ping.ms,Ping.L.ms,Ping.H.ms,DL.bps,UL.bps,Loss%,ISP,ExternalIP,Server.ID,Server.Host,Server.Name,Server.City,Server.State,Server.Country,Server.IP,Result.URL";

### Perform Speed Test Loop
    while($true){
        Clear-Host;
        Write-Warning "Using Options: | IntervalInMinutes = $IntervalInMinutes | OnTheMark = $OnTheMark | SpecifyServer = $ServerID | Executing Speedtest.exe $ExeArgs";
        if($OnTheMark){
            while($true){
                if(((Get-Date).Minute % $IntervalInMinutes -eq 0) -or (Get-Date).Minute -eq 0){
                    $NextRunTime = (Get-Date).AddMinutes($IntervalInMinutes); break;
                };
                Start-Sleep -Seconds 45;
            };
        };
        Print-Message -Text $BeingTestMsg -PrependLines -AppendLines;
        [Int]$StartMinute = (Get-Date).Minute;
        $J = Invoke-Expression -Command "$SpeedTestExe $ExeArgs" | ConvertFrom-Json;
        while((Get-Date).Minute -eq $StartMinute){ Start-Sleep -Seconds 1; };
        Write-Host "Logging Results...";
        Add-Content -Path $LogFileName -Value "$($J.timestamp),$($J.ping.jitter),$($J.Ping.latency),$($J.Ping.low),$($J.ping.high),$($J.download.bandwidth),$($J.upload.bandwidth),$($J.packetLoss),$($J.isp),$($J.interface.externalIp),$($J.server.id),$($J.server.host),$($J.server.name),$($J.server.location),$($J.server.country),$($J.server.ip),$($J.result.url)";
        Write-Host "Results written to log file $LogFileName ...";
        if(!$OnTheMark){
            $NextRunTime = (Get-Date).AddMinutes($IntervalInMinutes * 60);
            Print-Message -Text @("Next Speedtest will execute at $NextRunTime ... please wait...") -PrependLines;
            Start-Sleep -Seconds ($IntervalInMinutes * 60);
        };
    };