# Plan de Monetización — Stuck to You

Fuente de diseño: sección **Monetization** de `Stuck to You- One-Week Prototype.md`.
Estado del lugar auditado el **2026-08-13** sobre `Exposición pegajosa` (Studio, modo Edit).

---

## 1. Auditoría: qué hay hoy en el place

| Ítem del documento | Estado real | Evidencia |
| --- | --- | --- |
| **Gamepass: Permanent x2 Wins** | ❌ No existe | No hay una sola referencia a `GamePassService` ni a `UserOwnsGamePassAsync` en el juego |
| **Gamepass: Permanent Speed Boost** | ❌ No existe | Ídem |
| **Premium Rest Zones** | 🟡 ~90 % hecho | `RestZoneService` tiene prompt, `ProcessReceipt`, concesión, persistencia y desbloqueo. Faltan ProductId reales, `RequirePurchaseForPaidTiers = true` y el pop-up de confirmación authored |
| **Premium Sticky Wraps** | ❌ No existe | Los 8 wraps son de Wins y **todos** se borran al renacer (`TryRebirth`) |
| **Double Win Plates** | ❌ No existe | Hay 20 `WinPedestal` (10 por mundo) y ninguna placa hermana |
| **Dev product: Skip Rebirth** | ❌ No existe | — |
| **Dev product: Stickiness Packs** | ❌ No existe | `StatsPanel.BoostRow` tiene 4 botones **placeholder**: sin `Activated`, sin producto, precios de ejemplo `14/45/225/449` |
| **Dev product: Trails y Auras con Robux** | ❌ No existe | `GameConfig.Trails` y `GameConfig.Auras` están completos y jugables, pero solo con `WinCost` |
| **Dev product: Temporary Boosts** | ❌ No existe | — |

### Lo que sí está listo para colgar monetización encima

- **Trails y Auras implementados de verdad**: catálogo, compra con Wins, equipado, persistencia, VFX authored (`CosmeticService` + `CosmeticVfxService`) y pantalla `InventoryScreen` con 3 pestañas y plantilla `_CosmeticRow`. Solo les falta la vía de Robux.
- **`PerkService`** ya centraliza velocidad y radio con una fórmula de capas y techos separados (`Maximum` / `MaximumWithBonuses`). El Speed Boost de pago entra ahí como un factor más, no como un `WalkSpeed = X` suelto.
- **`ProgressionService.AwardWins`** es el único punto por el que entran Wins al perfil. El x2 se aplica ahí o en `WinPedestalService`, en un solo sitio.
- **Persistencia probada** (`DataService` con `UpdateAsync`, session lock, reintentos) y el precedente de `OwnedRestZoneIds`: lo pagado con Robux **no se pierde con el Rebirth**.
- **14 placas de descanso y 16 de wrap** authored, con carteles hijos y tags. El patrón "placa + cartel authored + tag + atributo" ya existe y se reutiliza para todo lo nuevo.

### El bloqueador técnico que ordena todo el plan

> `MarketplaceService.ProcessReceipt` es **un único callback en todo el juego, y no se puede leer, solo escribir**.

Hoy lo posee `RestZoneService`. En cuanto exista un segundo tipo de producto, quien instale el callback después borra al anterior **sin ningún error en consola**: las compras del primero simplemente dejan de entregarse y Roblox reintenta para siempre. El propio módulo ya lo deja anotado.

Por eso la **Fase 0 no es opcional ni se puede posponer**: hay que mudar el callback a un servicio de compras que enrute por `ProductId` antes de añadir el primer producto nuevo.

---

## 2. Decisiones de diseño que asume este plan

Si alguna no te cuadra, se cambia antes de ejecutar la fase correspondiente.

