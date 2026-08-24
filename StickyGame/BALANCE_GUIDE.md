# Guía de balance — Stuck to You

Para el game designer. Dice, punto por punto, **dónde** se toca cada cosa en el place,
**qué opciones** hay y **qué cuidado** hay que tener.

## Regla general

Casi todo el balance vive en un solo sitio:

```
ReplicatedStorage → Shared → GameConfig   (ModuleScript, ~2.500 líneas)
```

Se abre en el Explorer de Studio y se edita como texto. Las tablas están separadas por
comentarios largos que explican por qué está puesto cada número: **léelos antes de mover
nada**, porque varios valores se eligieron contra otro valor y moverlos sueltos rompe la
relación.

Lo que **no** vive en GameConfig son los valores *authored*: atributos puestos a mano sobre
instancias del Workspace. Cuando existen, **ganan sobre GameConfig**. Son tres casos y están
señalados en cada punto de abajo.

Después de tocar GameConfig hay que reiniciar el Play: el módulo se lee una vez al arrancar.

---

## 1. Stickiness base de cada objeto (diferencias por tipo)

**Estado: no se puede hacer solo con configuración. Necesita un cambio de código pequeño.**

Dónde está la tabla:

```
GameConfig.CollectibleTypes
  { Id = "ToyBlock", DisplayName = "Toy Block", Template = "ToyBlock", GainMultiplier = 1 },
  ... 9 tipos: ToyBlock, ToyBall, ToyCar, Pillow, Sock, Book, Apple, Mug, Plate
```

El campo `GainMultiplier` **ya existe** y `RoomSettingsReader` lo lee y lo mete en cada objeto
colocado, pero **nadie lo usa después**. La fórmula real de ganancia es:

```
Gain = WrapBaseGain × (RebirthMultiplier + TrailAddition) × AuraMultiplier
```

(`GameConfig.GetStickinessGain`, y quien la llama es `ServerScriptService.Server.ProgressionService`)

Ahí no entra el tipo de objeto: hoy un calcetín y un coche dan exactamente lo mismo.

**Opciones:**

| Opción | Qué implica |
| --- | --- |
| **A. Conectar `GainMultiplier` (recomendada)** | Cambio de una línea en la concesión del servidor para multiplicar por el `GainMultiplier` del objeto recogido. A partir de ahí el diseñador balancea solo con la tabla: `0.8 / 1 / 1.3`, etc. Pídelo como tarea de código. |
| **B. Simular la progresión sin tocar código** | Se puede hoy mismo, con dos palancas que sí están conectadas: ver abajo. |

**Palancas que sí funcionan hoy para diferenciar objetos:**

- **`CollectibleRequirements`** por sala, en `GameConfig.Zones` — cuatro umbrales
  (`{ 0, 5, 12, 25 }` en Toy Room). Cada objeto colocado toma uno de esos cuatro requisitos,
  así que dentro de la misma sala ya hay objetos "baratos" y "caros" de desbloquear. Es la
  progresión *dentro* de la sala. Los cuatro se reparten a 0 %, 25 %, 50 % y 75 % del tramo
  entre entrar y abrir la puerta.
- **`ObjectPool` + atributo `Weight`**, authored por sala:
  ```
  Workspace → StuckToYou → Zones → <Sala> → RoomSettings → ObjectPool → <ObjectValue>
  ```
  Cada entrada apunta a una plantilla de `ReplicatedStorage.Assets.Collectibles` y admite un
  atributo numérico `Weight` (por defecto 1). Sube el peso y ese objeto sale más veces.
- **`TotalObjects`** y **`MinSeparationStuds`**, también en `RoomSettings` (IntValue /
  NumberValue). Cuántos objetos hay a la vez y cuán juntos. Estos dos **sí** son authored y
  pisan a los de `GameConfig.Zones`.

---

## 2. Sticky Wraps: stickiness ganada y precio

```
GameConfig.StickyWraps          ← catálogo, 10 entradas
GameConfig.Wraps                ← comportamiento de las placas del lobby
```

Cada entrada: `Id`, `DisplayName`, `WinCost`, `BaseGain`, `Color`, y en los premium
`Premium = true`, `ProductId`, `RobuxPrice`.

