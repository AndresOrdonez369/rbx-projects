# Residuo, Máquina Aspiradora y Pestaña Cosmética

# Residuo, Máquina Aspiradora y Pestaña Cosmética — especificación de diseño

**Documento hermano:** `claude/blobs-elementos-y-recompensa-2026-09-18.md` — cómo se producen los blobs que la máquina entrega y cómo se integran. Corrige §4.5 de este documento.

---

## 0. El cambio en una página

### Hoy

```
  objeto  ──►  ¿tengo Stickiness ≥ N?  ──► sí ──► lo recojo ──► +Stickiness
                        │                                          │
                        └── no ──► está apagado y no puedo tocarlo  └──► abre blockers
```

El número sobre el objeto es **un requisito**, pero el jugador lo lee como **una recompensa**. Esa es la confusión que se está viendo. Y los objetos, una vez pegados, no hacen absolutamente nada: son decorado permanente.

### El modo nuevo

```
  objeto  ──►  lo recojo SIEMPRE  ──►  +Stickiness (fórmula de siempre, invisible en el objeto)
                                  └──►  +RESIDUO   (el número que SÍ está escrito encima)
                                              │
                                              ▼
                                   ┌─────────────────────┐
                                   │  MÁQUINA ASPIRADORA │  1 por mundo, en el lobby
                                   │  RESIDUO  412 / 600 │
                                   └──────────┬──────────┘
                                              │ pisas · cobra · aspira tu bola
                                              ▼
                                      BLUR + PREMIO COSMÉTICO
                                              │
                                              ▼
                          PESTAÑA `BLOBS` DEL INVENTARIO
                          (equipar · revisar · nada más)
```

### Las tres cosas que esto arregla, y son las tres que pediste

| Problema | Cómo lo arregla |
| --- | --- |
| **El número miente.** El jugador cree que el `25` es lo que va a ganar | Ahora **es** lo que va a ganar. El número deja de ser una puerta y pasa a ser un premio |
| **Los assets no hacen nada.** Juego de recolección sin destino | La bola pegada es literalmente la cartera, y la máquina es su sumidero |
| **Cero incertidumbre en la sesión** | Un resultado que no sabías **cada dos minutos**, en el sitio por donde el jugador ya pasa |

### Lo que NO cambia, y conviene tenerlo escrito

- La fórmula de Stickiness: `WrapBaseGain × (RebirthMultiplier + TrailAddition) × AuraMultiplier × WorldStickinessMultiplier`. **Ni un número.**
- Los blockers, el Rebirth, los niveles, los perks, los wraps, las Rest Zones, los pedestales de Win.
- La tienda de trails y auras por Wins (§4.5 explica por qué es intocable).

---

## 1. Las tres piezas y su responsabilidad única

La regla que ordena todo el documento — la misma de `rework-aspiradoras-w1` §4.3: **cada pieza hace exactamente una cosa, para no tener que balancear dos objetos a la vez.**

| Pieza | Hace exactamente una cosa | Dónde vive el balance |
| --- | --- | --- |
| **Objeto recogible** | Produce Residuo al recogerse | `ResidueValue` del prop |
| **Máquina aspiradora** | Convierte Residuo en un cosmético que no tenías | `Price` + `PoolId` del pad |
| **Pestaña de blobs** | **Equipar** un aspecto y **revisar** cuáles tienes. Nada más: aquí no se compra ni se gasta | nada — es presentación pura |

Nada más produce Residuo. Nada más lo consume. **Una moneda, una fuente, un sumidero** — y esa austeridad es lo que la mantiene legible para un niño de nueve años en un teléfono.

---

## 2. Objetos agarrables — qué cambia

### 2.1 Se retira el requisito, y se retira con un booleano

```
GameConfig.Collection.RequireStickinessForPickup = false   -- flag maestro de rollback
```

**No se borra el código de validación.** `PickupService` sigue comprobando sesión, distancia contra la posición del servidor, personaje vivo y rate limit por token bucket — todo eso es seguridad y se queda. Lo único que se salta es la comparación contra `RequiredStickiness`.

La razón de hacerlo con un flag y no borrando: **el rollback de este proyecto tiene que ser un booleano.** Es la misma regla que el `VacuumZones.Enabled` del rework y la que hizo reversibles `Wins.AwardOnRunCompletion` y `Finish.TeleportOnCompletion`.

⚠️ `RequiredStickiness`** sigue existiendo en los blockers y ahí sí gatea.** Son dos consumidores distintos (`PickupService` y `BlockerService`) del mismo nombre de atributo. Tocar uno no puede tocar el otro.

### 2.2 El número de la etiqueta pasa a ser el Residuo

La plantilla `ReplicatedStorage/Assets/Collectibles/_RequirementBillboard` **se reutiliza entera**. Cambia el número que pinta y el color, nada más:

|  | Hoy | Nuevo |
| --- | --- | --- |
| Qué dice | `25` (Stickiness requerida) | `3` (Residuo que da) |
| Icono | ninguno | **obligatorio** — el número nunca va desnudo (§2.5) |
| Color | rojo / verde por elegibilidad | color de bracket de tamaño (§3.2) |
| Tamaño | en **Scale** (studs) | igual — no tocar |
| `AlwaysOnTop` | `false` | igual — no tocar |

⚠️ **Las dos trampas de **`BillboardGui`** de este proyecto siguen vigentes** y el letrero de la máquina (§4.1) también pasa por ellas:

1. `TextBounds = 0,0`**.** El texto se mide una sola vez; si Roblox lo dispone antes de que el billboard tenga tamaño en pantalla, pinta el fondo sin los dígitos y **no vuelve a medir**. `ObjectLabelController.healLabel` ya cura esto por tick; todo letrero nuevo tiene que pasar por ese mismo camino.
2. `TextScaled`** y **`TextWrapped`** van juntos.** Apagar el segundo apaga el primero en silencio y el texto cae al `TextSize` de la plantilla (8 px aquí, o sea ilegible).

### 2.3 ⚠️ Lo que se pierde: el gradiente de elegibilidad

`ObjectLabelController` atenúa el color propio del prop (`IneligibleTintFactor`) y lo hace semitransparente cuando no puedes cogerlo. Con el requisito retirado **todos los objetos quedan a color pleno siempre**, y con ello desaparece la lectura *«esta sala todavía me queda grande»*.

Eso no es solo estética: era **la progresión visible dentro de una sala**. Los cuatro umbrales de `CollectibleRequirements` (0 %, 25 %, 50 %, 75 % del tramo) repartían los objetos en cuatro tandas que se iban encendiendo conforme subías.

**La sustitución es directa y reutiliza la misma máquina:** esos cuatro umbrales pasan de ser **cuatro puertas** a ser **cuatro valores de Residuo**. `ItemPlanner` ya reparte los objetos entre los cuatro por resto mayor; no hay que tocar una línea del reparto. Lo que cambia es qué significa el tramo:

```
antes:  tramo 0   → RequiredStickiness 0     (lo puedo coger ya)
        tramo 3   → RequiredStickiness 25    (apagado hasta que suba)

ahora:  tramo 0   → ResidueValue 1           (cógelo, da poco)
        tramo 3   → ResidueValue 5           (cógelo, da más — y se ve más grande)
```

**El gradiente sigue estando; ahora es aspiracional en vez de prohibitivo.** El jugador ve el `5` al fondo de la sala y va a por él porque quiere, no porque el juego se lo permita.

`ObjectLabelController` conserva el Highlight único de «este es el que vas a agarrar» y la regla de no usar `Highlight` para estado por objeto (tope de 31 por cliente, sin API para subirlo).

### 2.4 ⚠️ Riesgo #1: World 1 se acorta, y hay que medir cuánto

Hoy, al entrar a una sala, **solo el 25 % de los objetos son elegibles**. El jugador coge esos 8 de 32, sube, se encienden los siguientes. Ese escalonado le obliga a dar vueltas y a esperar reposiciones.

Con el requisito retirado, **los 32 están disponibles desde el primer segundo**. El jugador barre la sala en línea recta. Menos vueltas, menos espera, **misma Stickiness necesaria en menos tiempo**.

- La Stickiness total para abrir un blocker **no cambia** (los objetos dan lo mismo que antes).
- Lo que cambia es el **tiempo** de conseguirla.
- Estimación previa a medición: **−10 % a −25 % por sala** `[PLACEHOLDER]`.

Eso importa porque el presupuesto de contenido está calibrado: World 1 en **\~35,7 min** y el juego entero en **16,5 h** tras los tres aceleradores del 16-sep (que ya recortaron un 22 %). Un −20 % más deja World 1 en \~29 min.

**Cómo medirlo, y es barato:** una corrida cronometrada de las 10 salas con el flag en `true` y otra con el flag en `false`, en el mismo place y con el mismo wrap. Es literalmente encender y apagar un booleano entre las dos.

**Los diales para compensar, por orden de preferencia:**

1. `TotalObjects`** por sala** — menos objetos a la vez, el jugador espera reposición. Es el dial más directo y no toca ninguna fórmula.
2. `Collection.RespawnSeconds` — reposición más lenta.
3. **La escalera de blockers** — último recurso. Un mes de balance vive ahí y moverla arrastra a los tres mundos.

⚠️ **No compensar subiendo **`MinSeparationStuds`**.** `ItemPlacementService` avisa solo cuando el área no da los slots pedidos (`produced N slots but the room asks for M objects`), y ese aviso —no la intuición— es el criterio. Con props grandes las salas ya bajaron de 32 a 20 y a 10 objetos.

### 2.5 ⚠️ Riesgo #2: los jugadores actuales van a leer el número como Stickiness

Esto es el problema del cambio **al revés**. Quien ya juega tiene aprendido que el número sobre el objeto es un requisito; quien entra nuevo no tiene nada aprendido. Y el número nuevo es **más pequeño** que el viejo (un `3` donde antes ponía `25`), así que un veterano puede leerlo como *«me han nerfeado los objetos»*.

Tres mitigaciones, todas baratas:

1. **El número nunca va solo.** Siempre `♻ 3`, con el icono de Residuo, y **el mismo icono** que lleva el contador del HUD y el letrero de la máquina. Un icono compartido es lo que hace que el jugador conecte las tres cosas sin leer una palabra.
2. **Color distinto al de la Stickiness.** La Stickiness se lee hoy con el color del wrap equipado (`Feedback.TintPopupWithWrapColor`). El Residuo tiene que tener **un color propio y fijo**, igual en los tres mundos, o el jugador no distinguirá los dos números.
3. **El popup de recogida enseña los dos.** `+8` en color de wrap y `♻ +3` debajo, en color de Residuo. Es la única forma de enseñar, sin texto, que son dos cosas distintas que pasan a la vez. Y ya hay canal: `PickupFeedback` y el `StickyGain` que suena encima de `Pickup`.

