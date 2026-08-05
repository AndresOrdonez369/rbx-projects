# Plan — Objetos per-player y pools de sala configurables

**Fecha:** 2026-08-03
**Estado:** propuesta, pendiente de aprobación para ejecutar con el MCP de Roblox Studio
**Lugar inspeccionado:** `Exposición pegajosa` (modo Edit)

---

## 1. Qué pide diseño

1. **Objetos per-player.** Hoy los collectibles son instancias del servidor replicadas a todos. Si un jugador recoge uno, el resto lo ve desaparecer y no puede recogerlo. Se quiere que cada jugador tenga su propio conjunto de objetos, de modo que varios jugadores en la misma room no se bloqueen la progresión.
2. **Pool de objetos configurable por sala.** Hoy los 12 spawns están *baked* en el editor con `RequiredStickiness` y `ZoneId` por marker. Se quiere definir por room qué tipos de objeto pueden aparecer.
3. **Meta de objetos por sala.** Definir cuántos objetos debe haber en la room y que el sistema reparta equitativamente esa meta entre los tipos del pool.
4. **Colocación aleatoria a lo largo de toda la room**, no en 12 posiciones fijas.
5. **Spawn diferido:** los objetos se crean cuando el jugador entra a la room; ninguna room vacía tiene objetos ni lógica corriendo.

---

## 2. Estado actual (lo que hay que tocar)

| Módulo | Rol hoy | Impacto |
|---|---|---|
| `ServerScriptService.Server.CollectibleService` | Lee markers taggeados `ItemSpawn`, crea el Part, escucha `Touched`, valida y otorga | Se reescribe: pasa a validar peticiones de pickup del cliente |
| `ServerScriptService.Server.CollectibleFactory` | Construye por código el Part + BillboardGui | Se mueve al cliente y pasa a **clonar plantillas authored** |
| `ServerScriptService.Server.SpawnService` | Pool global por zona: 12 handles, 10 activos, 2 reservas, mínimo 4 elegibles | Se parte en dos: cálculo de slots (por sala) y pool por jugador |
| `ServerScriptService.Server.RoomService` | Registro de zonas por tag + validación estructural | Se conserva; se le añade validación del área de colocación |
| `StarterPlayer...Client.ObjectLabelController` | Colorea verde/rojo por tag `StickyCollectible` | Se conserva casi igual (ahora trackea partes locales) |
| `AttachmentService`, `ProgressionService`, `BlockerService`, `FinishService` | Pila visual, stats, blockers, meta | **No se tocan** si se conserva el contrato `CollectibleService.ConnectCollected` |
| `Workspace...Zones.<Zone>.ItemSpawns` (12 Parts/zona) | Posiciones fijas | Quedan como modo de compatibilidad opcional; dejan de ser obligatorias |
| `Workspace...Zones.<Zone>.Collectibles` | Contenedor server-side | Queda vacío / se retira del contrato |

Ya existe una pieza clave a favor: **`Player:GetAttribute("CurrentZoneId")` es autoritativo del servidor** (lo fija `ProgressionService` al iniciar/resetear y `BlockerService` al absorber un blocker). Ese atributo es la señal natural de "entré a la room" y nos evita inventar volúmenes de trigger.

---

## 3. Decisión técnica central: por qué el render pasa al cliente

Roblox **no permite filtrar la replicación de instancias de `Workspace` por jugador**. No hay forma de que un Part del servidor sea visible solo para uno. Las únicas rutas per-player reales son:

- **A) Instancias creadas en el cliente** (LocalScript) → existen solo en esa máquina. ✅
- B) Un set de objetos por jugador replicado a todos, filtrando visualmente por transparencia/colisión desde el cliente → replica N×jugadores instancias a todo el mundo. ❌ escala pésimo y sigue enviando datos ajenos.
- C) `PlayerGui`/Billboards → solo sirve para UI, no para props en el mundo. ❌

Vamos por **A**, con el modelo estándar de Roblox: **servidor autoritativo de datos, cliente autoritativo de presentación**.

