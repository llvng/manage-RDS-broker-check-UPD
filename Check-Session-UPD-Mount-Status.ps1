$sessions = Get-RDUserSession
$connected_users = @()
foreach($session in $sessions){
$objUser = New-Object System.Security.Principal.NTAccount($session.DomainName, $session.UserName)
$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
$SID = $strSID.Value
$user_object = ([PSCustomObject][Ordered]@{
User = $session.UserName
Server = $session.HostServer
State = $session.SessionState
LogonTime = $session.CreateTime
IdleTime = $session.IdleTime
SID = $SID
})
$connected_users += $user_object
}
$sessions_group = $sessions | Group HostServer,SessionState | ForEach-Object {
$server, $state = $_.Name -split ','
[PSCustomObject][Ordered]@{
Server = $server
State = $state
Count = $_.Count
}}
Write-Host "Found the following session counts:" -ForegroundColor Yellow
$sessions_group | Format-Table
foreach($server in ($sessions_group | Group Server).Name){
Write-Host "$($server) has: $(($sessions_group | ? {$_.Server -like $server} | Measure -Sum Count).Sum) sessions"
}
Write-Host "`nTotal sessions: $(($sessions_group | Measure -Sum Count).Sum)"



$multi_sessions = ($connected_users | Group User | ? {$_.Count -gt 1}).Name
foreach($session in $multi_sessions){
    Write-Host "The following user is currently logged onto to MORE THAN ONE SESSION: $($session)`n" -ForegroundColor Red
}

$all_open_files = Get-SmbOpenFile | ? {$_.Path -like "*.vhdx" -or $_.Path -like "*.VHDX"}
$open_files = $all_open_files.Path.Replace(".vhdx","").Replace(".VHDX","").Replace("U:\Users\UVHD-","") | Select -Unique
$locked_upds= @()
foreach ($upd_sid in $open_files){
$SID_to_Check = New-Object System.Security.Principal.SecurityIdentifier($upd_sid)
$user = ($SID_to_Check.Translate([System.Security.Principal.NTAccount])).Value
$user_object = ([PSCustomObject][Ordered]@{
User = $User
SID = $upd_sid
})
$locked_upds += $user_object
}

$comparison = Compare-Object -DifferenceObject $connected_users.SID -ReferenceObject $locked_upds.SID -IncludeEqual | Group SideIndicator

if($comparison.Name -contains "=>"){
foreach($diff in $comparison | ? {$_.Name -eq "=>"}){
foreach($sid in $diff.Group.InputObject){
$SID_to_Check = New-Object System.Security.Principal.SecurityIdentifier($sid)
$user = ($SID_to_Check.Translate([System.Security.Principal.NTAccount])).Value
$server = ($connected_users | ? {$_.SID -eq $sid}).Server
Write-Host "This user has an active RD Session but their UPD is NOT mounted: $($user)
They are currently logged onto $($server)`n" -ForegroundColor Yellow
}
}}else{Write-Host "`nNo sessions found WITHOUT their UPDs mounted." -ForegroundColor Green}

if($comparison.Name -contains "<="){
foreach($diff in $comparison | ? {$_.Name -eq "<="}){
foreach($sid in $diff.Group.InputObject){
$SID_to_Check = New-Object System.Security.Principal.SecurityIdentifier($sid)
$user = ($SID_to_Check.Translate([System.Security.Principal.NTAccount])).Value
Write-Host "This user does NOT have an active RD Session but their UPD IS mounted: $($user)"
}
}
}else{Write-Host "No UPDs found mounted WITHOUT an Active Session.`n"-ForegroundColor Green}
Pause