⚠️ **Y una comprobación que bloquea el arranque de la fase 1:** con `AlwaysOnTop = false` y 32 tarjetas por sala, el proyecto ya midió el peor caso (cámara a ras de suelo) en **3 parejas solapadas**. Añadir un icono al lado del número **ensancha la tarjeta**. Hay que volver a medir ese peor caso antes de dar por bueno el diseño de la etiqueta.

---

## 3. RESIDUO — especificación de moneda

### 3.1 Ficha

```
## Moneda: Residuo (♻)

**Propósito**: darle un destino a los objetos pegados y crear la única decisión aleatoria
             de la sesión. Es la moneda de COLECCIÓN, no de poder.
**Tipo**: blanda, ganada, no comerciable, no vendible por Robux en v1
**Fuentes**: recogida física de un objeto, y NADA MÁS (§3.4)
**Sumideros**: la máquina aspiradora del mundo, y NADA MÁS
**Ratio grifo/desagüe objetivo**: ~1,0 en régimen (el jugador tira en cuanto puede)
**Tope**: sin tope duro en v1; umbral de alarma definido en §3.5
**Conversión**: ninguna. No se convierte a Wins, ni a Stickiness, ni al revés
**Superficie de exploit**: pickups falsos (ya cubierto por `PickupService`), granja AFK
                        por Rest Zones (§3.4 — **bloqueante**), reroll del sorteo en cliente
                        (§6.3), doble cobro por doble `Touched` (§6.4)
```

**Por qué una moneda nueva y no reutilizar las Wins.** Porque el competidor ya demostró el argumento: *«una partida que ignora el rodar se atasca en la tienda de huevos; una que ignora recoger cash se atasca en la tienda de gear»*. Dos monedas que cierran puertas distintas obligan a correr los dos bucles y crean una decisión de guardar-o-gastar. Aquí es más limpio todavía: **las Wins compran poder (wraps) y el Residuo compra identidad (cosméticos).** Nunca compiten, nunca se canibalizan, y cada una tiene su propio ritmo.

---

### 3.2 ⭐ Duda 1 — ¿El Residuo debería tener fórmula de recolección como la Stickiness?

> **No. Y si la tuviera, el cambio fallaría en su propio objetivo.**

#### El argumento que cierra la discusión

La razón por la que estás haciendo esto es que **el número sobre el objeto confunde**. Si el Residuo usa la fórmula de Stickiness, ese número pasa a ser:

```
Residuo = WrapBaseGain × (RebirthMultiplier + TrailAddition) × AuraMultiplier × WorldMultiplier
```

o sea, **exactamente la misma magnitud que la Stickiness que el jugador creía estar leyendo.** Un jugador con Galaxy Glue vería `+900` sobre una taza, que es indistinguible de la Stickiness que le va a dar. **La confusión no se arregla: se duplica.**

El número de Residuo tiene que ser visiblemente **otra clase de número**. Pequeño, entero, entre 1 y 10. Es lo único que garantiza que nadie lo confunda con lo otro.

#### Y los tres argumentos de economía, que apuntan al mismo sitio

**a) Una moneda de colección con catálogo fijo no puede escalar con la curva de poder.** Si el ingreso crece ×4.000 con la escalera de wraps de World 1 (BaseGain `1 → 4.000`) y ×50 con los Rebirths, solo hay dos finales posibles:

- **El precio de la máquina escala igual** → nada cambia nunca. Es una cinta de correr, y una cinta de correr sin decisión es peor que no tener moneda.
- **El precio se queda fijo** → a las dos horas el jugador vacía el pool entero en una tirada y la máquina se muere para siempre.

**b) Este proyecto ya ha cometido tres veces el error de las unidades absolutas**: los charms a 4.000 Wins, los días 1–2 del daily, y los Playtime Rewards (`+225` contra un glue de `+2.055.000.000`). La regla que salió de ahí está escrita: **denominar en objetos equivalentes, nunca en valor absoluto.** El Residuo es el caso literal de esa regla — *es* el objeto.

**c) La única unidad estable de este juego es el objeto por segundo, y está acotada por la física.** Un jugador recoge **1,43–1,64 obj/s** medidos, y eso no cambia con el wrap, ni con los Rebirths, ni con el mundo: lo acota la velocidad de movimiento, el radio de recogida y la densidad de la sala. Por eso es la **única** magnitud del juego en la que se puede denominar un precio y que ese precio siga significando lo mismo dentro de seis meses.

#### Entonces, ¿de dónde sale el valor de un objeto?

> **Del objeto. Del tamaño que tiene y que el jugador ya está viendo.**

Y esto tiene un premio: **usa el campo que lleva reservado y vacío desde agosto.**

```
GameConfig.CollectibleTypes = {
    { Id = "ToyBlock", DisplayName = "Toy Block", Template = "ToyBlock",
      GainMultiplier = 1,   -- reservado desde agosto, nunca conectado
      ResidueValue  = 3 },  -- ← NUEVO. Esto sí se conecta
    ...
}
```

`RoomSettingsReader` **ya lee **`GainMultiplier`** y ya lo mete en cada objeto colocado**; simplemente nadie lo consume después. El camino de datos está construido entero. `ResidueValue` viaja por ese mismo carril.

**La escala, por bracket de tamaño authored:**

| Bracket | Tamaño del prop | `ResidueValue` | Ejemplos |
| --- | --- | --- | --- |
| **XS** | \< 2 studs | **1** | bellota, moneda, taza |
| **S** | 2–4 | **2** | manzana, plato, calcetín |
| **M** | 4–8 | **3** | bloque, libro, almohada |
| **L** | 8–16 | **5** | silla, cubo de basura, coche |
| **XL** | \> 16 | **8** | nevera, sofá, árbol |

Cuatro propiedades que salen gratis de hacerlo así:

1. **Es intuitivo a los nueve años.** Cosa grande, más residuo. No hay nada que explicar.
2. **El número nunca pasa de 8.** Legible en un teléfono, a cualquier distancia, en la tarjeta que ya existe y con el tamaño que ya tiene.
3. **La progresión por profundidad sale sola, del arte.** Las salas tardías de World 1 V2 ya usan props grandes: bajaron de 32 objetos a 20 y a 10 con separaciones de 9,5–16 studs **porque los props son más grandes**. Sin escribir ninguna tabla de zona, la sala 10 paga más que la 1.
4. **El pool de cada sala pasa a ser una palanca de balance que ya existe.** `RoomSettings/ObjectPool` admite un atributo `Weight` por entrada. Subir el peso de la nevera en la sala 8 sube el residuo de esa sala. Sin tocar código, sin tocar `GameConfig`.

⚠️ `ResidueValue`** es authored en el prop, y el prop manda.** Misma disciplina que `AttachmentProxies/<Prop>/AttachmentScale`: el valor vive en el prefab, no en una tabla paralela. Un prop sin `ResidueValue` declarado cae a **1** con un `warn` explícito, nunca en silencio.

#### El modelo de ingreso resultante

```
Ingreso = objetos/s × ResidueValue medio
        = 1,5 obj/s × ~3
        = 4,5 ♻/s  ≈  270 ♻/min
```

Con la media subiendo de \~2,5 en las salas 1–4 a \~5 en las salas 8–10, el rango real es **\~225 a \~450 ♻/min**. Un factor 2 a lo largo de todo un mundo — suficiente para que se note, demasiado poco para inflar nada. `[PLACEHOLDER hasta la corrida cronometrada de la fase 1]`

---

### 3.3 ⭐ Duda 2 — ¿Debería afectarle el multiplicador del mundo?

> **No el de Stickiness. Nunca ese. Y si quieres uno, que sea suyo y diminuto.**

#### Por qué no `Worlds[].StickinessMultiplier`

Ese multiplicador existe y está vivo (`GameConfig.Worlds[].StickinessMultiplier`, valores verificados hoy `1 / 1 / 1,8`; el diseño original era `1 / 2 / 4,5`). Se aplica en `ProgressionService`, en dos sitios: el atributo replicado y la ganancia real.

Y aquí está la razón de fondo para no colgarse de él:

> `StickinessMultiplier`** es el dial de DURACIÓN de este proyecto, y se re-afina cada pocas semanas.**

No es una suposición. `lava-20h` lo documenta como *«la palanca de duración correcta»*, y sus valores vivos hoy (`1 / 1 / 1,8`) ya no son los de diseño (`1 / 2 / 4,5`) precisamente porque se movieron para cuadrar la duración. **Cada vez que alguien ajuste cuánto dura el juego, movería el ritmo del gacha sin saberlo** — y este proyecto ha hecho cinco pasadas de duración entre el 4 y el 10 de septiembre. Un ajuste de contenido cambiaría cuántos cosméticos saca un jugador por hora, en silencio y sin que nadie lo relacione.

Ese acoplamiento es exactamente el mismo error que la divergencia `GameConfig` ↔ Workspace de los blockers de World 1, que lleva meses arrastrándose: **dos cosas que tienen que moverse juntas atadas a un número que se mueve por otra razón.**

#### Y el segundo argumento: se cancela solo

Si el Residuo escala ×1,8 en Lava **y** la máquina de Lava cuesta ×1,8, el jugador saca exactamente las mismas tiradas por hora. El multiplicador no ha hecho nada salvo hacer los números más grandes. Eso no es progresión: es inflación con pasos extra.

#### La recomendación

```
GameConfig.Residue = {
    WorldMultipliers = {                 -- dial PROPIO, separado de la Stickiness
        World1 = 1,
        World2 = 1,                      -- v1: apagado a propósito
        World3 = 1,
    },

    DuplicateRefund = 0.40,              -- §4.4 · dial de DURACIÓN.  ⚠️ estrictamente < 1
    PityStreak      = 5,                 -- §4.4 · dial de JUSTICIA.  duplicados seguidos
                                         --        antes de garantizar uno nuevo
    FirstPullPrice  = 250,               -- §4.6 · una vez por cuenta, es onboarding
}
```

**En v1 se queda en **`1 / 1 / 1`** y el dial existe apagado.** Tres razones:

1. **La progresión por mundo ya la da el arte.** Los props de Desierto y Lava son más grandes, así que su `ResidueValue` medio sube solo, sin tabla.
2. **Deja el precio de cada máquina expresable en minutos y que siga siendo verdad.** «600 ♻ ≈ 2 minutos de recoger» vale igual en Bosque que en Lava, hoy y dentro de un año. Eso es lo que hace la economía auditable.
3. **Si más adelante quieres que un mundo profundo pague más, mueves ese número y nada más.** Un dial, un consumidor, cero efectos colaterales.

#### La regla que hay que respetar si algún día lo enciendes

> **El precio de la máquina de un mundo tiene que subir MÁS que su multiplicador de Residuo.**

Es la misma forma que el balance de mundos que ya funciona (*«requisitos ×10, Wins ×15, deja el mundo 2 un 50 % más rentable»*). Si el multiplicador sube ×2 y el precio ×2,5, el mundo profundo se siente **más caro por tirada pero con mejores premios**, que es la sensación correcta. Si suben igual, no pasa nada. Si el precio sube menos, el mundo profundo regala el pool y el gacha se muere ahí.