Estado actual:

| Wrap | Coste (Wins) | BaseGain |
| --- | --- | --- |
| Basic Glue | 0 | 1 |
| Strong Glue | 3 | 3 |
| Super Glue | 10 | 8 |
| Cosmic Glue | 30 | 20 |
| Quantum Glue | 75 | 50 |
| Nova Glue | 150 | 120 |
| Galaxy Glue | 300 | 300 |
| Infinity Glue | 600 | 750 |
| Eternal Glue | Robux 199 | 1.500 |
| Omega Glue | Robux 499 | 4.000 |

**Qué tocar:** `BaseGain` es el multiplicador **base** de toda la economía — todo lo demás
(Rest Zone, packs de boost, Trails, Auras) se calcula a partir de él, así que moverlo mueve el
juego entero. `WinCost` es seguro de mover en aislamiento.

**Criterio que ya está aplicado y conviene mantener:** ganancia ×2,5 por peldaño, precio ×2 por
peldaño. Comprar el siguiente cuesta lo mismo que todo lo comprado hasta ahora. Si quieres que
el juego se sienta más rápido, baja los `WinCost`; si quieres que se sienta más largo, súbelos.
Tocar `BaseGain` para eso es el camino difícil.

**Ojo:** el Rebirth **borra** los wraps comprados con Wins (los premium no). Por eso los
precios son bajos a propósito. Si subes mucho un `WinCost`, recuerda que el jugador vuelve a
pagarlo cada Rebirth.

**Dónde está cada placa en el mundo:**
```
Workspace → StuckToYou → Zones → Lobby → Geometry → WrapPad_<WrapId>
```
Cada placa lleva un atributo `WrapId`. Reasignar qué placa vende qué wrap es cambiar ese
atributo, sin tocar código. El cartel `WrapSign` es hijo authored de cada placa.

---

## 3. Rest Zones: stickiness ganada y tiempo

```
GameConfig.RestZones
```

Fórmula:

```
RestZoneGain = WrapBaseGain × (RebirthMultiplier + TrailAddition) × AuraMultiplier × Multiplier_de_la_placa
```

cada **`TickSeconds`**.

**Los dos números:**

- **`TickSeconds = 3`** — cadencia. **Es global, una sola para las siete placas.** No hay
  tiempo por tier hoy.
- **`Multiplier`** por tier, dentro de `RestZones.Tiers`:
  `1 → 1.5 → 3 → 5 → 10 → 20 → 30`

**Referencia para calibrar:** jugando se recogen 1–2 objetos por segundo. Con tick de 3 s, la
placa gratis rinde entre 1/3 y 1/6 de jugar; la de ×3 llega a la par; las de pago la superan.
Ese arco es intencionado.

**Opciones:**

| Quieres | Toca |
| --- | --- |
| Que el AFK rinda más/menos **en bloque** | `TickSeconds` (bajar = más rendimiento) |
| Cambiar la pendiente entre placas | los `Multiplier` de cada tier |
| **Tiempo distinto por placa** | **no existe** — hay que añadir un `TickSeconds` por tier. Es un cambio pequeño en `ServerScriptService.Server.RestZoneService` (usa `config.TickSeconds` global en dos sitios). Pídelo si lo necesitas. |

**Dónde están las placas:**
```
Workspace → StuckToYou → Zones → Lobby → Geometry → RestZonePlates → RestPad_RestZone1..7
```
Atributo `RestZoneId` en cada una: reasignar qué placa es qué tier es arrastrar un valor.

---

## 4. Requisitos de las Rest Zones

Misma tabla, `RestZones.Tiers`, campo **`RequiredRebirths`**:

| Tier | Multiplier | RequiredRebirths | Pago |
| --- | --- | --- | --- |
| RestZone1 | 1 | 0 | — |
| RestZone2 | 1.5 | 1 | — |
| RestZone3 | 3 | 5 | — |
| RestZone4 | 5 | 8 | Robux 99 |
| RestZone5 | 10 | 10 | Robux 199 |
| RestZone6 | 20 | 12 | Robux 399 |
| RestZone7 | 30 | 14 | Robux 799 |