1. **Lo comprado con Robux nunca se pierde con el Rebirth.** Ya es la regla de `OwnedRestZoneIds`; se extiende a wraps premium, gamepasses y cosméticos comprados con Robux.
2. **El x2 Wins también cuenta para `TotalWinsEarned`.** Es la estadística que abre mundos. Contarlo es coherente con la regla del documento ("paying players accelerate those same loops"); no contarlo obligaría a llevar dos contadores y castigaría al que paga.
3. **Los precios en Robux de este plan son propuestas de partida**, marcados en cada fase. Se ajustan en la pasada final.
4. **Todos los ProductId y GamePassId nacen como placeholder**, igual que hoy en las Rest Zones. Los productos de verdad hay que crearlos en `create.roblox.com` (no se puede desde Studio ni por MCP) y pegar los ids; hay un `warn` al arrancar que los lista mientras sigan siendo falsos.
5. **Toda UI y toda placa nueva se crea authored en el editor** (regla 5.1 de `AGENTS.md`). Por eso cada fase con presencia visual pide una referencia antes de ejecutarse.
6. **Ninguna compra interrumpe el movimiento.** Regla del documento: los pop-ups son de confirmación, no bloqueos de cámara ni cortes de control.

---

## 3. Fases

### Fase 0 — Infraestructura de compras · ✅ **HECHA** (2026-08-13)

Es puramente de código y desbloquea todo lo demás.

- **`PurchaseService`** (nuevo, servidor): dueño único de `MarketplaceService.ProcessReceipt`. Registro `ProductId → handler` al que se apuntan los demás servicios; enruta, concede, persiste y solo devuelve `PurchaseGranted` si la concesión **y** su guardado salieron bien. Deduplicación por `receiptInfo.PurchaseId` persistida en el perfil, para que un recibo reentregado por Roblox no pague dos veces.
- **`GamePassService`** (nuevo, servidor): caché de propiedad por jugador (`UserOwnsGamePassAsync` con reintento), escucha `PromptGamePassPurchaseFinished` para conceder en caliente sin reconectar, y publica el atributo replicado `OwnedGamePassIds`. **La propiedad de un gamepass no se persiste**: Roblox es la fuente de verdad y guardarlo abriría la puerta a conservar un pase reembolsado.
- **`GameConfig.Monetization`** (nuevo): catálogo único de gamepasses y dev products, con `Id`, `DisplayName`, `RobuxPrice`, `AssetId` y descripción. Nadie escribe un id suelto en un servicio.
- **Migración de `RestZoneService`**: deja de instalar `ProcessReceipt` y se registra en `PurchaseService`. Sin cambios de comportamiento.
- **Perfil**: campo nuevo `ProcessedReceiptIds` (acotado a 50, purga por los más viejos). `ActiveBoosts` **se movió a la Fase 5**: añadir un campo que nadie lee todavía es peso muerto en el perfil.

**Resultado de la ejecución:**

- `ServerScriptService.Server.PurchaseService` y `ServerScriptService.Server.GamePassService` creados; `GameConfig.Monetization` con el catálogo, los dos gamepasses y los helpers `GetGamePass` / `GetGamePassByAssetId` / `GetDevProduct` / `GetPlaceholderPurchaseIds`.
- `RestZoneService` dejó de instalar `ProcessReceipt` y ahora registra sus 4 productos; su aviso de placeholders desapareció porque `PurchaseService` lo da una sola vez con la lista entera (gamepasses **y** rest zones).
- `DataService` guarda `ProcessedReceiptIds` con `HasProcessedReceipt` / `MarkReceiptProcessed`. Van por su propia API y no por `UpdateProfile` porque un recibo tiene que guardarse en el momento, no en el autosave.
- `Main` arranca `PurchaseService` y `GamePassService` justo detrás de `DataService`, delante de cualquiera que registre productos.

**Pruebas hechas (Play, un jugador):**

| Prueba | Resultado |
| --- | --- |
| Arranque del servidor | Sin errores. Un solo aviso de placeholders con los 6 ids (2 pases + 4 rest zones) |
| `GamePassService` publica propiedad | Atributo `OwnedGamePassIds = ""` presente en el jugador (distingue "no tiene nada" de "no ha replicado") |
| Regresión de Rest Zone gratuita | Sesión abierta (`RestZoneId = "RestZone1"`), Stickiness 0 → 2 en 8 s (2 cobros de 3 s). Sin cambios |
| Enrutado por `ProductId` | Dos productos registrados, cada uno con su dueño |
| Registro duplicado | Lanza con el mensaje explícito, no se traga en silencio |
| `PromptProduct` con id placeholder | No lanza; el segundo intento dentro del cooldown se frena |
| Teardown | Studio vuelve a Edit sin errores propios |

