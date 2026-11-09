# Clearer — Plan de implementación en 5 días (A + B)

**Preparado por:** roblox-producer · **Fecha:** 2026-11-06 · **Versión:** v2 (alcance A + B decidido por el dueño)
**Estado:** PROPUESTA, pendiente del resto de decisiones del dueño (§5)
**Fuentes:** `Docs/00_README_Prototype_Pack_v1.0.md`, `01_Environmental_Clearing_Prototype_v1.0.md`, `02_Object_Organization_Prototype_v1.0.md`, `05_Shared_Research_and_Playtest_Protocol_v1.0.md`, `MANIFEST.json`.
**Fuera de estos 5 días:** C (Revelación) y D (Lavado de precisión). Nada de *Thaw a Creature*. Sin monedas, persistencia, upgrades ni monetización.

---

## 1. Lectura del proyecto

- Paquete de prototipos de investigación ("Restoring a Visible Mess"). Haremos **A — Limpieza ambiental** y **B — Organizar objetos**: cada uno es una tarea + botón de replay, partida de 45–90 s, en memoria, servidor autoritativo.
- Objetivo: medir qué fantasía (limpiar vs ordenar) da más satisfacción y replay voluntario por costo (protocolo `05`).
- **"Listo" en 5 días** = A y B en P0 completo, suites A-T01..T12 y B-T01..T13 en PASS observado en Studio (PC + viewport móvil), logs de métricas y kit de playtest listos. No incluye el playtest con 10–15 testers ni pulido de lanzamiento.
- Esfuerzo según los docs: A 2–3 dev-días + B 3–5 dev-días = 5–8 dev-días. Cabe en 5 días con agentes en paralelo, **pero B es el que puede comerse el Día 5**; el plan lo asume como colchón.

## 2. Qué se comparte y qué es nuevo

| Compartido A/B (se construye una vez en A) | Nuevo en B |
|---|---|
| `RoundService`: máquina `READY → ACTIVE → COMPLETE → REPLAY_OFFERED → RESETTING → ACTIVE`, `RoundId` inmutable, rechazo de requests de rondas viejas | `PropStateService`: `Scattered → Held → Placed`, dueño único del objeto, un objeto por jugador |
| `ActionValidator` (parte genérica): jugador vivo, ronda activa, distancia, rate | Pickup/place con **`ProximityPrompt.Triggered` del servidor** (no PropId enviado por el cliente) |
| `MetricLogger`: eventos de `05` §4 como logs estructurados en memoria | Carry: weld/attachment no colisionante al personaje, autorizado por el servidor, con rollback si falla |
| Patrón `Config` centralizado | `PlacementService`: categoría correcta → reserva el slot libre más bajo, ancla el objeto; categoría incorrecta → rechazo suave, sigue cargándolo |
| HUD shell: contador, etiqueta de instrucción, panel final con "Try another round" / "Finish" | Gestión de prompts: solo el pickup más cercano; prompt de estante solo si cargas algo; sin solapes en pantalla estrecha |
| Kit de audio base (confirmación, fin) | Limpieza de carry en muerte/reset/salida; 3 distribuciones iniciales validadas; arte: 12 props (4 categorías x 3), 4 estantes con icono + texto, 12 slots |

Lo de A que **no** sirve a B: raycast de apuntado, retícula, botón Clean táctil, parches de 2 golpes.

## 3. Plan día por día

Reglas de todos los días:
- Un escritor por archivo y por subárbol de Studio. Las escrituras en Studio van en serie y pasan por `roblox-studio-sync-integrator` antes y después.
- Scripts vía Rojo (el repo es la fuente de verdad). Un FAIL vuelve a su dueño y se re-prueba.
- PASS solo con prueba observada en Studio, nunca leyendo código. Sin commits (los haces tú), sin publicar, sin Robux.

### Día 1 — Specs A + B aprobadas, núcleo de A jugable en PC

| Momento | Trabajo | Agentes (║ = paralelo, archivos disjuntos) |
|---|---|---|
| Mañana | Brief + **Gate 0** (alcance A+B, guardarraíles "no Thaw") | `roblox-design-guardian`; `roblox-librarian` (solo lecciones genéricas: prompts, carry, botón táctil; cero código de Thaw) |
| Mañana | Specs delta de A y B (lo que los docs dejan abierto: hold vs tap en A, reset de personaje, drop voluntario en B, categorías) + contrato del núcleo compartido | `roblox-mechanics-designer` (`Docs/Production/A/spec.md`, `B/spec.md`, `contracts.md`) ║ `roblox-world-level-designer` (greybox del patio 48x48 y de la tienda 36x32 en studs, nodos de spawn, recorridos) ║ `roblox-economy-balance-designer` (tablas Config: A 120 golpes/7 por s/12 studs; B 12 objetos x ~5 s, 10 studs; tiempo estimado vs 45–90 s) ║ `roblox-ui-ux-designer` (Design Package del HUD shell + variantes A "% CLEAN" y B "0/12 PLACED", pista de categoría cargada, aviso de rechazo) |
| Mediodía | Gate 1a + **Gate 1 (apruebas spec A, spec B y HUD)** | `roblox-design-guardian` → tú |
| Tarde | A-01/A-02: RoundService, ActionValidator, PatchService, MetricLogger, Config | `roblox-server-systems-engineer` ║ `roblox-gameplay-client-engineer` (input mouse/touch, retícula, raycast, feedback) ║ `roblox-technical-artist` (suciedad x3, escoba, VFX de A; empieza los 12 props y 4 estantes de B en `Assets/`, sin tocar Studio) ║ `roblox-analytics-liveops-engineer` (MetricLogger + métricas extra de B en el contrato) |
| Cierre | Sync verificado | `roblox-studio-sync-integrator` |

