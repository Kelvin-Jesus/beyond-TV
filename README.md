# Beyond TV

Sistema de *digital signage* **auto-hospedado** para redes locais. Com ele você
controla várias TVs Android a partir de um painel web que roda no seu próprio PC.

> 🚧 **Em desenvolvimento.** Acompanhe o progresso em
> [docs/PLANO_DE_DESENVOLVIMENTO.md](docs/PLANO_DE_DESENVOLVIMENTO.md).

## Como funciona

1. Você roda o **servidor Beyond TV** no PC e abre o **dashboard** no navegador.
2. Instala o **app Beyond TV** (APK) em cada TV Android.
3. No dashboard, clica em **Adicionar TV** e recebe um código.
4. Digita esse código na TV. Pronto, ela está pareada.
5. Agora você escolhe o que cada TV exibe: sites e dashboards, imagens, vídeos e
   playlists. Também dá para agendar conteúdos por horário.

## Componentes

| Pasta | O que é | Tecnologia |
|-------|---------|------------|
| `apps/server` | API, tempo real, descoberta na rede | Dart (shelf) + SQLite |
| `apps/dashboard` | Painel de administração | Flutter Web |
| `apps/tv` | Player para Android TV | Flutter (Android) |
| `packages/beyond_protocol` | Modelos compartilhados | Dart |

## Rodando localmente

Pré-requisitos: Flutter SDK (stable, Dart ≥ 3.6) e, para o app da TV, Android
SDK com o emulador Android TV. Detalhes na
[seção 14 do plano](docs/PLANO_DE_DESENVOLVIMENTO.md#14-ambiente-de-desenvolvimento).

```sh
flutter pub get        # na raiz: resolve todo o workspace de uma vez
```

| O quê | Comando | Resultado |
|-------|---------|-----------|
| Servidor | `dart run apps/server/bin/server.dart` | `http://localhost:8787/health` |
| Dashboard | `cd apps/dashboard && flutter run -d chrome` | Abre o painel no Chrome |
| App da TV | `cd apps/tv && flutter run` | Instala no emulador/TV conectada |
| APK de debug | `cd apps/tv && flutter build apk --debug` | `apps/tv/build/app/outputs/flutter-apk/` |
| Análise | `flutter analyze` (na raiz) | Analisa todos os pacotes |
| Testes | `dart test` ou `flutter test` dentro de cada pacote | |

O servidor aceita `--port`, `--data-dir` e `--log-level` (ou as variáveis
`BEYOND_PORT`, `BEYOND_DATA_DIR` e `BEYOND_LOG_LEVEL`, veja o
[.env.example](.env.example)). Use
`dart run apps/server/bin/server.dart --help` para ver todas as opções.

### Problemas conhecidos no Windows

- **Caminho com acento ou espaço** (ex.: `Área de Trabalho`): o `dart test`
  falha com *"package_config.json did not contain its own root package"* e o
  Gradle também costuma se perder. Clone o projeto num caminho simples, como
  `C:\dev\beyond-TV`, ou crie uma unidade virtual:

  ```powershell
  subst X: "C:\caminho\com\acento"   # depois trabalhe a partir de X:\
  subst X: /D                         # remove a unidade
  ```

- **NDK ausente** (*"sdkmanager did not install NDK …"*): instale a versão
  pedida no erro pelo Android Studio (*SDK Manager → SDK Tools → NDK*) ou por
  linha de comando, com aspas por causa do `;`:

  ```powershell
  sdkmanager --sdk_root=<pasta-do-sdk> "ndk;<versão>"
  ```

## Privacidade

Tudo roda **na sua rede local**. O projeto não usa nuvem nem telemetria e não
envia dados a terceiros.

## Contribuindo

Veja o [CONTRIBUTING.md](CONTRIBUTING.md). Para relatar uma falha de
segurança, siga o [SECURITY.md](SECURITY.md).

## Licença

Distribuído sob a licença [MIT](LICENSE).
