# Stuck to You — Memoria de proyecto

Este documento guarda el estado técnico y las decisiones que necesitamos recordar entre sesiones. El alcance y los checks diarios siguen viviendo en `PLAN_MVP.md`.

## Estado actual

**Última actualización:** 2026-08-03  
**Lugar de Roblox Studio:** `Exposición pegajosa`  
**Modo verificado:** Edit  
**Fase:** miércoles fase 2 completada; persistencia cloud, reconexión, respawn y fallos de carga aprobados. Sistema de objetos per-player implementado y probado con un jugador; prueba con 2 jugadores pendiente (manual).

### Implementado

- Estructura base en servicios y `Workspace.StuckToYou`.
- `ReplicatedStorage.Shared.GameConfig` como fuente única de balance.
- Greybox lineal de Toy Room.
- StartSpawn propio y eliminación del SpawnLocation predeterminado.
- 12 spawn markers etiquetados como `ItemSpawn`.
- Toy Chest etiquetado como `StickinessBlocker`, con requisito 50.
- Funciones de configuración verificadas para Level, Wrap y Rebirth multiplier.
- Collectibles runtime generados desde tags y attributes de spawn markers.
- Pickup autoritativo con validación de requisito, distancia, Humanoid y bloqueo contra doble premio.
- Stickiness, Level y Sticky Wrap replicados mediante atributos del jugador.
- HUD funcional y labels rojo/verde calculados localmente desde estado replicado.
- Respawn configurable de 2 segundos con cancelación y limpieza explícitas.
- Pila visual server-side con 30 slots deterministas y propiedades físicas seguras.
- `AttachmentService` desacoplado mediante evento interno de colección.
- Pool global acotado a 60 piezas libres en `ServerStorage`.
- Crecimiento visual posterior al límite, acotado a 5 pasos.
- Reset de personaje sincronizado: reinicia run y devuelve visuals al pool.
- Toy Chest funcional con validación server-side y estado independiente por jugador.
- Estado visual verde/rojo y animación local de absorción mediante `BlockerController`.
- Salida física greybox hacia `ExitPreview` y transición de HUD a Bedroom.
- Timer de zona replicado en `LastZoneSeconds`.
- `RoomService` data-driven con registro por tag, validación estructural y API de consulta por `ZoneId`.
- ~~`SpawnService` desacoplado con 12 instancias reutilizadas~~ — **retirado el 2026-08-03**, sustituido por el sistema per-player.
- Respawn rotativo: el slot consumido vuelve al final de la cola y una posición distinta ocupa su lugar.
- Bedroom greybox con 12 spawns, Bed requerida a 180 y transición a Kitchen.
- Kitchen greybox con 12 spawns, Refrigerator requerido a 500 y objetivo lógico `FinishZone`.
- Tres pools simultáneos: cada zona mantiene 12 instancias, 10 activas, 2 reservas y 4 elegibles al entrar.
- `BlockerController` con estado rojo/verde completo y tres pases de descubrimiento inicial acotados/cancelables.
- FinishZone físico con `FinishSpawn`, resumen ambiental y `ReplayPad`, deliberadamente fuera del contrato/tag de salas con collectibles.
- `FinishService` server-authoritative con premio idempotente por vuelta, resumen replicado, teletransporte y replay sin recargar el character.
- Una Win exacta al absorber Refrigerator; pile limpia al terminar y Wins conservadas durante replay o muerte.
- APIs públicas pequeñas de reset en `BlockerService` y `AttachmentService`, y API de premio en `ProgressionService`.
- HUD muestra Wins y estado de vuelta completada.
- Tutorial ambiental de una línea junto al StartSpawn y ruta visual continua por las tres zonas.
- Relojes separados de zona y vuelta: `LastZoneSeconds` ya no es acumulativo y Finish conserva `LastRunSeconds` total.
- Stress de 10 vueltas/10 replays en un mismo servidor sin duplicar Wins, agotar pools ni dejar estado residual.
- `DataService` versionado con `UpdateAsync`, session lock, reintentos, autosave, liberación al salir/cerrar y mock aislado a Studio.
- Wins y Rebirths conectados al perfil persistente; Rebirth fuerza guardado inmediato.
- Rebirth 0 → 1 autoritativo: exige vuelta completa y Level 20, conserva Wins, reinicia la vuelta y activa multiplicador 1.5x.
- `StarterGui.StickyHUD` authored y editable en Explorer; `HUDController` únicamente enlaza y actualiza la plantilla.
- Panel authored de Rebirth con estado visible, requisito y botón; el cliente solo solicita y el servidor decide.
- Persistencia cloud verificada entre dos servidores con `Wins 1 / Rebirths 1` usando un almacén aislado de validación.
- Fallos de DataStore reproducibles mediante inyección limitada al mock de Studio; reintento y fallo terminal verificados.

