# Stuck to You — Memoria de proyecto

Este documento guarda el estado técnico y las decisiones que necesitamos recordar entre sesiones. El alcance y los checks diarios siguen viviendo en `PLAN_MVP.md`.

## Estado actual

**Última actualización:** 2026-08-13
**Lugar de Roblox Studio:** `Exposición pegajosa`  
**Modo verificado:** Edit  
**Fase:** arquitectura mobile-first de attachments implementada y probada con un cliente. El
servidor conserva 300 records lógicos y no crea geometría cosmética; cada cliente renderiza hasta
110 propios y 20 por remoto, con cap 320 `[PLACEHOLDER hasta Android]`. Los cambios están en el
DataModel abierto, no guardados/publicados. La prueba real de 2/8 jugadores y Android sigue pendiente.

### Contrato vigente de attachments (reemplaza contratos históricos posteriores)

- Autoridad: `ServerScriptService.Server.AttachmentService`, capacidad lógica 300.
- Presentación: `StarterPlayer.StarterPlayerScripts.Client.AttachmentRenderer`, client-local.
- Assets authored: `ReplicatedStorage.Assets.AttachmentProxies`, 29 modelos de una parte.
- Registry: `ReplicatedStorage.Shared.AttachmentProxyTemplates`.
- Red visual: `ReplicatedStorage.Shared.Remotes.AttachmentVisual`, protocolo v1.
- Conteo canónico: `LogicalAttachmentCount`; `VisualAttachmentCount` es alias de compatibilidad.
- Presupuestos iniciales: own 110, remote 20, created cap 320, show/hide 90/110 studs.
- El clear usa generation isolation y release amortizado; un visual solo transiciona
  `Active → Queued → Pooled/Destroyed`.
- Ningún sistema de progreso consulta proxies locales.

Las referencias posteriores a pila server-side, 30/36 visuals, `Rings`, pool server o growth
describen iteraciones históricas y no deben usarse como contrato actual.

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
- Stickiness, Level y Sticky Wrap replicados mediante atributos del jugador. Los tres son progreso del ciclo de Rebirth: sobreviven a cobrar en un pedestal, al ReplayPad y a morir, y **solo el Rebirth los reinicia**.
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
- Rebirth autoritativo y **repetible** (2026-08-06): pide solo el level cap, conserva Wins, reinicia la vuelta, sube el techo 5 niveles y suma `+0.5x` permanente.
- `StarterGui.StickyHUD` authored y editable en Explorer; `HUDController` únicamente enlaza y actualiza la plantilla.
- Botón de Rebirth en el HUD y pantalla modal authored (`RebirthScreen`) con antes/después, barra de progreso y motivo de bloqueo; el cliente solo solicita y el servidor decide.
- Persistencia cloud verificada entre dos servidores con `Wins 1 / Rebirths 1` usando un almacén aislado de validación.
- Fallos de DataStore reproducibles mediante inyección limitada al mock de Studio; reintento y fallo terminal verificados.

### Sistema de mundos (2026-08-13)

- `GameConfig.Worlds`: cada mundo declara su lobby, su sala inicial, su FinishZone y su último blocker. La cadena de salas la sigue definiendo `NextZoneId`; el mundo solo dice dónde empieza y dónde acaba.
- Cada entrada de `GameConfig.Zones` lleva `WorldId`. `GetWorldZones`, `GetWorldOfZone` y `ResolveWorld` derivan todo lo demás.
- Requisitos de desbloqueo como catálogo (`GameConfig.WorldRequirements`) y mapa por mundo. `EvaluateWorldRequirements` la usan servidor y cliente, así que la pantalla nunca puede prometer algo que el servidor rechace.
- `WorldRegistry` (mapa mundo → instancias) y `WorldService` (portal, remotes, viaje). Las reglas y la persistencia viven en `ProgressionService`.
- Perfil: `CurrentWorldId`, `UnlockedWorldIds` y `TotalWinsEarned`.
- Portal authored en cada lobby, tag `WorldPortal` y atributo `WorldId`; abre `StickyHUD.WorldScreen`, con filas clonadas de `_WorldRow`.
- Mundo 2 completo en el editor: lobby con sus 8 placas de wrap y 7 de descanso, 10 salas, 10 pasillos con pedestal y FinishZone, desplazados `+900` en X y retintados.
- Botón temporal de desbloqueo (`GameConfig.WorldTravel.DebugUnlockEnabled`), con aviso en consola al arrancar.

### Objetos per-player (2026-08-03)

