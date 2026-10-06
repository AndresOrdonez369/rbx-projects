# Plan de implementación — Residuo, Máquina Aspiradora y Blobs de recompensa

**Fuentes:** `Residuo, Máquina Aspiradora y Pestaña Cosmética.md` (la máquina) y `Blobs como recompensa- producción, propiedades y encaje con la máquina aspiradora.md` (los blobs).
**Reglas que manda el proyecto:** `AGENTS.md` (pruebas, ciclo de vida, `GameConfig` como única fuente de balance, instancias authored, localización).
**Alcance de v1:** World 1 completo, 7 items. Worlds 2 y 3 quedan fuera y con su decisión estructural (variantes) tomada **antes** de construir la segunda máquina.

---

## 0. Lo que este plan añade a los dos documentos

Los dos documentos están completos por separado y cada uno trae su propia lista de fases. Puestos juntos aparecen tres cosas que ninguno resuelve solo:

| # | Qué falta cuando se leen juntos | Dónde lo resuelve este plan |
| --- | --- | --- |
| 1 | **Las dos listas de fases se pisan.** La fase 3 de la máquina («revelado con un cosmético de prueba») no puede empezar hasta que la fase 2 de los blobs haya validado que el modelo de capa funciona | §2 — dos carriles con un punto de encuentro explícito |
| 2 | **No hay fase de catálogo.** Los 21 items están propuestos en una tabla, pero nadie los ha convertido en fichas producibles con presupuesto, nombre, rareza y criterio de aceptación | §5 — **Fase P (Propuestas)** |
| 3 | **No hay fase de producción.** «4 paletas + 2 elementos + 1 épico» es un renglón de una tabla, y es la mitad del trabajo real | §6 — **Fase G (Generación)** |

Y tres correcciones que salen del cruce, todas pequeñas pero que hay que escribir antes de empezar (§9).

---

## 0.1 Decisiones tomadas — 2026-09-19

| # | Decisión | Resuelta así |
| --- | --- | --- |
| **Pesos del sorteo** | §4.8 del documento de la máquina contradecía a §4.4 | **Manda §4.4: `18 / 11 / 6` por item.** El equivalente por tier es `72 / 22 / 6`, no `60/30/10` — ese era el reparto de la versión de 15 items. §4.8 corregido en el documento fuente |
| **Localización** | No estaba en ninguna fase | **Fase `L`, última del plan** (§4.8). Cada fase entrega sus claves sobre la marcha; `L` es la auditoría de cierre que garantiza que no queda una sola cadena a mano |
| **Instancias authored** | Duda sobre qué se crea en el editor | **Sin excepciones: todo se crea en el editor.** Pad, máquina, cartel, ancla de revelado, `_BlobRow`, `_GroupHeader` y las piezas del épico. El código localiza, clona, escribe texto y color — nada más |
| **Variantes** | Decidir antes o después de M4 | **Antes.** La persistencia de M4 guarda **un contador por item**, no un booleano de poseído. Las variantes no entran en v1, pero el sitio queda hecho y no habrá migración de perfiles |

---

## 1. Decisiones que bloquean el arranque

Ninguna fase empieza sin estas cuatro. Son minutos de conversación, no de trabajo, pero cada una puede invalidar una semana.

| # | Decisión | Por qué bloquea | Recomendación |
| --- | --- | --- | --- |
| **D1** | **¿Dónde se construye?** Producción (`95828455414780`) o laboratorio (`123113535376730`) | Studio está abierto en producción. La fase G escribe sobre las 24 plantillas de blob | **Laboratorio para las fases B0–B2 y P.** Producción, con backup, a partir de M1 |
| **D2** | **Quién guarda y publica** | El MCP no expone Save/Publish. Aparece como pendiente en cinco documentos del proyecto | Al cerrar cada fase, tú guardas y publicas, y se anota en `PROJECT_MEMORY.md` |
| **D3** | **¿Vía A o vía B para las paletas?** | Decide si los 12 comunes de los tres mundos cuestan 0 assets o 12 PNG subidos y moderados | **La fase B1 lo decide con datos**, no antes. Fallback garantizado: vía B, que ya está en producción |
| **D4** | **¿Entra el épico en v1?** | Es el único item que toca física y el único que necesita `generate_mesh` | **Sí, pero es el primero que se cae** si la fase M4 llega tarde (§8) |

---

## 2. La estructura: dos carriles y un punto de encuentro

Los dos carriles son independientes hasta el final y **se pueden trabajar a la vez**. Eso importa porque el carril de blobs tiene el riesgo que puede tumbar el diseño entero (¿funciona el modelo de capa?) y el carril de la máquina tiene el riesgo que puede descuadrar el presupuesto de contenido (¿cuánto se acorta World 1?). Los dos hay que saberlos pronto, y no dependen uno del otro.

```
CARRIL A · BLOBS                          CARRIL B · ECONOMÍA Y MÁQUINA
─────────────────────────────             ─────────────────────────────
B0  backup + banco de pruebas             M0  medir el antes (cronometrado)
B1  ⭐ test de EditableImage               M1  retirar el requisito + medir el después
B2  ⭐ un elemento, tres siluetas          M2  el Residuo existe (moneda + HUD + etiqueta)
    │                                     M3  la máquina sin premios
    ▼                                         │
P   ⭐ PROPUESTAS — las 7 fichas de W1         │
    │                                         │
    ▼                                         │
B3  tabla Elements + resolveBlobLook          │
B4  BlobMotionController                      │
    │                                         │
    ▼                                         │
G   ⭐ GENERACIÓN — producir los 7 ────────────┤
                                              ▼
                                          M4  el pool de World 1 (sorteo real)
                                              │
                                              ▼
                                          M5  la pestaña BLOBS
                                              ▼
                                          M6  instrumentación
                                              ▼
                                          M7  presupuesto en móvil  ← no se publica sin esto
                                              ▼
                                          L   ⭐ LOCALIZACIÓN — auditoría de cierre
```

**El punto de encuentro es M4.** Todo lo que está por encima puede ir en paralelo; nada por debajo puede empezar sin los dos carriles cerrados.

**Y una dependencia blanda:** M3 necesita **un** cosmético de prueba para el revelado. Ese cosmético sale de B2 (el `Ember` del banco de pruebas), no de G. Basta con uno y puede ser feo.

---

## 3. Carril A — Blobs, fases B0 a B4

### B0 · Backup y banco de pruebas

| | |
| --- | --- |
| **Qué** | `BlobElementsBackup_<fecha>` en `ServerStorage` con las 24 plantillas. Duplicados de `Lvl01_b`, `Lvl04_b` y `Lvl08_b` en `ServerStorage` para trabajar sin tocar los originales |
| **Herramienta** | `execute_luau` |
| **Criterio** | El backup existe, está fechado, y los tres duplicados cargan en una escena de prueba |
| **Riesgo que cubre** | Que la primera escritura sobre un blob rompa la jerarquía de huesos sin vuelta atrás. Es lo que salvó la sesión del mapeo invertido de texturas |

#### ✅ Cerrada — 2026-09-19

`ServerStorage.BlobElementsBackup_20260919` contiene las **24 plantillas**, una copia de `GameConfig` como `GameConfig_BeforeElements`, y el banco `TestBench` con `Lvl01_b_bench`, `Lvl04_b_bench` y `Lvl08_b_bench`.