### Objetos per-player (2026-08-03)

- Objetos privados por jugador: el servidor guarda los datos y el cliente renderiza sus propias instancias. Cero collectibles replicados desde el servidor.
- `ItemPlacementService`: slots válidos por sala calculados una vez, cacheados, con raycast a suelo, test de solapes y exclusiones alrededor de StartSpawn, puerta y blocker. Generación repartida en frames.
- `ItemPlanner`: módulo puro que reparte `TotalObjects` entre tipos y entre requisitos por resto mayor, garantizando el mínimo de objetos elegibles al entrar.
- `RoomSettingsReader`: lee la configuración authored del Workspace con fallback explícito a `GameConfig`.
- `RoomItemService`: una sesión por (jugador, sala) con una sola tarea de respawn por sesión.
- `PickupService`: valida sesión, requisito, distancia contra la posición del servidor, personaje vivo y rate limit por token bucket. Conserva el contrato `ConnectCollected`.
- Cliente: `CollectibleRenderer` (pool local de clones authored) y `CollectibleController` (un solo loop throttled de proximidad, sin `Touched` por objeto).
- `ObjectLabelController`: la elegibilidad se muestra atenuando los colores propios del prop (`IneligibleTintFactor`) y haciéndolo semitransparente (`IneligibleTransparency`), no con Highlights. Roblox solo renderiza 31 Highlights por cliente y no hay forma de subirlo, así que cualquier estado por objeto basado en ellos se rompe en silencio al crecer la sala. Queda un único Highlight como marca de "este es el que vas a agarrar".
- Plantillas authored en `ReplicatedStorage/Assets/Collectibles`: 9 props greybox y `_RequirementBillboard`.
- Configuración editable a mano por sala en `Zones/<Zone>/RoomSettings` y volumen `PlacementArea` por sala.
- `AttachmentService` reescrito: la pila pega un clon de **la misma plantilla que el jugador acaba de recoger**, no un cubo genérico. El tamaño se normaliza contra `TargetMaxSizeStuds` para que props de distinto tamaño authored se lean parecidos, y el prop conserva su color propio.
- Las soldaduras se reconstruyen al cambiar de paso de crecimiento, para que escalar un modelo multiparte no rompa las constraints.
- Límite de la pila subido de 30 a **36** slots (un anillo más, por debajo de la cabeza para no tapar la cámara). Al llenarse, cada nuevo pickup expulsa el más viejo y ocupa su slot, así que el jugador siempre lleva lo último que recogió.
- Dos animaciones cortas movidas por un único `Heartbeat` compartido: el objeto recogido vuela desde donde estaba hasta el cuerpo, y el expulsado se encoge y se desvanece en `Workspace.StickyDiscards`, desacoplado de la vida del personaje para que un reset a mitad del fundido no destruya una instancia del pool.
- `ClientMain` aísla el arranque de cada controlador con `pcall`: un fallo sigue avisando en consola pero ya no impide que arranquen los demás.
- **Los blockers absorbidos también se pegan al jugador.** `AttachmentService` clona el modelo authored del blocker desde el Workspace, más grande que un collectible (`BlockerSizeMultiplier`), y lo protege del reciclaje FIFO (`ProtectBlockerAttachments`). Solo hay 3 blockers por vuelta, así que cuesta 3 slots de 36 y conserva la lectura de "llevo puesta la puerta que rompí".
- El clon de un blocker se sanea antes de entrar al mundo: se le quitan los tags, los atributos `BlockerId`/`NextZoneId` y los `BillboardGui`. Sin eso, `BlockerController` descubriría la copia que lleva el jugador como si fuera un blocker real, porque escanea `Workspace` buscando el atributo `BlockerId`.
- `BlockerService.ConnectAbsorbed` emite una tabla interna con `Instance` y `Position` además del payload que va al cliente; el remoto no lleva la referencia a la instancia porque el cliente no la necesita.
- **Bug corregido:** `BlockerController` capturaba la lista de partes de un blocker una sola vez, al descubrir el Model. Un Model y sus partes no tienen por qué llegar al cliente en el mismo frame, así que una lista incompleta dejaba partes sin ocultar al absorber, y los pases de reintento se salían porque el registro ya existía. Ahora la lista se auto-repara con `refreshParts` en cada actualización y con `DescendantAdded`. Regla general para este proyecto: **no cachear listas de descendientes replicados sin una vía de reparación.**

