# ==============================================================================
# SCRIPT DE DEBLOAT - WINDOWS 10 (LABORATÓRIOS IFF)
# ==============================================================================
# Este script foi projetado para otimizar o desempenho das máquinas do IFF.
# Ele executa de forma silenciosa e deve ser rodado como ADMINISTRADOR.
# ==============================================================================

# Garante que o script está rodando com privilégios de Administrador.
# Caso contrário, ele tentará reabrir a si mesmo solicitando a elevação do UAC.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Este script precisa ser executado como Administrador. Tentando elevar privilégios..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Começando a Otimização de Desempenho (Debloat) - IFF W10" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. REMOÇÃO E DESATIVAÇÃO COMPLETA DO ONEDRIVE
# ------------------------------------------------------------------------------
# POR QUÊ: Em laboratórios de informática, múltiplos perfis de novos alunos são 
# criados constantemente. O instalador padrão do OneDrive roda em cada novo login,
# consumindo CPU, memória e banda de internet, além de atrasar o login inicial.
# ------------------------------------------------------------------------------
Write-Host "`n[+] Removendo e desativando o OneDrive..." -ForegroundColor Yellow

# Finaliza processos ativos do OneDrive e Explorer para evitar bloqueio de arquivos
taskkill.exe /F /IM "OneDrive.exe" 2>$null
taskkill.exe /F /IM "explorer.exe" 2>$null

# Executa desinstalador nativo do OneDrive (tanto em sistemas de 32-bit quanto 64-bit)
if (Test-Path "$env:systemroot\System32\OneDriveSetup.exe") {
    Start-Process -FilePath "$env:systemroot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -NoNewWindow
}
if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
    Start-Process -FilePath "$env:systemroot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -NoNewWindow
}

# Remove pastas residuais do OneDrive para liberar espaço físico no disco
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:programdata\Microsoft OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:systemdrive\OneDriveTemp"
if ((Get-ChildItem "$env:userprofile\OneDrive" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:userprofile\OneDrive"
}

# Desativa a sincronização de arquivos do OneDrive via registro do sistema (GPO)
$GPOPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
if (-not (Test-Path $GPOPath)) { New-Item -Path $GPOPath -Force | Out-Null }
Set-ItemProperty -Path $GPOPath -Name "DisableFileSyncNGSC" -Type DWord -Value 1 -ErrorAction SilentlyContinue

$GPOPath32 = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive"
if (-not (Test-Path $GPOPath32)) { New-Item -Path $GPOPath32 -Force | Out-Null }
Set-ItemProperty -Path $GPOPath32 -Name "DisableFileSyncNGSC" -Type DWord -Value 1 -ErrorAction SilentlyContinue

# Oculta o ícone do OneDrive no painel de navegação (barra lateral) do Explorador de Arquivos
New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Scope Global -Name "HKCR" | Out-Null
$ClsidPath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $ClsidPath) {
    Set-ItemProperty -Path $ClsidPath -Name "System.IsPinnedToNameSpaceTree" -Type DWord -Value 0 -ErrorAction SilentlyContinue
}
$ClsidPath32 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $ClsidPath32) {
    Set-ItemProperty -Path $ClsidPath32 -Name "System.IsPinnedToNameSpaceTree" -Type DWord -Value 0 -ErrorAction SilentlyContinue
}
Remove-PSDrive "HKCR"

# Remove o hook do registro padrão do Windows (NTUSER.DAT) para que o OneDrive
# não se auto-instale para nenhum novo usuário que fizer logon na máquina
try {
    reg load "hku\Default" "C:\Users\Default\NTUSER.DAT" 2>$null
    reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f 2>$null
    reg unload "hku\Default" 2>$null
} catch {
    Write-Host "Aviso: Não foi possível desativar o gancho do OneDrive no registro NTUSER.DAT (pode estar em uso)." -ForegroundColor DarkYellow
}

# Reinicia o Explorador de Arquivos para aplicar as alterações visuais
Start-Process "explorer.exe"
Write-Host "[OK] OneDrive removido e desativado com sucesso." -ForegroundColor Green