---

### 3.4 ⚠️ Las puertas que NO deben pagar Residuo — **bloqueante**

Este es el punto que puede romper el sistema entero antes de que nadie lo note, y viene de cómo está construido el proyecto hoy.

> `PassiveStickinessService`** concede su goteo por la misma puerta que un pickup.**

Está documentado en `rework-aspiradoras-w1` §6.7. Si `ResidueService` se engancha a esa puerta, pasa esto:

| Fuente | Qué concedería | Por qué es inaceptable |
| --- | --- | --- |
| **Rest Zones** | Residuo en AFK, ×1 a **×20** según tier | Un jugador quieto en `RestZone7` fabrica cosméticos mientras duerme |
| **Offline Gains** | Residuo sin estar conectado | Lo mismo, sin siquiera abrir el juego |
| **Gamepass **`x3 Offline Gains` (R$249, id `1981166758`) | **triplica** ese Residuo | ⚠️ **Convierte un pase de Robux en un acelerador de recompensas aleatorias.** Eso es territorio de divulgación de probabilidades y de revisión de monetización de Roblox, y lo sería por accidente |
| **Eventos de mundo **`Kind = "Stickiness"` | ×2 Residuo | Multiplican dentro de `AddStickinessFromCurrentWrap`, que es la misma función |
| **Packs de boost** | Residuo | Misma fórmula |

> Regla dura, y es la única línea del documento que no admite excepción:
> 
> **El Residuo se concede única y exclusivamente cuando un jugador recoge físicamente un objeto del suelo, validado por **`PickupService`** contra la posición del servidor.**

Implementación: `ResidueService` **no** se engancha a la concesión de Stickiness. Se engancha a `PickupService.ConnectCollected`, que es el evento que solo dispara una recogida real y que ya lleva el `TemplateName` del prop — o sea, ya lleva todo lo que hace falta para resolver el `ResidueValue`.

**Una recogida real es la única cosa de este juego que cuesta tiempo de verdad y que no se puede acelerar con Robux.** Eso es exactamente lo que se quiere debajo de un gacha.

Si más adelante se quiere un acelerador de Residuo, la forma correcta es un **evento de mundo con **`Kind = "Residue"`** propio** (una fila más en `GameConfig.WorldEvents.Catalog`, sin tocar código) o un `DoubleResiduePad` hermano del `DoubleWinPad`. Deliberado, acotado y visible — no heredado por accidente de una fórmula compartida.

### 3.5 Inflación: el umbral y el gatillo, definidos antes de lanzar

Sin tope duro en v1 — cortar el ingreso activo de un jugador que está jugando se siente a castigo. Pero el umbral de alarma se define ahora, no cuando el problema ya esté:

| Métrica | Umbral | Qué significa | Qué se hace |
| --- | --- | --- | --- |
| **Saldo P90 de Residuo** | \> **3 × precio** de la máquina de su mundo, 7 días seguidos | El jugador gana más rápido de lo que tira: o el pool se le acabó, o el precio es bajo | Subir precio o ampliar pool |
| **Tiradas por sesión** | **\< 1** en mediana | El precio es demasiado alto o la máquina no se ve | Bajar precio antes de tocar nada más |
| **Participación en el sumidero** | **\< 20 %** de jugadores activos tiran alguna vez | El sumidero no existe para el jugador. Es un problema de legibilidad, no de números | §4.2 — el letrero y la ruta |
| **Saldo mediano tras completar pool** | creciendo sin techo | El Residuo se volvió inútil para ese jugador | Es el disparador para abrir el pool del mundo siguiente |
| **Tasa de duplicados** | \> **70 %** de las tiradas | El sumidero efectivo se desplomó: con reembolso del 40 %, siete de cada diez tiradas devuelven parte (§4.4) | Es normal cerca del `COMPLETA`. Si pasa lejos del final, ampliar el pool |

**Preferencia de corrección, y es la regla del oficio:** añadir sumideros antes que recortar fuentes. Los jugadores castigan un nerf mucho más de lo que agradecen un regalo.

---

## 4. La máquina aspiradora

### 4.1 Contrato

|  |  |
| --- | --- |
| **Tag** | `VacuumMachine` |
| **Cantidad** | **1 por mundo**, en el lobby |
| **Atributos** | `WorldId`, `PoolId`, `Price` |
| **Piezas authored** | `Pad` (la placa que se pisa) · `Machine` (el modelo) · `PriceSign` (`BillboardGui`) · `RevealAnchor` (dónde nace el premio) |
| **Colisión con el jugador** | ninguna sobre la máquina; el `Pad` sí es pisable |

**Todo el balance de una máquina vive en esos tres atributos y en ninguna otra parte.** El modelo, los VFX y la animación no llevan ni un dato de balance. Es la misma decisión que dejó a los 20 `VacuumProp` del rework sin ningún número: no querer afinar dos objetos para ajustar uno.

#### ⚠️ Las tres referencias que no se actualizan solas al duplicar

Va a haber **tres máquinas** y la segunda y la tercera van a salir de duplicar la primera. Este proyecto ya se ha mordido **dos veces** con exactamente esto (2026-09-08 y 2026-09-09, duplicando Rest Zones). Al duplicar hay que repuntar a mano:

1. `WorldId`** y **`PoolId` — en el `Pad` **y** en la máquina. Si no, la copia sortea del pool del original.
2. `Pad.PadReference` (`ObjectValue`) → su propia máquina. Si no, la presentación 3D sale sobre la máquina equivocada.
3. `PriceSign.Adornee` (`BillboardGui`) → la pieza de **su** máquina. Un `BillboardGui` se dibuja donde está su `Adornee`, **no** donde está su padre. Con `MaxDistance` corto y el `Adornee` en otro lobby, el cartel **simplemente no se ve en ninguna parte**.

#### El letrero

```
        ┌──────────────────────────┐
        │      ♻  412 / 600        │
        │  ████████████░░░░░░░░    │
        │      PÍSALO PARA TIRAR   │   ← solo cuando ya llegas
        └──────────────────────────┘
```

- La cifra y la barra se pintan **en el cliente**, porque el saldo es estado por jugador. Un cartel escrito desde el servidor mostraría el saldo de otro. Es exactamente la lección de los `WrapSign`.
- El cartel es **authored, uno por máquina** (regla 12 y la corrección del 2026-08-06: que el contenido sea por jugador **no** justifica crearlo por código, porque las escrituras del cliente sobre el Workspace son locales).
- Pasa por `healLabel` (§2.2).

### 4.2 El ciclo, segundo a segundo

| t | Qué pasa | Autoridad |
| --- | --- | --- |
| — | El jugador cruza el lobby. El cartel dice `♻ 412 / 600` y la barra está a medias | cliente |
| — | Al llegar a 600 el cartel se pone verde y la máquina **arranca en vacío** (ruido + luz) | cliente |
| 0,0 s | Pisa el `Pad` | servidor valida ocupación |
| 0,0 s | **Se cobra el Residuo.** El contador del HUD baja a `0` de golpe | **servidor** |
| 0,0–2,5 s | **La bola se aspira.** Las piezas salen volando hacia la máquina, escalonadas (§4.3) | cliente, guiado por servidor |
| 2,5 s | **Blur.** `BlurEffect` sube a 18 en 0,3 s. El mundo se apaga | cliente |
| 2,5–3,5 s | Ruleta corta: siluetas pasando, el color de rareza subiendo | cliente |
| 3,5 s | **El premio.** Aparece el cosmético, con su nombre y su rareza. ⭐ **Si es un blob, se aplica aquí mismo, en vivo**: la bola acaba de vaciarse, así que es el único momento de la sesión en que el blob se ve entero (`blobs-elementos-y-recompensa` §8) | **servidor decide, cliente pinta** |
| 3,5 s | **Si es duplicado**, revelado corto: `YA LO TIENES` + `♻ +180 DEVUELTO` + el pip de piedad avanzando (§4.4) | ídem |
| 3,5 s | Botón `EQUIPAR` / `SEGUIR`. El blur baja al pulsar cualquiera | cliente |

**Tres reglas de presentación que no son opcionales:**

1. **El cobro va ANTES de la animación, no después.** Si la animación se cobra al final y el jugador se desconecta a mitad, o tiras gratis o cobras sin premio. Cobrar primero y tener un `pending` persistido (§6.5) es la única forma de que un corte no robe ni regale.
2. **El blur se apaga pase lo que pase.** Muerte, desconexión, viaje de mundo, reset de personaje, evento de mundo que tuitea la iluminación: el controlador tiene que limpiar su `BlurEffect` en `CharacterRemoving`, `PlayerRemoving` y `Destroy()`. Un blur pegado es un jugador que no puede jugar y que solo se arregla reiniciando. **Es el bug más caro de esta feature y es de una línea.**
3. **El premio se lee sin texto.** La audiencia son menores de 13 en un teléfono: el color de rareza, el tamaño del estallido y el sonido tienen que decir «esto es bueno» antes de que nadie lea el nombre. Ya hay canales dedicados: `FeedbackController` escucha `CosmeticFeedback`, y `Purchase` y `Equip` son canales propios desde agosto precisamente porque comprar sonaba como absorber.

### 4.3 ⭐ La bola es el sumidero, y literalmente

Confirmaste el modelo: **la bola se reduce en proporción al Residuo gastado.** Eso hace que el sumidero sea visible, que es justo lo que le falta a un sink de moneda normal.

```
fracciónGastada = precio / residuoAntes        -- 1,0 si tiras con lo justo
piezasAAspirar  = floor(recordsActuales × fracciónGastada)
```

Si tiras con lo justo, **la bola desaparece entera**. Si tiras con el triple ahorrado, se lleva un tercio. El jugador aprende la relación en dos tiradas y sin una palabra: *«cuanto más ahorro, menos me quita»*. Es una decisión de guardar-o-gastar que no hubo que diseñar — sale de la fórmula.

#### ⚠️ Cómo se implementa, porque aquí hay un hitch medido esperando

`AttachmentService` mantiene **300 records lógicos** y el cliente renderiza 110 propios. Y este proyecto ya midió lo que cuesta vaciar la pila de golpe:

> **600 piezas = 10,6 ms de Lua + el frame siguiente de 19 ms en escritorio, del orden de 50–100 ms en móvil.** Y lo sufre **todo el que tenga esa pila cargada**, no solo su dueño.

Así que:

| ❌ No | ✅ Sí |
| --- | --- |
| Un `ClearPlayerVisuals` de golpe al pisar el pad | `AttachmentService.ReleaseOldest(n, ratePerFrame)`, escalonado |
| Destruir los records | Devolverlos al pool (`PoolCapacity = 400` ya existe para esto) |
| Aspirar en 1 frame | Repartir sobre los **2,5 s** de la animación, con techo de piezas por frame |

