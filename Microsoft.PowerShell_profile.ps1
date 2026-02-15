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

function gcr {
    git fetch --all --prune | Out-Null

    $branch = git for-each-ref --format="%(refname:short)" refs/heads refs/remotes/origin | fzf

    if ($branch) {
        if ($branch -like "origin/*") {
            $localBranch = $branch -replace "origin/", ""
            git switch -c $localBranch --track $branch 2>$null
        }
        else {
            git switch $branch
        }
    }
}

function gcl() {
    $branch = git branch | ForEach-Object { $_.Trim().Replace('* ', '') } | fzf
    if ($branch) {
        git switch $branch
    }
}

function dnb {
    $projects = @(Get-ChildItem -Filter *.csproj)

    if (-not $projects) {
        Write-Host "No .csproj file found"
        return
    }

    $project =
        if ($projects.Count -eq 1) {
            $projects[0].FullName
        }
        else {
            $projects.FullName | fzf
        }

    dotnet build $project --consoleloggerparameters:ForceConsoleColor 2>&1 | Select-String -notmatch 'warning'
}
