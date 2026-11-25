# Divulgación de vulnerabilidades de seguridad

Este archivo es el proceso de divulgación, no el diseño de seguridad. El diseño del núcleo está en docs/SECURITY.md; el modelo de amenazas de kore está en el repositorio kore.

## Alcance

Covered: `index/plugins.json` and its signature `index/plugins.json.sig`, `index/versions.lock.json`, `presets/*.json`, the `market/` static page and `scripts/` validation scripts.

## Versiones compatibles

| Versión | Estado | Notas |
| --- | --- | --- |
| 当前 `main` | Sí — acepta y corrige | Instantánea de vista previa/desarrollo; actualiza. |
| 历史 commit / 快照 | No — sin soporte | Instantánea de vista previa/desarrollo; actualiza. |

Durante la fase 0.x se usa una superficie mínima: solo se corrige el último parche de cada línea minor; los parches antiguos no se respaldan.

## Superficie de ataque en este repositorio

Las acciones remotas y las escrituras en el host se limitan a las capacidades declaradas; una evasión es una vulnerabilidad. Los sockets de los plugins los crea el shell con permisos restringidos; evadir permisos o leer datos de otro plugin es una vulnerabilidad.

## Informes

Preferido: GitHub Security Advisory en este repositorio («Informar de una vulnerabilidad», privado, sin issue público). Correo alternativo: pengtang1024@users.noreply.github.com con asunto `[kore security] <repo>`. No abras issues públicos ni publices detalles explotables en debates o PR.

Incluye: versión o commit afectado, pasos de reproducción o PoC, evaluación del impacto, si ya es público y tu preferencia de atribución.

## Plazos y divulgación

Confirmación en 72 horas con una primera valoración; los casos complejos reciben un plan de investigación. Divulgación coordinada con plazo por defecto de 90 días; contáctanos primero si hace falta anticiparla (p. ej. explotación activa). Registra las correcciones en CHANGELOG.md sin detalles de explotación y publica un aviso si procede.

## Agradecimientos

Con tu consentimiento agradecemos al informante en las notas de lanzamiento; anónimo si lo pides.
