# 0003. SQLite como banco do servidor

- **Status:** Aceita
- **Data:** 2026-10-13

## Contexto

O servidor roda no PC de quem usa o sistema, normalmente sem conhecimento de
administração de banco. O volume de dados é pequeno: algumas dezenas de TVs,
playlists e agendamentos. As mídias ficam em arquivos, não no banco.

## Decisão

Usar **SQLite** via pacote `sqlite3`, num arquivo único em `data/beyond.db`.
Migrações SQL numeradas (`0001_init.sql`, …) ficam em
`apps/server/lib/src/db/migrations/` e são aplicadas automaticamente na
inicialização, registrando a versão em `PRAGMA user_version`.

## Consequências

- ✅ Zero configuração: o banco é criado na primeira execução.
- ✅ Backup = copiar a pasta `data/`.
- ✅ Testes rodam com banco em memória.
- ⚠️ Um único processo escreve no banco. Não há plano de rodar várias
  instâncias do servidor.
- ⚠️ O `sqlite3` usa a biblioteca nativa; no Windows ela precisa estar
  disponível (o pacote `sqlite3` cuida disso via build hooks).