**Tres interruptores globales en `GameConfig.RestZones` que cambian lo que ves al probar:**

- **`RequirePurchaseForPaidTiers = false`** — hoy los tiers de pago se desbloquean **o**
  comprando **o** llegando a su `RequiredRebirths`. Así toda la escalera es jugable y
  balanceable. **Hay que ponerlo en `true` al monetizar.** Mientras esté en `false`, el
  `RequiredRebirths` de los tiers 4–7 **es** el balance real.
- **`ProductIdsArePlaceholders = true`** — los ProductId de arriba son inventados; una compra
  real fallará en el prompt de Roblox. No es un bug de balance.
- **`PurchasePromptCooldownSeconds = 8`** — cada cuánto se reabre el prompt al pisar una placa
  bloqueada.

**Ojo con el tope:** el máximo de Rebirths que permite el balance actual es **17** (ver punto
8). Un `RequiredRebirths` por encima de eso deja la placa muerta para siempre.

---

## 5. Stickiness para subir de nivel, y la barra de nivel

```
GameConfig.LevelThresholds     ← 20 umbrales a mano
GameConfig.LevelExtension      ← generación automática del 21 al 100
```

Los 20 primeros son curva a mano: `0, 5, 12, 20, 30, 45, 60, 80, 95, 110, 135, 165, 195, 225,
260, 300, 345, 395, 445, 500`.

Del 21 en adelante se generan al cargar el módulo: se continúa el último salto (500 − 445 = 55)
y se hace crecer un porcentaje fijo:

```
GameConfig.LevelExtension = {
    MaxLevel = 100,      -- último nivel que existe
    StepGrowth = 1.1,    -- cada salto es un 10% mayor que el anterior
}
```

**Opciones:**

| Quieres | Toca |
| --- | --- |
| Retocar la curva temprana (niveles 1–20) | los números de `LevelThresholds`, uno a uno |
| Alargar/acortar el tramo a mano | añadir o quitar entradas de `LevelThresholds` — la generación arranca donde acabe la tabla, sea cual sea su longitud |
| Endgame más largo o más corto | `StepGrowth` (1.05 = curva más plana y niveles más rápidos; 1.2 = muro) |
| Más niveles totales | `MaxLevel` — **sube también el techo de Rebirths**, ver punto 8 |

**La barra de nivel ya lo refleja sola. No hay nada que sincronizar.**
`StarterPlayer.StarterPlayerScripts.Client.HUDController` mide el progreso *dentro del nivel
actual* (`stickiness − umbral_actual` sobre `umbral_siguiente − umbral_actual`), leyendo la
misma tabla. En el último nivel generado la barra se llena y el texto dice `MAX`.

Las instancias de la barra son authored y se editan en Studio (tamaño, fuente, colores):
```
StarterGui → StickyHUD → StatsPanel → LevelBar → { Fill, LevelText, AmountText }
```
El código solo escribe el `Size` del `Fill` y el texto. **No renombres esas instancias**: el
HUD falla en voz alta si no las encuentra.

---

## 6. Trails: stats y precios

```
GameConfig.Trails      ← catálogo
GameConfig.Cosmetics   ← comportamiento común de Trails y Auras
```

| Trail | WinCost | Robux | MultiplierAddition | SpeedBonus |
| --- | --- | --- | --- | --- |
| trail_basic | 15 | 29 | +0.5 | +10 % |
| trail_green | 30 | 49 | +1.0 | +15 % |
| trail_blue | 50 | 79 | +1.5 | +20 % |
| trail_gold | 75 | 99 | +3.0 | +30 % |

**Cómo entra cada stat** (importante, porque los dos campos no se comportan igual):

- **`MultiplierAddition` se SUMA al multiplicador de Rebirth**, no multiplica:
  `Gain = BaseGain × (RebirthMultiplier + TrailAddition) × AuraMultiplier`.
  Un `+3.0` vale como 6 Rebirths a un jugador nuevo y casi nada a uno con 15. Es la palanca de
  *early game*.
- **`SpeedBonus` es un porcentaje plano** que se suma al del Aura y se aplica sobre la
  velocidad base ya calculada. Techo final en `LevelPerks.WalkSpeed.MaximumWithBonuses = 52`.