### Reparto de responsabilidades

```
SERVIDOR (fuente de verdad, 0 instancias en Workspace)
  RoomService            → qué salas existen, su config y su área de colocación
  ItemPlacementService   → calcula UNA vez por sala una lista de slots válidos (cacheada)
  RoomItemService        → sesión por (jugador, sala): qué objetos tiene, dónde, requisito, estado
  PickupService          → recibe la petición, valida todo, otorga, dispara ConnectCollected
        │
        │  RemoteEvents (payloads compactos)
        ▼
CLIENTE (solo presentación y detección)
  CollectibleRenderer    → clona plantillas authored, las coloca, las devuelve al pool local
  PickupSensor           → loop throttled: distancia al objeto → pide pickup al servidor
  ObjectLabelController  → verde/rojo (sin cambios de fondo)
```

### Sobre seguridad

El servidor sigue decidiendo todo el progreso, igual que hoy:

- El pickup se valida contra la **posición guardada en el servidor**, nunca contra la que mande el cliente.
- Se verifica: el objeto pertenece a la sesión activa de ese jugador, no está consumido, el requisito de stickiness se cumple, el personaje está vivo, la sala de la sesión coincide con `CurrentZoneId`, y la distancia `HumanoidRootPart → slot` está dentro de `PickupRadius + tolerancia`.
- Rate limit por jugador (token bucket configurable) para que un exploiter no pueda vaciar la sala en un frame.

Esto **no empeora** la superficie actual: hoy el pickup depende de `Touched`, que también lo dispara la física del cliente. La diferencia es que ahora la validación de distancia es explícita y configurable en vez de implícita.

---

## 4. Configuración nueva en `GameConfig`

Toda la palanca de diseño vive aquí (regla 3 de `AGENTS.md`). No hay que editar servicios para rebalancear.

### 4.1 Catálogo de tipos de objeto

```lua
GameConfig.CollectibleTypes = {
    { Id = "ToyBlock",  DisplayName = "Toy Block",  Template = "ToyBlock",  GainMultiplier = 1 },
    { Id = "TeddyBear", DisplayName = "Teddy Bear", Template = "TeddyBear", GainMultiplier = 1 },
    { Id = "RubberDuck",DisplayName = "Rubber Duck",Template = "RubberDuck",GainMultiplier = 1 },
    -- ...
}
```

`Template` apunta a un modelo **authored** en `ReplicatedStorage.Assets.Collectibles.<Template>` (regla 5: nada de geometría permanente construida por código). `GainMultiplier` queda reservado —arranca en 1 para todos— por si diseño luego quiere que el tipo afecte balance.

### 4.2 Por sala

```lua
{
    Id = "ToyRoom",
    ...
    -- NUEVO
    ObjectPool = { "ToyBlock", "TeddyBear", "RubberDuck", "ToyCar" },  -- o { Id = "...", Weight = 2 }
    TotalObjects = 24,          -- objetos visibles simultáneamente, por jugador
    PlacementMode = "Procedural",  -- "Procedural" | "Markers" | "Hybrid"
    MinSeparationStuds = 8,
    -- se conserva el balance existente
    CollectibleRequirements = { 0, 5, 12, 25 },
}
```

`ActivePickupTarget` queda sustituido por `TotalObjects` (mismo concepto, ahora per-player y sin tope de 12).

### 4.3 Globales nuevos

```lua
GameConfig.Collection.PickupRadius = 5            -- radio de recogida en el cliente
GameConfig.Collection.PickupValidationSlack = 8   -- tolerancia servidor (lag/altura)
GameConfig.Collection.MaxPickupRequestsPerSecond = 12
GameConfig.Collection.SensorIntervalSeconds = 0.1 -- muestreo del cliente
GameConfig.Collection.MaxRenderedPerRoom = 60     -- techo duro de instancias por cliente
GameConfig.Placement = {
    SlotOversamplingFactor = 2.0,   -- slots calculados = TotalObjects * factor
    MaxSlotAttempts = 400,
    GenerationBudgetPerFrame = 60,  -- validaciones por frame al construir el cache
    FloorInsetStuds = 4,
    ExclusionRadiusStuds = 6,       -- alrededor de StartSpawn, blockers y puertas
    RaycastHeight = 30,
}
```

