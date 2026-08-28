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

function gmb {
    $branch = git branch | ForEach-Object { $_.Trim().Replace('* ', '') } | fzf
    if ($branch) {
        git merge $branch
    }
}

function gdb {
    param(
        [switch]$f
    )

    $branch = git branch | ForEach-Object { $_.Trim().Replace('* ', '') } | fzf
    if ($branch) {
        if ($f) {
           git branch -D $branch
        } else {
           git branch -d $branch
        }
    }
}

function gfb {
    $branch = git branch --show-current

    if (-not $branch) {
        Write-Host "Not on a branch."
        return
    }

    git fetch origin $branch
}

function gpb {
    $branch = git branch --show-current

    if (-not $branch) {
        Write-Host "Not on a branch."
        return
    }

    git pull --rebase origin $branch
}

function git-check-commits {

    $exist = @()
    $notExist = @()

    foreach ($c in $args) {

        git merge-base --is-ancestor $c HEAD *> $null

        if ($LASTEXITCODE -eq 0) {
            $exist += $c
        }
        else {
            $notExist += $c
        }
    }

    echo "================="
    echo "exist in current branch:"
    $exist
    echo "================="
    echo "not exist:"
    $notExist
    echo "================="
}

function glg {
    git log --graph --decorate --date=format:'%Y-%m-%d' --pretty=format:"%C(yellow)%h%Creset %C(cyan)%an%Creset %s %C(green)%ad%Creset%C(auto)%d%Creset"
}

function glo {
    git log --oneline
}

function gshow() {
    $selected = git log `
        --date=format:'%Y-%m-%d' `
        --pretty=format:'%H|%h|%an|%ad|%s' |
        fzf `
            --no-sort `
            --delimiter='|' `
            --with-nth=2,3,4,5 `
            --preview "git show --stat --color=always {1}" `
            --preview-window=right:60%

    if ($selected) {
        $hash = ($selected -split '\|')[0]
        git show -m --color=always $hash
    }
}

function touch {
    Param([string]$Path)
    if (Test-Path $Path) {
        (Get-Item $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path
    }
}

function gdf {
    $files = @(
        git status --short |
            ForEach-Object {
                $_.Substring(3)
            } |
            Sort-Object -Unique
    )

    if (-not $files) {
        Write-Host "No modified or untracked files."
        return
    }

    # Use git diff for tracked files.
    # For untracked files, show their contents.
    #
    # We use PowerShell's $input to receive the filename from fzf.
    $previewCommand = 'git diff --color=always HEAD -- "{}"'

    $selected = $files | fzf `
        --ansi `
        "--preview=$previewCommand" `
        '--preview-window=right:60%' `
        '--bind=ctrl-d:preview-half-page-down' `
        '--bind=ctrl-u:preview-half-page-up'

    if (-not $selected) {
        return
    }

    # Clear-Host

    $tracked = git ls-files --error-unmatch -- $selected 2>$null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Untracked: $selected" -ForegroundColor Yellow
        Write-Host ""
        Get-Content -LiteralPath $selected
    }
    else {
        git -c color.ui=always diff HEAD -- $selected
    }
}