#### ⚠️ Y el censo destapó algo que ningún documento recoge: **el rig no es uniforme**

| Tier | Huesos | Emisores |
| --- | --- | --- |
| **Lvl01 – Lvl03** | **5** — `root`, `spine_01..04` | **1** — solo `PrestigeAura` |
| **Lvl04 – Lvl08** | **8** — los anteriores + `spine_05`, `Left`, `Right` | **3** — `PrestigeAura`, `PrestigeMist`, `PrestigeBurst` |

Idéntico en los tres mundos (verificado en las 24). Los dos documentos generalizan desde `Lvl08_b` («8 Bones, 3 emisores») y eso **no vale para los tres primeros peldaños**. Tres consecuencias directas:

1. **Un perfil de `BoneMotion` que escriba a `spine_05` / `Left` / `Right` no hace nada en los tiers 1–3**, y no da error. Falla en silencio, que es la peor forma.
2. **Un elemento cuyo perfil de emisores nombre `PrestigeMist` o `PrestigeBurst` no encuentra nada en los tiers 1–3.** El elemento tiene que **degradar**, no asumir tres capas.
3. ⭐ **El banco de pruebas elegido es el correcto por accidente feliz**: `Lvl01` (5/1), `Lvl04` (8/3) y `Lvl08` (8/3) cruzan justo el escalón. B2 va a ver el problema si existe.

> **Regla que se añade a la fase P:** toda ficha declara su comportamiento **con 1 emisor y con 3**, y su `BoneMotion` nombra huesos que existen en los 8 tiers (`root`, `spine_01..04`) o declara explícitamente su degradación.

### B1 · ⭐ El test de `EditableImage` (decide D3)

| | |
| --- | --- |
| **Qué** | Leer el atlas base con `CreateEditableImageAsync`, rotar el tono de las **filas 0–3** con la curva `v' = 1-(1-v)^1.9`, escribir con `WritePixelsBuffer`, asignar por `Content.fromObject` a un duplicado |
| **Criterio de paso** | Un blob de otro color **con los ojos intactos**, verificado por test de píxel: las 8 celdas de las filas 4–5 idénticas al original, byte a byte |
| **Y además hay que medir, no solo mirar** | 1) Memoria en **Android real** — es el hueco de verificación de siempre del proyecto. 2) Coste de 12 `EditableImage` vivas contra 1 cacheada compartida. 3) Si 128² basta en vez de 512² (1/16 de memoria). 4) Que la imagen se suelte al morir, viajar y reconectar |
| **Si falla** | Vía B: PNG generados aquí, importados por ti en el Asset Manager. El pool de comunes pasa de «gratis» a «12 assets moderados», y la fase G se alarga |

> **Este test se hace antes que nada del carril A y no se puede saltar.** Diseñar 21 items encima de una API que no rinde en móvil es exactamente el error que el documento de blobs escribió para evitar.

#### ✅ Resultados medidos — 2026-09-19, place de producción, modo Edit

| Comprobación | Resultado |
| --- | --- |
| `CreateEditableImageAsync` sobre el atlas W1 | **OK.** 512×512, rejilla 4×6, las 24 celdas coinciden **byte a byte** con lo documentado |
| Recoloreo a naranja (tono 27°, sat ×1,15, curva 1,9) **contra el atlas W2 que ya está en producción** | ⭐ **Delta máximo por canal: 0.** La vía A reproduce el asset subido **píxel a píxel** |
| Filas 4 y 5 tras el recoloreo | **0 píxeles alterados** en barrido completo, no solo en centros de celda |
| `Content.fromObject` → `MeshPart.TextureContent` | **OK** sobre las tres plantillas del banco |
| Coste de una paleta a 512² | **1,00 MB** cada una. 12 vivas = **12,1 MB**, lineal: no comparten nada |
| `EditableImage:Destroy()` | **Libera los 12 MB enteros.** La ruta de soltado funciona |
| Bajar la paleta a 128² | **Delta 0 en las 24 celdas.** La rejilla sobrevive intacta — son rectángulos planos |
| Coste a 128² | **64 KB** por paleta. **1/16** |

#### ✅ Resuelto — `Allow Mesh & Image APIs` activado, 2026-09-19

Activada la opción, se repitió todo **en modo Play**. Funciona. Y el desglose de coste desmonta el susto inicial de los 436 ms:

| Paso | Coste | Notas |
| --- | --- | --- |
| `CreateEditableImageAsync` del atlas base, **en frío** | **264 ms** | Es una llamada que cede (yield), no un frame congelado. **Y se paga UNA vez para los 7 elementos** |
| El mismo atlas, en caliente | 17 ms | |
| `ReadPixelsBuffer` del 512² | **0,3 ms** | |
| Bucle de recoloreo a 128² | **2,0 ms** | El trabajo real de una paleta |
| `CreateEditableImage` + `WritePixelsBuffer` 128² | **0,0 ms** | |
| Lectura desde caché | **0,001 ms** | |
| Asignar `TextureContent` a un blob | **0,003 ms** | |
| Reaplicar tras respawn | **0,031 ms** | |
| Volver a `ORIGINAL` | **0,005 ms** | |
| 20 ciclos equipar/quitar | **0,066 ms** totales | Sin fugas |

> ⭐ **La conclusión de arquitectura:** el atlas base se busca **una sola vez al arrancar el cliente** y se guarda su buffer de píxeles. A partir de ahí **cada paleta cuesta ~2 ms de trabajo síncrono**. Los 7 elementos de World 1 son **~14 ms en total**, repartibles entre frames. Equipar es gratis.

**Ciclo de vida, probado en vivo:**

| Caso | Resultado |
| --- | --- |
| Morir y respawnear | ⚠️ **El elemento se pierde.** El blob se reconstruye desde la plantilla: vuelve a `TextureContent = Uri` y `Material = SmoothPlastic`. **B3 tiene que reaplicar en `CharacterAdded`** — y cuesta 0,031 ms porque la caché sobrevive |
| La caché tras respawn | **Sobrevive.** Vive fuera del personaje, no colgada de él |
| La fila `ORIGINAL` | ⭐ **Funciona**: `Content.fromUri(atlas)` devuelve el aspecto de fábrica. El camino de vuelta existe y es trivial |
| Caminar y recoger con el elemento puesto | **La animación sigue.** El elemento no rompe el rig |
| Filas 4–5 leídas **en runtime** desde la paleta cacheada de 128² | **Idénticas al original**, las 8 celdas |

⚠️ **Y un detalle que hay que saber:** asignar `TextureContent` **vacía `TextureID`**. Quitarse el elemento no es restaurar `TextureID`, es volver a poner `TextureContent = Content.fromUri(...)`.

#### 🔴 El descubrimiento que casi tumba la vía A — B2 en vivo, 2026-09-19

Todo lo de arriba se midió en **modo Edit**. Al aplicar la misma paleta al blob real del personaje **en modo Play**:

```
EditableImage is not accessible.
Go to the Security Tab in Experience Settings to enable this API.
```

`EditableImage` y `EditableMesh` están detrás de un **opt-in de la experiencia**: `Game Settings → Security → Allow Mesh & Image APIs`. En `95828455414780` está **apagado**.

