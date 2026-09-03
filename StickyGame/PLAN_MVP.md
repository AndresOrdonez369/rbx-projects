# Stuck to You — Plan ejecutable de MVP

**Semana:** lunes 3 a viernes 7 de agosto de 2026  
**Equipo:** 1 desarrollador  
**Meta del viernes:** experiencia pública o no listada, jugable de principio a fin en móvil y PC, probada por personas que no conocen el diseño.  
**Duración objetivo de la primera vuelta:** 3–5 minutos.  
**Fuente de verdad:** el documento “Stuck to You: One-Week Prototype”.

---

## 1. La promesa que estamos construyendo

> Toca objetos más pequeños, haz crecer tu pila y vuélvete lo bastante pegajoso para absorber el objeto gigante que bloquea el camino.

El juego se entiende con una sola regla:

> **Si tienes suficiente Stickiness, el objeto se pega.**

El loop completo es:

```text
TOCAR → PEGAR → GANAR STICKINESS → ABSORBER BLOQUEADOR → AVANZAR
```

No hay botón de recoger, inventario, venta, combate, vida, daño ni una segunda moneda durante la partida. El jugador se mueve; el resto ocurre automáticamente.

### Señales de que el núcleo funciona

- El primer objeto se pega antes de los 10 segundos.
- Después de 3 objetos, el jugador ya entiende la regla sin leer un tutorial largo.
- Siempre se ve el siguiente objetivo grande.
- Hay un pickup cada 0.2–2 segundos mientras el jugador se mueve por la ruta correcta.
- La pila cambia de forma de manera visible cada 10–20 segundos.
- Al no poder absorber algo, el jugador entiende cuánto le falta.
- Terminar las tres zonas toma 3–5 minutos en la primera vuelta.

---

## 2. Alcance cerrado del MVP

### Entra obligatoriamente

- 3 zonas lineales y diferenciadas:
  1. Toy Room → bloqueador: Toy Chest.
  2. Bedroom → bloqueador: Bed.
  3. Kitchen → bloqueador final: Refrigerator.
- Recolección automática por contacto.
- Un único stat visible: **Stickiness**.
- Requisitos visibles sobre cada objeto.
- Estados claros: verde si se puede recoger, rojo si aún no.
- Objetos pegados visualmente al personaje.
- Room Manager data-driven por zona.
- Respawn de coleccionables y disponibilidad multijugador.
- HUD mínimo y legible en móvil.
- Niveles derivados de Stickiness; no existe XP separada.
- 4 Sticky Wraps, desbloqueados y equipados automáticamente.
- Final de vuelta, +1 Win y opción de Rebirth al llegar al nivel máximo.
- Persistencia de Wins y Rebirths.
- `leaderstats` del servidor y leaderboard global solo si el core está estable.
- Analítica mínima de embudo.
- Sonido, partículas y una animación grande al absorber bloqueadores.

### Queda fuera esta semana

- Neighborhood y cualquier cuarta o quinta zona.
- Tienda, pets, inventario o selección manual de wraps.
- Gamepasses, dev products y Robux.
- Daño, vida, muerte, pérdida de objetos o Rest Zone con recompensa AFK.
- Peso que reduzca la velocidad.
- Obstáculos que golpeen, empujen o interrumpan la colección.
- Quests, daily rewards, códigos, trades o colecciones permanentes.
- Modelado propio complejo.
- Rebirths con árboles de mejoras o recompensas adicionales.

**Por qué:** todas esas funciones abren loops nuevos. Esta semana solo debe responder una pregunta: ¿es satisfactorio tocar objetos, verlos pegarse y crecer hasta absorber algo enorme?

### Interpretación de “Rest Zone” para este MVP

Habrá una **Finish / Rest Zone** después del Refrigerator. Es un lugar seguro que:

- muestra el resumen de la vuelta;
- limpia la pila visual;
- otorga la Win;
- presenta el botón de Rebirth si corresponde;
- permite empezar otra vuelta.

No genera recursos por quedarse quieto. Así cumple una función clara sin crear otro sistema.

---

## 3. Reglas de juego cerradas

### 3.1 Recolección

Cada objeto coleccionable tiene:

```lua
Id
ZoneId
RequiredStickiness
RespawnSeconds
AttachScale
Category
```

Al tocarlo, el servidor valida:

1. que el objeto esté activo;
2. que el jugador esté vivo y dentro de la zona correcta;
3. que no exista un debounce activo para ese jugador/objeto;
4. que `PlayerStickiness >= RequiredStickiness`.

Si cumple:

1. desactiva el pickup;
2. suma Stickiness;
3. agrega una copia visual a la pila, si no alcanzó el límite;
4. actualiza HUD, nivel y progreso del bloqueador;
5. reproduce feedback;
6. devuelve el pickup al pool después de 2 segundos.

Si no cumple:

- no consume ni mueve el objeto;
- muestra una reacción corta en rojo con la cantidad faltante;
- aplica un cooldown local de 0.5 s para no saturar HUD y audio.

### 3.2 Fórmula de ganancia

```text
RebirthMultiplier = 1 + (Rebirths × 0.5)
StickinessGain = StickyWrapBaseGain × RebirthMultiplier
```

| Sticky Wrap | Desbloqueo provisional | Ganancia base |
|---|---:|---:|
| Basic Glue | Nivel 1 | +1 |
| Strong Glue | Nivel 5 | +3 |
| Super Glue | Nivel 10 | +8 |
| Cosmic Glue | Nivel 15 | +20 |

El wrap más fuerte desbloqueado se equipa automáticamente. El cambio debe verse en el material, color o aura del personaje. No se construye menú de equipamiento esta semana.

Los valores fraccionarios producidos por Rebirth se conservan internamente. El HUD puede mostrar un decimal cuando sea necesario.

### 3.3 Nivel

El nivel se calcula a partir de Stickiness. No hay XP, drops de XP ni otra barra que balancear.

```text
Level = nivel más alto cuyo umbral sea <= Stickiness
```

Umbrales provisionales para Rebirth 0:

| Nivel | Stickiness | Evento |
|---:|---:|---|
| 1 | 0 | Basic Glue |
| 2 | 5 | — |
| 3 | 12 | — |
| 4 | 20 | — |
| 5 | 30 | Strong Glue |
| 6 | 45 | — |
| 7 | 60 | — |
| 8 | 80 | — |
| 9 | 95 | — |
| 10 | 110 | Super Glue |
| 11 | 135 | — |
| 12 | 165 | — |
| 13 | 195 | — |
| 14 | 225 | — |
| 15 | 260 | Cosmic Glue |
| 16 | 300 | — |
| 17 | 345 | — |
| 18 | 395 | — |
| 19 | 445 | — |
| 20 | 500 | Rebirth disponible |

Estos números son de arranque, no promesas. Viven en `GameConfig` y se ajustan con telemetría y playtests.

### 3.4 Rebirth y Win

Absorber el Refrigerator:

- completa la vuelta;
- suma `Wins += 1`;
- envía al jugador a Finish / Rest Zone;
- registra tiempo total y zonas completadas;
- muestra Rebirth si el jugador alcanzó su level cap.

Rebirth:

- requiere el nivel máximo actual **y nada más**: no exige terminar la vuelta;
- reinicia Stickiness a 0 y Level a 1;
- reinicia los Sticky Wraps al Basic Glue;
- conserva Wins;
- suma `Rebirths += 1`;
- aumenta permanentemente el multiplicador en `+0.5x`;
- sube el level cap 5 niveles y devuelve al jugador al inicio.

El Rebirth es repetible (2026-08-06). El level cap es la fórmula `20 + 5 × Rebirths` y los niveles por encima del 20 se generan desde `GameConfig.LevelExtension`, así que dejó de existir el tope duro de un solo Rebirth. Con los valores actuales hay 17 Rebirths disponibles antes de que el techo salga de los niveles generados; a partir de ahí la pantalla muestra `MAX REBIRTH` en vez de pedir un nivel imposible.

---

## 4. Ruta y balance inicial

La ruta es horizontal, sin bifurcaciones ni búsquedas. Al entrar a una zona debe verse el bloqueador y un rastro de objetos alcanzables.

| Zona | Requisitos de objetos | Bloqueador | Meta | Tiempo objetivo |
|---|---|---|---:|---:|
| Toy Room | 0, 5, 12, 25 | Toy Chest | 50 | 45–60 s |
| Bedroom | 50, 70, 100, 140 | Bed | 180 | 55–75 s |
| Kitchen | 180, 220, 300, 380 | Refrigerator | 500 | 60–90 s |

### Densidad inicial por zona

Los valores se editan a mano por sala en `Workspace/StuckToYou/Zones/<Zone>/RoomSettings`; `GameConfig` solo aporta defaults.

- `TotalObjects`: objetos visibles a la vez, por jugador. Arranca en 12.
- `ObjectPool`: qué tipos de objeto pueden aparecer en esa sala. El sistema reparte `TotalObjects` equitativamente entre ellos.
- `MinSeparationStuds`: separación mínima entre objetos. Arranca en 8.
- Respawn base: 2 s.
- Al menos `MinimumEligibleActivePerZone` (4) objetos deben ser alcanzables con el umbral de entrada de la sala. Lo garantiza `ItemPlanner`.
- La colocación es aleatoria a lo largo de toda la sala, dentro del volumen authored `PlacementArea`.

### Multijugador

**Cambio de diseño 2026-08-03:** los objetos son **privados por jugador**. Varios jugadores pueden estar en la misma sala sin verse ni bloquearse los objetos.

- El servidor es dueño de los datos (posición, tipo, requisito, estado) en una sesión por (jugador, sala). Cero instancias de collectible en el servidor.
- El cliente renderiza sus propios objetos clonando plantillas authored de `ReplicatedStorage/Assets/Collectibles`.
- El pickup lo pide el cliente y lo valida el servidor contra su propia posición guardada, con rate limit.
- Los slots de colocación se calculan una vez por sala y se cachean; una sala sin jugadores no tiene instancias, ni tareas, ni slots calculados.
- Diseñar densidad para 6 jugadores simultáneos: cada uno lleva su propio conjunto, así que la disponibilidad ya no depende de cuánta gente haya en la sala.

---

## 5. Feedback y UX obligatorios

### HUD

Mostrar únicamente:

- `Stickiness: actual`;
- `BLOQUEADOR: actual / requerido`;
- barra de Level con nivel actual;
- Wins y Rebirths en tamaño secundario.

No mostrar peso, velocidad, inventario ni XP.

### Objetos del mundo

Cada collectible usa un `BillboardGui`:

- número requerido;
- verde si es coleccionable;
- rojo si no lo es;
- actualización local del color cuando cambia Stickiness, sin pedir al servidor que repinte todos los objetos.

### Cada pickup exitoso

- objeto se pega inmediatamente;
- número `+X Stickiness`;
- 3–4 variaciones cortas de sonido;
- partícula pequeña;
- HUD interpola, no salta de forma seca.

### Cada bloqueador

- cambia a verde al llegar al requisito;
- pulsa o emite una señal visible;
- al tocarlo: animación de 1–2 s, sonido grande, pequeña cámara shake;
- se abre la siguiente zona sin pantalla de carga.

### Pila visual

- Límite inicial: **30 objetos visibles por jugador**.
- El progreso lógico nunca se detiene por llegar al límite visual.
- Al llegar al límite, los pickups siguen haciendo crecer ligeramente el radio de la pila en umbrales definidos; no se agregan más piezas.
- Cada blocker usa un “hero slot”: se pega como pieza grande y reemplaza uno de los props pequeños, para que el cambio de zona siempre produzca crecimiento visible.
- Las copias pegadas son `Massless`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`.
- Usar partes o meshes low-poly, sin scripts y preferiblemente de una sola pieza.
- Distribuir attachments alrededor del torso con posiciones predefinidas y un poco de rotación; evitar offsets completamente aleatorios que tapen la cámara o la cabeza.
- Reservar una silueta legible: cámara y HumanoidRootPart nunca quedan bloqueados.

---

## 6. Arquitectura técnica mínima

```text
ReplicatedStorage/
  Shared/
    GameConfig          -- zonas, objetos, umbrales, wraps, rebirth
    Remotes             -- creados por bootstrap
ServerScriptService/
  Server/
    Main                -- orden de inicialización
    DataService         -- Wins y Rebirths persistentes
    CollectionService   -- validación de pickups y stickiness
    AttachmentService   -- pila visual y límite
    RoomService         -- gates, bloqueadores y avance
    SpawnService        -- pools y garantía de disponibilidad
    ProgressionService  -- niveles, wraps, wins y rebirth
    AnalyticsService    -- eventos del embudo
StarterPlayer/
  StarterPlayerScripts/
    Client/
      HUDController
      ObjectLabelController
      JuiceController
Workspace/
  StuckToYou/
    StartSpawn
    Zones/
      ToyRoom/
      Bedroom/
      Kitchen/
      FinishZone/
```

### Reglas no negociables

1. **Servidor autoritativo.** El cliente nunca decide si ganó Stickiness, una Win o un Rebirth.
2. **Una sola configuración.** Umbrales, ganancias, spawns y tiempos viven en `GameConfig`.
3. **Tags y Attributes.** Usar `CollectionService` para identificar collectibles, blockers y zone spawns; evitar scripts clonados dentro de cada objeto.
4. **Debounces por objeto y jugador.** `Touched` puede dispararse varias veces.
5. **Pools, no churn.** Reutilizar collectibles y attachments cuando sea práctico.
6. **Límite visual estricto.** Empezar en 30 y bajar a 20 si el test multijugador lo exige.
7. **Assets auditados.** Eliminar scripts desconocidos y rechazar modelos multiparte pesados.
8. **Persistencia pequeña.** Solo guardar `Wins`, `Rebirths`, versión del perfil y, si hace falta, mejor tiempo. Stickiness y Level son datos de la vuelta.

### Esquema de perfil

```lua
{
    SchemaVersion = 1,
    Wins = 0,
    Rebirths = 0,
    BestRunSeconds = nil,
}
```

Para no arriesgar datos, usar una librería estable con session locking o una implementación mínima muy probada. La persistencia no debe bloquear el loop local del lunes.

---

## 7. Analítica y criterios de éxito

Eventos mínimos:

| Evento | Propiedades |
|---|---|
| `session_start` | rebirths, wins |
| `first_pickup` | seconds_from_join |
| `pickup_denied` | zone, required, current |
| `zone_entered` | zone, seconds_from_join |
| `blocker_absorbed` | zone, seconds_in_zone, stickiness |
| `run_completed` | total_seconds, rebirths |
| `rebirth_used` | run_count, total_seconds |

Objetivos del prototipo:

- 90% recoge el primer objeto antes de 10 s.
- 70% absorbe el Toy Chest.
- 55% llega a Bedroom.
- 40% completa Kitchen.
- Mediana de tiempo entre pickups < 3 s.
- Primera vuelta mediana entre 180 y 300 s.
- Menos de 5% de sesiones queda 10 s o más sin un objeto elegible visible.
- En un servidor de 6 jugadores, el rendimiento se mantiene estable y la pila no oculta la lectura del personaje.

La analítica sirve para detectar dónde se rompe el loop; no se dedica medio día a construir dashboards.

---

## 8. Plan de lunes a viernes

### Lunes 3 — El verbo ya funciona (8–10 h)

#### Bloque 1: 60–90 min

- [x] Crear la experiencia y estructura mínima.
- [x] Crear `GameConfig` con Toy Room, umbrales y wraps.
- [x] Hacer greybox de una ruta corta, Toy Chest visible y 12 spawn points.
- [x] Usar cubos de colores; todavía no buscar arte.

**Notas de avance — 2026-08-03:**

- Lugar activo: `Exposición pegajosa`, verificado en modo Edit mediante Roblox Studio MCP.
- Se creó `Workspace.StuckToYou.Zones.ToyRoom` sin sobrescribir contenido previo; el lugar solo contenía la Baseplate y SpawnLocation por defecto.
- Toy Room incluye ruta lineal, señalización, punto de inicio, 12 spawn markers con requisitos `0/5/12/25` y un Toy Chest con requisito 50.
- Se creó `ReplicatedStorage.Shared.GameConfig` con zonas, niveles, Sticky Wraps, Rebirth y funciones puras de consulta.
- Verificación superada: `GameConfig` carga correctamente, los umbrales clave devuelven niveles 1/5/20, Rebirth 1 devuelve `1.5x`, existen 12 tags `ItemSpawn` y 1 tag `StickinessBlocker`.
- Siguiente paso: Bloque 2, comenzando por pickup autoritativo. Los marcadores todavía no son collectibles funcionales.

#### Bloque 2: 3 h

- [x] Implementar pickup autoritativo.
- [x] Implementar requisito rojo/verde.
- [x] Sumar Stickiness y actualizar HUD.
- [x] Respawn de 2 s con debounce correcto.

**Notas de avance — 2026-08-03:**

- Se separaron responsabilidades en `ProgressionService`, `CollectibleService`, `CollectibleFactory`, `HUDController` y `ObjectLabelController`.
- Todos los valores de balance, colores, límites, nombres de tags y RemoteEvent salen de `GameConfig`.
- El servidor identifica al jugador desde el contacto físico, valida Humanoid, distancia, requisito y estado activo; el cliente no solicita ni concede Stickiness.
- Cada pickup se bloquea antes de otorgar progreso para impedir premios dobles por eventos `Touched` simultáneos.
- Las conexiones, cooldowns y tareas de respawn tienen dueño y limpieza; `Destroy()` cancela threads, desconecta señales, limpia tablas y destruye instancias runtime.
- Prueba Play superada con 12 collectibles: rechazo de requisito 25 mantuvo Stickiness en 0; pickups elegibles actualizaron Stickiness, Level y HUD; un pickup inactivo volvió a `Active=true`, `Transparency=0` y `CanTouch=true` después de 2 s.
- Prueba visual superada a Stickiness 11: requisitos 0/5 verdes y 12/25 rojos.
- Prueba de teardown superada: al detener Play, `Collectibles` quedó con 0 hijos runtime y los spawn markers conservaron su estado de Edit.
- No se observaron errores propios del juego en servidor o cliente durante la prueba.
- Siguiente paso: Bloque 3, pila visual desacoplada con pool, slots predefinidos y límite configurable de 30.

#### Bloque 3: 3 h

- [x] Implementar pila visual con posiciones predefinidas.
- [x] Aplicar propiedades físicas seguras.
- [x] Límite de 30 attachments.
- [x] Probar con pickups rápidos y reset de personaje.

**Notas de avance — 2026-08-03:**

- Se creó `AttachmentService`, conectado a `CollectibleService` mediante un evento interno; el sistema de pickups no conoce welds, slots ni representación visual.
- `GameConfig.Attachments` controla límite, capacidad del pool, tamaño, rings de slots, escalas, colores y crecimiento posterior al límite.
- Los cuatro rings generan exactamente 30 slots deterministas alrededor de UpperTorso/Torso/HumanoidRootPart.
- Cada pieza usa `Massless=true`, `Anchored=false`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false` y un `WeldConstraint` válido.
- El pool en `ServerStorage` conserva como máximo 60 piezas libres; el exceso se destruye y cada jugador mantiene como máximo 30 records activos.
- Después de 30 pickups, no se crean partes adicionales: cada 5 pickups aumenta ligeramente el tamaño existente, hasta 5 pasos configurables.
- El reset del personaje reinicia Stickiness y Level, devuelve todas las piezas al pool y comienza sin `StickyPile` residual.
- Stress test superado: Stickiness llegó a 175, `VisualAttachmentCount` permaneció en 30, los slots fueron únicos, el crecimiento se topó en 5 y el personaje siguió navegando.
- Test de reset superado: `30 → 0` visuals, Stickiness `175 → 0`, Level `→ 1` y 30 piezas recuperadas en el pool.
- Test de reutilización superado: el siguiente pickup tomó piezas del pool (`30 → 25`) en vez de crear otras nuevas.
- Teardown de Play limpio: sin pool ni collectibles runtime persistidos en Edit y sin errores del juego en consola.
- Siguiente paso: Cierre del lunes, absorción del Toy Chest y medición real de 45–60 s.