- Objetos privados por jugador: el servidor guarda los datos y el cliente renderiza sus propias instancias. Cero collectibles replicados desde el servidor.
- `ItemPlacementService`: slots válidos por sala calculados una vez, cacheados, con raycast a suelo, test de solapes y exclusiones alrededor de StartSpawn, puerta y blocker. Generación repartida en frames.
- `ItemPlanner`: módulo puro que reparte `TotalObjects` entre tipos y entre requisitos por resto mayor, garantizando el mínimo de objetos elegibles al entrar.
- `RoomSettingsReader`: lee la configuración authored del Workspace con fallback explícito a `GameConfig`.
- `RoomItemService`: una sesión por (jugador, sala) con una sola tarea de respawn por sesión.
- `PickupService`: valida sesión, requisito, distancia contra la posición del servidor, personaje vivo y rate limit por token bucket. Conserva el contrato `ConnectCollected`.
- Cliente: `CollectibleRenderer` (pool local de clones authored) y `CollectibleController` (un solo loop throttled de proximidad, sin `Touched` por objeto).
- `ObjectLabelController`: la elegibilidad se muestra atenuando los colores propios del prop (`IneligibleTintFactor`) y haciéndolo semitransparente (`IneligibleTransparency`), no con Highlights. Roblox solo renderiza 31 Highlights por cliente y no hay forma de subirlo, así que cualquier estado por objeto basado en ellos se rompe en silencio al crecer la sala. Queda un único Highlight como marca de "este es el que vas a agarrar".
- Plantillas authored en `ReplicatedStorage/Assets/Collectibles`: 9 props greybox y `_RequirementBillboard`. La tarjeta se dimensiona en studs (`Size = {2.6, 0}, {1.27, 0}`), con `AlwaysOnTop = false` y `MaxDistance = 50`.
- Plantillas authored de gratificación en `ReplicatedStorage/Assets/Feedback`: `Audio/` (`Pickup`, `Denied`, `LevelUp`, `Absorb`, `Rebirth`, `RestTick`, `WinClaim`, `UIClick`, `StickyGain`, `Purchase`, `Equip`), `Particles/` (`PickupBurst`, `AbsorbBurst`) y `UI/_ScorePopup`. `FeedbackController` solo las clona y dispara; los pools y los tiempos viven en `GameConfig.Feedback`.
- Audio definitivo (agosto 2026): se sustituyeron los placeholders de ProSoundEffects por los assets propios con permisos concedidos. `Denied` y `RestTick` conservan su placeholder a propósito. `StickyGain` (ingreso de stickiness) suena **encima** de `Pickup` a `Volume 0.10`: son dos capas del mismo golpe, el objeto pegándose y lo que produce, y sólo `Pickup` sube de tono con el combo. `Purchase` y `Equip` son canales nuevos: antes comprar sonaba como absorber y equipar como subir de nivel, así que la tienda no tenía voz propia. `FeedbackController` escucha ahora también `CosmeticFeedback`, porque Trails y Auras se compraban y equipaban en silencio.
- Pasada de iluminación: `ColorGrade` (`ColorCorrectionEffect`, `Saturation 0.28`), `Bloom` con `Threshold 1.15`, `Atmosphere` con `Haze 0.7`, ambiente azulado. `Lighting.Technology` no se puede escribir desde el command bar (requiere capacidad `RobloxScript`); ponerla a `Future` es un paso manual pendiente.
- El Sticky Wrap equipado se lee por color: el `+N` de cada recogida usa el `Color` del wrap, el nombre en el HUD va del mismo color vía `RichText` y la tienda pinta una franja con él. Al equipar uno mejor sale su nombre como popup; bajar de wrap a propósito no se celebra. Ver `GameConfig.Feedback.TintPopupWithWrapColor`.
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
- Analítica y revisión responsive del miércoles.
- Poner `Lighting.Technology` en `Future` a mano: la propiedad no se puede escribir desde el command bar.

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
- **Un solo modo de colocación** (2026-08-05). Se retiraron `PlacementMode`, los modos `Markers`/`Hybrid` y los 36 marcadores `ItemSpawns`. Nunca se usaron: las tres salas siempre estuvieron en `Procedural`. Mantener dos rutas de colocación sin datos era complejidad que había que leer y explicar cada vez. Si diseño quiere colocar objetos a mano en el futuro, se reimplementa.
- **`0 slots` en una sala casi siempre significa que falta el suelo dentro de su propia `Geometry`** (2026-08-05). El raycast de `ItemPlacementService` usa un filtro `Include` limitado a la carpeta `Geometry` de esa zona. Si el suelo se borra, se renombra o se mueve a otra carpeta, no hay nada que golpear y la sala produce cero posiciones, con el aviso `ItemPlacement: <Zona> produced 0 slots`. El jugador sigue caminando porque debajo está el `Baseplate`, que no cuenta para la colocación. Antes de tocar `TotalObjects` o `MinSeparationStuds`, comprobar que `Zones/<Zona>/Geometry/Floor` existe.
- **El audio sale de ProSoundEffects, no de lo más popular del Creator Store** (2026-08-05). Buscando SFX, casi todos los resultados mejor posicionados son rips con copyright (Mario Kart, Undertale, Sonic, Earthbound). Usarlos es riesgo de moderación al publicar. `ProSoundEffects` es la biblioteca licenciada que Roblox distribuye gratis, viene descrita y con duración, y es la fuente por defecto de este proyecto.
- **El texto de un `BillboardGui` se mide una sola vez y se puede quedar en cero** (2026-08-05). Si Roblox dispone la etiqueta cuando el billboard todavía no tiene tamaño en pantalla, calcula `TextBounds = 0,0` y **no vuelve a medir**: la tarjeta pinta su fondo pero nunca sus dígitos. Es la causa real del "panel negro sin texto", y también de que el cartel del pedestal de Win saliera mudo al construirlo a mano. Reactivar `TextScaled` fuerza el reescalado; `ObjectLabelController.healLabel` lo hace por tick sobre las tarjetas que tengan tamaño pero medida cero.
- **`TextScaled` y `TextWrapped` van juntos: apagar el segundo apaga el primero en silencio** (2026-08-05). Poner `TextWrapped = false` en una etiqueta con `TextScaled = true` deja `TextScaled = false` sin avisar, y el texto cae al `TextSize` de la plantilla (8 px aquí), o sea ilegible. Al tocar una de las dos, comprobar siempre la otra.
- **Las tarjetas de requisito se dimensionan en studs, nunca en píxeles** (2026-08-05). El `Size` de un `BillboardGui` en Offset conserva su tamaño en píxeles a cualquier distancia: con 24 objetos por sala las tarjetas lejanas quedan igual de grandes que las cercanas, se apilan en pantalla y, como el fondo del `TextLabel` es opaco, una tapa el número de otra y deja un rectángulo negro sin cifra. Con `Size` en Scale (studs) la tarjeta se aleja junto con su objeto. Además `AlwaysOnTop = false`, para que al solaparse gane la más cercana en vez de un orden de dibujado arbitrario en el que una tarjeta lejana tapa a una cercana. Medido en el peor caso (cámara a ras de suelo mirando la sala entera): 15 parejas solapadas antes, 3 después, y ninguna deja una tarjeta sin número.
- **Un mundo es un lobby más su cadena de salas, y nada más** (2026-08-13). No hay "modo mundo 2": las mismas reglas, los mismos servicios y los mismos pads, con otra escala. Lo único que un mundo aporta es dónde se empieza, dónde se acaba y qué hace falta para entrar.
- **El progreso viaja con el jugador; el mundo no lo reinicia.** Viajar no toca Stickiness, Level ni Wrap: solo reposiciona la zona lógica, limpia los blockers de la vuelta y teletransporta. Sigue siendo cierto que **solo el Rebirth reinicia la Stickiness**, y renacer devuelve a la primera sala **del mundo en el que estás**, no al mundo 1.
- ~~**Los requisitos de mundo se miden contra Wins ganadas de por vida (`TotalWinsEarned`), no contra el saldo** (2026-08-13)~~ — **revertido el 2026-08-19 por petición de diseño.**
- **Las Wins de un mundo son un precio, no una marca histórica** (2026-08-19). Se miden contra el **saldo** (`Wins`) y se **cobran** al desbloquear, exactamente igual que un Sticky Wrap o un cosmético: si un mundo cuesta 2.500, hay que tenerlas en ese momento y desaparecen al abrirlo. Consecuencia directa: **el desbloqueo dejó de ser automático**. Cobrar solo, en el instante en que el saldo cruza el precio, le vaciaría las Wins a quien las estaba ahorrando para un wrap; ahora el jugador pulsa `UNLOCK` en la pantalla del portal y el servidor cobra en `ProgressionService.TryUnlockWorld`. Lo que ya se abrió sigue siendo permanente: gastar Wins después no vuelve a cerrar nada. `GameConfig.WorldRequirements` distingue los dos tipos con `Spend`: puerta (`Rebirths`, se comprueba) y precio (`WinCost`, se cobra). `RefreshWorldUnlocks` solo concede los mundos **sin precio**. `TotalWinsEarned` se sigue guardando y replicando como histórico, pero ya no decide ningún desbloqueo.
- **El nivel requerido para el Rebirth es también el nivel máximo** (2026-08-19). Al alcanzar el techo del Rebirth actual, el Level deja de subir hasta renacer, y la barra del HUD lo dice (`Level N MAX` / `REBIRTH!`, barra llena). Es claridad, no balance: el jugador ve sin ambigüedad que ya cumple el requisito. La **Stickiness sí sigue subiendo** por encima, y tiene que hacerlo — los blockers de las últimas salas piden mucho más que el último umbral de nivel del ciclo. Los perks (velocidad, radio) se congelan con el Level porque se calculan desde él. Un solo sitio decide el techo: `GameConfig.ClampLevelToCap`, que usa el servidor en `refreshLevel` y el HUD para saber cuándo pintar `MAX`.
- **La primera sala de cada mundo empieza en requisito 0.** Un jugador recién renacido llega con Stickiness 0; si la sala inicial del mundo 2 pidiera 500 se quedaría encerrado, sin nada que recoger, hasta volver al mundo 1 a pie.
- **El `SpawnLocation` de los mundos que no son el inicial va desactivado.** Uno habilitado entra en el sorteo de Roblox y mandaría allí a jugadores que no han desbloqueado el mundo. Quien viaja o reaparece lo coloca `WorldService` por teleport, con dos vías (cambio de atributo y `CharacterAdded`) porque el orden entre "carga el perfil" y "aparece el personaje" no está garantizado.
- **`GameConfig` y el Workspace llevan divergiendo en el mundo 1, y manda el Workspace** (2026-08-13). Los blockers piden lo que dice su atributo `RequiredStickiness` (`25/150/450/1000/2500/6000/10000/14000/20000/50000`), no el `BlockerRequiredStickiness` de `GameConfig.Zones` (`50/180/…/4000`); igual con `WinReward`. El único consumidor del valor de config es `HUDController`, así que **hoy la barra del HUD miente en el mundo 1**. En el mundo 2 los dos números se pusieron a coincidir a propósito. Pendiente de decidir si se alinea el mundo 1.
- **No usar `Highlight` para estado por objeto.** Roblox renderiza como máximo 31 a la vez, los deshabilitados también ocupan slot, y no existe API para subir el límite (petición abierta en el DevForum desde 2021, sin respuesta a noviembre de 2024). Un tope por debajo de ese límite deja parte de la sala sin marcar, que se lee peor que no marcar nada. Para estado por objeto: atenuar los colores propios del prop. Los Highlight solo para elementos únicos, como el objeto enfocado — y para los **blockers**, que son tres por vuelta (ver la nota de props reales).
- **El nombre de la plantilla es el único identificador de un objeto** (2026-08-19). No hay ids paralelos: el `Name` de la plantilla en `ReplicatedStorage/Assets/Collectibles` es lo que apunta el `ObjectValue` del pool de la sala, lo que viaja como `TemplateName` en la recogida y lo que busca `AttachmentService` como `ProxyKey` en `Assets/AttachmentProxies`. Una plantilla que no está declarada en `GameConfig.CollectibleTypes` funciona igual, como variante visual con `GainMultiplier = 1`. Añadir un prop es: plantilla en `Collectibles`, proxy con el mismo nombre en `AttachmentProxies`, y un `ObjectValue` en el pool de la sala. Ningún servicio cambia.
- **Cuánto se encoge un objeto al pegarse lo decide el propio prefab** (2026-08-19). `Assets/AttachmentProxies/<Prop>/AttachmentScale` es un NumberValue en [0, 1]: la fracción de su tamaño original con la que se pega. **No toca el tamaño con el que aparece en la sala**, y esa separación es justo lo que pedía diseño — los props reales se ven grandes en el suelo y razonables en la pila. `Model:ScaleTo(0)` es inválido, así que el 0 del diseño se traduce a `MinimumAttachmentScale = 0.005`. Un proxy sin el valor conserva el comportamiento viejo (la escala sale del tramo de requisito en `ScaleTiers`), que es lo que mantiene vivos los placeholders de W2 y W3.
- **Toda plantilla de coleccionable tiene el pivote donde el objeto toca el suelo**, no en su centro (2026-08-19). Con props de hasta 40 studs no hay alternativa: un pivote central entierra medio árbol, porque el punto del slot es el mismo para un árbol que para una bellota. `GameConfig.Collection.SpawnGroundDrop` baja el visual la altura del slot para que se apoye; la posición **lógica** del objeto no se mueve, así que el radio de recogida es el de siempre.
- **Los proxies de pegado dejaron de ser de una sola parte** (2026-08-19). Eran cubos sustitutos; ahora son los props de verdad, con malla y detalle. Se admiten hasta `MaxPartsPerProxy` y `AttachmentRenderer` suelda las partes extra a la principal una sola vez, al crear el clon. **Anclar y desanclar es una operación sobre toda la pieza**: una sola parte anclada deja el ensamblaje entero anclado y la pieza se queda flotando donde nació.
- **Un prop con `SurfaceAppearance` puede ignorar `Color`** (2026-08-19). Si trae ColorMap, escribirle el color no pinta nada y el rojo/verde de "puedo o no puedo" muere en silencio. Por eso cada puerta del mundo 1 lleva un `StateHighlight` authored y `BlockerController` escribe **los dos canales**: el `Color` de las partes (único canal de los blockers greybox de W2/W3) y el Highlight cuando existe.
- **El tamaño del prop manda sobre cuántos caben en una sala.** Una sala mide 62 × 70 studs. `ItemPlacementService` avisa él solo (`produced N slots but the room asks for M objects`) y ese aviso es el criterio, no la intuición: con props medianos las salas bajaron de 32 a 20 objetos y la de props grandes a 10. **Es una bajada real de objetos por vuelta**; la palanca para recuperarla es agrandar la `PlacementArea`, no bajar la separación.

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
    AttachmentService, BlockerService, FinishService, WinPedestalService
    WorldRegistry          -- mundo -> instancias del mapa (lobby, spawns, ReplayPad)
    WorldService           -- portal, remotes de viaje y bypass temporal
