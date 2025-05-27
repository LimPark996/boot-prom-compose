# PowerShell version of test.sh

$success_count = 0
$fail_count = 0

# 10,000번 반복 실행
for ($i = 1; $i -le 10000; $i++) {
    # 50% 확률로 랜덤 선택
    $random = Get-Random -Minimum 0 -Maximum 2

    if ($random -eq 1) {
        # 50% 확률로 정상 엔드포인트 호출
        try {
            Invoke-WebRequest -Uri "http://localhost:8080/counted" -Method Get -UseBasicParsing | Out-Null
            $success_count++
            Write-Host "[$i/10000] Success: counted endpoint (Total: $success_count)" -ForegroundColor Green
        }
        catch {
            Write-Host "[$i/10000] Failed to call counted endpoint" -ForegroundColor Red
        }
    }
    else {
        # 50% 확률로 에러 엔드포인트 호출
        try {
            Invoke-WebRequest -Uri "http://localhost:8080/error" -Method Get -UseBasicParsing | Out-Null
            $fail_count++
            Write-Host "[$i/10000] Failure: error endpoint (Total: $fail_count)" -ForegroundColor Yellow
        }
        catch {
            $fail_count++
            Write-Host "[$i/10000] Failure: error endpoint (Total: $fail_count)" -ForegroundColor Yellow
        }
    }

    # 1초 대기 (너무 빠른 요청 방지)
    Start-Sleep -Seconds 1
}

Write-Host "Test complete: $success_count successes, $fail_count failures." -ForegroundColor Cyan

# 실제 메트릭이 생성되었는지 확인
Write-Host "Checking Prometheus metrics..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/prometheus" -Method Get -UseBasicParsing
    $metrics = $response.Content | Select-String "give_me_money_total"
    if ($metrics) {
        Write-Host "Found metrics:" -ForegroundColor Green
        $metrics | ForEach-Object { Write-Host $_.Line -ForegroundColor Green }
    }
    else {
        Write-Host "No give_me_money_total metrics found" -ForegroundColor Red
    }
}
catch {
    Write-Host "Failed to retrieve metrics: $($_.Exception.Message)" -ForegroundColor Red
}