**No probado, y no se puede hasta la Fase 7:** el cobro real de un recibo y la deduplicación contra DataStore de verdad. Con ids placeholder no existe ningún recibo que procesar, y el mock de DataStore de Studio muere al salir de Play (misma limitación ya anotada para los wraps y los campos de mundo).

---

### Fase 1 — Gamepasses permanentes · ✅ **HECHA** (2026-08-13)

**x2 Wins** y **Speed Boost**, los dos del documento.

**Balance decidido:**

| Pase | Efecto | Precio |
| --- | --- | --- |
| `DoubleWins` | x2 Wins, y **cuentan para `TotalWinsEarned`** (desbloqueo de mundos) | R$ 199 |
| `SpeedBoost` | x1.5 WalkSpeed, con techo propio de 65 | R$ 149 |

El x1.5 sale de la referencia de UI del usuario. El techo de 65 es la decisión no obvia: **el pase multiplica después del recorte cosmético, no dentro del mismo paréntesis que Trail y Aura.** Eso garantiza que comprarlo no toque el balance de quien no lo compra — el jugador gratuito sigue topando en 52 exactamente como antes. 65 y no 78 (=52×1.5) porque 78 studs/s cruza una sala de ~35 studs en menos de medio segundo. El resultado medido:

| Nivel / Rebirths | base | gratis | gratis + cosméticos | con pase | pase + cosméticos |
| --- | --- | --- | --- | --- | --- |
| L1 R0 | 16.00 | 16.00 | 24.80 | 24.00 | 37.20 |
| L20 R2 | 23.75 | 23.75 | 36.81 | 35.62 | 55.22 |
| L60 R11 | 40.00 | 40.00 | 52.00 | 60.00 | 65.00 |

El pase entrega su x1.5 íntegro durante casi toda la partida y en el endgame se queda en +25% sobre el jugador gratuito.

**Construido:**

- `GameConfig.Monetization.GamePasses` con los efectos; `ApplyPerkBonus` acepta el multiplicador del pase con su propio techo (`LevelPerks.WalkSpeed.MaximumWithGamePass`).
- `ProgressionService.AwardWins` aplica el x2 y **devuelve cuánto concedió de verdad**. Sin ese segundo valor el pedestal anunciaba su cifra authored mientras el jugador recibía el doble; `WinPedestalService` ahora anuncia lo concedido y manda `BaseReward` aparte para poder celebrar la duplicación.
- `PerkService` recalcula al cambiar `OwnedGamePassIds` y publica `WalkSpeedPassMultiplier` aparte del factor cosmético — tienen techos distintos y fundirlos daría un número falso. `HUDController` lo lee para prometer el incremento del jugador con pase.
- `GameConfig.GetPerkGamePassMultiplier` centraliza **qué pase mueve qué perk**. Sin ese mapa, servidor y HUD podían acabar aplicando el multiplicador de velocidad al radio de adherencia.
- HUD: `StickyHUD.GamePassPanel` authored en el borde derecho, con `SpeedPass` y `WinsPass` (botón con degradado, contorno grueso, glifo de marca de agua y línea de precio verde), atributos `Compact*` para móvil y atributo `GamePassId` como contrato.
- Lobby: **trofeo de oro** authored en los dos lobbies (`Zones/<Lobby>/Geometry/WinsTrophy`), tag `GamePassDisplay`, con `TouchZone` atravesable de 15 studs y `TrophySign` en studs. Diseñado sin referencia: pedestal oscuro escalonado, columna, copa con asas y tapa, sobre la plaza central entre las dos alas de tienda.
- `GamePassController` (cliente) es dueño de las dos fichas **y** del trofeo. El cartel se pinta desde el cliente porque "comprado" es estado por jugador: uno pintado desde el servidor mostraría el estado de otro.
- `GameConfig.Monetization.StudioDebugOwnedPassIds`: concesión de prueba **solo en Studio**, con la puerta cerrada por código y no por acordarse de vaciar la lista. Sin ella el contenido de pago no se puede probar ni balancear hasta que existan los productos reales. Sirve igual para las fases 2-6.

