# 0001. Dart em todas as camadas

- **Status:** Aceita
- **Data:** 2026-10-13

## Contexto

O Beyond TV tem três partes: servidor local, dashboard web e app Android TV. O
app da TV precisa de WebView, player de vídeo e navegação por D-pad, e o
Flutter atende bem a isso. As três partes trocam as mesmas mensagens
(manifesto de conteúdo, comandos, status), e manter esses modelos duplicados em
linguagens diferentes gera divergência.

## Decisão

Usar **Dart em tudo**:

- servidor em Dart puro com `shelf`;
- dashboard em Flutter Web;
- app da TV em Flutter (Android);
- modelos e mensagens num pacote compartilhado, `packages/beyond_protocol`.

## Consequências

- ✅ Um único idioma e um único conjunto de ferramentas (`dart analyze`,
  `dart test`).
- ✅ O protocolo é definido uma vez e checado pelo compilador nas três pontas.
- ✅ O servidor compila para um executável nativo (`dart compile exe`), sem
  runtime para instalar no PC.
- ⚠️ O ecossistema de servidor em Dart é menor que o de Node/Go; bibliotecas
  mais específicas podem precisar ser escritas.
- ⚠️ O Flutter Web gera um bundle maior que um SPA tradicional. Para um painel
  administrativo na LAN, isso é aceitável.