#### Cierre: 60–90 min

- [x] Toy Chest requiere 50, se vuelve verde y puede absorberse.
- [x] Grabar tiempo desde spawn hasta el blocker.
- [ ] Confirmar con una prueba manual de jugador nuevo que la zona dura 45–60 s; ajustar densidad solo si queda fuera.

**Notas de cierre — 2026-08-03:**

- Se creó `BlockerService`, reusable y server-authoritative, que descubre blockers por tag y attributes.
- La validación compartida de Humanoid, Character y distancia se extrajo a `PlayerCharacterUtil`; collectibles y blockers usan el mismo contrato.
- El estado de absorción es por jugador: completar Toy Chest no lo elimina ni lo abre globalmente para otros jugadores.
- `BlockerController` cambia el chest completo a verde en 50, ejecuta una absorción local de 0.55 s y desactiva colisión local para abrir la salida.
- Se añadió `ExitPreview` detrás del chest para verificar físicamente que el jugador puede atravesar la puerta.
- El HUD cambia de `TOY CHEST` a `BED` y `CurrentZoneId` cambia a `Bedroom` después de una absorción válida.
- Rechazo probado con Stickiness 0: feedback `NEED 50 MORE`, sin absorción ni cambio de zona.
- Éxito probado con Stickiness 54: 3/3 partes verdes antes del contacto; después, 3/3 ocultas y sin colisión, Billboard apagado y salida transitable.
- Seguridad multijugador comprobada: después del éxito local, el modelo de servidor permaneció visible y con colisión para otros jugadores.
- Reset comprobado: Stickiness 0, Level 1, visuals 0, Toy Room restaurado y chest rojo/visible/con colisión.
- Se detectó una carrera de replicación cliente: el tag del blocker podía llegar antes que sus descendientes. La mitigación inicial con retry fue reforzada después del playtest manual; ver la corrección posterior.
- Ruta óptima automatizada con movimiento normal: 36 pickups, Stickiness 51 y absorción en **42.1 s**. Al ser una ruta perfecta sin dudas ni desvíos, no se cambió balance; falta confirmar 45–60 s con una persona nueva.
- La medición server-side se guarda en `LastZoneSeconds` y la zona en `LastCompletedZoneId` para futura analítica.
- Sin errores del juego en consola durante las pruebas finales.

**Corrección posterior al playtest manual — 2026-08-03:**

- Reporte real: el servidor mostraba `ZONE OPEN!`, pero Toy Chest no se ponía verde ni desaparecía.
- Causa raíz: `BlockerController` podía perder el registro si tag, attributes y descendientes no estaban disponibles dentro del retry inicial de 0.5 s. El flujo de servidor sí funcionaba; fallaba únicamente la presentación cliente.
- Corrección: el cliente descubre blockers también por attribute `BlockerId` al iniciar, cuando cambia Stickiness y como fallback al recibir una absorción autoritativa. Después de registrar el modelo no vuelve a escanear.
- Rendimiento: no se añadió polling. Se conserva un scan inicial acotado, un retry cancelable y scans de recuperación únicamente mientras no exista ningún blocker registrado.
- Regresión completa superada: rojo → verde en 50 → tres partes ocultas/sin colisión → Bedroom → reset rojo/visible.
- Estabilidad de arranque: estado verde verificado en tres sesiones Play independientes.
- Consola limpia después de la corrección.

**Entregable del lunes:** entrar, tocar cubos, verlos pegarse, aumentar Stickiness y absorber un Toy Chest. Feo, pero el juego central ya existe.

**Checkpoint duro:** si el objeto no se pega de forma estable y satisfactoria al terminar hoy, mañana no se empieza persistencia, rebirth ni arte.

### Martes 4 — Vuelta completa en gris (8–10 h)

- [x] Convertir Toy Room en zona data-driven.
- [x] Implementar Room Manager y pool de respawn.
- [x] Construir Bedroom y Kitchen en greybox.
- [x] Crear gates Toy Chest → Bedroom, Bed → Kitchen y Refrigerator → Finish.
- [x] Implementar Level derivado y autoequip de wraps.
- [x] Implementar Win y reinicio de vuelta.
- [x] Añadir tutorial ambiental de una línea y camino visual.
- [x] Probar la vuelta completa 10 veces; registrar duración por zona.

**Notas de avance — 2026-08-03, fase 1 del martes:**

- `RoomService` registra únicamente folders con tag `StickyZone`, valida `ZoneId` contra `GameConfig` y exige la estructura `Geometry/ItemSpawns/Collectibles/Blockers`.
- `SpawnService` quedó como dueño exclusivo de disponibilidad, objetivo activo, reservas, cooldown y rotación; `CollectibleService` solo valida el contacto y concede progreso.
- Toy Room usa 12 instancias persistentes, 10 activas y 2 en reserva; el respawn reutiliza el pool y evita reactivar inmediatamente el mismo punto consumido.
- El mínimo configurable es 4 objetos alcanzables con el Stickiness de entrada. `Spawn_09` funciona como reserva de entrada para restaurar ese mínimo tras un consumo.
- Pruebas Play superadas: arranque limpio, `12 total / 10 activos / 2 reservas / 4 elegibles`, pickup real, retorno a 10 activos, rotación hacia otra reserva y conteo constante de 12 instancias.
- La primera ejecución de prueba detectó que podía reaparecer el mismo spawn; se añadió exclusión explícita del handle consumido y la regresión posterior quedó verde.
- No hubo errores del juego en consola. El nuevo `Workspace.StuckToYou.Zones.Lobby.Geometry` se conservó y no se registró como zona jugable.
- Siguiente paso: construir Bedroom y Kitchen reutilizando exactamente este contrato de zona, sin duplicar scripts ni lógica.

**Notas de avance — 2026-08-03, fase 2 del martes:**

- Se construyeron `Bedroom` y `Kitchen` como salas lineales contiguas a Toy Room, cada una con `Geometry`, `ItemSpawns`, `Collectibles` y `Blockers`; no se duplicaron scripts.
- Cada sala tiene 12 markers authored, 10 pickups activos, 2 reservas y exactamente 4 objetos alcanzables con su Stickiness de entrada (`50` en Bedroom, `180` en Kitchen).
- Bedroom usa una Bed de varias piezas con requisito 180; Kitchen usa un Refrigerator con requisito 500. Ambos blockers salen de attributes y tags compatibles con el sistema reusable existente.
- Prueba real de ruta superada exclusivamente mediante pickups/contactos: Toy Room llegó a 51 y abrió Bedroom; Bedroom llegó a 183 y abrió Kitchen; Kitchen llegó a 503, Level 20 y `CosmicGlue`, y Refrigerator apuntó correctamente a `FinishZone`.
- Rechazo de Bed probado a Stickiness 0: no hubo absorción, progreso ni cambio de zona.
- Absorción local probada en Toy Chest, Bed y Refrigerator: ocultos y sin colisión para el jugador, mientras el estado sigue siendo por jugador.
- Reset probado después de completar la ruta lógica: Stickiness 0, Level 1, `BasicGlue`, `CurrentZoneId=ToyRoom`, pile visual 0 y los tres blockers restaurados.
- Se detectó que una sola comprobación cliente a los 0.5 s podía perder tags/attributes durante la replicación de tres zonas. `BlockerController` ahora hace tres pases iniciales finitos y cancelables (`0.25/0.75/1.5 s`), sin polling permanente.
- Estado rojo inicial corregido: todos los BaseParts de un blocker usan el color inelegible de `GameConfig`, y cambian al verde elegible con el mismo contrato.
- Smoke test final limpio: los tres pools registraron `12/10/4`, los tres blockers aparecieron rojos y no hubo errores del juego en consola.
- `Lobby` se preservó mientras otra sesión colaborativa añadía geometría; ninguna de sus piezas fue modificada por esta fase.
- Siguiente paso: completar físicamente `FinishZone`, cerrar los gates como recorrido final y otorgar exactamente una Win con reinicio de vuelta.

**Notas de avance — 2026-08-03, fase 3 del martes:**

- Se construyó `FinishZone` físico detrás de Kitchen, separado del tag `StickyZone` porque no contiene collectibles ni pertenece al contrato de `RoomService`. Incluye `FinishSpawn`, resumen ambiental y `ReplayPad`.
- Se añadió `FinishService`: escucha el evento genérico de absorción, valida `BlockerId/ZoneId/NextZoneId` desde `GameConfig`, bloquea el cierre por jugador antes de premiar y otorga exactamente una Win mediante `ProgressionService`.
- La finalización replica `RunCompleted`, Stickiness, Level y tiempo del último recorrido; limpia la pila mediante la API pública de `AttachmentService`, conserva el character y teletransporta al jugador a Finish.
- El replay reutiliza APIs pequeñas de `ProgressionService`, `BlockerService` y `AttachmentService`: conserva Wins, reinicia progreso/wrap/zona, restaura los tres blockers, limpia visuals y vuelve al `StartSpawn` sin recargar el character.
- Rechazo probado: tocar Replay antes de terminar no cambió Wins, progreso ni estado; tocar Refrigerator tras el reset con Stickiness 0 tampoco concedió premio ni cambió de zona.
- Ruta completa probada con contactos reales: `50 → ToyChest → 180 → Bed → 503/Level 20/CosmicGlue → Refrigerator`; resultado: una Win, resumen válido, pile 0 y teletransporte a Finish. Cinco contactos adicionales con Refrigerator mantuvieron Wins en 1.
- Replay probado: Wins 1 se conservó, el run volvió a `0/Level 1/BasicGlue/ToyRoom`, los blockers reaparecieron rojos y un pickup de requisito 0 inició correctamente una nueva vuelta. Muerte/respawn también limpió la vuelta sin perder la Win de sesión.
- Teardown verificado: las tres carpetas runtime `Collectibles` quedaron vacías en Edit. Smoke final limpio en servidor y cliente, sin errores del juego. `Lobby` siguió fuera de nuestras escrituras mientras su contenido cambiaba en paralelo.
- Siguiente paso: añadir el tutorial ambiental mínimo y ejecutar/registrar las 10 vueltas completas de balance del martes.

**Notas de avance — 2026-08-03, fase 4 del martes:**

- Se añadió una sola instrucción ambiental frente al `StartSpawn`: `TOUCH SMALL OBJECTS → GROW → ABSORB THE GREEN BLOCKER`. Está a 9.6 studs del spawn, no tiene colisión/touch y reutiliza la ruta visual amarilla existente.
- Al preparar la medición se corrigió una semántica engañosa: `LastZoneSeconds` medía tiempo acumulado de vuelta. `BlockerService` ahora mantiene relojes separados de zona y run; el payload expone `ZoneSeconds` y `RunSeconds`, y Finish usa el total correcto.
- Se ejecutaron 10 vueltas completas consecutivas en el mismo servidor mediante contactos reales de física, sin inyectar Stickiness: 10/10 terminaron en 503, otorgaron exactamente una Win y completaron replay.
- Línea base automatizada acelerada (mínimo / promedio / máximo): Toy Room `10.53 / 11.66 / 13.63 s`; Bedroom `8.88 / 9.80 / 10.72 s`; Kitchen `6.13 / 6.82 / 7.62 s`; total `27.20 / 28.28 / 29.28 s`.
- Promedio de pickups exitosos por vuelta: Toy Room `36.2`, Bedroom `28.7`, Kitchen `21.2`. Las diferencias entre vueltas vienen de la selección/rotación real del pool.
- Después de 10 replays: Wins 10, Stickiness 0, Level 1, pile 0, blockers visibles/rojos y cada zona restaurada a `12 instancias / 10 activas`. El ReplayPad en una vuelta incompleta no mutó el estado.
- Estos tiempos son una regresión acelerada del sistema, no una medición de experiencia humana. No se cambió balance con datos artificiales; siguen pendientes una vuelta manual de 3–5 min y la confirmación de Toy Room en 45–60 s con jugador nuevo.
- Teardown limpio: las tres carpetas `Collectibles` quedaron vacías en Edit y la consola final no mostró errores del juego. `Lobby` continuó cambiando en paralelo y no fue modificado.
- Siguiente paso: iniciar el miércoles con persistencia de Wins/Rebirths y Rebirth 0 → 1, manteniendo el playtest humano como validación pendiente.

**Entregable del martes:** una vuelta completa de 3–5 min, desde el primer pickup hasta la Win, sin comandos ni intervención manual.

**Checkpoint de diversión:** jugar 20 min con cubos. Si no provoca empezar otra vuelta, ajustar densidad, velocidad de ganancia, tamaño de la pila y feedback antes de agregar sistemas.

### Miércoles 5 — Progresión, datos y multijugador (8–10 h)

- [x] Persistir Wins y Rebirths.
- [x] Implementar Rebirth 0 → 1 y verificar el multiplicador de 1.5x.
- [x] Finish / Rest Zone con resumen y replay.
- [x] Probar respawn, reconexión, cierre del servidor y datos faltantes.
- Probar con 3–6 jugadores o clientes simulados.
- Corregir carreras de `Touched`, escasez de pickups y limpieza de attachments.
- Añadir los siete eventos analíticos.
- Revisar HUD en teléfono, tablet y desktop.

**Notas de avance — 2026-08-03, miércoles fase 1:**

- Se creó `DataService` con perfil versionado, normalización de datos faltantes, `UpdateAsync`, session lock, reintentos configurables, autosave cancelable, guardado al salir/cerrar y backend mock limitado a Studio. En producción usa `DataStoreService` real.
- `ProgressionService` carga Wins/Rebirths desde el perfil, mantiene Stickiness como dato de vuelta y guarda cambios persistentes. Rebirth se guarda inmediatamente además del autosave.
- Rebirth solo se acepta en servidor después de completar la vuelta, alcanzar el level cap y no superar `MaximumImplementedRebirth`; una segunda solicitud queda rechazada.
- Se añadió `StarterGui.StickyHUD` como plantilla authored visible en Explorer. `HUDController` ya no crea UI en runtime: valida y enlaza `ProgressPanel`, `RebirthPanel` y `RebirthButton` desde la plantilla.
- Prueba de rechazo superada: solicitar Rebirth al inicio mantuvo `Rebirths=0`, `Stickiness=0` y `RunCompleted=false`.
- Prueba exitosa superada mediante pickups y blockers reales: `503 Stickiness / Level 20 / Win 1`; Rebirth produjo `Rebirths=1`, conservó `Wins=1`, reinició `Stickiness=0`, `Level=1`, zona `ToyRoom`, pile 0 y ocultó el panel.
- Verificación de multiplicador superada: el primer pickup Basic Glue después de Rebirth otorgó exactamente `+1.5 Stickiness`.
- Guardado mock verificado con snapshot `Wins=1 / Rebirths=1`; cierre y teardown dejaron cero collectibles runtime y consola limpia en el smoke final.
- Bugs encontrados por prueba y corregidos: carrera entre carga y espera del perfil; `CurrentZoneId` permanecía en FinishZone después de Rebirth; espera del HUD podía emitir una advertencia antes de que StarterGui terminara de clonarse.
- Pendiente para cerrar el bloque de datos: prueba controlada contra DataStore cloud con salida/reentrada real, caso de fallo de API y reconexión. No se activó desde Studio para no tocar datos reales del usuario.

**Notas de avance — 2026-08-03, miércoles fase 2:**

- El probe read-only confirmó que el place ya tenía acceso a DataStore cloud; no se modificaron ajustes de seguridad.
- Se usó el almacén aislado `StuckToYouProfile_CloudValidation_20260803_v1`, separado del perfil de producción. Un perfil ausente cargó con defaults seguros `Wins=0 / Rebirths=0`.
- Prueba cloud completa: una vuelta real guardó `Wins=1 / Rebirths=1`; se cerró el servidor, se abrió uno nuevo y recuperó exactamente ambos valores, `Multiplier=1.5`, `Stickiness=0`, `Level=1` y zona `ToyRoom`.
- Respawn aprobado después de reconectar: character reemplazado, Wins/Rebirths y multiplicador conservados, run/pile/blockers limpios.
- Se añadió una inyección de fallos exclusiva del mock de Studio y configurable en `GameConfig.Data.StudioMockFailuresBeforeSuccess`.
- Retry aprobado: dos fallos consecutivos cargaron correctamente en el tercer intento. Fallo terminal aprobado: tres fallos marcaron `DataLoadFailed=true` y no inicializaron progreso ni defaults guardables.
- La configuración final fue restaurada a `StuckToYouProfile_v1`, `UseStudioMockStore=true` y cero fallos inyectados. Smoke final limpio y Studio en Edit.
- Siguiente paso: prueba de 3–6 jugadores/clientes simulados, con atención a carreras de `Touched`, disponibilidad de pickups y limpieza individual de attachments.

**Entregable del miércoles:** todos los sistemas del MVP existen y funcionan en un server multijugador. A partir de aquí se viste y se pule; no se inventan features.

**Notas de avance — 2026-08-03, objetos per-player (inserción de alcance pedida por diseño):**

Detalle completo del diseño en `PLAN_PER_PLAYER_OBJECTS.md`. Resumen de lo construido y probado:

- Sistema viejo retirado: `SpawnService`, `CollectibleService` y `CollectibleFactory` eliminados. El servidor ya no crea ni replica ningún collectible.
- Nuevos módulos servidor: `ItemPlacementService` (slots por sala, cacheados), `ItemPlanner` (reparto equitativo, puro), `RoomSettingsReader` (lee la config authored del Workspace), `RoomItemService` (sesión por jugador y sala), `PickupService` (validación autoritativa).
- Nuevos módulos cliente: `CollectibleRenderer` (clona plantillas authored con pool local) y `CollectibleController` (sync + un solo loop throttled de proximidad). `ObjectLabelController` reescrito para usar Highlights pooled y no repintar el arte.
- Contrato `ConnectCollected` conservado: `AttachmentService`, `ProgressionService`, `BlockerService` y `FinishService` no se tocaron.
- Plantillas authored creadas en `ReplicatedStorage/Assets/Collectibles` (9 props greybox + `_RequirementBillboard`). Esto además corrige la deuda con la regla 5 de `AGENTS.md`, ya que el cubo y su billboard se construían por código.
- Config authored por sala creada en `Zones/<Zone>/RoomSettings` y volumen `PlacementArea` por sala.

Pruebas ejecutadas en Studio (Play, un jugador):

- Slots: 24 por sala con `TotalObjects=12` y separación 8; separación real mínima medida 8.4–9.0; generación 0–2 ms. Cero slots dentro del Toy Chest, distancia mínima al borde del chest 8.5 studs.
- Capacidad: 46 slots con separación 8, 73 con separación 6 y 103 con separación 5 (50–150 ms, repartidos en frames). Margen suficiente para subir bastante `TotalObjects`.
- Reparto: 2400 combinaciones (3 salas × 4 totales × 200 seeds) con total exacto siempre y mínimo de elegibles ≥ 4 en todos los casos. 24 objetos / 3 tipos → 8/8/8; 25 → 9/8/8.
- Pickup elegible: 0.33 s desde que el jugador llega; Stickiness sube y el objeto desaparece solo para él.
- Rechazo: objeto de requisito 25 con Stickiness 0 no se recoge y emite `NEED X MORE` a la cadencia del cooldown del servidor.
- Respawn: la sala vuelve a su objetivo a los ~2 s, en un slot distinto.
- Ciclo de vida: cambio de sala carga y descarga, `FinishZone` deja la sesión en cero, muerte reinicia con layout nuevo y Stickiness 0, sin tareas ni slots huérfanos.
- Optimización confirmada: con el jugador en ToyRoom, `slots Bedroom: not generated` y `slots Kitchen: not generated`. Las salas sin jugadores no calculan nada.
- Servidor limpio: cero instancias tagueadas `StickyCollectible`, cero hijos en las carpetas `Collectibles`, y los 36 markers `ItemSpawns` ocultos en runtime.
- Rechazos registrados en la prueba: solo `TooFar=12`, todos provocados por teletransportes del script de prueba antes de que replicara la posición del personaje. Ningún rechazo espurio.

**Ajustes posteriores — mismo día:**

- `TotalObjects` subido a 24 en las tres salas, con `MinSeparationStuds` en 8. Verificado: 24 objetos renderizados por jugador, 46 slots en ToyRoom, 22 libres para respawn.
- Bug corregido: cambiar `TotalObjects` no invalidaba el cache de slots. El tamaño del pool de slots se deriva de `TotalObjects`, así que subirlo sobre una sala ya cacheada dejaba cero slots libres y el respawn se quedaba sin sitio.
- Causa de que los cambios manuales "no se vieran": los valores sí se guardaban, pero `MinSeparationStuds` estaba en 22 en ToyRoom. Con esa separación apenas caben ~7 posiciones en la sala, así que subir `TotalObjects` no producía más objetos. Es el caso que el `warn` de `ItemPlacementService` ya reporta en consola.
- **La pila ahora usa el mismo objeto recogido.** `AttachmentService` clona la plantilla authored del objeto en lugar de crear un cubo genérico. Tamaño normalizado por `TargetMaxSizeStuds` (1.6) multiplicado por el tier de requisito, así un ToyCar authored de 3.2 studs y un ToyBlock de 2.5 quedan ambos en 1.20 pegados al personaje. El prop conserva su color.
- Verificado: orden de recogida y orden de la pila coinciden 1:1 (`ToyBlock, ToyBlock, ToyBall, ToyCar, ToyBall, ToyBlock, ToyCar`); con 30 attachments y paso de crecimiento 5, cero partes sin soldar y distancia máxima al personaje de 2.48 studs; el reset devuelve todo al pool.

**Corrección del feedback de elegibilidad — mismo día:**

- Roblox renderiza **un máximo de 31 `Highlight` por cliente**, los deshabilitados también ocupan slot, y no hay API para subirlo. La petición al DevForum sigue abierta sin respuesta de staff. La documentación oficial menciona 255 slots de instancia, pero el límite de render efectivo que reportan los desarrolladores es 31.
- El diseño anterior limitaba los Highlights a los 16 objetos más cercanos, así que con 24 objetos por sala había 8 sin marcar. Un estado parcial se lee peor que ningún estado.
- Sustituido por atenuar los colores propios del prop: elegible al color authored, no elegible al mismo color multiplicado por `IneligibleTintFactor` (0.32). Conserva el tono, así que una esfera se sigue reconociendo como esfera, y no tiene ningún límite de instancias.
- Se conserva **un solo** `Highlight` como marca del objeto enfocado, con un significado distinto: "este es el que vas a agarrar", no "puedes agarrarlo".
- Verificado con 24 objetos: cero desajustes entre estado real y estado visual en spawn, junto a un objeto y tras cruzar un tier de requisito.
- Verificado con **60 objetos**, casi el doble del límite de Highlights: 30 en claro, 30 atenuados, **cero desajustes**, con una única instancia de Highlight en todo el cliente.

**Legibilidad y reciclaje de la pila — mismo día:**

- Atenuar el color no bastaba para distinguir lo recogible de lo no recogible. Los objetos no elegibles ahora son además semitransparentes (`IneligibleTransparency = 0.4`). Elegible = color pleno y sólido. Verificado con 24 objetos: 6 sólidos, 18 semitransparentes, cero desajustes.
- Límite de la pila subido de **30 a 36** (+20%). El contrato entre `MaxVisualAttachments` y los anillos se mantiene con un anillo nuevo de 6 slots a altura −2.05, por debajo de la cabeza para no tapar la cámara.
- **Reciclaje FIFO:** al llegar a 36, cada nuevo pickup expulsa el más antiguo y ocupa su mismo slot. Antes los pickups por encima del tope simplemente no se pegaban. Verificado con 62 recogidas seguidas: la pila se queda exactamente en 36 y siempre muestra lo más reciente.
- Dos animaciones cortas, movidas por un único `Heartbeat` compartido en lugar de una tarea por pieza:
  - **Vuelo:** el objeto recogido viaja desde su posición en el suelo hasta su slot en el cuerpo, con arco y giro. El destino se recalcula cada frame, así que persigue al jugador aunque se esté moviendo.
  - **Fundido:** la pieza expulsada se despega, se encoge y se desvanece en `Workspace.StickyDiscards`, desacoplada de la vida del personaje para que un reset a mitad del fundido no destruya una instancia del pool.
- Verificado sin fugas: tras 62 recogidas y un reset, `StickyDiscards` queda en 0, `animating=0` y 40 instancias reutilizadas en el pool.
- `ClientMain` ahora aísla el arranque de cada controlador con `pcall`. Un `WaitForChild` lento de `StarterGui` hacía fallar `HUDController` y con él se caía toda la cadena, dejando al jugador sin objetos. El fallo se sigue reportando en consola.

**Blockers pegados al jugador — mismo día:**

- Al absorber un blocker, una copia reducida del propio modelo se pega al jugador como cualquier otro objeto, volando desde la puerta hasta el cuerpo. Refuerza la lectura de que hay que pegarse los bloqueadores para poder avanzar entre salas.
- Tamaño mayor que un collectible normal (`BlockerSizeMultiplier = 1.75`, es decir 2.8 studs frente a 1.2–2.16) porque es el trofeo que abre la sala.
- Exentos del reciclaje FIFO (`ProtectBlockerAttachments`). Con 3 blockers por vuelta cuesta 3 slots de 36, y evita que el trofeo se pierda a las 36 recogidas siguientes.
- El clon se sanea antes de entrar al mundo: se le quitan tags, los atributos `BlockerId`/`NextZoneId` y los `BillboardGui`. Sin eso `BlockerController` habría descubierto la copia sobre el jugador como un blocker real, porque escanea `Workspace` por el atributo `BlockerId`.
- `AttachmentService` se refactorizó a una función `attach` común con dos entradas: `PickupService.ConnectCollected` y `BlockerService.ConnectAbsorbed`. Sin ciclo de dependencias: `BlockerService` no requiere `AttachmentService`.
- Verificado: Toy Chest y Bed pegados a la vez (3.5 studs cada uno con la pila crecida), `tags=0`, `BlockerId=nil`, sin billboards; el Toy Chest sobrevivió a 40 recogidas posteriores que sí expulsaron piezas normales; el reset devuelve también los trofeos al pool y `StickyDiscards` queda en 0.

**Bug de blockers a medio desaparecer — mismo día:**

- Síntoma reportado: al absorber la cama del Bedroom solo desaparecía una parte del mueble; el resto se quedaba plantado.
- No era un problema del modelo. `Bed` es un Model correcto con sus 5 partes dentro (Frame, Mattress, Blanket, Pillow, Headboard) y el Headboard es el que sella el hueco de la puerta.
- Causa real: `BlockerController` capturaba la lista de partes con un único `GetDescendants()` al descubrir el Model. Un Model y sus partes no llegan necesariamente al cliente en el mismo frame, así que una lista incompleta dejaba partes sin ocultar, y los tres pases de reintento se salían porque `records[instance]` ya existía. El Bed es el más expuesto por tener 5 partes y estar más lejos del spawn. Intermitente por definición.
- Arreglo: la lista se auto-repara. `refreshParts` adopta partes nuevas en cada actualización y una conexión `DescendantAdded` las incorpora en cuanto llegan, aplicándoles al momento el estado que ya tiene el resto del blocker.
- Verificado reproduciendo el fallo a propósito: con el cliente ya siguiendo la cama, se le añadió desde el servidor una parte nueva (`LateLeg`). Al absorber, se ocultaron las 6 partes y `STILL VISIBLE` quedó vacío. El trofeo se pegó con las 6 partes.
- `HUDController` esperaba su plantilla 10 s. En arranques pesados de Studio eso expiraba y el jugador se quedaba sin HUD; subido a 30 s. La plantilla ausente de verdad sigue fallando de forma explícita.

**Revisión de optimización — mismo día:**

- `AttachmentService` tenía un `Heartbeat` permanente que recorría una lista vacía en cada frame cuando no había nada animándose. Contradecía la regla 2 de `AGENTS.md` ("ningún loop frecuente sin condición de salida"). Ahora la conexión se crea al empezar una animación y se corta cuando la última termina.
- `ObjectLabelController.Apply` ordenaba la lista completa de objetos en cada tick (10 veces por segundo, hasta 60 elementos) solo para quedarse con el más cercano. Sustituido por un único recorrido que aplica el estado y busca el mínimo a la vez. De paso deja de mutar la lista que recibe.
- `BlockerController` llamaba a `refreshParts` en cada actualización, con un `GetDescendants()` por blocker en cada cambio de Stickiness. Conectando `DescendantAdded` **antes** del primer escaneo desaparece la ventana que hacía falta cubrir, así que el refresco periódico sobra.
- Revisado y considerado aceptable sin cambios: el loop de proximidad del cliente asigna una tabla por objeto y tick (~600 tablas pequeñas por segundo con 60 objetos), muy por debajo de lo que molesta al GC de Luau y a cambio el código queda legible.
- Verificado tras los tres cambios: cama absorbida completa incluida la parte tardía, cofre completo, pila 36/36 con `animating=0`, tres salas con slots generados y consola limpia.

**Pedestales de Win y pasillos entre salas — mismo día:**

- Pasillo corto authored después de la puerta de cada sala, en `Workspace/StuckToYou/Corridors/<Zona>Exit`: dos paredes laterales de 22 studs de ancho, una franja de suelo y el pedestal centrado con 7,5 studs libres a cada lado para poder rodearlo.
- Premios 1 / 3 / 10 Wins según la sala limpiada, editables a mano en el atributo `WinReward` del pedestal (gana sobre el valor por zona de `GameConfig`).
- Pisarlo cobra las Wins y devuelve al inicio con la vuelta reiniciada. Pasar de largo conserva la vuelta y deja optar al pedestal mayor de la sala siguiente. Es el bucle de riesgo/recompensa del documento de diseño.
- `WinPedestalService` valida en servidor que el jugador limpió esa zona en la vuelta actual (`CompletedZone_<ZoneId>`), con lock por jugador y debounce contra pagos dobles.
- `FinishService.ReturnToStart` centraliza reinicio y teletransporte; lo comparten ReplayPad, Rebirth y pedestales.

Dos consecuencias necesarias para que el sistema sea coherente, ambas detrás de flags reversibles:

- `GameConfig.Wins.AwardOnRunCompletion = false`. Absorber el Refrigerator ya no da una Win automática; si no, pagaría dos veces junto a su propio pedestal de 10.
- `GameConfig.Finish.TeleportOnCompletion = false`. Antes el jugador era teletransportado a `FinishSpawn` 0,65 s después de absorber el Refrigerator, lo que lo dejaba **al otro lado** del último pedestal y lo hacía inalcanzable. Ahora sale caminando y elige. La FinishZone conserva su papel para quien pasa de largo: ReplayPad y panel de Rebirth.

Pruebas ejecutadas:

- Pisar el pedestal sin haber limpiado la sala: no paga nada y no reinicia.
- Limpiar Toy Room y cobrar: `Wins 0 → 1`, Stickiness a 0, pila vacía, jugador de vuelta en el StartSpawn.
- Limpiar Toy Room, **pasar de largo** el pedestal de 1: Wins sigue en 0 y la vuelta continúa con Stickiness 51 hacia Bedroom.
- Limpiar Bedroom y cobrar el de 3: `Wins 0 → 3` y reinicio correcto.
- Vuelta completa hasta Stickiness 503, absorber el Refrigerator: el jugador **se queda en la Kitchen** (`posZ=-218`, no teletransportado), `RunCompleted=true` y las Wins no cambian.
- Cobrar el pedestal de 10: `Wins 3 → 13` y reinicio correcto.
- El texto del pedestal se construye clonando la plantilla authored `_RequirementBillboard`; una BillboardGui equivalente creada a mano no renderizaba su texto.

**Bug de tarjetas en negro sin número — 2026-08-05:**

- Síntoma reportado: varios objetos mostraban su tarjeta de requisito como un rectángulo negro, sin la cifra.
- Descartado primero por medición: los datos estaban bien. Los 24 objetos tenían billboard, `Text` correcto y `TextColor3` correcto (18 en verde elegible, 6 en rojo). No era un fallo de `ObjectLabelController` ni del pool de clones.
- Causa real: el `Size` de `_RequirementBillboard` estaba en Offset (`{0,90},{0,44}`), así que **la tarjeta ocupaba 90×44 píxeles a cualquier distancia**. Con 24 objetos por sala, los lejanos proyectan sus tarjetas a tamaño completo sobre las cercanas; el fondo del `TextLabel` es opaco (`BackgroundTransparency = 0.15`), de modo que una tarjeta tapaba el número de la vecina. Y con `AlwaysOnTop = true` no hay orden por profundidad, así que la que ganaba podía ser la lejana.
- Medido en el peor caso (cámara a ras de suelo mirando la sala a lo largo): **15 parejas de tarjetas solapadas** de 19 visibles.
- Arreglo, todo en la plantilla authored y editable desde el Explorer: `Size` en studs (`{2.6,0},{1.27,0}`), `AlwaysOnTop = false` y `MaxDistance = 50`.
- Resultado medido en el mismo peor caso: 3 parejas solapadas y **ninguna tarjeta sin número**, porque la que tapa es siempre la más cercana y por tanto la más grande, así que la de atrás asoma con su cifra. En vista de juego normal y en vista alta: 0 solapes.
- Se eliminó `GameConfig.Collection.LabelMaxDistance`, que estaba muerto: ningún script lo leía y el valor real vivía en la plantilla. El tamaño y la distancia de la tarjeta se ajustan ahora en `ReplicatedStorage/Assets/Collectibles/_RequirementBillboard`.
- Nota: los carteles de blocker y de pedestal siguen en píxeles a propósito, para que se lean igual desde toda la sala. Son instancias únicas, así que no se apilan entre ellas; solo pueden cruzarse entre sí mirando desde una sala hacia el pasillo siguiente.

Pendiente, no ejecutable desde esta herramienta:

- **Prueba con 2 jugadores en la misma sala** (`Test > Clients and Servers > 2 Players`). Es la verificación directa de la petición de diseño. Pasos en `MANUAL_TEST_CHECKLIST.md`.

### Jueves 6 — Arte y gratificación (8–10 h)

- [x] Elegir un único lenguaje visual: low-poly cartoon, colores saturados, siluetas grandes.
- [ ] Reemplazar cubos por objetos temáticos de una sola pieza.
- [ ] Vestir las tres zonas sin cambiar la ruta.
- [x] Auditar y borrar scripts de todos los assets importados.
- [x] Crear variantes de SFX de pickup, sonidos de blocker, level up, win y rebirth.
- [x] Añadir partículas, popups, pulsos y camera shake moderado.
- [x] Hacer visible el cambio de cada Sticky Wrap.
- [x] Pasada de iluminación y señalización.
- [x] Prueba de rendimiento con el máximo de attachments.

**Notas de avance — 2026-08-05, jueves fase 1 (iluminación y gratificación):**

Punto de partida medido antes de tocar nada: **cero `Sound`, cero `ParticleEmitter` y cero luces en todo el place**. Las salas sí tenían paleta authored por zona (ToyRoom crema/azul, Bedroom lila, Kitchen verde) con `SmoothPlastic` y franja de ruta `Neon`, así que el lenguaje visual estaba a medias y lo que faltaba entero era la gratificación.

*Iluminación y post-proceso (instancias authored en `Lighting`, todas editables desde el Explorer):*

- `Brightness` 3 → 2. Estaba quemando las paredes claras.
- `Ambient` y `OutdoorAmbient` pasan de gris `0.27` a azulado (`72,74,96` y `140,150,178`). El gris neutro desatura todo; el tinte frío da sombra de dibujo animado.
- `ExposureCompensation` 0 → 0.15, `EnvironmentDiffuseScale` 1 → 0.6, `EnvironmentSpecularScale` 1 → 0.4, `ShadowSoftness` 0.35.
- **`ColorCorrectionEffect` nuevo llamado `ColorGrade`** con `Saturation = 0.28` y `Contrast = 0.12`. Es el único cambio que más separa un greybox de un juego publicado.
- `Bloom`: `Threshold` 2.0 → 1.15 e `Intensity` 1.0 → 0.65, para que brille la franja `Neon` y no las paredes.
- `Atmosphere`: `Haze = 0.7` y `Decay` azulado, que da profundidad al fondo de la sala.
- `SunRays`: estaba en `Intensity = 0.01`, es decir apagado; ahora 0.06.