**Y aquí el rendimiento y el diseño piden lo mismo, que es cuando sabes que la solución es la correcta:** la animación quiere que las piezas salgan volando **una a una** hacia la máquina, no que desaparezcan de golpe. Escalonar es a la vez lo bonito y lo barato.

**La máquina de animar ya está construida.** `AttachmentRenderer` tiene la animación de descarte —la pieza expulsada se encoge y se desvanece en `Workspace.StickyDiscards`, movida por un `Heartbeat` compartido y desacoplada de la vida del personaje. **Solo cambia el destino**: en vez de encogerse donde está, viaja hacia la máquina. Cero instancias nuevas, cero física.

⚠️ **Los blockers pegados están protegidos del reciclaje FIFO (**`ProtectBlockerAttachments`**).** La aspiración tiene que respetar esa protección o el jugador pierde *«la puerta que rompí»*, que es una lectura de progreso, no decorado. Se aspiran primero los no protegidos; los de blocker, solo si no queda otra y solo al 100 %.

### 4.4 ⭐ El sorteo: **con duplicados, con reembolso y con piedad**

> **Decisión de Camilo (18-sep):** el sorteo **tiene que poder soltar duplicados**. Sin ellos el sumidero es demasiado corto y la apuesta desaparece: la máquina se convierte en una tienda más, con animación. **El duplicado devuelve un % del Residuo que costó la tirada.**

Es la decisión correcta, y la razón es que el duplicado es lo que le da a la tirada **dos resultados posibles**. Sin él no hay apuesta: hay una cola. Lo que sí hace falta es **acotar la mala suerte**, y eso es lo que ocupa el resto de la sección.

#### Las tres piezas, y ninguna funciona sin las otras dos

| Pieza | Qué hace | Valor `[PH]` |
| --- | --- | --- |
| **Duplicados permitidos** | Crean la apuesta y estiran el sumidero **×2,3** (16 tiradas para 7 items) | — |
| **Reembolso al duplicar** | Convierte «no me tocó nada» en «me tocó menos» | **40 %** del precio |
| **Piedad por racha** | Acota la cola. **Es lo que hace el sistema publicable** | **5** duplicados seguidos → la siguiente es nueva |

#### La simulación, recalculada para un pool de 7

> **Decisión de Camilo (18-sep, 2):** **7 recompensas por mundo, 21 en total** (antes 15 / 20 / 25).

Reparto propuesto y **pesos por item, no por tier** — con siete casillas, declarar «Común 60 %» y repartirlo entre cuatro items dejaría cada común al 15 % y cada raro al 15 % también, o sea la misma probabilidad con distinto nombre. Con pools pequeños **el peso se declara item a item**:

| Rareza | Items | Peso por item | Total |
| --- | --- | --- | --- |
| **Común** | 4 | **18 %** | 72 % |
| **Raro** | 2 | **11 %** | 22 % |
| **Épico** | 1 | **6 %** | 6 % |

Cada común es exactamente **3× más probable que el épico**. Es una pirámide que se lee de un vistazo en una lista de siete filas.

**12.000 corridas por fila. Pool de 7, precio 850, reembolso 40 %, ritmo 270 ♻/min:**

| Piedad | Tiradas med | Tiradas P90 | Completar med | Completar P90 | **P90 / mediana** | % duplicados |
| --- | --- | --- | --- | --- | --- | --- |
| **Ninguna** | 20 | 41 | 35 min | **56 min** | **×1,60** 🔴 | 71 % |
| 4 | 15 | 19 | 24 min | 29 min | ×1,20 | 53 % |
| **5** ⭐ | **16** | **21** | **39 min** | **48 min** | **×1,24** ✅ | 56 % |
| 8 | 18 | 25 | 28 min | 36 min | ×1,31 | 61 % |
| 10 | 19 | 27 | 29 min | 39 min | ×1,34 | 63 % |

> ⚠️ **Con 7 items la piedad importa MÁS que con 15, no menos.** Sin ella el decil con mala suerte tarda un **60 %** más que la mediana (era un 46 % con 15). La razón es aritmética: con un pool pequeño, la probabilidad de sacar el item que te falta cae a **6 %** en cuanto tienes seis de siete, y a partir de ahí el jugador está tirando contra una moneda de 16 caras. **La piedad de 5 es lo que convierte ese muro en «seis tiradas como mucho».**

**Piedad se queda en 5.** Bajarla a 4 acorta el pool un 40 % sin ganar nada en justicia (×1,20 contra ×1,24, dentro del ruido). Subirla a 8 o 10 empeora las dos cosas a la vez.

#### Los pesos de rareza son un dial narrativo, no de duración

Con la piedad puesta, mover los pesos **casi no cambia cuánto dura el pool** — lo que cambia es **cuándo llega el épico**, que es otra cosa. Precio 850, piedad 5:

| Reparto | Completar (med) | **El épico llega en la tirada…** (med / P90) |
| --- | --- | --- |
| Plano, 7 × 14,3 % | 37 min | **5** / 14 — *llega pronto y no es un clímax* |
| **4C 18 · 2R 11 · 1E 6** ⭐ | 39 min | **11** / 19 — *casi siempre en la segunda mitad, pero puede sorprender* |
| 4C 19 · 2R 10 · 1E 4 | 41 min | 14 / 21 — *casi siempre el último* |
| 4C 20 · 2R 9 · 1E 2 | 43 min | 17 / 22 — *siempre el último, y lo entrega la piedad* |

**Recomendación: 18 / 11 / 6.** Con un épico al 6 % la mediana lo pone en la tirada 11 de 16 — normalmente hacia el final, pero con cola suficiente para que a veces salga pronto. **Un premio que *****siempre***** es el último deja de ser aleatorio: es un cronómetro**, y encima lo acaba entregando la piedad, que es la peor forma de recibir el mejor item del mundo.

El 2 % es la opción si quieres que el épico sea el clímax garantizado del mundo. El plano no, nunca: regala el épico en la quinta tirada y deja las diez siguientes sin nada que esperar.

#### El reembolso

```
local refund = math.floor(machine.Price * GameConfig.Residue.DuplicateRefund)   -- 0.40
```

Con 7 items el reembolso **sí mueve la duración de forma apreciable** (más que con 15, porque hay más duplicados por tirada). Precio 850, piedad 5:

| Reembolso | Completar (med) | Completar (P90) |
| --- | --- | --- |
| 25 % | 43 min | 55 min |
| **40 %** ⭐ | **39 min** | **48 min** |
| 50 % | 36 min | 44 min |
| 60 % | 33 min | 40 min |

**40 % se queda.** Es el punto donde un duplicado devuelve lo bastante para que la siguiente tirada se sienta cerca (340 ♻ de 850, o sea el 40 % del camino andado) sin que el sumidero se desfonde.

⚠️ **Tiene que ser estrictamente menor que 100 %.** Un reembolso del 100 % —o más, si algún día alguien le suma un bono encima— convierte la máquina en un bucle infinito de tiradas gratis. Es obvio escrito aquí y no lo es a las dos de la mañana ajustando un número.

⚠️ **Y el reembolso es un grifo parcial, así que cuenta en los umbrales de §3.5.** El sumidero efectivo por tirada es `precio × (1 − reembolso × tasa_de_duplicado)`, y con 7 items esa tasa llega al **56 %**: más de la mitad de las tiradas devuelven parte. La piedad también acota eso, porque pone techo a la tasa de duplicado.

**Variante para la v2, si la telemetría la pide:** reembolso **escalado por rareza** — `Común 25 % · Raro 50 % · Épico 75 %`. El duplicado que más duele es el épico (acertaste el 6 % y no sirvió de nada), así que es el que merece el aterrizaje más blando. No entra en v1 porque son dos conceptos que explicar en lugar de uno; entra si `CosmeticGranted` muestra que las sesiones se terminan justo después de un épico repetido.

#### La piedad, y hay que enseñarla

Contador de **duplicados consecutivos**, persistido en el perfil. A los 5, la siguiente tirada sortea solo entre lo que no tienes.

**Y el contador se ve en el cartel de la máquina**, no se esconde:

```
        ┌───────────────────────────────┐
        │        ♻  612 / 850           │
        │   ████████████░░░░░░░░        │
        │   SIGUIENTE NUEVO  ● ● ● ○ ○  │
        └───────────────────────────────┘
```

Enseñarlo es honesto y además es lo que convierte una racha mala en tensión en vez de en frustración: el jugador ve que la mala suerte **tiene final** y sigue tirando. Escondido, una racha de cuatro duplicados se lee como que el juego está roto. Y con 7 items **más de la mitad de las tiradas serán duplicadas**, así que esos pips no son un adorno: son la mitad de la interfaz.

#### El sorteo, en servidor

```
-- Servidor. El cliente NUNCA ve el pool, los pesos ni la semilla.
local elegido
if state.DupStreak >= GameConfig.Residue.PityStreak then          -- 5
    elegido = weightedPick(unownedFrom(pool, state), rng)         -- piedad: solo lo que falta
else
    elegido = weightedPick(pool, rng)                             -- normal, duplicados incluidos
end

if state.Owned[elegido.Id] then
    state.DupStreak += 1
    state.Residue  += math.floor(machine.Price * DuplicateRefund) -- reembolso
else
    state.DupStreak = 0
    grantCosmetic(player, elegido)
end
```

#### ⚠️ El revelado de un duplicado se lee distinto, y nunca como un castigo

Es la parte que más fácil sale mal, **y con 7 items pasa a ser el caso mayoritario: el 56 % de las tiradas.** O sea que esta pantalla se ve más veces que la del premio.

| ❌ No | ✅ Sí |
| --- | --- |
| La misma fanfarria que un item nuevo | Un revelado más corto, sin el estallido grande |
| El sonido `Denied` | Un sonido propio, neutro y satisfactorio. **El reembolso es un ingreso, no un rechazo** |
| Solo `YA LO TIENES` | `YA LO TIENES` **y** `♻ +340 DEVUELTO`, con el contador del HUD subiendo a la vista |
| Cerrar y ya | El pip de piedad avanzando, visible, en el mismo frame |

**El jugador tiene que salir de un duplicado con algo en la mano y sabiendo que está más cerca.** Si sale con las manos vacías, deja de tirar — y ahí se pierde la feature entera, no una tirada.

**Tirada dorada** `[PH]`: **3 %** de que la máquina entregue **dos** premios. Varianza al alza pura —cero pérdida— y es el pico que compensa emocionalmente las rachas de duplicados.

### 4.5 ⚠️ El pool es exclusivo, y no es negociable

**Nada de lo que da la máquina puede estar también a la venta por Wins.**

Si los 15 trails y las 15 auras del catálogo entran al pool, pasan dos cosas malas a la vez:

1. **Se mata el único sumidero real de Wins.** Y las Wins ya sobran: el Bosque produce \~3.650 Wins contra una escalera de wraps que cuesta **1.205**, y Lava termina con \~7,6 B de sobrante. Regalar los cosméticos empeora un problema que ya está diagnosticado.
2. **Se devalúa el premio.** «Me salió el trail azul» no vale nada si el de al lado lo compró con Wins hace una hora.

