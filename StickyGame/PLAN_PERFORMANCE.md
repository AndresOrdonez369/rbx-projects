# Plan — Rendimiento de la pila pegada y escalado de objetos

**Fecha de inicio:** 2026-08-11
**Rama de documentación:** `main`
**Lugar:** `Exposición pegajosa` (`PlaceId 95828455414780`)
**Última iteración:** 2026-08-25, medición de MicroProfiler en Android (v5)
**Estado:** 60 FPS estables en Redmi Note 13 Pro 5G en las seis situaciones probadas. **Cuello: GPU** (12–14 ms de 16,67). La pila pegada queda medida y descartada como problema. Pendiente: low-end y 8 jugadores
**Configuración efectiva:** `LogicalCapacity=300`, `OwnVisualBudget=110`, `RemoteVisualBudget=20`, `MaxClientProxyInstances=320`, `MaxPartsPerProxy=8`, `StreamingEnabled=true`

---

## 0. Estado operativo v5 — medición en dispositivo del 2026-08-25

**Esta sección manda sobre v4 y v3.** Es la primera atribución real en un teléfono. Todo lo
anterior era evidencia indirecta, y la medición refuta parte de ello.

### 0.1 Qué se midió

Seis capturas de MicroProfiler de cliente, 90 frames cada una (~1,5 s a 60 FPS), exportadas a
HTML y parseadas con el visor propio de Roblox.

| Dato del dispositivo | Valor |
| --- | --- |
| Modelo | Xiaomi Redmi Note 13 Pro 5G (`2312DRA50G`) |
| SoC / GPU | ARM 8 núcleos · **Adreno 710** · Vulkan 1.1 |
| RAM del sistema | 7.301 MB · `VideoMemoryMB 64` |
| Android | 16 (`OS 36`) · Roblox `2.735.1138` |
| Pantalla | `DisplaySize 1220×2712` · **`DrawSize 610×1356`** · `ScreenDpiScale 3` |
| Refresco | 60 Hz (variable hasta 120, el cliente corrió a 60) |
| **`QualityLevel`** | **21 (auto)** — el máximo de la escala de Roblox |
| Iluminación | `Technology Unified`, `Style: Soft`, `PrioritizeLighting: true` |
| Red / entorno | Wi-Fi · Bogotá 17 °C · funda puesta · batería 78 % |

**Es un teléfono mid-range de 2023, no el low-end objetivo.** Y las capturas de 3 jugadores no
son las de 8. Lo que sigue es un baseline sólido y una atribución válida; **no es la
certificación** de §0.8 histórica.

### 0.2 Resultado en una línea

> **El juego mantiene 60 FPS en las seis situaciones, y está limitado por GPU, no por CPU.**
> La CPU pasa entre **7,3 y 9,5 ms de cada frame sin hacer nada**, esperando a la GPU.

Ningún frame de las seis capturas superó **21,41 ms**. El peor p95 fue `17,82 ms`. No hay
emergencia de rendimiento en este dispositivo.

### 0.3 Las seis capturas

Todos los tiempos en milisegundos. `Espera GPU` es `cpu_waits_for_gpu`, el tiempo que el hilo
principal se queda bloqueado en `queuePresent`.

| Captura | Frame p50 | p95 | máx | **GPU p50** | **Espera GPU p50** | Jobs | Render | Physics | Script | UI |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 01 idle 1 min | 16,61 | 17,75 | 18,24 | **13,86** | **8,54** | 5,78 | 2,84 | 2,78 | 2,05 | 1,01 |
| 02 movimiento normal | 16,72 | 17,63 | 18,15 | **13,84** | 7,30 | 5,86 | 4,36 | 2,19 | 2,25 | 1,73 |
| 03 velocidad máxima | 16,67 | 17,82 | 18,39 | 13,05 | 8,58 | 6,95 | 4,91 | 2,64 | 2,58 | 1,97 |
| 04 pila llena · 3 jug. | 16,70 | 17,55 | **21,41** | 11,99 | 9,48 | 4,74 | 2,99 | 2,24 | 1,67 | 0,54 |
| 05 clear/muerte · 3 jug. | 16,63 | 17,48 | 18,00 | 12,32 | 7,44 | 6,04 | 2,38 | 3,99 | 1,49 | **2,47** |
| 07 térmico 15 min | 16,76 | 17,69 | 18,43 | **13,99** | 9,31 | 5,58 | 2,13 | 4,06 | 1,55 | 0,78 |

Memoria usada: 697–887 MB, con 2.303 MB libres. Sin fuga observable entre capturas.

### 0.4 Reparto real del frame

Con la GPU en `13,9 ms` sobre un presupuesto de `16,67 ms`, el ocupante es **83 % GPU**. El
desglose de CPU por *exclusive time* medio (captura 01, sin `Sleep` de hilos secundarios):

| Scope | ms | Qué es |
| --- | --- | --- |
| `queuePresent` | **8,25** | **La CPU esperando a la GPU.** No es trabajo |
| `queryOcclusion` | **2,75** | Occlusion culling en CPU; escala con clusters visibles |
| `Thread (FG)` | 1,84 | Trabajo agregado de hilos de trabajo |
| `Script_ClientMain` | **1,27** | **Todo el Lua del juego** |
| `lightingUpdateChunkGlobal` | 1,11 | Unified Lighting, actualización de chunks |
| `fillGuiVertices` | **0,86** | **Generación de vértices de GUI** |
| `TS::JobStep` | 0,85 | Scheduler |
| `Fill tiled casters` | 0,59 | Preparación de casters de sombra |
| `LightGridCPU::updateChunkOccupancy` | 0,47 | Light grid |
| `AnimatorParallelManager::stepAll` | 0,47 | Animación de personajes |
| `Id_Transparent` | 0,42 | Pase de transparencias |
| `UpdateUILayouts` | 0,34 | Layout de GUI |

Sumando: iluminación unificada ≈ **2 ms de CPU** (`lightingUpdateChunkGlobal` +
`updateChunkOccupancy` + `lightingUpdateChunkSkylight` + `updateChunksAsyncTask`), además de su
coste en GPU.

### 0.5 Hipótesis refutadas por la medición

Esta es la parte que más cambia el plan. Se aplica la regla propia del proyecto (§2): la medición
manda sobre la intuición, incluida la de las secciones v3 y v4 de este mismo documento.

| Hipótesis | Origen | Medición | Veredicto |
| --- | --- | --- | --- |
| La pila pegada es el coste móvil dominante | v3 completo | `AttachmentRenderer.Animate` **0,067 ms**, `Reconcile` 0,019, `Release` 0,012 con pila llena y 3 jugadores | **Refutada** |
| La física de la pila es un impuesto permanente grave | v3 §4.3, v4 §0.2 | Grupo `Physics` con pila llena y 3 jugadores: **2,24 ms**, *menos* que en idle (2,78) | **Refutada en este escenario** |
| `ClearPlayerVisuals` produce un tirón de 50–100 ms en móvil | v3 §4.5 | Captura 05: **cero frames por encima de 25 ms**; máximo **18,00 ms** | **Refutada** |
| Los 119 `BillboardGui` dominan `Pass3dAdorn` | v4 §N3 | `Pass3dAdorn` inclusive: **0,248 ms** | **Refutada** |
| El cuello móvil es CPU | v3 §4.6 | La CPU espera 7,3–9,5 ms por frame a la GPU | **Refutada** |
| Hay ~30 ms de CPU sin explicar | v3 §9.3 | No existen. El frame es 16,6 ms y el 50 % es espera | **Obsoleta** |

La medida de `45,70 ms` de CPU de v3 §4.6 venía de la barra de Performance Stats, no de un
MicroProfiler, y de una build anterior. No se sostiene.

**Consecuencia directa:** los presupuestos `OwnVisualBudget=110` y `RemoteVisualBudget=20` están
holgados por el lado de la CPU en este dispositivo. Antes de subirlos hay que comprobar el efecto
en GPU (más triángulos y más clusters), que es el recurso escaso — no el efecto en física, que
era la preocupación de v3.

### 0.6 Hipótesis confirmadas

| Hipótesis | Origen | Medición |
| --- | --- | --- |
| El coste GPU es casi constante y no depende de la escena | v4 §N2 | GPU entre **11,99 y 13,99 ms** en las seis situaciones, incluida idle. Un coste que no varía con el contenido es un coste de pantalla completa: post-procesado e iluminación |
| El HUD es el mayor coste de CPU atribuible al juego | v4 §N1 | `fillGuiVertices` es el segundo scope de juego más caro y **varía 5,5×** entre capturas |
| Velocidad alta produce picos en el sensor | v3 §5 guía | `CollectibleSensor` máximo **1,288 ms** en un frame de la captura 03, con media 0,051 |
| El contrato de proxy importa por triángulos, no por física | v4 §0.3 | Siendo GPU-bound, `RenderFidelity=Performance` pasa de "gratis y opcional" a **ataque directo al cuello** |

`fillGuiVertices` por captura: **0,86** (idle) · **1,60** (movimiento) · **1,80** (velocidad máxima)
· **0,41** (pila llena) · **2,29** (clear/muerte) · **0,69** (térmico).

Correlaciona con el movimiento de cámara, no con el contenido de la pila. Los dos candidatos son
el HUD 2D y los 119 billboards del mundo, que se re-vertexan cuando la cámara se mueve.
**Cuál de los dos manda no está atribuido**: un toggle de cada uno lo resuelve en una tarde y es
la primera medición del panel de §0.9 v4.

### 0.7 El hallazgo que cambia la estrategia: `QualityLevel 21 (auto)`

El auto-quality de Roblox sube el nivel gráfico hasta que deja de alcanzar el objetivo de frame.
En este teléfono lo subió al **máximo de la escala (21)**. Por eso la GPU está al 83 %: **el motor
está gastando deliberadamente todo el margen disponible.**

Eso significa dos cosas, y las dos importan:

1. **"GPU al 83 %" no es una crisis en este dispositivo.** Es el auto-quality haciendo su trabajo.
2. **En un teléfono low-end el auto-quality bajará el nivel.** Cuánto tenga que bajar lo decide el
   **coste fijo** de la escena: post-procesado, `UnifiedLighting Soft`, sombras, transparencias.
   Un coste fijo alto obliga a bajar mucho el nivel — el juego se ve peor **y** puede seguir sin
   llegar a 30 FPS, porque parte de ese coste (la CPU de iluminación, ~2 ms) no baja con el nivel
   gráfico.

> **El objetivo correcto no es "bajar la GPU en este teléfono". Es bajar el coste fijo para que un
> teléfono débil pueda sostener un nivel gráfico decente.**

Esto convierte G3 y G4 de §0.6 v4 —y la revisión de `UnifiedLighting`, sombras y transparencias—
de "limpieza opcional" en la palanca principal.

### 0.8 Los tres costes reales, ordenados

#### C1 — Coste fijo de pantalla completa · GPU 12–14 ms + ~2 ms de CPU

Post-procesado activo (`SunRaysEffect`, `BloomEffect`, dos `ColorCorrectionEffect`, `Atmosphere`)
más `UnifiedLighting` en `Soft` con `PrioritizeLighting: true`, más `GlobalShadows` con 418 partes
proyectando sombra, más 88 partes semitransparentes (`Id_Transparent` 0,32–0,67 ms).