**Pruebas hechas (Play, un jugador):**

| Prueba | Resultado |
| --- | --- |
| Velocidad con pase | `WalkSpeed` 16 → 24 y el Humanoid con ella; al retirarlo vuelve a 16 |
| Techos de la escalera | Tabla de arriba, verificada contra `GetPerkBase` / `ApplyPerkBonus` |
| El pase no toca el radio | `PickupRadiusPassMultiplier` = 1 en todos los casos |
| x2 Wins en pedestal real | Pedestal authored de 1 Win → `Wins 0 → 2`, `TotalWinsEarned 0 → 2`, `LastWinReward = 2` (lo concedido, no el cartel) |
| Fichas del HUD | `x1.5 Speed` / `ONLY R$ 149!` y `x2 Wins` / `ONLY R$ 199!`; con el pase pasan a `OWNED` y se atenúan |
| Trofeo | Cartel `X2 WINS / R$ 199`, y `OWNED` al tenerlo. Caminar contra él dispara el prompt sin errores |
| Teardown | Studio vuelve a Edit sin errores propios |

**No probado, y no se puede hasta la Fase 7:** una compra real de gamepass. Con `AssetId` placeholder la ventana de Roblox no abre nada y el evento `PromptGamePassPurchaseFinished` nunca llega; la propiedad se simuló con la concesión de Studio.

---

### Fase 2 — Precio en Robux sobre las placas · ✅ **HECHA** (2026-08-13)

**Decisión del usuario, y cambia el plan original: no hay pop-up de confirmación propio.** La ventana nativa de compra de Roblox *es* la confirmación. Lo que faltaba era que el mundo anunciara el precio, como en la referencia que pasó: precio grande en verde flotando sobre la placa y el nombre debajo.

Esto **elimina** el `PurchasePromptScreen` que planeaba la versión anterior de este documento, y con él la dependencia que las fases 3, 4 y 5 tenían de esa pantalla. Cada una lleva su precio sobre la pieza del mundo y abre el prompt nativo.

**El bug real que había detrás:** con el respaldo por Rebirths encendido, `IsRestZoneUnlocked` devolvía `RebirthRequired` antes de mirar si la placa era de pago. Consecuencia: **una placa de pago no enseñaba su precio ni abría su compra jamás** — el único camino visible era el gratuito. Ahora, si el tier es de pago y el jugador no ha alcanzado el Rebirth de respaldo, se le ofrece la compra; quien sí lo ha alcanzado la usa gratis, así que la escalera sigue entera y balanceable.

- `PriceTag` authored en las 8 placas de pago (4 por mundo): el cartel creció hacia arriba y la tarjeta bajó a ocupar su sitio de siempre, así que las tres líneas de dentro conservan sus proporciones.
- La línea de estado dejó de repetir el precio y ahora dice **la vía libre** (`OR REBIRTH 8`), que es la información que al jugador le faltaba. Con `RequirePurchaseForPaidTiers = true` dirá `ROBUX ONLY`.
- El precio solo se anuncia mientras se pueda comprar: a quien ya tiene acceso, por compra o por Rebirths, se le oculta.
- `RequirePurchaseForPaidTiers` sigue en `false` hasta la Fase 7, como estaba previsto.

**Pruebas hechas (Play, un jugador):**

| Placa | Cartel de precio | Línea de estado |
| --- | --- | --- |
| RestZone1 | — | `STEP TO REST` |
| RestZone2 / 3 | — | `🔒 REBIRTH 1` / `🔒 REBIRTH 5` |
| RestZone4…7 | `R$ 99` / `199` / `399` / `799`, visibles | `OR REBIRTH 8` / `10` / `12` / `14` |