| | |
| --- | --- |
| **Lo que NO cambia** | Los números de B1 siguen siendo válidos: el recoloreo es exacto, la memoria está medida, 128² sirve |
| **Lo que SÍ cambia** | **La vía A no es gratis.** Cuesta activar una opción de la experiencia, y esa es una decisión de plataforma, no de código |
| **Estado** | ✅ **Activado el 2026-09-19.** La vía A queda desbloqueada |
| ⚠️ **Lo que hay que recordar** | Es una opción de la experiencia. Si alguien la apaga, **los blobs de todos los jugadores vuelven al color de fábrica en silencio** — no hay error, solo dejan de pintarse. Merece una nota en el runbook de despliegue |
| ⚠️ **Y lo que esto enseña** | Edit mode **no es representativo del runtime** para estas APIs. Cualquier medición futura de `EditableImage` —incluida la de Android— tiene que hacerse **en Play, no en Edit**, o mide otra cosa |

**Las tres conclusiones que esto cierra** (válidas si se activa la opción):

1. **La vía A es un reemplazo exacto de la vía B, no una aproximación.** Delta 0 contra un asset que lleva meses en producción. Los 12 comunes de los tres mundos cuestan **0 assets y 0 moderación**.
2. **La paleta va a 128², no a 512².** El tamaño de 512 se mantuvo en su día por miedo al sangrado entre celdas por filtrado bilineal; con celdas de 32×21 px de color plano ese miedo no aplica, y está medido que las 24 celdas salen idénticas.
3. **Se cachea por elemento, nunca por jugador.** El coste es estrictamente lineal, así que 7 elementos de World 1 a 128² son **448 KB en total**, contra los 12 MB de cachear 12 jugadores a 512². Son **27×**.

⚠️ **Lo que sigue pendiente de B1 y necesita una persona:**

- **Android real.** Es el único número que no se puede sacar desde aquí y es el hueco de verificación de siempre del proyecto. Con 448 KB para todo World 1 el riesgo baja mucho, pero *baja*, no desaparece.
- **El juicio visual.** Los cuatro blobs están puestos en `workspace._B1_PaletteTest` (original · naranja · rojo · un candidato a Musgo). ⚠️ **Es una carpeta transitoria: hay que borrarla antes de guardar y publicar.**
- **Soltar la imagen** al morir, viajar y reconectar: `Destroy()` funciona, pero el enganche al ciclo de vida se escribe en B3.

### B2 · ⭐ Un elemento, tres siluetas — **la apuesta entera**

| | |
| --- | --- |
| **Qué** | `Ember` completo (paleta + `MaterialVariant` + emisores + perfil de `BoneMotion`) aplicado a `Lvl01_b`, `Lvl04_b` y `Lvl08_b`, **en movimiento**, con `start_stop_play` + `character_navigation` + `screen_capture` |
| **Criterio de paso** | Dos preguntas, las dos a ojo y las dos tuyas: **¿se lee como el mismo elemento en los tres?** y **¿se sigue distinguiendo el tier?** |
| **Si falla** | El modelo de capa no sirve. Hay que saberlo aquí, cuesta una tarde, y evita producir 21 items sobre una premisa falsa |
| **Regla que se valida de paso** | El elemento **multiplica** el tier, nunca asigna. `AuraRate` de fuego tier 8 = `10 × factorFuego`, no `14` |

#### ✅ Parte estática — pasa, 2026-09-19

`Ember` (paleta tono 8° / sat ×1,18 / curva 1,9 a 128², material `CrackedLava`, emisores multiplicados, luz ×1,25) sobre `Lvl01`, `Lvl04` y `Lvl08`, contra los mismos tres sin elemento.

| Criterio | Resultado |
| --- | --- |
| ¿Se lee como el mismo elemento en los tres? | **Sí.** Mismo rojo, mismo material, misma familia en los tres peldaños |
| ¿Se sigue distinguiendo el tier? | **Sí.** Tier 1 es una bola; tier 8 es una figura alta con brazos. La silueta sigue contando el progreso y el elemento no la pisa |
| ¿La cara sobrevive? | **Sí**, y está probado numéricamente (delta 0 en filas 4–5), no solo a ojo |
| ⭐ Caché por elemento | **1 sola `EditableImage` para los 3 blobs.** La regla de cachear por elemento funciona tal cual |
| ⭐ Degradación en tier 1 | El perfil pide `PrestigeAura`, `PrestigeMist` y `PrestigeBurst`; en `Lvl01` **solo existe el primero**. Se aplicó el que hay y se reportaron los ausentes, **sin error y sin romper nada**. Es exactamente el escalón que descubrió B0, y el elemento lo aguanta |

⚠️ **Falta la parte en movimiento**, que necesita modo Play y el `BlobMotionController` de B4. La pregunta que queda abierta es si el `BoneMotion` de un elemento se lee igual con 5 huesos que con 8.

⚠️ **B2 produce el cosmético de prueba que M3 necesita.** Al cerrarla, dejar el `Ember` accesible como item concedible manualmente.

### B3 · La tabla y el enganche

| | |
| --- | --- |
| **Qué** | `GameConfig.WrapBlobs.Elements` (derivada con bucle, nunca escrita a mano), `resolveBlobLook()` en `WrapBlobService.applyPrestige()`, campo `BlobElementId`, validación con caída al default + `warn` |
| **Barrido obligatorio de cortocircuitos** | `TryEquipWrap`, `TryBuyWrap`, `GrantWrap`, `effectiveBlobSkinId`, `TrySetWorld`, `TryRebirth`, `WrapBlobService.currentWrapId`. Es el bug del `AlreadyEquipped`, que ya pasó una vez con **dos** campos y ahora hay **tres** |
| **Criterio de paso** | Equipar, **desequipar (volver a `ORIGINAL`)**, viajar de mundo, renacer, morir y reconectar conservan el elemento correcto. Los seis casos, uno a uno |
| **Test que no se recorta** | **Dos jugadores.** La paleta en runtime es cliente; si los blobs remotos no se pintan, el cosmético **solo lo ve su dueño** y la mitad del valor desaparece. Es el pendiente nº 6 que la piel dejó abierto en septiembre |

### B4 · `BlobMotionController`

| | |
| --- | --- |
| **Qué** | Perfiles de `BoneMotion` componiéndose encima de la animación de caminar |
| ⚠️ **Huesos disponibles** | **`root` + `spine_01..04` en los 8 tiers. `spine_05`, `Left` y `Right` SOLO en los tiers 4–8** (§B0). Un perfil que asuma los siete escribe al vacío en los tres primeros peldaños **sin dar error**. El controlador resuelve por nombre y omite lo que no existe |
| **Reglas duras** | Aplicar **por la izquierda sobre el `CFrame` authored**, nunca acumulando (acumular deriva — lección de las órbitas). **Un solo `Heartbeat` compartido** para todos los blobs. Registrarse **después** de `AttachmentRenderer`. LOD por distancia con los umbrales de cosméticos; el blob local nunca se recorta |
| **Criterio de paso** | 12 blobs con motion sin mover el frame time, medido con `Stats.PhysicsStepTimeMs` |

---

## 4. Carril B — Economía y máquina, fases M0 a M7

### M0 · Medir el antes

Corrida cronometrada de las 10 salas de World 1 **con el requisito puesto**, censo de duración por sala. **Sin esto, M1 no se puede juzgar nunca.** Es el criterio que el documento marca como irrecortable.

#### ⚠️ Corrección medida — 2026-09-19: el 25 % no es 25 %

