# Claude Code eklentilerini kurar (mobil + tasarım).
$claude = 'C:\Users\bakib\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\claude-code\2.1.325\806e0a45e6f5\claude.exe'
$plugins = @(
  'ui-ux-pro-max@ui-ux-pro-max-skill',
  'frontend-design@claude-plugins-official',
  'firebase@claude-plugins-official',
  'flutter-all@flutter-claude-code',
  'ui-design@claude-code-workflows',
  'frontend-mobile-development@claude-code-workflows'
)
# (marketplace update atlandı: kaynaklar zaten indirilmiş)
foreach ($p in $plugins) {
  Write-Host "`n== $p ==" -ForegroundColor Yellow
  & $claude plugin install $p --scope user
}
Write-Host "`n== Kurulu eklentiler ==" -ForegroundColor Yellow
& $claude plugin list
