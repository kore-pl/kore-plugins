> 状态: borrador (草稿) · 归属: wave1 · 更新: 2026-11-25 · 里程碑: M5

# kore-plugins

Este repositorio solo publica `index/plugins.json` (y su firma ed25519 `plugins.json.sig`), `index/versions.lock.json`, `presets/*.json` y la página estática `market/`, con scripts de validación. El índice solo responde «qué plugins, qué versión, tamaño y resumen»; no prueba que un paquete sea fiable: kore recalcula el sha256 localmente y lo compara. La raíz de confianza es la clave pública compilada en kore más el cálculo local. Sin revisión, sin cuentas, funciona sin conexión (G-10).

Idioma: [简体中文](DETAIL.md) · [English](DETAIL.en.md) · [Español](DETAIL.es.md) · [Français](DETAIL.fr.md) · [Deutsch](DETAIL.de.md) · [Русский](DETAIL.ru.md) · [Português](DETAIL.pt.md)

## Qué hace

- **Canal de descubrimiento, no fuente de confianza**: el `sha256` / `download_url` del índice solo se comprueban antes de instalar; la raíz de confianza es la clave pública compilada en kore y el recálculo local.
- **Cadena de firma**: `plugins.json.sig` es una firma ed25519 raw de 64 bytes, refirmada por el mantenedor en la fuente autoritativa; CI verifica por capas: PR solo esquema, push main/tag verificación completa; firma ausente o inválida = FAIL. La clave privada nunca entra al repositorio ni a secretos de CI.
- **Libro de versiones**: `versions.lock.json` solo se añade; un sha por `id@version`; cambiar un paquete exige subir la versión.
- **Ocho preajustes**: `minimal` / `dev` / `web-lite` / `web-pro` / `db-only` / `gateway` / `security` / `full`; `out_of_box=true` no debe activar plugins basic (G-20).
- **Mercado estático**: `market/index.html` abre sin conexión, sin framework, CDN ni enlaces http(s); `market/plugins.js` se incrusta en construcción con `build-market.sh`.
- **Puertas de validación**: `make check` = `validate-index.sh` + `validate-presets.sh` (verificación completa por defecto); `KORE_INDEX_SKIP_SIG=1` solo para esquema en PR.

## Inicio rápido

```bash
KORE_INDEX_SKIP_SIG=1 make check   # PR: solo esquema / libro / referencias de preajustes
bash scripts/validate-index.sh     # validación completa (incluye firma ed25519)
bash scripts/validate-presets.sh   # validación de preajustes
bash scripts/build-market.sh       # reconstruir market/plugins.js
```

Tras cambiar `plugins.json`, el mantenedor debe refirmar en la fuente autoritativa con la clave privada de la máquina de publicación (`KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh`) y subir contenido y `.sig` en el mismo commit; la clave privada nunca entra al repositorio ni a CI.

## Seguridad y límites

Informa de manipulación del índice, firma o cadena de suministro por [SECURITY.md](../SECURITY.md) (72 h / 90 días); no abras issues públicos. **La clave privada la tiene el mantenedor, nunca en el repositorio ni en secretos de CI; CI solo verifica, no firma.** Un cambio de clave pública debe publicarse con el núcleo kore y mantener un ciclo de compatibilidad de rotación.

## Mapa de documentación

- [SECURITY.md](../SECURITY.md) — proceso de divulgación; la cadena de firma y rotación están en el README.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — entradas del índice, libro de versiones, preajustes y convenciones de commit.
- [CHANGELOG.md](../CHANGELOG.md) — historial del índice y versiones de plugins.
- [index/plugins.json](../index/plugins.json) — entradas actuales (fuente de verdad).
- [index/versions.lock.json](../index/versions.lock.json) — libro de versiones (solo añadir).
- [Documentación del protocolo kore](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md) — fuente de verdad del protocolo.

## Más documentos

La descripción completa está en [README.md](../README.md).
El procedimiento de divulgación está en [SECURITY.md](../SECURITY.md) y el diseño de seguridad en [SECURITY.md](../SECURITY.md).
El historial de versiones está en [CHANGELOG.md](../CHANGELOG.md).
Cómo contribuir: [CONTRIBUTING.md](../CONTRIBUTING.md).

## Preguntas frecuentes

**P: ¿Necesito una cuenta?**
No. No hay cuentas, verificación en línea ni telemetría oculta; la configuración es texto plano que puedes leer y cambiar.

**P: ¿Dónde están los plugins?**
Cada plugin vive en su propio repositorio `kore-plugin-<id>`. Este repositorio solo contiene el núcleo y el SDK público.

**P: ¿Qué documento debo leer primero?**
Empieza por `QUICKSTART.md` (de la compilación al primer inicio de sesión) y usa el índice «qué quiero hacer» en `docs/README.md`.