**Checkpoint del dueño (15 min):** en Studio, Play en A. Apuntas a un parche: medio-limpio, luego limpio. El contador sube. Un click lejano o el spam no suman.

### Día 2 — A completo (Gate 2) + sala de B en greybox

| Trabajo | Agentes |
|---|---|
| A-03/A-04: HUD prefabs, panel final, replay con nuevo RoundId, 3 seeds, pase móvil | `roblox-ui-producer` ║ `roblox-gameplay-client-engineer` ║ `roblox-server-systems-engineer` (mañana: reset atómico y seeds) ║ `roblox-audio-localization` (sonidos de A + textos de A y B) |
| A-05: suite A-T01..A-T12 con evidencia | `roblox-qa-harness-engineer` |
| Auditoría UI + Gate 2 de A | `roblox-ui-ux-designer` → `roblox-design-guardian` |
| **B-01:** greybox de la tienda, 4 estantes, IDs de props, 12 slots (en Studio, después de las escrituras de A del día) | `roblox-world-level-designer` (greybox) + `roblox-technical-artist` (props/estantes listos para insertar) |
| **B-02 en repo (tarde):** PropStateService + carry | `roblox-server-systems-engineer` |
| Primer minuto de A y B (instrucción única, primera acción ≤10 s) | `roblox-ftux-retention-designer` (ligero) |

**Checkpoint del dueño (30 min):** **Gate 2 de A**: partida completa en PC y en emulador de teléfono, replay, reset de personaje. Ver la sala de B desde la entrada y confirmar que el antes/después se lee (salida de B-01).

### Día 3 — B: recoger, cargar y colocar en PC

| Trabajo | Agentes |
|---|---|
| B-02/B-03: pickup con validación (ronda, estado, 10 studs, mano libre), carry, colocación correcta/incorrecta, slots atómicos | `roblox-server-systems-engineer` (PropStateService, PlacementService) |
| Visual del carry que no tape la cámara ni empuje al jugador, feedback de rechazo, efectos cosméticos | `roblox-gameplay-client-engineer` |
| 12 props y 4 estantes en Studio, attachments de slots sin clipping | `roblox-technical-artist` |
| HUD "0/12 PLACED", pista de categoría cargada, aviso de estante incorrecto | `roblox-ui-producer` |
| Sonidos: recoger, colocar, error suave | `roblox-audio-localization` |
| Arreglos de feedback de A | el dueño de cada archivo |
| Sync antes/después de cada escritura en Studio | `roblox-studio-sync-integrator` |

**Checkpoint del dueño (15 min):** en PC: recoges un objeto, el estante incorrecto lo rechaza y sigues cargándolo, el correcto lo encaja, el contador sube una vez. **Punto de decisión:** si B-03 no funciona al final del Día 3, se aplican los recortes de B (§4) desde el Día 4 por la mañana.

### Día 4 — B completo (Gate 2)

| Trabajo | Agentes |
|---|---|
| B-04: 12 objetos completos, final 12/12, sala ordenada | `roblox-server-systems-engineer` ║ `roblox-technical-artist` |
| B-05: prompts táctiles sin solapes, replay con 3 distribuciones, limpieza en muerte/reset/salida | `roblox-gameplay-client-engineer` ║ `roblox-server-systems-engineer` |
| Suite B-T01..B-T13, incluida la prueba con **2 clientes** (B-T08 requests simultáneas) y B-T09 (reset/salida cargando) | `roblox-qa-harness-engineer` |
| Auditoría UI + Gate 2 de B | `roblox-ui-ux-designer` → `roblox-design-guardian` |

**Checkpoint del dueño (30 min):** **Gate 2 de B** en PC y emulador de teléfono: partida 12/12, replay, morir/resetear cargando un objeto.

### Día 5 — Colchón de B + endurecer + kit de playtest

| Trabajo | Agentes |
|---|---|
| Terminar lo que quede de B (colchón previsto) | dueños de cada archivo |
| Regresión A + B, rendimiento en móvil, fugas tras varios replays | `roblox-qa-harness-engineer` |
| Logs verificados + métricas extra de B (intentos en estante incorrecto, tiempo de viaje por colocación, tiempo cargando sin acercarse a un destino) + plantilla del scorecard (`05` §6, §8) | `roblox-analytics-liveops-engineer` |
| Guion de observación para testers (`05` §7, incluye "¿escanea la sala antes de elegir?") | `roblox-ftux-retention-designer` |
| Sync final con hashes | `roblox-studio-sync-integrator` |
| Cierre y lecciones | `roblox-librarian` |