Pisar la placa de pago devuelve ahora `Denied reason=PurchaseRequired robux=99` (antes `RebirthRequired`) y dispara el prompt. `PromptProductPurchaseFinished` no llega porque el ProductId es placeholder, que es lo esperado.

**Pendiente menor:** el precio va como texto `R$` y no con el hexágono de Robux de la referencia. Ninguna de las rutas de icono nativo de Roblox (`rbxasset://textures/ui/common/robux.png` y variantes) carga. Si consigues el icono como asset, el `PriceTag` es authored y cambiarlo es arrastrar un `ImageLabel` dentro.

---

### Fase 3 — Premium Sticky Wraps · ✅ **HECHA** (2026-08-13)

| Wrap | Ganancia | Precio | Se pierde al renacer |
| --- | --- | --- | --- |
| Infinity Glue (el mejor gratuito) | +750 | 600 Wins | Sí |
| **Eternal Glue** | +1.500 | R$ 199 | **No** |
| **Omega Glue** | +4.000 | R$ 499 | **No** |

**Lo que vende un wrap premium no es la ganancia, es que el Rebirth no se lo lleve.** Los ocho normales se borran al renacer y hay que recomprarlos con Wins cada ciclo; estos dos se quedan puestos, así que cada vuelta después de un Rebirth arranca a toda velocidad en vez de volver al `+1`. Por eso la línea del cartel dice `KEEPS ON REBIRTH` y no repite el precio.

- `Premium = true`, `ProductId` y `RobuxPrice` en `GameConfig.StickyWraps`. `WinCost = 0` **no significa gratis**: significa que no están a la venta por Wins, y tanto `TryBuyWrap` como `RequestWrap` lo rechazan explícitamente con `PurchaseRequired`.
- `TryRebirth` conserva los premium (mismo trato que `OwnedRestZoneIds`) **y mantiene el equipado si sobrevive**: obligar a volver a la placa a reequipar algo que nunca se perdió sería un paso vacío.
- `ProgressionService.GrantWrap`, idempotente y con guardado inmediato, registrado en `PurchaseService` desde `WrapService`.
- `WrapService.PromptPremiumPurchase` es el punto único donde "esto se paga con Robux" se convierte en ventana de compra. Lo llaman la pantalla del HUD y las placas del lobby con el mismo motivo devuelto por `RequestWrap`, así que las dos rutas no pueden divergir.
- 4 placas nuevas (2 por lobby), colocadas **relativas a la última placa normal**, así que el mismo cálculo sirvió para los dos mundos sin coordenadas absolutas. Marco dorado y `PriceTag` verde encima, el mismo estrenado en la Fase 2.
- El inventario del HUD muestra `R$ N` en vez de `🏆 0` en las filas premium y su botón siempre es pulsable. **No encienden el punto del botón del HUD**: ese aviso significa "ya puedes permitirte algo", y un premium se puede comprar siempre, así que lo dejaría encendido para siempre.

**Pruebas hechas (Play, un jugador):**

| Prueba | Resultado |
| --- | --- |
| Concesión del recibo | `GrantWrap("EternalGlue")` → `OwnedWrapIds = BasicGlue,EternalGlue`, equipado |
| **Supervivencia al Rebirth** | Antes: `BasicGlue,StrongGlue,EternalGlue` / equipado `EternalGlue` / Level 30. Después: `BasicGlue,EternalGlue` / equipado `EternalGlue` / Level 1 / Rebirths 1 / Wins intactas |
| Placa premium sin comprar | Pisar `WrapPad_OmegaGlue` → `Denied reason=PurchaseRequired Source=Pad` y se abre el prompt |
| Carteles | `OMEGA GLUE / R$ 499 / KEEPS ON REBIRTH` y `ETERNAL GLUE / EQUIPPED` (sin precio, ya comprado) |
| Placas normales | Sin cambios: siguen mostrando su coste en Wins |
| Teardown | Sin restos, consola limpia |

---

### Fase 4 — Double Win Plates · ✅ **HECHA** (2026-08-13)

**20 placas nuevas**, una reflejada al otro lado del pasillo frente a cada `WinPedestal`: el pedestal dorado a un lado, la placa doble morada al otro, las dos visibles al pasar. Tag `DoubleWinPad`, atributos `ZoneId` y `WinReward` copiados del pedestal hermano.