- Los Trails **no** tocan el radio de recogida. Eso es solo del Aura.
- El Rebirth **no** borra los cosméticos (`Cosmetics.ResetOnRebirth = false`). Por eso pueden
  costar bastante más que un wrap.

Las plantillas visuales son authored:
`ReplicatedStorage → Assets → Cosmetics → Trails → trail_basic / green / blue / gold`.
El `Id` de GameConfig tiene que coincidir con el nombre de la carpeta/instancia.

---

## 7. Auras: stats y precios

```
GameConfig.Auras
```

| Aura | WinCost | Robux | StickinessMultiplier | SpeedBonus | RadiusBonus |
| --- | --- | --- | --- | --- | --- |
| aura_green | 20 | 39 | ×1.5 | +10 % | +5 % |
| aura_blue | 50 | 79 | ×2.0 | +15 % | +10 % |
| aura_purple | 75 | 99 | ×2.5 | +20 % | +15 % |
| aura_gold | 100 | 129 | ×3.0 | +25 % | +20 % |

**Diferencia clave con el Trail:** `StickinessMultiplier` **multiplica el resultado ya
combinado**. Un ×3 es ×3 siempre, tenga el jugador 0 o 15 Rebirths. Es la palanca de *late
game*, y es la más peligrosa de subir: multiplica todo, incluida la Rest Zone y los packs.

Máximos combinados hoy: **+55 % de velocidad** (trail_gold + aura_gold) y **+20 % de radio**.
Los techos que impiden que eso rompa el juego están en `GameConfig.LevelPerks`:

```
WalkSpeed.Maximum             = 40   -- techo de la base (nivel + rebirths)
WalkSpeed.MaximumWithBonuses  = 52   -- techo con Trail + Aura
WalkSpeed.MaximumWithGamePass = 65   -- techo solo para quien tiene el pase
PickupRadius.Maximum          = 12
PickupRadius.MaximumWithBonuses = 15
```

**Si subes los bonus de Aura/Trail, sube también `MaximumWithBonuses`** — si no, el cosmético
nuevo no hace nada en el endgame y la mitad de su valor desaparece. Y ojo al revés: las salas
miden ~35 studs, por encima de ~52 de velocidad el personaje se pasa de largo los objetos.

Plantillas authored: `ReplicatedStorage → Assets → Cosmetics → Auras → aura_*` (carpetas con
ParticleEmitters).

---

## 8. Rebirth: caps de nivel y multiplicador

```
GameConfig.Rebirth
```

```lua
BaseLevelCap        = 20    -- nivel que hay que alcanzar para el Rebirth 1
LevelCapPerRebirth  = 5     -- cada Rebirth pide 5 niveles más
MultiplierPerRebirth = 0.5  -- cada Rebirth da +0.5 al multiplicador
LevelCapOverrides   = {}    -- excepciones a mano, ganan sobre la fórmula
```

- **Nivel requerido para el Rebirth N** = `20 + N × 5`
- **Multiplicador** = `1 + Rebirths × 0.5` → R1 = ×1.5, R10 = ×6, R17 = ×9.5

> ⚠️ Esta tabla y las dos fórmulas de arriba están **desactualizadas** frente a
> `GameConfig.Rebirth`, que hoy interpola de `BaseLevelCap = 20` a `MaximumLevelCap = 500` sobre
> `MaximumRebirths = 100` y usa `MultiplierAdditionOverrides` cada 5 Rebirths. Los conceptos
> siguen siendo los mismos; los números, no. Pendiente de repasar el punto 8 entero.

**El nivel requerido para el Rebirth es también el nivel máximo** (2026-08-19). Al alcanzarlo,
el Level se queda quieto hasta renacer: la barra del HUD se llena y pasa a `Level N MAX` /
`REBIRTH!`. Es una decisión de claridad — el jugador ve sin ambigüedad que ya cumple el
requisito y que lo único que queda es renacer.

Lo que **no** se congela es la Stickiness, y no puede congelarse: los blockers de las últimas
salas piden mucho más que el último umbral de nivel del ciclo. Lo que sí se congela con el Level
son los perks (velocidad y radio), porque se calculan a partir de él.