**La composición correcta:**

| Línea | De dónde sale | Coste de arte |
| --- | --- | --- |
| **Paletas de blob** | **solo máquina** | bajo — pero **no es un **`Color3`: el color vive en un atlas de paleta de 512×512. Ver `claude/blobs-elementos-y-recompensa-2026-09-18.md` §3 |
| **Elementos de blob** (superficie + VFX + movimiento) | **solo máquina** | medio — una fila de datos sobre las 8 siluetas rigged que ya existen. **Un elemento se repinta sobre los 8 peldaños de wrap, así que 7 items rinden como 56** |
| **Elemento + piezas** (el épico) | **solo máquina** | alto — MeshParts soldados a los huesos. **No hay mallas de cuerpo nuevas**: las 8 siluetas rigged no se tocan |
| **VFX exclusivos** (auras/trails que no están en la tienda) | **solo máquina** | medio — recolorear y recomponer sobre `_CosmeticRig`, que ya soporta 15 tiers con su LOD |
| Los 15 trails + 15 auras del catálogo | **solo Wins**, como hoy | cero — no se tocan |

⚠️ **Los VFX exclusivos tienen que respetar las dos reglas de composición** de `vfx-auras-trails-2026-09-14`: *un elemento dominante + dos apoyos, nunca más*, y *el aura describe al personaje, la estela describe su movimiento*. Y el presupuesto de relleno (`≤ ~174 studs²` con aura y estela a tope). Una capa nueva que respete los nombres de capa entra sola en el LOD del `CosmeticVfxController`, sin tocar código.

### 4.6 Precios y ritmo — recalculados para 7 items

Modelo: **270 ♻/min** en World 1 (§3.2), reembolso 40 %, piedad 5.

Con un pool de 7, **el precio es el único dial de duración que queda** — el tamaño del pool ya está fijado y los pesos casi no lo mueven (§4.4). Barrido, 8.000 corridas por fila:

| Precio W1 | 1 tirada cada | Completar (med) | Completar (P90) | **Items al acabar World 1** (min 36) |
| --- | --- | --- | --- | --- |
| 450 | 1,7 min | 20,7 min | 25,7 min | **7 / 7** — se acaba a mitad del mundo |
| 550 | 2,0 min | 25,3 min | 31,4 min | 7 / 7 |
| 700 | 2,6 min | 32,2 min | 39,9 min | 6,7 / 7 |
| **850** ⭐ | **3,1 min** | **39,0 min** | **48,5 min** | **6,2 / 7** |
| 1.000 | 3,7 min | 46,0 min | 57,0 min | 5,7 / 7 |

> **Recomendación: 850.** El jugador sale de World 1 con **6 de 7 casillas llenas y un hueco mirándole**, y lo cierra en los primeros minutos del Desierto. Un hueco es una razón para volver mañana; una lista sin huecos, no.

⚠️ **El precio sube de 450 a 850 respecto a la versión de 15 items, y eso tiene un coste real:** la cadencia pasa de una tirada cada 1,7 min a una cada 3,1 min. **Con 7 items no se puede tener a la vez pool largo y tiradas frecuentes** — es una elección, no un ajuste. Si al medir la fase 1 la sesión se siente vacía entre tiradas, la salida es **bajar a 700** y aceptar que el pool se complete un poco antes del final del mundo.

⚠️ **La primera tirada.** Con 850 ♻ y el ritmo de la sala 1 (\~225 ♻/min) son **\~3,8 minutos**. Es tarde: el embudo pierde el **39,6 %** de las vueltas entre `01_RunStarted` y `02_Zone01Cleared`, y a ese jugador la máquina no llega a existirle nunca. **Mitigación obligatoria en v1: la primera tirada de una cuenta cuesta 250 ♻** (≈ 1,1 min), una sola vez, marcada en el perfil. No es un descuento de tienda: es onboarding, y es lo que garantiza que todo el mundo vea la máquina funcionar antes de decidir si el juego le interesa.

#### Los tres mundos

| Mundo | Pool | Precio `[PH]` | Ritmo `[PH]` | 1 tirada cada | Completar (med) | **% del mundo** |
| --- | --- | --- | --- | --- | --- | --- |
| **1 · Bosque** | 7 | **850** | 270 ♻/min | 3,1 min | 39 min (P90 49) | **\~108 %** ✅ |
| **2 · Desierto** | 7 | **1.750** | 360 ♻/min | 4,9 min | 60 min (P90 75) | \~20 % |
| **3 · Lava** | 7 | **3.000** | 430 ♻/min | 7,0 min | 87 min (P90 107) | \~8,5 % |

Coste neto de completar un pool, para dimensionar: **\~10.500 ♻** en el Bosque, **\~21.700 ♻** en el Desierto, **\~37.200 ♻** en Lava (medianas; el P90 es un 24 % más).

#### ⚠️ Lo que 7 items por mundo no puede arreglar, y hay que decirlo

**World 1 encaja perfecto. Worlds 2 y 3 no, y no hay precio que lo arregle.**

El Desierto dura 5,1 h y Lava 17 h. Siete items se completan en 1–1,5 h a una cadencia jugable, o sea que **la máquina se apaga en el primer 20 % del Desierto y en el primer 8 % de Lava**. Subir el precio para estirarlos lleva a una tirada cada 28 minutos en Lava, que ya no es una apuesta: es un trámite con espera.

Tres salidas, por orden de lo que costarían:

|  | Qué | Coste | Qué se gana / se pierde |
| --- | --- | --- | --- |
| **a** | **Aceptarlo.** La máquina es una feature de World 1 y del arranque de cada mundo | cero | Honesto y suficiente para v1. Deja abierto que **el endgame de Desierto y Lava sigue sin sumidero propio**, que es un problema anterior a esta feature (el Bosque produce \~3.650 Wins contra una escalera de wraps de 1.205, y Lava termina con \~7,6 B de sobrante) |
| **b** | Subir precios de W2 y W3 ×2,5 | cero | Cubre \~50 % del Desierto y \~20 % de Lava. **Pero la cadencia se va a 12 y 18 min por tirada** y la tensión se evapora |
| **c** ⭐ | **Variantes.** Al completar los 7, la máquina sigue funcionando y los duplicados **suben de variante** en vez de reembolsar: Normal → Dorado → Arcoíris → Cósmico | bajo — recolor y cambio de material sobre assets que ya existen | **7 items se convierten en 28 casillas por mundo** sin 28 assets nuevos. Y los duplicados dejan de ser duplicados en el endgame, que es exactamente donde más duelen |

**La (c) es la buena, y encima es barata:** una variante es un recolor y un cambio de material sobre un asset que ya existe, así que multiplica la colección por cuatro sin multiplicar el arte por cuatro. Y para los blobs tiene una implementación literal: **una variante es otra rotación de tono sobre la misma paleta**, o sea el mismo mecanismo de `blobs-elementos-y-recompensa` §3 aplicado dos veces. Regla propuesta `[PH]`: un duplicado suma 1 al contador de ese item; a **3** pasa a Dorado, a **8** a Arcoíris, a **20** a Cósmico. Cuando todo está en Cósmico, entonces sí `COMPLETA`.

Y resuelve de paso el problema emocional del duplicado en el endgame: **cuando ya tienes los siete, un duplicado deja de ser un duplicado y pasa a ser progreso visible sobre un item que te gusta.**

**No entra en v1.** V1 es World 1 con sus 7 (§9). La (c) es lo que se construye si la fase 4 mide que la máquina engancha, y **es la decisión que hay que tomar antes de construir la máquina del Desierto**, no después.

#### Y una consecuencia de permitir duplicados que sigue vigente

Los pools ya no se completan dentro de su mundo, así que un jugador que se va al Desierto con 6/7 tiene que **poder volver al lobby del Bosque a terminarlo**. El viaje entre mundos ya es gratis y los portales existen, así que la regla es: **cada máquina es usable siempre que estés en su lobby**, no solo mientras sea tu mundo actual. No abre ningún exploit — el reembolso es menor que el precio, así que toda tirada es Residuo neto negativo, y una máquina con el pool completo no cobra.

### 4.7 Pool completa

```
        ┌──────────────────────────┐
        │      ✔  COMPLETA         │
        │     7 / 7 · BOSQUE       │
        │  la del Desierto te      │
        │  espera con 7 más        │
        └──────────────────────────┘
```

**La máquina deja de aceptar Residuo.** No cobra, no sortea, no da consolación.

Cobrar por nada sería un patrón oscuro y además no hace falta: el Residuo sigue acumulándose hacia la máquina del mundo siguiente, así que el jugador que sigue jugando **está ahorrando**, no desperdiciando. Y ver el cartel de lo que hay en el Desierto es el empujón.

⚠️ **Con duplicados, el **`COMPLETA`** llega bastante después de terminar el mundo** (§4.6), así que el estado normal de la máquina del Bosque para un jugador del Desierto es *«me faltan dos»*, no *«completa»*. Esa máquina tiene que seguir siendo accesible y tiene que seguir apareciendo en la pestaña `BLOBS` con sus filas bloqueadas.

### 4.8 Reglas de plataforma — léelas antes de monetizar

|  |  |
| --- | --- |
| **v1: sin Robux en la máquina** | El Residuo solo se gana jugando. Así no hay obligación de publicar probabilidades ni riesgo en la revisión de monetización |
| ⚠️ **El día que se venda una tirada, un acelerador de Residuo o un pase que lo multiplique** | **Hay que publicar las probabilidades.** Los pesos de §4.4 —**18 % por común, 11 % por raro, 6 % el épico**, o sea 72 / 22 / 6 agrupado por rareza— son exactamente lo que habría que publicar, y **la piedad por racha ya está construida** — que es la otra mitad de lo que Roblox espera ver. Con duplicados en el sorteo esto deja de ser hipotético: si algún día entra Robux, es obligatorio |
| **Y ojo con la puerta trasera** | §3.4: si el Residuo saliera del goteo pasivo, el gamepass `x3 Offline Gains` (R$249) **ya sería** un acelerador de recompensas aleatorias, sin que nadie lo hubiera decidido |
| **Lo que sí se puede vender sin complicaciones** | Cosméticos **directos**, fuera del pool, a precio fijo. El jugador sabe exactamente lo que compra. Es la línea premium y no toca el gacha |

---

## 5. Pestaña de blobs en el inventario

### 5.1 Para qué sirve, exactamente

> **La pestaña sirve para dos cosas y solo para dos: EQUIPAR un aspecto y REVISAR cuáles tienes.**

No es una tienda: **aquí no se compra nada**, no se gasta Residuo y no hay ningún botón que abra un prompt de Robux. No es una pantalla de reclamo: no hay nada que recoger. No es la máquina: las recompensas no salen de aquí.

Es el armario. Se entra a ponerse algo o a mirar lo que se tiene, igual que la pestaña de WRAPS.

