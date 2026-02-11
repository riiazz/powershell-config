Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

$global:__LastPath = ""

Register-EngineEvent PowerShell.OnIdle -Action {
    $current = Split-Path -Leaf (Get-Location)
    if ($current -ne $global:__LastPath) {
        $host.UI.RawUI.WindowTitle = $current
        $global:__LastPath = $current
    }
} | Out-Null

oh-my-posh init pwsh --config "$HOME\Documents\oh-my-posh\cobalt2.omp.json" | Invoke-Expression

function gcr() {
    $branch = git branch --all | ForEach-Object { $_.Trim().Replace('* ', '') } | fzf
    if ($branch) {
        git switch $branch
    }
}

function gcl() {
    $branch = git branch | ForEach-Object { $_.Trim().Replace('* ', '') } | fzf
    if ($branch) {
        git switch $branch
    }
}
