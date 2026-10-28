param (
    [Parameter(Mandatory=$true, HelpMessage="Enter the email address of the compromised user")]
    [string]$UserEmail
)

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " INITIATING LOCKDOWN FOR: $UserEmail" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Generate a memorable secure temporary password
$adjectives = @("Brave", "Calm", "Bright", "Quick", "Cool", "Neat", "Fast", "Smart", "Happy", "Solid")
$nouns = @("Tiger", "River", "Apple", "Falcon", "Ocean", "Rocket", "Forest", "Eagle", "Planet", "Mountain")

$adj = Get-Random -InputObject $adjectives
$noun = Get-Random -InputObject $nouns
$num = Get-Random -Minimum 10 -Maximum 99
$TempPassword = "$adj$noun$num!"

# 2. Reset password and force change on next login
Write-Host "[1/5] Resetting password..."
gam update user $UserEmail password $TempPassword changepassword on

# 3. Terminate active web sessions
Write-Host "[2/5] Resetting login cookies (Web Sign-out)..."
gam user $UserEmail signout

# 4. Revoke OAuth tokens and Mobile Apps
Write-Host "[3/5] Revoking tokens (Mobile App Deprovision)..."
gam user $UserEmail deprovision

Write-Host "`n>> USER LOCKED OUT SUCCESSFULLY <<" -ForegroundColor Green
Write-Host ">> Give the user this temporary password: $TempPassword `n" -ForegroundColor Green

# 5. Run Security Checks
Write-Host "[4/5] Checking for unauthorized forwarding rules..."
$forwardingFile = "Forwarding_$($UserEmail).csv"
gam user $UserEmail print forwardingaddresses > $forwardingFile

Write-Host "[5/5] Checking for unauthorized account delegates..."
$delegatesFile = "Delegates_$($UserEmail).csv"
gam user $UserEmail print delegates > $delegatesFile

# 6. Display the Security Audit Results
Write-Host "`n================ SECURITY AUDIT RESULTS ================" -ForegroundColor Yellow

Write-Host "`n--- Forwarding Rules ---" -ForegroundColor Cyan
if ((Get-Item $forwardingFile).length -gt 10) {
    Import-Csv $forwardingFile | Format-Table -AutoSize
    Write-Host "WARNING: Review the above forwarding rules. If unauthorized, delete them immediately." -ForegroundColor Red
} else {
    Write-Host "Clear: No forwarding rules found." -ForegroundColor Green
}

Write-Host "`n--- Account Delegates ---" -ForegroundColor Cyan
if ((Get-Item $delegatesFile).length -gt 10) {
    Import-Csv $delegatesFile | Format-Table -AutoSize
    Write-Host "WARNING: Review the above delegates. If unauthorized, delete them immediately." -ForegroundColor Red
} else {
    Write-Host "Clear: No delegated accounts found." -ForegroundColor Green
}

Write-Host "`nAudit complete. Raw logs saved to your current directory."