### Pedestales de Win (2026-08-03)

- Pasillo corto authored después de la puerta de cada sala, en `Workspace/StuckToYou/Corridors/<Zona>Exit`: dos paredes laterales, una franja de suelo y el pedestal.
- El pedestal paga 1 / 3 / 10 Wins según la sala que se acaba de limpiar, y devuelve al jugador al inicio con la vuelta reiniciada. Pasar de largo conserva la vuelta y deja optar al pedestal mayor de la sala siguiente.
- `WinPedestalService` es data-driven por el tag `WinPedestal` y los atributos `ZoneId` y `WinReward`. El premio authored gana sobre el valor por zona de `GameConfig`.
- Solo paga si el jugador limpió esa zona en la vuelta actual (`CompletedZone_<ZoneId>`), con lock por jugador y debounce contra pagos dobles.
- `FinishService.ReturnToStart` centraliza reinicio y teletransporte; lo comparten el ReplayPad, el Rebirth y los pedestales.
- Las `PlacementArea` de Bedroom y Kitchen se recortaron para que no aparezcan objetos dentro de los pasillos.

### Todavía no implementado

- Confirmación manual con un jugador nuevo de que Toy Room dura 45–60 segundos.
- Prueba con 2 jugadores en la misma sala para el sistema per-player (pasos en `MANUAL_TEST_CHECKLIST.md`).
- Borrar `ServerScriptService.TempDiagnostics`, creado solo para verificar el sistema per-player.
- Analítica y revisión responsive del miércoles.

## Decisiones vigentes

- El documento nuevo del prototipo es la fuente de verdad del diseño.
- Solo existe un stat de run: Stickiness.
- El MVP usa 3 zonas; Neighborhood queda provisionalmente para semana 2.
- Los Sticky Wraps se desbloquean y equipan automáticamente por nivel, salvo que el usuario cambie esta decisión.
- No hay vida, daño, peso, banking de Wins ni obstáculos adicionales en el MVP.
- Todo premio y progreso se valida en servidor.
- Los números de balance viven en `GameConfig`, no dentro de servicios o UI.
- Los objetos visuales pegados tendrán un máximo inicial de 30.
- Toda UI y todo modelo/prop reutilizable nuevo debe existir como plantilla authored visible y editable en Studio; el código solo lo referencia, controla o clona.
- **Las Wins vienen de los pedestales, no de terminar la vuelta** (2026-08-03). Cada sala limpia pone un pedestal en el pasillo siguiente: pisarlo cobra y reinicia, pasarlo de largo arriesga la vuelta por el pedestal mayor. Por eso `GameConfig.Wins.AwardOnRunCompletion` está en `false` (si no, absorber el Refrigerator pagaría además de su pedestal) y `GameConfig.Finish.TeleportOnCompletion` también en `false` (si no, el jugador aparecería al otro lado del último pedestal y no podría cobrarlo). Ambos son flags reversibles.
- La FinishZone conserva su papel: es adonde llega quien pasa de largo el pedestal de 10, y sigue teniendo el ReplayPad y el panel de Rebirth.
- **Los objetos recolectables son privados por jugador** (decisión de diseño, 2026-08-03). Varios jugadores en la misma sala no se bloquean la progresión. Sustituye la nota anterior del plan que decía que los objetos serían compartidos durante la semana 1.
- El render de objetos vive en el cliente porque Roblox no permite filtrar la replicación de `Workspace` por jugador. El servidor sigue siendo dueño de todo el progreso y valida cada pickup contra su propia posición guardada.
- `TotalObjects` significa objetos visibles a la vez, no un total agotable por visita.
- El tipo de objeto es variedad visual, no balance. `GainMultiplier` queda reservado en `GameConfig.CollectibleTypes` para cuando diseño quiera usarlo.
- La configuración de cada sala se edita a mano en el Workspace (`RoomSettings`, `PlacementArea`); `GameConfig` solo aporta defaults. Un valor authored inválido cae al default con `warn` explícito, nunca en silencio.
- Los `ItemSpawns` authored se conservan sin uso, como red de seguridad para `PlacementMode = "Markers"`, y se ocultan en runtime.
- **No usar `Highlight` para estado por objeto.** Roblox renderiza como máximo 31 a la vez, los deshabilitados también ocupan slot, y no existe API para subir el límite (petición abierta en el DevForum desde 2021, sin respuesta a noviembre de 2024). Un tope por debajo de ese límite deja parte de la sala sin marcar, que se lee peor que no marcar nada. Para estado por objeto: atenuar los colores propios del prop. Los Highlight solo para elementos únicos, como el objeto enfocado.