StarterGui/
  StickyHUD/
    StatsPanel/                    -- bloque central abajo, todo en Scale
      BlockerProgress              -- "TOY CHEST 7 / 50"
      Stickiness                   -- numero grande abreviado
      WrapLabel                    -- pegamento equipado en su color, con su +N
      MultiplierLabel              -- "x1.5 Stickiness (Rebirths)"
      LevelBar/Fill+LevelText+AmountText
      BoostRow/Boost1..Boost4      -- placeholder, sin dev product detras
    CounterStack/                  -- arriba-izquierda, como la referencia
      RebirthCounter/Icon+Amount
      WinsCounter/Icon+Amount
    PickupFeedback
    RebirthOpenButton/ReadyBadge   -- abre la pantalla; el punto se enciende si hay Rebirth
    RebirthScreen/Window/          -- modal authored: Title, CloseButton,
                                   -- MultiplierBefore/Arrow/After,
                                   -- LevelCapBefore/Arrow/After, Warning,
                                   -- ProgressBar/Fill+LevelText+AmountText,
                                   -- RebirthButton, Message
StarterPlayer/
  StarterPlayerScripts/
    Client/
      HUDController
      RebirthController    -- dueño de la pantalla de Rebirth y del remote
      CollectibleRenderer  -- clones locales con pool
      ObjectLabelController-- billboard + Highlights pooled
      CollectibleController-- sync + loop de proximidad
      BlockerController
Workspace/
  StuckToYou/
    Zones/
      ToyRoom/
        Geometry/
        Blockers/ToyChest
        StartSpawn
        PlacementArea      -- volumen invisible donde pueden caer objetos
        RoomSettings/      -- Configuration editable a mano
          TotalObjects, MinSeparationStuds
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

El Folder necesita tag `StickyZone`, attribute `ZoneId`, entrada correspondiente en `GameConfig.Zones` y los folders hijos `Geometry` y `Blockers`. Para que aparezcan objetos hace falta además el `PlacementArea` (BasePart invisible, tagueado) y el `RoomSettings` con su `ObjectPool`. Cada zona configura `EntryStickiness`, `CollectibleRequirements`, `TotalObjects`, `MinSeparationStuds` y `WinReward`.

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
- Configuración `Attachments` con `Shell`, `MaxVisualAttachments`, tamaño objetivo y límites de pool/growth.

### Garantías

- Máximo de `MaxVisualAttachments` records por jugador; un record puede contener varias partes,
  por lo que el presupuesto físico debe limitarse por `BasePart`, no solo por record.
- Todas las partes son massless y no participan en collision, touch o query.
- Slots deterministas; ningún offset aleatorio puede tapar la cámara de forma impredecible.
- Limpieza en `CharacterRemoving`, `PlayerRemoving` y `Destroy()`.
- Pool libre acotado; nunca crece por encima de `PoolCapacity`.
- Los pickups posteriores al límite reciclan el record no protegido más antiguo, conservan los
  blockers protegidos cuando hay alternativa y aplican como máximo cinco growth steps.

### Para portarlo

Copiar `AttachmentService`, `CollectibleTemplates` y las plantillas authored requeridas; proporcionar
orígenes de eventos compatibles con `PickupService.ConnectCollected` y
`BlockerService.ConnectAbsorbed`; reemplazar `GameConfig.Attachments`. El servicio no depende de
Toy Room, HUD ni persistencia, pero sí del contrato de payload y de las plantillas.

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

### 2026-08-06 — Rebirth con pantalla propia y repetible