El Skip Rebirth descongela el nivel al instante: sube el techo y, como conserva la Stickiness,
el Level salta hasta donde llegue con lo que ya tenía.

**El techo real de Rebirths es 17, y no está aquí.** Sale de que el nivel requerido no puede
pasar de `LevelExtension.MaxLevel` (100): `20 + 16×5 = 100`. Para permitir más Rebirths hay que
subir **`GameConfig.LevelExtension.MaxLevel`** (punto 5), no solo los números de esta tabla.

**Opciones:**

| Quieres | Toca |
| --- | --- |
| Rebirths más frecuentes | bajar `LevelCapPerRebirth` |
| Que cada Rebirth valga más | subir `MultiplierPerRebirth` — afecta a **todo**: recogida, Rest Zone, packs de boost |
| Un techo raro para un Rebirth concreto | `LevelCapOverrides = { [5] = 60 }` |
| Más Rebirths totales | `LevelExtension.MaxLevel` |

**Efecto secundario que hay que tener presente:** el Rebirth también sube el *suelo permanente*
de velocidad y radio (`LevelPerks.WalkSpeed.PerRebirth = 2`,
`LevelPerks.PickupRadius.PerRebirth = 0.6`). Como el nivel se reinicia, renacer **cuesta**
velocidad a corto plazo. Con los valores actuales esa caída arranca en −1,75, culmina en −9,25
hacia el Rebirth 6 y vuelve a cero en el 11. Si mueves `LevelCapPerRebirth` o `PerRebirth`, ese
arco cambia — es lo primero que hay que volver a probar.

`Rebirth.Skip` es el Rebirth comprado con Robux (149): sube Rebirths **sin** reiniciar nada.
Respeta el mismo techo de 17.

---

## 9. Worlds: costos y requisitos

```
GameConfig.Worlds             ← qué mundos hay y qué piden
GameConfig.WorldRequirements  ← qué tipos de requisito existen
GameConfig.WorldTravel        ← comportamiento del portal
GameConfig.Zones              ← la escala de cada sala de cada mundo
```

**Requisitos de entrada:**

```lua
World1 → Requirements = {}                              -- nunca se cierra
World2 → Requirements = { Rebirths = 10, WinCost = 2500 }
World3 → Requirements = { Rebirths = 31, WinCost = 75000 }
```

Hay dos tipos de requisito declarados (`GameConfig.WorldRequirements`) y **no funcionan
igual**:

| Tipo | Ejemplo | Qué hace |
| --- | --- | --- |
| Puerta (`Spend` ausente) | `Rebirths` | Se comprueba y no se toca |
| Precio (`Spend = true`) | `WinCost` | Se mide contra el **saldo** de Wins y se **cobra** |

**Las Wins de un mundo son un precio, no una marca histórica** (2026-08-19). Funcionan igual
que en la tienda de Sticky Wraps: hay que tenerlas en el momento de abrir el mundo, y al
abrirlo desaparecen del saldo. Por eso el desbloqueo dejó de ser automático — cobrar solo, en
el instante en que el saldo cruza el precio, le vaciaría las Wins a quien las estaba ahorrando
para un wrap. El jugador pulsa `UNLOCK 🏆 2.5K` en la pantalla del portal y el servidor cobra.

Una vez concedido, el mundo es **permanente**: gastar Wins después no vuelve a cerrarlo.

Un requisito nuevo ("tener Galaxy Glue", "haber acabado el mundo 2") es una entrada más en esa
tabla y un cambio pequeño en quien evalúa; pídelo si lo necesitas.

**El "costo" real de un mundo es su escala, y vive en `GameConfig.Zones`:**

El mundo 2 es el mundo 1 con **requisitos ×10 y Wins ×15**. Esa diferencia entre los dos
factores es el balance entero del mundo: pagar 15 veces más por 10 veces más esfuerzo deja el
mundo 2 un 50 % más rentable por unidad de Stickiness.

> Si el mundo 2 se siente obligatorio o inútil, **mueve ese 15 y nada más.**

Por sala (20 entradas, 10 por mundo):