## Reglas de trabajo acordadas

Las reglas completas y permanentes están en `AGENTS.md`; deben leerse al iniciar futuras sesiones de este proyecto.

1. Actualizar `PLAN_MVP.md` al terminar cada fase o subfase verificable.
2. Marcar un check únicamente después de comprobarlo en Studio.
3. Añadir notas breves de lo construido, pruebas realizadas, problemas y próximo paso.
4. Actualizar esta memoria cuando cambie una decisión técnica o de alcance.
5. Inspeccionar antes de editar para no sobrescribir trabajo existente.
6. Mantener nombres técnicos y código en inglés; documentación y comunicación en español.
7. No agregar features fuera del plan sin señalar primero el impacto en la semana.
8. Probar camino exitoso, rechazo y limpieza/reinicio siempre que sea posible.
9. Diseñar conexiones, tareas, tablas e instancias con límites y limpieza explícitos para evitar leaks.
10. Mantener servicios desacoplados y APIs pequeñas; balance y límites deben salir de configuración.
11. Favorecer módulos portables y documentar sus contratos para reutilizarlos en futuros juegos.
12. No construir UI permanente por código; crearla en `StarterGui` o en el contenedor authored correspondiente y enlazarla desde controladores.
13. No reconstruir geometría permanente por código; conservar modelos/props authored en el DataModel para poder colocarlos y editarlos manualmente.

## Jerarquía creada

```text
ReplicatedStorage/
  Shared/
    GameConfig
    CollectibleTemplates
    Remotes/
      PickupFeedback, BlockerFeedback, RebirthRequest, RebirthFeedback
      RoomItemsSync        -- servidor -> cliente: Load / Spawned / Consumed / Unload
      PickupRequest        -- cliente -> servidor: solo el id del objeto
  Assets/
    Collectibles/          -- plantillas authored que el cliente clona
      _RequirementBillboard
      ToyBlock, ToyBall, ToyCar
      Pillow, Sock, Book
      Apple, Mug, Plate
ServerScriptService/
  Server/
    DataService, ProgressionService, RoomService
    RoomSettingsReader     -- lee la config authored del Workspace
    ItemPlacementService   -- slots por sala, cacheados
    ItemPlanner            -- reparto equitativo, puro
    RoomItemService        -- sesión por (jugador, sala)
    PickupService          -- validación autoritativa del pickup
    AttachmentService, BlockerService, FinishService
  TempDiagnostics          -- TEMPORAL, borrar antes de publicar
StarterGui/
  StickyHUD/
    ProgressPanel
    RebirthPanel/RebirthButton
StarterPlayer/
  StarterPlayerScripts/
    Client/
      HUDController
      CollectibleRenderer  -- clones locales con pool
      ObjectLabelController-- billboard + Highlights pooled
      CollectibleController-- sync + loop de proximidad
      BlockerController
Workspace/
  StuckToYou/
    Zones/
      ToyRoom/
        Geometry/
        ItemSpawns/        -- solo para PlacementMode "Markers"; ocultos en runtime
        Collectibles/      -- ya sin uso
        Blockers/ToyChest
        StartSpawn
        PlacementArea      -- volumen invisible donde pueden caer objetos
        RoomSettings/      -- Configuration editable a mano
          TotalObjects, MinSeparationStuds, PlacementMode
          ObjectPool/      -- un ObjectValue por tipo permitido
```

## Contrato reusable — sistema de collectibles

### Componentes

