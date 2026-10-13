# Architecture Decision Records

Cada decisão relevante de arquitetura vira um arquivo `NNNN-titulo.md` com
**contexto**, **decisão** e **consequências**. Uma ADR aceita não é editada:
se a decisão mudar, crie outra ADR que a substitua e marque a antiga como
*Substituída por NNNN*.

| # | Título | Status |
|---|--------|--------|
| [0001](0001-dart-full-stack.md) | Dart em todas as camadas | Aceita |
| [0002](0002-pub-workspaces.md) | Monorepo com pub workspaces | Aceita |
| [0003](0003-sqlite.md) | SQLite como banco do servidor | Aceita |
| [0004](0004-descoberta-udp.md) | Descoberta do servidor por UDP broadcast | Aceita |

## Modelo

```markdown
# NNNN. Título

- **Status:** Proposta | Aceita | Substituída por NNNN
- **Data:** AAAA-MM-DD

## Contexto
## Decisão
## Consequências
```