# ------------------------------------------------------------------------------
# 2. REMOÇÃO DE APLICATIVOS INÚTEIS (UWP BLOATWARE)
# ------------------------------------------------------------------------------
# POR QUÊ: O Windows 10 vem com dezenas de jogos e apps pré-instalados (ex: Candy Crush,
# Xbox, Skype). Removê-los e retirar a sua provisão impede que consumam memória RAM
# em segundo plano e reduz o tempo de carregamento de novos perfis de alunos.
# ------------------------------------------------------------------------------
Write-Host "`n[+] Removendo aplicativos inúteis do sistema (UWP Bloatware)..." -ForegroundColor Yellow

$bloatApps = @(
    # Aplicativos Microsoft sem utilidade no contexto acadêmico do laboratório
    "Microsoft.549981C3F5F10", # Cortana
    "Microsoft.3DBuilder",
    "Microsoft.BingFinance",
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MixedReality.Portal",
    "Microsoft.Office.OneNote",
    "Microsoft.Office.Sway",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.XboxApp",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic", # Groove Music
    "Microsoft.ZuneVideo", # Filmes e TV
    
    # Redes sociais, streaming e jogos pré-instalados por padrão
    "Amazon.com.Amazon",
    "Clipchamp.Clipchamp",
    "Facebook",
    "Instagram",
    "SpotifyAB.SpotifyMusic",
    "TikTok",
    "Twitter",
    "Netflix",
    "PrimeVideo",
    "CandyCrush",
    "DisneyMagicKingdoms",
    "BubbleWitch"
)