**Bandas de precio en vez de un producto por pedestal.** Hay 20 pedestales con 18 premios distintos entre los dos mundos; crear 18 dev products a mano y mantenerlos alineados con los atributos authored sería una fuente de errores permanente. Cada placa resuelve su banda por el premio de su pedestal hermano, así que **subir el premio de un pedestal en el editor mueve su placa de banda sola**.

| Banda | Cubre premios hasta | Precio | Ejemplos |
| --- | --- | --- | --- |
| `DoubleWin_S` | 10 | R$ 25 | W1 ToyRoom (1→2), Bedroom (3→6), Kitchen (10→20) |
| `DoubleWin_M` | 50 | R$ 49 | W1 Zone4-6, W2 ToyRoom (15→30), W2 Bedroom |
| `DoubleWin_L` | 300 | R$ 99 | W1 Zone7-10 (300→600), W2 Kitchen, W2 Zone4 |
| `DoubleWin_XL` | 1.500 | R$ 199 | W2 Zone5-8 (1500→3000) |
| `DoubleWin_XXL` | resto | R$ 399 | W2 Zone9-10 (4500→9000) |

La eficiencia (Wins por Robux) **sube** con la banda a propósito: de 0,8 a 22,6 Wins por Robux en el tope de cada una. Comprar el doble en el pedestal pequeño de tu banda es mal negocio y en el grande es bueno — exactamente la decisión que ya propone el sistema de pedestales: pasar de largo el pequeño y arriesgar la vuelta por el siguiente.

- **El premio sale del atributo authored del pedestal, nunca de `GameConfig.Zones`.** En el mundo 1 los dos llevan tiempo divergiendo y el que paga de verdad es el atributo; leer la config habría hecho que las placas del mundo 1 pagaran mal.
- **La reclamación se captura al pisar, no al llegar el recibo.** Entre el prompt y la entrega el jugador puede morir, rehacer la vuelta o desconectarse. Si el recibo llega y ya no se cumple la condición, **se pagan las Wins igual** (el dinero ya está puesto) y lo que se pierde es el teletransporte.
- **Sin reclamación viva se paga el tope de la banda** (`FallbackWins`): ante la duda, de más antes que de menos.
- **El x2 del gamepass se aplica encima**, porque `AwardWins` es el único punto por el que entran Wins: quien tenga los dos cobra x4. Es coherente con que los dos se anuncien como "duplica tus Wins".

**Pruebas hechas (Play, un jugador):**

| Prueba | Resultado |
| --- | --- |
| Sin la zona limpiada | No captura reclamación ni abre compra; ahora además avisa (`CLEAR THIS ZONE FIRST`) |
| Con la zona limpiada | Captura `Kitchen(10)` y abre la ventana |
| Cobro real (Kitchen, banda S) | `Wins +20` exactas, run reiniciada (`CompletedZone_Kitchen = false`) y teletransporte al inicio |
| Cobro real (W2_Zone10, banda XXL) | `Wins +9.000` exactas |
| Recibo repetido | Paga una sola vez |
| Recibo sin reclamación viva | Paga el `FallbackWins` de la banda (600) y no teletransporta |
| Reparto de bandas | Los 20 pedestales caen en la banda esperada |

**Herramienta nueva:** `PurchaseService.DebugSimulateReceipt` — entrega un recibo falso por el camino real (mismo enrutado, handler, deduplicación y guardado), **solo en Studio**. Sin ella ningún producto puede probarse hasta que existan los dev products. La usarán también las fases 5 y 6.

---

### Fase 5 — Stickiness Packs y Boosts temporales · ✅ **HECHA** (2026-08-13)

Aquí se llenó la `BoostRow` del HUD, que llevaba desde el 2026-08-06 como placeholder.