- `ProgressionService`: estado de run y fórmula de ganancia; no conoce Parts ni UI.
- `CollectibleFactory`: construye la representación runtime; no otorga progreso.
- `CollectibleService`: descubre spawns por tag, valida contactos y concede progreso; delega toda disponibilidad a `SpawnService`.
- `ObjectLabelController`: presentación rojo/verde por jugador; no modifica estado de servidor.
- `HUDController`: observa atributos y feedback; no conoce la implementación interna de los servicios.
- `AttachmentService`: escucha el evento de colección y mantiene la representación soldada; no concede Stickiness.

### Requisitos para portarlo a otro juego

1. Copiar los cinco módulos/controladores y el bootstrap correspondiente.
2. Proveer en `GameConfig` las secciones `Tags`, `Network`, `PlayerDefaults` y `Collection`.
3. Crear un RemoteEvent con el nombre configurado en `Network.PickupFeedbackRemote`.
4. Etiquetar spawn markers con `ItemSpawn` y darles attributes `ZoneId` y `RequiredStickiness`.
5. Cada carpeta de spawns requiere una carpeta hermana `Collectibles` para las instancias runtime.

La representación puede reemplazarse editando `CollectibleFactory`; las reglas de progreso pueden cambiarse en `ProgressionService`; ninguno de esos cambios requiere reescribir el otro sistema.

## Contrato reusable — salas y pool de spawns

### Componentes

- `RoomService`: registra zonas tagged, valida su estructura y expone configuración/folder por `ZoneId`; no conoce pickups ni progreso.
- `SpawnService`: mantiene handles lógicos, objetivo activo, reservas, cooldown y selección balanceada; no crea Parts ni otorga Stickiness.
- `CollectibleService`: adapta cada Part runtime a un handle mediante un callback `SetActive`.

### Contrato de una zona

El Folder necesita tag `StickyZone`, attribute `ZoneId`, entrada correspondiente en `GameConfig.Zones` y folders hijos `Geometry`, `ItemSpawns`, `Collectibles` y `Blockers`. Cada zona configura `EntryStickiness`, `CollectibleRequirements` y `ActivePickupTarget`.

### Garantías verificadas

- Un solo pool compartido por zona, con conteos acotados por los markers authored.
- No se clonan ni destruyen collectibles durante el respawn; solo cambia su estado activo.
- La selección inicial prioriza el mínimo de objetos elegibles y conserva una reserva cuando el contenido lo permite.
- La reposición excluye el handle recién consumido, rota hacia otra instancia y restaura el objetivo activo tras el cooldown.
- Las tareas diferidas se cancelan al retirar un handle o destruir el servicio.

## Contrato reusable — pila visual

### Entradas

- Evento interno de colección con `CollectibleId`, `ZoneId` y `RequiredStickiness`.
- Character estándar con `UpperTorso`, `Torso` o `HumanoidRootPart`.
- Configuración `Attachments` con rings cuyo total coincida con `MaxVisualAttachments`.

### Garantías

- Máximo de 30 records y partes activas por jugador, configurable.
- Todas las partes son massless y no participan en collision, touch o query.
- Slots deterministas; ningún offset aleatorio puede tapar la cámara de forma impredecible.
- Limpieza en `CharacterRemoving`, `PlayerRemoving` y `Destroy()`.
- Pool libre acotado; nunca crece por encima de `PoolCapacity`.
- Los pickups posteriores al límite solo cambian un contador escalar acotado y actualizan tamaños en un máximo de cinco ocasiones.

### Para portarlo

Copiar `AttachmentService`, proporcionar un origen de eventos compatible y reemplazar únicamente `GameConfig.Attachments`. El servicio no depende de Toy Room, Stickiness como fórmula, HUD ni persistencia.

## Contrato reusable — blockers por jugador

### Componentes

- `PlayerCharacterUtil`: validación común de contacto, Character, Humanoid y distancia.
- `BlockerService`: valida requisito y guarda completitud por jugador; no modifica geometría global.
- `BlockerController`: presenta elegibilidad y absorción local; no concede progreso.
- `HUDController`: consume feedback y el nuevo `CurrentZoneId`.

### Contrato del objeto

El objeto etiquetado como `StickinessBlocker` necesita attributes:

```text
BlockerId
ZoneId
NextZoneId
RequiredStickiness
```

