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
feat(app): add capture and analyze button
fix(server): handle incomplete TCP payload
docs: add IP and port setup
```

## App (`app/`)

Dependências em `pubspec.yaml`: `camera`, `image`, `image_picker`, `permission_handler`, `shared_preferences`.

```
app/lib/
├── main.dart
└── src/
    ├── app.dart
    ├── config.dart                 # IP/porta, 1280px, JPEG 80
    ├── camera/image_prep.dart      # redimensionar + compactar
    ├── protocol/tcp_client.dart    # dart:io Socket
    └── ui/
        ├── home_page.dart          # Tirar e Analisar
        └── widgets/result_card.dart
```

```powershell
cd app
.\setup.ps1
flutter pub get
flutter run
```

IP e porta: campos na tela (padrão em `config.dart`). Celular e PC na mesma Wi-Fi; em emulador use `10.0.2.2`.

## Servidor (`server/`)

Estrutura mínima para quem for implementar: `main.py`, `protocol.py`, `detector.py`, `config.py`. Dependências em `requirements.txt`.
