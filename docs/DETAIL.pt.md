> 状态: rascunho (草稿) · 归属: wave1 · 更新: 2026-11-25 · 里程碑: M5

# kore-plugins

Este repositório publica apenas `index/plugins.json` (e sua assinatura ed25519 `plugins.json.sig`), `index/versions.lock.json`, `presets/*.json` e a página estática `market/`, com scripts de validação. O índice responde apenas “quais plugins, qual versão, tamanho e resumo”; não prova que um pacote é confiável: o kore recalcula o sha256 localmente e compara. A raiz de confiança é a chave pública compilada no kore mais o cálculo local. Sem revisão, sem contas, funciona offline (G-10).

Idioma: [简体中文](DETAIL.md) · [English](DETAIL.en.md) · [Español](DETAIL.es.md) · [Français](DETAIL.fr.md) · [Deutsch](DETAIL.de.md) · [Русский](DETAIL.ru.md) · [Português](DETAIL.pt.md)

## O que faz

- **Canal de descoberta, não fonte de confiança**: o `sha256` / `download_url` do índice só é verificado antes da instalação; a raiz de confiança é a chave pública compilada no kore mais o recálculo local.
- **Cadeia de assinatura**: `plugins.json.sig` é uma assinatura ed25519 bruta de 64 bytes, reassinada pelo mantenedor na fonte autoritativa; o CI verifica em camadas — PR apenas esquema, push main/tag verificação completa; assinatura ausente ou inválida = FAIL. A chave privada nunca entra no repositório nem nos segredos do CI.
- **Registro de versões**: `versions.lock.json` é somente acréscimo; um sha por `id@version`; alterar um pacote exige bump de versão.
- **Oito predefinições**: `minimal` / `dev` / `web-lite` / `web-pro` / `db-only` / `gateway` / `security` / `full`; `out_of_box=true` não deve ativar plugins basic (G-20).
- **Mercado estático**: `market/index.html` abre offline, sem framework, CDN ou links http(s); `market/plugins.js` é incorporado na compilação por `build-market.sh`.
- **Portões de validação**: `make check` = `validate-index.sh` + `validate-presets.sh` (verificação completa por padrão); `KORE_INDEX_SKIP_SIG=1` apenas para esquema em PR.

## Início rápido

```bash
KORE_INDEX_SKIP_SIG=1 make check   # PR: apenas esquema / registro / referências de predefinições
bash scripts/validate-index.sh     # validação completa (inclui assinatura ed25519)
bash scripts/validate-presets.sh   # validação de predefinições
bash scripts/build-market.sh       # reconstruir market/plugins.js
```

Após alterar `plugins.json`, o mantenedor deve reassinar na fonte autoritativa com a chave privada da máquina de release (`KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh`) e enviar conteúdo e `.sig` no mesmo commit; a chave privada nunca entra no repositório nem no CI.

## Segurança e limites

Relate falsificação do índice, cadeia de assinatura ou supply chain por [SECURITY.md](../SECURITY.md) (confirmação em 72 h / divulgação coordenada em 90 dias); não abra issues públicas. **A chave privada fica com o mantenedor, nunca no repositório ou em segredos do CI; o CI apenas verifica, nunca assina.** A troca da chave pública deve sair junto com o núcleo kore e manter um ciclo de compatibilidade de rotação.

## Mapa da documentação

- [SECURITY.md](../SECURITY.md) — processo de divulgação; cadeia de assinatura e rotação estão no README.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — entradas do índice, registro de versões, predefinições e convenções de commit.
- [CHANGELOG.md](../CHANGELOG.md) — histórico do índice e versões dos plugins.
- [index/plugins.json](../index/plugins.json) — entradas atuais (fonte da verdade).
- [index/versions.lock.json](../index/versions.lock.json) — registro de versões (somente acréscimos).
- [Documentação do protocolo kore](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md) — fonte da verdade do protocolo.

## Mais documentos

A descrição completa está em [README.md](../README.md).
O processo de divulgação está em [SECURITY.md](../SECURITY.md) e o projeto de segurança em [docs/SECURITY.md](SECURITY.md).
O histórico de versões está em [CHANGELOG.md](../CHANGELOG.md).
Como contribuir: [CONTRIBUTING.md](../CONTRIBUTING.md).

## Perguntas frequentes

**P: Preciso de uma conta?**
Não. Não há contas, verificação online nem telemetria oculta; a configuração é texto simples que você pode ler e alterar.

**P: Onde ficam os plugins?**
Cada plugin fica no seu próprio repositório `kore-plugin-<id>`. Aqui estão apenas o núcleo e o SDK público.

**P: Qual documento ler primeiro?**
Comece por `QUICKSTART.md` (da compilação ao primeiro login) e use o índice “o que quero fazer” em `docs/README.md`.
