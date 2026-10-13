# 0002. Monorepo com pub workspaces

- **Status:** Aceita
- **Data:** 2026-10-13

## Contexto

Servidor, dashboard, app da TV e o pacote de protocolo evoluem juntos. Uma
mudança no protocolo precisa ser validada nas três pontas no mesmo PR.

## Decisão

Um único repositório usando **pub workspaces** (Dart ≥ 3.6): o `pubspec.yaml`
da raiz lista os pacotes em `workspace:` e cada pacote declara
`resolution: workspace`. Existe um único `pubspec.lock` na raiz.

O Melos fica opcional, apenas se scripts agregados se tornarem necessários.

## Consequências

- ✅ Recurso nativo do Dart, sem ferramenta extra para instalar.
- ✅ Versões de dependências consistentes entre os pacotes.
- ✅ `dart pub get` na raiz resolve tudo de uma vez.
- ⚠️ Todos os pacotes precisam aceitar as mesmas versões de dependências em
  comum, o que pode exigir atualizações coordenadas.