---

## 5. Reparto equitativo de la meta de objetos

Dos ejes independientes, ambos con **reparto por resto mayor (Hare)** para que la suma dé exactamente `TotalObjects`:

**Eje 1 — tipo visual.** `TotalObjects = 24`, pool de 4 tipos → 6 y 6 y 6 y 6. Con 25 → 7,6,6,6 y el resto rota de sala en sala (o por seed del jugador) para que no sea siempre el mismo tipo el favorecido. Si un tipo trae `Weight`, la cuota se pondera.

**Eje 2 — requisito de stickiness.** Se reparte `CollectibleRequirements` sobre los mismos 24 objetos con la misma función, **pero respetando la regla ya existente** de `MinimumEligibleActivePerZone` (mínimo 4 objetos recogibles al entrar con la stickiness de entrada de la sala). El algoritmo:

1. Reserva `MinimumEligibleActivePerZone` objetos en el tier más bajo (`<= EntryStickiness`).
2. Reparte el resto entre los tiers por resto mayor.
3. Baraja el emparejamiento tipo ↔ requisito con el RNG del jugador.

Así el tipo de objeto es puramente visual y el balance sigue viniendo de `CollectibleRequirements`, sin acoplarlos.

Se conserva una función pura y testeable, p.ej. `ItemPlanner.Build(zoneConfig, seed) -> { {TypeId, RequiredStickiness} }`, que se puede verificar sin tocar el mundo.

---

## 6. Colocación aleatoria: slots calculados una vez por sala

El coste real de "aleatorio a lo largo de toda la room" son los raycasts y las pruebas de solapamiento. Se pagan **una sola vez por sala, la primera vez que alguien entra**, y se cachean para toda la vida del servidor.

### Área de colocación

Una Part authored e invisible por zona: `Zones.<Zone>.PlacementArea`, taggeada `ItemPlacementArea`. Es editable en Studio, así diseño ajusta a mano dónde pueden caer objetos (p.ej. excluir el pasillo de salida). Fallback si no existe: bounds de `Geometry.Floor` con `FloorInsetStuds` de margen, con `warn` explícito.

### Generación del cache de slots

1. Muestreo por **rejilla jitterada** con celda = `MinSeparationStuds` (equivale a Poisson-disk y es determinista y barato). Objetivo: `TotalObjects * SlotOversamplingFactor` slots válidos.
2. Por cada candidato: raycast hacia abajo desde `RaycastHeight` con whitelist de `Geometry` de la zona → si no golpea suelo de la zona, se descarta.
3. `Workspace:GetPartBoundsInBox` con el tamaño del objeto contra `Geometry` + `Blockers` → descarta solapes con muebles y paredes.
4. Descarta candidatos dentro de `ExclusionRadiusStuds` de `StartSpawn`, del blocker y del hueco de la puerta.
5. El trabajo se reparte en frames con `GenerationBudgetPerFrame` para no producir un hitch al entrar el primer jugador.

Resultado: `{ CFrame }` cacheado por `ZoneId`. Con `TotalObjects = 24` y factor 2 son ~48 slots; el coste one-time es del orden de un par de cientos de raycasts, repartido en unos pocos frames.

### Selección per-player

`Random.new(seed)` por sesión (seed = `UserId + zoneOrder + runIndex`) baraja los índices de slots y toma los primeros `TotalObjects`. Ventajas:

- Ningún objeto del mismo jugador se solapa (los slots ya respetan `MinSeparationStuds`).
- Dos jugadores pueden caer en el mismo slot — es irrelevante, no ven los objetos del otro.
- El layout es distinto por jugador y por vuelta, que es lo que pide diseño.
- Al respawnear un objeto consumido, se elige un slot libre **distinto** del sobresample, conservando la sensación de rotación que ya tiene el juego hoy.