*Biblioteca authored de gratificación en `ReplicatedStorage/Assets/Feedback`:*

- `Audio/`: cuatro `Sound` (`Pickup`, `Denied`, `LevelUp`, `Absorb`). Los cuatro `SoundId` son de **ProSoundEffects**, la biblioteca licenciada que Roblox distribuye gratis. Descartados a propósito los resultados más populares del Creator Store por ser rips con copyright (Mario Kart, Undertale, Sonic), que es riesgo de moderación al publicar.
- `Particles/`: `PickupBurst` (chispa corta, 0.3 s) y `AbsorbBurst` (estallido grande, 0.85 s). Textura `rbxasset://` incluida en el cliente, sin dependencia de asset externo.
- `UI/_ScorePopup`: `BillboardGui` en studs con `TextLabel` `Amount`. Clonado de `_RequirementBillboard`, por el problema conocido de que una BillboardGui construida a mano en este place no renderiza su texto.

*`FeedbackController` (cliente):*

- Recoger: sonido con **tono creciente por racha** (cada recogida encadenada dentro de `ComboWindowSeconds` sube el pitch, hasta 12 pasos), popup `+N` que sube y se desvanece, y chispa. Popup y chispa salen retrasados `Attachments.FlightSeconds`, para que el golpe coincida con el aterrizaje de la pieza en el cuerpo y no con la confirmación del servidor.
- Rechazo: sonido propio y la racha se corta.
- Subida de nivel: chime, popup `LEVEL N` y sacudida corta. Solo al subir; un reset a nivel 1 no suena a recompensa.
- Absorber blocker: whoosh, estallido grande y sacudida.
- Sacudida vía `Humanoid.CameraOffset`, que no pelea con los scripts de cámara de Roblox y se restaura sola.
- Un único `Heartbeat` **bajo demanda** mueve popups, devuelve partículas al pool y aplica la sacudida; se corta cuando no queda trabajo. Todo con pools de tamaño fijo configurable en `GameConfig.Feedback`.

Pruebas ejecutadas:

- Los cuatro `SoundId` cargan de verdad en este place: `PreloadAsync` OK, `IsLoaded = true`, duraciones 0.81 / 0.78 / 1.45 / 3.03 s.
- Pools construidos: 14 anclas, 24 sonidos, 8 emisores, 10 billboards.
- Racha de recogida, 310 muestras: pico de 3 popups y 3 sonidos simultáneos, muy por debajo de los topes (10 y 6).
- **Sin fugas:** 151 recogidas rápidas seguidas y el conteo de instancias en `FeedbackEffects` no se movió (71 → 71). Al parar: 0 popups encendidos, 0 sonidos sonando, `CameraOffset` exactamente `0, 0, 0`.
- Absorción del Toy Chest: sonido `Absorb` reproducido, pico de sacudida 0.678 studs (tope 0.9, con caída cuadrática) y `CameraOffset` de vuelta a cero.

**Causa raíz de las tarjetas en negro — 2026-08-05:**

El arreglo anterior (tarjetas en studs, `AlwaysOnTop = false`) redujo el problema pero no lo eliminó: seguían apareciendo tarjetas con el fondo dibujado y sin número. La causa real es otra.

- Diagnóstico: pintando cada familia de billboard de un color distinto se confirmó que la tarjeta muda **sí era de un objeto**. Identificada como `Collectible_40`, proyectada exactamente en el píxel del hueco negro, con `AbsoluteSize = 42×21` (o sea, con tamaño real en pantalla) pero **`TextBounds = 0,0`**.
- **Roblox mide el texto de un `BillboardGui` una sola vez.** Si lo dispone cuando el billboard todavía no tiene tamaño en pantalla —un objeto que aparece fuera de cámara, que es lo normal al reaparecer— se queda con medida cero y no vuelve a medir. El fondo sigue dibujándose; los dígitos no.
- Es la misma causa por la que el cartel del pedestal de Win salió mudo al construirlo a mano, y por la que clonar una plantilla ya usada lo "arreglaba": la plantilla ya venía medida.
- Arreglo: `ObjectLabelController.healLabel` comprueba por tick si una etiqueta tiene tamaño pero medida cero y reactiva `TextScaled`, lo que fuerza el reescalado. Cuesta dos lecturas de propiedad por objeto y por tick.

**Error cometido y corregido durante este arreglo:** el primer intento fue poner `TextWrapped = false`, ya que un número corto no necesita envolver. Salió peor: en Roblox `TextScaled` depende de `TextWrapped`, así que apagar el segundo **apagó el primero en silencio** en las 8 etiquetas del place, y todo el texto cayó al `TextSize = 8` de la plantilla, ilegible. Revertido y verificado que ambas quedan en `true`.

Verificado tras el arreglo:

- Escala del texto: ocupa el **99 %** de la altura de la tarjeta, mínima y mediana.
- 264 comprobaciones tras 14 ciclos de "recoger de espaldas y girar la cámara", que es el patrón que provoca el enganche: **0 tarjetas sin texto**.
- Barrido de 40 posiciones de cámara entre 12 y 60 studs y cuatro alturas: 0 tarjetas sin medir.

**Limpieza de iteraciones anteriores — 2026-08-05:**

Barrido de lo que dejaron de usar las iteraciones previas, comprobando referencia por referencia en vez de por intuición.

Retirado:

- **Modos de colocación `Markers` e `Hybrid`, con sus 36 marcadores `ItemSpawns`.** Nunca se usaron: las tres salas estuvieron siempre en `Procedural`. Fuera también `PlacementMode` (de `GameConfig`, del tipo `RoomSettings`, del lector y del `Configuration` de cada sala), el tag `ItemSpawn`, `ValidPlacementModes`, `DefaultPlacementMode`, y las funciones `readMarkerSlots` y `hideAuthoringMarkers`.
- Las tres carpetas `Zones/<Zone>/Collectibles`, vacías desde que el render pasó al cliente.
- `ServerScriptService.TempDiagnostics`, que ya cumplió su función.
- Tags sin ninguna referencia en código: `RouteGuide` y `ZoneGeometry`. Y la basura que deja el plugin Tag Editor (`data-testid=…`, `size-full`, `gui-object-defaults`, `TagEditorTagContainer`).

Total: 46 instancias y un modo entero del sistema.

Conservado a propósito, después de comprobarlo:

- **`Zones/Lobby`**, porque es donde está el `StartSpawn` (`-5, 1.5, 107`) y adonde vuelve el jugador al cobrar un pedestal. Borrarla dejaría al jugador cayendo al vacío.
- **`Zones/Lobby2`**, por decisión del usuario, reservada para la zona de descanso.
- **`ExitPreview`**, que parecía andamio pero es el umbral de color al Bedroom más su cartel `BEDROOM NEXT`. Sí tenía un defecto: `ExitFloor` estaba exactamente coplanar con el suelo del Bedroom (ambas caras superiores en `y = 1.0`) sobre 22×20 studs, es decir parpadeo por z-fighting. Subido 0.02 studs.

Verificado tras la limpieza: las tres salas siguen generando **24 objetos con separación mínima de 8.1 studs**, y la consola queda sin errores.

Pendiente de esta fase, no ejecutable desde la herramienta:

- **`Lighting.Technology` sigue en su valor anterior.** La propiedad requiere capacidad `RobloxScript` y el command bar no puede escribirla. Ponerla a `Future` a mano en el Explorer es el mayor salto visual que queda, y son cinco segundos.
- Escuchar los cuatro sonidos y ajustar a gusto: cada uno es una sola propiedad `SoundId` en `Assets/Feedback/Audio`.

**Notas de avance — 2026-08-05, jueves fase 2 (auditoría, rendimiento y Sticky Wraps):**

*Auditoría de scripts en assets importados — sale limpia sin tocar nada:*

- Barrido de todo el DataModel buscando `LuaSourceContainer` fuera de `ServerScriptService.Server`, `StarterPlayerScripts.Client` y `ReplicatedStorage.Shared`: **cero**. Ningún asset importado trae scripts.
- Tampoco hay `RemoteEvent`, `RemoteFunction`, `Tool`, `HopperBin` ni `Animation` sueltos en `Workspace`. Solo 24 `SurfaceGui` (los carteles authored) y 1 `Texture`.
- Peso total de geometría: **157 BaseParts** en todo el `Workspace`, de los cuales 86 están en `Lobby` + `Lobby2`. Las tres salas de juego suman 43.

*Prueba de rendimiento con la pila al máximo:*

| Escenario | Resultado |
|---|---|
| Pila vacía (línea base) | 60 FPS, media **16.66 ms**, peor frame 19.9 ms |
| Pila llena, quieto | 60 FPS, media **16.66 ms**, peor frame 19.2 ms |
| Pila llena, caminando | 60 FPS, media **16.67 ms**, peor frame 19.9 ms |

- Pila en el tope: **36 piezas / 47 partes / 0 sin soldar**, radio máximo 3.07 studs respecto al personaje.
- 24 objetos renderizados en la sala, 267 BaseParts en el `Workspace` del cliente.
- Conclusión: la pila llena **no tiene coste medible** frente a la pila vacía (0.01 ms de diferencia, dentro del ruido). Aviso honesto: esto es Studio en una máquina de desarrollo con el límite de 60 FPS. No sustituye una prueba en un móvil de gama baja, que sigue pendiente para el viernes.
- Nota metodológica: los dos primeros intentos de esta prueba no llegaron al tope (5 y 20 piezas) porque el bucle elegía objetos al azar y la mayoría eran inelegibles. Escribir en el atributo `Stickiness` desde el servidor no sirve: `ProgressionService` lo recalcula en el siguiente pickup. La medida válida es la tercera, filtrando por objetos elegibles, que es además lo que hace un jugador real: 58 intentos para llenar la pila.

*Sticky Wraps visibles:*

- El `+N` de cada recogida se pinta del **color del pegamento equipado**. Es lo único que hace que mejorar de wrap se sienta mientras juegas, en vez de cambiar una palabra gris del HUD. Verificado: BasicGlue blanco `0.94`, StrongGlue verde `0.36,1.00,0.54`, SuperGlue azul `0.31,0.64,1.00`.
- Al desbloquear un wrap sale un popup con su nombre en su color, más sonido y sacudida. Verificado: `STRONG GLUE!` verde y `SUPER GLUE!` azul.
- Los wraps se desbloquean en los niveles 1/5/10/15, es decir en el mismo instante que una subida de nivel. Dentro de `WrapOverridesLevelSeconds` solo se anuncia el wrap, que es la noticia grande; si no, sonaban dos veces y salían dos popups encima.
- Bajar de wrap (un reset devuelve a BasicGlue) no celebra nada: se compara `BaseGain` antes de anunciar.
- El nombre del wrap en el HUD va en su propio color, vía `RichText` sobre la etiqueta authored. Verificado con `TextBounds = 398, 16`, o sea que renderiza de verdad.

Queda del jueves, y es trabajo de arte más que de código:

- **Reemplazar los props por objetos temáticos de una sola pieza.** Hoy son primitivas greybox (`ToyBlock` un cubo, `ToyBall` una esfera). El sistema ya no necesita cambios: basta sustituir la geometría dentro de cada plantilla de `ReplicatedStorage/Assets/Collectibles` conservando el nombre y el `PrimaryPart`, y todo lo demás (colocación, pila, tarjetas) sigue funcionando.
- **Vestir las tres zonas.** La ruta no debe cambiar; el `PlacementArea` de cada sala define dónde pueden caer objetos, así que el mobiliario nuevo debe quedar fuera de ese volumen o los objetos aparecerán encima.

**Entregable del jueves:** alguien puede entender y disfrutar el juego sin explicación del creador.

### Viernes 7 — Playtest, cortes y publicación (8–10 h)

#### Mañana

- Implementar leaderboard global solo si no quedan bugs P0/P1.
- Crear icono y thumbnail centrados en la fantasía de una pila enorme.
- Revisar onboarding, móvil, audio, reset y reconexión.
- Publicar como no listado antes del playtest.

#### Playtest

- 6–8 personas; no explicarles la regla.
- Observar primer pickup, primer rechazo, cada blocker y decisión de replay.
- Preguntar solo al final: “¿qué estabas intentando hacer?” y “¿qué querías hacer después?”.
- Capturar tiempos y abandonos, no solo opiniones.

#### Tarde

- Arreglar únicamente fallos observados y valores de `GameConfig`.
- Repetir smoke test de punta a punta en móvil y PC.
- Pasar a público o dejar no listado si existe un bug que pierda datos, impida completar o rompa móvil.

**Entregable del viernes:** enlace jugable y una lista corta de aprendizajes medidos para la semana 2.

---

## 9. Prioridad de bugs y palancas de recorte

### Bloquean publicación

- No se puede recoger o absorber un blocker.
- Stickiness, Wins o Rebirth se pueden otorgar desde el cliente.
- Una vuelta no puede terminar.
- Los datos se pierden o duplican.
- El personaje queda inmóvil, sale disparado o la cámara queda tapada.
- La interfaz principal no se puede leer en móvil.

### Se arreglan si hay tiempo

- Un objeto visual queda ligeramente mal orientado.
- Una transición carece de animación especial.
- Falta variedad de props o audio.
- Un leaderboard tarda en actualizar.

### Cortar en este orden si hay retraso

1. Leaderboard global; conservar `leaderstats` local.
2. Rebirth visual elaborado; conservar botón y multiplicador.
3. Cosmic Glue como apariencia única; conservar su valor.
4. Dressing detallado de Kitchen.
5. Bedroom completa: fusionarla visualmente con Toy Room, pero mantener sus umbrales y blocker.

Nunca cortar:

- pickup automático;
- requisito rojo/verde;
- attachment visual;
- los tres blockers funcionales;
- vuelta completa y Win;
- HUD móvil;
- validación del servidor.

---

## 10. Checklist de “terminado”

### Funcional

- [ ] Un jugador nuevo recoge algo en menos de 10 s.
- [x] Todos los pickups validan requisito en servidor.
- [x] Los objetos reaparecen y nunca se agota una zona.
- [x] Los tres blockers abren su siguiente tramo.
- [x] Level y wrap cambian en los umbrales correctos.
- [x] Completar Kitchen otorga exactamente una Win.
- [ ] Rebirth reinicia la vuelta y conserva Wins.
- [ ] Salir y volver conserva Wins y Rebirths.

### Experiencia

- [ ] El blocker se ve desde el inicio de cada zona.
- [ ] Rojo/verde se comprende sin explicación.
- [ ] La pila crece sin tapar cámara ni movimiento.
- [ ] Cada pickup tiene respuesta visual y sonora inmediata.
- [ ] La vuelta inicial dura 3–5 min.
- [ ] Hay una razón visible para comenzar otra vuelta.

### Técnico

- [ ] Probado en móvil y desktop.
- [ ] Probado con 6 jugadores o simulación equivalente.
- [ ] No hay scripts desconocidos de Creator Store.
- [ ] No hay números de balance fuera de `GameConfig`.
- [ ] No hay remotes que acepten premios calculados por el cliente.
- [x] El límite de attachments se respeta al morir, salir y reiniciar.
- [ ] Analítica registra el embudo completo.

---

## 11. Primeras acciones de hoy

No comenzar buscando assets. El orden exacto es:

1. Crear `GameConfig` con los números de las secciones 3 y 4.
2. Hacer Toy Room con piso, spawn, 12 puntos y Toy Chest.
3. Conseguir que un cubo con requisito 0 otorgue +1 y se pegue.
4. Añadir label rojo/verde.
5. Añadir respawn de 2 s.
6. Repetir hasta Stickiness 50 y absorber Toy Chest.
7. Solo después, mejorar el aspecto del pegado.

La primera prueba útil de hoy no es “¿se ve bonito?”, sino:

> ¿Puedo pasar 60 segundos tocando cubos y sentir que mi personaje se convierte en una pila cada vez más absurda?

---

## 12. Decisiones provisionales por confirmar

Estas decisiones no bloquean el trabajo de hoy:

1. **Tres zonas en lugar de cuatro.** Neighborhood queda para semana 2; es el recorte que protege la calidad del loop.
2. **Wraps automáticos.** Se desbloquea y equipa el más fuerte por nivel; una selección manual implicaría inventario y UI.
3. **Sin obstáculos adicionales.** Los blockers son los obstáculos del MVP. Un hazard que empuje o quite objetos contradice la experiencia de una sola acción.
4. **Finish / Rest Zone sin AFK.** Sirve como cierre y replay, no como economía pasiva.
5. **Stickiness como único término.** Se elimina “Size” del HUD y de los criterios para no enseñar dos palabras para la misma progresión.

Si se cambia alguna de estas decisiones, debe hacerse antes del martes al mediodía; después de ese punto solo se ajustan configuración, contenido y presentación.

---

## 13. Semana 2, si el prototipo valida

1. Neighborhood como cuarta zona y landmark final.
2. Sticky Collection de objetos únicos absorbidos.
3. Selección manual y cosméticos de Sticky Wraps.
4. Más capas de Rebirth y balance de largo plazo.
5. Leaderboards adicionales: mejor tiempo, mayor Stickiness, más Rebirths.
6. Monetización coherente con el loop, sin interrumpir el movimiento.
7. Experimentos de retención basados en el embudo real, no en suposiciones.

**Regla final:** cualquier feature nueva debe hacer más claro o más satisfactorio el ciclo tocar → pegar → crecer → absorber. Si lo interrumpe, espera.

---

## 14. Registro — 2026-08-06, Rebirth con pantalla propia

### Construido

- **Botón `RebirthOpenButton` en el HUD** con `ReadyBadge`: un punto verde que se enciende solo cuando el Rebirth está disponible. Abre la pantalla en cualquier momento de la partida.
- **`RebirthScreen` authored** en `StarterGui.StickyHUD`: modal con fondo atenuado, título, X de cierre, comparación *Before → After* de multiplicador y level cap, aviso de reset, barra de progreso hacia el nivel requerido, botón de Rebirth y línea de mensaje. Toda la jerarquía es editable desde Explorer; el código solo la enlaza.
- **`RebirthController`** (cliente): dueño de la pantalla y del remote. No concede nada; lee atributos replicados, pide al servidor y pinta la respuesta. `HUDController` soltó el panel viejo y conserva solo el aviso de la línea de feedback.
- **`GameConfig.LevelExtension`**: los 20 umbrales afinados a mano se conservan y los niveles 21–100 se generan al cargar el módulo continuando el último salto con un crecimiento del 10 %.
- **Level cap por fórmula**: `GameConfig.GetLevelCap` = `BaseLevelCap + rebirths × LevelCapPerRebirth`, con `LevelCapOverrides` para excepciones a mano. Devuelve `nil` si el techo cae fuera de los niveles generados, y `GameConfig.GetMaximumRebirth()` sustituye al viejo `MaximumImplementedRebirth` en `ProgressionService` y `DataService`.
- **Requisito alineado con el diseño**: `FinishService.requestRebirth` dejó de exigir `RunCompleted`. Se añadió `GameConfig.Rebirth.RequestDebounceSeconds` porque el botón ya está disponible durante toda la partida.

