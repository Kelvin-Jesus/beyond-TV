# Contribuindo com o Beyond TV

Obrigado pelo interesse! Este guia resume como trabalhar no projeto. As decisões
completas estão no [plano de desenvolvimento](docs/PLANO_DE_DESENVOLVIMENTO.md).

## Antes de começar

1. Leia a [seção 10 do plano](docs/PLANO_DE_DESENVOLVIMENTO.md#10-segurança--repositório-público).
   O repositório é **público**: nada da sua rede ou das suas credenciais pode
   entrar no git.
2. Configure o e-mail *noreply* do GitHub neste repositório:

   ```sh
   git config user.email "ID+usuario@users.noreply.github.com"
   ```

3. Instale o Flutter SDK (stable, Dart ≥ 3.6). Os detalhes estão na
   [seção 14 do plano](docs/PLANO_DE_DESENVOLVIMENTO.md#14-ambiente-de-desenvolvimento).

## Fluxo de trabalho

- A `main` está sempre estável. Cada fase do roadmap é desenvolvida em
  `fase/NN-nome` e entra na `main` por Pull Request.
- Correções pontuais podem usar `fix/descricao-curta`.
- Preencha o template do PR com o que foi feito e **como testar**.

## Commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/pt-br/), em
português e no imperativo:

```
feat(server): gera códigos de pareamento com expiração de 10 min
```

- **Tipos**: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `build`,
  `perf`, `style`.
- **Escopos**: `server`, `dashboard`, `tv`, `protocol`, `repo`, `docs`, `ci`.
- Um commit faz uma coisa. Código e teste da mesma funcionalidade vão juntos.

## Checklist antes do commit

- [ ] `dart analyze` (ou `flutter analyze`) sem avisos.
- [ ] Testes passando (`dart test` / `flutter test`).
- [ ] `git diff --staged` revisado: sem `.env`, `data/`, keystores, IPs reais ou
      URLs internas.
- [ ] Documentação atualizada no mesmo commit, se o comportamento mudou.

## Segurança

Encontrou uma vulnerabilidade? Siga o [SECURITY.md](SECURITY.md). Não abra issue
pública.