foreach ($app in $bloatApps) {
    # Verifica se o aplicativo está instalado nos perfis ou provisionado na imagem
    $package = Get-AppxPackage -AllUsers -Name "*$app*" -ErrorAction SilentlyContinue
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like "*$app*"

    if ($package -or $provisioned) {
        Write-Host " -> Removendo: $app..." -ForegroundColor DarkGray
        
        # Desinstala o aplicativo de todos os usuários existentes
        if ($package) {
            Get-AppxPackage -AllUsers -Name "*$app*" | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        }
        
        # Remove o provimento do aplicativo (impede que ele seja instalado para novos usuários)
        if ($provisioned) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$app*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "[OK] Aplicativos UWP desnecessários desinstalados e desprovisionados." -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. DESATIVAÇÃO DE SERVIÇOS DE ALTO IMPACTO E TELEMETRIA
# ------------------------------------------------------------------------------
# POR QUÊ: Serviços de telemetria enviam dados em segundo plano, consumindo processamento
# e rede. O serviço SysMain (Superfetch) é o maior causador de 100% de uso de disco em
# computadores com HDDs mecânicos. O Xbox e os Mapas são dispensáveis em ambientes acadêmicos.
# ------------------------------------------------------------------------------
Write-Host "`n[+] Configurando serviços do sistema (Desativando Gargalos)..." -ForegroundColor Yellow

$servicesToDisable = @(
    # Telemetria e coleta de dados
    "DiagTrack",        # Experiências do Usuário Conectado e Telemetria
    "dmwappushservice",  # Serviço de Roteamento de Mensagens Push do WAP
    "diagnosticshub.standardcollector.service", # Coletor Padrão do Hub de Diagnóstico
    
    # Serviços de alto consumo que geram lentidão no disco
    "SysMain",          # SysMain / Superfetch (Evita gargalo de disco 100%)
    "MapsBroker",       # Gerenciador de Mapas Baixados
    "RetailDemo",       # Serviço de Demonstração de Varejo (Loja)
    
    # Serviços relacionados a jogos (Xbox) desnecessários no laboratório
    "XblAuthManager",
    "XblGameSave",
    "XboxGipSvc",
    "XboxNetApiSvc"
)

foreach ($service in $servicesToDisable) {
    if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
        $displayName = (Get-Service -Name $service).DisplayName
        Write-Host " -> Desativando serviço: $service ($displayName)..." -ForegroundColor DarkGray
        
        # Para a execução do serviço imediatamente
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        
        # Desativa o início automático do serviço
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
    }
}
Write-Host "[OK] Serviços de telemetria, jogos e alto consumo de disco desativados." -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. DESATIVAÇÃO DE TAREFAS AGENDADAS DE TELEMETRIA E COLETA DE DADOS
# ------------------------------------------------------------------------------
# POR QUÊ: O Windows possui diversas tarefas agendadas que rodam silenciosamente 
# em segundo plano para coletar dados de telemetria, hábitos de uso e enviar à 
# Microsoft. Desativá-las economiza ciclos de processamento (CPU) e melhora a 
# privacidade e o desempenho do sistema nos computadores do laboratório.
# ------------------------------------------------------------------------------
Write-Host "`n[+] Desativando tarefas agendadas de telemetria e coleta de dados..." -ForegroundColor Yellow

$tasksToDisable = @(
    # Telemetria do Office
    "\Microsoft\Office\OfficeTelemetryAgentLogOn",
    "\Microsoft\Office\OfficeTelemetryAgentFallBack",
    "\Microsoft\Office\Office 15 Subscription Heartbeat",
    
    # Telemetria e diagnóstico do Windows (Customer Experience Improvement Program)
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\Uploader",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    
    # Sensores de localização, mapas e outros
    "\Microsoft\Windows\Location\Notifications",
    "\Microsoft\Windows\Location\WindowsActionDialog",
    "\Microsoft\Windows\Maps\MapsToastTask",
    "\Microsoft\Windows\Maps\MapsUpdateTask",
    
    # Controle parental e demonstração de varejo
    "\Microsoft\Windows\Retail Demo\CleanupOfflineContent",
    "\Microsoft\Windows\Shell\FamilySafetyMonitor",
    "\Microsoft\Windows\Shell\FamilySafetyRefreshTask",
    "\Microsoft\Windows\Shell\FamilySafetyUpload"
)

foreach ($taskPath in $tasksToDisable) {
    $taskName = Split-Path -Path $taskPath -Leaf
    $parent = Split-Path -Path $taskPath -Parent
    if ($parent -notlike "*\") { $parent += "\" }
    
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath $parent -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host " -> Desativando tarefa agendada: $taskPath..." -ForegroundColor DarkGray
        $task | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
    }
}
Write-Host "[OK] Tarefas agendadas de telemetria e coleta de dados desativadas." -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. DESATIVAÇÃO DE HIBERNAÇÃO E INICIALIZAÇÃO RÁPIDA (FAST STARTUP)
# ------------------------------------------------------------------------------
# POR QUÊ: Em computadores de laboratório, desligamentos limpos diários são essenciais 
# para evitar o acúmulo de bugs de memória e instabilidades. A Inicialização Rápida 
# impede que o Windows desligue completamente, salvando o estado do sistema no disco. 
# Desativar a hibernação remove o arquivo hiberfil.sys, liberando gigabytes de espaço 
# em disco (igual à quantidade de RAM instalada), o que é ideal para SSDs menores.
# ------------------------------------------------------------------------------
Write-Host "`n[+] Desativando hibernação e Inicialização Rápida..." -ForegroundColor Yellow
if (Get-Command "powercfg.exe" -ErrorAction SilentlyContinue) {
    powercfg.exe /hibernate off
    Write-Host "[OK] Hibernação desativada e hiberfil.sys removido." -ForegroundColor Green
} else {
    Write-Host "Aviso: Utilitário powercfg.exe não encontrado." -ForegroundColor DarkYellow
}

# ------------------------------------------------------------------------------
# 6. DESATIVAÇÃO DE PESQUISA NA WEB (BING) NO MENU INICIAR
# ------------------------------------------------------------------------------
# POR QUÊ: Quando alunos pesquisam programas locais no menu Iniciar (como VS Code ou Word), 
# o Windows tenta buscar resultados na web pelo Bing. Isso gera lentidão na busca local, 
# consome banda de internet desnecessariamente e afeta o desempenho do sistema.
# ------------------------------------------------------------------------------
Write-Host "`n[+] Desativando pesquisa na web no menu Iniciar..." -ForegroundColor Yellow

# Configura diretiva de grupo via registro para desativar a busca na web pelo menu iniciar
$SearchPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (-not (Test-Path $SearchPolicyPath)) { 
    New-Item -Path $SearchPolicyPath -Force | Out-Null 
}
Set-ItemProperty -Path $SearchPolicyPath -Name "DisableWebSearch" -Type DWord -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $SearchPolicyPath -Name "ConnectedSearchUseWeb" -Type DWord -Value 0 -ErrorAction SilentlyContinue

Write-Host "[OK] Pesquisa na web no menu Iniciar desativada com sucesso." -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " Otimizações concluídas com sucesso! Reinicie a máquina." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

