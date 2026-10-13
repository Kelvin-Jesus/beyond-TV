# Política de segurança

## Versões suportadas

O Beyond TV ainda está em desenvolvimento (`0.x`). Apenas a versão mais recente
da branch `main` recebe correções de segurança.

| Versão | Suportada |
|--------|-----------|
| `main` (última) | ✅ |
| Anteriores | ❌ |

## Como reportar uma vulnerabilidade

**Não abra uma issue pública** para relatar falhas de segurança.

Use o recurso
[*Report a vulnerability*](https://github.com/abiass/beyond-TV/security/advisories/new)
do GitHub (aba **Security → Advisories**). O relato fica privado entre você e os
mantenedores.

Inclua, se possível:

- componente afetado (`server`, `dashboard`, `tv` ou `protocol`);
- versão ou commit;
- passos para reproduzir;
- impacto esperado (ex.: acesso ao dashboard sem login, leitura de arquivos).

Respondemos em até **7 dias**. Depois da correção publicada, o relato pode ser
divulgado com os devidos créditos, se você quiser.

## Escopo

O Beyond TV foi pensado para rodar **numa rede local confiável**. Algumas
limitações são conhecidas e aceitas no MVP:

- o tráfego entre servidor, dashboard e TVs usa HTTP sem TLS;
- a descoberta por UDP broadcast responde a qualquer dispositivo da sub-rede.

Esses pontos estão descritos na
[seção 10 do plano](docs/PLANO_DE_DESENVOLVIMENTO.md#10-segurança--repositório-público).
Relatos sobre eles são bem-vindos se mostrarem um impacto além do documentado.

## Nunca publique dados reais

Ao reportar ou contribuir, não inclua IPs reais da sua rede, URLs internas,
tokens, senhas ou prints com dados de dashboards. Use `192.168.0.10` e
`example.local` nos exemplos.