- **El Rebirth ya no exige terminar la vuelta.** El documento de diseño dice "unlocked when the player reaches the required Level" y punto; la exigencia de `RunCompleted` era un añadido del código. Se retiró de `FinishService.requestRebirth`. Como consecuencia el remote quedó disponible durante toda la partida y necesitó su propio freno: `GameConfig.Rebirth.RequestDebounceSeconds`.
- **El level cap pasó de tabla a fórmula.** `LevelCapByRebirth = {[0]=20, [1]=25}` se cambió por `BaseLevelCap + rebirths × LevelCapPerRebirth`, más `LevelCapOverrides` para excepciones a mano. El `.md` dice "Rebirth 0: Level 20, Rebirth 1: 25, etc.": eso es una fórmula, y una tabla de dos filas la contradecía en cuanto alguien renacía.
- **El sistema estaba muerto tras el primer Rebirth y no lo decía.** `LevelThresholds` tenía exactamente 20 entradas, así que el nivel máximo alcanzable era 20 — pero el cap del Rebirth 1 era 25. Un jugador con `Rebirths = 1` no podía volver a renacer nunca y la UI solo mostraba "LEVEL 25 REQUIRED" para siempre. El tope duro `MaximumImplementedRebirth = 1` tapaba el síntoma sin arreglar la causa. Ahora `GetLevelCap` devuelve `nil` cuando el techo cae fuera de los niveles generados, y ese `nil` es la única fuente del tope: `GetMaximumRebirth()` lo deriva. **Regla: un requisito que el jugador no puede cumplir debe apagar la función, no quedarse esperando.**
- **Los niveles altos se generan, no se escriben.** `GameConfig.LevelExtension` continúa la curva afinada a mano (20 umbrales) hasta el nivel 100 creciendo el último salto un 10 % por nivel. Con eso hay 17 Rebirths disponibles. La curva generada es mecánica, no diseñada: sirve para que el Rebirth sea repetible, no como balance final.
- **`execute_luau` tiene su propia caché de módulos** (2026-08-06). Un `require` desde la herramienta MCP devuelve una instancia nueva del ModuleScript, no la que está corriendo: `ProgressionService.GetTrackedPlayerCount()` daba 0 con un jugador dentro. No sirve para leer ni mutar estado vivo de un servicio. Para probar progreso hay que recorrer la ruta real; mover el `HumanoidRootPart` encima de objetos elegibles y dejar que el sensor del cliente y la validación del servidor hagan su trabajo funciona bien (88 pickups reales en 29 s).
- **Un pickup fallido casi siempre es el requisito, no la posición.** Al depurar el farmeo, el primer objeto no se recogía: `Collectible_1` pedía 25 de Stickiness y el jugador tenía 0. Antes de sospechar del sensor o del teleport, mirar `RequiredStickiness`.
- La pantalla vieja (`RebirthPanel`, panel pequeño que solo aparecía al completar la vuelta) fue sustituida por `RebirthOpenButton` + `RebirthScreen`. `HUDController` soltó todo lo de Rebirth salvo el aviso de la línea de feedback; el dueño ahora es `RebirthController`.
- Próximo paso exacto: comprobar la conservación de Wins sobre el flujo nuevo con `Wins > 0`, y afinar la curva de los niveles 21+ con playtest.

### 2026-08-06 — El Level deja de caer al reiniciar la vuelta

- **Síntoma reportado:** pisar un pedestal de Wins devolvía al inicio y ponía Stickiness en 0 (correcto), pero también el Level en 1 (no era la idea).
- **Causa:** el Level no se guardaba, se *derivaba*. `AddStickinessFromCurrentWrap` hacía `state.Level = GetLevel(state.Stickiness)`, así que al poner la Stickiness a 0 el Level caía con ella. `ProgressionService.ResetRun` además lo forzaba a 1 explícitamente junto con el Sticky Wrap.
- **Arreglo:** el Level pasa a ser la **marca más alta del ciclo de Rebirth**, no una lectura de la Stickiness actual. `AddStickinessFromCurrentWrap` usa `math.max(state.Level, GetLevel(state.Stickiness))` y `ResetRun` ya solo toca la Stickiness y la zona.
- **Quién comparte `ResetRun`:** el pedestal de Wins, el ReplayPad y el respawn tras morir, todos vía `FinishService.returnToStart`. El arreglo aplica a los tres: morir tampoco baja el Level. El Rebirth es lo único que devuelve Level y Wrap al principio, y lo hace en `TryRebirth`, no en `ResetRun`.
- **Consecuencia buscada:** el Sticky Wrap también se conserva entre vueltas, así que cada vuelta después de cobrar arranca más rápida — coherente con "Makes the next run faster" del documento de diseño. Verificado: primer pickup tras el pedestal dio `+8` (SuperGlue conservado) en lugar de `+1`.
- **Consecuencia a tener en cuenta:** como la Stickiness sí vuelve a 0, subir de nivel exige alcanzar el umbral **dentro de una misma vuelta**. Cobrar a mitad de camino no acumula hacia niveles altos; lo que deja es la velocidad. Es lo que hace que el pedestal sea una decisión y no un trámite.
- Pruebas: pedestal de 1 Win real tras absorber el Toy Chest → `Stickiness 183 → 0`, `Level 12` intacto, `Wrap SuperGlue` intacto, `Wins 0 → 1`, teleport al inicio y zona `ToyRoom`; el Level siguió subiendo de 12 a 14 en la vuelta siguiente; muerte y respawn conservaron `Level 14`; Rebirth con `Level 20` devolvió `Level 1 / BasicGlue` y conservó `Wins 1` con multiplicador `1.5x`. Consola limpia y teardown correcto.
- Esto cierra el pendiente anterior de comprobar la conservación de Wins con `Wins > 0` sobre el flujo nuevo.

### 2026-08-06 — Sticky Wraps: se compran con Wins, no se desbloquean por nivel

- **La implementación anterior contradecía el documento de diseño.** El `.md` dice "Wins are used to unlock Sticky Wraps" y "The **equipped** Sticky Wrap determines how much Stickiness the player gains". El código hacía lo contrario: `UnlockLevel` 1/5/10/15 y `GetStrongestWrap(level)` forzaba siempre el más fuerte, así que no había nada que equipar ni nada en lo que gastar las Wins.
- **Modelo nuevo:** `Basic Glue` viene de fábrica y no se puede comprar ni perder; `Strong / Super / Cosmic` se compran con Wins (3 / 10 / 25) y se equipan a mano. `GameConfig.GetStrongestWrap` y `UnlockLevel` desaparecieron; en su lugar están `GetDefaultWrap`, `IsDefaultWrap` y `GameConfig.Wraps`.
- **El Level y el Wrap quedaron desacoplados del todo.** El Level ya solo sirve para el techo del Rebirth. Comprobado: 80 recogidas seguidas pasando de Level 5 a 8 siguieron dando `+1`, donde antes el nivel habría subido el pegamento solo.
- **Los wraps comprados se persisten** (`OwnedWrapIds` y `EquippedWrapId` en el perfil). Se pagan con Wins, que son moneda persistente: perderlos al reconectar sería robar. El Rebirth sí los borra, como pide el `.md`, y las Wins no se tocan, así que el jugador conserva con qué volver a comprarlos.
- **Los atributos no admiten tablas**, así que el conjunto comprado viaja como una cadena separada por comas en el atributo `OwnedWrapIds`. Una sola señal de cambio en vez de una por wrap; el cliente la parte y siempre añade el de fábrica por su cuenta, aunque el atributo aún no haya replicado.
- **`WrapService`** solo valida la forma de la petición y frena el spam; las reglas viven en `ProgressionService`. `DataService.normalizeWrapIds` descarta cualquier id que no exista hoy en el catálogo, así que un perfil viejo o manipulado no puede meter un wrap inventado.
- **La lista de la tienda se clona de `_WrapRow`**, plantilla authored dentro de `WrapScreen`. Añadir un pegamento es tocar `GameConfig.StickyWraps`, no la pantalla. La plantilla vive **fuera** del `ScrollingFrame` a propósito: un `UIListLayout` reserva hueco también para los hijos invisibles, así que dejarla dentro habría dejado un espacio vacío arriba de la lista.
- Pendiente explícito: **el viaje completo de ida y vuelta de los wraps persistidos no está verificado**. El mock de DataStore de Studio vive en el VM del servidor y muere al salir de Play, así que no se puede probar reconectando. Sí está verificada la escritura (`DataLastSavedWraps` mostró `BasicGlue,StrongGlue` tras comprar y `BasicGlue` tras el Rebirth). Falta repetir la prueba cloud con almacén aislado, como se hizo con Wins/Rebirths.
- Pendiente de diseño: el `.md` pide que los wraps "**visibly change the player's sticky coating, material, or attachment effect**". Hoy el wrap solo se lee por color (nombre del HUD, `+N` de cada recogida y la franja de la tienda). El recubrimiento visual del personaje es trabajo de arte y no entró aquí.

