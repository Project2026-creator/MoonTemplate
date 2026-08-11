param(
  [ValidateRange(1, 1000)]
  [int]$Iterations = 10
)

$ErrorActionPreference = "Stop"
$items = "lexer, parser, engine, cli, tests, docs, release"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le $Iterations; $i++) {
  & moon run src/cli --target native -- `
    --file examples/benchmark.txt `
    --var "title=MoonBit" `
    --var "enabled=true" `
    --var "items=$items" *> $null
  if ($LASTEXITCODE -ne 0) {
    throw "Benchmark iteration $i failed with exit code $LASTEXITCODE"
  }
}

$stopwatch.Stop()
$totalMs = $stopwatch.Elapsed.TotalMilliseconds
$averageMs = $totalMs / $Iterations
Write-Output "benchmark=cli-native-file-render"
Write-Output "iterations=$Iterations"
Write-Output ("total_ms={0:N3}" -f $totalMs)
Write-Output ("average_ms={0:N3}" -f $averageMs)