Puede ser Model o BasePart. El servidor conecta sus BaseParts, evita completados duplicados y mantiene el blocker intacto para otros jugadores. Para portarlo, se reemplaza `GameConfig.Blockers`, la fuente de progreso y el comportamiento visual cliente.

El cliente conserva el aspecto authored para restaurarlo después de un reset, pero pinta todas las piezas con `IneligibleColor` o `EligibleColor` según el progreso local. El descubrimiento inicial usa tres pases finitos durante 2.5 s y se cancela en `Destroy()`; no existe polling permanente.

## Contrato reusable — cierre y replay de una vuelta

- `FinishService` escucha `BlockerService.ConnectAbsorbed`; no conoce Parts de Refrigerator ni concede progreso desde el cliente.
- `GameConfig.Finish` define blocker/zona final, nombres de spawns, delay, debounce y distancias. Cambiar la ruta no exige editar el servicio.
- `ProgressionService.AwardWin` solo modifica el dominio de progreso; la idempotencia por vuelta pertenece a `FinishService` y se activa antes de premiar.
- `AttachmentService.ClearPlayerVisuals` y `BlockerService.ResetPlayerRun` permiten reiniciar sin destruir el character ni duplicar lógica privada.
- El folder físico de Finish requiere `FinishSpawn` y `ReplayPad`; no necesita tag `StickyZone` porque no administra un pool de collectibles.
- Las conexiones, locks, cooldowns y threads diferidos se limpian en `PlayerRemoving`, `CharacterAdded` y `Destroy()`.

## Registro de trabajo

### 2026-08-03 — Lunes, Bloque 1

- Estado inicial: lugar vacío, sin scripts; solo objetos predeterminados.
- Construcción: estructura mínima, GameConfig y Toy Room en greybox.
- Validación: módulo requerido con éxito; assertions de Level, Wrap, Rebirth y conteo de tags superadas.
- Próximo paso exacto: crear collectibles desde los 12 spawn markers e implementar pickup autoritativo con debounce y respawn de 2 segundos.

### 2026-08-03 — Lunes, Bloque 2

- Construcción: servicios de progreso y collectibles, factory runtime, HUD, feedback y labels por jugador.
- Pruebas: arranque sin errores; 12 collectibles presentes; pickup elegible; rechazo por requisito; actualización HUD/Level; rojo/verde; respawn de 2 s; teardown limpio al salir de Play.
- Seguridad: ningún RemoteEvent concede progreso; el premio nace únicamente de una validación server-side de `Touched`.
- Ciclo de vida: conexiones rastreadas, cooldown por Player limpiado en `PlayerRemoving`, threads de respawn cancelables y tablas acotadas a jugadores/spawns activos.
- Próximo paso exacto: implementar pila visual mediante un `AttachmentService` independiente, con slots configurados, pool/reuso, reset seguro y máximo de 30 objetos.

### 2026-08-03 — Lunes, Bloque 3

- Construcción: evento interno de colección, `AttachmentService`, 30 slots por rings, pool de 60 y crecimiento acotado tras el límite.
- Pruebas: pickup real, propiedades físicas, welds, slots únicos, stress hasta 30 piezas/Stickiness 175, navegación con pila completa, reset y reuso del pool.
- Resultado de reset: Stickiness 0, Level 1, visuals 0, growth 0 y 30 piezas recuperadas.
- Teardown: Studio volvió a Edit sin instancias runtime ni errores del juego.
- Próximo paso exacto: implementar el blocker reutilizable, hacer que Toy Chest cambie a verde en 50 y abra la salida al absorberse; después medir y ajustar la duración.

### 2026-08-03 — Lunes, cierre

- Construcción: `PlayerCharacterUtil`, `BlockerService`, `BlockerController`, RemoteEvent de feedback y `ExitPreview`.
- Pruebas: rechazo en 0, estado verde en 54, absorción de las tres partes, salida transitable, servidor intacto para otros jugadores, reset completo y consola limpia.
- Bug encontrado: el registro cliente podía adelantarse a la replicación de descendientes. El retry inicial de 0.5 s fue insuficiente en el playtest manual y después se reforzó con descubrimiento por attributes.
- Medición: ruta óptima con WalkSpeed normal completada en 42.1 s y 36 movimientos de pickup. Se espera 45–60 s para una persona nueva, pendiente de comprobación manual.
- Próximo paso exacto: ejecutar `MANUAL_TEST_CHECKLIST.md`; si Toy Room queda fuera de 45–60 s, tocar únicamente valores de `GameConfig` o distribución de spawn markers antes de iniciar el martes.