### Probado en Studio

| Prueba | Resultado |
| --- | --- |
| Enlace de la plantilla authored | Los cuatro hijos del HUD presentes; pantalla arranca oculta |
| Rechazo en Level 1 | `Denied / LevelRequired`; `Rebirths`, `Stickiness` y `Level` sin mutar |
| Objeto por encima del requisito | Pickup rechazado (objeto de 25 con Stickiness 0) |
| Ruta real hasta el cap | 88 pickups reales → `503 / Level 20 / CosmicGlue`, con `RunCompleted = false` |
| Abrir con el botón del HUD | Clic real de ratón → `RebirthScreen.Visible = true` |
| Rebirth 0 → 1 con el botón real | `Rebirths 1`, `2.0x`… ver fila siguiente; Stickiness 0, Level 1, wrap `BasicGlue`, Wins intactas, zona `ToyRoom`, pila 0 piezas, teleport al inicio, modal cerrado |
| Multiplicador aplicado | Primer pickup real posterior otorgó exactamente `+1.50` |
| Rebirth 1 → 2 (antes imposible) | 71 pickups → Level 25 → `Rebirths 2`, multiplicador `2.0x`, cap nuevo 30 |
| Persistencia | `DataLastSavedRebirths = 2`; el clamp viejo de 1 ya no lo recorta |
| Anti-spam del remote | 10 peticiones seguidas → 1 sola respuesta; `Rebirths` sin cambios |
| Cierre con la X | Clic real → `RebirthScreen.Visible = false` |
| Teardown | Studio volvió a Edit sin errores ni warnings propios |

### Pendiente explícito

- ~~**Wins tras Rebirth** con valor distinto de cero~~ — comprobado el 2026-08-06: `Wins 1` conservada a través del Rebirth.
- **Balance de los niveles 21+**: la curva generada es mecánica, no diseñada. El nivel 100 pide ~1.25 M de Stickiness. Sirve para que el Rebirth sea repetible; hay que afinarla con playtests.

### Corrección del mismo día — el Level ya no cae al reiniciar la vuelta

El Level no se guardaba, se derivaba de la Stickiness, así que cobrar en un pedestal lo devolvía a 1. Ahora es la marca más alta del ciclo de Rebirth: `ResetRun` solo toca la Stickiness y la zona, y únicamente `TryRebirth` devuelve Level y Wrap al principio. El Sticky Wrap se conserva con él, así que cada vuelta posterior arranca más rápida.

| Prueba | Resultado |
| --- | --- |
| Pedestal de 1 Win real, tras absorber el Toy Chest | `Stickiness 183 → 0`, `Level 12` intacto, `SuperGlue` intacto, `Wins 0 → 1`, teleport al inicio, zona `ToyRoom` |
| Wrap conservado de verdad | Primer pickup posterior otorgó `+8`, no `+1` |
| El Level sigue subiendo | 12 → 14 en la vuelta siguiente, sin reiniciar la cuenta |
| Muerte y respawn | `Level 14` y `SuperGlue` conservados; Stickiness a 0 |
| Rebirth con `Level 20` | `Level 1` y `BasicGlue`, `Wins 1` conservada, multiplicador `1.5x` |

**Consecuencia de diseño a tener presente:** como la Stickiness sí vuelve a 0, subir de nivel exige alcanzar el umbral dentro de una misma vuelta. Cobrar a mitad de camino no acumula hacia niveles altos; lo que deja es velocidad. Es lo que convierte el pedestal en una decisión.

---

## 15. Registro — 2026-08-06, Sticky Wraps comprables con Wins

### Corrección de fondo

El código desbloqueaba los wraps por nivel (`UnlockLevel` 1/5/10/15) y equipaba siempre el más fuerte. El documento de diseño dice lo contrario: **"Wins are used to unlock Sticky Wraps"** y **"The equipped Sticky Wrap determines how much Stickiness the player gains"**. Con el modelo viejo no había nada que equipar y las Wins no se gastaban en nada.

### Construido

- **`Basic Glue` de fábrica**, los otros tres se compran con Wins: `Strong 3`, `Super 10`, `Cosmic 25`. Precios en `GameConfig.StickyWraps.WinCost`.
- **Equipado manual.** La ganancia por objeto sale del wrap equipado, no del nivel. Comprar equipa (`GameConfig.Wraps.EquipOnPurchase`).
- **`WrapService`** atiende el remote: valida la forma de la petición y frena el spam. Las reglas (`TryBuyWrap`, `TryEquipWrap`) viven en `ProgressionService`.
- **Persistencia:** el perfil guarda `OwnedWrapIds` y `EquippedWrapId`. La compra fuerza guardado inmediato porque gasta moneda persistente.
- **El Rebirth borra lo comprado** y conserva las Wins, como pide el `.md`.
- **UI authored:** `WrapOpenButton` en el HUD (con punto que se enciende al poder comprar algo) y `WrapScreen` con lista desplazable. Las filas se clonan de la plantilla `_WrapRow`, así que añadir un pegamento es tocar `GameConfig`, no la pantalla.
- Se retiraron `GameConfig.GetStrongestWrap` y `UnlockLevel`; entraron `GetDefaultWrap`, `IsDefaultWrap` y `GameConfig.Wraps`.

### Probado en Studio

| Prueba | Resultado |
| --- | --- |
| Enlace y construcción de filas | Cuatro filas con nombre, ganancia, color y precio correctos |
| El nivel ya no regala wraps | 80 recogidas de Level 5 → 8 dieron `+1` siempre; antes el nivel habría subido a Strong Glue |
| Compra con clic real | `Wins 3 → 0`, `StrongGlue` comprado y equipado, guardado inmediato (`DataLastSavedWraps = BasicGlue,StrongGlue`) |
| La ganancia cambia de verdad | `+3.00` con Strong Glue equipado |
| Equipar a mano | Volver a Basic Glue devolvió `+1.00`; reequipar Strong volvió a `+3.00` |
| Comprar sin Wins | `Denied / NotEnoughWins`, estado intacto |
| Comprar algo ya comprado | `Denied / AlreadyOwned` |
| Comprar el de fábrica | `Denied / AlreadyOwned` |
| Equipar algo no comprado | `Denied / NotOwned` |
| Id inventado (`DiamondGlue`) | `Denied / UnknownWrap` |
| Acción inválida y payload basura | Ignorados sin respuesta ni cambio de estado |
| Rebirth borra lo comprado | `Owned BasicGlue,StrongGlue → BasicGlue`, equipado a `BasicGlue`, `Wins 3` conservadas, la tienda se actualizó sola |
| Teardown | Studio volvió a Edit sin errores ni warnings propios |

### Pendiente explícito

- **Ida y vuelta de los wraps persistidos sin verificar.** El mock de DataStore de Studio vive en el VM del servidor y muere al salir de Play, así que no se puede probar reconectando. La escritura sí está verificada. Falta repetir la prueba cloud con almacén aislado, igual que se hizo con Wins/Rebirths.
- **Cambio visual del recubrimiento.** El `.md` pide que los wraps "visibly change the player's sticky coating, material, or attachment effect". Hoy el wrap solo se distingue por color en el HUD, en el `+N` y en la tienda. Es trabajo de arte y no entró aquí.
- **Precios sin playtest.** 3 / 10 / 25 es una escala de arranque elegida contra los pedestales de 1 / 3 / 10. Vive en `GameConfig`.

---

## 16. Revisión — 2026-08-06, el `.md` añade Trails y Auras

Revisión del documento actualizado contra lo implementado. **No se implementaron Trails ni Auras**; solo se corrigió lo que el documento ya obliga y se dejó preparado el punto de enganche.

### Lo que cambió de verdad: la fórmula de ganancia

Antes el documento definía la ganancia como un solo multiplicador:

```
Stickiness Gain = Wrap Base Gain × (1 + Rebirths × 0.5)
```

Ahora define una composición de tres capas, y el orden importa:

```
Stickiness Gain = Wrap Base Gain × [1 + (Rebirths × 0.5) + Trail Addition] × Aura Multiplier
```

- El **Trail suma** al multiplicador base; no se multiplica aparte.
- El **Aura multiplica** el resultado ya combinado.

Es la parte fácil de implementar mal, así que la fórmula entera se movió a `GameConfig.GetStickinessGain` y `GameConfig.GetBaseMultiplier`. `ProgressionService` ya no calcula la multiplicación a mano.

### Lo que siguió igual

Base de Sticky Wraps (ganancias +1/+3/+8/+20), Rebirth (`+0.5x`, resetea Stickiness, Level y wraps, sube el techo), Level (lo llena la Stickiness, sin XP aparte), pedestales de Wins (1/3/10) y el hecho de que las Wins no se resetean. Nada de eso obligó a tocar código.

### Corregido

- **Cosmic Glue: 25 → 30 Wins.** El documento ahora fija los precios (`0 / 3 / 10 / 30`) y el 25 era una elección mía anterior.
- Nuevo atributo replicado `StickinessMultiplier`: el multiplicador efectivo del jugador. Hoy coincide con el del Rebirth; con Trails y Auras dejará de coincidir, y la UI debe leerlo en vez de recalcular la fórmula por su cuenta.

### Preparado para Trails y Auras

`ProgressionService` tiene dos funciones `getTrailAddition(state)` y `getAuraMultiplier(state)` que hoy devuelven el valor neutro de cada uno (`0` y `1`). Son el único punto que hay que cambiar en el cálculo. Para implementar Trails/Auras haría falta, siguiendo el patrón ya montado con los Wraps:

1. `GameConfig.Trails` y `GameConfig.Auras` con id, aporte, bonus de velocidad, radio de recogida, precio y color.
2. `OwnedTrailIds` / `OwnedAuraIds` y equipados en `PlayerState` y en el perfil de `DataService`, con su normalización contra el catálogo.
3. `TryBuyTrail` / `TryEquipTrail` y equivalentes de Aura en `ProgressionService`, clonando la forma de `TryBuyWrap`.
4. Un servicio de remote por tienda, o generalizar `WrapService` a un `CosmeticShopService` con la categoría en el payload.
5. Pantallas nuevas reutilizando `_WrapRow` y el patrón de `WrapController`.
6. **Efectos que no toca la fórmula:** el bonus de velocidad va sobre `Humanoid.WalkSpeed` y el de radio sobre `GameConfig.Collection.PickupRadius`, que hoy es una constante global. Ese radio se valida en servidor (`PickupValidationSlack`), así que hacerlo por jugador exige tocar también la validación de `PickupService`.

### Verificado

| Prueba | Resultado |
| --- | --- |
| Ejemplo textual del `.md` (Strong Glue, Rebirth 2, Blue Trail, Blue Aura) | `Base = 4.5`, `Gain = 27.0`, exactamente lo que dice el documento |
| Sin Trail ni Aura, la ganancia no cambia | Idéntica a la fórmula anterior en 6 combinaciones de rebirth y wrap |
| Pickup real | `+1.00` con Basic Glue en Rebirth 0 |
| Precio nuevo en la tienda | Cosmic Glue muestra `🏆 30` |
| Teardown | Consola limpia, Studio de vuelta en Edit |

### Conflicto pendiente de decisión

El documento cambió **cómo se compran los Sticky Wraps**: ahora dice que se compran "*stepping into the respective plate inside the lobby*", y que cambiar de wrap es volver a pisar otra placa. Lo implementado es un botón en el HUD con pantalla. Trails y Auras sí se describen explícitamente como botón en el HUD.

Las reglas de compra y equipado ya viven en `ProgressionService.TryBuyWrap` / `TryEquipWrap`, así que unas placas serían otro llamador de la misma API — el trabajo es el servicio de placas y los modelos authored, no la lógica. Falta decidir si las placas sustituyen a la pantalla o conviven con ella.

---

## 17. Registro — 2026-08-06, placas de Sticky Wrap en el lobby

### Construido

- **Ocho placas en `Zones/Lobby/Geometry`**, identificadas por su firma `7×1×7` en color `(255,176,0)`. Renombradas a `WrapPad_<WrapId>`, tagueadas `WrapPad` y con attribute `WrapId`. Fila baja (`x=-50`) = tiers 1–4, fila alta (`x=-68`) = tiers 5–8, así la escalera sube al subir el escalón. **`Lobby2` quedó intacto.**
- **`WrapPadService`**: pisar una placa pide ese wrap. Valida contacto con `PlayerCharacterUtil`, aplica debounce por jugador y relee el `WrapId` del atributo en cada toque, para que reasignar una placa a mano en Studio no exija tocar código.
- **`ProgressionService.RequestWrap`**: punto de entrada único — compra si no lo tienes, equipa si ya lo tienes. Lo usan la placa y la pantalla del HUD, así que no pueden divergir y el cliente ya no decide qué operación toca. Devuelve cuántas Wins faltan.
- **`WrapPadController`**: clona el cartel authored `Assets/LobbyUI/_WrapPadSign` sobre cada placa y lo pinta con el estado del jugador. La placa equipada se pone verde, la comprable conserva su amarillo y la que no puedes pagar se atenúa. Todo local: "comprado" y "equipado" son estado por jugador.
- **Cuatro Sticky Wraps nuevos** para llenar las ocho placas: Quantum `+50`/75, Nova `+120`/150, Galaxy `+300`/300, Infinity `+750`/600. Los cuatro del documento no se tocaron.
- **Pasada de gratificación** en `FeedbackController`: comprar dispara sonido de absorción, ráfaga grande, sacudida y popup `<NOMBRE> UNLOCKED!` en el color del wrap; equipar dispara sonido de subida, ráfaga y popup con el nombre; no poder pagar dispara el sonido de rechazo y el popup `NEED N MORE WINS`.

### Balance de los cuatro nuevos

Ganancia `1 → 3 → 8 → 20 → 50 → 120 → 300 → 750`: cada peldaño multiplica por ~2,5, la misma pendiente que ya traían los cuatro del documento. Precio `0 → 3 → 10 → 30 → 75 → 150 → 300 → 600`: cada uno cuesta el doble que el anterior, o sea lo mismo que todo lo comprado hasta ese punto. La eficiencia (ganancia por Win) queda casi plana y sube un poco en los últimos, lo que premia ahorrar.

### Probado en Studio

| Prueba | Resultado |
| --- | --- |
| Descubrimiento y carteles | 8 placas tagueadas, las 8 con su cartel, nombre, ganancia y precio correctos |
| Solo el `Lobby` | `Lobby=8`, `Lobby2=0`, fuera `0` |
| Pisar sin Wins | `Denied / NotEnoughWins / MissingWins=3`, estado intacto |
| Compra pisando la placa | `Wins 3 → 0`, `StrongGlue` comprado y equipado, cartel a `EQUIPPED`, placa en verde |
| Equipar uno ya comprado | Pisar la placa de Basic Glue lo equipó |
| La ganancia cambia de verdad | `+1.00` con Basic Glue; tras pisar la placa de Strong Glue, `+3.00` |
| Gratificación de equipado | Popup `BASIC GLUE` + sonido `LevelUp` observados en vivo |
| Gratificación de rechazo | Popup `NEED 10 MORE WINS` + sonido `Denied` observados en vivo |
| Rebirth borra lo comprado | `owned` vuelve a `BasicGlue`, las 8 placas vuelven a mostrar su precio sin recargar |
| Pantalla del HUD | Lista los 8 wraps y sigue funcionando con el contrato nuevo |
| Teardown | Consola limpia, Studio de vuelta en Edit |

### Notas y pendientes

- **La pantalla del HUD se conservó.** El documento solo describe placas para los Wraps, pero la pantalla ya estaba construida y probada, sirve de catálogo con precios y es el patrón que reutilizarán Trails y Auras. Se quita en un minuto si estorba.
- **`Touched` no dispara si el jugador aparece encima de la placa sin moverse.** Se detectó teletransportando el personaje justo sobre ella: hay que caer o caminar encima. Un jugador real siempre entra caminando, y las Wins no se ganan dentro del lobby, así que no se llega a dar el caso de estar parado encima cuando cambia lo que puedes pagar. Queda anotado por si aparece.
- **Precios sin playtest.** Con los pedestales dando 1/3/10, el tope de ingreso por vuelta es 10 Wins, así que Infinity Glue son ~60 vueltas. Las vueltas se acortan mucho al subir de wrap, pero el ingreso por vuelta no escala. Si se quiere una escalera más corta, o suben los pedestales o bajan los precios altos.
- **Cambio visual del recubrimiento**: sigue pendiente. El wrap se distingue por color en el HUD, en el `+N`, en la tienda y ahora en la placa, pero el personaje no cambia de aspecto.

---

## 18. Registro — 2026-08-06, regla de autoría y Stickiness solo por Rebirth

### 1. Regla dura: si es fijo, se crea en el editor

Nueva sección **5.1 de `AGENTS.md`**. Todo lo que el jugador ve —UI o mundo— y existe en cantidad fija y conocida debe estar creado a mano en el DataModel; el código no lo instancia en runtime.

Que el contenido sea distinto por jugador **no** justifica crearlo por código: las escrituras del cliente sobre el Workspace son locales, así que una instancia authored compartida puede mostrar a cada jugador su propio texto y color. Ése fue el error con los carteles de las placas.

**Corregido:** los 8 `WrapSign` pasaron de clonarse en runtime a ser hijos authored de cada placa en `Zones/Lobby/Geometry`. Se borró la plantilla `Assets/LobbyUI/_WrapPadSign`. `WrapPadController` ahora localiza el cartel, valida su contrato, avisa si falta y solo escribe texto y color; tamaño, offset, fuente y layout son del editor.

### 2. La Stickiness solo se pierde con el Rebirth

Cobrar en un pedestal ya no la reinicia, ni morir, ni el ReplayPad. `ProgressionService.ResetRun` dejó de tocar el progreso y solo reposiciona la zona lógica.

Lo que sí se sigue reiniciando cada vuelta son los blockers: los atributos `CompletedZone_*` autorizan el cobro, así que sin ese reinicio se podría cobrar el mismo pedestal en bucle.

### Probado en Studio