En el perfil aparecen `horizontalBlur` y `verticalBlur` (0,11 / 0,08 ms de CPU cada uno) y
`AdvSky/Compute` (0,54 ms medio, **4,60 ms de pico** en la captura 03).

Medición pendiente, barata y de una sola variable: repetir la captura 01 con el post-procesado
desactivado y con `Style: Voxel` en vez de `Soft`. Dos capturas, dos números.

#### C2 — `queryOcclusion` · 2,5–3,1 ms de CPU, constante

El scope de CPU más caro después de la espera de GPU. Es el occlusion culling, y escala con el
número de clusters renderizables. No lo baja el auto-quality. Lo bajan menos objetos únicos
visibles y mejor agrupación de geometría estática.

Es el candidato natural para `StreamingEnabled` más agresivo y para revisar cuánta decoración
(`Dressing_Level_01/02`, 513 `SurfaceAppearance`) está viva a la vez.

#### C3 — `fillGuiVertices` · 0,41–2,29 ms de CPU

Ya descrito en §0.6. Es el único de los tres que es CPU pura y que por tanto **pega igual en
todos los dispositivos**, incluidos los low-end donde el auto-quality ya bajó todo lo demás.

Lo que sigue vigente de §N1 v4: 1.322 descendientes de `InventoryScreen` y 361 de `ShopScreen`
viven materializados con `Visible=false`; 295 `UIStroke` y 253 `UITextSizeConstraint` solo dentro
del inventario. Lo visible en juego es pequeño (~110 descendientes, 24 `UIStroke`), así que **si
el toggle demuestra que manda el HUD, el culpable son los billboards del mundo o un re-fill que no
debería ocurrir** — no las pantallas cerradas. Medir antes de reconstruir nada.

### 0.9 Lo que estas capturas **no** prueban

Escribirlo explícitamente para que nadie cite este documento de más:

1. **No hay medición de 8 jugadores.** El máximo probado es 3.
2. **No hay medición en low-end.** Un Adreno 710 con 8 GB no es el dispositivo objetivo.
3. **90 frames por captura ≈ 1,5 s.** Los `p99` y "hitch máximo en 5 min" de los gates históricos
   no se pueden calcular con esta ventana. La captura 07 cubre 15 minutos de juego pero solo
   guardó los últimos 90 frames.
4. **No hay captura de servidor**, ni de join, ni de stream-in.
5. **No hay medición con trails**, porque los trails están vacíos (§N6 v4).
6. **Sin thermal throttling observado**: GPU pasó de `13,86` (idle) a `13,99` (15 min). Con funda,
   a 17 °C ambiente y 60 Hz. No es transferible a 30 °C ni a un chasis peor.

### 0.10 Plan de acción revisado

Sustituye a §0.10 de v4. El orden cambia porque el cuello cambió.

| Paso | Qué | Por qué ahora | Coste |
| --- | --- | --- | --- |
| 1 | G1 `RenderFidelity=Performance` y G2 `CollisionFidelity=Box` en los 183 `MeshPart` de proxy | Siendo GPU-bound, menos triángulos ataca el cuello real | ✅ **hecho 2026-08-25**, ver §0.12 |
| 2 | A/B de coste fijo: captura idle con post-procesado off, y otra con `Style: Voxel` | Aísla C1, que es 12–14 ms de los 16,67 | 2 capturas |
| 3 | A/B de `fillGuiVertices`: una captura con HUD off, otra con billboards off | Separa C3 entre HUD y mundo | 2 capturas |
| 4 | A/B de `queryOcclusion`: captura con la decoración de una zona oculta | Aísla C2 | 1 captura |
| 5 | Panel de atribución authored (§0.9 v4) con los toggles de 2–4 | Convierte cada A/B de una tarde en un botón | 1 `ScreenGui` |
| 6 | Repetir 01/04/05 en el **low-end** objetivo y con **8 jugadores** | Es la certificación que sigue pendiente desde v3 | sesión de pruebas |
| 7 | G5 `MaxPartsPerProxy: 8 → 3` y aserción agregada de §0.7 v4 | Protege el resultado de mañana, no el de hoy | 1 valor + 5 líneas |
| 8 | Presupuesto de VFX de §0.8 v4 antes de authorizar los 17 trails | Los trails aún no existen; el presupuesto todavía es gratis | escribir config |

Los pasos 2, 3 y 4 son **tres pares de capturas**. Con ellos el reparto del frame deja de tener
huecos y §0.5 v4 se puede escribir con números en vez de con `[PLACEHOLDER]`.

Lo que **ya no** es prioritario, y conviene decirlo para no gastar semanas ahí: reescribir el
sistema de pila, bajar `OwnVisualBudget`, presupuestar el clear por frames, o perseguir el churn
de welds. La medición dice que ninguno de los cuatro es el problema en este dispositivo.

### 0.11 Gate revisado `[PROPUESTO]`

El gate de v3 (`p95 ≤33,3 ms` en low-end) sigue siendo el correcto, pero le faltaba la mitad
que ahora se sabe que manda:

| Gate | Low-end | Mid-end (verificado hoy) |
| --- | --- | --- |
| Frame p95 | `≤33,3 ms` | `≤22,2 ms` · **medido 17,8 ✅** |
| **GPU p95** | **`≤28 ms`** | `≤18 ms` · **medido 14,2 ✅** |
| **Coste fijo de escena (idle, GPU)** | **`≤18 ms`** | `≤10 ms` · **medido ~13,9 ❌** |
| `fillGuiVertices` p95 | `≤1,5 ms` | `≤1,0 ms` · **medido 2,29 ❌** |
| `queryOcclusion` p95 | `≤3,0 ms` | `≤2,0 ms` · **medido 3,14 ❌** |
| Lua de juego (`Script_ClientMain`) | `≤3,0 ms` | `≤2,0 ms` · **medido 1,41 ✅** |
| Pila completa (todos los marcadores `AttachmentRenderer.*`) | `≤1,0 ms` | `≤0,5 ms` · **medido 0,10 ✅** |
| Hitch máximo en 5 min | `<100 ms` | `<75 ms` · **no medible con 90 frames** |
| `QualityLevel` sostenido en low-end | `≥10` | — |

Las tres filas en rojo son el trabajo. Las cuatro en verde son el permiso para dejar de
preocuparse por la pila.

### 0.12 Cambios aplicados el 2026-08-25 — G1 y G2

Aplicados en el DataModel abierto de Studio, en modo Edit, sobre
`ReplicatedStorage.Assets.AttachmentProxies` y **solo** ahí.

| Cambio | Antes | Después | Alcance |
| --- | --- | --- | --- |
| `RenderFidelity` | `Automatic` ×183 | **`Performance` ×183** | 183 `MeshPart` de 107 proxies |
| `CollisionFidelity` | `Default` ×183 | **`Box` ×183** | los mismos 183 |

#### Comprobación de calidad previa, no asumida

Antes de escribir nada se montó un banco A/B temporal (`workspace._FidelityAB`, ya borrado) que
clona cada proxy con **su escala real de pegado** —la misma fórmula que usa `AttachmentService`:
`AttachmentScale` authored si existe, si no `TargetMaxSizeStuds / dimensión mayor`— y coloca dos
filas idénticas, una en `Automatic` y otra en `Performance`.

- **Peor caso probado:** `SM_Level_1_BigTree_02`, el proxy más grande del set, a **25,7 studs**
  pegados, fotografiado a 48 studs de cámara. Las dos versiones son indistinguibles: misma
  silueta, mismos volúmenes, mismo sombreado.
- **Caso masivo probado:** seis proxies pequeños (cristal, flor, escarabajo, monedas, bellota,
  obelisco) a su tamaño real de 2,2–2,3 studs y a distancia de juego. Indistinguibles.

La razón es que las mallas son low-poly estilizadas: el LOD más bajo que genera Roblox apenas se
separa del original. `Performance` cobra la ventaja de no reconstruir detalle que nunca se ve, sin
pagar la degradación que justificaría el nombre.

#### Comprobaciones posteriores

| Verificación | Resultado |
| --- | --- |
| `AttachmentProxyTemplates.ValidateAll()` | **PASS** |
| Banderas de física de los proxies | 192/192 anchored, massless, sin collide/touch/query, sin sombra — **intactas** |
| `MeshPart` de `Workspace` | **sin tocar**: 816 `Automatic` + 80 `Precise` |
| `CollisionFidelity` de `Workspace` | **sin tocar**: 816 `Default` + 80 `Hull` |
| Plantillas de suelo (`Assets.Collectibles`) | **sin tocar**: 93 `Automatic` |
| Banco A/B temporal | borrado (76 instancias) |

`CollisionFidelity = Box` no tiene efecto visual: las 192 partes ya tenían
`CanCollide/CanTouch/CanQuery = false`, así que su geometría de colisión nunca se consultaba. Lo
que ahorra es el horneado y la carga de la malla de colisión compleja.

> ⚠️ **Los cambios están en el DataModel abierto, no guardados.** El MCP no expone Save ni Publish.
> Hay que revisar el diff en Studio y guardar/publicar a mano.

#### Hallazgo colateral: `AttachmentScale` sin tunear · P1 de diseño

Al replicar la fórmula de escalado para el banco A/B salió un dato que no estaba en ningún
documento. El tamaño con el que cada prop se pega al cuerpo:

| Tamaño pegado | Proxies |
| --- | --- |
| `<2` studs | 29 |
| `2–3` studs | 48 |
| `3–5` studs | 3 |
| `5–10` studs | 9 |
| **`10–20` studs** | **17** |
| **`≥20` studs** | **1** |

**27 de 107 proxies se pegan a 5 studs o más, y 18 a 10 studs o más.** El máximo es
`SM_Level_1_BigTree_02` con **25,7 studs** — más alto que el propio personaje, sobre un cuerpo
cuya bola completa está dimensionada para `MaxRadiusCap = 8`.

Casi todos comparten el valor `AttachmentScale = 0.600`, que sobre bases de 20–43 studs produce
esos tamaños. Los que sí están tuneados usan valores muy distintos (`SM_Level_2_Obelisk_01` usa
`0.055` sobre una base de 40 studs y queda en 2,2). El patrón sugiere `0.600` como valor por
defecto copiado y nunca revisado, no como decisión.

No se ha tocado: es una decisión de diseño, no de rendimiento. Pero tiene tres consecuencias que
conviene registrar:

1. **Legibilidad.** Un árbol de 25,7 studs pegado a la espalda tapa cámara y personaje, y
   contradice el principio de §0.4.2 v2 ("la pila comunica tamaño y personalidad", no una sola
   pieza dominante).
2. **Presupuesto de triángulos.** Un proxy de 25 studs ocupa mucho más pantalla que uno de 2,3, y
   siendo el juego GPU-bound (§0.2) el coste de relleno no es despreciable.
3. **El contrato de §0.7 v4 debería incluirlo.** El validador comprueba partes por proxy; no
   comprueba el tamaño resultante. Un `assert` de `tamañoPegado ≤ N studs` `[PLACEHOLDER]` cuesta
   tres líneas y habría cazado esto el día que se subió el prop.


