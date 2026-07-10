Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Action
  )
  Write-Host "==> $Name"
  & $Action
  if ($LASTEXITCODE -ne 0) {
    throw "Step failed: $Name (exit code $LASTEXITCODE)"
  }
}

function Test-NativeCompiler {
  foreach ($name in @("cl", "gcc", "clang", "cc")) {
    if (Get-Command $name -ErrorAction SilentlyContinue) {
      return $true
    }
  }
  return $false
}

Push-Location (Split-Path -Parent $PSScriptRoot)
try {
  Invoke-Step "moon fmt --check" { moon fmt --check }
  Invoke-Step "moon info" {
    moon info
    git diff --exit-code -- src/moontemplate/pkg.generated.mbti
  }
  Invoke-Step "moon check --deny-warn" { moon check --deny-warn }
  Invoke-Step "moon test --deny-warn" { moon test --deny-warn }
  Invoke-Step "repository compliance report" { python scripts/check_repo_compliance.py }

  if (Test-NativeCompiler) {
    Invoke-Step "native CLI smoke test" {
      moon run src/cli --target native -- --template "Hello {{ name | uppercase }}" --var name=moonbit
    }
  } else {
    Write-Warning "Skipping native CLI smoke test because no system C compiler was found on this machine."
  }
}
finally {
  Pop-Location
}
