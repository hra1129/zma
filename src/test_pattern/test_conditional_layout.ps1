param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\x64\Debug\zma.exe')
)

$ErrorActionPreference = 'Stop'
$Executable = (Resolve-Path $Executable).Path
$work = Join-Path ([System.IO.Path]::GetTempPath()) ('zma-if-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null
$count = 0

function Assemble([string]$Source, [string[]]$Options = @(), [string]$Directory = $work) {
    $inputFile = Join-Path $work 'input.asm'
    $outputFile = Join-Path $work 'output.bin'
    [System.IO.File]::WriteAllText($inputFile, $Source, [System.Text.Encoding]::ASCII)
    $start = [System.Diagnostics.ProcessStartInfo]::new($Executable)
    $start.Arguments = ($Options -join ' ') + ' "' + $inputFile + '" "' + $outputFile + '"'
    $start.WorkingDirectory = $Directory
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::Start($start)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) {
        Stop-Process -Id $process.Id
        throw 'Conditional layout evaluation timed out'
    }
    $result = @{
        ExitCode = $process.ExitCode
        Stdout = $stdout.Result
        Stderr = $stderr.Result
        Bytes = [System.IO.File]::ReadAllBytes($outputFile)
        Log = [System.IO.File]::ReadAllText((Join-Path $Directory 'zma.log'))
        Symbols = [System.IO.File]::ReadAllText((Join-Path $Directory 'zma.sym'))
    }
    $process.Dispose()
    return $result
}

function Check([string]$Name, [string]$Source, [string]$Expected, [string[]]$Options = @()) {
    $result = Assemble $Source $Options
    if ($result.ExitCode -ne 0 -or $result.Stderr -ne '' -or
        [BitConverter]::ToString($result.Bytes).Replace('-', '') -ne $Expected) {
        throw "${Name}: unexpected result`nExit=$($result.ExitCode)`n$($result.Stdout)$($result.Stderr)$($result.Log)"
    }
    $script:count++
    return $result
}

function Check-Error([string]$Name, [string]$Source, [string]$Diagnostic) {
    $result = Assemble $Source
    if ($result.ExitCode -ne 1 -or $result.Stderr -notmatch $Diagnostic -or
        $result.Stderr -notmatch 'Found \d+ error\(s\)' -or $result.Log -notmatch $Diagnostic) {
        throw "${Name}: expected an explicit layout error`n$($result.Stdout)$($result.Stderr)$($result.Log)"
    }
    $script:count++
}