| Verbo | Dónde ocurre |
| --- | --- |
| **Conseguir** un cosmético | La máquina aspiradora (§4) |
| **Equipar** un cosmético | **Esta pestaña** |
| **Revisar** qué tienes y qué te falta | **Esta pestaña** |
| Comprar | La tienda, con Wins. **Nunca aquí** |

### 5.2 La regla de layout, que es donde falló la primera versión

La primera versión de este documento proponía una **rejilla de casillas con siluetas**. Estaba mal, y el motivo es que **el inventario ya tiene un idioma y la rejilla se lo saltaba**:

```
pestañas por TIPO  →  lista vertical de filas  →  chip de estado a la derecha
```

Es lo que hacen `TRAILS`, `AURAS` y `WRAPS` hoy, y funciona. Una rejilla al lado de tres listas se lee como otra pantalla que se coló dentro del inventario.

> La regla
> 
> **Las pestañas del inventario se organizan por TIPO de cosmético, no por procedencia.**
> 
> Un trail es un trail, lo hayas comprado con Wins o te haya salido de la máquina. Una pestaña llamada «COSMÉTICOS» que mezcla blobs, trails y auras porque *vienen del mismo sitio* obliga al jugador a recordar de dónde salió cada cosa para encontrarla. Nadie recuerda eso.

**Consecuencia directa, y simplifica todo:**

| Lo que entrega la máquina | En qué pestaña aparece |
| --- | --- |
| Paletas y elementos de blob | `BLOBS` — pestaña nueva, cuarta |
| Trails exclusivos | `TRAILS`, junto a los 15 de la tienda |
| Auras exclusivas | `AURAS`, junto a las 15 de la tienda |

Se añade **una** pestaña, no una pantalla. Y las dos que ya existen no cambian de estructura: solo reciben entradas nuevas.

### 5.3 El layout

Calcado del flujo de `WRAPS`, que es el que más se parece porque también es *elegir uno de una escalera y equiparlo*:

```
╔════════════════ ~INVENTORY~ ════════════════╗
║   ♻ 412 RESIDUO                        [X]  ║
╟─────────────────────────────────────────────╢
║  TRAILS    AURAS    WRAPS   ▎ BLOBS ▏       ║
╟─────────────────────────────────────────────╢
║                                             ║
║  ── BOSQUE ───────────────────────── 6 / 7 ─║
║  ┌───────────────────────────────────────┐  ║
║  │ ORIGINAL                              │  ║
║  │ el blob de tu pegamento   ⬤  ┌───────┐│  ║
║  │                              │EQUIPADO││  ║
║  └──────────────────────────────└───────┘┘  ║
║  ┌───────────────────────────────────────┐  ║
║  │ MUSGO                        común    │  ║
║  │ paleta                    ⬤  ┌───────┐│  ║
║  │                              │EQUIPAR ││  ║
║  └──────────────────────────────└───────┘┘  ║
║  ┌───────────────────────────────────────┐  ║
║  │ HOJA                         raro     │  ║
║  │ elemento                  ⬤  ┌───────┐│  ║
║  │                              │EQUIPAR ││  ║
║  └──────────────────────────────└───────┘┘  ║
║  ┌───────────────────────────────────────┐  ║
║  │ ? ? ?                        épico    │  ║
║  │ te falta uno              ◍  ┌───────┐│  ║
║  │                              │  ♻ 🔒 ││  ║
║  └──────────────────────────────└───────┘┘  ║
║                                             ║
║  ── DESIERTO ─────────────────────── 0 / 7 ─║
║  ┌───────────────────────────────────────┐  ║
║  │ ? ? ?                        común    │  ║
║  │ 🔒 desbloquea el Desierto ◍           │  ║
║  └───────────────────────────────────────┘  ║
╚═════════════════════════════════════════════╝
```

#### Anatomía de una fila — idéntica a la de WRAPS

| Zona | `WRAPS` hoy | `BLOBS` |
| --- | --- | --- |
| Título | `BASIC GLUE` | El nombre del aspecto — `MUSGO` |
| Sub-línea | `+1 / object` | **Qué es**: `paleta` · `elemento` · `elemento + piezas` |
| Esquina | — | **La rareza**: `común` · `raro` · `épico` |
| Icono | el bote de pegamento | **La silueta del blob, teñida** (§5.5) |
| Chip derecho | `EQUIPPED` verde / `🏆 14` | `EQUIPADO` verde / `EQUIPAR` / `♻ 🔒` |
| Fondo de la fila | el color del item | el `ColorA` del elemento |

**El fondo de la fila lleva el color del item, no el borde.** Es al revés que en el Shop, y es deliberado: está medido en este proyecto que **el color de fondo funciona en filas y no en tarjetas** — en una fila el texto va a un lado, sobre poco color; en una tarjeta el título va encima y un item casi blanco deja título blanco sobre fondo blanco.

#### Los tres estados de una fila

| Estado | Se ve | Chip |
| --- | --- | --- |
| **Equipado** | a color pleno | `EQUIPADO`, verde, no pulsable |
| **Lo tienes, no lo llevas** | a color pleno | `EQUIPAR`, pulsable. **Un toque, sin confirmación** |
| **No lo tienes** | nombre `? ? ?`, icono en silueta gris, fila atenuada | `♻ 🔒` — el icono de Residuo, que dice *de dónde sale* sin decir *qué es* |

**El hueco se conserva, pero dentro del idioma de filas.** La tensión de colección no necesitaba una rejilla: `WRAPS` ya enseña hoy los que no tienes, con su precio al lado. Aquí, en vez de un precio, la fila dice que eso sale de la máquina.

⚠️ **La fila no poseída enseña la rareza pero no el nombre.** Saber que te falta un épico es lo que crea la tentación; saber cuál te falta arruina el revelado de §4.2. Es la única diferencia real con la fila de un wrap, y tiene razón de ser.

#### ⭐ La fila `ORIGINAL`, y no es opcional

**Es la única forma de quitarse un elemento.** Sin ella, un jugador que equipa `MUSGO` no tiene ningún camino de vuelta al blob de su pegamento.

Y este proyecto ya se dio ese golpe exacto: al desdoblar el wrap en *ganancia* y *piel*, el cortocircuito `AlreadyEquipped` dejaba la piel **pegada para siempre**, porque la única acción capaz de cambiarla era justo la que se rechazaba. Aquí el riesgo es el mismo con un campo más — ver `claude/blobs-elementos-y-recompensa-2026-09-18.md` §2.2.

`ORIGINAL` va **siempre la primera**, siempre está desbloqueada, y equiparla escribe `BlobElementId = ""`.

#### La cabecera de grupo

Una fila de cabecera por mundo, dentro de la misma lista: `── BOSQUE ─── 6 / 7 ─`.

- Es **el contador de colección**, y está donde el jugador ya está mirando.
- Los mundos que no tiene desbloqueados salen igual, con sus siete filas bloqueadas y un `🔒 desbloquea el Desierto`. Ver siete huecos de un mundo al que no has llegado es aspiración, y es gratis.
- Es una fila más del `UIListLayout`, no un sistema aparte.

#### El saldo de Residuo, en la cabecera de la ventana

Donde hoy dice `0 WINS`. Misma esquina, mismo tamaño, mismo icono que el HUD y que el letrero de la máquina (§2.5). Aquí es **información, no un botón**: no se gasta Residuo desde el inventario.

### 5.4 Qué se reutiliza y qué hay que construir

|  |  |
| --- | --- |
| **Se reutiliza** | La ventana, la barra de pestañas, el `ScrollingFrame`, el `UIListLayout`, el patrón de fila, el chip de estado, y `CosmeticFeedback` — que ya existe porque trails y auras se compraban y equipaban en silencio |
| **Se construye** | Una pestaña más, una plantilla `_BlobRow`, una plantilla `_GroupHeader`, y el cableado a `BlobSkinService` |
| **Contrato de red** | Ninguno nuevo. Se copia `RequestWrap`: **el cliente solo pide un id y el servidor decide** si lo posee y lo equipa. Menos superficie que validar, y dos rutas que no pueden divergir |

⚠️ `_BlobRow`** va authored y FUERA del **`ScrollingFrame`, igual que `_WrapRow`: un `UIListLayout` reserva hueco también para los hijos invisibles, así que dejar la plantilla dentro deja un espacio vacío arriba de la lista.

### 5.5 El icono de la fila: un asset para los 21

El icono no es una imagen por elemento. Es **una silueta de blob en escala de grises, teñida con el **`ColorA`** del elemento** — un `ImageLabel` con `ImageColor3`.

- **Un solo asset** para las 21 filas, y para las que vengan después.
- Un elemento nuevo **no necesita arte de UI**: hereda el icono al declarar su paleta.
- Y para el estado no poseído, el mismo asset en gris. La silueta ya es el «hueco».

⚠️ **No usar **`ViewportFrame`** con el blob real por fila.** Es la opción tentadora —enseñaría exactamente cómo te verías— y son 21 vistas 3D vivas en una lista que además scrollea. Si más adelante se quiere esa previsualización, va **una sola, arriba de la lista**, que se actualiza al tocar una fila; no una por fila.

⚠️ **Los emoji no son todos iguales para Roblox.** 🫧 salía como hueco en blanco con FredokaOne mientras 👑 🏆 ⚡ ✨ se pintaban bien, y un icono que falta **no da error ni warning**: deja la fila muda. El icono de Residuo del chip `♻ 🔒` hay que verlo en una captura antes de darlo por bueno.

### 5.6 El flujo completo, de punta a punta

```
   máquina  ──►  revelado del premio  ──►  [ EQUIPAR ]  ──► ya lo llevas puesto
                        │                      │
                        │  [ SEGUIR ]          └── o después, desde la pestaña BLOBS
                        ▼
                  vuelves a jugar
```

**El botón **`EQUIPAR`** del revelado (§4.2) y el chip **`EQUIPAR`** de la fila hacen exactamente lo mismo y llaman al mismo sitio.** Uno es para el momento; el otro, para cuando cambies de idea. Si el jugador pulsa `SEGUIR`, el premio queda en la pestaña con su chip `EQUIPAR` esperando — y esa es la razón de que la pestaña exista.

---

## 6. Arquitectura técnica

### 6.1 Servicios

| Módulo | Dónde | Responsabilidad |
| --- | --- | --- |
| `ResidueService` | `ServerScriptService/Server` | Autoridad del saldo. Concede al recoger, cobra, persiste |
| `VacuumMachineService` | `ServerScriptService/Server` | Ocupación del pad, cobro, sorteo, concesión del cosmético |
| `VacuumMachineController` | `StarterPlayerScripts/Client` | Letrero, blur, ruleta, revelado, limpieza |
| `BlobSkinService` | `ServerScriptService/Server` | Propiedad y equipado de colores/mallas de blob |
| `CosmeticInventoryController` | `StarterPlayerScripts/Client` | La pestaña nueva |

### 6.2 `ResidueService`