### 2026-08-03 — Corrección de blocker visual

- Síntoma reportado manualmente: `ZONE OPEN!` funcionaba, pero Toy Chest no cambiaba a verde ni desaparecía.
- Diagnóstico: carrera de replicación exclusivamente cliente; `BlockerService` y el estado server-side estaban correctos.
- Causa raíz: el retry único de 0.5 s no garantizaba que tag, attributes y BaseParts estuvieran disponibles juntos.
- Solución: `BlockerController` usa descubrimiento por `BlockerId` como fallback en inicio, cambio de Stickiness y evento de absorción.
- Coste: un scan inicial; no hay polling permanente. Los scans adicionales solo ocurren mientras `records` está vacío.
- Pruebas: ciclo completo de absorción/reset y dos reinicios adicionales; tres inicializaciones correctas, consola limpia.

### 2026-08-03 — Martes, fase 1

- Construcción: `RoomService`, `SpawnService`, tag `StickyZone`, `EntryStickiness` por zona y orden explícito de inicialización/teardown en `Main`.
- Refactor: `CollectibleService` dejó de controlar timers y disponibilidad; ahora consume/restaura handles del pool y conserva la autoridad sobre la concesión de progreso.
- Balance authored de Toy Room: 12 markers, 10 activos, 2 reservas y 4 accesibles a Stickiness 0; `Spawn_09` es la reserva accesible.
- Pruebas: arranque sin errores, pickup real, conteo constante de 12 instancias, retorno a 10 activas y restauración de 4 elegibles después del cooldown.
- Bug encontrado por prueba: la primera selección podía escoger otra vez el handle consumido. Solución: parámetro `excludedHandle` en la selección de reemplazo; regresión de rotación superada.
- Alcance protegido: `Lobby` permanece fuera del tag `StickyZone` y su geometría no fue modificada.
- Próximo paso exacto: construir Bedroom y Kitchen con el mismo esquema, colocar sus 12 markers y blockers, y verificar cada zona antes de conectar la vuelta completa.

### 2026-08-03 — Martes, fase 2

- Construcción: Bedroom y Kitchen lineales, paletas greybox distintas, ruta visible, 12 markers por sala, Bed y Refrigerator tagged/configurados.
- Balance: cinco markers del tier de entrada permiten cuatro activos más una reserva; cada pool mantiene objetivo 10 sin churn.
- Ruta probada con gameplay real: `51 → ToyChest → Bedroom → 183 → Bed → Kitchen → 503/Level 20/CosmicGlue → Refrigerator → FinishZone`.
- Rechazo: Bed a 0 no cambió progreso, completitud ni zona.
- Reset: progreso, wrap, zona, pile y los tres blockers regresaron a estado inicial.
- Corrección: estado inelegible ahora pinta el blocker completo en rojo; tres reintentos iniciales acotados resuelven la carrera de replicación con varias salas.
- Teardown: las tres carpetas `Collectibles` quedaron vacías en Edit; no persistieron instancias runtime.
- Alcance protegido: `Lobby` fue modificado en paralelo por el usuario y se mantuvo completamente fuera de nuestras escrituras.
- Próximo paso exacto: crear FinishZone físico, otorgar una sola Win al completar Refrigerator y reiniciar la vuelta sin duplicar premios.

### 2026-08-03 — Martes, fase 3

- Construcción: FinishZone físico, `FinishService`, resumen de run por atributos, Win visible en HUD y ReplayPad.
- Arquitectura: `FinishService` depende de contratos públicos pequeños; todo identificador, delay, distancia y nombre de punto sale de `GameConfig.Finish`.
- Idempotencia: el estado por jugador se bloquea antes de `AwardWin`; cinco contactos repetidos con Refrigerator mantuvieron Wins en 1.
- Pruebas: rechazo del pad antes de completar; ruta real completa hasta 503/Level 20/CosmicGlue; Win, resumen, pile clear y teleport; rechazo final tras reset; replay completo y nuevo pickup; muerte/respawn conservando Wins.
- Ciclo de vida: threads de teleport cancelables, conexiones y tablas limpiadas por jugador y en `Destroy`; no hay polling ni instancias runtime persistentes al volver a Edit.
- Presentación: los tres blockers se restauran rojos después del replay y el HUD muestra `WINS` desde atributos replicados.
- Alcance protegido: FinishZone no se etiqueta como `StickyZone` y `Lobby` permaneció fuera de las escrituras aunque siguió cambiando por colaboración en vivo.
- Próximo paso exacto: cerrar el tutorial ambiental de una línea y ejecutar diez vueltas para registrar duración por zona y ajustar solo configuración/balance.

