# Changelog

Todas as mudanças relevantes do projeto ficam registradas aqui.

O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e
o projeto usa [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não lançado]

## [0.1.0] — Fase 1: esqueleto do monorepo

### Adicionado

- Workspace Dart na raiz, reunindo servidor, dashboard, app da TV e protocolo.
- Pacote `beyond_protocol` com o envelope de mensagens versionado.
- Servidor `shelf` com a rota `/health`.
- Dashboard Flutter Web vazio.
- App Flutter Android TV com manifesto *leanback* e banner.
- CI no GitHub Actions: formatação, análise, testes, APK de debug e gitleaks.
- Guia de como rodar cada app localmente no README.

## [0.0.0] — Fase 0: fundação do repositório

### Adicionado

- `.gitignore` com proteções para repositório público.
- Plano de desenvolvimento, README, licença MIT, `SECURITY.md` e
  `CONTRIBUTING.md`.
- ADRs 0001–0004 (Dart full-stack, workspace, SQLite e descoberta UDP).
- `.editorconfig` e templates de issue e PR.