El documento de la máquina estima el impacto desde *«al entrar a una sala solo el 25 % de los objetos son elegibles»*. Eso asume cuartiles iguales. **No lo son:**

```
GameConfig.<zona>.CollectibleRequirementWeights = { 4, 3, 2, 1 }
```

El escalón más barato —el que casi siempre es elegible al entrar— se lleva **4/10 = 40 %** de los objetos, no el 25 %. Los cuatro escalones reparten **40 / 30 / 20 / 10**. Y encima existe `Collection.MinimumEligibleActivePerZone = 4`, que garantiza un suelo de elegibles.

**Consecuencia:** el Δ de duración que M1 va a medir es probablemente **menor** que el −10 % a −25 % estimado, porque había menos objetos apagados de los que el documento suponía. Sigue habiendo que medirlo —esa es toda la razón de M0— pero **la expectativa contra la que se compara baja**, y con ella la probabilidad de tener que tocar la escalera de blockers.

### M1 · Retirar el requisito

`GameConfig.Collection.RequireStickinessForPickup = false` y nada más. Segunda corrida cronometrada. Se conoce el Δ real por sala (estimado −10 % a −25 % `[PH]`) y **se decide si se compensa**, por este orden: `TotalObjects` → `RespawnSeconds` → la escalera de blockers (último recurso). Nunca `MinSeparationStuds`.

⚠️ `RequiredStickiness` sigue vivo en los blockers. Dos consumidores del mismo nombre de atributo; tocar uno no puede tocar el otro.

#### ⚠️ El flag **no existe todavía** — 2026-09-19

`GameConfig.Collection.RequireStickinessForPickup` vale **`nil`**. El documento lo describe como *«se retira con un booleano»*, y eso da a entender que hay un interruptor esperando. No lo hay: **M1 incluye crearlo** y enganchar el corte en el servidor, y solo entonces existe la corrida A/B. Es media hora, pero no es cero, y el rollback del que depende todo el plan no existe hasta que se escriba.

#### ⚠️ Y una atadura que ningún documento recoge: **el audio cuelga de la tabla de requisitos**

`GameConfig.Feedback` deriva el tono y el volumen del sonido de recogida del **escalón del objeto dentro de `CollectibleRequirements`**, con el comentario explícito de que *«lo que se oye y lo que se ve coinciden por construcción»* (`PickupSizePitchFloor = 0.85`, `PickupSizeVolumeCeiling = 1.3`, cuatro escalones, escalón 1 = factor 1 en los dos).

Al retirar el requisito quedan **dos nociones distintas de «grande» que pueden discrepar**:

| | «Grande» significa | De dónde sale |
| --- | --- | --- |
| **El sonido**, hoy | escalón alto de `CollectibleRequirements` | la tabla de la sala |
| **La etiqueta**, tras M2 | `ResidueValue` alto | el **tamaño authored del prop** |

Un prop pequeño colocado en el escalón 4 sonaría grande y diría `♻ 1`. Hoy no chirría porque el número y el sonido salen de la misma tabla; después de M2, no.

> ⭐ **Y la salida es mejor que el estado actual, no un parche:** apuntar el audio a `ResidueValue`. Entonces **el tamaño del prop decide las tres cosas a la vez** — lo que ves, lo que oyes y lo que suma —, que es exactamente el principio que el comentario de `GameConfig` ya declara, solo que atado a una tabla que estamos retirando. **Entra en M2**, junto al `ResidueValue` authored, porque son el mismo cambio.

### M2 · El Residuo existe

`ResidueValue` authored en los props (brackets XS 1 / S 2 / M 3 / L 5 / XL 8), `ResidueService` enganchado **solo** a `PickupService.ConnectCollected`, etiqueta nueva reutilizando `_RequirementBillboard`, contador del HUD, popup doble en la recogida, **y el audio de recogida repuntado a `ResidueValue`** (ver M1).

⚠️ **Son 9 `CollectibleTypes`, no cientos.** Verificado hoy: los 9 ya llevan `GainMultiplier` —el carril de datos que `RoomSettingsReader` lee y nadie consume— y **ninguno lleva `ResidueValue`**. Authorizar los 9 es una tarde, no una semana, y se puede hacer desde el minuto cero.

| Criterio de paso | |
| --- | --- |
| Legibilidad | Un jugador nuevo entiende **sin leer nada** que el número del objeto es lo que sube arriba |
| 🔴 **Bloqueante** | **60 s en una Rest Zone → `Residue` sin cambio.** Y evento de mundo `Stickiness ×2` activo → el Residuo **no** se multiplica |
| Billboard | Re-medir el peor caso de solapamiento (cámara a ras de suelo, 32 tarjetas). El icono **ensancha la tarjeta** y el proyecto ya medía 3 parejas solapadas sin él |
| Trampas conocidas | `TextBounds = 0,0` pasa por `healLabel`; `TextScaled` y `TextWrapped` van juntos |

### M3 · La máquina sin premios

`Pad` + `Machine` + `PriceSign` + `RevealAnchor` **authored** (regla 5.1: cantidad fija y conocida). Cobro, aspiración escalonada de la bola, blur, revelado con el `Ember` de B2.

| Criterio de paso | |
| --- | --- |
| Rendimiento | Aspira **sin tirón en móvil**. Nunca `Destroy`: `ReleaseOldest(n, ratePerFrame)` repartido sobre los 2,5 s, con techo por frame. 600 piezas de golpe son 10,6 ms de Lua y 50–100 ms de frame en móvil, y lo sufre todo el que tenga la pila cargada |
| Limpieza | **El blur se va siempre**: `CharacterRemoving`, `PlayerRemoving`, `Destroy()`. 20 ciclos sin fugas ni instancias huérfanas |
| Ocupación | Punto-en-caja contra la posición del servidor en tick de 0,25 s, **no `Touched`** (`Touched` no dispara si el personaje aparece encima del pad sin moverse) |
| Protección | Los attachments de blocker (`ProtectBlockerAttachments`) se aspiran los últimos, y solo al 100 % |

### M4 · El pool de World 1 — **punto de encuentro**

Los 7 items reales de la fase G, sorteo en servidor **con duplicados**, reembolso 40 %, piedad 5, primera tirada a 250, estado `COMPLETA`, `PendingPull` persistido.

| Criterio de paso | |
| --- | --- |
| Simulación contra el servidor real | **Mediana ≈ 16 tiradas, P90 ≤ 21.** Ninguna racha de más de 5 duplicados |
| 🔴 Persistencia de la piedad | Forzar 5 duplicados, comprobar que la sexta es nueva, **y reconectar a mitad de racha**. Si el `DupStreak` no persiste, el sistema **falla en silencio**: el sorteo funciona, solo que a algunos les va muy mal |
| Integridad del cobro | Cortar el servidor entre cobro y concesión → al volver, precio devuelto entero |
| Duplicado | Nunca `Denied`, nunca la fanfarria completa. `YA LO TIENES` + `♻ +340 DEVUELTO` + el pip avanzando, **en el mismo frame** |

#### ✅ Construida — 2026-09-22 (sin guardar ni publicar)