---


## 0. Estado operativo v4 — auditoría en vivo del 2026-08-25

**Fuente:** censo del DataModel abierto en Play (`PlaceId 95828455414780`) vía Roblox Studio MCP,
1 jugador, pila 0, sin arnés de carga. Todo lo de esta sección es **medido**, salvo lo marcado
explícitamente como modelo o extrapolación.

**Qué cambió desde v3:** llegó el arte real, llegaron dos mundos más, y llegaron HUD completo,
tienda, inventario, plataformas móviles, eventos y cosméticos. El plan v3 sigue siendo correcto
en su método, pero **su objeto de estudio ya no es el mayor sospechoso móvil**: v3 razona sobre
una escena de 9 primitivas y 24 collectibles que hoy no existe.

### 0.1 Censo en vivo

| Métrica | Cliente | Servidor |
| --- | --- | --- |
| `InstanceCount` | 50.497 | 47.501 |
| `PrimitivesCount` | 1.643 | 2.413 |
| `MovingPrimitivesCount` | 68 | 19 |
| `PhysicsStepTimeMs` (pila 0, 1 jugador) | **1,22** | 0,032 |
| `BaseParts` en Workspace | 1.295 (`Part 500` + `MeshPart 795`) | 1.958 |
| `SurfaceAppearance` | 513 | 742 |
| `MeshId` únicos en proxies | 96 | — |
| `ColorMap` únicos en proxies | **5** | — |
| `BillboardGui` (habilitados / totales) | **119 / 138** | 143 |
| `TouchTransmitter` | 232 | **341** |
| Partes con `CastShadow=true` | **418** | — |
| Partes semitransparentes (0<T<1) | 88 | — |
| Instancias en `PlayerGui` | **1.976** | — |
| `GuiObject` visibles | 556 | — |
| `UIStroke` en `PlayerGui` | **456** | — |
| Memoria `Gui` | **43,4 MB** | — |
| Memoria `GraphicsTexture` | 47,9 MB | — |
| Memoria `GraphicsParticles` | 15,3 MB (con 0 emitters activos) | — |

`PhysicsStepTimeMs` cliente pasó de `0,064` (baseline v2, 2026-08-12) a **`1,22`** con la pila
vacía y un solo jugador. Es un ×19 sobre el baseline con el que se dimensionó todo el plan v3, y
**ocurre antes de pegar una sola pieza**. Atribuirlo es la primera tarea de medición, no la
última: 68 primitivas en movimiento en el cliente sin pila apuntan a `MovingPlatforms`
(simuladas en cliente por diseño) más el personaje.

### 0.2 Hallazgo principal

> El plan v3 presupuestó **250 `BasePart` móviles** para 8 jugadores. La configuración vigente
> permite **hasta 2.000**, y la que hay authored hoy produce **~448**.