### 2026-08-06 — El `.md` añade Trails y Auras: la fórmula pasa a tener tres capas

- **La ganancia dejó de ser un solo multiplicador.** Ahora es `WrapBaseGain × (RebirthMultiplier + TrailAddition) × AuraMultiplier`. El **Trail suma** al multiplicador base y el **Aura multiplica** el resultado ya combinado. Confundir esas dos operaciones es el error fácil: por eso la fórmula entera vive ahora en `GameConfig.GetStickinessGain` / `GetBaseMultiplier` y nadie más multiplica a mano. Verificada contra el ejemplo textual del documento (`3 × 4.5 × 2.0 = 27`).
- **Trails y Auras no se implementaron.** `ProgressionService.getTrailAddition` y `getAuraMultiplier` devuelven el neutro (`0` y `1`) y son el único punto del cálculo que habrá que cambiar. Hoy el resultado es idéntico al anterior en todas las combinaciones probadas.
- **Nuevo atributo `StickinessMultiplier`**: el multiplicador efectivo del jugador. Hoy coincide con `RebirthMultiplier`; en cuanto existan Trails y Auras dejará de coincidir. **La UI debe leer ese atributo, no recalcular la fórmula por su cuenta** — hoy `HUDController` y `RebirthController` llaman a `GetRebirthMultiplier` directamente, y eso solo es correcto mientras no haya trail ni aura. El de Rebirth sigue teniendo sentido en la pantalla de Rebirth, que compara antes/después de renacer.
- **Precio de Cosmic Glue corregido a 30 Wins**: el documento ahora fija `0 / 3 / 10 / 30` y el 25 era una elección previa mía.
- **Trails y Auras no se resetean con el Rebirth.** El documento sigue diciendo solo "Resets unlocked Sticky wraps". Con precios de 15–100 Wins tiene sentido, pero conviene confirmarlo antes de implementarlos.
- **Velocidad y radio de recogida quedan fuera de la fórmula.** Los bonus de Trails y Auras sobre movimiento y radio no cambian la ganancia por objeto: van sobre `Humanoid.WalkSpeed` y `GameConfig.Collection.PickupRadius`. Ese radio es hoy una constante global **validada en servidor** (`PickupValidationSlack`), así que hacerlo por jugador obliga a tocar también `PickupService`.
- **Conflicto sin resolver:** el documento cambió la compra de Sticky Wraps a **placas físicas en el lobby** ("stepping into the respective plate"), mientras que Trails y Auras sí son botón en el HUD. Lo implementado para Wraps es botón + pantalla. La lógica no estorba — `TryBuyWrap`/`TryEquipWrap` ya son API de servidor y unas placas serían otro llamador —, pero falta decidir si las placas sustituyen la pantalla o conviven con ella.

### 2026-08-06 — Los Sticky Wraps se equipan pisando placas del lobby

- **El documento manda: placas, no botón.** Los Wraps se compran y equipan pisando una placa del lobby. La pantalla del HUD se conservó como catálogo y porque es el patrón que reutilizarán Trails y Auras, pero la ruta oficial es la placa.
- **Una sola regla para las dos rutas.** `ProgressionService.RequestWrap` es el punto de entrada único: compra si no lo tienes, equipa si ya lo tienes, y devuelve cuántas Wins faltan. La placa y la pantalla lo llaman igual. Antes el cliente decidía si mandaba `Buy` o `Equip`; ahora solo pide el wrap y el servidor resuelve. Menos superficie que validar y dos rutas que no pueden divergir.
- **Las ocho placas se identificaron por su firma geométrica**, no por nombre: eran las únicas partes `7×1×7` en color `(255,176,0)` dentro de `Zones/Lobby/Geometry`. El resto de partes amarillas del lobby son rampas y suelos de otros tamaños. Quedaron renombradas `WrapPad_<WrapId>`, tagueadas `WrapPad` y con attribute `WrapId`. **`Lobby2` no se tocó.**
- **El cartel de cada placa lo pinta el cliente**, no el servidor: "comprado" y "equipado" son estado por jugador, así que un cartel server-side mostraría el estado de otro. Misma razón por la que el color de la placa se cambia desde el cliente — las escrituras del cliente sobre partes del Workspace son locales. Plantilla authored en `ReplicatedStorage/Assets/LobbyUI/_WrapPadSign`, con `Size` en Scale (studs) por la misma lección de las tarjetas de requisito.
- **Cuatro wraps nuevos** para llenar las ocho placas: Quantum `+50`/75, Nova `+120`/150, Galaxy `+300`/300, Infinity `+750`/600. Los cuatro del documento se mantuvieron intactos. Ganancia ×2,5 por peldaño (la pendiente que ya traían los originales) y precio ×2, que deja la eficiencia casi plana.
- **`Touched` no dispara si el personaje aparece encima de una placa sin moverse** (2026-08-06). Al probar teletransportando el personaje justo sobre la placa no ocurría nada; cayendo desde arriba sí. Roblox necesita contacto real, no solapamiento estático. Vale para cualquier pad del proyecto: al probar pads por script, hay que **caer** sobre ellos, no aparecer encima.
- **Techo de ingreso de Wins.** Los pedestales dan 1/3/10, así que una vuelta rinde como mucho 10 Wins pase lo que pase con el wrap equipado. Las vueltas se acortan mucho al subir de pegamento pero el ingreso no escala, así que la parte alta de la escalera (Infinity = 600 Wins ≈ 60 vueltas) es larga. Si se quiere acortar, o suben los pedestales o bajan los precios altos.

### 2026-08-06 — Regla dura de autoría, y la Stickiness solo se pierde con el Rebirth

**1. Si es fijo, se crea en el editor.** Regla nueva en `AGENTS.md` (sección 5.1). Todo lo que el jugador ve, en UI o en el mundo, y existe en cantidad fija y conocida, debe estar creado a mano en el DataModel. El código no lo instancia en runtime.

- El criterio es *quién decide el aspecto*: cantidad fija → instancias authored una por una; cantidad variable o lista repetida desde configuración → plantilla authored que el código clona.
- **Que el contenido sea distinto por jugador no justifica crearlo por código.** Las escrituras del cliente sobre instancias del Workspace son locales, así que un cartel authored y compartido muestra a cada jugador su propio texto y color. Ese fue exactamente el error con los carteles de las placas: se clonaban por jugador "porque el estado es por jugador", cuando bastaba con uno authored por placa.
- El motivo práctico: si el cartel nace en runtime, subirlo unos studs o agrandarlo obliga a editar código en vez de arrastrarlo en Studio.
- **Corregido:** los 8 `WrapSign` son ahora hijos authored de cada placa en `Zones/Lobby/Geometry`. Se borró la plantilla `Assets/LobbyUI/_WrapPadSign` y `WrapPadController` dejó de clonar: localiza el cartel, valida su contrato y solo escribe texto y color. Tamaño, offset, fuente y layout son del editor. Si falta el cartel, avisa y deja esa placa sin etiqueta en vez de generar una.

**2. La Stickiness solo se pierde con el Rebirth.** Cobrar en un pedestal de Wins ya no la reinicia; tampoco morir ni el ReplayPad.