| Prueba | Resultado |
| --- | --- |
| Un solo billboard por placa, y es el authored | 8/8 con `WrapSign`, ninguno duplicado en runtime |
| Los carteles sobreviven a salir de Play | Presentes en Edit con su `Size` y `StudsOffsetWorldSpace` editables |
| Textos correctos por placa | Nombre, ganancia y precio de los 8 wraps |
| Cobrar un pedestal conserva la Stickiness | `190 → 190`, `Level 12` intacto, `Wins 0 → 3`, teleport al inicio |
| No se puede cobrar en bucle | 3 intentos sin rehacer la ruta → `Wins` sin cambios; rehaciéndola → `+3` |
| Morir conserva la Stickiness | `190 → 190` |
| El Rebirth sí la reinicia | `500 → 0`, `Level 20 → 1`, `Wins 6` conservadas, multiplicador `1.5x` |
| Teardown | Consola limpia, Studio de vuelta en Edit |

### Pendiente señalado

La Stickiness y el Level **siguen sin persistir entre sesiones**: `initializePlayer` los arranca en `0` y `1`. Con la regla nueva de "solo el Rebirth resetea", salir y volver a entrar es hoy la única forma de perderlos sin renacer. Si diseño quiere coherencia total hay que añadirlos al perfil de `DataService`.

---

## 19. Registro — 2026-08-06, HUD central de Stickiness, nivel y multiplicador

El panel de arriba a la izquierda (`ProgressPanel`) daba la información pero no se leía como un simulador. Se sustituyó por un bloque central abajo, calcado en forma y color a la referencia que pidió diseño.

### Qué se construyó

Todo authored en `StarterGui.StickyHUD`, creado desde el editor y editable a mano:

- **`StatsPanel`** (centro-abajo): `BlockerProgress` (línea del blocker de la zona), `Stickiness` (número grande abreviado), `WrapLabel` (pegamento equipado en su color, con su `+N`), `MultiplierLabel` (`x1.5 Stickiness (Rebirths)`), `LevelBar` (`Fill` + `LevelText` + `AmountText`) y `BoostRow` con 4 botones placeholder.
- **`CounterStack`** (arriba-izquierda): `RebirthCounter` y `WinsCounter`, cada uno con `Icon` (ImageLabel vacío, listo para arrastrarle un asset) y `Amount`.
- `ProgressPanel` borrado. `HUDController` solo localiza, valida y escribe texto, color y el `Size` del relleno de la barra.

### Reglas respetadas

- **Cero offsets.** Todo `Size` y `Position` del bloque nuevo va en Scale puro; verificado por script sobre todos los descendientes. Donde hacía falta forma fija (iconos circulares, badges) se usó `UIAspectRatioConstraint`, que no introduce píxeles.
- **Autoría (5.1).** Las instancias son de cantidad fija y conocida, así que están creadas una por una en el DataModel. El código no instancia nada en runtime.
- **La UI lee `StickinessMultiplier`**, no recalcula la fórmula. En cuanto existan Trails y Auras el número seguirá siendo correcto sin tocar el HUD.

### Probado en Studio

| Prueba | Resultado |
| --- | --- |
| Enlace de las 11 referencias authored | Sin errores; consola limpia al arrancar |
| Recogida real (ruta física, 24 objetos en Toy Room) | `Stickiness 0 → 7`, `Level 1 → 2` |
| Barra dentro del nivel actual | `Level 2`, `2/7`, relleno `0.286` — el tramo se mide contra el nivel, no contra el total |
| Barra a mitad de un nivel alto | `Level 32`, `96/191`, relleno `0.503` |
| Abreviatura de números | `14100 → "14.1K"`, `1900 → "1.9K"`, `7 → "7"` |
| Blocker, wrap y multiplicador | `TOY CHEST 7 / 50`, `Basic Glue (+1)` en su color, `x1.0 Stickiness (Rebirths)` |
| Contadores | `Wins 0`, `Rebirths 0`; icono cuadrado exacto (`61.32 × 61.32`) |
| Colisiones de layout | 0 solapes entre `StatsPanel`, `CounterStack`, los dos botones y `PickupFeedback` |
| Teardown | Consola limpia, Studio de vuelta en Edit |

### Correcciones que salieron de la prueba

- `CounterStack` pisaba `RebirthOpenButton` y `WrapOpenButton`. Los dos botones bajaron debajo de la pila y **pasaron de Offset a Scale**, así que en móvil ya no se quedan clavados en píxeles.
- `PickupFeedback` caía justo encima del número grande de Stickiness. Subió a `0.6` de altura, por encima del panel.

### Pendiente señalado

- Los 4 botones de `BoostRow` son **placeholder visual**: no tienen dev product detrás ni `Activated` conectado. Los precios (`14/45/225/449`) son texto de ejemplo.
- Los `Icon` de los contadores son `ImageLabel` con `Image` vacío sobre un círculo de color. Falta arte: basta arrastrar el asset en Studio, sin tocar código.
- No se pudo tomar captura de pantalla (la herramienta agota el tiempo de espera); la verificación visual quedó en medidas numéricas. Falta una revisión a ojo en el emulador de dispositivos.

---

## 20. Registro — 2026-08-12, auditoría MCP y plan de performance v2

### Alcance

Se auditó mediante Roblox Studio MCP el lugar `Exposición pegajosa`
(`PlaceId 95828455414780`) y se contrastó la implementación viva con
`PLAN_PERFORMANCE.md`, `PLAN_PER_PLAYER_OBJECTS.md`, `PROJECT_MEMORY.md` y este tablero.
No se modificaron scripts ni el DataModel: esta fase fue de diagnóstico y decisión.

### Verificado

- [x] Studio activo y PlaceId correctos; Play inició y terminó por MCP.
- [x] Arranque de servidor y cliente sin errores; solo permanece el warning conocido de
  ProductId placeholder de Rest Zones.
- [x] Configuración efectiva: `MaxVisualAttachments=36` temporal, `PoolCapacity=400`,
  `TargetMaxSizeStuds=1.6`, `StreamingEnabled=true`.
- [x] Los collectibles del suelo son locales, anclados y sin collide/touch/query; 24 cargados
  en Toy Room durante el smoke.
- [x] La pila adherida sigue siendo server-side: una `WeldConstraint` al torso por cada
  `BasePart`, con `Massless`, collide/touch/query y sombras apagados.
- [x] Nueve plantillas actuales inspeccionadas: ocho de una parte y `ToyCar` de dos.
- [x] Limpieza y ownership de conexiones inspeccionados en `CharacterRemoving`,
  `PlayerRemoving` y `Destroy`.
- [x] Se corrigió en `PLAN_PERFORMANCE.md` la extrapolación aritmética de física y se añadió un
  plan priorizado con quick wins, arquitectura condicional, réplica/memoria y gates.

### Smoke de esta auditoría

| Prueba | Resultado |
| --- | --- |
| Identidad del lugar | `PlaceId 95828455414780`, correcto |
| Estado inicial | 1 jugador, pila 0, 24 collectibles locales |
| Física baseline cliente | `PhysicsStepTimeMs≈0.064`, 367 primitives, 20 moving |
| Física baseline servidor | `PhysicsStepTimeMs≈0.015`, 321 primitives, 18 moving |
| Join baseline | 29.109 bytes de instancia/terrain |
| SceneAnalysis cliente | audio `≈5,25 MB`, animación `≈139 KB`, 11 instancias sin parent |
| SceneAnalysis servidor | 7 instancias sin parent, todas BindableEvents pequeños/persistentes |
| Memoria de scripts | no disponible por flag Studio `STUDIOPLAT37936` |
| Consola | servicios inicializados; sin errores de runtime |
| Teardown | Studio volvió a Edit |

Este smoke valida inicialización y limpieza básica, **no** capacidad móvil.

### Bloqueantes antes de cerrar performance

- [ ] Matriz `1/4/8 jugadores × 0/36/110/300 visuales` en móvil low/mid real.
- [ ] Proxies authored de exactamente una parte y presupuesto de arte representativo.
- [ ] `ClearPlayerVisuals` amortizado y probado en pedestal, muerte, Replay y Rebirth, también
  durante una recogida concurrente.
- [ ] Late join con siete pilas llenas, fill simultáneo y clear simultáneo.
- [ ] Dumps MicroProfiler cliente móvil y servidor para steady, fill, clear y join.
- [ ] Camino exitoso, requisito/distancia/rate limit y limpieza con 2 y 8 jugadores.
- [ ] Diez ciclos fill/clear/respawn sin pendiente creciente de memoria o instancias.

**Decisión vigente:** conservar `300` como capacidad lógica, probar primero un presupuesto visual
de `110` proxies de una parte `[PLACEHOLDER]`, y no restaurar 300 visuales en producción hasta
pasar los gates definidos en `PLAN_PERFORMANCE.md`.

---

## 21. Registro — 2026-08-13, render local mobile-first implementado

### Alcance

Se implementó en el DataModel abierto la Fase B de `PLAN_PERFORMANCE.md`: el servidor conserva
hasta 300 attachments lógicos por jugador y cada cliente materializa una cantidad acotada de
proxies cosméticos. La presentación local no concede Stickiness, premios, blockers ni progreso.

### Implementado

- [x] 29 `AttachmentProxies` authored (9 collectibles y 20 blockers de dos mundos), exactamente
  una `BasePart` por proxy, IDs únicos y sin collide/touch/query/sombra.
- [x] `AttachmentProxyTemplates` valida el contrato y falla de forma explícita; no crea arte de
  fallback por código.
- [x] `AttachmentService` guarda capacidad lógica 300, generations/sequences y deltas/snapshots;
  el servidor dejó de crear `StickyPile`, parts o welds cosméticos.
- [x] `AttachmentRenderer` usa budgets `110` propios, `20` remotos y cap creado `320`
  `[PLACEHOLDER hasta Android]`, LOD por distancia y pool client-local.
- [x] Clear lógico atómico y liberación visual amortizada (`16` records o `1 ms` por frame), con
  estado de release exactamente una vez.
- [x] Sensor sin tabla `candidates` por tick; distancias al cuadrado.
- [x] Labels event-driven, heal acotado a 8 por frame, culling a 42 studs y `_FocusHighlight`
  authored.
- [x] Marcadores `AttachmentServer.Flush/Snapshot`, `AttachmentRenderer.Reconcile/Animate/Release`,
  `CollectibleSensor` y `ObjectLabels`.

### Pruebas proporcionales ejecutadas por Roblox Studio MCP

| Prueba | Resultado |
| --- | --- |
| Arranque y snapshot | PASS; `SnapshotReady=true`, conteos 0, consola sin error del sistema |
| Pickup real | PASS; ToyBlock id 8, logical/legacy `0→1`, 1 proxy cliente |
| Rechazo inválido | PASS; `-999999`, string y `NaN` no cambiaron Stickiness ni pila |
| Muerte/respawn | PASS; logical/active/metadata/pending volvieron a 0 |
| Pickup tras respawn | PASS; el proxy se reutilizó sin incrementar `Created` |
| Stress de creación | PASS; 300 deltas a ~96/s quedaron en 110 active/metadata |
| Física del proxy | PASS; 110 parts, 110 welds, 0 anchored y 0 flags inseguros |
| Aislamiento servidor | PASS; 0 `StickyPile`, proxy parts o attachment welds server-side |
| Clear + mensaje stale | PASS; generación vieja ignorada y vigente aceptada |
| 10 + 50 fill/clear | PASS tras corregir double-release; cola final 0, sin crecimiento |
| Pool warm | PASS; fill final 110 active/created, cap 320 respetado |
| Consola final | PASS; sin stack/error de attachment; warnings conocidos ajenos |
| Teardown | PASS; Studio en Edit y PlaceId `95828455414780` |

### Bug encontrado y corregido durante la prueba

Los ciclos comprimidos reprodujeron un double-release: un batch viejo retenía un record que ya
había vuelto al pool y había sido readquirido. Se añadió el ciclo de vida
`Active → Queued → Pooled/Destroyed`, borrado de la referencia antes de liberar e idempotencia en
release/destroy. La corrección pasó 60 ciclos adicionales y respawn.

### Pendiente antes de publicación/certificación móvil

- [ ] Guardar y publicar manualmente el Place. El MCP no dispone de Save/Publish y Team Create
  devolvió 503; esta sesión dejó los cambios solo en el DataModel abierto.
- [ ] Prueba real con 2 y 8 clientes, incluyendo late join, salida del owner y siete pilas remotas.
- [ ] Android low-end y móvil mid-end con thermal soak y dumps MicroProfiler.
- [ ] Registrar p50/p95/p99 de frame/physics, memoria y red en empty/fill/steady/clear/join.
- [ ] Probar pedestal, Replay y Rebirth, incluido pickup concurrente durante clear.
- [ ] Sustituir `[PLACEHOLDER]` de budgets solo con evidencia de dispositivo.

**Estado:** implementación y suite de un cliente aprobadas; no guardada/publicada y no certificada
para `8 × 300` en Android.

---

## 22. Registro — 2026-08-26, feedback de avatar en Rest Zones

> **Histórico sustituido:** la variante con hebras `Beam` se reemplazó el mismo día por
> **Sticky Snap**, documentado en la sección 23.

### Decisión e implementación

Se implementó la primera versión del concepto **Sticky Pull**: mientras el jugador permanece en
una Rest Zone válida, reproduce un gesto R15 de amasar/atraer pegamento hacia el pecho y muestra
dos hebras cortas desde las manos. Cada concesión real de Stickiness lleva la pose al punto de
contacto y ensancha brevemente las hebras, de modo que el feedback coincide con el tick validado
por servidor y no con una simulación visual independiente.

- `ReplicatedStorage.Assets.RestZone.StickyPullR15` es una `KeyframeSequence` authored y editable.
- `ReplicatedStorage.Assets.RestZone.StickyStrand` es la plantilla authored de `Beam`; en runtime
  solo se clonan dos instancias transitorias por personaje.
- `RestZoneAvatarController` es presentación exclusivamente cliente y observa el atributo
  replicado `RestZoneId` y el evento existente `RestFeedback`.
- La duración, fade, pulso, escala y nombres de assets viven en `GameConfig.RestZones.Presentation`.
- No se añadieron remotos, progreso cliente, partes físicas, polling por frame ni texto visible.
- R6, assets ausentes, zona vacía/inválida, cambios rápidos, muerte, respawn y `Destroy` tienen
  salidas explícitas y limpieza. La pista se carga una vez por personaje y se reutiliza.

### Pruebas en Studio

| Caso | Resultado |
| --- | --- |
| RestZone1 desbloqueada | PASS; `RestZoneId=RestZone1`, 2 hebras habilitadas, 1 pista activa y Stickiness `0.70→1.05` |
| Salida de la zona | PASS; zona vacía, 0 hebras habilitadas y 0 pistas reproduciéndose; las 2 instancias quedan reutilizables |
| RestZone2 bloqueada | PASS; con 0 Rebirths no activó zona, animación ni hebras |
| Muerte y respawn | PASS; personaje nuevo con 2 hebras limpias, 0 habilitadas, 0 pistas activas y zona vacía |
| Stress de lifecycle | PASS; 20 entradas/salidas rápidas terminaron con exactamente 2 hebras, 0 habilitadas y 0 pistas activas |
| Pulso por concesión | PASS; ancho base `0.105`, máximo medido `0.22575`, igual a `0.105 × 2.15` |
| Consola final | PASS; sin errores del sistema nuevo; permanece solo el warning conocido de ProductIds placeholder |
| Teardown | PASS; Studio volvió a Edit, PlaceId `95828455414780` |

### Rendimiento observado

- Scene Analysis reportó el mismo conteo visible con las hebras apagadas y encendidas en la vista
  de prueba: 39,172 triángulos opacos/32 draws, 24 transparentes/2 draws y 3,220 UI/8 draws.
- El clip `StickyPullR15` ocupó 2,461 bytes de memoria de animación en la sesión.
- El controlador no registra `Heartbeat`, `RenderStepped` ni otro loop frecuente.
- La única `AnimationTrack` retenida por el módulo es intencional, acotada a una por personaje y
  no creció tras respawn ni los 20 ciclos.

### Pendiente antes de declarar cierre de plataforma

- [ ] Validar sensación, encuadre y costo en un dispositivo móvil real.
- [ ] Probar con 2–8 clientes para observar simultaneidad, respawn remoto y distancia de cámara.
- [ ] Guardar/publicar manualmente el Place; el cambio permanece en el DataModel abierto.

**Estado:** implementación de un cliente y casos borde aprobados; pendiente validación móvil,
multicliente y publicación manual.

---

## 23. Registro — 2026-08-26, Sticky Snap sin cables

### Decisión e implementación

Se retiró por completo la hebra `Beam`. El feedback actual conserva el gesto R15 y, ante cada
`RestFeedback.Kind == "Granted"` válido, hace volar tres objetos básicos translúcidos hacia el
torso para simular que se pegan. Son `ToyBlock`, `ToyBall` y `Mug`, proxies authored ya
existentes en `ReplicatedStorage.Assets.AttachmentProxies`; funcionan aunque el jugador llegue
al lobby con cero objetos reales.

- `RestZoneStickySnapController` sustituyó a `RestZoneAvatarController` en `ClientMain`.
- `StickySnapR15` sustituyó a `StickyPullR15`; `StickySnapHighlight` es la nueva plantilla
  authored y `StickyStrand` fue eliminado.
- Hay exactamente tres clones pooled por personaje. Se crean una vez, viven en un contenedor
  local separado del character y permanecen invisibles fuera de un snap.
- Cada viaje dura 0.48 s, con 0.07 s de stagger y actualización acotada por `Heartbeat`; no hay
  conexión o loop persistente cuando el efecto está quieto.
- Los offsets se escalan con el tamaño de `UpperTorso`/`Torso`; no se busca ni se toca la
  superficie de ropa, layered clothing, accesorios o skin.
- R15 reproduce la animación; R6 conserva la ilusión de objetos y omite solo el clip R15.
- Sigue sin haber progreso cliente, remotos nuevos, física, colisiones, raycasts ni texto nuevo.

### Pruebas en Studio

| Caso | Resultado |
| --- | --- |
| RestZone1 con pila vacía | PASS; Stickiness `0→0.70`, 3 objetos y 3 highlights simultáneos, 1 pista activa |
| Salida | PASS; 3 modelos pooled, 0 visibles, 0 highlights y 0 pistas activas |
| RestZone2 bloqueada | PASS; con 0 Rebirths no activó zona, objetos ni animación |
| Muerte/respawn | PASS; 1 contenedor nuevo, 3 modelos invisibles, sin contenedor anterior |
| 20 entradas/salidas | PASS; terminó con 1 contenedor, 3 modelos, 0 visibles y 0 pistas |
| 30 grants rápidos | PASS; máximo 3 modelos/3 visibles/3 highlights; al finalizar volvieron a invisibles |
| Payload inválido/fuera de zona | PASS; string, `Kind` incorrecto y `ZoneId` ajeno no mostraron objetos |
| Proporciones R15 distintas | PASS; width 0.72, height 1.15, depth 1.18 y head 0.85 mantuvieron 3 objetos visibles |
| Consola final | PASS; sin errores del sistema nuevo; solo warning conocido de ProductIds placeholder |
| Teardown | PASS; Studio volvió a Edit, PlaceId `95828455414780` |