`PlacementMode = "Markers"` reutiliza los 12 `ItemSpawns` actuales como lista de slots (compatibilidad hacia atrás y modo de emergencia). `"Hybrid"` los usa como slots garantizados y completa con procedurales.

---

## 7. Ciclo de vida: nada corriendo en salas vacías

| Evento | Servidor | Cliente |
|---|---|---|
| Servidor arranca | 0 instancias, 0 slots calculados, 0 tareas | — |
| `CurrentZoneId` cambia a Z | Genera cache de slots de Z si no existe → crea sesión del jugador → envía manifiesto | Clona plantillas y coloca los objetos |
| Jugador recoge | Valida, marca consumido, otorga, agenda respawn (1 tarea por sesión, no por objeto) | Devuelve el objeto al pool local, muestra feedback |
| Respawn | Elige slot libre, envía `Spawned` | Coloca uno nuevo |
| `CurrentZoneId` cambia a W | Cierra sesión de Z (cancela tarea, limpia tabla) → abre W | Descarga todo lo de Z |
| Muerte / reset / replay / rebirth | Cierra y reabre sesión con nuevo seed | Descarga y recarga |
| `PlayerRemoving` | Cierra sesión, limpia todo el estado por jugador | — |
| Sala sin jugadores | Solo queda el cache de slots (una tabla de CFrames). Cero instancias, cero tareas | — |

**Una sola tarea de respawn por sesión** (una cola ordenada por tiempo) en vez de un `task.delay` por objeto: con 24 objetos × 8 jugadores eso son 8 tareas en vez de 192.

### Presupuesto de instancias

| | Hoy | Después |
|---|---|---|
| Parts permanentes en servidor | 36 collectibles + 36 billboards, replicados a todos | 0 |
| Parts por cliente | los 36 de todas las salas | ~24–30 (solo su sala actual) |
| Escala con jugadores | no escala, pero se bloquean entre sí | tablas del servidor: ~24 entradas por jugador activo |

Es decir: más objetos por sala **y** menos instancias replicadas que hoy.

---

## 8. Contrato de red

Dos RemoteEvents nuevos en `ReplicatedStorage.Shared.Remotes`:

**`RoomItemsSync` (servidor → cliente)**

```lua
-- Load: manifiesto completo al entrar
{ Op = "Load", ZoneId = "ToyRoom", Items = {
    { I = 1, T = 2, P = Vector3, R = 0, Q = 0 },   -- Id, TypeIndex, Position, RotY, Requirement
    ...
} }
{ Op = "Consumed", I = 7 }
{ Op = "Spawned",  I = 25, T = 1, P = Vector3, R = 90, Q = 12 }
{ Op = "Unload",   ZoneId = "ToyRoom" }
```

Payload de carga con 30 objetos: unos pocos cientos de bytes. Se envía una vez por entrada a sala, no por frame.

**`PickupRequest` (cliente → servidor)**: `{ I = 7 }`. Nada más — la posición y el tipo los tiene el servidor.

La respuesta reutiliza el `PickupFeedback` que ya existe (`Kind = "Collected" | "Denied"`), así el HUD y el feedback actual no cambian.

---

## 9. Plantillas authored requeridas (regla 5 de AGENTS.md)

Hay que crear en Studio, editables a mano:

```
ReplicatedStorage/
  Assets/
    Collectibles/
      ToyBlock      (Model con PrimaryPart, o BasePart)
      TeddyBear
      RubberDuck
      ...
      _RequirementBillboard   (plantilla del BillboardGui, hoy construido por código)
```

Contrato que valida el renderer al arrancar, con fallo explícito si no se cumple:

- Es `BasePart` o `Model` con `PrimaryPart`.
- Nº de partes ≤ `MaxPartsPerTemplate` (configurable; sugerido 8).
- Sin scripts.
- Se fuerza `Anchored = true`, `CanCollide = false`, `CanTouch = false`, `CastShadow = false` al clonar.

