# Changelog

Todas as mudanças relevantes do projeto ficam registradas aqui.

O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e
o projeto usa [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não lançado]

## [0.4.0] — Fase 4: pareamento

### Adicionado

- Botão **Adicionar TV** no painel: gera um código de 6 caracteres válido por
  10 minutos e avisa quando a TV pareia.
- O servidor responde à descoberta por UDP broadcast (porta `8788/udp`,
  configurável com `--discovery-port`).
- `POST /api/v1/pair`: a TV troca o código por um token próprio. Códigos são
  de uso único e cada IP tem 5 tentativas por minuto.
- App da TV: procura servidores na rede, aceita IP manual e tem teclado na
  tela para digitar o código com o controle remoto (D-pad).
- A TV guarda as credenciais no armazenamento seguro do Android e, ao abrir
  de novo, já sabe que está pareada.
- Especificação do protocolo em `docs/protocolo.md`.

## [0.3.0] — Fase 3: autenticação do administrador

### Adicionado

- Configuração inicial: quem abre o painel pela primeira vez cria o
  administrador. Não existe senha padrão; a senha é guardada com bcrypt.
- Login e logout com sessão em cookie `HttpOnly` e `SameSite=Strict`, válida
  por 7 dias. O banco guarda só o hash do token.
- Limite de 5 logins errados por minuto por IP (resposta `429`).
- Requisições que alteram dados vindas de outra origem são recusadas
  (proteção contra CSRF).
- Dashboard com telas de configuração inicial, login e painel provisório.

## [0.2.0] — Fase 2: núcleo do servidor

### Adicionado

- Configuração do servidor por argumentos ou variáveis de ambiente: porta,
  pasta de dados, pasta do dashboard e nível de log (veja o `.env.example`).
- Banco SQLite em `data/beyond.db` com migrações versionadas e aplicadas na
  inicialização.
- Esquema inicial: configurações do servidor, administrador, sessões, grupos
  e TVs.
- Logs estruturados (logfmt) e erros da API padronizados em JSON.
- O servidor serve o dashboard compilado em `http://localhost:8787/`.

### Alterado

- O servidor passa a exigir Dart ≥ 3.10.

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
