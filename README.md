# Debloat IFF Windows 10

Este projeto tem como objetivo desenvolver um script em PowerShell para otimizar o desempenho das máquinas com Windows 10 dos laboratórios do IFF (Instituto Federal Fluminense). O script desinstala programas desnecessários (bloatware) e desativa configurações que consomem recursos de forma desnecessária, executando de forma silenciosa e no modo administrador.

---

## Estrutura do Projeto

* [debloat.ps1](file://wsl.localhost/Ubuntu/home/vinicius/debloat-iff-w10/debloat.ps1): Script principal em PowerShell que unifica e realiza as ações de limpeza, desinstalação de bloatwares UWP, remoção de OneDrive e otimização de serviços pesados.
* [specs/llm-specs.md](file://wsl.localhost/Ubuntu/home/vinicius/debloat-iff-w10/specs/llm-specs.md): Especificações gerais do projeto.
* [Win-Debloat-Tools-main/](file://wsl.localhost/Ubuntu/home/vinicius/debloat-iff-w10/Win-Debloat-Tools-main): Repositório/pasta de referência que serve como guia para a criação do nosso script.

---

## O que o script faz atualmente?

1. **Remoção e Desativação do OneDrive**:
   * Encerra processos ativos (`OneDrive.exe` e `explorer.exe`).
   * Executa a desinstalação silenciosa do OneDrive.
   * Remove pastas temporárias e residuais.
   * Desativa a sincronização via Diretiva de Grupo (GPO/Registro).
   * Oculta o ícone do OneDrive no Explorador de Arquivos.
   * Remove a inicialização automática do OneDrive para novos perfis criados no sistema (editando a colmeia padrão `NTUSER.DAT`).
2. **Remoção de Aplicativos Inúteis (UWP Bloatware)**:
   * Desinstala e desprovisiona (bloqueia reinstalação automática) apps como Cortana, Xbox, Skype, jogos pré-instalados (Candy Crush, Disney Magic Kingdoms), redes sociais (TikTok, Facebook, Instagram) e streamings (Spotify, Netflix).
3. **Desativação de Serviços de Alto Impacto e Telemetria**:
   * Desativa serviços de telemetria e diagnósticos (`DiagTrack`, `dmwappushservice`, etc.).
   * Desativa o serviço `SysMain` (antigo Superfetch) para evitar 100% de uso de disco.
   * Desativa serviços do Xbox e de mapas desnecessários no ambiente escolar.
4. **Desativação de Tarefas Agendadas de Telemetria e Coleta de Dados**:
   * Desativa diversas tarefas agendadas nativas do Windows e do Office que realizam coleta de dados, diagnósticos e telemetria em segundo plano, liberando CPU e melhorando a privacidade.
5. **Desativação de Hibernação e Inicialização Rápida**:
   * Desativa a hibernação, o que remove o arquivo `hiberfil.sys` e libera gigabytes de espaço em disco.
   * Desativa a Inicialização Rápida para garantir desligamentos limpos e reinicializações frescas diariamente nos laboratórios.
6. **Desativação de Pesquisa na Web no Menu Iniciar**:
   * Bloqueia pesquisas na web (Bing) a partir do Menu Iniciar, tornando as pesquisas instantâneas e puramente locais, além de economizar banda de internet da instituição.

---

## Como Executar o Script

Por padrão, o Windows impede a execução de scripts do PowerShell não assinados devido à política de execução de segurança. Além disso, o script de debloat precisa de privilégios elevados (Administrador) para modificar configurações do sistema e remover softwares nativos.

Siga os passos abaixo para executar o script:

### 1. Abrir o PowerShell como Administrador
1. Pressione a tecla `Windows` ou clique no menu Iniciar.
2. Digite **PowerShell**.
3. Clique com o botão direito em **Windows PowerShell** e selecione **Executar como Administrador**.

### 2. Navegar até a pasta do projeto
No console do PowerShell, navegue até a pasta onde este projeto está localizado:
```powershell
cd "C:\caminho\para\debloat-iff-w10"
```
*(Nota: Substitua `C:\caminho\para\debloat-iff-w10` pelo caminho real da pasta no seu computador).*

### 3. Executar o Script ignorando a Política de Execução
Para executar o script de teste ignorando a restrição de políticas temporariamente apenas para esta execução, execute o seguinte comando:
```powershell
powershell -ExecutionPolicy Bypass -File .\debloat.ps1
```

O comando acima faz o seguinte:
* `powershell`: Abre uma nova sessão do PowerShell.
* `-ExecutionPolicy Bypass`: Ignora temporariamente a política de restrição de execução de scripts para que o `debloat.ps1` possa rodar.
* `-File .\debloat.ps1`: Indica qual arquivo de script deve ser executado.

### Resultado Esperado
O console exibirá o progresso de cada etapa em cores e avisará para reiniciar o computador ao terminar. Exemplo:
```text
============================================================
 Começando a Otimização de Desempenho (Debloat) - IFF W10
============================================================

[+] Removendo e desativando o OneDrive...
...
[OK] OneDrive removido e desativado com sucesso.

[+] Removendo aplicativos inúteis do sistema (UWP Bloatware)...
...
[OK] Aplicativos UWP desnecessários desinstalados e desprovisionados.

[+] Configurando serviços do sistema (Desativando Gargalos)...
...
[OK] Serviços de telemetria, jogos e alto consumo de disco desativados.

[+] Desativando tarefas agendadas de telemetria e coleta de dados...
...
[OK] Tarefas agendadas de telemetria e coleta de dados desativadas.

============================================================
 Otimizações concluídas com sucesso! Reinicie a máquina.
============================================================
```