try {
    $simple = @'
    org 0
start:
    if (end_label - start) < 128
        jr end_label
    else
        jp end_label
    endif
end_label:
    ret
'@
    Check 'Forward self-dependent condition' $simple '1800C9' | Out-Null
    $userFixture = Join-Path $PSScriptRoot 'test_error_if2\test1.asm'
    if (Test-Path $userFixture) {
        $reference = Join-Path $PSScriptRoot 'test_error_if2\ref_test1.asm.bin'
        $expected = [BitConverter]::ToString([System.IO.File]::ReadAllBytes($reference)).Replace('-', '')
        if ($expected -ne '1800C9') { throw 'test_error_if2 reference must contain JR + RET' }
        Check 'test_error_if2 fixture' ([System.IO.File]::ReadAllText(
            $userFixture, [System.Text.Encoding]::Default)) $expected | Out-Null
    }
    Check 'Detailed errors' $simple '1800C9' @('-EALL') | Out-Null
    $result = Check 'Hex output' $simple ([BitConverter]::ToString(
        [System.Text.Encoding]::ASCII.GetBytes(":030000001800C91C`n")).Replace('-', '')) @('-HEX')
    if ($result.Symbols -notmatch 'END_LABEL equ 02h') { throw 'Winner symbols were not published' }

    Check 'Nested dependent IF' @'
start:
    if (finish - start) < 128
        if (finish - start) < 127
            jr finish
        else
            jp finish
        endif
    else
        jp finish
    endif
finish:
    ret
'@ '1800C9' | Out-Null

    Check 'Multiple consistent layouts prefer short' ($simple.Replace('< 128', '== 2')) '1800C9' | Out-Null
    Check 'Mutually dependent IFs choose the global minimum' @'
start:
    if (finish - start) < 6
        jr finish
    else
        jp finish
    endif
    if (finish - start) < 6
        jr finish
    else
        jp finish
    endif
finish:
    ret
'@ '18021800C9' | Out-Null
    Check-Error 'Contradictory layouts' ($simple.Replace('< 128', '== 3')) 'No consistent, valid IF layout'
    Check-Error 'Undefined condition symbol' ($simple.Replace('(end_label - start) < 128', 'missing_symbol')) 'No consistent, valid IF layout'
    Check-Error 'Invalid selected instruction' ($simple.Replace('jr end_label', 'ld [1234], b')) 'No consistent, valid IF layout'

    Check 'Invalid shortest layout is rejected' @'
start:
    if (finish - start) == 130
        jr finish
    else
        jp finish
    endif
    space 128
finish:
    ret
'@ ('C38300' + ('00' * 128) + 'C9') | Out-Null

    foreach ($padding in @(127, 128)) {
        $source = @"
start:
    if (finish - start - 2) <= 127
        jr finish
    else
        jp finish
    endif
    space $padding
finish:
    ret
"@
        $prefix = if ($padding -eq 127) { '187F' } else { 'C38300' }
        Check "Forward JR boundary $padding" $source ($prefix + ('00' * $padding) + 'C9') | Out-Null
    }
    foreach ($padding in @(126, 127)) {
        $source = @"
start:
    space $padding
    if (start - `$ - 2) >= -128
        jr start
    else
        jp start
    endif
    ret
"@
        $suffix = if ($padding -eq 126) { '1880C9' } else { 'C30000C9' }
        Check "Backward JR boundary $padding" $source (('00' * $padding) + $suffix) | Out-Null
    }

    Check 'Independent macro invocations' @'
jump macro target
    if (target - $ - 2) >= -128 && (target - $ - 2) <= 127
        jr target
    else
        jp target
    endif
    endm
    jump near_label
near_label:
    nop
    jump far_label
    space 128
far_label:
    ret
'@ ('180000C38600' + ('00' * 128) + 'C9') | Out-Null

    Check 'Nested IF in macro with local labels' @'
jump_local macro padding
start:
    if (finish - start - 2) <= 127
        if (finish - start) < 128
            jr finish
        else
            jp finish
        endif
    else
        jp finish
    endif
    space padding
finish:
    ret
    endm
    jump_local 0
    jump_local 128
'@ ('1800C9C38600' + ('00' * 128) + 'C9') | Out-Null

    Check 'Macro calling another macro' @'
inner macro target
    if (target - $ - 2) <= 127
        jr target
    else
        jp target
    endif
    endm
outer macro target
    inner target
    endm
    outer finish
finish:
    ret
'@ '1800C9' | Out-Null

    Check 'ELSEIF chooses smallest consistent branch' @'
start:
    if (finish - start) == 4
        space 4
    elseif (finish - start) == 2
        space 2
    else
        space 3
    endif
finish:
    ret
'@ '0000C9' | Out-Null

    Check 'Empty selected branch without ELSE' @'
start:
    if (finish - start) == 1
        nop
    endif
finish:
    ret
'@ 'C9' | Out-Null

    Check 'Nested invalid inactive branch stays inactive' @'
start:
    if (finish - start) < 128
        jr finish
    else
        if missing_symbol
            ld [1234], b
        endif
    endif
finish:
    ret
'@ '1800C9' | Out-Null

    Check 'Conditional symbols do not leak from rejected branches' @'
start:
    if (finish - start) < 128
        value = 7
        jr finish
    else
        value = 9
        jp finish
    endif
finish:
    db value
'@ '180007' | Out-Null

    Check 'Command line defines survive candidate replay' ($simple.Replace('< 128', '< MAX_DISTANCE')) '1800C9' @('-DMAX_DISTANCE=128') | Out-Null

    Check 'Repeated macro expansions have independent IF choices' @'
jump macro target
    if (target - $ - 2) >= -128 && (target - $ - 2) <= 127
        jr target
    else
        jp target
    endif
    endm
    repeat i, 2
        jump finish
        space 64
    endr
finish:
    ret
'@ ('C38500' + ('00' * 64) + '1840' + ('00' * 64) + 'C9') | Out-Null

    Check 'Forward labels inside macro-local branches' @'
local_jump macro
start:
    if (finish - start) < 128
        jr finish
finish:
        ret
    else
        jp finish
finish:
        ret
    endif
    endm
    local_jump
    local_jump
'@ '1800C91800C9' | Out-Null

    Check 'Repeated local-label macro with per-expansion padding' @'
local_jump macro padding
start:
    if (finish - start - 2) <= 127
        jr finish
    else
        jp finish
    endif
    space padding
finish:
    ret
    endm
    repeat i, 2
        local_jump i * 128
    endr
'@ ('1800C9C38600' + ('00' * 128) + 'C9') | Out-Null

    $messages = $simple.Replace('jr end_label', "message `"winner`"`r`n        jr end_label").
        Replace('jp end_label', "message `"rejected`"`r`n        jp end_label")
    $result = Check 'Only winner emits messages' $messages '1800C9'
    if ([regex]::Matches($result.Stdout, 'MESSAGE: winner').Count -ne 1 -or
        $result.Stdout -match 'rejected') {
        throw 'Speculative messages escaped candidate evaluation'
    }

    [System.IO.File]::WriteAllText((Join-Path $work 'conditional.asm'),
        $simple, [System.Text.Encoding]::ASCII)
    Check 'Dependent IF in included source' "    org 0`r`n    include `"conditional.asm`"`r`n" '1800C9' | Out-Null

    $withinLimit = "    org 0`r`n"
    $limit = "    org 0`r`n"
    for ($i = 0; $i -lt 10; $i++) {
        $limit += @"
start$i`:
    if (finish$i - start$i) == 1
        nop
    else
        nop
        nop
    endif
finish$i`:

"@
        if ($i -eq 8) { $withinLimit = $limit + "    ret`r`n" }
    }
    Check '1023 candidate evaluations complete successfully' $withinLimit (('00' * 9) + 'C9') | Out-Null
    $limit += "    ret`r`n"
    Check-Error '1024-candidate limit' $limit 'IF layout search exceeded 1024 candidates'

    $ordinary = ''
    for ($i = 0; $i -lt 12; $i++) {
        $ordinary += "    if flag`r`n        nop`r`n    else`r`n        space 2`r`n    endif`r`n"
    }
    $ordinary += "flag = 1`r`n    ret`r`n"
    Check 'Ordinary forward conditions do not trigger combinatorial search' $ordinary (('00' * 12) + 'C9') | Out-Null

    $fixtureDirs = @('test_if', 'test_macro', 'test_macro2', 'test_repeat',
        'test_all_opecode', 'test_index_reg', 'test_one_operand', 'test_link', 'test_include')
    foreach ($directory in $fixtureDirs) {
        foreach ($source in Get-ChildItem (Join-Path $PSScriptRoot $directory) -Filter 'test*.asm') {
            $reference = Join-Path $source.DirectoryName ('ref_' + $source.Name + '.bin')
            if (-not (Test-Path $reference)) { continue }
            $fixtureWork = Join-Path $work ($directory + '-' + $source.BaseName)
            New-Item -ItemType Directory -Path $fixtureWork | Out-Null
            Copy-Item -Path (Join-Path $source.DirectoryName '*') -Destination $fixtureWork -Recurse
            $result = Assemble ([System.IO.File]::ReadAllText($source.FullName, [System.Text.Encoding]::Default)) @() $fixtureWork
            $expected = [System.IO.File]::ReadAllBytes($reference)
            $expectedExit = if ($expected.Length -eq 0) { 1 } else { 0 }
            if ($result.ExitCode -ne $expectedExit -or
                [BitConverter]::ToString($result.Bytes) -ne [BitConverter]::ToString($expected)) {
                throw "Existing fixture failed: $directory\$($source.Name)`n$($result.Stdout)$($result.Stderr)"
            }
            $count++
        }
    }
    Write-Output "Passed $count conditional layout and existing fixture cases."
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force
}