- `ProgressionService.ResetRun` dejó de tocar el progreso: ahora solo reposiciona la zona lógica. Stickiness, Level y Wrap pertenecen al ciclo de Rebirth y únicamente `TryRebirth` los devuelve al principio. El documento de diseño solo lista "Resets Stickiness" bajo Rebirth, y del pedestal solo dice que concede Wins y teletransporta.
- **Lo que sí debe seguir reiniciándose en cada vuelta son los blockers.** Los atributos `CompletedZone_*` son los que autorizan cobrar un pedestal, así que sin `BlockerService.ResetPlayerRun` se podría cobrar el mismo pedestal en bucle sin moverse. Verificado: tres intentos seguidos de cobrar sin rehacer la ruta no pagaron nada; rehacerla sí.
- Consecuencia de diseño: la vuelta pasa a ser "vuelvo con toda mi Stickiness, atravieso los blockers al toque y llego más lejos a cobrar un pedestal mayor". Es lo que hace que subir de Sticky Wrap se note entre vueltas.
- La pila visual sí se sigue limpiando al volver al inicio. Es presentación, no progreso, y además evita que los adjuntos de blocker —que están protegidos del reciclado— se acumulen vuelta tras vuelta hasta llenar los 36 slots.
- **Pendiente señalado:** la Stickiness y el Level siguen sin persistir entre sesiones (`initializePlayer` los arranca en 0 y 1). Con la regla nueva de "solo el Rebirth resetea", salir y volver a entrar es hoy la única forma de perderlos sin renacer. Si diseño quiere coherencia total, hay que añadirlos al perfil de `DataService`.

### 2026-08-06 — HUD central de Stickiness, nivel y multiplicador

- **`ProgressPanel` fue sustituido por `StatsPanel`**, un bloque centrado abajo con el número de Stickiness, el wrap equipado, el multiplicador efectivo y la barra de nivel, más `CounterStack` arriba a la izquierda con Rebirths y Wins. Calcado en forma y color a la referencia de simulador que dio diseño.
- **Todo el bloque nuevo va en Scale puro: ni un solo Offset en `Size` ni en `Position`.** Es lo que hace que escale en móvil sin una pasada aparte. Donde hacía falta forma fija —iconos circulares, badges— se usó `UIAspectRatioConstraint`, que no mete píxeles. Los únicos píxeles que quedan son los `UIStroke.Thickness`, que la API no permite en Scale.
- **La barra mide el tramo dentro del nivel actual**, no el total acumulado: `current = Stickiness - thresholds[Level]`, `span = thresholds[Level+1] - thresholds[Level]`. Contra el total la barra no se movía de forma legible. En el último nivel generado no hay siguiente umbral: se llena y muestra `MAX`.
- **El HUD lee el atributo `StickinessMultiplier`, no `GetRebirthMultiplier`.** Cierra el pendiente que dejó la sesión de Trails y Auras: cuando existan, el número seguirá siendo correcto sin tocar la UI.
- **Los números se abrevian con tres cifras significativas** (`14.1K`, `1.51K`, `3M`). Detalle que cuesta un bug: los ceros de cola solo se recortan si de verdad hay parte decimal — hacerlo a ciegas convierte `"100"` en `"1"`.
- **`RebirthOpenButton` y `WrapOpenButton` pasaron de Offset a Scale.** No entraban en el encargo, pero `CounterStack` los pisaba y, siendo Offset, en móvil se habrían quedado clavados en píxeles encima de los contadores.
- **`PickupFeedback` subió a `0.6` de altura**: caía justo encima del número grande de Stickiness.
- **`screen_capture` agota el tiempo de espera en este lugar**, tanto en Play como en Edit. La verificación visual se hizo por medidas: `AbsolutePosition`/`AbsoluteSize` de cada nodo y un test de intersección de rectángulos entre los cinco elementos de primer nivel del HUD. Sirve para detectar solapes y texto que no cabe (`TextFits`), no para juzgar el aspecto.
- Pendiente: los 4 botones de `BoostRow` son placeholder sin dev product; los `Icon` de los contadores son `ImageLabel` vacíos esperando arte; y falta una revisión a ojo en el emulador de dispositivos.

### 2026-08-11 — El límite de 36 objetos pegados NO es un límite de rendimiento

Auditoría de rendimiento de la pila pegada, con sonda propia y medición en Play. **Tres hipótesis previas quedaron refutadas por medición, dos de ellas mías.**

**Sonda nueva.** `ServerScriptService.Server.PerfProbe` y `StarterPlayer…Client.PerfProbeController`, ambas apagables desde `GameConfig.Perf`. Publican por atributos, no por API: `execute_luau` no puede leer estado vivo de un servicio (`require` devuelve una copia), así que el reset se dispara con el atributo `ResetRequested = true` sobre el Folder de cada sonda. El Folder del servidor vive en **ServerStorage**, no en Workspace: allí sus atributos se replicarían a todos los clientes cada segundo, y una sonda que mide replicación no puede añadir replicación propia.

**Refutación 1 — los draw calls no escalan con la pila.** Prueba A/B con `LocalTransparencyModifier` (cliente-local, no replica, reversible) sobre las 49 partes de una pila llena: **+0,81 draw calls**. Con clones locales soldados al personaje, de 0 a **4.834 partes**: los draw calls fueron 12 → 18, y variaron más con el ángulo de cámara que con el número de piezas. Las 9 plantillas son `Part` primitivas de 3 formas (Block/Ball/Cylinder), un solo material `SmoothPlastic` y cero texturas, así que el instancing de Roblox las colapsa en los batches que la escena ya dibuja. **Cualquier optimización cuyo argumento sea "bajar draw calls" no tiene nada que ganar aquí.**

**Refutación 2 — `EditableMesh` descartada, no aplazada.** Su premisa entera era ahorrar draw calls que no se están pagando. Además: no replica entre servidor y cliente, el cliente admite un máximo de **8 EditableMesh simultáneos**, y no hay geometría fuente que unir porque las plantillas son primitivas y no `MeshPart`.

**Refutación 3 — el churn de welds no es el primer cuello de botella.** `applyGrowthStep` destruye y recrea todos los `WeldConstraint` de la pila de golpe. Predije que sería lo primero en reventar. Con los 5 growth steps disparados (`VisualGrowthStep = 5`): **0 tirones en cliente**, y el único frame largo del servidor la sonda lo atribuyó a `PileAtCount = 0`, o sea que ni siquiera fue el growth step. A 49 welds el rebuild está por debajo del ruido. El mecanismo es real y es O(n), pero no justifica trabajo hoy.

**Coste medido de la pila real (3 → 36 piezas):** `InstanceCount` +149 (≈4,1 instancias por pieza: Model + Part(s) + WeldConstraint(s)), `MemoryPartsMb` +0,52, `FrameMsAverage` sin cambio (16,66 → 16,67), `DataSendKbps` sin cambio.

**Estrés de render (clones locales soldados, validado contra el foco de ventana):**

| Piezas | Partes | FPS | Peor frame | Draw calls | Moving primitives |
| --- | --- | --- | --- | --- | --- |
| 0 | 0 | 60,0 | 18,4 ms | 12 | 20 |
| 100 | 322 | 60,0 | 18,5 ms | 28 | 180 |
| 300 | 966 | 60,1 | 18,4 ms | 28 | 402 |
| 600 | 1.934 | 60,1 | 18,8 ms | 17 | 687 |
| 1.000 | 3.222 | 60,1 | 18,2 ms | 20 | 1.131 |
| 1.500 | 4.834 | 60,1 | 18,6 ms | 18 | 1.687 |

Memoria total en todo el rango: +1 MB. **Degradación cero hasta 1.500 piezas.**

**Trampa de medición que costó dos corridas:** Windows desprioriza las ventanas en segundo plano y Roblox baja su render a ~15 FPS. Cualquier medida de FPS tomada mientras Studio no es la ventana activa es basura, y sale como un 15 sospechosamente exacto. La versión final del arnés escucha `UserInputService.WindowFocused`/`WindowFocusReleased` y **repite la muestra** si pierde el foco, en vez de publicar un número falso. Regla general: **toda medición de FPS en este proyecto debe validarse contra el foco de la ventana.**

**Conclusión.** El tope de 36 lo pone el `assert` de `AttachmentService.buildSlots`, que exige que los 5 anillos escritos a mano en `GameConfig.Attachments.Rings` sumen exactamente `MaxVisualAttachments`. Es un límite de layout, no de rendimiento. Subirlo exige sustituir los anillos por una distribución paramétrica (esfera de Fibonacci sobre un radio que crece con el conteo).