Nota: esto además **corrige una deuda actual** — hoy `CollectibleFactory` construye por código el Part y el BillboardGui, lo cual va contra la regla 5.

---

## 10. Fases de ejecución

| Fase | Contenido | Verificación | Est. |
|---|---|---|---|
| **0. Contratos** | `GameConfig` nuevo, carpeta `Assets/Collectibles` con 1 plantilla (réplica del cubo actual) + billboard authored, 2 RemoteEvents, `PlacementArea` en las 3 salas | El place carga sin warnings; `RoomService` valida las áreas | 1 h |
| **1. Slots** | `ItemPlacementService`: muestreo, raycast, overlap, exclusiones, cache, presupuesto por frame | Comando que dibuja los slots de una sala; contar válidos, verificar que ninguno cae en muebles/paredes/puerta | 1.5 h |
| **2. Planner** | `ItemPlanner.Build(zoneConfig, seed)` — función pura de reparto tipo + requisito | Prueba en command bar: 24 objetos/4 tipos → 6/6/6/6; 25 → 7/6/6/6; ≥4 elegibles a la entrada; totales exactos con varios seeds | 1 h |
| **3. Sesiones + render** | `RoomItemService` (sesión por jugador/sala) + `CollectibleRenderer` cliente con pool local. **Sin pickup todavía** | Entrar a una sala: aparecen N objetos; salir: desaparecen; 2 jugadores ven layouts distintos | 2 h |
| **4. Pickup** | `PickupService` con validación completa y rate limit; se reconecta `ConnectCollected` para no tocar `AttachmentService` ni `ProgressionService` | Camino feliz, rechazo por requisito, rechazo por distancia, doble petición del mismo id, ráfaga de peticiones | 2 h |
| **5. Respawn + ciclo de vida** | Cola única de respawn por sesión; cierre en cambio de sala, muerte, replay, rebirth, `PlayerRemoving` | Recoger → reaparece en otro slot a los 2 s; morir, hacer replay y rebirth sin objetos huérfanos ni fugas de tareas | 1.5 h |
| **6. Retiro del sistema viejo** | Quitar `SpawnService` global, `CollectibleFactory` server, creación de parts en `CollectibleService`; los `ItemSpawns` quedan solo para `PlacementMode = "Markers"` | Cero instancias de collectibles en el servidor durante el juego | 1 h |
| **7. Balance y prueba multijugador** | Subir `TotalObjects` por sala al valor que quiera diseño; test con 2 jugadores | 2 jugadores en la misma sala: ninguno ve ni bloquea los objetos del otro; contadores de instancias y memoria antes/después; actualizar `PLAN_MVP.md` y `PROJECT_MEMORY.md` | 1.5 h |

**Total estimado: 11–12 h.** Se puede cortar a ~7 h si la fase 7 se limita a una sala y se dejan los tipos de objeto en 1 plantilla (el sistema queda igual, solo con menos arte).

### Estado de ejecución — 2026-08-03

Fases 0 a 6 **completadas y verificadas en Studio con un jugador**. Fase 7 completada salvo la prueba con 2 jugadores, que no se puede lanzar desde la herramienta MCP.

| Medición | Resultado |
|---|---|
| Slots por sala (`TotalObjects=12`, sep 8) | 24, generados en 0–2 ms |
| Separación real mínima medida | 8.4 – 9.0 studs |
| Capacidad máxima ToyRoom | 46 slots a sep 8 · 73 a sep 6 · 103 a sep 5 |
| Exclusiones | 0 slots dentro del Toy Chest; borde más cercano a 8.5 studs |
| Reparto (2400 combinaciones) | total exacto siempre; elegibles al entrar ≥ 4 siempre |
| Latencia de pickup | 0.33 s |
| Instancias de collectible en el servidor | 0 |
| Salas sin jugador | sin slots calculados, sin instancias, sin tareas |
| Rechazos del servidor durante la prueba | solo `TooFar`, todos por teletransportes del script de prueba |

