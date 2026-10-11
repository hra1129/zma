param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\x64\Debug\zma.exe')
)

$ErrorActionPreference = 'Stop'
$Executable = (Resolve-Path $Executable).Path
$work = Join-Path ([System.IO.Path]::GetTempPath()) ('zma-operands-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null
$count = 0

function Invoke-Assembler([string]$Source, [string[]]$Options = @()) {
    $inputFile = Join-Path $work 'input.asm'
    $outputFile = Join-Path $work 'output.bin'
    [System.IO.File]::WriteAllText($inputFile, $Source, [System.Text.Encoding]::ASCII)
    $arguments = $Options + @('"' + $inputFile + '"', '"' + $outputFile + '"')
    $start = [System.Diagnostics.ProcessStartInfo]::new($Executable)
    $start.Arguments = $arguments -join ' '
    $start.WorkingDirectory = $work
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::Start($start)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(10000)) {
        Stop-Process -Id $process.Id
        throw "Assembler timed out for: $Source"
    }
    $result = @{
        ExitCode = $process.ExitCode
        Stdout = $stdout.Result
        Stderr = $stderr.Result
        Log = [System.IO.File]::ReadAllText((Join-Path $work 'zma.log'))
        Bytes = [System.IO.File]::ReadAllBytes($outputFile)
    }
    $process.Dispose()
    return $result
}

function Test-Invalid([string[]]$Instructions, [string[]]$Options = @()) {
    $source = (($Instructions | ForEach-Object { "    $_" }) -join "`r`n") + "`r`n    NOP`r`n"
    $result = Invoke-Assembler $source $Options
    $expected = $Instructions.Count
    if ($result.ExitCode -ne 1 -or $result.Stdout -notmatch 'Failed\.' -or
        $result.Stderr -notmatch "Found $expected error\(s\)\." -or
        ([regex]::Matches($result.Log, '\|ERROR \|')).Count -ne $expected -or
        $result.Bytes.Length -ne 1 -or $result.Bytes[0] -ne 0) {
        throw "Invalid instruction regression: $($Instructions -join '; ')`nExit: $($result.ExitCode)`n$($result.Stdout)$($result.Stderr)$($result.Log)"
    }
    $script:count++
}

try {
    $invalid = @(
        'LD (0x1234), B', 'LD [0x1234], B', 'LD [0x1234], C',
        'LD [0x1234], D', 'LD [0x1234], E', 'LD [0x1234], H', 'LD [0x1234], L',
        'LD [0x1234], IXH', 'LD [0x1234], IYL', 'LD [0x1234], 1',
        'LD [HL]', 'LD [HL],', 'LD [HL], B,', 'LD [HL], B extra',
        'LD [IX]', 'LD [IX],', 'LD [IX + 1]', 'LD [IX + 1],',
        'LD [IY]', 'LD [IY],', 'LD [IY - 1]', 'LD [IY - 1],',
        'LD [0x1234]', 'LD [0x1234],', 'LD [0x1234], BC extra',
        'LD [1 + 2 + 3]', 'LD [1 + 2 + 3],', 'LD [1 + 2 + 3',
        'LD A, [1 + 2', 'LD A, [1 + 2 + 3', 'LD A, [1 + 2 +',
        'LD A, [1 + 2], extra', 'LD BC, [1 + 2 +',
        'OUT [1 + 2]', 'OUT [1 + 2],', 'OUT [1 + 2 + 3]',
        'OUT [1 + 2 + 3],', 'OUT [1 + 2], B', 'OUT [1 + 2], A extra',
        'LD', 'ADD', 'ADC', 'SUB', 'SBC', 'AND', 'OR', 'XOR', 'CP',
        'INC', 'DEC', 'PUSH', 'POP', 'EX', 'BIT', 'SET', 'RES',
        'RLC', 'RRC', 'RL', 'RR', 'SLA', 'SRA', 'SRL', 'SLL',
        'JP', 'JR', 'DJNZ', 'CALL', 'RST', 'IN', 'OUT', 'MULUB', 'MULUW'
    )
    foreach ($instruction in $invalid) {
        Test-Invalid @($instruction)
    }
    Test-Invalid @('LD [0x1234], B', 'LD [HL],', 'OUT [1 + 2]', 'LD A, [1 + 2')
    Test-Invalid @('LD [0x1234], B', 'LD [HL],', 'OUT [1 + 2]', 'LD A, [1 + 2') @('-EALL')

    $valid = @(
        'LD [0x1234], A', 'LD [0x1234], HL', 'LD [0x1234], BC',
        'LD [0x1234], IX', 'LD [HL], B', 'LD [IX + 1], C',
        'LD [IY - 1], 2', 'LD A, [0x1234]', 'OUT [1 + 2], A', 'NOP'
    )
    $result = Invoke-Assembler (($valid -join "`r`n") + "`r`n")
    $expectedBytes = '323412223412ED433412DD22341270DD7101FD36FF023A3412D30300'
    if ($result.ExitCode -ne 0 -or [BitConverter]::ToString($result.Bytes).Replace('-', '') -ne $expectedBytes) {
        throw "Valid instruction regression`n$($result.Stdout)$($result.Stderr)$($result.Log)"
    }
    $count++

    foreach ($name in @('test1', 'test2')) {
        $source = Join-Path $PSScriptRoot "test_all_opecode\$name.asm"
        $reference = Join-Path $PSScriptRoot "test_all_opecode\ref_$name.asm.bin"
        $result = Invoke-Assembler ([System.IO.File]::ReadAllText($source, [System.Text.Encoding]::Default))
        $expectedBytes = [System.IO.File]::ReadAllBytes($reference)
        if ($result.ExitCode -ne 0 -or
            [BitConverter]::ToString($result.Bytes) -ne [BitConverter]::ToString($expectedBytes)) {
            throw "Existing opcode fixture failed: $source`n$($result.Stdout)$($result.Stderr)"
        }
        $count++
    }
    Write-Output "Passed $count operand and opcode regression cases."
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force
}
