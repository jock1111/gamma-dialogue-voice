function Get-DialogueVolume {
    param([string]$Path)

    $data = [System.IO.File]::ReadAllText($Path, $ByteEncoding)
    $mcm = [regex]::Match($data, '(?mi)^\[mcm\][^\r\n]*(?:\r?\n|$)(?<body>[\s\S]*?)(?=^\[|\z)')
    $value = [regex]::Match($mcm.Groups['body'].Value,
        '(?mi)^[ \t]*gamma_dialogue_voice/volume[ \t]*=[ \t]*(?<value>[+-]?\d+)[ \t]*(?:;[^\r\n]*)?\r?$')
    $number = 0
    if (-not [int]::TryParse($value.Groups['value'].Value, [ref]$number)) { return 100 }
    return [Math]::Max(0, [Math]::Min(200, $number))
}

function Set-DialogueVolume {
    param([string]$Directory, [int]$Percent)

    $pack = [System.IO.Path]::GetFullPath((Join-Path $Directory '..\..\..\..'))
    $state = Join-Path $pack 'Dialogue volume.txt'
    if ([System.IO.File]::Exists($state) -and [System.IO.File]::ReadAllText($state).Trim() -eq "$Percent") {
        return
    }
    if (-not ('DialogueOggVolume' -as [type])) {
        Add-Type -Path (Join-Path $ToolDir 'DialogueOggVolume.cs')
    }
    # An interrupted rewrite must be retried even when the next choice equals the old gain.
    if (-not [System.IO.File]::Exists($state)) {
        [System.IO.File]::WriteAllText($state, 'pending')
    } else {
        Write-AtomicBytes -Path $state -Bytes ([System.Text.Encoding]::ASCII.GetBytes('pending'))
    }
    Write-Log "Applying dialogue volume $Percent% to the selected voice pack."
    $count = [DialogueOggVolume]::ApplyDirectory($Directory, $Percent)
    Write-AtomicBytes -Path $state -Bytes ([System.Text.Encoding]::ASCII.GetBytes("$Percent"))
    Write-Log "Dialogue volume $Percent% ready ($count clip headers updated)."
}