Cambios respecto al plan original, decididos durante la ejecución:

1. **La elegibilidad se muestra atenuando los colores propios del prop, no con `Highlight`.** Primero se implementó con Highlights pooled sobre los objetos más cercanos, pero Roblox renderiza como máximo **31 Highlights por cliente**, los deshabilitados también ocupan slot y no hay API para subir el límite. Cualquier tope deja parte de la sala sin marcar, y un estado parcial se lee peor que ninguno. Atenuar el color propio (`IneligibleTintFactor = 0.32`) conserva el tono —una esfera se sigue viendo como esfera— y no tiene límite de instancias: verificado con 60 objetos simultáneos y cero desajustes. Queda un único `Highlight` para marcar el objeto enfocado, que es un mensaje distinto.
2. **El manifiesto envía el nombre de la plantilla, no un índice de tipo.** Cuesta unos bytes más y permite que diseño añada una plantilla nueva a `Assets/Collectibles` y la use en una sala sin tocar `GameConfig`.
3. **Reintento de pickup separado del cooldown de rechazo.** El primer intento puede llegar antes de que el servidor reciba la posición nueva del personaje; con un reintento de 0.2 s la recogida baja de ~2 s a 0.33 s. Los objetos no elegibles siguen reintentando a la cadencia lenta, que es la que produce el feedback `NEED X MORE`.
4. **La pila pegada al personaje usa el objeto recogido.** Antes `AttachmentService` creaba un cubo genérico y lo pintaba según el tier de requisito. Ahora clona la plantilla authored del objeto que el jugador acaba de tomar, normalizada a `TargetMaxSizeStuds` para que props de distinto tamaño se lean parecidos, y conservando el color propio del prop. Las soldaduras se reconstruyen al cambiar de paso de crecimiento, porque escalar un modelo multiparte con `ScaleTo` mueve las partes y las constraints existentes las devolverían a su posición anterior.
5. **`RoomService` ya no exige las carpetas `ItemSpawns` ni `Collectibles`.** Eran obligatorias en el contrato de sala y ahora una de ellas no se usa; dejarlas obligatorias sería una trampa al crear salas nuevas.

---

## 14. Guía rápida para diseño

Todo se hace desde el Explorer de Studio, sin tocar código.

**Cambiar cuántos objetos hay en una sala**
`Workspace > StuckToYou > Zones > <Sala> > RoomSettings > TotalObjects`. Son objetos visibles a la vez; al recoger uno, otro aparece a los 2 s en otro sitio.

**Cambiar qué objetos aparecen en una sala**
`RoomSettings > ObjectPool`. Cada hijo es un `ObjectValue` que apunta a una plantilla de `ReplicatedStorage > Assets > Collectibles`. Añadir un hijo añade ese tipo; borrarlo lo quita. El reparto de `TotalObjects` entre los tipos se reajusta solo.

**Dar más peso a un tipo**
Atributo `Weight` en el `ObjectValue` (por defecto 1). Con pesos 2 y 1 y 1, el primero aparece el doble.

**Crear un objeto nuevo**
Meter el modelo en `ReplicatedStorage > Assets > Collectibles` (Model con `PrimaryPart`, o una sola Part, sin scripts, máximo 8 partes) y apuntarle un `ObjectValue` desde la sala que lo use.

**Cambiar dónde pueden caer los objetos**
Mover o redimensionar `Zones > <Sala> > PlacementArea`. Es invisible en el juego. El sistema respeta paredes, muebles, la puerta y el punto de aparición por su cuenta.

**Cambiar qué tan juntos aparecen**
`RoomSettings > MinSeparationStuds`. Más bajo permite más objetos en la misma sala.

**Volver al sistema de posiciones fijas**
`RoomSettings > PlacementMode` a `Markers`: usa los 12 `ItemSpawns` authored de siempre. `Hybrid` usa esos primero y completa con posiciones aleatorias.

Si algo está mal configurado (pool vacío, plantilla inválida, valor fuera de rango), la consola lo dice explícitamente y el sistema cae al default. Nunca sustituye en silencio.

