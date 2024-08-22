# 全域變數
$global:processName = ""
$global:urlExist = $false
$global:prtgProbe = ""

# Process 類別
class Process {
    [int]$pid
    [long]$ppt
    [int]$threadCount
    [int]$handleCount
    [long]$privateByte
    [long]$workingSet
    [long]$ts
}

# 獲取邏輯處理器數量
function Get-LogicalProcessorCount {
    $cores = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
    return $cores
}

# 獲取進程資訊
function Get-ProcessInformation {
    $processes = Get-WmiObject Win32_PerfRawData_PerfProc_Process | 
                 Select-Object Name, WorkingSet, PrivateBytes, PercentProcessorTime, ThreadCount, HandleCount, Timestamp_Sys100NS, IDProcess

    $result = @()
    foreach ($proc in $processes) {
        if ($proc.Name -match "^$global:processName#*\d*$") {
            $p = [Process]::new()
            $p.pid = [int]$proc.IDProcess
            $p.ppt = [long]$proc.PercentProcessorTime
            $p.threadCount = [int]$proc.ThreadCount
            $p.handleCount = [int]$proc.HandleCount
            $p.privateByte = [long]$proc.PrivateBytes
            $p.workingSet = [long]$proc.WorkingSet
            $p.ts = [long]$proc.Timestamp_Sys100NS
            $result += $p
        }
    }
    return $result
}

# 主函數
function Main {
    param (
        [string]$processNameArg,
        [string]$prtgProbeArg
    )

    $global:processName = $processNameArg
    if ($prtgProbeArg -match '^https*\:\/\/\S+\:\d+\/\S+$') {
        $global:urlExist = $true
        $global:prtgProbe = $prtgProbeArg
    }

    if ([string]::IsNullOrEmpty($global:processName)) {
        exit
    }

    $cores = Get-LogicalProcessorCount
    Write-Host "Logical Processors: $cores"
    Write-Host "Process Name: $global:processName"
    if ($global:urlExist) {
        Write-Host "Probe URL: $global:prtgProbe"
    }

    $p1 = Get-ProcessInformation
    Start-Sleep -Seconds 1
    $p2 = Get-ProcessInformation

    $instance = 0
    $ppt = 0
    $dppt = 0
    $threadCount = 0
    $handleCount = 0
    $privateByte = 0
    $workingSet = 0

    foreach ($proc2 in $p2) {
        $instance++
        $proc1 = $p1 | Where-Object { $_.pid -eq $proc2.pid }
        if ($proc1) {
            $pptDiff = $proc2.ppt - $proc1.ppt
            $tsDiff = $proc2.ts - $proc1.ts
            if ($tsDiff -gt 0) {
                if ($pptDiff -ge 0) {
                    $dpptTemp = [Math]::Round(($pptDiff / $tsDiff) * 100 / $cores)
                    $ppt += $dpptTemp
                }
            }
        }
        $threadCount += $proc2.threadCount
        $handleCount += $proc2.handleCount
        $privateByte += $proc2.privateByte
        $workingSet += $proc2.workingSet
    }

    if ($instance -gt 0) {
        $dppt = $ppt / $instance
    } else {
        $dppt = 0
    }

    $payload = @"
<PRTG>
<Result><Channel>Instances</Channel><Value>$instance</Value></Result>
<Result><Channel>Handles</Channel><Value>$handleCount</Value></Result>
<Result><Channel>Threads</Channel><Value>$threadCount</Value></Result>
<Result><Channel>CPU Usage (Total)</Channel><Value>$ppt</Value><Unit>Percent</Unit></Result>
<Result><Channel>CPU Usage (average per Instance)</Channel><Value>$dppt</Value><Unit>Percent</Unit></Result>
<Result><Channel>Working Set</Channel><Value>$workingSet</Value><Unit>BytesMemory</Unit></Result>
<Result><Channel>Private Bytes</Channel><Value>$privateByte</Value><Unit>BytesMemory</Unit></Result>
</PRTG>
"@

    Write-Host "HTTP POST Payload: $payload"

    if ($global:urlExist) {
        try {
            $securityProtocol = [Net.ServicePointManager]::SecurityProtocol
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            $response = Invoke-WebRequest -Uri $global:prtgProbe -Method Post -Body "content=$payload" -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
            Write-Host "`nProbe Response: $($response.Content)"
        }
        catch {
            Write-Host "`nError: $_"
        }
        finally {
            [Net.ServicePointManager]::SecurityProtocol = $securityProtocol
        }
    }
}

# 執行主函數
Main -processNameArg $args[0] -prtgProbeArg $args[1]