**Lo que sigue sin medir, y es lo único que puede seguir siendo un muro:**

1. **Replicación.** El estrés usó clones **locales**; la pila real se crea en el servidor y se replica. A 4,1 instancias por pieza, 1.500 piezas son ~6.200 instancias por jugador.
2. **Multijugador.** Todo se midió con 1 jugador. 8 jugadores multiplican render y replicación.
3. **Móvil.** Medido en un escritorio que sostiene 60 FPS. Móvil es la mayoría de Roblox y no se probó.

**Próximo paso exacto:** sustituir los anillos por distribución paramétrica, subir `MaxVisualAttachments` sobre el sistema real (server-side) y medir `InstanceCount` y `DataSendKbps`. Eso decide si hace falta mover el render al cliente o basta con subir una constante.

### 2026-08-11 — 300 objetos pegados, medidos sobre el sistema real. Bastaba con subir una constante

**Cambio.** `GameConfig.Attachments.Rings` (5 anillos escritos a mano) sustituida por `Shell`, una distribución paramétrica en `AttachmentService.buildSlots`. `MaxVisualAttachments` de **36 a 300**. `PoolCapacity` de 72 a 400, para que una pila entera devuelta de golpe por `ClearPlayerVisuals` quepa en el pool en vez de destruirse y volver a clonarse.

**La distribución separa dirección de radio, y esa separación es lo importante.** El radio crece con la **raíz cúbica** del índice del slot (única curva que da densidad uniforme en volumen: con crecimiento lineal las piezas se amontonan en el centro y la bola se ve hueca). La dirección sale de una **secuencia R2 de baja discrepancia**, no de una espiral de Fibonacci clásica: en la de Fibonacci la latitud se deriva del propio índice, así que la pila se llenaría barriendo de un polo al otro. Verificado antes de correrla: con 12 piezas ya ocupa 7 de 8 octantes; con 36, los 8 equilibrados.

**Curva medida (1 jugador, sistema real server-side, pila replicada):**

| Pila | InstanceCount | Δ | DataSendKbps | MemoryPartsMb | Frame servidor | Tirones |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | 39.827 | — | 0,33 | 2,15 | — | 0 |
| 26 | 39.924 | +97 | 7,34 | 2,35 | 16,68 ms | 0 |
| 51 | 40.014 | +187 | 7,07 | 2,54 | 16,64 ms | 0 |
| 100 | 40.195 | +368 | 7,70 | 2,94 | 16,67 ms | 0 |
| 150 | 40.386 | +559 | 7,00 | 3,36 | 16,68 ms | 0 |
| 203 | 40.577 | +750 | 10,00 | 3,77 | 16,67 ms | 0 |
| 250 | 40.746 | +919 | 9,89 | 4,16 | 16,68 ms | 1 |
| 300 | 40.930 | +1.103 | 4,30 | 4,55 | 16,64 ms | 2 |

**El `DataSendKbps` de la tabla es del arnés, no de la pila.** Los 7–10 kbps son los teletransportes y los remotes de pickup del script de farmeo. Con el arnés parado y 300 piezas encima el envío cae a **0,46 kbps**, contra 0,33 en reposo con la pila vacía. **Una pila de 300 no cuesta ancho de banda en régimen permanente**, y tiene sentido: las piezas soldadas viajan con la asamblea del personaje, así que después de crearse no replican CFrame.

**Cliente con 300 piezas encima, medido con la ventana enfocada y tras reiniciar la sonda:** `Fps 59,95`, `PeakFrameMs 18,35`, **`SpikeCount 0`**, 401 partes y 1.102 instancias en `StickyPile`.

**Coste unitario:** 3,68 instancias por pieza (Model + Part(s) + WeldConstraint(s)) y ~8 KB de memoria por pieza.

**Conclusión histórica, limitada al arnés de un jugador/escritorio:** no hacía falta una reescritura para quitar el tope de 36 ni para alcanzar 300 en esa prueba. Draw calls, churn por weld individual y réplica *steady-state* no fueron el muro allí. La auditoría del 2026-08-12 reabrió servidor lógico + render local para el caso no medido `8 × 300` móvil, creación activa y late join. **Regla para este proyecto: medir el coste antes de diseñar la solución.**

**Lo que sigue sin medir:**

1. **Multijugador.** Todo con 1 jugador. Con 8 × 300 piezas son ~8.800 instancias y ~19 MB en servidor.
2. **Coste de join.** Un jugador que entra a un servidor donde otros llevan 300 piezas recibe todas esas instancias de golpe. El join con la pila vacía transmitió 29.129 bytes.
3. **Móvil.** Medido en escritorio a 60 FPS.

### 2026-08-11 — El coste real es CPU, y es el número de partes soldadas

Prueba en celular multijugador (dos capturas de la barra de Performance Stats): **CPU 39–46 ms, GPU 5,4–6,0 ms**, recibidos 40–46 KB/s, ping 113–117 ms. En esas capturas el cuello predominante fue CPU. Esto rebaja render en el greybox observado, pero no retira draw calls, overdraw ni LOD del análisis con arte real.

**Trampa de método:** el frame time no sirve para medir esto. VSync lo clava en 16,67 ms mientras haya margen, así que un coste creciente es invisible hasta que revienta. **La métrica útil es `Stats.PhysicsStepTimeMs`, que no está capada.** Mirando solo FPS se concluye "no pasa nada" tres veces seguidas.

**Coste medido de la pila (escritorio, cliente):**

| Piezas soldadas | `PhysicsStepTimeMs` |
| --- | --- |
| 0 | 0,121 ms |
| 100 | 0,190 ms |
| 300 | 0,619 ms |
| 600 | 0,868 ms |

Lineal, **~1,4 µs por parte y por paso de física**. No es un pico por recogida: es un **impuesto permanente** mientras el jugador las lleve puestas, y se paga por cada pila cargada en el cliente, propia o ajena.

**Hipótesis refutada:** creí que cada recogida forzaba un rebuild de la asamblea, con coste O(piezas). Falso. Añadir un `WeldConstraint` cuesta lo mismo con 0 piezas que con 600 (delta entre −0,023 y +0,057 ms, sin tendencia). El coste no está en soldar, está en **estar soldado**.

**Comparativa que decide el arreglo (600 partes):**

| Modo | Física | Lua | Total añadido |
| --- | --- | --- | --- |
| Ancladas, quietas | 0,022 ms | 0 | **0,022 ms** |
| Ancladas + `workspace:BulkMoveTo` cada frame | 0,043 ms | 1,434 ms | **1,455 ms** |
| Soldadas a `UpperTorso` | 0,490 ms | 0 | **0,468 ms** |

Las partes ancladas y quietas son gratis: **el coste es al 100 % pertenecer a la asamblea en movimiento**. Pero moverlas a mano con `BulkMoveTo` cuesta **3× más** que dejar que el motor propague la asamblea — el gasto son las 600 multiplicaciones de `CFrame` en Lua.

**Conclusión: soldar ya es la forma óptima de mover N partes con el personaje. La Opción A (quitar constraints y mover por código) queda descartada con medición. El único arreglo real es reducir el número de partes.**

**Los hitches tienen nombre:** vaciar la pila de golpe. 600 piezas = **10,6 ms de Lua + frame siguiente de 19 ms** en escritorio, del orden de 50–100 ms en celular. `ClearPlayerVisuals` se llama al cobrar un pedestal, al morir, en el ReplayPad y en el Rebirth — o sea, en el bucle central — y lo sufre todo el que tenga esa pila cargada, no solo su dueño.

**Palanca gratis y no obvia:** el tamaño visual de la bola lo fija `Shell.MaxRadius`, no el número de piezas. Subir `TargetMaxSizeStuds` y bajar `MaxVisualAttachments` conserva la silueta con una fracción de las partes. 100 piezas a 2,4 studs llenan el mismo volumen que 300 a 1,6.