### Rendimiento observado

- Con cámara fija, Scene Analysis midió exactamente lo mismo idle y durante Sticky Snap:
  69,856 triángulos y 99 draw calls totales (incluidos shadows), sin delta visible en esa vista.
- El clip `StickySnapR15` ocupó 2,461 bytes.
- Después de respawn, 20 ciclos y 30 grants rápidos no quedaron Models, Parts ni Highlights
  unparented. La única instancia retenida por el controlador fue una `AnimationTrack` de 1 por
  personaje, intencionalmente cacheada y reutilizada.

### Pendiente

- [ ] Validar sensación y costo en móvil real.
- [ ] Ejecutar una prueba con 2–8 clientes y LOD social.
- [ ] Guardar/publicar manualmente el Place; los cambios permanecen en el DataModel abierto.

**Estado:** implementación y suite de un cliente aprobadas; pendiente móvil, multicliente y
publicación manual.
## Shop unificado de Robux · ✅ HECHA (2026-08-24)

Tienda única del juego, pedida por el game designer sobre una referencia visual de cards con
precio en Robux. Sustituye a los paneles sueltos que vendían lo mismo desde el HUD.

**Alcance decidido:** solo Robux. 5 secciones y 11 tarjetas.

| Sección | Origen del catálogo | Tarjetas |
| --- | --- | --- |
| GAME PASSES | `Monetization.GamePasses` | 2 |
| STICKINESS PACKS | `Boosts.Packs` | 4 |
| X2 BOOSTS | `Boosts.Timed` | 2 |
| PREMIUM WRAPS | `StickyWraps` con `ProductId` | 2 |
| SKIP REBIRTH | `Rebirth.Skip` | 1 |

**Fuera de alcance a propósito.** Los 8 tiers `DoubleWin_*` **no** son packs de Wins: son bandas
de precio del premio de un pedestal concreto y solo valen con una reclamación viva. Vendidos
sueltos pagarían `FallbackWins` (20 Wins por R$25), el peor cambio del juego. Si alguna vez hace
falta un pack de Wins de verdad, se añade su catálogo a `SECTION_SOURCES` y una sección authored
con ese `SectionId`.

**Qué se creó**
- `StarterGui.StickyHUD.ShopScreen` authored: `Backdrop`, `Window` (`TitleBar` + `CloseButton`,
  `Sections`, `Message`), las 5 secciones `Section_*` con atributo `SectionId`, y la plantilla
  `_Card`.
- `StarterGui.StickyHUD.ShopOpenButton`, en la misma columna que Rebirth e Inventory.
- `StarterPlayer.StarterPlayerScripts.Client.ShopController`, registrado en `ClientMain`.
- `GameConfig.UI.CompactAttributes.CellSize = "CompactCellSize"`.

**Qué se retiró**
- `GamePassPanel`, `BoostPanel` y `StatsPanel.BoostRow` del HUD.
- `GamePassController` se queda solo con el trofeo del lobby (tag `GamePassDisplay`).
- `BoostController` se queda solo con `ActiveBoostChip` y su cuenta atrás.

**PC y móvil.** El grid reparte por ancho disponible y las secciones tienen `AutomaticSize`, así
que en pantalla estrecha caben menos tarjetas por fila y la sección crece sola; el
`AutomaticCanvasSize` del scroll se ajusta detrás. `CompactCellSize` solo encoge la celda.

**Pruebas (Play, un cliente)**
- [x] 11 tarjetas construidas en las 5 secciones, con título, tagline y precio correctos.
- [x] Consola sin errores ni warnings; ningún controlador falló al arrancar.
- [x] Estados: `OwnedGamePassIds=DoubleWins` → OWNED; `OwnedWrapIds` con `EternalGlue` → OWNED;
      `ActiveBoosts=Boost_Wins:<expiry>` → ACTIVE. El resto siguió comprable.
- [x] Tagline dinámico de los packs: con BasicGlue/R0 daba `S=+250 M=+1K L=+5K XL=+25K`; con
      OmegaGlue y 5 rebirths pasó a `S=+350K M=+1.4M L=+7M XL=+35M`.
- [x] Layout compacto aplicado con el presupuesto de píxeles de un móvil horizontal (817×369):
      todo legible, sin solapes, scroll correcto.
- [ ] **Pendiente:** pasada final en el emulador de dispositivo de Studio (el MCP no puede
      cambiar el viewport de Play; el compacto se validó aplicando sus valores a mano).
- [ ] **Pendiente:** los prompts fallarán hasta que existan los dev products y game passes reales
      y sus ids se peguen en `GameConfig` (`IdsArePlaceholders = true`).

---

## Registro — 2026-08-19, props de `Level_02` en el mundo 2

Los 31 props de `Workspace.GameplayProps.Level_02` sustituyen a los placeholders en las 10 salas
del mundo 2 (Desert). **Ningún prop se usa como puerta**: las 10 puertas del mundo 2 quedan
exactamente como estaban, y los 31 props están dentro de pools de sala.

Mismo pipeline que el mundo 1, así que no hubo que tocar una sola línea de código: plantilla en
`Assets/Collectibles`, proxy con el mismo nombre en `Assets/AttachmentProxies` con su
`AttachmentScale`, y `ObjectValue` en el `ObjectPool` de la sala. Los ProxyId nuevos van del 77
al 107.

### Escalas de pegado

Calculadas para que todo lo pegado se lea a ~2,2 studs, igual que en el mundo 1. Van de `1.000`
(Pot_01, Brick_01 — se pegan a tamaño real) a `0.050` (Pillar_01, que mide 44 studs). Cada una
es editable a mano en `Assets/AttachmentProxies/<Prop>/AttachmentScale`.

### Los pools, repartidos por huella y no por carpeta

La carpeta `MediumProps` de `Level_02` mezcla un cristal de 5,3 studs de ancho con un sarcófago
de 15,6. Es el **ancho** lo que decide cuántos caben en una sala, así que el reparto se hizo por
huella horizontal:

| Sala | Objetos | Sep. | Caben | Pool |
| --- | --- | --- | --- | --- |
| W2_ToyRoom | 32 | 8 | 32 | Pot_01/02/03, Brick_01 |
| W2_Bedroom | 32 | 8 | 38 | Coins_01/02/03, Brick_02 |
| W2_Kitchen | 32 | **5** | 41 | Scarab_01/02/03, Brick_03 |
| W2_Zone4 | 32 | 8 | 34 | Bone_01, Bone_03, Pot_01, Coins_02 |
| W2_Zone5 | 32 | **7** | 36 | Brick_01/02/03, Scarab_01 |
| W2_Zone6 | 32 | 8 | 33 | Pot_02, Pot_03, Coins_03, Bone_03 |
| W2_Zone7 | 20 | 8 | 26 | SmallCrystal_01/02/03, Cactus_01 |
| W2_Zone8 | 10 | 11 | 13 | Cactus_02, Cactus_03, Chest_01, Chest_02 |
| W2_Zone9 | 10 | 12 | 14 | Chest_03, Sarcophagi_01, Sarcophagi_02, Cactus_02 |
| W2_Zone10 | 8 | 15 | 11 | Obelisk_01/02/03, Pillar_01/02/03 |

Los 31 props están usados; ninguno se quedó fuera.

### La capacidad de una sala se mide, no se estima

En el mundo 1 estimé los slots a partir del área y acerté por poco. En el desierto la estimación
se equivoca mucho: las salas tienen obstáculos y retos de plataforma que comen suelo, y el
`raycast` de `ItemPlacementService` solo acepta puntos con suelo propio debajo.

El método que funcionó, y que conviene reutilizar: **poner `TotalObjects` a 100 temporalmente**.
Con eso `targetCount` llega al tope de `MaxSlotsPerZone` y el generador no para antes de tiempo,
así que el aviso imprime la capacidad **real** de la sala. Tres pasadas de medición dieron la
columna "Caben" de la tabla.

Ejemplo de por qué importa: `W2_Kitchen` mide 62 × 88 —más grande que cualquier sala del mundo
1— y con separación 8 solo produce **17 slots**.

### Dos avisos que ya venían de antes

Al medir salió que `W2_Kitchen` (17 slots) y `W2_Zone5` (30) **ya pedían 32 objetos con los
placeholders**, así que arrastraban el aviso de `ItemPlacement` desde antes de este cambio. Se
arreglaron de paso bajando su separación a 5 y 7: los props de `Level_02` de esas salas miden
2–3,7 studs, así que a esa distancia no se tocan, y las dos vuelven a servir sus 32 objetos.

### Lo que cambia de balance

Las siete primeras salas conservan sus 32 objetos por vuelta. `W2_Zone8`, `W2_Zone9` y
`W2_Zone10` bajan a 10, 10 y 8, y `W2_Zone7` a 20. No es una decisión de diseño: son props de 13
a 31 studs de ancho en salas que solo dan 11–26 slots. **Hay que mirarlo en playtest.** La
palanca para recuperarlo es agrandar la `PlacementArea` de esas cuatro salas.

### Pruebas (Studio, Play, un jugador)

| Comprobación | Resultado |
| --- | --- |
| Contrato de proxies (`ValidateAll`) | Válido; 107 proxies, 31 plantillas de Level_02 |
| Recorrido lógico por las 10 salas del mundo 2 | **Ningún aviso de `ItemPlacement`** |
| Render de W2_ToyRoom | 32 objetos: Pot_01 x8, Pot_02 x8, Pot_03 x8, Brick_01 x8 |
| Props apoyados en el suelo | Base a `0.00` studs del suelo en las cuatro muestras |
| Tarjeta de requisito | Offset por plantilla (`+2.26`, `+2.74`, `+3.07`), texto correcto |
| Recogida real en el mundo 2 | 20 objetos visitados, 12 recogidos y pegados |
| Tamaño de lo pegado | AABB 2,70–3,22 studs, el mismo rango que los props del mundo 1 |
| Puertas del mundo 2 | Intactas: 4 partes cada una, ningún prop de `Level_02` dentro |

`[MovingPlatform] fallo en Desert_ZoneN` aparece en consola durante las pruebas: es un `print`
del reto de plataformas del desierto, disparado porque el arnés teletransporta al personaje por
las salas. No es un error ni tiene que ver con este cambio.

### Pendiente señalado

- `Level_01/SmallProps` tiene ahora **22 props**, siete más que los 15 que importé en la sesión
  anterior. Los nuevos no están en `Assets/Collectibles` ni en ningún pool. Se importan con el
  mismo procedimiento en cuanto se pidan.
- `Level_03` (23 props: 12 Small, 5 Medium, 6 Big) sigue sin usar, a la espera del mundo 3.
- La captura de pantalla de Studio dio timeout en esta sesión, así que la verificación del mundo
  2 es numérica (posiciones, tamaños y contados), no visual.

---

## Registro — 2026-08-25, props de `Level_03` en el mundo 3

Los 23 props de `Workspace.GameplayProps.Level_03` sustituyen a los placeholders en las 10 salas
del mundo 3 (Lava). **Ningún prop se usa como puerta**: las 10 puertas del mundo 3 quedan como
estaban y los 23 props están dentro de pools de sala.

Con esto los tres mundos usan sus props reales. Cero cambios de código en las tres sesiones
después de la primera: el pipeline (plantilla en `Collectibles` → proxy con el mismo nombre y su
`AttachmentScale` → `ObjectValue` en el pool) aguantó los tres sets sin tocar nada.

| Set | Plantillas | ProxyIds |
| --- | --- | --- |
| Level_01 (Forest) | 37 | 40–76 |
| Level_02 (Desert) | 31 | 77–107 |
| Level_03 (Lava) | 23 | 108–130 |

### Escalas de pegado

Calculadas para leerse a ~2,2 studs, igual que en los otros dos mundos. Van de `1.000`
(LavaRocks_02, se pega a tamaño real) a `0.039` (GuardianStatue_01, que mide 57 studs de alto —
el prop más grande de todo el juego). Editables a mano en
`Assets/AttachmentProxies/<Prop>/AttachmentScale`.

### Los pools

| Sala | Objetos | Sep. | Caben | Pool |
| --- | --- | --- | --- | --- |
| W3_ToyRoom | 32 | 6,5 | 40 | Mineral_01/02/03, Coal_01 |
| W3_Bedroom | 32 | 6,5 | 46 | Mineral_04/05/06, Coal_02 |
| W3_Kitchen | 32 | 8 | 43 | Obsidian_01/02, LavaRocks_01/02 |
| W3_Zone4 | 32 | 6,5 | 38 | Coal_01, Coal_02, Mineral_01, Obsidian_01 |
| W3_Zone5 | 32 | 7 | 35 | LavaRocks_01/02, Mineral_04, Obsidian_02 |
| W3_Zone6 | 32 | 8 | 44 | Mineral_02, Mineral_05, Coal_01, Obsidian_01 |
| W3_Zone7 | 14 | 9 | 19 | MineCart_01/02, Egg_01, Egg_02 |
| W3_Zone8 | 16 | 11 | 22 | Egg_03, Egg_01, MineCart_01/02 |
| W3_Zone9 | 10 | 10 | 14 | BigCrystal, Pillar_01, Pillar_02, AncientPillar_01 |
| W3_Zone10 | 12 | 12 | 16 | AncientPillar_02, GuardianStatue_01, BigCrystal, Pillar_01 |

Los 23 props están usados; ninguno se quedó fuera.

**Las seis primeras salas conservan sus 32 objetos**, pero para conseguirlo hubo que **bajar** la
separación de cuatro de ellas (ToyRoom, Bedroom y Zone4 a 6,5; Zone5 a 7). Con la separación 8
que probé primero, ToyRoom daba 30, Bedroom 27 y Zone4 27, por debajo de los 32 que piden. Los
minerales de `Level_03` miden 2,1–4,3 studs, así que a 6,5 siguen sin tocarse.

### Lo que cambia de balance

`W3_Zone7`, `W3_Zone8`, `W3_Zone9` y `W3_Zone10` bajan de 32 a 14, 16, 10 y 12 objetos. Son
props de 11 a 40 studs de ancho en salas que dan 14–22 slots. **Hay que mirarlo en playtest**; la
palanca para recuperarlo es agrandar la `PlacementArea` de esas cuatro salas.

`W3_Zone9` y `W3_Zone10` llevan los props más grandes de todo el juego (28,9 a 39,9 studs de
huella, y la estatua mide 57 de alto). A separación 10 y 12 **se solapan de forma visible**, y no
hay configuración que lo evite: a separación 14 la sala 9 solo produce 8 slots y a 18 produce 7,
que es por debajo del `MinSlotsPerZone`. Se eligió la opción jugable —más objetos, con solape—
sobre la opción limpia con 8 objetos y cero margen de respawn. Si diseño prefiere lo contrario,
es cambiar dos números.

### Pruebas (Studio, Play, un jugador)

| Comprobación | Resultado |
| --- | --- |
| Contrato de proxies (`ValidateAll`) | Válido; 130 proxies, 23 plantillas de Level_03 |
| Recorrido lógico por las 10 salas del mundo 3 | **Ningún aviso de `ItemPlacement`** |
| Render de W3_ToyRoom | 32 objetos: Mineral_01 x8, Mineral_02 x8, Mineral_03 x8, Coal_01 x8 |
| Props apoyados en el suelo | Base a `0.00` studs del suelo en las cuatro muestras |
| Tarjeta de requisito | Offset por plantilla (`+2.66`, `+2.87`, `+3.08`), texto correcto |
| Recogida real en el mundo 3 | 16 objetos visitados, 9 recogidos y pegados |
| Tamaño de lo pegado | AABB 2,87–3,53 studs, el mismo rango que los mundos 1 y 2 |
| Props multiparte pegados | 3 de las 9 piezas tienen 2 partes y su AABB sigue siendo pequeño: las partes extra viajan soldadas, no se quedan atrás |
| Puertas del mundo 3 | Las 10 intactas; ningún prop de `Level_03` dentro de un blocker |
| Captura visual | W3_ToyRoom con sus minerales apoyados y la pila en el personaje |

### Pendiente señalado

- `Level_01/SmallProps` sigue teniendo **22 props**, siete más que los 15 importados en su día.
  Los nuevos no están en `Assets/Collectibles` ni en ningún pool.
- Los requisitos de los objetos del mundo 3 se leen ahora en el orden de `2,25 × 10¹³`
  (`22.5T` en las tarjetas). No es de este cambio, pero conviene confirmarlo con diseño.

## Registro — 2026-08-27, cierre de la migración del HUD, escala por viewport y rendimiento

Continuación de la migración del HUD desde el place de pruebas (`Lugar de tvg_andy`,
placeId 80814338519901) al place de producción (`Exposición pegajosa`, placeId
95828455414780). La copia de la plantilla estaba **completa**: los 941 descendientes de
`StickyHUD` son idénticos propiedad a propiedad en los dos lugares. Lo que faltaba era
todo lo demás.

### Lo que faltaba

**1. Tres paneles se quedaron con la paleta anterior.** `ShopScreen`, `RunFailureOverlay`
y `RestZoneStatus` solo existen en producción, así que la copia no los tocó: seguían en
azul marino con radios de 18/14/12 px, mientras el resto del HUD ya era la paleta
`Ink` + `Surface` con radio de panel 5 y de control 0.02 en escala. Se confirmó
comparándolos con `ServerStorage.HUDMigrationBackup_20260827`: su `Window` tiene el mismo
color exacto que antes de migrar.

Se restilizan contra el token que corresponde a su **rol**, no por gusto: `RestZoneStatus`
y `RunFailureOverlay` como chips o avisos flotantes (relleno `Ink`, esquina 0.05, contorno
de 3 en el color que da el significado), igual que `ActiveBoostChip` y `WorldEventBanner`;
`ShopScreen` como ventana modal (superficie blanca, contorno de tinta de 5, secciones en
`SurfaceAlt`, tarjetas con la receta de `_CosmeticRow`), igual que `InventoryScreen`.

**2. Trece etiquetas seguían en `GothamSSm` y `LegacyArial`.** Pasan a `FredokaOne`.

**3. Dos elementos del HUD estaban apagados.** `TopStats.BlockerProgress` (la línea de
objetivo, "TOY CHEST 0 / 25") y `StatsPanel.PerkRow` (los chips de SPEED y MAGNET) tenían
`Visible = false`. En el backup previo a la migración los dos estaban en `true`, y
`HUDController` los sigue calculando y escribiendo en cada actualización. Es estado del
sandbox de Andy que viajó con la copia. Se devuelven a `true`.