**Los packs se miden en objetos, no en un número fijo** (decisión del usuario: "que escalen con el rebirth"). Un `+3.000` fijo es una fortuna para quien empieza y menos de un objeto para quien lleva Omega Glue (+4.000), y en el mundo 2 —donde los requisitos son ×10— sería irrelevante desde el primer día. Medido en objetos, el pack vale siempre "tantas recogidas" y escala solo con el wrap, los Rebirths, el Trail y el Aura, porque reutiliza `GetStickinessGain`. Ningún sitio nuevo que recordar cuando cambie el balance.

| Pack | Objetos | Precio | Con Basic Glue | Con Omega Glue |
| --- | --- | --- | --- | --- |
| `Pack_S` | 250 | R$ 25 | +250 | +1M |
| `Pack_M` | 1.000 | R$ 79 | +1.000 | +4M |
| `Pack_L` | 5.000 | R$ 199 | +5.000 | +20M |
| `Pack_XL` | 25.000 | R$ 449 | +25.000 | +100M |

**Boosts temporales:** `x2 Sticky` (R$ 49) y `x2 Wins` (R$ 79), 10 minutos cada uno.

- La caducidad se guarda como **marca de tiempo absoluta** (`os.time()`), no como tiempo restante: guardar lo que queda haría que salir del juego congelara el boost, convirtiendo un producto de 10 minutos en uno infinito para quien sepa desconectarse.
- **Comprar uno ya activo suma tiempo** en vez de reiniciarlo, con techo de 4 horas. Reiniciarlo haría que comprar dos seguidos valiera menos que comprar uno.
- El multiplicador **no se aplica en `BoostService`**: se publica en el atributo `ActiveBoosts` y lo leen `AddStickinessFromCurrentWrap` y `AwardWins`, que son los dos únicos puntos por donde entra progreso. Así la Rest Zone, los pedestales y las Double Win Plates lo heredan sin una línea aparte.
- El boost **no** entra en el cálculo del pack: son dos compras distintas y multiplicar una por la otra regalaría el doble por comprarlas en el orden correcto.
- HUD: los 4 botones de `BoostRow` conectados con su cantidad real, `BoostPanel` con los dos boosts en la columna derecha bajo los gamepasses, y `ActiveBoostChip` con cuenta atrás sobre el panel de stats.

**Pruebas hechas (Play, un jugador):**

| Prueba | Resultado |
| --- | --- |
| `Pack_S` con Basic Glue | `+250` (250 × 1) |
| `Pack_S` con Omega Glue | `+1.000.000` (250 × 4.000) — escala exacta |
| Boost de Stickiness | Recogida `+8.000` en vez de `+4.000` |
| Boost apilado | Caducidad `+600s` sobre la anterior, no reinicio |
| Boost de Wins | `AwardWins(10)` concede 20 |
| Caducidad | Un boost pasado devuelve multiplicador 1; mezclado resuelve por tipo; basura e ids inventados se ignoran |
| HUD | `+1M / +4M / +20M / +100M` con sus precios, los dos boosts en `ACTIVE` y el chip contando `x2 Sticky 19:31   x2 Wins 9:31` |

---

### Fase 6 — Skip Rebirth y Robux en Trails/Auras · ✅ **HECHA** (2026-08-13)

Construida sobre las dos referencias del usuario: el Skip Rebirth arcoíris junto al Rebirth verde con `KEEP ALL STATS!` debajo, y las filas de cosmético con **los dos precios visibles a la vez**, cada uno con su botón.

**Skip Rebirth (R$ 149).** Lo que se compra no es saltarse el nivel, es **no perder nada**. Sube `Rebirths` —y con él el multiplicador y el techo de nivel— y no toca Stickiness, Level, Sticky Wraps ni cosméticos. El Rebirth gratuito sigue exigiendo llegar al nivel y sigue borrándolo todo.

- Son **dos funciones separadas y no una con bandera** (`TryRebirth` / `TrySkipRebirth`): compartirlas invitaría a que un cambio en el reinicio se colara en la versión de pago.
- No exige nivel —saltarse ese requisito es justo lo que se paga— pero sí respeta `GetMaximumRebirth()`: por encima de ahí no hay niveles generados y el sistema entero quedaría apagado.
- **Se deshace si el guardado falla, y no es opcional.** A diferencia de conceder un wrap o un aura, sumar un Rebirth no tiene forma natural de ser idempotente: sin el rollback, el reintento del recibo sumaría un Rebirth de más sobre el ya aplicado en memoria.
- No teletransporta ni cierra la pantalla: el jugador acaba de pagar y lo que quiere ver es el antes/después ya actualizado.

