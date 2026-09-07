# Detector de objetos — Android + Servidor Python (Sockets + YOLO)

> **Trabalho II — Sistemas Distribuídos (UFPI/CSHNB — 2026.2)**

App Android em Flutter captura uma foto e envia o JPEG por socket TCP a um servidor Python com YOLO.

- Padrão de commits: [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

## Conventional Commits

Mensagens no formato:

```
<type>[optional scope]: <description>
```

Tipos usados neste repositório:

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

Exemplos:

```
feat: adiciona tela inicial com ip, porta e resultado
feat: adiciona envio da imagem via socket tcp
docs: atualiza readme com fluxo do aplicativo
```

## Como rodar o app (Flutter)

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) e o Android Studio (SDK + aparelho ou emulador).
2. Confira com `flutter doctor`.
3. Na pasta `app/`:

```powershell
.\setup.ps1
flutter pub get
flutter run
```

O `setup.ps1` gera a pasta `android/` (se ainda não existir) e aplica:

- permissões de **câmera**, **internet** e leitura da galeria
- tráfego HTTP/TCP sem TLS (`usesCleartextTraffic` + `network_security_config`)

### IP e porta

| Onde | Padrão | Como mudar |
| --- | --- | --- |
| App | `192.168.0.10:5000` | campos **IP do servidor** e **Porta** na tela (ficam salvos no aparelho) |
| Servidor | `0.0.0.0:5000` | quem for do backend altera em `server/config.py` |

1. PC e celular na **mesma Wi-Fi**.
2. No PC, `ipconfig` → IPv4 (ex.: `192.168.0.15`).
3. No app, coloque esse IP e a porta `5000`.
4. Libere a porta **5000 TCP** no Firewall do Windows.
5. Emulador Android: use `10.0.2.2` no lugar do IP da máquina.

### Fluxo da demo

1. Informe IP e porta.
2. Toque em **Tirar e Analisar** (ou **Escolher da galeria** no emulador).
3. O app redimensiona a foto (largura máx. 1280, JPEG qualidade 80) e envia `4 bytes` (tamanho big-endian) + JPEG.
4. A resposta vem no mesmo framing (`4 bytes` + JSON ou texto).
5. A tela mostra *Pessoa detectada*, *Cadeira detectada*, etc., ou **Nada Detectado**.
6. Outra foto substitui o resultado.

Dependências em `pubspec.yaml`: `camera`, `image`, `image_picker`, `permission_handler`, `shared_preferences`.

```
app/lib/
├── main.dart
└── src/
    ├── app.dart
    ├── config.dart
    ├── camera/image_prep.dart
    ├── protocol/tcp_client.dart
    └── ui/
        ├── home_page.dart
        └── widgets/result_card.dart
```

## Servidor (`server/`)

Estrutura mínima para quem for implementar: `main.py`, `protocol.py`, `detector.py`, `config.py`. Dependências em `requirements.txt`.

O servidor é o único serviço em container (`server/Dockerfile` + `docker-compose.yml`). O YOLO roda **dentro** desse processo, não em um container separado. O app Flutter **não** é container: a demo é no Android (aparelho ou emulador), falando TCP com o servidor.

```bash
docker compose up --build
```