**4. `TopStats` estaba fuera de su marco.** Sus cuatro etiquetas tenían la `Position` base
con la Y en **escala 4.32 a 5.02** —entre 294 y 341 px por debajo de un marco de 68 px de
alto—, así que flotaban sueltas a media pantalla, justo donde salen los avisos de acción.
Solo se veía en layout ancho: el juego compacto de atributos (`CompactPosition`) sí era
correcto, y la ventana de pruebas de Andy (1108x612) entraba en compacto. Se recolocan
dentro de la banda y el bloque entero se ancla ahora **encima de la barra de nivel**
(`AnchorPoint` 0.5,1 y `Position` {0.5,0},{1,-166}), con `CompactAnchorPoint` para que en
móvil siga arriba.

**5. `ScreenInsets`** pasa de `DeviceSafeInsets` a `None`, que es lo que tiene el place de
Andy. En escritorio no cambia nada (`IgnoreGuiInset` ya era `true`); importa en móviles con
recorte. **Aviso**: `None` significa que el HUD ignora el área segura, así que hay que
mirarlo en un teléfono con notch antes de publicar.

### Por qué el HUD se veía más pequeño

No se veía más pequeño: **a igual viewport los dos HUD son idénticos al píxel**. Lo que
cambia es el tamaño de la ventana de pruebas, y varios bloques están dimensionados en
**píxeles fijos**: `TopStats` y `StatsPanel` llevan el alto en offset, y `NavGrid` y
`UtilityRow` lo llevan en las dos dimensiones. La misma banda de 68 px es el 11,1 % de una
pantalla de 612 de alto y el 6,3 % de una de 1080; el texto va con `TextScaled` dentro de
esa caja, así que encoge con ella hasta quedarse en 14 px.

`DesignSystem.Scale` ya describía la solución —tokens escritos para 720p de alto,
multiplicados por el viewport y acotados entre 0.70 y 1.50— pero **nadie la había
conectado**. Ahora la conduce `ResponsiveLayout`, que ya era el dueño de adaptar el HUD al
tamaño de pantalla:

- Un `UIScale` **authored** llamado `ViewportScale` dentro de cada bloque que lo necesita.
  Añadir o quitar un bloque del escalado es crear o borrar esa instancia en Studio.
- Va por bloque y **no en la raíz del `ScreenGui`** a propósito: un `UIScale` en la raíz
  escalaría también las `Position` en escala de sus hijos y mandaría fuera de pantalla todo
  lo anclado a un borde (`UtilityRow`, `GamePassPanel`, `NavGrid`).
- Atributo authored `ScaledOffset = true` para el problema hermano: un bloque que crece
  también tiene que separarse lo proporcional de sus vecinos. El `-166` de `TopStats` es
  62 + 96 + 8 medidos a 720p; sin escalarlo, un `StatsPanel` de 144 px se lo come.
- En layout compacto el factor se fuerza a 1: los atributos `Compact*` ya están calibrados
  para pantallas pequeñas.

Resultado a 1918x1080: `TopStats` pasa del 6,3 % al 9,4 % del alto (el objetivo del sistema
de diseño; en la ventana de Andy era el 11,1 %) y `NavGrid` del 18,1 % al 27,2 %. El cuerpo
de letra de la Stickiness pasa de 27 a 40 px y el de las líneas auxiliares de 14 a 21.

**Pendiente**: `RestZoneStatus` no escala. Ya tiene un `UIScale` (`PulseScale`) que anima
`RestZoneMachineController`, y Roblox solo aplica uno por objeto. Además, ahora que
`StatsPanel` es más alto, ese panel tapa más de la barra de nivel de lo que tapaba antes.
Las dos cosas se arreglan juntas moviéndolo, y es decisión de diseño.

### Rendimiento del HUD

Medido en Studio, cliente, 1918x1080. En reposo el HUD ya estaba limpio (0 reescrituras en
6 s, antes y después). El coste estaba en los **picos**: abrir el inventario, cambiar de
tamaño la ventana y, sobre todo, cualquier repintado de un botón.

| Cambio | Medida |
| --- | --- |
| `DesignSystem.ApplyRim`: huella de las 6 entradas que deciden el bisel, guardada en un atributo de la propia instancia. Era idempotente en el RESULTADO, pero rehacía el trabajo: dos secuencias nuevas (`ColorSequence` + `NumberSequence`) de cuatro puntos por pieza, cada vez | Barrido global de 271 biseles: 2,67 → 0,92 ms (−66 %) |
| `RimScaler`: cola de instancias sucias en vez de barrido global. Antes, cambiar el color de UN botón re-aplicaba el bisel a los 271 | Repintar un botón: 2,67 → 0,009 ms (**293x menos**) |
| `TextStrokeScaler`: caché por etiqueta de las cuatro entradas de `padTo` y `applyTo`. El barrido reescribía padding y contorno de las ~180 etiquetas para corregir dos | Barrido en reposo: −38 % |
| `TextStrokeScaler`: `DescendantRemoving` filtrado. Sin la condición, cualquier instancia que desapareciera lanzaba un barrido completo, y desaparecen constantemente sin que nadie toque una letra (los `UIScale` de `PressFeedback`, los biseles, los iconos del pinner) | Elimina una clase entera de barridos |
| `TextIconPinner`: caché de lado, ancho de texto y alineación. Está enganchado a tres señales por etiqueta y las tres se disparan juntas en cada cambio de contador; reescribía ocho propiedades cada vez | 2 de cada 3 disparos salen sin escribir |
| `HUDController`: los 16 `GetAttributeChangedSignal` se juntan en un `update()` diferido por frame. Una recogida movía hasta cuatro atributos y producía cuatro repintados completos | 4 → 1 por frame |
| `HUDController.updatePerk`: sale antes si el valor, el siguiente escalón y el prefijo no se movieron. El caso normal es que el nivel no cambie y la Stickiness sí | Dos `string.format` con RichText menos por actualización |

### Pruebas (Studio, Play, un jugador, 1918x1080)

| Comprobación | Resultado |
| --- | --- |
| Consola durante toda la sesión | Solo los dos avisos previos (ids placeholder de compra, `ZoneFailSafe` sin volumen) |
| Apilado vertical del HUD inferior | `BlockerProgress` 729–750, `Stickiness` 755–796, wrap y multiplicador 800–821, `PerkRow` 844–915, `LevelBar` 958–1019, `BoostRow` 1035–1080. Sin solapes, nada fuera de pantalla |
| Ráfaga de 4 atributos en el mismo frame | Un solo repintado, aplicado antes del frame siguiente; Stickiness, objetivo, nivel, barra y los dos perks correctos; restaurar los valores los devuelve |
| Shop abierto con clic real | Ventana blanca con contorno de tinta, secciones lavanda, tarjetas con acento por producto, desenfoque del modal activo |
| Inventario abierto con clic real | 40 filas clonadas; 271 objetos piden bisel, **271 lo tienen y 271 tienen huella** (la cola de sucios no deja piezas sin biselar) |
| `RunFailureOverlay` y `RestZoneStatus` forzados visibles | Paleta correcta y coherente con los chips ya migrados |
| Contraste de todo lo restilizado | 14 pares medidos, todos por encima del mínimo. La X blanca sobre coral da 2,88:1 igual que en Inventory y World, y se lee por el halo de tinta: se le puso el mismo `ApplyStrokeMode = Contextual` que allí |
| Reposo, 6 s | 0 reescrituras de padding, contorno, gradiente o icono |

### Decisión que conviene revisar

Las cinco secciones del Shop tenían cada una un contorno de color distinto (amarillo, cian,
morado, rosa, dorado) como identidad de sección. Se han unificado a contorno de tinta, que
es lo que hacen el resto de contenedores del HUD migrado, y el color de producto se queda
donde `ShopController` ya lo pone: en el borde de cada tarjeta. **Si esa identidad por
sección importaba, se recupera cambiando cinco `Stroke.Color`.**

## Registro — 2026-08-27 (2), retoque de tamaño y agrupación del HUD en PC

Continuación directa del registro anterior, sobre una captura real en PC. Tres quejas:
todo se veía pequeño menos los botones de la derecha, la barra de abajo estaba pegada al
borde y le faltaba tamaño, y los textos de encima de la barra se leían sueltos porque no
estaban cerca de la barra ni entre sí.

### Lo que se descartó por el camino

El `ViewportScale` del registro anterior **no vale para `TopStats` ni `StatsPanel`**, y esto
es la lección del día: un `UIScale` escala por igual las dos dimensiones. Esos dos bloques
tienen el **ancho en escala y el alto en offset**, así que el ancho —que ya era
proporcional— se multiplicaba otra vez: con el factor a 1,875 la barra de nivel pasó del
50 % al **94 %** de la pantalla.

El `UIScale` se queda solo donde es correcto: bloques con las dos dimensiones en píxeles
(`NavGrid`, `UtilityRow`). Para los otros dos la solución es más simple y no necesita
factor: **escribir el alto también en escala**, que es proporcional por definición. Con eso
desaparece también el atributo `ScaledOffset`, que existía para escalar la separación entre
los dos bloques y ya no tiene nada que escalar.

### Presupuesto vertical del bloque inferior, en fracción del alto de pantalla

    BlockerProgress  0.0250   \
    aire             0.0019    |  TopStats   0.6315 .. 0.7324   ancho 0.34
    Stickiness       0.0463    |  (antes 0.50: por eso las dos
    aire             0.0037    |   etiquetas de abajo quedaban
    Wrap+Multiplier  0.0241   /    a 347 px una de otra)
    aire             0.0139  <- separación entre bloques
    PerkRow          0.0556   \
    aire             0.0083    |  StatsPanel 0.7463 .. 0.9546   ancho 0.50
    LevelBar         0.0806    |
    aire             0.0083    |
    BoostRow         0.0556   /
    margen inferior  0.0454  <- antes 0: `BoostRow` colgaba fuera del panel
                                (Position Y 1.2675) y tocaba el borde

### Agrupación horizontal

- **La banda de `TopStats` baja de medio ancho de pantalla a un tercio.** Es lo que junta
  el bloque de texto en vez de estirarlo de lado a lado.
- **`WrapLabel` y `MultiplierLabel` se dan la vuelta.** Estaban ancladas a los extremos de
  la banda y alineadas hacia fuera, así que su texto se iba a los dos bordes. Ahora se
  anclan junto al centro y alinean hacia él, con un 4,4 % de la banda de aire en medio
  (29 px a 1080p). Llevan `CompactAnchorPoint` porque el ancla no viaja en el juego de
  atributos compacto y sin él se saldrían de la banda en móvil.
- **Los chips de perk pasan del 49 % al 34 % del panel cada uno.** Al estrecharlos, su
  `UIListLayout` centrado los junta en el medio en vez de dejar "SPEED" en un extremo y
  "MAGNET" en el otro.

### Tamaño de letra: dos causas distintas

**1. Cuatro etiquetas no tenían `TextScaled`.** `SpeedChip.Value`, `SpeedChip.Next` y sus
gemelas de `RadiusChip` tenían `TextScaled = false` con un `TextSize` authored de 8, así que
subían al **mínimo** de su `UITextSizeConstraint` y se quedaban clavadas en 14 px con la
caja a 43. Por eso los chips de perk se leían diminutos por grandes que fueran. Es un fallo
anterior a la migración, no de ella.

**2. Varias estaban topadas por `MaxTextSize` con caja de sobra.** Se suben los topes solo
donde la caja lo permite: los cuatro tiles de `NavGrid` 16 → 22, los cuatro `BoostRow.Amount`
26 → 34 y `LevelBar.AmountText` 36 → 38. **`GamePassPanel` no se toca**: los botones de la
derecha se ven bien y se quedan como están.

**Y un efecto secundario que hubo que arreglar:** `LevelBar.LevelText` tenía el ancho clavado
en 76 px de offset. Al crecer la barra, "Level 1" ya no cabía y se partía en dos líneas. Pasa
a `{0.16, 0}` en escala de la barra, con un `CompactSize` de `{0, 76}` porque en móvil la
barra es estrecha y 0,16 de ella no da ni para el mínimo de 14 px.

### Resultado medido a 1918x1080

| Elemento | Antes | Ahora |
| --- | --- | --- |
| `Stickiness` | 40 px | 49 px |
| `BlockerProgress` | 21 px | 26 px |
| `WrapLabel` / `MultiplierLabel` | 21 px | 25 px |
| `LevelText` | 58 px **en dos líneas** | 40 px en una |
| `SpeedChip.Value` | 14 px | 38 px |
| `SpeedChip.Next` | 14 px | 24 px |
| `BoostRow.Amount` | 26 px | 34 px |
| Etiqueta de `NavGrid` | 16 px | 22 px |
| Alto de `LevelBar` | 61 px | 85 px |
| Alto de `BoostRow` | 45 px | 59 px |
| `NavGrid` | 7 % x 27 % | 7 % x 34 % |
| `CounterStack` | 12 % x 17 % | 12 % x 14 % del alto, 25 % más grande en escala |
| Margen bajo la fila de boosts | 0 px | 49 px (4,5 %) |
| Ancho de la banda de texto | 50 % | 34 % |
| Hueco "Basic Glue" / "x1.0 Stickiness" | 347 px | 29 px |

### Pruebas (Studio, Play, un jugador, 1918x1080)

| Comprobación | Resultado |
| --- | --- |
| Apilado vertical completo | 682–709 / 711–761 / 765–791 / 811–870 / 878–964 / 972–1031, aires de 2, 4, 20, 9 y 9 px. Sin solapes |
| Margen inferior | 49 px, la fila de boosts ya no toca el borde |
| Ráfaga de 4 atributos con valores altos (4.2K Stickiness, Level 7) | Un solo repintado; "Level 7" y "4.2K Stickiness" siguen en una línea y dentro de su caja (291 px de texto en 652 de banda) |
| Consola | Limpia |
| Reposo, 5 s | 0 reescrituras de padding o contorno: las optimizaciones del registro anterior siguen en pie |

### Palanca para seguir ajustando

`ScaleBoost` es un atributo numérico authored que se lee desde Studio: multiplica el factor
de viewport del bloque que lo lleva. Hoy `NavGrid` y `UtilityRow` van a 1.25. Subir o bajar
el tamaño de esos bloques es escribir otro número, sin tocar código. Los bloques con el alto
en escala (`TopStats`, `StatsPanel`) se ajustan cambiando esas fracciones en el editor.

## Registro — 2026-08-27 (3), contadores de la izquierda y fila de utilidades

### Sonido y ajustes, escondidos

`StickyHUD.UtilityRow.Visible = false`. Los dos botones llevan el atributo authored
`Placeholder = true` y **ningún script del juego los referencia** (cero menciones a
`SoundSlot` en todo el datamodel), así que no se pierde comportamiento. Se esconde la fila
entera en vez de borrarla: volver a encenderla es marcar `Visible` en el Explorer.

Conserva su `ViewportScale` y su `ScaleBoost`, así que si se reactiva vuelve con el tamaño
que le tocaba.

### Contadores de la izquierda, más grandes

**Lo que de verdad los limitaba no era el `Size`.** `CounterStack` tiene un
`UISizeConstraint` con `MaxSize = 230x150`, y a 1918x1080 ya estaba clavado en el tope: el
`Size` en escala pedía 288x227 y la restricción lo recortaba. Agrandar la escala no habría
hecho absolutamente nada.

| | Antes | Ahora |
| --- | --- | --- |
| `SizeLimits.MaxSize` | 230x150 | 330x205 |
| `Size` | {0.15}, {0.21} | {0.19}, {0.23} |
| `Position` Y | 0.15 | 0.125 (sube para no chocar con `NavGrid` al crecer) |
| Fila de Rebirth / Wins | 45 px | 62 px |
| Icono | 45 px | 62 px |
| Número | 38 px | 52 px (tope subido de 50 a 56 para que mande la caja) |
| Hueco hasta `NavGrid` | 55 px | 27 px |

### Un desbordamiento que llevaba ahí desde siempre

`SpeedCounter` y `ReachCounter` medían 0.65 y 0.60 del ancho de su fila: **1.25 más el
padding del `UIListLayout`**, así que el de alcance siempre salía por la derecha del
bloque. Con el bloque a 230 px se salía 57 y se perdía sobre el fondo; al subir a 330 se
plantó encima del cartel de WORLDS y se hizo evidente. Los dos pasan a 0.44, que con el
padding suma 0.925 y cabe.

Verificado en Play: los cuatro contadores dentro del bloque, desborde máximo 0 px.

### Pendiente que aparece al encender la línea de objetivo

`TopStats.BlockerProgress` ahora se lee, y dice **"BLOCKER 0 / 25"**. No es un fallo del
HUD: `GameConfig` tiene `BlockerDisplayName = "Blocker"` en **las 30 zonas**, es un texto de
relleno que nunca se rellenó. Los datos para hacerlo bien ya están al lado (`BlockerId` vale
`ToyChest`, `Bed`, `Refrigerator`, `Zone4Gate`...), pero derivarlo del id daría "ZONE 4 GATE"
en siete de cada diez zonas. Necesita una pasada de contenido, y por la regla 7 debería
entrar ya como claves de localización, no como texto a mano.

### Añadido al registro (3): zapato y mano verde escondidos

`CounterStack.CounterStack.Visible = false`. Los dos contadores que colgaban de esa fila
—`SpeedCounter` (zapato) y `ReachCounter` (mano verde)— usan **exactamente los mismos
assets de icono** que `PerkRow.SpeedChip` (`137108235876714`) y `PerkRow.RadiusChip`
(`120376248907319`), o sea que representaban velocidad y radio de recogida, lo mismo que
los dos chips de encima de la barra.

Y no estaban enlazados a nada: `SpeedCounter` y `ReachCounter` no aparecen en un solo
script del juego, y `HUDController` solo busca dentro de `CounterStack` los nombres
`RebirthCounter`, `WinsCounter` y un `ObjectCounter` opcional. Su "0" era el texto authored
de la plantilla, congelado: no cambiaba nunca. Los chips de perk sí muestran el valor real
y además la siguiente mejora.

Al quedarse el bloque con dos filas se le ajusta la caja para que coincida con lo que
enseña —un frame cuyos límites no coinciden con su contenido obliga a adivinar la
separación con los vecinos, que es como estuvo a punto de pisar `NavGrid`—:

| | Antes | Ahora |
| --- | --- | --- |
| `SizeLimits.MaxSize` | 330x205 | 330x135 |
| `Size` | {0.19}, {0.23} | {0.19}, {0.155} |
| Fracción de cada fila | 0.3033 | 0.466 (para que sigan midiendo 63 px) |
| Hueco hasta `NavGrid` | 27 px | 97 px |

Verificado en Play: dos filas de 63 px con icono de 63 y número de 53, la fila del zapato
oculta, consola limpia.
