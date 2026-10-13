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

## Privacidade

Tudo roda **na sua rede local**. O projeto não usa nuvem nem telemetria e não
envia dados a terceiros.

## Contribuindo

Veja o [CONTRIBUTING.md](CONTRIBUTING.md). Para relatar uma falha de
segurança, siga o [SECURITY.md](SECURITY.md).

## Licença

Distribuído sob a licença [MIT](LICENSE).