**Trails y Auras con Robux.** `RobuxProductId` y `RobuxPrice` en los ocho cosméticos, como **vía paralela** a las Wins y no como sustituto.

| Cosmético | Wins | Robux |
| --- | --- | --- |
| Basic / Green / Blue / Golden Trail | 15 / 30 / 50 / 75 | 29 / 49 / 79 / 99 |
| Green / Blue / Purple / Golden Aura | 20 / 50 / 75 / 100 | 39 / 79 / 99 / 129 |

La fila del inventario acabó con **tres formas**, resueltas por la misma función: Wins + Robux (cosméticos), solo Robux (wraps premium) y solo Wins (todo lo demás). Cuando solo hay una vía, ocupa la fila entera en vez de dejar un hueco.

**Pruebas hechas (Play, un jugador):**

| Prueba | Resultado |
| --- | --- |
| Cosmético con Robux | Concedido y equipado, `Wins 190 → 190` (no se descuentan) |
| Recibo repetido | Concede una sola vez |
| **Skip Rebirth** | `Rebirths 0 → 1` y **todo lo demás intacto**: Stickiness 640, Level 22, wraps `BasicGlue,SuperGlue`, trail equipado |
| Techo tras el skip | El Rebirth gratuito pasa a pedir `LEVEL 25`, coherente con el cap subido |
| Vía Robux desde el remote | No cae por accidente en la compra con Wins: saldo intacto |
| Filas del inventario | Trails con doble precio y doble botón; wraps normales solo Wins; premium solo Robux |

**Bug encontrado y corregido durante la fase:** un `UIGradient` sobre un `TextButton` **tiñe también la letra**, así que el texto blanco del Skip salía arcoíris sobre fondo arcoíris — invisible. El texto se mudó a un `TextLabel` hijo, que el gradiente del padre no toca. Es la misma solución que ya se había usado en las fichas de gamepass.

---

### Fase 7 — Cierre y publicación

- Lista final de **todos los gamepasses y dev products a crear** en `create.roblox.com`, con nombre, descripción y precio propuesto. Los creas tú (no es posible desde Studio ni por MCP), me pasas los ids y los pego.
- `ProductIdsArePlaceholders = false`, `RequirePurchaseForPaidTiers = true`, `WorldTravel.DebugUnlockEnabled = false`.
- Pasada de balance sobre los precios completos, con la escalera entera a la vista.
- Prueba manual de compra real en un place de prueba, actualización de `PROJECT_MEMORY.md`, `PLAN_MVP.md` y `MANUAL_TEST_CHECKLIST.md`.

---

## 4. Riesgos anotados

- **`ProcessReceipt` único** — resuelto por la Fase 0, pero es la causa de que el orden de fases no se pueda alterar.
- **Los ids placeholder no se pueden probar de verdad.** Todo el flujo se valida con productos falsos: el prompt de Roblox falla, que es lo esperado. La prueba de compra real solo existe después de crear los productos.
- **`TotalWinsEarned` abre mundos.** Cualquier fuente nueva de Wins (x2, Double Win Plates, boosts) mueve el desbloqueo de mundos. Está contemplado en la decisión 2, pero conviene revisar los requisitos del mundo 2 (hoy 10 Rebirths y 5.000 Wins) cuando exista el x2.
- **El techo de `PerkService`** puede tragarse el Speed Boost de pago. Se comprueba en la Fase 1, no al final.
- **Divergencia `GameConfig` ↔ Workspace en el mundo 1** (pendiente ya anotado en `PROJECT_MEMORY`): los `WinReward` reales salen del atributo authored. Las Double Win Plates tienen que leer el atributo del pedestal hermano, **nunca** el valor de config, o pagarían mal en el mundo 1.
