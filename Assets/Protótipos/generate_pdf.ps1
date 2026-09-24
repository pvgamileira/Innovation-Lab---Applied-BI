$ErrorActionPreference = 'Stop'
Write-Host "Starting Vite dev server..."
$process = Start-Process -FilePath "npx.cmd" -ArgumentList "vite --port 4173" -PassThru -NoNewWindow
Write-Host "Waiting for Vite to start..."
Start-Sleep -Seconds 10

Write-Host "Running Puppeteer script..."
node generate_pdf.js

Write-Host "Killing Vite..."
Stop-Process -Id $process.Id -Force
Write-Host "Done!"
