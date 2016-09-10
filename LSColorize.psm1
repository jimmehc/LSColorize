
function Invoke-ColorizedLS
{
    Invoke-Expression "get-childitem $args" | Format-High Name -Print {    
        $item = $args
        $fore = $host.UI.RawUI.ForegroundColor        
        $ANSICode = ""
        $host.UI.RawUI.ForegroundColor = .{     
            if ($item[1].psIsContainer) {'Blue'}
#            elseif ($item[1].Extension -match '\.(exe|bat|cmd|ps1|psm1|vbs|rb|reg|dll|o|lib)') {'Green'}
            elseif ($item[1].Extension -match '\.(zip|tar|gz|rar)') {'Yellow'}
            elseif ($item[1].Extension -match '\.(py|pl|cs|rb|h|cpp|ps1)') {'Cyan'}
            elseif ($item[1].Extension -match '\.(txt|cfg|conf|ini|csv|log|xml)') {'Red'}
            else {$fore}
        }

        # Make code/executables/libraries green and bold, if ConEmu is set up right...
        if ($item[1].Extension -match '\.(exe|bat|cmd|ps1|psm1|vbs|rb|reg|dll|o|lib)')
        {
            $ANSICode = "$([char]27)[32;42;1m";
        }

        write-host "$ANSICode$($args[0])" -NoNewLine
        $host.UI.RawUI.ForegroundColor = $fore
    }
}

function Invoke-ls 
{
    # This could be better...
	if($MyInvocation.PipelinePosition -ne $MyInvocation.PipelineLength)
	{
		iex "Get-ChildItem $args";
	}
	else
	{
		iex "Invoke-ColorizedLS $args";
	}
}

if(Test-Path alias:ls)
{
    Write-Error "Alias 'ls' is defined.  Remove it with 'Remove-Item alias:ls -Force' before importing this module"
    return
}
Set-Alias ls Invoke-ls
Set-Alias hi Invoke-ls

Export-ModuleMember -Function * -Alias *
