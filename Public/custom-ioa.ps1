function Edit-FalconIoaGroup {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/entities/rule-groups/v1:patch')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:patch', Mandatory = $true,
            ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, Position = 1)]
        [ValidatePattern('^\w{32}$')]
        [string] $Id,

        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:patch', Position = 2)]
        [string] $Name,

        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:patch', Position = 3)]
        [boolean] $Enabled,

        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:patch', Position = 4)]
        [string] $Description,

        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:patch', Position = 5)]
        [string] $Comment
    )
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = $PSBoundParameters
            Format   = @{
                Body = @{
                    root = @('description', 'rulegroup_version', 'name', 'enabled', 'id', 'comment')
                }
            }
        }
        ($Param.Format.Body.root | Where-Object { $_ -ne 'id' }).foreach{
            # When not provided, add required fields using existing policy settings
            if (!$Param.Inputs.$_) {
                if (!$Existing) {
                    $Existing = Get-FalconIoaGroup -Ids $Param.Inputs.id -ErrorAction 'SilentlyContinue'
                }
                if ($Existing) {
                    $Value = if ($_ -eq 'rulegroup_version') {
                        $Existing.version
                    } else {
                        $Existing.$_
                    }
                    $PSBoundParameters[$_] = $Value
                }
            }
        }
        Invoke-Falcon @Param
    }
}
function Edit-FalconIoaRule {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/entities/rules/v1:patch')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:patch', Mandatory = $true, Position = 1)]
        [ValidatePattern('^\w{32}$')]
        [string] $RulegroupId,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:patch', Position = 2)]
        [array] $RuleUpdates,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:patch', Position = 3)]
        [string] $Comment
    )
    begin {
        $Fields = @{
            RuleGroupId = 'rulegroup_id'
            RuleUpdates = 'rule_updates'
        }
    }
    process {
        if ($PSBoundParameters.RuleUpdates) {
            # Filter 'rule_updates' to required fields
            $RuleRequired = @('instance_id', 'pattern_severity', 'enabled', 'disposition_id', 'name',
                'description', 'comment', 'field_values')
            $FieldRequired = @('name', 'label', 'type', 'values')
            [array] $PSBoundParameters.RuleUpdates = ,(
                @($PSBoundParameters.RuleUpdates | Select-Object $RuleRequired).foreach{
                    $_.field_values = $_.field_values | Select-Object $FieldRequired
                    $_
                }
            )
        }
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = Update-FieldName -Fields $Fields -Inputs $PSBoundParameters
            Format   = @{
                Body = @{
                    root = @('rulegroup_id', 'comment', 'rule_updates', 'rulegroup_version')
                }
            }
        }
        ($Param.Format.Body.root | Where-Object { $_ -ne 'rule_updates' }).foreach{
            # When not provided, add required fields using existing policy settings
            if (!$Param.Inputs.$_) {
                if (!$Existing) {
                    $Existing = Get-FalconIoaGroup -Ids $Param.Inputs.rulegroup_id -ErrorAction 'SilentlyContinue'
                }
                if ($Existing) {
                    $Value = if ($_ -eq 'rulegroup_version') {
                        $Existing.version
                    } else {
                        $Existing.$_
                    }
                    $PSBoundParameters[$_] = $Value
                }
            }
        }
        Invoke-Falcon @Param
    }
}
function Get-FalconIoaGroup {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/queries/rule-groups/v1:get')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:get', Mandatory = $true, Position = 1)]
        [ValidatePattern('^\w{32}$')]
        [array] $Ids,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups/v1:get', Position = 1)]
        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups-full/v1:get', Position = 1)]
        [ValidateScript({
            Test-FqlStatement $_ @('enabled','platform','name','description','rules.action_label','rules.name',
            'rules.description','rules.pattern_severity','rules.ruletype_name','rules.enabled','created_on',
            'modified_on')
        })]
        [string] $Filter,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups/v1:get', Position = 2)]
        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups-full/v1:get', Position = 2)]
        [string] $Query,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups/v1:get', Position = 3)]
        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups-full/v1:get', Position = 3)]
        [ValidateSet('created_by.asc','created_by.desc','created_on.asc','created_on.desc','description.asc',
            'description.desc','enabled.asc','enabled.desc','modified_by.asc','modified_by.desc',
            'modified_on.asc','modified_on.desc','name.asc','name.desc')]
        [string] $Sort,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups/v1:get', Position = 4)]
        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups-full/v1:get', Position = 4)]
        [ValidateRange(1,500)]
        [int] $Limit,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups/v1:get', Position = 5)]
        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups-full/v1:get', Position = 5)]
        [int] $Offset,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups-full/v1:get', Mandatory = $true)]
        [switch] $Detailed,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups/v1:get')]
        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups-full/v1:get')]
        [switch] $All,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-groups/v1:get')]
        [switch] $Total
    )
    begin {
        $Fields = @{
            Query = 'q'
        }
    }
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = Update-FieldName -Fields $Fields -Inputs $PSBoundParameters
            Format   = @{
                Query = @('limit', 'ids', 'sort', 'q', 'offset', 'filter')
            }
        }
        @(Invoke-Falcon @Param).foreach{
            if ($_.version -and $null -eq $_.version) {
                $_.version = 0
            }
            $_
        }
    }
}
function Get-FalconIoaPlatform {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/queries/platforms/v1:get')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/platforms/v1:get', Mandatory = $true, Position = 1)]
        [ValidateSet('windows', 'mac', 'linux')]
        [array] $Ids,

        [Parameter(ParameterSetName = '/ioarules/queries/platforms/v1:get', Position = 2)]
        [ValidateRange(1,500)]
        [int] $Limit,

        [Parameter(ParameterSetName = '/ioarules/queries/platforms/v1:get', Position = 3)]
        [int] $Offset,

        [Parameter(ParameterSetName = '/ioarules/queries/platforms/v1:get')]
        [switch] $Detailed,

        [Parameter(ParameterSetName = '/ioarules/queries/platforms/v1:get')]
        [switch] $All,

        [Parameter(ParameterSetName = '/ioarules/queries/platforms/v1:get')]
        [switch] $Total
    )
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = $PSBoundParameters
            Format   = @{
                Query = @('ids', 'offset', 'limit')
            }
        }
        Invoke-Falcon @Param
    }
}
function Get-FalconIoaRule {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/queries/rules/v1:get')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rules/GET/v1:post', Mandatory = $true, Position = 1)]
        [array] $Ids,

        [Parameter(ParameterSetName = '/ioarules/queries/rules/v1:get', Position = 1)]
        [ValidateScript({
            Test-FqlStatement $_ @('enabled','platform','name','description','rules.action_label','rules.name',
            'rules.description','rules.pattern_severity','rules.ruletype_name','rules.enabled','created_on',
            'modified_on')
        })]
        [string] $Filter,

        [Parameter(ParameterSetName = '/ioarules/queries/rules/v1:get', Position = 2)]
        [string] $Query,

        [Parameter(ParameterSetName = '/ioarules/queries/rules/v1:get', Position = 3)]
        [ValidateSet('rules.created_by.asc','rules.created_by.desc','rules.created_on.asc',
            'rules.created_on.desc','rules.current_version.action_label.asc',
            'rules.current_version.action_label.desc','rules.current_version.description.asc',
            'rules.current_version.description.desc','rules.current_version.modified_by.asc',
            'rules.current_version.modified_by.desc','rules.current_version.modified_on.asc',
            'rules.current_version.modified_on.desc','rules.current_version.name.asc',
            'rules.current_version.name.desc','rules.current_version.pattern_severity.asc',
            'rules.current_version.pattern_severity.desc','rules.enabled.asc','rules.enabled.desc',
            'rules.ruletype_name.asc','rules.ruletype_name.desc')]
        [string] $Sort,

        [Parameter(ParameterSetName = '/ioarules/queries/rules/v1:get', Position = 4)]
        [ValidateRange(1,500)]
        [int] $Limit,

        [Parameter(ParameterSetName = '/ioarules/queries/rules/v1:get', Position = 5)]
        [int] $Offset,

        [Parameter(ParameterSetName = '/ioarules/queries/rules/v1:get')]
        [switch] $Detailed,

        [Parameter(ParameterSetName = '/ioarules/queries/rules/v1:get')]
        [switch] $All,

        [Parameter(ParameterSetName = '/ioarules/queries/rules/v1:get')]
        [switch] $Total
    )
    begin {
        $Fields = @{
            Query = 'q'
        }
    }
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = Update-FieldName -Fields $Fields -Inputs $PSBoundParameters
            Format   = @{
                Query = @('limit', 'sort', 'q', 'offset', 'filter')
                Body  = @{
                    root = @('ids')
                }
            }
        }
        Invoke-Falcon @Param
    }
}
function Get-FalconIoaSeverity {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/queries/pattern-severities/v1:get')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/pattern-severities/v1:get', Mandatory = $true,
            Position = 1)]
        [ValidatePattern('^(critical|high|medium|low|informational)$')]
        [array] $Ids,

        [Parameter(ParameterSetName = '/ioarules/queries/pattern-severities/v1:get', Position = 1)]
        [ValidateRange(1,500)]
        [int] $Limit,

        [Parameter(ParameterSetName = '/ioarules/queries/pattern-severities/v1:get', Position = 2)]
        [int] $Offset,

        [Parameter(ParameterSetName = '/ioarules/queries/pattern-severities/v1:get')]
        [switch] $Detailed,

        [Parameter(ParameterSetName = '/ioarules/queries/pattern-severities/v1:get')]
        [switch] $All,

        [Parameter(ParameterSetName = '/ioarules/queries/pattern-severities/v1:get')]
        [switch] $Total
    )
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = $PSBoundParameters
            Format   = @{
                Query = @('ids', 'offset', 'limit')
            }
        }
        Invoke-Falcon @Param
    }
}
function Get-FalconIoaType {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/queries/rule-types/v1:get')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rule-types/v1:get', Mandatory = $true, Position = 1)]
        [ValidatePattern('^\d{1,2}$')]
        [array] $Ids,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-types/v1:get', Position = 2)]
        [ValidateRange(1,500)]
        [int] $Limit,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-types/v1:get', Position = 3)]
        [int] $Offset,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-types/v1:get')]
        [switch] $Detailed,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-types/v1:get')]
        [switch] $All,

        [Parameter(ParameterSetName = '/ioarules/queries/rule-types/v1:get')]
        [switch] $Total
    )
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = $PSBoundParameters
            Format   = @{
                Query = @('ids', 'offset', 'limit')
            }
        }
        Invoke-Falcon @Param
    }
}
function New-FalconIoaGroup {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/entities/rule-groups/v1:post')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:post', Mandatory = $true, Position = 1)]
        [ValidateSet('windows', 'mac', 'linux')]
        [string] $Platform,

        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:post', Mandatory = $true, Position = 2)]
        [string] $Name,

        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:post', Position = 3)]
        [string] $Description,

        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:post', Position = 4)]
        [string] $Comment
    )
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = $PSBoundParameters
            Format   = @{
                Body = @{
                    root = @('description', 'platform', 'name', 'comment')
                }
            }
        }
        Invoke-Falcon @Param
    }
}
function New-FalconIoaRule {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/entities/rules/v1:post')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:post', Mandatory = $true, Position = 1)]
        [ValidatePattern('^\w{32}$')]
        [string] $RulegroupId,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:post', Mandatory = $true, Position = 2)]
        [string] $Name,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:post', Mandatory = $true, Position = 3)]
        [ValidateSet('critical', 'high', 'medium', 'low', 'informational')]
        [string] $PatternSeverity,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:post', Mandatory = $true, Position = 4)]
        [ValidateSet(1, 2, 5, 6, 9, 10, 11, 12)]
        [string] $RuletypeId,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:post', Mandatory = $true, Position = 5)]
        [ValidateSet(10, 20, 30)]
        [int32] $DispositionId,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:post', Mandatory = $true, Position = 6)]
        [array] $FieldValues,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:post')]
        [string] $Description,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:post')]
        [string] $Comment
    )
    begin {
        $Fields = @{
            DispositionId   = 'disposition_id'
            FieldValues     = 'field_values'
            PatternSeverity = 'pattern_severity'
            RulegroupId     = 'rulegroup_id'
            RuletypeId      = 'ruletype_id'
        }
    }
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = Update-FieldName -Fields $Fields -Inputs $PSBoundParameters
            Format   = @{
                Body = @{
                    root = @('rulegroup_id', 'disposition_id', 'comment', 'description', 'pattern_severity',
                        'ruletype_id', 'field_values', 'name')
                }
            }
        }
        Invoke-Falcon @Param
    }
}
function Remove-FalconIoaGroup {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/entities/rule-groups/v1:delete')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:delete', Mandatory = $true, Position = 1)]
        [ValidatePattern('^\w{32}$')]
        [array] $Ids,

        [Parameter(ParameterSetName = '/ioarules/entities/rule-groups/v1:delete', Position = 2)]
        [string] $Comment
    )
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = $PSBoundParameters
            Format   = @{
                Query = @('ids', 'comment')
            }
        }
        Invoke-Falcon @Param
    }
}
function Remove-FalconIoaRule {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/entities/rules/v1:delete')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:delete', Mandatory = $true, Position = 1)]
        [ValidatePattern('^\w{32}$')]
        [string] $RuleGroupId,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:delete', Mandatory = $true, Position = 2)]
        [array] $Ids,

        [Parameter(ParameterSetName = '/ioarules/entities/rules/v1:delete')]
        [string] $Comment
    )
    begin {
        $Fields = @{
            RuleGroupId = 'rule_group_id'
        }
    }
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = Update-FieldName -Fields $Fields -Inputs $PSBoundParameters
            Format   = @{
                Query = @('ids', 'rule_group_id', 'comment')
            }
        }
        Invoke-Falcon @Param
    }
}
function Test-FalconIoaRule {
    [CmdletBinding(DefaultParameterSetName = '/ioarules/entities/rules/validate/v1:post')]
    param(
        [Parameter(ParameterSetName = '/ioarules/entities/rules/validate/v1:post', Mandatory = $true,
            Position = 1)]
        [array] $Fields
    )
    process {
        $Param = @{
            Command  = $MyInvocation.MyCommand.Name
            Endpoint = $PSCmdlet.ParameterSetName
            Inputs   = $PSBoundParameters
            Format   = @{
                Body = @{
                    root = @('fields')
                }
            }
        }
        Invoke-Falcon @Param
    }
}