| Campo | Qué es |
| --- | --- |
| `EntryStickiness` | Stickiness con la que se entra |
| `BlockerRequiredStickiness` | lo que pide la puerta al final |
| `CollectibleRequirements` | los 4 umbrales de objeto (0 %, 25 %, 50 %, 75 % del tramo) |
| `WinReward` | Wins que paga el pedestal del pasillo |
| `TotalObjects`, `MinSeparationStuds` | densidad (los pisa `RoomSettings` si existe) |
| `ExpectedSeconds` | referencia de diseño, no lo usa el código |

### ⚠️ Los dos valores authored que ganan sobre GameConfig

Esto es lo que más confunde. Dos números de `GameConfig.Zones` **no son los que manda**:

1. **`BlockerRequiredStickiness`** — quien decide es el atributo **`RequiredStickiness`** del
   blocker en el Workspace:
   ```
   Workspace → StuckToYou → Zones → <Sala> → Blockers → <Blocker>
   ```
   En el mundo 1 los dos llevan tiempo divergiendo. **Si cambias el de GameConfig y no ves
   efecto, es por esto.**

2. **`WinReward`** — quien decide es el atributo **`WinReward`** del pedestal, en
   `Workspace → StuckToYou → Corridors → <Sala>Exit`. Solo cae al valor de GameConfig si el
   pedestal no lo tiene puesto.

   Además, la Double Win Plate hermana lee el `WinReward` **authored del pedestal** y resuelve
   sola su banda de precio en Robux (`GameConfig.DoubleWins.Tiers`): subir el premio de un
   pedestal en el editor mueve su placa de banda automáticamente.

### Interruptor de pruebas que hay que apagar antes de publicar

```lua
GameConfig.WorldTravel.DebugUnlockEnabled = true
```

Enciende el botón "desbloquear todo" en la pantalla del portal y hace que el servidor lo
acepte. **Es la única vía que se salta los requisitos.** Mientras esté encendido no puedes
juzgar si el gate del mundo 2 está bien puesto. El servidor avisa por consola al arrancar.

---

## Resumen: qué se puede balancear hoy y qué no

| # | Tema | ¿Solo configuración? |
| --- | --- | --- |
| 1 | Stickiness base por objeto | ❌ **necesita conectar `GainMultiplier`** (cambio pequeño) |
| 2 | Wraps: ganancia y precio | ✅ `GameConfig.StickyWraps` |
| 3 | Rest Zone: ganancia | ✅ `RestZones.Tiers[].Multiplier` |
| 3 | Rest Zone: tiempo **por placa** | ❌ solo hay un `TickSeconds` global |
| 4 | Requisitos de Rest Zone | ✅ `RequiredRebirths` + `RequirePurchaseForPaidTiers` |
| 5 | Curva de nivel y barra | ✅ `LevelThresholds` + `LevelExtension`; la barra se ajusta sola |
| 6 | Trails | ✅ `GameConfig.Trails` (+ techos en `LevelPerks`) |
| 7 | Auras | ✅ `GameConfig.Auras` (+ techos en `LevelPerks`) |
| 8 | Rebirth | ✅ `GameConfig.Rebirth`, pero el techo de 17 sale de `LevelExtension.MaxLevel` |
| 9 | Worlds | ✅ `GameConfig.Worlds` + `Zones`, **ojo con los dos atributos authored** |

## Antes de dar por bueno un cambio

1. Reinicia el Play (GameConfig se lee una vez al arrancar).
2. Si tocaste una puerta o un premio, comprueba el **atributo del Workspace**, no solo el config.
3. Apaga `WorldTravel.DebugUnlockEnabled` para juzgar los gates de mundo.
4. Recuerda que `RestZones.RequirePurchaseForPaidTiers = false` hace jugables los tiers de pago
   por Rebirths: eso es lo que estás midiendo, no la versión monetizada.
5. Registra qué probaste y el resultado en `PLAN_MVP.md` (regla 1 de `AGENTS.md`).

## 10. Eventos de mundo

Todo vive en `GameConfig.WorldEvents`. Añadir un evento es añadir una fila al `Catalog`; no hay código que tocar.