### 2026-08-03 — Martes, fase 4

- Construcción: tutorial ambiental no bloqueante frente al spawn; se conservaron las franjas amarillas de navegación existentes.
- Corrección de medición: `BlockerService` separa `zoneStartedAtByPlayer` de `runStartedAtByPlayer`; el evento entrega `ZoneSeconds` y `RunSeconds`.
- Stress: 10/10 vueltas reales de física, 10 Wins exactas, 10 replays y estado final limpio en el mismo servidor.
- Tiempos acelerados min/prom/max: Toy `10.53/11.66/13.63 s`, Bedroom `8.88/9.80/10.72 s`, Kitchen `6.13/6.82/7.62 s`, total `27.20/28.28/29.28 s`.
- Pools después del stress: tres veces `12 total / 10 activos`; pile 0, Stickiness 0, Level 1 y blockers rojos/visibles.
- Decisión de balance: no ajustar con tiempos de teletransporte automatizado. La meta humana de 3–5 min y Toy Room 45–60 s continúa como prueba manual explícita.
- Teardown: Collectibles runtime 0 en las tres salas, consola limpia y Studio en Edit. `Lobby` permaneció fuera de las escrituras.
- Próximo paso exacto: persistencia server-side de Wins/Rebirths y flujo Rebirth 0 → 1 con pruebas de fallo, reconexión simulada y cierre seguro.

### 2026-08-03 — Miércoles, fase 1

- Construcción: `DataService`, configuración de perfil, remotes de Rebirth, validación server-side y guardado inmediato de Rebirth.
- UI authored: `StarterGui.StickyHUD` contiene el HUD existente y el nuevo `RebirthPanel`; `HUDController` dejó de crear la jerarquía visual por código.
- Prueba de rechazo: solicitud al inicio no mutó Rebirths, Stickiness ni estado de vuelta.
- Prueba exitosa: ruta física completa hasta `503 / Level 20 / Win 1`; Rebirth conservó la Win, produjo `Rebirths 1`, reseteó run/zone/pile y guardó `Wins 1 / Rebirths 1` en el backend mock.
- Multiplicador: el primer pickup Basic Glue posterior otorgó `+1.5` real.
- Regresiones corregidas: señal de carga perdida entre consulta y espera; zona lógica incorrecta después de Rebirth; warning de espera no acotada al clonar el HUD authored.
- Teardown: Studio volvió a Edit sin collectibles runtime. El smoke final arrancó sin errores ni warnings propios.
- Limitación explícita: no se habilitó acceso cloud desde Studio; falta validar salida/reentrada contra DataStore real y fallo de API antes de marcar el bloque completo de datos como cerrado.
- Próximo paso exacto: ejecutar prueba cloud controlada de persistencia/reconexión y luego continuar con 3–6 clientes simulados.

### 2026-08-03 — Miércoles, fase 2

- Cloud: acceso existente confirmado mediante `GetAsync` de solo lectura; no se cambiaron ajustes del place.
- Datos faltantes: un perfil nuevo en el store aislado cargó defaults sin error.
- Persistencia/reconexión: el primer servidor guardó `Wins 1 / Rebirths 1`, liberó la sesión al cerrar y el segundo servidor recuperó los valores exactos con multiplicador 1.5x.
- Respawn: muerte y character nuevo conservaron únicamente los datos persistentes; Stickiness, Level, zona, pile y estado de vuelta quedaron reiniciados.
- Fallos: con dos errores mock la carga tuvo éxito en el tercer intento; con tres errores agotó el límite, marcó `DataLoadFailed` y no creó un estado guardable con defaults.
- Configuración final restaurada: store de producción, mock habilitado solo en Studio e inyección de fallos en cero.
- Smoke final: perfil mock cargado, servicios inicializados sin errores y Studio devuelto a Edit.
- Próximo paso exacto: ejecutar test local con 3–6 clientes y medir carreras de touch, disponibilidad por zona y limpieza por jugador.