| Criterio | Resultado |
| --- | --- |
| Simulación contra el servidor real | **Mediana 16, P90 21**, racha máxima 5 en 24.000 corridas contra `VacuumDraw`, el módulo que usa el servidor |
| Persistencia de la piedad | La racha llega al DataStore y la carga la lee. ⚠️ **Falta reconectar de verdad**: el mock de Studio no sobrevive a salir de Play. Necesita Team Test o servidor real |
| Integridad del cobro | `PendingPull` lleva ahora el precio **pagado** (`World1|250`) y devuelve eso. ⚠️ El corte real del servidor sigue pendiente, igual que en M3 |
| Duplicado | ✅ Verificado en captura: `YOU ALREADY HAVE IT` + `+340 REFUNDED` + pips, solo `CONTINUE`, en el mismo frame |

⚠️ **Descubierto de paso:** el Residuo de recoger no se copiaba al perfil al guardar (`synchronizeHotFields` copiaba Stickiness y no Residuo), y con él tampoco la devolución de `PendingPull` de M3. Arreglado. Detalle en `PROJECT_MEMORY.md`.

### M5 · La pestaña `BLOBS`

Cuarta pestaña, patrón de filas de `WRAPS`, `_BlobRow` y `_GroupHeader` authored **fuera del `ScrollingFrame`**, icono único teñido con `ColorA`, cabeceras por mundo, filas bloqueadas con `? ? ?` + rareza.

| Criterio de paso | |
| --- | --- |
| Equipar | Un toque, sin confirmación |
| ⚠️ `ORIGINAL` | **Se prueba explícitamente**, no se asume. Es la única vía de quitarse un elemento y es exactamente el camino que el cortocircuito `AlreadyEquipped` bloqueó una vez |
| Iconos | El emoji del chip `♻ 🔒` se verifica **en captura**. Un emoji que Roblox no pinta no da error ni warning: deja la fila muda |

### M6 · Instrumentación

Los 6 eventos de §7 del documento de la máquina, con la guarda `if game.PlaceId ~= PRODUCTION_PLACE_ID then return end` si se construyó en laboratorio.

Lo primero que se grafica, en este orden: **tiempo hasta la primera tirada** (si la mediana pasa de 4 min, bajar el precio antes de tocar nada), **duración de sala antes/después de M1**, y **distribución de tiradas hasta completar** contra la simulación.

### M7 · Presupuesto en móvil — **sin esto no se publica**

Aura tier 15 + estela tier 15 + elemento + bola a 300 piezas, **en Android real**.

| Restricción | Número |
| --- | --- |
| Relleno de aura + estela a tope | ~174 studs² |
| Relleno propio del elemento | **≤ 60 studs²** `[PH]` |
| Coste por parte en la asamblea móvil | ~1,4 µs / parte / paso de física |
| `Highlight` por cliente | **31, sin API para subirlo** — prohibido para el elemento |

### 4.8 ⭐ L · Localización — la auditoría de cierre

**Cuándo:** al final, después de M7. Pero **no es donde se hace el trabajo**: cada fase entrega sus propias claves sobre la marcha. `L` existe porque una regla que se cumple «en cada fase» se incumple en la última, y porque hay cadenas que solo aparecen al juntarlo todo.

**Por qué al final y no solo por fases:** `AGENTS.md` §7 es una regla dura, y su propia sección de deuda conocida demuestra que este proyecto ya tiene HUD, Rebirth, inventario, portales y carteles con texto escrito a mano en los controladores. Esta feature añade la superficie de texto más grande desde el inventario: un cartel de mundo, una secuencia de revelado, una pestaña entera y **los nombres y descripciones de 21 items**. Sin una pasada de cierre, se repite la deuda exacta que ya está inventariada.

#### Qué audita

| Superficie | Qué entra |
| --- | --- |
| **Objetos** | La etiqueta de Residuo y el popup doble de recogida |
| **HUD** | El contador de Residuo y su etiqueta |
| **La máquina** | Cartel (`♻ 412 / 600`, `PÍSALO PARA TIRAR`, `SIGUIENTE NUEVO`, `COMPLETA`, `7 / 7 · BOSQUE`, el empujón al Desierto) |
| **El revelado** | Nombre y rareza del premio, `YA LO TIENES`, `♻ +340 DEVUELTO`, botones `EQUIPAR` / `SEGUIR` |
| **La pestaña `BLOBS`** | Título, nombre de la pestaña, `ORIGINAL` y su sub-línea, `EQUIPAR` / `EQUIPADO` / `♻ 🔒`, `? ? ?`, `te falta uno`, `🔒 desbloquea el Desierto`, cabeceras de mundo y su contador |
| **Los items** | **Nombre, tipo (`paleta` / `elemento` / `elemento + piezas`) y rareza (`común` / `raro` / `épico`) de los 21** |
| **Errores y estados** | Cualquier `warn` que llegue al jugador, y los estados de rechazo del pad |

#### Las reglas que se verifican, una por una

1. **El código maneja claves, nunca cadenas.** Nomenclatura `Sistema.Cosa.Estado` en inglés y PascalCase: `Vacuum.Sign.StepToPull`, `Vacuum.Sign.PityNext`, `Vacuum.Reveal.Duplicate`, `Vacuum.Reveal.Refunded`, `Vacuum.Pool.Complete`, `Blobs.Tab.Title`, `Blobs.Row.Equip`, `Blobs.Row.Equipped`, `Blobs.Row.Locked`, `Blobs.Row.Unknown`, `Blobs.Original.Name`, `Blobs.Item.Moss.Name`, `Blobs.Rarity.Common`, `Residue.Hud.Label`…
2. ⚠️ **El cartel de la máquina es UI compartida del mundo.** El servidor manda **estado** (`Saving`, `Affordable`, `Complete`, `Locked`), **jamás una frase**; el texto lo escribe `VacuumMachineController` por clave. `LeaderboardService`/`LeaderboardController` son la referencia del patrón.
3. ⚠️ **Los números se pasan como cadena.** Un `number` en `Locale.Translate` sale en pantalla como `2.00`. Aplica a `412 / 600`, `+340`, `6 / 7` y a los pips de piedad.
4. **Nada de concatenar trozos traducidos.** `♻ +340 DEVUELTO` es **una** entrada con `{amount}`, no tres pedazos pegados: el orden de las palabras cambia entre idiomas.
5. **Lo que no se traduce se deja fuera a propósito:** números y sus abreviaturas, nombres de jugador, y los términos de marca del juego (`WINS`, `STICKINESS`, `REBIRTH`, `ROBUX`). **`RESIDUO` entra en esa lista de marca** — es un término propio, se queda igual en todos los idiomas, y la frase de alrededor sí se traduce.
6. **El `Source` de cada entrada es `en-us`, y es el mismo texto que va en la plantilla authored**, para que el editor enseñe el cartel de verdad y no un marcador vacío.

#### Criterio de paso

- **Barrido automático**: un `script_grep` sobre los módulos nuevos (`ResidueService`, `VacuumMachineService`, `VacuumMachineController`, `BlobSkinService`, `CosmeticInventoryController`, `BlobMotionController`) **no devuelve ni una cadena de UI literal**.
- **Los 21 items tienen sus tres entradas** (nombre, tipo, rareza) y ninguno cae al fallback.
- **Se juega la feature entera en un idioma que no sea el de origen** — recoger, ver la etiqueta, tirar de la máquina, sacar un nuevo, sacar un duplicado, equipar desde el revelado, equipar desde la pestaña y volver a `ORIGINAL`. Se anota en `PLAN_MVP.md`.
- ⚠️ **Se verifica en captura que ninguna clave cae al fallback y que ningún icono sale mudo.** Una clave sin traducir se pinta a propósito con su nombre y un `warn`; un emoji que Roblox no pinta **no da error ni warning** y deja la fila en blanco — 🫧 ya salió hueco con FredokaOne mientras 👑 🏆 ⚡ ✨ se pintaban bien. El `♻` del chip `♻ 🔒` y el del cartel entran en esa comprobación.