**Checkpoint del dueño (30 min):** juego final de A y B. Si quieres, **tú** publicas en privado para testers.

**Tu tiempo total:** ~2–2.5 h en 5 días.

## 4. Riesgos y recortes

**Riesgos**
1. **B se corre al Día 5:** es el más probable. El Día 5 es el colchón de B; el punto de decisión es el cierre del Día 3. Si B se pasa del Día 5, se entrega A completo + B hasta B-04 en PC, marcado incompleto.
2. **Carry / drop:** muerte, reset o salida con un objeto en la mano (B-T09); weld que falla (rollback); objeto flotando o duplicado. Mitigación: el servidor es dueño del carry, sin física, props anclados al colocar, limpieza en `CharacterRemoving`/`PlayerRemoving`, y el objeto vuelve a su nodo de spawn.
3. **Dos jugadores:** P0 es de un tester por servidor, pero el servidor debe aguantar 2 (B-T08: un objeto, un solo dueño, una sola colocación). Se prueba con 2 clientes en Studio.
4. **Prompts táctiles:** solapes en pantalla estrecha, estantes que tapan el prompt. Mitigación: solo el prompt más cercano, `Exclusivity` de un prompt por botón, prompt de estante solo si cargas algo, volumen de activación más grande sin agrandar el prop.
5. **Categoría poco clara:** icono + texto en el objeto y en el estante, nunca solo color.
6. **Viajes que dominan la partida:** si caminar pesa más que decidir, se ajusta el layout (no se agregan recompensas).
7. **Apuntado táctil en A** y "último 10%": proxies más grandes; resaltado sutil a partir del 90%.
8. **Studio en serie** y **emulador ≠ teléfono real**: el PASS móvil será en emulación salvo que pruebes en un teléfono.
9. **Tu disponibilidad en los gates:** cada día que se retrasa un gate corre el plan.

**Recortes en orden**
1. A: 3 seeds → 1; VFX decorativos; animación de la herramienta.
2. B: 3 distribuciones → 1; etiquetas decorativas y animaciones extra; variedad de mallas únicas (props hechos con partes simples reutilizadas).
3. B: drop voluntario fuera (ya recomendado).
4. Gamepad, cámara antes/después, audio más allá de lo básico.
5. Último recurso: A completo + B hasta B-04 en PC.

**Nunca se recorta:** en A, el cambio local visible, la transformación al 100%, el replay, la autoridad del servidor y la acción móvil. En B, la claridad de categoría, la decisión real de colocación, la transformación visible de la sala, la limpieza fiable del carry y el estado en el servidor. En ambos, la evidencia real de QA.

## 5. Decisiones que necesito antes del Día 1

1. ~~Alcance~~ → **decidido: A + B.**
2. **Gate 1 delegado:** ¿me dejas aprobar las specs delta si el Guardián las aprueba y no cambian reglas de los docs? Recomendado: sí (tú conservas el Gate 2). Ahorra ~medio día.
3. **Idioma de los textos del jugador:** español, inglés o ambos. Recomendado: ambos, con base en el idioma de tus testers.
4. **"Listo" = listo para playtest en un place privado**, no publicado al público. Recomendado: sí; publicar lo haces tú.
5. **B — drop voluntario:** ¿se puede soltar un objeto a mano? Recomendado: **no en P0** (el doc lo permite). Solo se suelta al morir, resetear o salir, y el objeto vuelve a su nodo de spawn. Menos casos borde, misma prueba de la fantasía.
6. **B — categorías y tema:** Recomendado: la tienda/almacén con **Libros, Juguetes, Herramientas y Comida** (3 de cada una), como propone el doc, sin marcas.

**Datos de setup que necesito**
- ¿Existe ya un place/experiencia para Clearer o se crea uno? ¿Tu cuenta o un grupo?
- ¿Trabajas solo o en Team Create con alguien (¿quién?)?
- ¿Usamos Rojo? (Recomendado: sí.) ¿Studio MCP está conectado a ese place?
- ¿Un place por prototipo (recomendado: evita sesgos y permite trabajar A y B sin pisarse) o uno con dos arenas?
- Para el playtest: ¿máximo 1 jugador por servidor? (Recomendado: sí; la prueba con 2 clientes se hace igual en Studio.) Es un ajuste del place que haces tú.
- ¿Tienes un teléfono real para la prueba móvil?
- ¿Confirmas que los commits los haces tú?

## 6. Decisiones que tomé (reversibles)

- Núcleo compartido A/B (RoundService, ActionValidator genérico, MetricLogger, Config, HUD shell); lo específico de cada uno va en módulos propios.
- B usa `ProximityPrompt.Triggered` en el servidor, como manda el doc; el cliente nunca envía CFrames ni elige slot.
- Las métricas son logs estructurados en memoria (`05` §3–4), sin AnalyticsService ni red.
- El Gate 0 con el Guardián se corre el Día 1 sobre A+B.
- Al arrancar el Día 1 creo `Docs/Production/` (STATUS, DECISIONS, brief, spec y plan por prototipo).