```
-- La ÚNICA puerta. No se engancha a la concesión de Stickiness (§3.4).
PickupService.ConnectCollected(function(player, payload)
    local value = ResidueValueOf(payload.TemplateName)          -- authored, fallback 1 + warn
        * GameConfig.Residue.WorldMultipliers[state.CurrentWorldId]
    state.Residue += value
    player:SetAttribute("Residue", state.Residue)               -- replicado, lo pinta el HUD
end)
```

- **El atributo replicado **`Residue`** lleva el saldo**, igual que `Stickiness` y `Wins`. El HUD lo pinta sin que nadie le cuente nada.
- **El servidor es la verdad.** El cliente nunca envía cuánto residuo tiene ni cuánto ha ganado.
- ⚠️ **No emitir un evento de analítica por recogida.** A 1,5 obj/s × 12 jugadores son 18 eventos por segundo. Se agrega (§7).

### 6.3 `VacuumMachineService` — el sorteo vive aquí y solo aquí

```
local function tryPull(player)
    if locked[player.UserId] then return end                     -- 1. lock de animación
    local machine = machineForPad(padTouched)
    if not state.UnlockedWorlds[machine.WorldId] then return end -- 2. su mundo, no el actual (§4.6)
    if state.Residue < machine.Price then return end             -- 3. saldo
    if poolComplete(machine.PoolId, state) then                  -- 4. pool completa: NO cobra
        return showComplete(player)
    end

    locked[player.UserId] = true
    state.Residue -= machine.Price                               -- 5. COBRA PRIMERO
    state.PendingPull = machine.PoolId                           -- 6. marca, y persiste ya
    DataService.FlushNow(player)

    -- 7. sortea EN SERVIDOR, con duplicados y con piedad (§4.4)
    local elegido, isDup = rollFor(player, machine, state)
    local refunded = 0
    if isDup then
        state.DupStreak += 1
        refunded = math.floor(machine.Price * GameConfig.Residue.DuplicateRefund)
        state.Residue += refunded
    else
        state.DupStreak = 0
        grantCosmetic(player, elegido)
    end

    state.PendingPull = nil
    DataService.FlushNow(player)                                 -- 8. el resultado también se persiste
    -- 9. y solo ahora el cliente se entera de qué pasó
    VacuumReveal:FireClient(player, elegido.Id, elegido.Rarity, isDup, refunded,
                            state.DupStreak, piezasAAspirar)
end
```

**Por qué en ese orden, punto por punto:**

- **El sorteo nunca sale del servidor.** Si el cliente recibiera el pool y la semilla, un exploiter reintentaría hasta sacar el épico. El cliente recibe **un id ya decidido** y lo pinta.
- **Cobrar antes que sortear** hace que un corte a mitad no pueda regalar una tirada.
- `PendingPull`** persistido** hace que un corte a mitad no pueda robarla: al cargar el perfil, si hay un `PendingPull`, se **devuelve el precio entero** y se olvida la tirada. Devolver es más simple y más seguro que re-sortear, y con duplicados en la mesa es además lo único legible: el jugador no puede distinguir «me devolvieron la tirada» de «me tocó duplicado». Sin esto, una caída entre el cobro y la concesión le quita el Residuo y no le da nada.
- **El **`DupStreak`** y el **`Residue`** se persisten en la misma transacción que el cobro.** Si el reembolso se guardara aparte, una caída entre los dos pasos cobraría la tirada y perdería el reembolso — que es exactamente el bug que un jugador reporta como «me robó Residuo».
- **El lock se suelta** al confirmar el cliente o por timeout de 8 s, lo que llegue antes. Nunca solo por el cliente.

⚠️ `Touched`** no dispara si el personaje aparece encima del pad sin moverse.** Está documentado (2026-08-06): Roblox necesita contacto real, no solapamiento estático. Un jugador teletransportado por `ReturnToStart` justo encima de la máquina no la activaría. **Dos salidas:**

- **(recomendada)** Ocupación por prueba de punto-en-caja contra la **posición del servidor**, en un tick de 0,25 s. Con 3 máquinas y 12 jugadores son 36 pruebas por tick: más barato, más determinista, y usa la posición que el servidor ya tiene. Es el mismo patrón que `VacuumZoneService` y `PickupService`.
- Mantener `Touched` y asegurarse de que ningún spawn ni teleport cae sobre un pad.

### 6.4 Persistencia

Se añaden al perfil de `DataService`:

| Campo | Tipo | Nota |
| --- | --- | --- |
| `Residue` | number | Saldo. **Sobrevive al Rebirth** — el Rebirth reinicia poder, no colección |
| `OwnedCosmeticIds` | string | ⚠️ **Los atributos no admiten tablas.** Cadena separada por comas, exactamente como `OwnedWrapIds`. Una sola señal de cambio en vez de una por item |
| `EquippedBlobSkinId` | string |  |
| `PendingPull` | string? | §6.3 |
| `DupStreak` | number | Duplicados consecutivos. **Es la piedad** (§4.4). Si no se persiste, se reinicia al reconectar y deja de acotar nada |

- `UpdateAsync`, nunca `SetAsync`. Session lock, reintentos con backoff, autosave, guardado en `PlayerRemoving` **y** `BindToClose`. Todo eso ya está construido en `DataService`.
- **Normalizar al cargar**, como hace `normalizeWrapIds`: un id que ya no exista en el catálogo se descarta, para que un perfil viejo o manipulado no meta un cosmético inventado.
- ⚠️ **El Rebirth no borra ni el Residuo ni los cosméticos.** `Cosmetics.ResetOnRebirth = false` ya es la regla para trails y auras; el pool de la máquina va en el mismo saco y por la misma razón: se pagaron con tiempo, no con la vuelta.

### 6.5 Casos borde

| Caso | Comportamiento correcto |
| --- | --- |
| Se desconecta durante la animación | `PendingPull` en el perfil: al volver, recibe el premio (o el reembolso). **Nunca se pierde el cobro** |
| El servidor cae entre cobro y concesión | Igual. Es para lo que existe `PendingPull` |
| Pisa el pad dos veces en el mismo frame | El lock por jugador, puesto **antes** de cobrar |
| Pisa el pad con el pool completo | No cobra. Cartel `COMPLETA` |
| Pisa el pad sin saldo | No cobra. El cartel ya decía cuánto falta |
| **Muere / respawnea con el blur puesto** | El controlador limpia en `CharacterRemoving`. **Probarlo explícitamente** |
| **Viaja de mundo durante la animación** | Salida forzada, blur fuera, lock suelto. El `PendingPull` se resuelve igual |
| Renace (Rebirth) durante la animación | Bloquear el Rebirth mientras el lock esté puesto |
| La bola está vacía al tirar | Se cobra igual y no se aspira nada. **El Residuo es el precio, la bola es el espectáculo** |
| Tiene blockers pegados y aspira al 100 % | Se aspiran los últimos, después de todo lo no protegido (§4.3) |
| Dos jugadores pisan el mismo pad a la vez | Estado, cobro y sorteo por jugador. Ninguno ve ni toca lo del otro |
| **Sale duplicado y se desconecta antes del revelado** | El reembolso ya está en el perfil (misma transacción que el cobro). Al volver tiene el Residuo devuelto y el `DupStreak` subido |
| **Llega a 5 duplicados y cambia de mundo antes de tirar** | El `DupStreak` es **del jugador, no de la máquina**. La garantía se cobra donde tire. Es lo más simple y lo más justo |
| Tira en la máquina de un mundo que no es el actual | Permitido si lo tiene desbloqueado (§4.6). Se cobra el precio de **esa** máquina |
| Recoge un objeto sin `ResidueValue` authored | Cae a **1** con `warn` explícito. Nunca en silencio |
| Un evento de mundo `Stickiness ×2` está activo | **El Residuo no se multiplica** (§3.4). Verificarlo con un test |
| Está en una Rest Zone acumulando goteo | **Cero Residuo.** Es el caso bloqueante de §3.4 |
| Entra con un perfil viejo, sin campos de Residuo | Defaults limpios. `Residue = 0`, sin cosméticos |

---

## 7. Instrumentación

Sin esto no se puede balancear ni el precio ni el pool, y la §3.5 no se puede leer.

| Evento | Campos | Para qué |
| --- | --- | --- |
| `ResidueEarned` | `worldId`, `zoneId`, `amount`, `windowSeconds` | **Agregado por zona y minuto, nunca por recogida.** Es la curva de ingreso real, que es lo que valida o tumba los 270 ♻/min del modelo |
| `VacuumActivated` | `worldId`, `price`, `residueBefore`, `pullIndex`, `secondsSinceLastPull` | **El dato central.** `residueBefore / price` dice si el precio está bien; `secondsSinceLastPull` dice si el ritmo engancha |
| `CosmeticGranted` | `itemId`, `rarity`, `pullIndex`, `poolRemaining`, `isDuplicate`, `dupStreak`, `refunded` | La curva de completado, la tasa real de duplicados y **si la piedad se está disparando**. Sin `dupStreak` no hay forma de saber si el P90 de §4.4 se cumple en vivo — y ese P90 es lo único que separa esta feature de una frustración |
| `CosmeticEquipped` | `itemId`, `secondsSinceGranted` | **Si nadie equipa, el premio no vale nada** y el problema es el arte, no la economía |
| `PoolCompleted` | `worldId`, `totalMinutes` | ¿Llega el `COMPLETA` cuando debe? |
| `ZoneCleared` (ya existe) | + `residueEarned` | Cruzar ritmo de Residuo contra ritmo de sala |

**Lo primero que hay que graficar:** el **tiempo hasta la primera tirada** de un jugador nuevo, por percentiles. Si la mediana pasa de 4 minutos, bajar el precio de World 1 antes de tocar nada más (§4.6).

**Lo segundo:** duración de sala antes y después de retirar el requisito (§2.4). Es el riesgo con más impacto sobre el presupuesto de contenido y es el más fácil de medir.

**Lo tercero:** la **distribución de tiradas hasta completar**, contra la simulación de §4.4. El modelo dice mediana **16** y P90 **21**. Si en vivo el P90 se va a 60, o la piedad no está enganchada o el `DupStreak` no se persiste — y los dos son fallos silenciosos: nadie los reporta como bug, la gente solo deja de tirar.

⚠️ **Si esto se construye en un place laboratorio, la analítica del laboratorio cae en el mismo funnel que producción** — el dashboard agrega por universo, no por place. La guarda es la misma de `rework-aspiradoras-w1` §0.2: `if game.PlaceId ~= PRODUCTION_PLACE_ID then return end`.

---

## 8. Riesgos