**Aritmética corregida el 2026-08-12:** con la pendiente documentada de `~1,4 µs/BasePart/paso`, 300 piezas ≈ 400 partes implican `~0,56 ms` de delta en escritorio. Cuatro pilas proyectan `~2,24 ms` y ocho `~4,48 ms`; aplicando el factor móvil hipotético 5–10×, ocho pilas serían `~22–45 ms`. Es una extrapolación, no una medición, y exige MicroProfiler en el escenario objetivo.

**Instrumentación añadida:** etiquetas `debug.profilebegin` en `AttachmentService` (`Sticky/PlaceAndWeld`, `Sticky/ClearAll`, `Sticky/GrowthStep`, `Sticky/Acquire`, `Sticky/Animations`) y delta de `InstanceCount` por frame en las dos sondas, que separa "CPU sostenida" de "tirón por churn". `acquireVisual` se reescribió con una sola salida: su `return` temprano dejaba un `profilebegin` sin cerrar.

**Pendiente de diseño, no de ingeniería.** A 300 piezas la bola mide **13 studs de diámetro** y sube **4,58 studs sobre el torso**, o sea ~2,5 por encima de la cabeza; se contaron 9 piezas interpuestas entre cámara y cabeza. El pasillo de salida de la Kitchen mide 8 studs de ancho, así que la bola lo atraviesa visualmente (no encaja al jugador: las piezas van con `CanCollide = false`). Ajustar `Shell.MaxRadius`, `VerticalScale` y `VerticalOffset` es una decisión de diseño con la palanca ya expuesta en `GameConfig`.

### 2026-08-12 — Auditoría MCP: la meta 8 × 300 sigue abierta

Se inspeccionó la implementación viva del lugar `95828455414780`, no solo la documentación.
El valor efectivo es `MaxVisualAttachments=36` temporal y `PoolCapacity=400`; la pila adherida
continúa creándose en servidor y soldando cada `BasePart` directamente al torso. Los objetos del
suelo sí son presentación local con estado autoritativo en servidor.

**Corrección crítica:** la pendiente escrita de `~1,4 µs/BasePart/paso` no cuadra con la
extrapolación previa. `400 × 1,4 µs ≈ 0,56 ms`, no `0,31 ms`. Ocho pilas de ~400 partes proyectan
`~4,48 ms` desktop y `~22–45 ms` con el factor móvil hipotético 5–10×. Es una extrapolación, no
una medición, pero invalida cerrar la arquitectura para 8 jugadores sin probarla.

**Lo sólido:** autoridad server, collectibles locales, rate limit, flags físicos, pools acotados,
slots cacheados, Heartbeats bajo demanda para animaciones y limpieza explícita.

**Lo no demostrado:** `8 × 300` co-localizado en móvil, creación/animación/clear de réplica,
late join, arte multiparte y estabilidad de memoria. El `0,46 kbps` histórico describe una pila
ya construida y quieta; no mide materialización ni `Replicator/ProcessPackets`.

**Nuevo criterio de arquitectura:** separar capacidad lógica de presupuesto visual. Mantener
300 pickups lógicos y probar `110` proxies authored de una parte `[PLACEHOLDER]`. Si no pasa los
gates móviles, el servidor conservará solo el ring lógico y los clientes renderizarán pools
locales con LOD propio/remoto, snapshots chunked y animaciones locales. La UI muestra el conteo
lógico, no el número de instancias visibles.

**Trabajo prioritario:** proxy de una parte; clear ≤2 ms Lua/frame con `GenerationId`; retirar el
rebuild global de growth; eliminar allocs por objeto/tick del sensor; curar labels solo al nacer;
A/B de BillboardGui; medir `Simulation/assemble`, `physicsStepped`, `SpatialFilter`, `SolveBatch`,
`interpolateNetworkedAssemblies`, `Pass3dAdorn` y `Replicator/ProcessPackets`.

**Smoke de auditoría:** Play limpio con 1 jugador, pila 0 y 24 collectibles locales; cliente
`PhysicsStepTimeMs≈0.064`, servidor `≈0.015`; join baseline 29.109 bytes; Studio volvió a Edit.
Esto valida arranque/teardown, no capacidad.

`SceneAnalysisService` reportó en cliente `≈5,25 MB` de audio y `≈139 KB` de animaciones. El
mayor audio es el core `FreeFalling` (`≈1,76 MB`); entre assets del juego destacan Rebirth
(`≈731 KB`) y WinClaim (`≈682 KB`). Hubo 11 instancias sin parent en cliente y 7 en servidor:
PlayerModule/Animate y BindableEvents pequeños de servicios, sin acumulación material visible en
el baseline. Debe repetirse tras diez ciclos; una sola muestra no descarta crecimiento. La memoria
de scripts no estuvo disponible porque Studio exige el flag `STUDIOPLAT37936`.

### 2026-08-13 — Fase B implementada: servidor lógico, render local acotado

**Decisión.** Para priorizar celulares low-end se eliminó la pila cosmética replicada por el
servidor. `AttachmentService` conserva hasta 300 records compactos por jugador y emite deltas,
clear y snapshots versionados. `AttachmentRenderer` decide la presentación local: 110 proxies
propios, 20 por jugador remoto cercano y máximo 320 creados por cliente. Estos valores son
`[PLACEHOLDER]` hasta Android/8 jugadores.

**Arte y contratos.** Se authored 29 proxies (9 collectibles + 20 blockers de los dos mundos),
cada uno con un único `BasePart`, `ProxyId` único y física inerte. El registry
`AttachmentProxyTemplates` valida las plantillas y no genera geometría sustituta. El focus de
pickup también pasó a `_FocusHighlight` authored.

**Réplica y seguridad.** `AttachmentVisual` es cosmético. El cliente puede solicitar un snapshot
con cooldown, pero no enviar records, counts ni progreso. Pickups, requisito, distancia,
Stickiness, blockers y premios siguen validados por sus servicios de servidor. El alias
`VisualAttachmentCount` conserva consumidores antiguos y ahora refleja el mismo conteo lógico
que `LogicalAttachmentCount`.

**CPU cliente.** Los slots de 110/20 se precalculan; un pickup no reconstruye la pila. Remotos
usan histéresis 90/110 studs a 4 Hz. Sensor de collectibles dejó de asignar `Candidate` por item
y usa distancia al cuadrado. Labels actualizan elegibilidad por evento, curan máximo 8 por frame
y se desactivan a más de 42 studs.

**Pruebas ejecutadas.** Arranque/snapshot, pickup real, rechazo de ID negativo/string/`NaN`,
muerte, respawn y pickup posterior pasaron. Un stress de 300 deltas a ~96/s quedó en 110 models,
110 parts y 110 welds locales, con 0 flags inseguros y 0 geometría cosmética server-side. Clear
por generación ignoró el add stale y aceptó el vigente.

**Bug encontrado por lifecycle stress.** Los primeros diez ciclos reprodujeron double-release:
un batch antiguo conservaba un record ya devuelto y readquirido. Se añadió estado explícito
`Active/Queued/Pooled/Destroyed`, borrado de la referencia antes de liberar y guards idempotentes.
Después del fix pasaron 10 + 50 ciclos: active/metadata/pending volvieron a 0, el pool quedó
acotado y el fill final se estabilizó en 110 creados/activos sin errores.

**Estado operativo.** Consola final sin errores de `AttachmentService`/`AttachmentRenderer`;
solo warnings conocidos de `WorldService.DebugUnlock` y Team Create 503. Studio quedó en Edit,
PlaceId correcto. El MCP no expone Save/Publish: el cambio no está guardado ni publicado live.

**Gates pendientes.** Dos y ocho clientes reales, late join/owner leave, pedestal/Replay/Rebirth
con pickup concurrente, Android low/mid-end, thermal soak y dumps MicroProfiler cuantitativos
para empty/fill/steady/clear/join. No declarar performance móvil cerrada antes de estos gates.