### Ritmo

| Valor | Por defecto | Qué controla |
| --- | --- | --- |
| `DurationSeconds` | 300 (5 min) | Cuánto dura un evento |
| `CooldownMinSeconds` / `CooldownMaxSeconds` | 600 / 900 | Hueco entre eventos (10-15 min) |
| `FirstDelayMinSeconds` / `FirstDelayMaxSeconds` | 120 / 300 | Espera hasta el primer evento del servidor |
| `MinimumPlayers` | 1 | Debajo de esto no se gasta un evento |
| `EmptyServerRetrySeconds` | 60 | Cada cuánto se reintenta con el servidor vacío |
| `AvoidRepeatCount` | 2 | Cuántos eventos recientes no pueden repetirse |

Con estos valores un jugador ve un evento aproximadamente cada 15-20 minutos y está bajo evento **entre un 25 % y un 33 % del tiempo**. Subir la duración o bajar el cooldown mueve ese porcentaje directamente; es la palanca principal si el juego se siente lento.

### Fila del catálogo

```lua
{
    Id = "StickyStorm",          -- id interno, no se muestra
    DisplayName = "STICKY STORM!",
    Tagline = "2X STICKINESS",   -- segunda línea del cartel, antes del reloj
    Kind = "Stickiness",         -- Stickiness | Wins | Speed | Radius | Spawn
    Multiplier = 2,
    SkyColor = Color3.fromRGB(60, 255, 120),
    Weight = 1,                  -- opcional: peso del sorteo
    Rainbow = false,             -- opcional: el color rota con el tiempo
}
```

`Kind` es lo único que decide en qué fórmula entra:

| `Kind` | Dónde multiplica | Hereda automáticamente |
| --- | --- | --- |
| `Stickiness` | `AddStickinessFromCurrentWrap` | Recogidas y Rest Zones |
| `Wins` | `AwardWins` | Pedestales y Double Win Plates |
| `Speed` | `WalkSpeed` del perk | — |
| `Radius` | Radio de adherencia | Sensor del cliente y validación del servidor |
| `Spawn` | Espera de reposición | Todas las salas |

### Topes de velocidad y radio

Un evento de `Speed` o `Radius` no puede desbordar el juego: multiplica **después** de todos los demás topes y se recorta contra el suyo.

| Perk | Tope sin evento | `MaximumWithEvent` |
| --- | --- | --- |
| `WalkSpeed` | 52 (65 con gamepass) | 80 |
| `PickupRadius` | 15 | 24 |

Un x2 de velocidad se entrega íntegro mientras la velocidad previa no pase de 40, que es casi toda la partida. Por encima de 80 studs/s el personaje cruza una sala de ~35 studs en menos de medio segundo y se pasa de largo los objetos: si se sube este tope, hay que probar la recogida antes de darlo por bueno.

### Reposición

`Spawn` divide `Collection.RespawnSeconds`. El suelo es `MinimumRespawnSeconds` (0,35 s) y existe para que una cifra disparatada no convierta la reposición en un bucle por frame.

### Presentación

| Valor | Por defecto | Qué controla |
| --- | --- | --- |
| `SkyBlend` | 0,55 | Cuánto se mezcla el color del evento con la iluminación authored. A 1 el mundo se pinta de un color plano y se pierde la dirección de arte |
| `LightingTweenSeconds` | 1,2 | Duración de la transición de color |
| `EndedNoticeSeconds` | 4 | Cuánto se ve `EVENT ENDED` |
| `RainbowCycleSeconds` | 6 | Vuelta completa al círculo cromático en los eventos `Rainbow` |

### Antes de dar por bueno un cambio

- Un evento nuevo con un `Kind` que no existe **no falla**: devuelve el neutro y no hace nada. Comprobar que el `Kind` está escrito exactamente como en la tabla.
- Subir un multiplicador de `Stickiness` afecta también a las Rest Zones, porque comparten fórmula. Es lo buscado, pero conviene mirar el efecto sobre el jugador AFK antes de subirlo mucho.
- Los eventos de `Wins` se multiplican con el gamepass x2 y con el boost temporal x2: quien tenga los tres cobra x8.