| # | Riesgo | Gravedad | Mitigación |
| --- | --- | --- | --- |
| 1 | **Las Rest Zones / Offline Gains imprimen Residuo** y el gacha se vuelve AFK y monetizado | 🔴 **bloqueante** | §3.4. `ResidueService` se engancha a `PickupService.ConnectCollected`, jamás a la concesión de Stickiness. **Test explícito: 60 s en una Rest Zone → **`Residue`** sin cambio** |
| 2 | **World 1 se acorta** al retirar el requisito y el presupuesto de contenido se descuadra | 🟠 alta | §2.4. Dos corridas cronometradas con el flag encendido y apagado, **antes** de construir la máquina |
| 3 | **El blur se queda pegado** tras una muerte o desconexión | 🟠 alta | §4.2. Limpieza en `CharacterRemoving`, `PlayerRemoving` y `Destroy()`. Es de una línea y arruina la sesión |
| 4 | **Tirón al aspirar la bola en móvil** (10,6 ms escritorio / 50–100 ms móvil) | 🟠 alta | §4.3. Nunca `Destroy`; liberar al pool, escalonado sobre los 2,5 s, con techo por frame |
| 5 | **El pool canibaliza la tienda de Wins** y las Wins se quedan sin sumidero | 🟡 media | §4.5. Pool exclusivo. Ninguna intersección con el catálogo de Wins |
| 6 | **El jugador no relaciona el número del objeto con el contador ni con la máquina** | 🟡 media | §2.5. Un icono, un color, los tres sitios. Y el popup doble en la recogida |
| 7 | **La máquina no se ve y nadie tira** (\< 20 % de participación) | 🟡 media | Colocarla **en la ruta de salida del lobby**, no en un rincón, y con el cartel visible desde el spawn. El criterio es el de las placas de wrap y las caminadoras, que funcionan porque están **en el camino, no son un destino** |
| 8 | **La piedad no se engancha, o el **`DupStreak`** no se persiste** | 🔴 **muy alta con 7 items** | §4.4. Sin ella el P90 de completar pasa de 48 a **56 minutos** y la relación P90/mediana salta de ×1,24 a **×1,60**. Y **falla en silencio**: el sorteo funciona, solo que a algunos les va muy mal. Test: forzar 5 duplicados y comprobar que la sexta es nueva; y reconectar a mitad de racha |
| 8b | **El reembolso se lee como castigo** y el jugador deja de tirar | 🟠 alta | §4.4. El revelado del duplicado nunca usa `Denied` ni la fanfarria completa. Se mide con `CosmeticGranted.isDuplicate` cruzado contra `SessionEnd` |
| 9 | **El cartel de la máquina sale mudo** (`TextBounds = 0,0`) o invisible (`Adornee` mal repuntado al duplicar) | 🟡 media | §2.2 y §4.1. Las dos ya mordieron a este proyecto |
| 10 | **Se vende algo de la máquina por Robux sin publicar probabilidades** | 🟡 media | §4.8. Decidirlo ahora, no después |
| 11 | **El jugador se va al Desierto con el pool del Bosque a medias y no puede volver a terminarlo** | 🟡 media | §4.6. Cada máquina se usa siempre que estés en su lobby, no solo mientras sea tu mundo actual. Y la pestaña `BLOBS` tiene que seguir enseñando el grupo del Bosque con sus filas bloqueadas |
| 11b | **No hay camino de vuelta al aspecto original** y el elemento se queda pegado | 🟠 alta | §5.3. La fila `ORIGINAL`, siempre primera y siempre desbloqueada. Es el bug del `AlreadyEquipped`, que ya pasó una vez con dos campos y ahora hay tres |
| 12 | **La máquina se apaga en el primer 20 % del Desierto y el 8 % de Lava** | 🟠 alta, pero **fuera de v1** | §4.6. Es estructural de un pool de 7, no un error de precio. La respuesta son las **variantes** (opción c). **Decidirlo antes de construir la máquina del Desierto**, no después |

---

## 9. Fases

Cada fase se juega antes de empezar la siguiente. La regla es la de siempre: **una pieza completa antes que tres a medias.**

| # | Fase | Contenido | Criterio para pasar |
| --- | --- | --- | --- |
| **0** | **Medir el antes** | Corrida cronometrada de las 10 salas de World 1, con el requisito puesto. Censo de duración por sala | Hay un número contra el que comparar. **Sin esto, la fase 1 no se puede juzgar** |
| **1** | **Retirar el requisito** | `RequireStickinessForPickup = false`. Nada más | Corrida cronometrada otra vez. **Se conoce el Δ de duración por sala** (§2.4) y se ha decidido si se compensa |
| **2** | **El Residuo existe** | `ResidueValue` authored en los props, `ResidueService`, la etiqueta nueva, el contador del HUD | Un jugador nuevo entiende **sin leer nada** que el número del objeto es lo que se le suma arriba. **Y 60 s en Rest Zone dan 0 Residuo** (riesgo 1) |
| **3** | **La máquina, sin premios** | Pad, letrero, cobro, aspiración de la bola, blur, revelado con un cosmético de prueba | Cobra bien, aspira sin tirones **en móvil**, el blur se va siempre. 20 ciclos sin fugas ni instancias huérfanas |
| **4** | **El pool de World 1** | **7** cosméticos exclusivos (4C / 2R / 1E), sorteo **con** duplicados, reembolso 40 %, piedad 5, primera tirada a 250, `COMPLETA` | Corridas simuladas contra el servidor real: **mediana ≈ 16 tiradas, P90 ≤ 21**, ninguna racha de más de 5 duplicados, y el `DupStreak` sobrevive a una reconexión |
| **5** | **La pestaña **`BLOBS` | Cuarta pestaña con el mismo patrón de filas que `WRAPS`, fila `ORIGINAL`, cabeceras por mundo, filas bloqueadas | Un jugador **equipa en un toque**, **vuelve a **`ORIGINAL` sin quedarse atrapado, y ve qué le falta y de dónde sale |
| **6** | **Instrumentación** | Los 6 eventos de §7 | Se puede graficar tiempo-hasta-primera-tirada y duración de sala antes/después |
| **7** | **Mundos 2 y 3** | Dos máquinas más, dos pools | Las **tres referencias** del §4.1 repuntadas y verificadas en cada copia |

### Lo que puede ir en paralelo desde el minuto cero

- **Los **`ResidueValue`** authored en los props** — es tabla, no código, y no depende de nada.
- **El arte de los colores de blob** — coste casi nulo y es el 60 % del pool de World 1.
- **La decisión de qué VFX son exclusivos** y cuáles se quedan en la tienda de Wins (§4.5).
- **Elegir dónde va la máquina en cada lobby** (riesgo 7). Es diseño de nivel puro.

### Lo que no se recorta si hay que recortar alcance

|  | Por qué |
| --- | --- |
| **La guarda del goteo pasivo** (§3.4) | Sin ella el gacha es AFK y un gamepass de R$249 lo acelera por accidente |
| **La medición de la fase 0** | Sin el antes, el Δ de duración de World 1 no se puede saber nunca |
| `PendingPull`** persistido** (§6.3) | Sin él, una caída de servidor cobra sin dar premio |
| **La limpieza del blur** (§4.2) | Una línea, y sin ella la sesión se rompe |
| **El sorteo en servidor** (§6.3) | Sin él, el gacha se exploita el primer día |
| **La piedad por racha** (§4.4) | Con 7 items es aún más crítica que con 15: sin ella el decil con mala suerte tarda un **60 %** más que la mediana, tirando contra un 6 % de probabilidad. Si se recorta, se recortan los duplicados con ella |
| **La primera tirada a 250** (§4.6) | A precio pleno la primera tirada cae en el minuto 3,8, y el embudo ya pierde el 39,6 % de las vueltas antes de eso |

Lo primero que se cae, en este orden: la tirada dorada (§4.4), los blobs con malla propia (los caros del pool), y el pulido de la ruleta. **La piedad no está en esa lista**: si no cabe, lo que no cabe son los duplicados, y entonces el pool vuelve a ser de 35 items para durar lo mismo.

---

## 10. Las dos dudas, en corto

### ¿Residuo con fórmula de recolección, como la Stickiness?

> **No.** Si usa la fórmula, el número sobre el objeto vuelve a tener la magnitud de la Stickiness y **la confusión que motiva este cambio se duplica en vez de arreglarse.** Además, una moneda de colección que escala con la curva de poder solo puede acabar en cinta de correr (si el precio escala igual) o en pool vaciado en una tarde (si no escala).
> 
> **El valor sale del objeto: 1–8 según su tamaño**, authored en el prop, sobre el carril de datos que `GainMultiplier` lleva reservado desde agosto. La progresión por profundidad sale sola porque las salas tardías ya usan props más grandes. Y el precio de la máquina queda expresado en minutos de recoger, que es la única unidad de este juego que no se devalúa.

### ¿Le afecta el multiplicador del mundo?

> **El de Stickiness, no. Nunca.** `Worlds[].StickinessMultiplier` es el **dial de duración** del proyecto y se re-afina cada pocas semanas: `lava-20h` lo usó, y sus valores vivos (`1 / 1 / 1,8`) ya no son los de diseño (`1 / 2 / 4,5`). Colgar el gacha de él significa que cualquier ajuste de contenido cambia el ritmo de los cosméticos en silencio. Y de todas formas se cancela: si el ingreso sube ×1,8 y el precio sube ×1,8, no ha pasado nada.
> 
> **Sí a un dial propio, **`Residue.WorldMultipliers`**, y en v1 apagado (**`1 / 1 / 1`**).** La progresión por mundo ya la da el arte. Si algún día lo enciendes, la regla es: **el precio de la máquina sube más que el multiplicador**, para que el mundo profundo se sienta más caro por tirada y mejor por premio. Es la misma forma que ya funciona en los mundos (*requisitos ×10, Wins ×15*).

---

## 11. Lo que este cambio arregla, dicho con los datos que hay

El diagnóstico del 15 de septiembre sigue en pie:

> *«La primera sesión funciona. El retorno no existe. El bucle cierra limpio cada dos minutos y no tiene nunca un cliffhanger.»*

Y el análisis del competidor lo dejó en una línea:

> *«Su bucle tiene un momento de incertidumbre cada pocos minutos. El tuyo no tiene ninguno.»*

Esto mete ese momento en el sitio por el que el jugador ya pasa, con una moneda que ya está produciendo sin saberlo, sobre una bola que ya lleva encima y que hasta hoy no servía para nada. **No inventa un juego nuevo: le da un destino al que ya existe.**

Y añade lo que ni el pedestal ni el blocker pueden dar: **una lista con huecos.** Un jugador que lleva 6 de 7 tiene una razón concreta para volver mañana, y es la clase de razón que sobrevive a cerrar la app. Y como la colección vive en la pestaña que ya visita para equiparse, ese hueco no hay que ir a buscarlo: aparece solo cada vez que entra a cambiarse de aspecto.

> **Pero la pregunta de los diez segundos sigue sin mirarse:** el **ratio de likes**. El competidor está en 97 %. Con el D1 en 2,7 % y el funnel de onboarding en 73 %, ese número es lo único que separa *«les gusta y no vuelven»* de *«no les gusta tanto como creemos»* — y decide si esta feature es la correcta o si el problema está más abajo. **Sigue costando menos que cualquier párrafo de este documento.**