⚠️ **Lo que `L` NO es:** una fase donde se escriba todo el texto de golpe. Si se llega a `L` con 200 cadenas a mano, la fase no cabe. **Cada fase de M y de G entrega sus claves al cerrarse**, y `L` verifica, completa los huecos y hace la pasada de idioma.

---

## 5. ⭐ Fase P — Propuestas de blob

**Cuándo:** después de B2 (ya se sabe que el modelo de capa funciona) y antes de B3/G.
**Duración:** una sesión de diseño más una de revisión. **Es barata y es la que evita producir lo que no encaja.**
**Salida:** un documento `VacummFeature/CATALOGO_BLOBS_W1.md` con 7 fichas cerradas, más una lista corta de suplentes.

### 5.1 Por qué existe esta fase

La tabla de los 21 del documento de blobs es una **propuesta de nombres**, no un catálogo producible. Entre «Musgo, común, paleta» y una ficha que la fase G pueda ejecutar sin volver a preguntar faltan siete campos por item. Escribirlos antes de producir cuesta una tarde; descubrirlos a mitad de producción cuesta rehacer.

Y hay una razón de diseño encima: **los 4 comunes de World 1 son colores sobre una base verde.** Cuatro verdes distintos que se distingan entre sí a diez metros, con la bola llena, no salen solos de una lista de nombres bonitos. Eso se comprueba **en la fase P, con las 4 paletas pintadas una al lado de otra**, antes de escribir una fila de la tabla `Elements`.

### 5.2 Qué produce cada ficha

```
## MUSGO
Id            MossW1
Rareza        Común          Peso 18 %
Mundo         World1
Qué es        Paleta — filas 0-3 recoloreadas. Nada más

Paleta        Hue <n>°  ·  SatScale <n>  ·  ValueCurve 1.9
              ColorA #......  ColorB #......      ← también tiñen el aura de prestigio (§8 doc blobs)
Material      Base <Enum.Material.X>  ·  Variant  —
Emisores      —                                    (los comunes no añaden emisores)
BoneMotion    default
Sonido        —
FillBudget    0 studs²

Claves        Blobs.Item.MossW1.Name  ·  Blobs.Item.MossW1.Kind  ·  Blobs.Rarity.Common
              (Source en en-us — §4.8)

Coste         Vía A: 3 números. Vía B: 1 PNG
Criterio de   Se distingue de los otros 3 comunes de W1 a 10 studs, con la bola a 300 piezas,
aceptación    y con los ojos intactos (test de píxel filas 4-5)
```

Para **raros** se añaden: perfil de emisores por capa (`Body`, `Motes`, `Accent`/`Bolts`, `Orbit`, `Light` — **nombres obligatorios**, el LOD recorta por nombre), perfil de `BoneMotion`, sonido de paso y presupuesto de relleno.

Para el **épico** se añade además: lista de piezas, **cómo se construye cada una** (`Beam` entre `Attachment`s / partículas / `BasePart` soldado) y **a qué distancia vive del cuerpo**.

### 5.3 Las cinco reglas que toda ficha tiene que respetar

Cualquier propuesta que incumpla una de estas se rechaza en la revisión, sin discusión:

1. **Nunca toca las filas 4 y 5 del atlas.** Ahí está la cara. Los 21 comparten cara.
2. **El elemento multiplica el tier, nunca lo asigna.** Un `AuraRate` absoluto en una ficha es un rechazo automático.
3. **El elemento no escala el cuerpo.** `VisualScale` es del tier. `CosmeticVfxController` escala los cosméticos midiendo el bounding box del personaje: un elemento que agranda el blob **agranda el aura con él**, y el pase de Eternal a 17 studs ya blanqueó la pantalla una vez.
4. **Prohibido `Highlight`.** Las vetas se hacen con textura o con emisión. El tope de 31 por cliente ya está comprometido con 12 jugadores + foco de pickup + blockers.
5. **Los emisores usan los nombres de capa que el LOD conoce.** Una capa con nombre nuevo cae en prioridad 2 y nunca se recorta cuando debería.

### 5.4 La restricción que manda sobre el diseño, y no es obvia

> **El blob vive dentro de la bola.** Blob ~4,3 studs; bola a 300 piezas, 13 studs de diámetro.

En el juego tardío el blob está **enterrado**. De ahí, tres consecuencias que la fase P aplica a cada ficha:

- **La identidad la llevan el color y los VFX, no el detalle de superficie.** Los emisores salen del `Attachment Core` y se leen fuera de la bola; una textura fina no.
- **Las piezas del épico viven a ~7–9 studs**, no pegadas al cuerpo. Los anillos orbitales del Fénix funcionan; unos cuernos de 1 stud no se verían jamás.
- **Los comunes son los que más sufren.** Mitigación que se decide aquí: que la paleta del elemento **tiña también `ColorA`/`ColorB` del aura de prestigio**. Es un cambio de dos campos en las entradas derivadas.

### 5.5 Propuesta de partida para World 1 (a cerrar en la revisión)

| Rareza | Item | Qué es | Lo que hay que resolver en la ficha |
| --- | --- | --- | --- |
| C 18 % | **Musgo** | paleta | Los cuatro verdes tienen que separarse entre sí. Este es el más cercano a la base |
| C 18 % | **Miel** | paleta | Ámbar — ojo, la fila 4 ya es dorada y no se toca. El cuerpo tiene que leerse distinto de esa fila |
| C 18 % | **Savia** | paleta | ¿Translúcido cuenta como común? Si lleva `Transparency`, sube a raro |
| C 18 % | **Corteza** | paleta | El más oscuro. Comprobar que no se pierde contra el suelo del Bosque |
| R 11 % | **Hoja** | paleta + material + emisores + motion | Mate, venas, aura de esporas, respiración lenta |
| R 11 % | **Rocío** | ídem | Translúcido, gotas que caen, wobble líquido, se aplana al caer |
| É 6 % | **Micelio** | lo anterior + piezas | Bioluminiscente, esporas, **hongos brotando de los huesos**. Decidir aquí si las piezas son `BasePart` o partículas |

⚠️ **El reparto 18/11/6 se declara por item, no por tier.** Con siete casillas, «Común 60 %» repartido entre cuatro deja cada común al 15 % y cada raro al 15 % también: la misma probabilidad con distinto nombre.

### 5.6 Criterio para cerrar la fase P

- Las 7 fichas están escritas, con sus siete campos y su criterio de aceptación.
- **Las 4 paletas de común están pintadas y vistas juntas**, sobre `Lvl04_b`, con la bola a 300 piezas. Si dos no se distinguen, se cambia la ficha aquí — no en producción.
- Cada ficha tiene un coste estimado y **un suplente** por si se cae.
- El presupuesto de relleno de los 7 suma dentro del tope del elemento (≤ 60 studs² `[PH]` el que más).

---

## 6. ⭐ Fase G — Generación de los blobs

**Cuándo:** después de P y de B3 (la tabla tiene que existir para que un item sea una fila de datos).
**Salida:** 7 entradas vivas en `GameConfig.WrapBlobs.Elements`, sus assets, y las 7 concedibles a mano para la prueba.