El contrato v3 decía "exactamente una `BasePart` por proxy". Ese contrato **ya no existe**:
`GameConfig.Attachments.MaxPartsPerProxy = 8`, y el comentario en `GameConfig` documenta el
cambio como deliberado ("los proxies dejaron de ser una sola parte cuando pasaron a ser los props
de verdad"). Medido hoy sobre los 107 proxies authored:

| Partes por proxy | Proxies |
| --- | --- |
| 1 | 52 |
| 2 | 25 |
| 3 | 30 |

Media **1,79 partes/proxy**; peor caso authored **3**; techo que el validador permite **8**.

Aritmética con la pendiente propia del proyecto (`~1,4 µs / BasePart / paso`, escritorio) y el
factor móvil hipotético 5–10× que ya usa el plan. Escenario: 8 jugadores co-localizados,
`OwnVisualBudget=110`, `RemoteVisualBudget=20`.

| Escenario | `BasePart` móviles | Escritorio | Móvil 5–10× (extrapolado) |
| --- | --- | --- | --- |
| Contrato v3 (1 parte) | 250 | 0,35 ms | 1,8 – 3,5 ms |
| **Real authored hoy (media 1,79)** | **448** | **0,63 ms** | **3,1 – 6,3 ms** |
| Peor caso authored hoy (3) | 750 | 1,05 ms | 5,3 – 10,5 ms |
| Techo del validador (8) | 2.000 | 2,80 ms | **14 – 28 ms** |

La última fila es el argumento: **hoy nada impide que un artista suba un prop de 8 partes y se
lleve el presupuesto móvil entero sin que ningún test falle.** El validador comprueba el proxy;
el presupuesto que importa es el de la pila.

### 0.3 Regresiones contra el propio contrato del proyecto

Todo medido sobre `ReplicatedStorage.Assets.AttachmentProxies` (107 modelos, 192 `BasePart`,
183 `MeshPart`).

| # | Regla escrita en `GUIA_SISTEMA_BOLA_Y_ARTE_MOBILE.md` §6.B | Estado real | Severidad |
| --- | --- | --- | --- |
| R1 | Exactamente **una** `BasePart` por proxy | 55 de 107 tienen 2 o 3 | **P0** |
| R2 | `RenderFidelity = Performance` | **183/183 en `Automatic`** | **P0** — gratis |
| R3 | `CollisionFidelity = Box` | **183/183 en `Default`** | **P0** — gratis |
| R4 | `Anchored`, `Massless`, sin collide/touch/query, sin sombra | ✅ 192/192 correcto | — |
| R5 | Un material y textura compartidos | ✅ solo **5 `ColorMap`** únicos | — |
| R6 | Sin partículas, trails, luces, guis, scripts | ✅ el validador lo bloquea | — |

`RenderFidelity` y `CollisionFidelity` **no se escriben en ningún sitio del código**
(`script_grep` de ambos términos: cero coincidencias). Nunca se aplicaron. Son dos propiedades
authored, 183 instancias, cero riesgo y cero coste de desarrollo:

- `Performance` fuerza el LOD más bajo del mesh siempre. Los proxies se renderizan a ~1,6 studs
  sobre el cuerpo: el detalle alto no es visible ni en el mejor caso.
- `Default` en `CollisionFidelity` hornea y carga geometría de colisión compleja por mesh
  **aunque `CanCollide=false`**. `Box` la elimina de memoria y del trabajo de carga.

### 0.4 Costes que el plan v3 no contempla

Ordenados por (coste móvil estimado × facilidad de eliminarlo). Ninguno se había medido porque
ninguno existía cuando se escribió v3.

#### N1 — HUD: 1.976 instancias, 43,4 MB, y el 93 % pertenece a pantallas cerradas · P0

| Subárbol de `StickyHUD` | Descendientes | `Visible` |
| --- | --- | --- |
| `InventoryScreen` | **1.322** | false |
| `ShopScreen` | 361 | false |
| `WorldScreen` | 88 | false |
| `RebirthScreen` | 68 | false |
| `StatsPanel` | 51 | true |
| `CounterStack` | 36 | true |

**1.839 de 1.976 instancias son pantallas cerradas.** Cuestan memoria residente y tiempo de
creación en el join. Además hay **456 `UIStroke`**, 384 `UITextSizeConstraint`, 298 `UICorner` y
106 `UIPadding` en el árbol: `UIStroke` es de los modificadores más caros de Roblox en móvil
porque añade geometría y pases extra por elemento.

Sospechoso número uno de los `~30 ms` de CPU móvil que el plan v3 dejó sin explicar
(§9.3 histórica).

Dirección de arreglo, en este orden: (a) `InventoryScreen` construye sus filas bajo demanda y las
libera al cerrar — es una lista de ~50 cosméticos que hoy vive materializada siempre; (b) auditar
los 456 `UIStroke` y sustituir los decorativos por textura o borde plano; (c) medir antes de (a) y
(b) con el toggle 5 del panel.

#### N2 — Pila de post-procesado activa · P0 para GPU

`Lighting` en vivo: `SunRaysEffect [Enabled=true]`, `BloomEffect [Enabled=true]`,
**dos** `ColorCorrectionEffect [Enabled=true]`, `Atmosphere`, `Sky`, `GlobalShadows=true`.
`DepthOfFieldEffect` ya está en `false` — correcto.

`SunRaysEffect` y `Atmosphere` son los dos efectos más caros en fill-rate móvil. Con `418` partes
proyectando sombra y `GlobalShadows` activo hay además un pase de shadow map completo. El plan v3
midió `5–6 ms` de GPU y concluyó "el cuello es CPU" — **esa medida es de greybox sin arte y sin
esta pila de efectos**. No es transferible.

#### N3 — 119 `BillboardGui` habilitados a la vez · P1

Disciplina buena: **los 138 tienen `MaxDistance` fijado**, ninguno en infinito. Pero la
distribución deja demasiados vivos:

| `MaxDistance` | Billboards |
| --- | --- |
| 140 | 32 |
| 80 | 20 |
| 70 | 10 |
| 50 | 32 |
| 37,5 | 8 |
| 28,125 | 32 |
| 120 / 180 | 4 |

Dentro llevan 236 `TextLabel`, 128 `UICorner` y 66 `UIStroke`. `MaxDistance` recorta el dibujado,
no necesariamente todo el trabajo de `Prepare/Pass3dAdorn`. Los de 140 y 180 studs son los que
hay que justificar uno a uno.

#### N4 — 341 `TouchTransmitter` en servidor / 232 en cliente · P1

Repartidos por cada zona (5–11) y cada corredor (4). Son las placas, pedestales, salidas y
volúmenes de reto. `script_grep` de `.Touched:Connect` solo encuentra 5 sitios, así que el resto
viene de otras rutas de conexión: **hay que inventariar quién las crea antes de tocarlas**, no
borrarlas a ciegas. Cada parte con touch interest entra en el broadphase contra cada personaje en
movimiento; a 8 jugadores es 8× ese conjunto.

#### N5 — `MaxVisualAttachments = 36` sigue en `GameConfig` · P2

Legacy declarado, pero `FeedbackController` lo lee. Un valor muerto que un lector futuro tomará
por vigente. Renombrar a `LegacyMaxVisualAttachments` o eliminar la dependencia.

#### N6 — Trails vacíos · funcional, no de rendimiento

Los **17** modelos de `Assets.Cosmetics.Trails` tienen **cero descendientes**: `trail_basic`,
`trail_gold`, `trail_cosmic`… todos vacíos. La compra, el equipado y la persistencia funcionan;
el VFX no existe. Las 17 Auras sí: **2 `ParticleEmitter` cada una**, con `Rate` sumado entre
**19 y 82 partículas/s** según el tier.

### 0.5 Presupuesto de frame móvil `[PROPUESTO]`

El plan v3 tiene gates de resultado (`p95 ≤33,3 ms`) pero **no reparte el presupuesto entre
subsistemas**, así que ningún equipo sabe cuánto le toca y nadie puede fallar su parte por
separado. Propuesta para low-end a 30 FPS:

| Bloque | CPU `[PLACEHOLDER]` | Cómo se verifica |
| --- | --- | --- |
| Motor, personaje, `PlayerModule` | 8,0 ms | baseline con todo lo demás apagado |
| Física de pilas (propia + remotas) | 5,0 ms | `PhysicsStepTimeMs` con toggle de pilas |
| Render de escena | 6,0 ms | dump con billboards y HUD apagados |
| UI y adornos (`Pass3dAdorn` + HUD) | 3,0 ms | toggles 4 y 5 del panel |
| Lua de gameplay (sensor, labels, plataformas, feedback) | 4,0 ms | marcadores `StickyClient/*` |
| Red entrante (`Replicator/ProcessPackets`) | 3,0 ms | ventana de join/fill |
| **Margen térmico y de pico** | **4,3 ms** | soak de 5 min tras warm-up |
| **Total** | **33,3 ms** | |

GPU low-end `[PLACEHOLDER]`: `≤20 ms` sostenido. El `5–6 ms` medido en greybox no vale como punto
de partida.

Regla que hace útil el reparto: **quien añade una feature paga de su bloque, no del margen.**

### 0.6 Ganancias inmediatas — coste cero, reversibles, aplicables hoy

Ninguna requiere código nuevo ni cambia el diseño. Las cinco son propiedades o valores de
configuración.

| # | Cambio | Alcance | Riesgo |
| --- | --- | --- | --- |
| G1 | `RenderFidelity = Performance` en los proxies | 183 `MeshPart` | ninguno: se ven a 1,6 studs |
| G2 | `CollisionFidelity = Box` en los proxies | 183 `MeshPart` | ninguno: `CanCollide=false` |
| G3 | `SunRaysEffect.Enabled = false` | 1 instancia | estético, A/B con captura |
| G4 | Fusionar los dos `ColorCorrectionEffect` en uno | 2 → 1 | estético, reproducir el look combinado |
| G5 | `MaxPartsPerProxy: 8 → 3` | 1 valor | ninguno: 3 es el peor caso authored actual |

G5 no ahorra nada hoy; **impide la regresión de mañana**. Es la diferencia entre un techo de
2.000 partes y uno de 750.

Candidatas del mismo tipo, pero que necesitan un A/B visual antes de decidir: `GlobalShadows`,
`Atmosphere.Density`, y las 418 partes con `CastShadow=true`.

### 0.7 Contrato de proxy endurecido — del per-proxy al per-pila

`AttachmentProxyTemplates` valida bien lo que valida: flags de física en **todas** las partes (no
solo la principal), clases prohibidas, IDs únicos, `PrimaryPart`. Lo que no valida:

1. `RenderFidelity` y `CollisionFidelity`.
2. Transparencia distinta de 0 o 1.
3. Número de `SurfaceAppearance` y que su `ColorMap` esté en la lista compartida de 5.
4. Triángulos por proxy.
5. **El presupuesto agregado de la pila.**

El punto 5 es el que cambia la naturaleza del contrato. Añadir a la validación de arranque:

```lua
-- Presupuesto agregado, no por proxy. Falla el arranque si el peor mix authored
-- no cabe en el presupuesto movil.
local worstPartsPerProxy = <máximo medido sobre los proxies authored>
local ownWorstCase    = worstPartsPerProxy * Rendering.OwnVisualBudget
local remoteWorstCase = worstPartsPerProxy * Rendering.RemoteVisualBudget * (MaxPlayers - 1)
assert(ownWorstCase + remoteWorstCase <= Rendering.MaxMovingPartsPerClient)
```

Con `MaxMovingPartsPerClient = 500` `[PLACEHOLDER]` y los 107 proxies de hoy
(`worstPartsPerProxy = 3`), la aserción **falla** a 110/20 — y debe fallar, porque el presupuesto
real es 750. Las salidas posibles son bajar `OwnVisualBudget`, bajar `RemoteVisualBudget`, reducir
partes por proxy, o subir `MaxMovingPartsPerClient` **con una medición en Android que lo
respalde**. Cualquiera de las cuatro es una decisión consciente; el estado actual es una decisión
que nadie tomó.

### 0.8 Trails y Auras — presupuesto antes de construirlos

Los Trails están vacíos, así que este es el único momento en el que el presupuesto es gratis.

Escenario objetivo: 8 jugadores, todos con trail y aura de tier alto, misma sala.

| Elemento | Presupuesto `[PLACEHOLDER]` | Razón |
| --- | --- | --- |
| `Trail` por jugador | **1** | Un `Trail` = 1 par de attachments. Dos no se leen mejor |
| `Trail.Lifetime` | ≤0,4 s | El coste es proporcional a segmentos vivos = `Lifetime × velocidad` |
| `Trail.MinLength` y `MaxLength` | fijar ambos | Sin `MaxLength`, a 52 studs/s la estela dobla su geometría |
| `ParticleEmitter` por aura | **≤2** (ya cumple) | — |
| `Rate` sumado por aura | ≤40 part/s `[PLACEHOLDER]` | Hoy los tiers altos van a **82**; ×8 jugadores = 656 partículas/s |
| Partículas vivas por jugador | ≤`Rate × Lifetime` ≤ 40 | Es el número a presupuestar, no `Rate` |
| `LightEmission` y `LightInfluence` | 0 | Evita el pase de iluminación por partícula |
| `Texture` de partícula | 1 compartida entre las 17 auras | 17 texturas rompen el batching |
| Luces dinámicas | **0** | — |
| VFX en jugadores remotos | LOD por distancia, mismo umbral que los proxies (90/110 studs) | Coherencia con el renderer |

Regla que evita la trampa clásica del género: **el tier alto se distingue por color, forma y
velocidad, no por más partículas.** Si `aura_galaxy` cuesta 4× más frame que `aura_green`, el
jugador que más paga es el que peor juega — y arrastra a los otros siete de la sala.

`GraphicsParticles = 15,3 MB` con **cero emisores activos** ya indica que el sistema de partículas
tiene buffers reservados; medir el delta al equipar 8 auras es una prueba de una sola variable y
barata.

### 0.9 El instrumento: panel de atribución en dispositivo

Sigue siendo el bloqueante que el plan v3 identificó en §6.2 (Hito B) y sigue sin construirse.
Todo lo de las secciones 0.1–0.4 son **sospechosos ordenados por evidencia indirecta**; ninguno es
una atribución. La trampa 4 del propio documento (§3) explica por qué el escritorio no puede
darla, y hoy vuelve a confirmarse: `PhysicsStepTimeMs` cliente es `1,22 ms` y el frame sigue
clavado en 60 FPS.

Toggles mínimos, todos cliente puro, cero riesgo de seguridad:

1. Pila propia · 2. Pilas remotas · 3. Collectibles del suelo · 4. `BillboardGui` de requisito
5. HUD entero · 6. Post-procesado · 7. Sombras · 8. Auras y trails · 9. Plataformas móviles

Más lectura en pantalla de FPS, `PhysicsStepTimeMs`, `MovingPrimitivesCount`, `InstanceCount` y
conteo de pila; y un simulador de multitud local (maniquíes con pila) para reproducir 8 jugadores
en solitario.

**La tensión con `AGENTS.md` §5.1 (prohibido construir UI por código) se resuelve así:** el panel
va authored en `StarterGui`, en una única `ScreenGui` llamada `_PerfPanel`, con `Enabled=false`
por defecto y un flag maestro en `GameConfig.Perf`. Es borrable de un tirón y no es UI de juego.
No incluir el bloque 4 del plan v3 (cheats de estado con RemoteEvent) hasta que haya lista blanca
por `UserId` validada **en servidor**.

### 0.10 Orden de trabajo propuesto

| Paso | Qué | Bloquea a | Estado |
| --- | --- | --- | --- |
| 1 | G1–G5 de §0.6 | nada | listo para aplicar |
| 2 | Panel de atribución authored + toggles 1–9 | todo lo demás | no empezado |
| 3 | Baseline Android low-end: 1 jugador, pila 0, cada toggle apagado uno a uno | 4, 5, 6 | no empezado |
| 4 | Presupuesto de §0.5 ajustado con los números reales del paso 3 | 5 | depende de 3 |
| 5 | Aserción agregada de §0.7 con `MaxMovingPartsPerClient` real | arte | depende de 4 |
| 6 | Presupuesto de VFX de §0.8 en `GameConfig` antes de authorizar los 17 trails | trails | depende de 4 |
| 7 | Matriz 8 jugadores × fill/clear/join de §0.8 histórica | lanzamiento | depende de 2 |

El paso 3 es el que convierte este documento de "lista de sospechosos" en "presupuesto con
dueños". Todo lo anterior a él son hipótesis con evidencia indirecta, y así deben tratarse.

### 0.11 Lo que falta para cerrar el diagnóstico

1. **Los dumps de MicroProfiler móvil ya capturados.** No están en el repositorio; sin ellos, las
   prioridades de §0.4 son orden de sospecha, no de medición.
2. Modelo/SoC/RAM del Android baseline elegido, para poder repetir.
3. Quién crea los 341 `TouchTransmitter` (§N4).
4. Si `MovingPlatforms` explica el `1,22 ms` de física cliente con pila 0 (§0.1).
5. Decisión de diseño sobre `GlobalShadows` y las 418 partes con `CastShadow`.

---


## 0. Estado operativo v3 — implementación mobile-first del 2026-08-13

Esta es la decisión vigente. Se adoptó directamente la Fase B: el servidor conserva la verdad
lógica de hasta 300 capturas por jugador y los clientes renderizan una representación cosmética
local, acotada y derivada de deltas/snapshots autoritativos. Las secciones posteriores se
conservan como evidencia histórica y plan de benchmark; ya no describen la arquitectura activa.

### 0.1 Resultado arquitectónico

| Responsabilidad | Implementación vigente |
| --- | --- |
| Progreso, requisitos y pickups | Autoridad exclusiva de servidor; no consulta geometría local |
| Pila lógica | `AttachmentService`, máximo 300 records compactos por jugador |
| Presentación | `AttachmentRenderer` client-local; cero `StickyPile`, parts o welds cosméticos en servidor |
| Presupuesto propio | 110 proxies de una parte `[PLACEHOLDER hasta Android]` |
| Presupuesto remoto | 20 proxies por jugador cercano `[PLACEHOLDER hasta Android]` |
| Techo por cliente | 320 proxies creados y 250 activos teóricos con 8 jugadores |
| LOD remoto | mostrar a 90 studs, ocultar a 110 studs, evaluación a 4 Hz |
| Clear | estado lógico atómico; liberación cliente `≤16` records o `≤1 ms` por frame |
| Red | `AttachmentVisual`, protocolo v1; batches de hasta 64 cada 0,10 s y snapshot con cooldown |

El alias `VisualAttachmentCount` se mantiene por compatibilidad, pero representa el conteo
lógico. El nuevo atributo canónico es `LogicalAttachmentCount`. Ninguno de los dos depende de
cuántos proxies decide materializar un teléfono.

### 0.2 Cambios implementados

- `ReplicatedStorage.Assets.AttachmentProxies`: 29 modelos authored, uno por collectible/blocker
  de ambos mundos; exactamente una `BasePart` por modelo, IDs únicos y física inerte.
- `ReplicatedStorage.Shared.AttachmentProxyTemplates`: registry que valida contratos e IDs; no
  genera geometría de fallback.
- `ReplicatedStorage.Shared.Remotes.AttachmentVisual`: único canal visual versionado. Del cliente
  solo acepta petición de snapshot; no acepta progreso ni records inventados.
- `ServerScriptService.Server.AttachmentService`: estado lógico, generación/secuencia, expulsión
  O(1) de normals, conservación de blockers protegidos, batch y snapshot por observador.
- `StarterPlayer.StarterPlayerScripts.Client.AttachmentRenderer`: slots precalculados, LOD,
  vuelos acotados, pool local, clear presupuestado y marcadores MicroProfiler.
- `CollectibleController` dejó de crear una tabla por candidato/tick y usa distancia al cuadrado.
- `ObjectLabelController` cura labels en cola bajo demanda, actualiza elegibilidad por evento,
  oculta tarjetas a más de 42 studs y clona `_FocusHighlight` authored.

### 0.3 Pruebas ejecutadas en Studio

| Prueba | Resultado |
| --- | --- |
| Contrato de proxies | PASS: 29 models, 29 parts, 29 IDs únicos, 0 errores de contrato |
| Arranque/handshake | PASS: `SnapshotReady=true`, conteos 0, servidor sin geometría cosmética |
| Pickup real | PASS: `ToyBlock` id 8; logical/legacy `0→1`; 1 proxy local |
| Requests inválidas | PASS: ID negativo, string y `NaN` lejos; progreso y pila sin cambios |
| Muerte/respawn | PASS: logical/active/metadata/pending `0`; nuevo pickup reutiliza pool |
| Stress | PASS: 300 deltas a ~96/s → 110 active/metadata, 110 parts/welds, 0 flags inseguros |
| Aislamiento server | PASS: 0 `StickyPile`, parts, proxies o welds cosméticos en servidor |
| Generaciones | PASS: add stale ignorado después de clear; add de generación vigente aceptado |
| Ciclo de vida | PASS tras corregir double-release: 10 + 50 ciclos, cola vuelve a 0 |
| Pool tras warm-up | PASS: fill final estable en 110 creados/activos; cap 320 no superado |
| Consola | PASS para este sistema; quedan warnings conocidos de `WorldService.DebugUnlock` y Team Create 503 |
| Teardown | PASS: Studio volvió a Edit, PlaceId correcto |

La prueba de ciclos detectó y corrigió un double-release: una cola antigua conservaba referencias
a records ya devueltos y readquiridos. Cada visual ahora transiciona exactamente una vez por
`Active → Queued → Pooled/Destroyed`; la cola elimina la referencia antes de liberar y `acquire`
solo acepta records `Pooled` válidos.

### 0.4 Estado de lanzamiento y gates restantes

Los cambios están en el DataModel abierto de Studio, pero el MCP disponible no expone Save ni
Publish. Team Create además devolvió 503 durante la sesión. Por tanto, **no están guardados ni
publicados live** y deben persistirse/publicarse manualmente después de revisar el diff de Studio.

Antes de declarar performance cerrada siguen siendo obligatorios:

1. prueba real de 2 y 8 clientes co-localizados, late join y salida de un owner;
2. Android low-end baseline y móvil mid-end, con thermal soak;
3. dumps MicroProfiler cliente/servidor para empty, fill, steady 110, clear y late join;
4. frame p50/p95/p99, `PhysicsStepTimeMs`, memoria y red antes/después;
5. pedestal, Replay y Rebirth con una recogida concurrente durante clear;
6. arte representativo dentro del contrato de una parte/triángulos/materiales.

No convertir `110`, `20`, `320`, `90/110 studs` ni `1 ms` en valores aprobados: permanecen
`[PLACEHOLDER]` hasta que pasen Android y 8 jugadores. El gate propuesto sigue siendo 30 FPS
estable en low-end (`p95 ≤33,3 ms`) sin picos de clear atribuibles al renderer.

---

## Registro histórico — Plan operativo v2, auditoría MCP del 2026-08-12

Esta sección registra el diagnóstico anterior a la implementación. Cuando una conclusión
contradiga el estado operativo v3, manda la v3.

### 0.1 Dictamen ejecutivo

La información disponible es **suficiente para diagnosticar y ordenar el trabajo**, porque el
MCP confirmó el `PlaceId 95828455414780`, leyó la implementación viva y permitió arrancar un
cliente y servidor limpios. No es suficiente para declarar cumplida la meta de 8 jugadores con
200–300 objetos en móviles low/mid-end: falta el escenario objetivo, arte representativo,
capturas MicroProfiler de dispositivo, late join y vaciados simultáneos.

La arquitectura actual tiene una base sana:

- objetos del suelo privados y renderizados localmente;
- progreso y pickups autoritativos en servidor;
- sensor único a 10 Hz en vez de `Touched` por objeto;
- attachments sin colisión, touch, query ni masa, y sin sombras;
- pools acotados, slots deterministas y limpieza explícita;
- un solo `Heartbeat` de attachments, conectado únicamente mientras anima.

El riesgo no está cerrado. La pila pegada sigue siendo geometría server-side soldada al
personaje y replicada a los observadores. Las pruebas históricas validan un jugador y el greybox
actual; no validan 8 pilas co-localizadas. Además, el `0,46 kbps` midió una pila ya construida y
quieta, no la creación, la animación, el clear, el stream-in ni el join.

**Decisión recomendada:** mantener 300 como conteo lógico/fantasía de colección, pero desacoplarlo
del presupuesto visual. El primer candidato de prueba es `110` proxies authored de una sola
parte por pila, con la misma silueta aproximada mediante `TargetMaxSizeStuds ≈ 2.3`.
`110` es una hipótesis `[PLACEHOLDER]`, no un valor aprobado. No restaurar 300 visuales en
producción hasta pasar los gates de la sección 0.8.

### 0.2 Hechos verificados mediante MCP

| Área | Estado observado el 2026-08-12 |
| --- | --- |
| Lugar | `Exposición pegajosa`, `PlaceId 95828455414780` |
| Configuración | `MaxVisualAttachments=36`, `PoolCapacity=400`, `TargetMaxSizeStuds=1.6`, shell `1.6–6.5` |
| Collectibles del suelo | 24 por zona por defecto, máximo 60; clones locales anclados y sin collide/touch/query |
| Sensor | `Heartbeat` permanente con trabajo cada `0.1 s`; recorre hasta 60 entradas |
| Pila pegada | clones server-side, una `WeldConstraint` directa al torso por cada `BasePart` |
| Física del attachment | `Massless=true`, `CanCollide/CanTouch/CanQuery=false`, `CastShadow=false` |
| Collision groups | no hay asignación de grupo en código; partes authored observadas en `Default` |
| Streaming | activo; los modelos authored usan `ModelStreamingMode.Default` |
| Plantillas actuales | 9; ocho tienen 1 `BasePart`, `ToyCar` tiene 2 |
| Contrato futuro | el validador permite hasta 8 partes por plantilla: no es un presupuesto móvil seguro |
| Baseline de Play | 1 jugador, pila 0, 24 collectibles locales, join de 29.109 bytes, consola sin errores |
| Baseline cliente | `PhysicsStepTimeMs≈0.064`, 367 primitives, 20 moving primitives |
| Baseline servidor | `PhysicsStepTimeMs≈0.015`, 321 primitives, 18 moving primitives |
| Memoria de audio cliente | `≈5,25 MB`; el mayor asset es el sonido core `FreeFalling` (`≈1,76 MB`) |
| Memoria de animación | `≈139 KB`, dos clips del avatar |
| Instancias sin parent | 11 cliente / 7 servidor; solo objetos pequeños de PlayerModule/Animate y BindableEvents persistentes de servicios |
| Memoria de scripts | consulta no disponible: `SceneAnalysisService` requiere el flag Studio `STUDIOPLAT37936` |
| Instrumentación | marcadores server `Sticky/*`; `GameConfig.Perf.Enabled=false` |

Los números de baseline son una comprobación de arranque, no un benchmark de capacidad. Studio
incluye editor, servidor y cliente, así que su memoria total tampoco representa la memoria de un
teléfono publicado.

### 0.3 Diagnóstico crítico priorizado

| Prioridad | Hallazgo | Consecuencia |
| --- | --- | --- |
| P0 | No existe prueba controlada `8 × 300` en móvil | No se puede aceptar la arquitectura actual como escalable todavía |
| P0 | La aritmética móvil histórica no cuadra | `400 partes × 1,4 µs ≈ 0,56 ms`, no `0,31 ms`; a 8 pilas son `≈4,48 ms` desktop y `≈22–45 ms` usando el propio factor móvil 5–10× |
| P0 | `ClearPlayerVisuals` libera toda la pila en un frame | Hitch ya confirmado: 10,6 ms Lua + frame posterior de 19 ms para 600 piezas en desktop |
| P0 | El coste escala por `BasePart`, pero el contrato permite 8 por prop | Peor caso teórico: `8 × 300 × 8 = 19.200 BaseParts` móviles |
| P1 | Réplica medida solo en steady state | Quedan sin medir create burst, vuelos server-side, clear, stream-in y late join |
| P1 | El pool de 400 está en `ServerStorage` y es global | Reduce clone/GC del servidor; no demuestra reutilización ni menor churn en clientes, y no absorbe 8 clears simultáneos |
| P1 | `applyGrowthStep` escala y resuelda toda la pila | El coste a 300 multiparte y 8 jugadores no está medido; la feature no justifica ese riesgo |
| P1 | Sensor/labels crean trabajo cliente no atribuido | Hasta 60 tablas de candidato a 10 Hz y `healLabel` sobre cada Billboard; son sospechosos plausibles de los ~30 ms móviles sin explicar |
| P1 | 24 `BillboardGui` visibles por sala | El tag `Prepare/Pass3dAdorn` debe medirse; Roblox recomienda reducir adornos visibles |
| P2 | No hay collision group dedicado | Es defensa adicional, no el gran ahorro: collide/touch/query ya están apagados y el impuesto está en la asamblea móvil |
| P2 | No apareció una retención grande en el baseline | Las 11/7 instancias sin parent son pequeñas y de ciclo de vida largo; repetir tras 10 ciclos para detectar pendiente, no declarar ausencia de leaks con una sola muestra |

Corrección de lenguaje: **la repetición visual del greybox actual es barata para batching; cada
`BasePart` móvil no es gratis para física.** “El número de objetos es casi gratis” no debe usarse
como afirmación global.

### 0.4 Principios de diseño que la optimización debe preservar

1. El jugador debe sentir acumulación continua; el contador lógico puede llegar a 300 aunque no
   haya 300 instancias visibles.
2. La pila propia comunica detalle y pickups recientes. Una pila remota solo necesita comunicar
   tamaño, progreso y personalidad a distancia.
3. La cadencia de recogida y el feedback inmediato no se reducen para salvar FPS.
4. Resetear la pila debe sentirse como una disolución satisfactoria, no como un congelamiento.
5. Todo valor numérico no validado se trata como `[PLACEHOLDER]` y vive en `GameConfig`.

### 0.5 Gains inmediatos — bajo riesgo, alto retorno

#### QW1 — Separar capacidad lógica y visual

Añadir configuración explícita. Mientras la geometría siga server-side, todos los observadores
reciben el mismo presupuesto visual; el LOD propio/remoto solo existe en Fase B:

```lua
LogicalAttachmentCapacity = 300
ServerVisualAttachmentBudget = 110 -- [PLACEHOLDER], Fase A
MaxAttachedPartsPerProxy = 1

-- Solo Fase B, cuando cada cliente sea dueño de la presentación:
OwnVisualAttachmentBudget = 110 -- [PLACEHOLDER]
RemoteVisualAttachmentBudget = 32 -- [PLACEHOLDER]
```

El progreso nunca depende del número de proxies visibles. La UI muestra el conteo lógico; la
presentación decide qué muestra. Si diseño exige que los 300 objetos sean individualmente
legibles y no acepta una representación condensada, esa condición debe probarse como variante
`300` y puede obligar a Fase B/C; `110` conserva silueta y sensación de volumen, no identidad
visual uno-a-uno.

#### QW2 — Contrato authored `AttachmentProxy`

Cada collectible debe ofrecer una variante authored para la pila, de exactamente una
`BasePart` o `MeshPart`. `AttachmentService` valida el contrato y falla explícitamente si falta;
no reconstruye geometría por código.

Presupuesto inicial de arte `[PLACEHOLDER]` para el peor mix visible:

- una parte por proxy;
- `≤250` triángulos p95 y `≤500` máximo por proxy;
- paleta/materiales compartidos y sin decal o `SurfaceAppearance` único por copia;
- `RenderFidelity = Performance` para `MeshPart` pegados;
- sin transparencia parcial salvo que una prueba A/B la justifique.

El modelo del suelo puede conservar más detalle; solo el proxy multiplicado por cientos tiene
este contrato.

#### QW3 — Vaciado con presupuesto y generación

- El estado lógico se limpia de forma atómica.
- Los visuals se pasan a una cola con `ClearBudgetMs = 2` `[PLACEHOLDER]` por frame.
- Cada pila lleva un `GenerationId`; una recogida, muerte o Rebirth durante el drain no puede
  mezclar generaciones ni devolver una instancia dos veces.
- Antes de reciclar se cancelan `Flight` y `Fade`, se retira el record de `animatedRecords` y se
  destruyen sus welds una sola vez.
- Gate: ningún `Sticky/ClearAll` consume más de 2 ms Lua en un frame y el clear no produce un
  frame cliente superior a 50 ms.

#### QW4 — Eliminar el rebuild global de crecimiento

No reescalar ni resoldar todos los records cada cinco pickups de overflow. Opciones, en este
orden:

1. eliminar el growth step y conservar crecimiento mediante nuevos slots;
2. aplicar escala solo al proxy que entra;
3. si diseño exige crecimiento global, cambiar de representación antes de optimizar el rebuild.

#### QW5 — Reducir trabajo del sensor y las tarjetas

- Separar elegibilidad de proximidad: repintar solo cuando cambia Stickiness o nace un item.
- En el tick de proximidad, calcular únicamente el más cercano y pickups en radio, sin crear una
  tabla `Candidate` por objeto.
- Comparar distancia al cuadrado; calcular magnitud solo para el candidato final si hace falta.
- Ejecutar `healLabel` en una cola de labels nuevas/defectuosas, no sobre las 24–60 cada 100 ms.
- A/B de `BillboardGui.Enabled`: mostrar tarjetas cercanas o enfocadas y ocultar las lejanas.
- Añadir marcadores `StickyClient/CollectibleSensor`, `LabelsApply`, `LabelsHeal`, `RoomItemsSync`
  y `Feedback` antes de afirmar que el coste es pequeño.

#### QW6 — Collision filtering defensivo, no multiplicativo

Mantener los cuatro flags físicos actuales. Si se quiere blindar el contrato, usar **un solo**
grupo global `AttachedVisuals` que no colisione con personajes ni mundo. No crear grupos por
jugador ni `NoCollisionConstraint` por pares: añadirían estado y constraints sin atacar el coste
medido.

### 0.6 Arquitectura/física por fases

#### Fase A — Welds server-side, pero con proxies y presupuesto universal menor

Es la ruta de menor cambio. Conservar `WeldConstraint` porque la comparación existente demuestra
que mover 600 partes por Lua cada frame fue 3× más caro en ese arnés. Esta conclusión solo aplica
a mover **todas** las partes **cada frame**; no descarta LOD ni presentación local.

Implementar QW1–QW5 usando `ServerVisualAttachmentBudget` y probar `36 / 110 / 300` con proxies
de una parte. En esta fase no existe LOD distinto por observador. No llamar
`SetNetworkOwner` de forma frecuente: medir primero `Distributed Physics Ownership`,
`Simulation/assemble`, `physicsStepped`, `SpatialFilter/filterStep`, `SolveBatch` e
`interpolateNetworkedAssemblies`.

#### Fase B — Servidor lógico + presentación local, si Fase A no pasa

El servidor conserva un ring compacto de hasta 300 records lógicos por jugador y sigue siendo
la única autoridad de progreso. No crea geometría cosmética ni anima CFrames.

Replica mensajes compactos:

- delta: `OwnerUserId`, `GenerationId`, `Sequence`, `SlotIndex`, `ProxyId`, `ScaleTier`;
- clear: `OwnerUserId`, `GenerationId`;
- snapshot de late join dividido en chunks pequeños y secuenciados.

Cada cliente mantiene pools locales acotados y aplica LOD por observador:

- pila propia: `110` proxies `[PLACEHOLDER]`;
- jugador remoto cercano: `16–32` proxies o clusters authored `[PLACEHOLDER]`;
- remoto lejano/fuera de frustum: cluster mínimo o cero;
- vuelos, fades y descartes: 100 % locales y con presupuesto.

Un cliente modificado solo puede falsear cosméticos en su pantalla; no obtiene Stickiness,
premios ni acceso. El servidor valida pickups y progreso igual que hoy.

#### Fase C — Clusters visuales, si diseño exige la silueta de 300

Usar clusters authored por niveles de llenado para que una pila remota sea 1–4 `MeshPart` en vez
de cientos. Conservar proxies individuales recientes en la capa exterior para que las recogidas
sigan siendo legibles. `EditableMesh` solo vuelve a evaluación si un prototipo en el dispositivo
baseline supera a clusters authored y respeta los límites vigentes; no es la primera opción.

### 0.7 Réplica y memoria

1. Medir cuatro ventanas por separado: join, fill, steady y clear. El promedio estacionario no
   sustituye bytes totales, pico de recepción ni tiempo de `Replicator/ProcessPackets`.
2. Si se mantiene server-side, el pool en `ServerStorage` se considera optimización del servidor,
   no del cliente, hasta demostrar lo contrario con deltas de instancias y allocations cliente.
3. Si se migra a visual local, el pool vive en cada cliente y se limita por proxy/LOD; nunca crece
   con la duración de la sesión.
4. Los slots son deterministas: no replicar `CFrame` por pieza si basta un índice y una semilla.
5. Chunkear el snapshot de late join para no materializar miles de instancias en un solo frame.
6. Tras diez ciclos fill/clear y diez respawns, `InstanceCount` y memoria deben estabilizarse;
   `StickyDiscards=0`, `Animating=0`, pool `≤cap` y cero estado del jugador que salió.
7. `StreamingEnabled` ayuda cuando jugadores están lejos, pero el benchmark obligatorio es la
   misma sala: es el peor caso y también el caso social buscado por el diseño.

### 0.8 Benchmark obligatorio y gates

#### Matriz mínima

| Eje | Casos |
| --- | --- |
| Jugadores | 1, 4 y 8 co-localizados |
| Visuales por pila | 0, 36, 110 y 300 |
| Partes por proxy | 1 y peor plantilla/cluster representativo |
| Estado | idle, fill sostenido, clear individual, clear de 8, late join, stream-in |
| Dispositivo | un Android low-end baseline y un móvil mid-end reales |
| Arte | greybox y mezcla de arte representativa |

Los clientes de carga pueden ser PC, pero el observador medido debe ser el teléfono. Registrar
modelo/SoC/RAM, OS, versión del cliente, nivel gráfico, tasa de refresco, temperatura, región,
ping, versión del place y configuración exacta.

#### Protocolo

1. Warm-up de 60 s y thermal soak antes de comparar.
2. Muestras de 120–300 s, tres repeticiones, orden A/B alternado.
3. Misma sala, cámara, ruta y cadencia de pickups.
4. Separar el período del arnés del período medido.
5. Guardar dump del MicroProfiler para cada transición y steady state; no basta una foto de la
   barra de Performance Stats.
6. En móvil: Settings → MicroProfiler On; abrir desde un PC en la misma red la IP/puerto que
   muestra el cliente, aumentar la captura a 90–256 frames y guardar el HTML.
7. Capturar servidor desde Developer Console → MicroProfiler → Server.
8. Comparar dumps antes/después con flame graph diferencial y conservar los archivos junto al
   resultado del test.

#### Métricas

- frame time cliente p50/p95/p99/máximo, CPU y GPU;
- `PhysicsStepTimeMs` p50/p95/p99;
- tiempos de `Simulation/assemble`, `physicsStepped`, `SpatialFilter`, `SolveBatch`,
  `interpolateNetworkedAssemblies`;
- `Net PacketReceive`, `deserializePacket`, `Replicator/ProcessPackets`, Data/Physics Senders;
- `Prepare/Pass3dAdorn`, `UpdateUILayouts`, `updateInstancedClusters`;
- marcadores `Sticky/*` de servidor y `StickyClient/*` propuestos;
- `InstanceCount`, `BaseParts`, welds, moving primitives y memoria por categoría;
- bytes totales, pico de KB/s y tiempo de proceso para join/fill/clear.

#### Gates `[TARGET PROPUESTO]`

| Gate | Low-end | Mid-end |
| --- | --- | --- |
| Frame p95 en `8 pilas × variante visual probada` | `≤33,3 ms` | `≤22,2 ms` |
| Frame p99 | `≤50 ms` | `≤33,3 ms` |
| Hitch máximo en 5 min | `<100 ms` | `<75 ms` |
| Delta de física atribuible a pilas | `≤20 %` del presupuesto de frame | `≤20 %` |
| Clear | `≤2 ms` Lua por frame y ningún frame `>50 ms` | igual |
| Red entrante | `Replicator/ProcessPackets` p95 `≤10 %` del frame; sin spike `>50 ms` por join | igual |
| Ciclo de vida | sin pendiente de memoria/instancias tras 10 fill/clear/respawn | igual |

Además deben pasar camino exitoso, rechazo por requisito/distancia/rate limit, doble petición y
limpieza con 2 y 8 jugadores.

### 0.9 Árbol de decisión

1. **Si `110` proxies de una parte pasa `8 × 300 lógicos`:** mantener pila server-side por ahora,
   aplicar clear presupuestado y cerrar el presupuesto de arte.
2. **Si steady falla por física:** reducir presupuesto visual remoto y probar Fase B.
3. **Si fill/join falla por red o materialización:** Fase B con deltas/snapshot chunked y pools
   locales.
4. **Si `Pass3dAdorn` o labels dominan:** culling de BillboardGui y actualización dirigida por
   eventos antes de tocar la pila.
5. **Si Lua domina:** optimizar los scopes nombrados; no introducir Parallel Luau sin un scope
   CPU puro, grande y demostrablemente paralelizable.
6. **Si GPU domina al llegar arte:** bajar triángulos/materiales/transparencia del proxy; no
   extrapolar desde las primitivas actuales.
7. **Si ninguna variante conserva la fantasía y pasa low-end:** diseño debe elegir entre menor
   concurrencia visual, clusters más abstractos o un objetivo de dispositivo/FPS distinto.

---

> **Registro histórico v1:** las secciones siguientes documentan cómo se llegó hasta aquí. Sus
> mediciones siguen siendo evidencia útil, pero sus conclusiones arquitectónicas quedan
> restringidas al arnés, plataforma y concurrencia que realmente se probaron.

## 1. El problema original

El límite de objetos pegados al jugador cortaba el bucle de satisfacción. Se pedía escalabilidad masiva. El encargo incluía evaluar cuatro arquitecturas alternativas (CFrame directo + pooling, servidor abstracto + cliente visual, poda de geometría interna, y `EditableMesh`).

**El encargo partía de una premisa falsa**, y eso es el hallazgo principal de este documento: el tope de 36 no era un límite de rendimiento.

---

## 2. Regla que salió de aquí, y que vale para todo el proyecto

> **Medir el coste antes de diseñar la solución.**

Durante esta sesión se formularon **cinco hipótesis razonables** sobre dónde estaba el coste. Las mediciones las refutaron o rebajaron **para el arnés de un jugador/escritorio**; no todas quedaron refutadas para creación activa, late join ni `8 × 300` en móvil:

| # | Hipótesis | Refutada por |
| --- | --- | --- |
| 1 | Los draw calls escalan con la pila | +0,81 draw calls con 49 partes; +1 con 4.834 |
| 2 | El churn de welds de `applyGrowthStep` revienta primero | 0 tirones con los 5 growth steps disparados |
| 3 | La réplica steady-state de una pila ya creada es el muro | 0,46 kbps con 300 piezas quietas; creación y join quedaron sin medir |
| 4 | Cada recogida fuerza un rebuild caro de asamblea | Delta por weld idéntico con 0 y con 600 piezas |
| 5 | Sacar las piezas de la asamblea y moverlas a mano las abarata | `BulkMoveTo` cuesta **3×** más que soldar |

**Corolario práctico histórico:** no hacía falta una reescritura para quitar el límite de layout ni para llegar a 300 en un jugador de escritorio. La necesidad arquitectónica para `8 × 300` móvil quedó abierta y se decide con los gates de la sección 0.

---

## 3. Trampas de medición encontradas (leer antes de medir cualquier cosa)

1. **El frame time no sirve como métrica mientras haya margen.** VSync lo clava en 16,67 ms hasta que la máquina se ahoga del todo. Un coste creciente es invisible. **Usar `Stats.PhysicsStepTimeMs`**, que no está capado.
2. **Toda medición de FPS debe validarse contra el foco de la ventana.** Windows desprioriza ventanas en segundo plano y Roblox baja su render a ~15 FPS. Una medida tomada sin foco sale como un 15 sospechosamente exacto. Los arneses de este proyecto escuchan `UserInputService.WindowFocused` / `WindowFocusReleased` y **repiten la muestra** en vez de publicar un número falso.
3. **`PerformanceStats.CPU` leído dentro de Studio está contaminado por el editor.** Marcó 67,5 ms con el juego a 60 FPS. No es comparable con el mismo contador en un cliente publicado.
4. **Un PC tope de gama no puede reproducir un problema de celular.** 2.004 partes soldadas y en movimiento dieron **delta cero** en frame time y en el contador de CPU. No hay configuración que lo sortee.
5. **`execute_luau` de la herramienta MCP tiene su propia caché de módulos.** Un `require` desde ahí devuelve una copia, no la instancia viva. Toda sonda debe publicar por **atributos**, y todo disparador debe ser un atributo, no una función.
6. **`start_stop_play(true)` agotó el tiempo de espera durante la sesión del 2026-08-11.** No es una limitación permanente: el 2026-08-12 arrancó y detuvo Play correctamente por MCP. Si vuelve a fallar, registrar el bloqueo y usar F5, sin asumir que siempre falla.

---

## 4. Registro de mediciones

### 4.1 Render — clones locales soldados al personaje (escritorio, foco validado)

| Piezas | Partes | FPS | Peor frame | Draw calls | Moving primitives |
| --- | --- | --- | --- | --- | --- |
| 0 | 0 | 60,0 | 18,4 ms | 12 | 20 |
| 100 | 322 | 60,0 | 18,5 ms | 28 | 180 |
| 300 | 966 | 60,1 | 18,4 ms | 28 | 402 |
| 600 | 1.934 | 60,1 | 18,8 ms | 17 | 687 |
| 1.000 | 3.222 | 60,1 | 18,2 ms | 20 | 1.131 |
| 1.500 | 4.834 | 60,1 | 18,6 ms | 18 | 1.687 |

Memoria total en todo el rango: **+1 MB**. Los draw calls varían más con el ángulo de cámara que con el número de piezas.

**Prueba A/B controlada** con `LocalTransparencyModifier` sobre una pila real llena: **49 partes = +0,81 draw calls.**

**Causa:** las 9 plantillas son `Part` primitivas de 3 formas (Block/Ball/Cylinder), un solo material `SmoothPlastic`, cero texturas, cero `SurfaceAppearance`. El instancing de Roblox las colapsa en los lotes que la escena ya dibuja.

### 4.2 Sistema real server-side — curva de llenado (1 jugador)

| Pila | InstanceCount | Δ | DataSendKbps | MemoryPartsMb | Frame servidor |
| --- | --- | --- | --- | --- | --- |
| 0 | 39.827 | — | 0,33 | 2,15 | — |
| 26 | 39.924 | +97 | 7,34 | 2,35 | 16,68 ms |
| 51 | 40.014 | +187 | 7,07 | 2,54 | 16,64 ms |
| 100 | 40.195 | +368 | 7,70 | 2,94 | 16,67 ms |
| 150 | 40.386 | +559 | 7,00 | 3,36 | 16,68 ms |
| 203 | 40.577 | +750 | 10,00 | 3,77 | 16,67 ms |
| 250 | 40.746 | +919 | 9,89 | 4,16 | 16,68 ms |
| 300 | 40.930 | +1.103 | 4,30 | 4,55 | 16,64 ms |

**El `DataSendKbps` de la tabla es del arnés de prueba, no de la pila** (teletransportes y remotes de pickup del script de farmeo). Con el arnés parado y 300 piezas encima el envío cae a **0,46 kbps**, contra 0,33 en reposo con la pila vacía.

**Coste unitario: 3,68 instancias por pieza** (Model + Part(s) + WeldConstraint(s)) y **~8 KB de memoria por pieza**.

Cliente con 300 piezas, foco validado: `Fps 59,95`, `PeakFrameMs 18,35`, **`SpikeCount 0`**.

### 4.3 Coste de física — el mecanismo real

| Piezas soldadas | `PhysicsStepTimeMs` |
| --- | --- |
| 0 | 0,121 ms |
| 100 | 0,190 ms |
| 300 | 0,619 ms |
| 600 | 0,868 ms |

Lineal: **~1,4 µs por parte y por paso de física**. No es un pico por recogida: es un **impuesto permanente** mientras las piezas estén puestas, y se paga por cada pila cargada en el cliente, propia o ajena.

### 4.4 Anclada vs soldada vs movida a mano (600 partes)

| Modo | Física | Lua | Coste añadido |
| --- | --- | --- | --- |
| Ancladas, quietas | 0,022 ms | 0 | **0,022 ms** |
| Ancladas + `workspace:BulkMoveTo` cada frame | 0,043 ms | 1,434 ms | **1,455 ms** |
| Soldadas a `UpperTorso` | 0,490 ms | 0 | **0,468 ms** |

Las partes ancladas y quietas son gratis: **el coste es al 100 % pertenecer a la asamblea en movimiento**. Pero moverlas a mano cuesta **3× más** que dejar que el motor propague la asamblea; el gasto son las 600 multiplicaciones de `CFrame` en Lua.

> **Conclusión limitada al arnés:** soldar fue la forma más barata de mover 600 partes cada frame. La palanca inmediata es reducir partes; LOD, clusters y presentación local con menos proxies no quedaron refutados.

### 4.5 Los hitches

Vaciar la pila de golpe: **600 piezas = 10,6 ms de Lua + frame siguiente de 19 ms** en escritorio. Del orden de 50–100 ms en celular.

`ClearPlayerVisuals` se llama al **cobrar un pedestal**, al morir, en el **ReplayPad** y en el **Rebirth** — o sea, en el bucle central — y lo sufre todo el que tenga esa pila cargada, no solo su dueño.

### 4.6 Medición en celular multijugador (barra de Performance Stats)

| | Captura 1 | Captura 2 |
| --- | --- | --- |
| CPU | **45,70 ms** | **39,08 ms** |
| GPU | **5,98 ms** | **5,41 ms** |
| Recibidos | 46,41 KB/s | 40,23 KB/s |
| Enviados | 9,45 KB/s | 8,10 KB/s |
| Ping | 117 ms | 113 ms |

**En esas dos capturas el cuello predominante fue CPU** (`39–46 ms` frente a `5–6 ms` de GPU). Esto rebaja render en el greybox observado, pero no elimina draw calls, overdraw ni LOD del análisis futuro con arte real.

**Aritmética corregida:** usando la pendiente documentada de `~1,4 µs/BasePart/paso`, 300 piezas ≈ 400 partes implican `~0,56 ms` de delta en escritorio, no `0,31 ms`. Cuatro pilas serían `~2,24 ms` y ocho `~4,48 ms`; con el factor móvil hipotético 5–10× usado en esta sesión, ocho pilas proyectan `~22–45 ms`. Es una extrapolación, no una medición, pero impide cerrar el riesgo sin probar el escenario objetivo.

### 4.7 Intento fallido de reproducir el problema en escritorio

Maniquíes con pilas soldadas orbitando (rampa 1/2/4/6 × 300 piezas):

| Maniquíes | Partes | Frame |
| --- | --- | --- |
| 0 | 0 | 16,67 ms |
| 1 | 300 | 16,66 ms |
| 4 | 1.200 | 16,68 ms |
| 6 | 1.800 | 16,68 ms |

Y el contador de CPU: **67,5 ms con y sin 2.004 partes. Delta cero.**

**El escritorio no puede reproducir el problema.** Ver trampa 4 de la sección 3.

---

## 5. Cambios aplicados

### 5.1 Distribución paramétrica de slots — `AttachmentService.buildSlots`

`GameConfig.Attachments.Rings` (5 anillos escritos a mano) sustituida por `GameConfig.Attachments.Shell`.

El `assert` que exigía que la suma de los anillos diera exactamente `MaxVisualAttachments` **era el límite real de 36**, no el rendimiento.

La nueva fórmula separa dirección de radio, y esa separación es lo importante:

- **Radio:** crece con la **raíz cúbica** del índice del slot. Única curva que da densidad uniforme en volumen; con crecimiento lineal las piezas se amontonan en el centro y la bola se ve hueca. Consecuencia buscada: las primeras piezas quedan pegadas al cuerpo y la bola crece hacia fuera según se llena.
- **Dirección:** secuencia **R2 de baja discrepancia**, no espiral de Fibonacci clásica. En la de Fibonacci la latitud se deriva del propio índice, así que la pila se llenaría barriendo de un polo al otro. Verificado antes de correrla: con 12 piezas ya ocupa 7 de 8 octantes; con 36, los 8 equilibrados.

### 5.2 Configuración

| Clave | Antes | Ahora |
| --- | --- | --- |
| `MaxVisualAttachments` | 36 | **36** (temporal — ver 6.1) |
| `PoolCapacity` | 72 | 400 |
| `Rings` | 5 anillos | eliminada |
| `Shell` | — | `MinRadius 1.6`, `MaxRadius 6.5`, `VerticalScale 0.75`, `VerticalOffset -0.3` |
| `Perf.Enabled` | — | `false` (apagada para no contaminar la prueba de celular) |

`MaxVisualAttachments` llegó a estar en 300 y se verificó estable. Está en 36 **solo como experimento de una variable** para medir en celular.

### 5.3 Sondas de rendimiento

`ServerScriptService.Server.PerfProbe` y `StarterPlayer…Client.PerfProbeController`. Apagables desde `GameConfig.Perf`; apagadas no dejan conexiones ni instancias.

Decisiones de diseño que conviene no deshacer:

- **Publican por atributos, no por API.** `execute_luau` no puede leer estado vivo de un servicio.
- **El reset se dispara con el atributo `ResetRequested`**, por la misma razón. Sin él habría que reiniciar Play entre cada corrida.
- **El folder del servidor vive en `ServerStorage`, no en `Workspace`.** Allí sus atributos se replicarían a todos los clientes cada segundo, y una sonda que mide replicación no puede añadir replicación propia.
- **Miden el pico, no la media.** `PeakFrameMs` junto a `PeakAtPileCount` contestan "con cuántas piezas encima llega el tirón". Una media esconde el stall de un frame.
- **Guardan la curva ellas mismas** en marcas fijas (25/50/100/150/200/250/300), para que una corrida deje los puntos escritos aunque el MCP agote el tiempo o Studio se caiga.
- **Delta de `InstanceCount` por frame**, que separa "CPU sostenida" de "tirón por churn". Mide el contador del motor, no uno propio, así que captura todas las fuentes y no acopla la sonda a ningún servicio.

### 5.4 Etiquetas de MicroProfiler en `AttachmentService`

`Sticky/PlaceAndWeld`, `Sticky/ClearAll`, `Sticky/GrowthStep`, `Sticky/Acquire`, `Sticky/Animations`.

Cuestan cero cuando el profiler no está grabando. `acquireVisual` se reescribió con una sola salida: su `return` temprano dejaba un `profilebegin` sin cerrar, y eso corrompe el profiler.

---

## 6. Plan de implementación pendiente

### 6.1 Hito A — Medición en celular (bloqueante, decide todo lo demás)

Publicar con `MaxVisualAttachments = 36` y repetir la prueba multijugador en celular, en condiciones comparables a las capturas de 4.6 (misma zona, gente parecida, pila llena).

| Resultado | Interpretación | Siguiente paso |
| --- | --- | --- |
| CPU baja mucho (45 → ~25 ms) | La pila es fracción grande | Hito B con el valor de compromiso |
| CPU casi no se mueve | La pila **no** es el problema | Hito C: buscar los ~30 ms en otro sitio |

**Un experimento que solo puede confirmar no sirve. Éste puede refutar.**

Aviso: a 36 la bola se ve hueca, porque el radio se reparte sobre el tope. Es esperado y temporal.

### 6.2 Hito B — Panel de depuración en dispositivo

Herramienta que convierte el celular en el instrumento de medida, que es lo único que funciona (trampa 4).

**Bloques sin servidor — riesgo cero, contestan la pregunta de CPU:**

1. **Toggles de atribución:** pila propia, pilas ajenas, objetos del suelo, tarjetas de requisito (`BillboardGui`), auras y trails, HUD. Se apaga un sospechoso y se mira el delta de CPU en la barra de Roblox. Es la atribución que el escritorio no puede dar.
2. **Simulador de multitud:** maniquíes locales con pila, para simular 8 jugadores en solitario.
3. **Lectura en pantalla:** FPS, paso de física, primitivas en movimiento, instancias, conteo de pila.

**Bloque con servidor — requiere lista blanca:**

4. **Cheats de estado:** saltar de zona, regalar Stickiness, llenar la pila.

> ⚠️ **Seguridad.** El juego se publica. Un `RemoteEvent` que conceda progreso lo puede disparar **cualquier** cliente. El bloque 4 exige validación por `UserId` **en servidor** y un flag maestro en `GameConfig` para apagarlo antes del lanzamiento real. Los bloques 1–3 son cliente puro y no abren nada: un exploiter que los use solo se estropea su propia pantalla.

**Tensión con `AGENTS.md` 5.1:** la regla prohíbe construir UI por código. El panel es herramienta de desarrollo, no UI de juego, y debe poder borrarse de un tirón. Pendiente de decidir si se acepta como excepción documentada o se deja authored en `StarterGui`.

### 6.3 Hito C — Arreglos, solo con número que los justifique

| Arreglo | Ataca | Estado |
| --- | --- | --- |
| **Menos partes, más grandes** | CPU sostenida | ✅ Listo para aplicar, **gratis** |
| **Vaciado por presupuesto de frames** | Los hitches | ⏸️ Pendiente de decisión |
| Unificar geometría (`EditableMesh`) | CPU sostenida | ⏸️ Solo si lo anterior no basta |

**Palanca gratis y no obvia:** el tamaño visual de la bola lo fija `Shell.MaxRadius`, **no el número de piezas**. Subir `TargetMaxSizeStuds` y bajar `MaxVisualAttachments` conserva la silueta con una fracción de las partes.

```
hoy:      MaxVisualAttachments = 300   TargetMaxSizeStuds = 1.6
opción:   MaxVisualAttachments = 110   TargetMaxSizeStuds = 2.3
```

Mismo volumen (300 × 1,6³ ≈ 110 × 2,3³), misma bola de 13 studs, **~2,7× menos partes**. Dos valores en `GameConfig`, cero código, reversible.

**Vaciado por frames:** liberar N piezas por frame en vez de todas. Riesgo real a manejar: si el jugador recoge a mitad del vaciado se mezclan dos pilas. Efecto secundario probablemente bueno — la bola se deshace en vez de parpadear.

**`EditableMesh` cambió de veredicto dos veces y conviene registrar por qué.** Se descartó porque su premisa (ahorrar draw calls) resultó falsa: ya estás en ~3 draw calls. Vuelve a la mesa **por un motivo distinto**: si el cuello es CPU y lo empuja el número de partes, unificar geometría reduce primitivas en movimiento. Sigue cargando sus problemas reales: **no replica** entre servidor y cliente, el cliente admite **un máximo de 8 `EditableMesh` simultáneos**, y no hay geometría fuente que unir porque las plantillas son primitivas y no `MeshPart`.

---

## 7. Qué decirle al equipo de diseño

> **Para batching del greybox, repetir pocos assets es barato. Para física, cada `BasePart` móvil tiene coste.**

En render, 300 copias de 9 props compartidos son mucho más baratas que 300 props únicos con texturas y materiales distintos. En física, el presupuesto correcto sigue siendo el total de `BasePart` y constraints dentro de asambleas móviles, no solo la variedad visual.

Rompe el instancing, y por tanto multiplica el coste:

| Qué | Por qué |
| --- | --- |
| Una textura o decal por prop | Roblox documenta que texturas y partículas no batchean bien |
| Un material distinto por prop | Cada material es su propio lote |
| `SurfaceAppearance` (PBR) único por prop | Rompe el instancing |
| **Transparencia parcial** | Pasa a un pase ordenado aparte y multiplica el overdraw |

**El riesgo real cuando el greybox pase a arte: triángulos.** Un `Block` son 12 triángulos. Con arte a 500 triángulos por prop:

```
300 piezas × 500 tri = 150.000 triángulos sobre un solo personaje
```

...antes del resto de la escena. Ese es el número que hay que llevar a una prueba en celular.

**Tres peticiones concretas:**

1. **Paleta de materiales compartida.** Uno o dos materiales para todos los props pegables, no uno por prop.
2. **Presupuesto de triángulos por prop**, elegido con la aritmética de arriba.
3. **Los props pegados se encogen a 1,6 studs**, así que el detalle no se ve. Al pasar a `MeshPart`, poner **`RenderFidelity = Performance`** en el clon pegado hace que Roblox use su malla de menor detalle automáticamente. Es gratis y es exactamente para esto.

Nada de esto limita la libertad artística de los props en el suelo. Limita lo que se pega al cuerpo, que es donde se multiplica por cientos.

---

## 8. Debilidades conocidas de la implementación actual

Reevaluadas contra medición. El orden cambió respecto a la primera intuición.

| # | Debilidad | Magnitud real |
| --- | --- | --- |
| 1 | **`ClearPlayerVisuals` vacía la pila en un frame** | 10,6 ms por 600 piezas, en el **bucle central**, y crece con el tope |
| 2 | **Todo es server-side y replica a todos** | 1.104 instancias por jugador remoto co-ubicado. Mitigado por `StreamingEnabled` para jugadores lejanos, pero el diseño busca que compartan sala |
| 3 | La animación de vuelo corre en el servidor | Menor: es O(recogidas/s), **no** O(tamaño de pila). ~32 piezas en vuelo como mucho |
| 4 | `PoolCapacity` es global, no por jugador | Menor. Clonar es barato (165 ms por 1.000 clones); el pool evita churn de GC, no un cuello |
| 5 | `applyGrowthStep` reconstruye todos los welds | Menor con el tope alto: solo dispara con la pila llena. **Puede que la mejor solución sea borrar la feature**, no optimizarla |

**Lo que está bien hecho y no conviene tocar:** física apagada con los cuatro flags + `Massless`; object pooling; `CastShadow = false`; plantillas authored clonadas y no construidas; slots deterministas; limpieza en `CharacterRemoving`, `PlayerRemoving` y `Destroy`; y el `Heartbeat` de animación conectado **solo mientras algo anima**.

---

## 9. Sin medir

1. **Multijugador real.** Todo se midió con 1 jugador. La prueba con 2 jugadores sigue pendiente desde el 2026-08-03 (`MANUAL_TEST_CHECKLIST.md`).
2. **Coste de join.** Quien entra a un servidor con pilas llenas recibe todas esas instancias de golpe. Con la pila vacía el join transmitió 29.129 bytes.
3. **Los ~30 ms de CPU en celular que no explica la pila.** Sospechosos por orden: tarjetas de requisito (`BillboardGui`, 24 por sala, notoriamente caras en móvil), decodificación de replicación entrante (40–46 KB/s medidos), y la UI del HUD.
4. **Móvil con arte real.** Todo el greybox actual son primitivas de 12 triángulos.