---

## 11. Riesgos y cómo se mitigan

| Riesgo | Mitigación |
|---|---|
| Hitch al generar slots la primera vez | Presupuesto por frame + cache permanente; se puede pre-calentar la sala siguiente cuando el jugador absorbe el blocker |
| Un exploiter recoge a distancia | Validación de distancia contra la posición del servidor + rate limit + comprobación de sala activa. Igual o mejor que el `Touched` actual |
| Desync visual (el cliente ve un objeto que el servidor ya consumió) | El servidor es la verdad: si `Denied`/id desconocido, el cliente descarga ese objeto. El id se marca consumido antes de otorgar |
| Plantillas pesadas → caída de FPS con 30 objetos | `MaxPartsPerTemplate`, `MaxRenderedPerRoom`, `CastShadow = false`, pool local de reutilización |
| Sensor de pickup costoso en el cliente | Muestreo cada 0.1 s sobre ≤ 30 posiciones con distancia al cuadrado: coste despreciable. Nada de `Touched` por objeto |
| Regresión en attachments/HUD/finish | Se conserva intacto el contrato `CollectibleService.ConnectCollected(player, payload)`; esos servicios no se tocan |
| `StreamingEnabled` interfiriendo | Verificar el flag del place antes de la fase 3; las instancias creadas en cliente no se ven afectadas, pero los raycasts del servidor sí dependen de geometría cargada (el servidor siempre la tiene completa, así que no hay problema real) |

---

## 12. Decisiones tomadas (2026-08-03)

1. **`TotalObjects` = objetos visibles a la vez**, con respawn al recoger. La sala nunca se vacía.
2. El tipo de objeto es **solo variedad visual** por ahora (`GainMultiplier = 1`), campo reservado para después.
3. Los `ItemSpawns` authored se conservan en el place sin uso (`PlacementMode = "Procedural"`), como red de seguridad hasta pasar el playtest del viernes.
4. **La configuración por sala se edita a mano en el Workspace.** Cada zona lleva un `RoomSettings` authored y editable en Studio; `GameConfig` solo aporta los valores por defecto cuando falta el override. Ver 12.1.

### 12.1 `RoomSettings` authored por sala

```text
Workspace/StuckToYou/Zones/<Zone>/
  PlacementArea            -- Part invisible: define dónde pueden caer objetos
  RoomSettings             -- Configuration
    TotalObjects           -- IntValue   : objetos visibles a la vez
    MinSeparationStuds     -- NumberValue: separación mínima entre objetos
    PlacementMode          -- StringValue: "Procedural" | "Markers" | "Hybrid"
    ObjectPool             -- Folder     : un hijo por tipo de objeto permitido
      <cualquier nombre>   -- ObjectValue apuntando a la plantilla en Assets.Collectibles
                           --   (o StringValue con el Id del tipo de GameConfig)
                           --   atributo opcional Weight (por defecto 1)
```

Para añadir un tipo a una sala, el diseñador arrastra la plantilla dentro de un `ObjectValue` nuevo en `ObjectPool`. Para cambiar la cantidad, edita `TotalObjects`. No hace falta tocar código.

Precedencia: `RoomSettings` (Workspace) → `GameConfig.Zones[i]` (defaults) → constantes globales de `GameConfig.Placement`. Los valores inválidos se ignoran con `warn` explícito y se cae al default; nunca se sustituye en silencio.

---

## 13. Impacto en el calendario de la semana

Esto es alcance nuevo que no estaba en el plan del miércoles/jueves. Son ~11 h, es decir un día completo. Mi recomendación: **hacerlo antes de las tareas de pulido del jueves**, porque el onboarding, el tuning de duración de sala (45–60 s) y el playtest del viernes dependen directamente de cuántos objetos hay y de cómo están distribuidos — afinar eso con el sistema viejo sería trabajo tirado. Las tareas de analítica y responsive del jueves no se ven afectadas y pueden correr después.