### 6.1 El orden de producción, y no es el orden de rareza

Se produce **por coste creciente**, no por rareza, porque cada escalón valida la tubería del siguiente:

```
G1  las 4 paletas comunes      →  valida la tubería de color de punta a punta
G2  MaterialVariants de raros  →  valida generate_material sobre un blob real
G3  emisores + motion de raros →  valida que el LOD recorta las capas nuevas
G4  el épico                   →  lo único que toca física, y lo único que puede caerse
```

### 6.2 G1 · Las 4 paletas comunes

| | |
| --- | --- |
| **Cómo** | Python **fuera de Studio**, sobre el atlas leído por `CreateEditableImageAsync`. Rotación de tono + la curva perceptual, **recibiendo el rango de filas como parámetro** — nunca la imagen entera |
| **Entrega** | Vía A: 4 filas de `Palette` en `GameConfig`. Vía B: 4 PNG en tu carpeta, que importas tú en el Asset Manager |
| **Test de píxel, automático** | Las 8 celdas de las filas 4–5, idénticas al original, para las 4 paletas. **Este test se escribe una vez y se corre en cada item**, es la red que impide que un elemento se lleve la cara por delante |
| **Y el segundo test** | Las 4 paletas aplicadas al aura de prestigio (`ColorA`/`ColorB`), vistas con la bola llena |

### 6.3 G2 · Materiales de los raros

| | |
| --- | --- |
| **Cómo** | `generate_material` → `MaterialVariant`. Hoy las 24 plantillas son `SmoothPlastic` con `MaterialVariant` vacío y sin `SurfaceAppearance`: hay sitio libre |
| ⚠️ **Regla dura** | **`generate_texture` NO se usa sobre el cuerpo del blob. Nunca.** Reemplaza la fuente in-place, puede romper la jerarquía de huesos, y produce textura orgánica — lo contrario de un atlas de 24 celdas planas donde la fila 5 son los ojos |
| **Dónde sí se puede** | Sobre las **piezas del épico**, que son MeshParts aparte y no están rigged |

### 6.4 G3 · Emisores y movimiento de los raros

| | |
| --- | --- |
| **Cómo** | Perfiles de emisor sobre los 3 emisores que ya existen (`PrestigeAura`, `PrestigeMist`, `PrestigeBurst`), con los nombres de capa del LOD. Perfiles de `BoneMotion` como datos que consume el controlador de B4 |
| **Criterio** | Cada raro se distingue del común más parecido **en movimiento**, a 10 studs, con la bola llena |
| **Medición** | Relleno de pantalla del elemento solo, contra el tope de ≤ 60 studs² |

### 6.5 G4 · El épico

| | |
| --- | --- |
| **Cómo** | `generate_mesh` / `generate_procedural_model` para las piezas. **`Beam` entre `Attachment`s y partículas primero; `BasePart` soldado solo cuando la silueta lo exija** |
| **Por qué ese orden** | Una parte soldada es `BasePart` dentro de la asamblea del personaje: el mismo impuesto de ~1,4 µs por parte y por paso. 6 piezas × 12 jugadores = 72 partes extra en movimiento. Los anillos orbitales del Fénix son `Beam`, que es como están hechas las órbitas de las auras tier 9+, y cuestan cero física |
| ⚠️ **Regla dura** | **Las mallas de IA son para accesorios, jamás para el cuerpo.** El cuerpo conserva sus 8 huesos y sus 8 animaciones |
| **Criterio** | Se lee **por encima de la bola**, desde 13 studs de cámara con FOV 82. Y las partes añadidas se miden contra el frame time con 12 jugadores |

### 6.6 Lo que necesita a una persona

| | Por qué |
| --- | --- |
| **Guardar y publicar** | El MCP no expone Save/Publish |
| **Importar PNG** (si vía B) | `upload_image` solo acepta URLs http/https. Los PNG se dejan en tu carpeta; el import es tuyo |
| ⭐ **El juicio visual** | *«el relleno estaba dentro de budget todo el rato; lo que falló fue la composición, y eso solo lo ve un ojo.»* El presupuesto se puede medir; si se ve bien, no |

---

## 7. Orden recomendado de ejecución

| Bloque | Contenido | Por qué en ese sitio |
| --- | --- | --- |
| **1º — en paralelo** | **B0 + B1 + B2** y **M0 + M1** | Son los dos riesgos que pueden cambiar el diseño, y cuestan poco. B2 dice si la idea funciona; M1 dice cuánto se acorta World 1 |
| **2º** | **Fase P** | Ya se sabe que el modelo de capa vale. Ahora se cierra el catálogo |
| **3º — en paralelo** | **B3 + B4** y **M2 + M3** | Código de las dos ramas, independiente. M3 usa el `Ember` de B2 como premio de prueba |
| **4º** | **Fase G** | Con la tabla viva, cada item es una fila |
| **5º** | **M4 → M5 → M6** | El encuentro y lo que va encima |
| **6º** | **M7** | La verificación en móvil, que es la puerta de publicación |
| **7º** | **L** | La auditoría de localización. Va al final porque es lo único que necesita que **todas** las superficies de texto existan ya |

### Lo que puede empezar el minuto cero, sin depender de nada

- **Los `ResidueValue` authored en los props.** Es tabla, no código.
- **Elegir dónde va la máquina en cada lobby.** Diseño de nivel puro, y el riesgo 7 (nadie la ve) se decide ahí: **en la ruta de salida, no en un rincón**.
- **Decidir qué VFX son exclusivos** y cuáles se quedan en la tienda de Wins.
- **Las entradas del `LocalizationTable`** (§9.3).

---

## 8. Si hay que recortar alcance

**Lo que se cae, en este orden:**

1. La tirada dorada (3 % de doble premio).
2. **El épico** — es el único item que toca física y el más caro. El pool queda en 4C + 2R + 1 suplente raro, y los pesos se rehacen.
3. El pulido de la ruleta.
4. Los perfiles de `BoneMotion` de los raros (B4 se reduce a un perfil `default`).

**Lo que no se cae nunca, y por qué:**

| | Por qué |
| --- | --- |
| **La guarda del goteo pasivo** | Sin ella el gacha es AFK y el gamepass `x3 Offline Gains` (R$249) lo acelera **por accidente**. Eso es territorio de divulgación de probabilidades sin que nadie lo haya decidido |
| **La medición de M0** | Sin el antes, el Δ de World 1 no se puede saber nunca |
| **`PendingPull` persistido** | Sin él, una caída de servidor cobra sin dar premio |
| **La limpieza del blur** | Una línea, y sin ella la sesión se rompe hasta reiniciar |
| **El sorteo en servidor** | Sin él, el gacha se exploita el primer día |
| **La piedad por racha** | Con 7 items el decil con mala suerte tarda un 60 % más que la mediana. Si no cabe la piedad, **lo que no cabe son los duplicados** |
| **La primera tirada a 250** | A precio pleno cae en el minuto 3,8, y el embudo ya pierde el 39,6 % de las vueltas antes de eso |
| **La fila `ORIGINAL`** | Es la única vía de quitarse un elemento |
| **Las filas 4 y 5 intactas** | Es la cara del personaje |
| **El test de 2 jugadores** | La mitad del valor de un cosmético es que lo vean los demás |

---

