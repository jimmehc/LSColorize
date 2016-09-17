$script:lsColors = @{}

function Set-LSColor
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateScript({$script:lsColors.ContainsKey($_)})]
        [string]$Name,
        [Parameter(Position=1, Mandatory=$true)]
        [ScriptBlock]$Condition,
        [Parameter(Position=2, Mandatory=$true)]
        [ConsoleColor]$Color
    )

    $script:lsColors[$Name] = [pscustomobject]@{Color=$Color;Condition=$Condition}
}

function Add-LSColor
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Name,
        [Parameter(Position=1, Mandatory=$true)]
        [ScriptBlock]$Condition,
        [Parameter(Position=2, Mandatory=$true)]
        [ConsoleColor]$Color
    )

    if($script:lsColors.ContainsKey($Name))
    {
        Write-Error "The ls color with name, $Name, already exists.  Use Set-LSColor to set it to a new value."
        return
    }

    $script:lsColors[$Name] = [pscustomobject]@{Color=$Color;Condition=$Condition}
}

function Get-LSColor
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateScript({$script:lsColors.ContainsKey($_)})]
        [string]$Name
    )

    if(![string]::IsNullOrEmpty($Name))
    {
        $script:lsColors[$Name]
    }
    else
    {
        $script:lsColors
    }
}

function script:Get-LSColorForFile
{
    param ($fileInfo)
    $outColor = $host.UI.RawUI.ForegroundColor
    foreach($key in $lsColors.Keys)
    {
        $cond = $lsColors[$key].Condition
        $color = $lsColors[$key].Color
        if(Foreach-Object -InputObject $fileInfo -Process $cond)
        {
            $outColor = $color
            break
        }
    }
    $outColor
}

Add-LSColor Dir {$_.PSIsContainer} Blue
Add-LSColor Exec {$_.Extension -match '\.(exe|bat|cmd|ps1|psm1|vbs|rb|reg|dll|o|lib)'} Green
Add-LSColor Archive {$_.Extension -match '\.(zip|tar|gz|rar)'} Yellow
Add-LSColor Source {$_.Extension -match '\.(py|pl|cs|h|cpp)'} Cyan
Add-LSColor Text {$_.Extension -match '\.(txt|cfg|conf|ini|csv|log|xml)'} Red

function Get-ChildItemColored
{
    [CmdletBinding(DefaultParameterSetName='Items', SupportsTransactions=$true, HelpUri='http://go.microsoft.com/fwlink/?LinkID=113308')]
    param(
        [Parameter(ParameterSetName='Items', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName='LiteralItems', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath')]
        [string[]]
        ${LiteralPath},

        [Parameter(Position=1)]
        [string]
        ${Filter},

        [string[]]
        ${Include},

        [string[]]
        ${Exclude},

        [Alias('s')]
        [switch]
        ${Recurse},

        [uint32]
        ${Depth},

        [switch]
        ${Force},

        [switch]
        ${Name}
    )


    dynamicparam
    {
        try {
            $targetCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Get-ChildItem', [System.Management.Automation.CommandTypes]::Cmdlet, $PSBoundParameters)
            $dynamicParams = @($targetCmd.Parameters.GetEnumerator() | Microsoft.PowerShell.Core\Where-Object { $_.Value.IsDynamic })
            if ($dynamicParams.Length -gt 0)
            {
                $paramDictionary = [Management.Automation.RuntimeDefinedParameterDictionary]::new()
                foreach ($param in $dynamicParams)
                {
                    $param = $param.Value

                    if(-not $MyInvocation.MyCommand.Parameters.ContainsKey($param.Name))
                    {
                        $dynParam = [Management.Automation.RuntimeDefinedParameter]::new($param.Name, $param.ParameterType, $param.Attributes)
                        $paramDictionary.Add($param.Name, $dynParam)
                    }
                }
                return $paramDictionary
            }
        } catch {
            throw
        }
    }

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Get-ChildItem', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters | %{ Add-Member -InputObject $_ @{"__Color"=(script:Get-LSColorForFile $_)} -PassThru } }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Management\Get-ChildItem
    .ForwardHelpCategory Cmdlet

    #>
}

function global:Out-Default
{
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113362', RemotingCapability='None')]
    param(
        [switch]
        ${Transcript},

        [Parameter(ValueFromPipeline=$true)]
        [psobject]
        ${InputObject})

    begin
    {
        try {
            $colorLSItems = New-Object System.Collections.ArrayList
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Core\Out-Default', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            if($_.__Color)
            {
                $colorLSItems.Add($_) | Out-Null
            }
            else
            {
                $steppablePipeline.Process($_)
            }
        } catch {
            throw
        }
    }

    end
    {
        try {
            if($colorLSItems.Length -gt 0)
            {
                 Format-High -InputObject $colorLSItems Name -Print {
                    $fore = $host.UI.RawUI.ForegroundColor
                    if($args[1].__Color)
                    {
                        $host.UI.RawUI.ForegroundColor = $args[1].__Color
                    }
                    write-host "$($args[0])" -NoNewLine
                    $host.UI.RawUI.ForegroundColor = $fore
                }
            }
            else
            {
                $steppablePipeline.End()
            }
        } catch {
            throw
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Core\Out-Default
    .ForwardHelpCategory Cmdlet

    #>
}

if(Test-Path alias:ls)
{
    Write-Error "Alias 'ls' is defined.  Remove it with 'Remove-Item alias:ls -Force' before importing this module"
    return
}
Set-Alias ls Get-ChildItemColored

Export-ModuleMember -Function * -Alias *
