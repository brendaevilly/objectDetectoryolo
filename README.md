# Detector de objetos — Android + Servidor Python (Sockets + YOLO)

> **Trabalho II — Sistemas Distribuídos (UFPI/CSHNB — 2026.2)**

App Android em Flutter captura uma foto e envia o JPEG por socket TCP a um servidor Python com YOLO.

- Padrão de commits: [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

## Conventional Commits

Mensagens no formato:

```
<type>[optional scope]: <description>
```

| Tipo | Quando usar |
| --- | --- |
| `feat` | nova funcionalidade |
| `fix` | correção de bug |
| `docs` | só documentação |
| `style` | formatação, sem mudança de lógica |
| `refactor` | reorganização de código |
| `test` | testes |
| `chore` | tarefas de manutenção (deps, ignore, setup) |
| `build` | build e empacotamento |

```
feat: adiciona tela inicial com ip, porta e resultado
docs: descreve como rodar o aplicativo flutter
```

---

## Como rodar o app (Flutter)

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) no PATH (confira com `flutter doctor`)
- Android Studio com Android SDK (platform-tools + uma platform)
- Um **aparelho Android** com Depuração USB **ou** um emulador
- Servidor do grupo escutando na porta TCP **5000** (quem for do backend)

O aviso *Android license status unknown* no `flutter doctor` (Command-line Tools 23 + Flutter 3.47) pode ser ignorado se o `flutter run` instalar o APK.

Visual Studio (C++) **não** é necessário: este app é Android, não Windows desktop.

### Primeira vez (gera a pasta `android/`)

No PowerShell, na pasta `app/`:

```powershell
$env:Path = "$env:USERPROFILE\develop\flutter\bin;" + $env:Path
cd app
.\setup.ps1
flutter pub get
```

Se o terminal foi aberto **antes** de instalar o Flutter, o `setup.ps1` não acha o comando. Feche a aba, abra outra, ou prefixe o PATH como acima.

O `setup.ps1` cria o projeto Android (se faltar) e aplica:

- permissões de câmera, internet e galeria
- TCP sem TLS (`usesCleartextTraffic` + `network_security_config`) — exigido pelo enunciado

### Ligar no aparelho

1. USB + Depuração USB (autorize o computador no telefone).
2. `flutter devices` deve listar o aparelho.
3. Na pasta `app/`:

```powershell
flutter run
```

Deixe esse terminal aberto. Atalhos: `r` hot reload, `R` hot restart, `q` sair.

### IP e porta (celular físico)

Celular e PC na **mesma Wi-Fi**, sem VPN. No app, preencha os campos (eles ficam salvos no aparelho).

| Onde | Valor | Como descobrir / mudar |
| --- | --- | --- |
| App → IP | IPv4 da Wi-Fi do **PC** | no PC: `ipconfig` → adaptador Wi-Fi → IPv4 |
| App → Porta | `5000` | igual à porta do servidor |
| Servidor | bind `0.0.0.0:5000` | `server/config.py` ou `python main.py --port 5000` |

Não commite o IPv4 da sua casa/laboratório. O padrão do código é só um exemplo (`192.168.0.10`). Sempre ajuste na tela.

**Firewall (Windows), PowerShell como administrador:**

```powershell
New-NetFirewallRule -DisplayName "Detector YOLO TCP 5000" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
```

O servidor precisa estar **ligado** antes de *Tirar e Analisar*. Sem isso o app mostra erro de conexão — não é falha da câmera.

### Emulador

No emulador, o IP do PC é **`10.0.2.2`**, porta `5000`. Dá para usar **Escolher da galeria** se a câmera virtual não abrir.

### Fluxo da demo

1. Informe IP e porta.
2. Autorize a câmera.
3. **Tirar e Analisar** (ou galeria).
4. O app redimensiona (largura máx. 1280, JPEG qualidade 80) e envia `4 bytes` (tamanho big-endian) + JPEG.
5. A resposta usa o mesmo framing (`4 bytes` + JSON ou texto).
6. A tela mostra *Pessoa detectada*, *Cadeira detectada*, etc., ou **Nada Detectado**.
7. Outra foto substitui o resultado.

### Problemas comuns

| Sintoma | O que checar |
| --- | --- |
| `Flutter nao encontrado` | PATH / terminal novo / `$env:USERPROFILE\develop\flutter\bin` |
| Erro de conexão no app | servidor ligado, mesmo Wi-Fi, IPv4 certo, firewall 5000 TCP |
| `Unable to delete ... build` | pasta do projeto no OneDrive; rode um `flutter run` só; pause o sync da pasta `build` |
| Build do plugin `camera` | use `camera: ^0.12.1` (já no `pubspec.yaml`) |

Logs `AdrenoVK` / `Gralloc` no terminal são da GPU do aparelho e podem ser ignorados.

### O que não enviar ao GitHub

Não commite (já estão no `.gitignore` ou não devem ser adicionados):

- `.env`, chaves, `*.jks` / keystore
- `app/android/local.properties` (caminho local do SDK)
- `app/build/`, `.dart_tool/`, `.idea/`
- IPv4 real, prints com IP/SSID visível, fotos pessoais da pasta `received/`

O IPv4 se informa **só na tela do app**, na hora da demo.

```
app/lib/
├── main.dart
└── src/
    ├── app.dart
    ├── config.dart              # exemplo de IP/porta, 1280px, JPEG 80
    ├── camera/image_prep.dart
    ├── protocol/tcp_client.dart
    └── ui/
        ├── home_page.dart
        └── widgets/result_card.dart
```

Dependências: `camera`, `image`, `image_picker`, `permission_handler`, `shared_preferences`.

---

## Servidor (`server/`)

Estrutura para quem for do backend: `main.py`, `protocol.py`, `detector.py`, `config.py`. Dependências em `requirements.txt`.

O servidor é o único serviço em container (`server/Dockerfile` + `docker-compose.yml`). O YOLO roda **dentro** desse processo. O app Flutter **não** é container.

```bash
docker compose up --build
```