## 9. Correcciones que salen de cruzar los dos documentos

### 9.1 Los pesos están escritos dos veces y no coinciden

| Dónde | Dice |
| --- | --- |
| Máquina §4.4 — la decisión | **18 / 11 / 6 por item** (4C+2R+1E = 100 %) |
| Máquina §4.8 — plataforma | *«los pesos de §4.4 (**60 / 30 / 10**)»* |

`60/30/10` es el reparto **por tier** de la versión anterior de 15 items. Con el pool de 7 vale **72 / 22 / 6** por tier.

> ✅ **Decidido (2026-09-19): manda §4.4 — `18 / 11 / 6` por item.**
>
> Es el número recalculado para el pool de 7 y es el que sostiene toda la simulación: mediana 16 tiradas, P90 21, el épico en la tirada 11. `60/30/10` es residuo de la versión de 15 y no cuadra con nada de lo que hay escrito debajo.
>
> Y hay una razón más fuerte que la aritmética: **§4.8 es justo la línea que dice qué probabilidades habría que publicar el día que entre Robux.** Publicar un número que no es el que usa el sorteo es peor que no publicarlo. **Corregido en el documento fuente.**

### 9.2 Las dos listas de fases arrancan las dos en «0» y no son la misma

Los dos documentos numeran sus fases desde 0 y las dos empiezan por algo distinto («medir el antes» / «backup»). En una conversación de tres semanas, «la fase 2» va a significar dos cosas. **Este plan renombra a `M0…M7`, `B0…B4`, `P` y `G`**, y esa nomenclatura es la que se usa en `PLAN_MVP.md`.

### 9.3 Falta la localización, y es una regla dura del proyecto

`AGENTS.md` §7: **todo texto que lee el jugador está localizado, sin excepciones.** Los dos documentos escriben UI en español directamente: `PÍSALO PARA TIRAR`, `YA LO TIENES`, `♻ +340 DEVUELTO`, `SIGUIENTE NUEVO`, `COMPLETA`, `EQUIPAR`, `EQUIPADO`, `desbloquea el Desierto`, `? ? ?`, y los nombres y rarezas de los 21 items.

> ✅ **Decidido (2026-09-19): entra como fase `L`, la última del plan** (§4.8). Cada fase entrega sus claves al cerrarse; `L` es la auditoría que verifica que no queda ni una cadena a mano y juega la feature en un idioma no-origen.

Consecuencias concretas:

- Cada fase entrega **sus claves** en `ReplicatedStorage.Shared.Localization`, con `Source` en `en-us`. Nomenclatura `Vacuum.Sign.StepToPull`, `Vacuum.Reveal.Duplicate`, `Blobs.Row.Equip`, `Blobs.Item.Moss.Name`…
- **El cartel de la máquina es UI compartida del mundo.** El servidor manda **estado** (`Complete`, `Affordable`, `Saving`), nunca una frase; el texto lo escribe `VacuumMachineController` por clave.
- Los **números** (`412 / 600`, `+340`) los escribe el servidor o el cliente directamente, pero **como cadena**: un `number` pasado a `Locale.Translate` sale en pantalla como `2.00`.
- Al cerrar cada fase se prueba **un idioma que no sea el de origen** y se anota en `PLAN_MVP.md`.

**Los nombres de los 21 items entran en la tabla en la fase P**, no en la G. Es gratis hacerlo ahí y caro hacerlo después.

### 9.4 Tres instancias que la regla 5.1 obliga a crear a mano

`AGENTS.md` §5.1: lo que existe en cantidad fija y conocida se crea en el editor, no en runtime.

> ✅ **Decidido (2026-09-19): sin excepciones.** Todo lo que el jugador ve y existe en cantidad fija se crea a mano en el DataModel, visible en el Explorer. El código **localiza, clona, y escribe texto, color y visibilidad** — el tamaño, la posición, el offset, la fuente y el layout son del editor. Ninguna fase de este plan puede instanciar geometría ni jerarquía visual permanente por código.

Aplica a:

- `Pad`, `Machine`, `PriceSign` y `RevealAnchor` — **una por máquina, authored**, aunque el contenido del cartel sea por jugador (las escrituras del cliente sobre el Workspace son locales).
- `_BlobRow` y `_GroupHeader` — plantillas authored, **fuera del `ScrollingFrame`** (un `UIListLayout` reserva hueco también para los hijos invisibles).
- Las piezas del épico — plantillas authored en `ReplicatedStorage.Assets`, que el código clona y suelda.

⚠️ **Y las tres referencias que no se actualizan solas al duplicar** la máquina para W2 y W3: `WorldId`/`PoolId` en el pad **y** en la máquina, `Pad.PadReference`, y `PriceSign.Adornee`. Este proyecto ya se mordió dos veces con esto duplicando Rest Zones.

### 9.5 La decisión que hay que tomar antes de M4, no después

**Las variantes (Normal → Dorado → Arcoíris → Cósmico).** No entran en v1, pero deciden la forma del `DupStreak`, del contador por item y del estado `COMPLETA`. Si se van a construir alguna vez, **el esquema de persistencia de M4 tiene que dejarles sitio ahora**: un contador por item en vez de un booleano de poseído. Cambiarlo después es una migración de perfiles.

Coste de dejar sitio hoy: un campo. Coste de no dejarlo: migrar los perfiles de todos los jugadores.

> ✅ **Decidido (2026-09-19): se deja el sitio.** `OwnedCosmeticIds` guarda **un contador por item**, no un booleano de poseído. Formato: cadena separada por comas con `id:cuenta` (los atributos no admiten tablas), normalizada al cargar como ya hace `normalizeWrapIds`.
>
> En v1 el contador solo sirve para dos cosas que ya están en el diseño: `> 0` es «lo tienes» y el incremento es el duplicado. Las variantes (Dorado a 3, Arcoíris a 8, Cósmico a 20 `[PH]`) leen ese mismo contador el día que se construyan, **sin tocar el perfil de nadie**.

---

## 10. Seguimiento

Al cerrar cada fase, y según `AGENTS.md` §6:

- **`PLAN_MVP.md`** — qué se probó, con qué resultado, y el idioma no-origen verificado.
- **`PROJECT_MEMORY.md`** — decisiones tomadas, contratos nuevos (`Residue`, `BlobElementId`, `OwnedCosmeticIds`, `DupStreak`, `PendingPull`), y **si se guardó y publicó**.
- Los `[PH]` de este plan se sustituyen por el número medido, con la fecha. Hoy son placeholders: `−10 a −25 %` del Δ de World 1, `≤ 60 studs²` del relleno del elemento, `270 ♻/min` del ritmo de ingreso, y el umbral de variantes `3 / 8 / 20`.

### Los cinco números que este plan existe para averiguar

| # | Número | Lo mide | Qué decide |
| --- | --- | --- | --- |
| 1 | ¿`EditableImage` rinde en Android? | **B1** | Si los 12 comunes cuestan 0 assets o 12 PNG moderados |
| 2 | ¿Se lee el mismo elemento en tres tiers? | **B2** | **Si la feature entera se construye o se rediseña** |
| 3 | Δ de duración de World 1 | **M0 → M1** | Si hay que compensar el presupuesto de contenido |
| 4 | Mediana y P90 de tiradas hasta completar | **M4** | Si la piedad está realmente enganchada |
| 5 | Frame time con todo puesto en móvil | **M7** | Si se publica |
