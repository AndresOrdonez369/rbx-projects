# Rework de World 1: Áreas aspiradoras · Especificación para programación

**Fecha:** 2026-09-17 · **Alcance:** World 1 primero, los tres mundos después.

|  | Place | Rol |
| --- | --- | --- |
| **Producción** | `95828455414780` | El juego vivo. 25 CCU, ads corriendo. **No se toca.** |
| **Laboratorio** | `123113535376730` | Aquí se implementa y se prueba todo, en su propio `World 1 V2` |
| **Universo** | `10604653036` | ⚠️ **Compartido por los dos.** Ver §0.1 |

**Decisiones tomadas por Camilo (17-sep):** morir no cuesta Stickiness · letrero blando (*Recommended*) · las Wins se bancan en los Win Pedestals existentes · **se construye entero en el place laboratorio y, si funciona, se porta a producción**.

---

## 0. Cómo se construye: un place laboratorio

Todo el rework se implementa en el place `123113535376730`, sobre su propio `World 1 V2`, con los nombres de siempre. **No hay **`World 1 V3`: el laboratorio es el place entero.

Producción no se entera hasta el port-back, así que **el riesgo sobre el juego vivo es cero** y **la lectura del sprint D1 del 20 de septiembre sobrevive intacta** — esas predicciones (`claude/plan-d1-4dias-2026-09-15.md` §6) siguen sin leerse y valen para los tres mundos.

> **La logística completa —aislamiento de datos, qué comparten los dos places, el diff, el port-back y sus checklists— vive en **`claude/fase0-duplicado-w1v3-2026-09-17.md`**.** Lo de aquí abajo es lo que no se puede dejar para mañana.

### 0.1 ⚠️ Los DataStores son del universo, no del place

**Los dos places comparten el universo **`10604653036` (verificado contra la API de Roblox), y un DataStore pertenece al universo. **El laboratorio escribe en el mismo **`PlayerData_v1`** que el juego vivo.**

Cualquiera que entre a probar está escribiendo sobre su perfil real, y un bug del drenaje en una build temprana le borra la Stickiness de verdad a una cuenta de verdad.

**Se cierra hoy, antes de la primera sesión de Play:**

```
-- GameConfig, SOLO en el laboratorio
DataStore = { Name = "PlayerData_v1", Scope = "VacuumDev" }
```

Y **ese campo es exactamente el que no se porta a producción**, o todo el mundo entra con el perfil vacío.

### 0.2 ⚠️ La analítica del laboratorio contamina la de producción

El dashboard agrega por **experiencia**, o sea por universo. Los eventos del laboratorio caen en el mismo funnel que los de producción — y producción mueve 25 CCU, así que **un tester haciendo cincuenta corridas se ve en las curvas que hay que leer el día 20**.

```
local PRODUCTION_PLACE_ID = 95828455414780
function Analytics.log(player, eventName, fields)
    if game.PlaceId ~= PRODUCTION_PLACE_ID then return end
    -- …
end
```

Se enciende otra vez, con un CustomField `variant`, cuando el modo llegue a producción.

### 0.3 Congelar producción

Cada cambio que producción reciba y no se replique al laboratorio encarece el port-back y lo vuelve más arriesgado. **Recomendación: congelar producción mientras dure el rework.** El juego está en 2,7 % de D1; no hay ahí ningún cambio que valga más que llegar limpio. Única excepción: un bug que esté rompiendo sesiones.

### 0.4 Y las tres protecciones de siempre

1. **Backup a **`ServerStorage` antes de la primera escritura, en los dos places.
2. **Flag maestro **`GameConfig.VacuumZones.Enabled`**.** Apagarlo devuelve el comportamiento actual **sin revertir geometría**. El rollback tiene que ser un booleano.
3. **Publicar a mano** — el MCP no expone Save/Publish. Es el paso que más veces se ha olvidado.

---

## 1. El cambio, en una página

### Hoy (producción, no se toca)

```
LOBBY ──► ZONA 1 ──► ZONA 2 ──► … ──► ZONA 10 ──► FINISH
          recoge     recoge            recoge
          objetos    objetos           objetos
          abre       abre              abre
          blocker    blocker           blocker
```

Un solo bucle. Recoges, abres, avanzas. **Determinista de principio a fin.**

### El modo nuevo

```
        ┌───────────────── LOBBY ──────────────────────┐
        │  ÚNICA zona de farmeo. Todos los objetos.   │
        │  Aquí sube la Stickiness. Aquí no hay       │
        │  peligro y no se gana ninguna Win.          │
        └───────────────────┬─────────────────────────┘
                            │  entras con tu TOTAL
                            ▼
   ZONA 1 ──► pasillo ──► ZONA 2 ──► pasillo ──► … ──► ZONA 10
   aspira     PEDESTAL     aspira     PEDESTAL          aspira
   ‑D₁/s      banca 1 W    ‑D₂/s      banca 3 W         ‑D₁₀/s
     │        cura total     │        cura total          │
     └── si llegas a 0 ──────┴───────────────────────────┘
              te absorbe la aspiradora, caes, vuelves al lobby
              CON TU TOTAL INTACTO · SIN LAS WINS NO BANCADAS
```

**Dos bucles que se alimentan:** el lobby produce Stickiness; las zonas convierten Stickiness en Wins; las Wins compran wraps que hacen el lobby más rápido.

### Qué es cada cosa en el modo nuevo

|  | Hoy | **Nuevo** |
| --- | --- | --- |
| **Stickiness** | Se acumula y abre puertas | **Vida.** El total es tu máximo; dentro de un área baja; al salir se cura entera |
| **Wins** | Premio de pedestal | **La apuesta.** Lo único que se pierde al morir |
| **Las zonas** | Sitios donde recoger | **La apuesta.** Cada una es un cruce cronometrado |
| **Los pasillos** | Tránsito | **Zona segura.** Curan, tienen pedestal y cintas, y ahí se decide |
| **El lobby** | Vestíbulo | **La mina.** El único sitio donde sube el número |
| **Los blockers** | Puerta dura | Retirados como puerta. Ver §9 |

---

## 1-bis. La mecánica, completa y en un solo sitio

El resto del documento la desarrolla por capas —economía en §3, balance en §4, nivel en §5, código en §6—. **Esto es el resumen normativo:** las cuatro piezas y qué hace cada una.

### Las cuatro piezas, y su única responsabilidad

| Pieza | Tag | Medida | **Hace exactamente una cosa** |
| --- | --- | --- | --- |
| **Área aspiradora** | `VacuumZone` | `96 × 38 × 168` (ajustable, §1-bis.2) | **Drena** la Stickiness y **topa** la velocidad mientras estés dentro |
| **Aspiradora** | `VacuumProp` | `11 × 38 × 160`, dos por zona | **Absorbe** al jugador, y solo al llegar a 1 |
| **Letrero** | authored | entrada de la zona | **Informa**: número de zona y Stickiness recomendada |
| **Powerup** | authored | dentro del área | **Cura**, hacia el Total y nunca por encima |

### 1-bis.1 El área aspiradora, punto por punto

1. **Drena mientras haya overlap.** `D_n` por segundo, en `TickSeconds` de 0,25 s. La cifra que baja es la **Actual**, no el Total (§2.1).
2. **Reduce los assets pegados, visualmente y en proporción.** `ratio = Actual / Total` → el renderer recorta el presupuesto visible. ⚠️ **Los records lógicos NO se destruyen** (§6.4): destruirlos cuesta 10,6 ms de Lua en escritorio y 50–100 ms en móvil, cada entrada y cada salida.
3. **Topa la velocidad.** `min(v_jugador, SpeedCap)`, default 22,4. Se aplica por el pipeline de perks, **nunca escribiendo **`WalkSpeed` (§6.2.1).
4. **Si la Actual llega a 1, muere.** La aspiradora más cercana lo absorbe, cae al FailVolume, y vuelve al spawn del lobby **con su Total intacto** y **sin las Wins no bancadas** (§6.3).
5. **Al dejar el overlap, se cura del todo.** Stickiness y assets vuelven al Total. «Curar» es `Actual = Total`: no hay snapshot que guardar (§6.2).
6. **Es balanceable con un solo número authored**: `RecommendedStickiness`. El drenaje **se deriva** de él, para que las dos cifras no puedan divergir (§3.1).

### 1-bis.2 El tamaño también es una palanca de balance

`96 × 38 × 168`** es el estándar y lo más probable es que sea el de las diez zonas.** Aun así, el tamaño **no se hardcodea**, y no es por purismo: si algún día una zona cambia de fondo, el tiempo de cruce cambia con ella, y con él la dificultad real. **El letrero empezaría a mentir en silencio** — que es justo la divergencia `GameConfig` ↔ Workspace que este proyecto lleva meses arrastrando con los blockers de World 1.

**Por eso el drenaje se deriva de la geometría real de la parte, no de una constante:**

```
local t_cruce = area.Size.Z / math.min(speedCap, walkSpeed)
local drainPerSecond = recommendedStickiness / (t_cruce * GameConfig.VacuumZones.SafetyMargin)
```

Con eso, **un diseñador puede redimensionar el área en el Explorer y el balance se recalcula solo**: el jugador sigue necesitando exactamente `Recommended` para cruzar con el mismo margen, mida el área 168 o 220 de fondo. La zona se vuelve más larga y más suave, o más corta y más brutal, sin tocar ninguna tabla.

⚠️ **Nunca hardcodear 168.** Es el valor de hoy, no una constante del sistema.

### 1-bis.3 Lo que decide si sobrevives vive en una sola instancia

Todo el balance de un cruce está en los atributos del `VacuumZone`: su `Size.Z`, su `RecommendedStickiness` y su `SpeedCap`. **Los 20 props no llevan ningún dato de balance.** Es la decisión de §4.3 y su razón de ser: no tener que afinar dos objetos a la vez para ajustar una zona.

### 1-bis.4 Las aspiradoras, cómo quedaron funcionando

Su papel original era *«la justificación visual del porqué el player pierde assets y stickiness»*, y eso es exactamente lo que son al final: **el objeto que explica lo que le está pasando al jugador, sin tocarle el personaje.**

|  |  |
| --- | --- |
| **Tag** | `VacuumProp` |
| **Medida** | `11 × 38 × 160` — altas y estrechas, a los lados del área |
| **Cantidad** | Dos por zona, una a cada lado |
| **Atributos** | **Solo **`ZoneId`**.** Ningún dato de balance |
| **Colisión** | **Ninguna** con el jugador. No son un obstáculo |

**Tres funciones, y solo una es comportamiento:**

1. **Ancla de los VFX.** Los chorros de succión, las partículas y el ruido salen de ellas. Es su trabajo principal y es permanente: lo que hace que el área se lea como una aspiradora y no como un campo de lentitud.
2. **Destino de las piezas recortadas.** Conforme baja la Actual, los assets que el renderer quita **vuelan hacia la aspiradora más cercana** en vez de desvanecerse en el sitio (§6.4.1). Esto es lo que las vuelve **visiblemente la causa**: el jugador ve sus cosas irse hacia ellas.
3. **Destino de la succión de muerte.** Al llegar a `Actual ≤ 1`, la más cercana lo absorbe y cae al FailVolume (§6.3). **Es la única vez que un prop ejecuta algo**, y ocurre como máximo una vez por corrida.

**Lo que NO hacen, y cambió el 17-sep:**

- ❌ **No drenan.** Drena el `VacuumZone`.
- ❌ **No reducen la velocidad.** La topa el `VacuumZone` con su `SpeedCap`.
- ❌ **No tiran del jugador durante el cruce.** Cero física mientras juegas; solo en la muerte.

> **La razón del reparto** (§4.3): unificar la función de cada elemento para no tener que balancear varios a la vez. Todo el balance de un cruce vive en el `VacuumZone`; las 20 aspiradoras son decorado con una función que se dispara una sola vez.

---

## 2. Las cuatro decisiones, y lo que implican

### 2.1 La Stickiness es una barra de vida ⭐ el modelo, en una frase

> **Tu Stickiness total es tu vida máxima. Las zonas te hacen daño. Las safe zones te curan del todo. Los powerups son pociones que no pueden pasarse del máximo.**

```
Lobby ──► subes tu TOTAL        (es lo único que lo sube; el Rebirth es lo único que lo baja)
Zona  ──► baja la ACTUAL        (daño por segundo)
Salida a pasillo ──► la ACTUAL vuelve al TOTAL, entera
Powerup ──► la ACTUAL sube hacia el TOTAL, nunca por encima
ACTUAL = 0 ──► te absorbe, mueres, vuelves al lobby con tu TOTAL intacto
```

**Cada zona es una prueba independiente:** *¿mi total aguanta este cruce?* No hay desgaste acumulado entre zonas, no hay checkpoints, no hay nada que recordar. Si tu total alcanza para la zona 7, alcanza siempre, hasta que renazcas.

**Las dos consecuencias que importan:**

**a) Dos números, no uno.** El total persistido y el actual replicado son cosas distintas, y confundirlos es el bug caro de este sistema:

|  | Qué es | Quién lo cambia | Se persiste |
| --- | --- | --- | --- |
| **Total** | La vida máxima. El progreso real del jugador | Lobby y Rebirth, nada más | **Sí**, en el perfil |
| **Actual** | Lo que queda dentro de un área | El drenaje y los powerups | **No.** Se descarta siempre |

El atributo replicado `Stickiness` lleva **el actual**, así que el HUD enseña el drenaje **sin tocar una línea de HUD**. El perfil guarda **el total**, así que un autosave a mitad de un cruce no puede robarle nada al jugador.

**b) La tensión vive entera en las Wins.** No hay castigo por intentarlo: el diseño es amable con menores de 13 y aun así es una apuesta, porque las Wins sin bancar sí se pierden.

### 2.2 Letrero blando (*Recommended*), no puerta dura

Siempre puedes entrar. Si no llegas, mueres a mitad. Es lo que hace `+1 Money Roll` con su `2.5K Recommended`, y es lo que convierte el letrero en información en vez de en un muro.

### 2.3 Las Wins se bancan en los Win Pedestals

**No hay que construir nada.** El sistema existe desde agosto y su documentación ya lo describe como push-your-luck:

> *«Cada sala limpia pone un pedestal en el pasillo siguiente: pisarlo cobra y reinicia, pasarlo de largo arriesga la vuelta por el pedestal mayor.»*

Lo único que le faltaba era que pasar de largo pudiera salir mal. Ahora puede.

⚠️ **Y aquí hay un cable que hay que soldar o nada funciona.** `WinPedestalService` solo paga si el jugador tiene el atributo `CompletedZone_<ZoneId>` de la vuelta actual, y hoy **eso lo pone **`BlockerService`** al absorber el blocker**. Si los blockers se retiran como puerta, nadie pone ese atributo y **ningún pedestal paga nunca**.

En V3 lo pone `VacuumZoneService` al salir vivo **por el lado lejano** (retroceder no cuenta), y lo **borra entero al morir**. Eso no es un detalle de implementación: **es literalmente el mecanismo de "pierdes las Wins no bancadas"**, o sea lo único que está en juego en todo el modo.

### 2.4 Se construye en el place laboratorio

Ver §0 y `claude/fase0-duplicado-w1v3-2026-09-17.md`.

---

## 3. La economía: dos ecuaciones gobiernan todo el modo

### 3.1 Supervivencia

```
sobrevives la zona n  ⟺  Total  >  D_n × t_cruce
```

- `D_n` = drenaje por segundo de la zona n
- `t_cruce` = profundidad del área ÷ velocidad efectiva

Con el área de **168 studs** de profundidad y la velocidad base de **22,4 st/s**, el cruce limpio son **7,5 s**.

**Y de aquí sale la forma correcta de configurarlo.** No se authorean los dos números —el del letrero y el del drenaje— porque acabarían divergiendo; este proyecto ya tiene documentado que `GameConfig` y el Workspace llevan meses divergiendo en los blockers de World 1. Se authorea **uno** y el otro se deriva **de la geometría real del área** (§1-bis.2):

```
t_cruce = area.Size.Z / min(SpeedCap, v_jugador)
D_n     = RecommendedStickiness_n / (t_cruce × SafetyMargin)
```

Con `SafetyMargin = 1.2`: al entrar con exactamente lo recomendado tienes **un 20 % más de combustible del que necesita el cruce limpio**. Un jugador que va directo sobrevive; uno que se desvía a por un powerup, rebota en una pared o duda, no.

Con los valores de hoy —168 de fondo, tope 22,4— son 7,5 s de cruce y 9 s de combustible. **Pero el 9 no se escribe en ningún sitio: sale de la cuenta.** Si el área se redimensiona, el margen se mantiene solo.

**Ese **`SafetyMargin`** es el dial de dificultad de todo el modo, y es un solo número.**

### 3.2 Push-your-luck

Seguir a la zona siguiente en vez de cobrar es rentable cuando:

```
P(sobrevivir n+1)  >  W_n / W_{n+1}
```

La escalera de Wins que ya existe en World 1 — **1 · 3 · 8 · 15 · 25 · 40 · 65 · 100 · 160 · 250** — da estos umbrales:

| Decisión | Ratio | Necesitas sobrevivir con P \> |
| --- | --- | --- |
| cobrar 1 o ir a por 3 | 3,00× | **33 %** |
| cobrar 3 o ir a por 8 | 2,67× | **37 %** |
| cobrar 8 o ir a por 15 | 1,88× | 53 % |
| cobrar 25 o ir a por 40 | 1,60× | 63 % |
| cobrar 100 o ir a por 160 | 1,60× | 63 % |
| cobrar 160 o ir a por 250 | 1,56× | **64 %** |

**La escalera de Wins ya está bien formada para este modo y no hay que tocarla.** Al principio seguir es obviamente correcto (basta un 33 %) y al final es una decisión de verdad (\~64 %). Eso es exactamente la curva que se quiere: las primeras decisiones enseñan el mecanismo sin castigar, y las últimas son apuestas reales.

> **Regla de diseño que se deriva, y hay que respetarla al balancear los otros dos mundos:** **la recompensa tiene que crecer más rápido de lo que cae la probabilidad de sobrevivir.** Si en Desert dos zonas seguidas pagan 1,2× y la supervivencia cae del 70 % al 45 %, nadie empujará nunca y el modo se convierte en «cobra siempre en la primera».

---

## 4. Balance de World 1

**La escalera de blockers del rebalanceo del 10-sep se reutiliza tal cual como escalera de **`RecommendedStickiness`**.** Un mes de trabajo de balance sobrevive al rework sin tocar un número.

| # | Zona | `Recommended` (letrero) | `D_n` derivado (/s) | Win pedestal |
| --- | --- | --- | --- | --- |
| 1 | Zone1 | **10** | 1,1 | 1 |
| 2 | Zone2 | **100** | 11,1 | 3 |
| 3 | Zone3 | **350** | 38,9 | 8 |
| 4 | Zone4 | **1.000** | 111 | 15 |
| 5 | Zone5 | **3.000** | 333 | 25 |
| 6 | Zone6 | **9.000** | 1.000 | 40 |
| 7 | Zone7 | **30.000** | 3.333 | 65 |
| 8 | Zone8 | **75.000** | 8.333 | 100 |
| 9 | Zone9 | **150.000** | 16.667 | 160 |
| 10 | Zone10 | **330.000** | 36.667 | 250 |

### 4.1 El problema: la escalera de velocidad rompería las zonas tardías

Sin tocar nada, el tiempo de cruce depende de la velocidad del jugador:

```
t_cruce = 168 / v      →  22,4 st/s: 7,50 s      50 st/s: 3,36 s
```

Un jugador al tope cruza en **menos de la mitad** de tiempo, así que sobrevive con la mitad de Stickiness y el letrero de la zona 10 le miente. Y un multiplicador no lo arregla: `50 × 0,55` sigue siendo 2,2× más rápido que `22,4 × 0,55`. **Un multiplicador baja la velocidad de todos por igual; lo que hay que hacer es igualarlos.**

### 4.2 `SpeedCap`: un tope de velocidad dentro del área

**El área aspiradora impone un tope, no un freno proporcional.**

```
v_efectiva = min(v_jugador, SpeedCap_n)
```

**Por defecto **`SpeedCap = 22.4`** en todas las zonas**, o sea la velocidad base. Consecuencias, y son todas buenas:

- **El cruce dura 7,5 s para todo el mundo, siempre.** La aritmética de §3.1 pasa de aproximada a exacta, y el letrero dice la verdad para un jugador de R0 y para uno de R30.
- **Un solo número global**, con override por zona si algún día se quiere que las últimas se sientan más pesadas.
- **Cero física sobre el jugador durante el cruce.** Nada de fuerzas laterales peleando con su input ni volviendo el tiempo de cruce impredecible.

**El coste, y conviene tenerlo escrito:** dentro de las áreas la escalera de velocidad deja de valer. Sigue valiendo en el lobby, que es donde decide el ritmo de farmeo — así que no se muere, se convierte en **una estadística de lobby**. Si más adelante se quiere que la velocidad también sea supervivencia, el camino es subir el `SpeedCap` de las zonas tardías por encima de 22,4 y dejar un tramo de escalera aprovechable.

### 4.3 Reparto de responsabilidades: el área frena, la aspiradora absorbe

**Decisión de Camilo (17-sep).** Las dos piezas hacen una cosa cada una:

| Pieza | Qué hace | Cuándo |
| --- | --- | --- |
| `VacuumZone` (el volumen) | Drena la Stickiness **y** aplica el `SpeedCap` | Todo el tiempo que estés dentro |
| `VacuumProp` (la aspiradora) | **Solo** te atrae hacia ella | Únicamente al llegar a `Actual ≤ 1` |

Por qué está bien así:

- **Los tres números que deciden si sobrevives viven en la misma instancia**: profundidad del área, `RecommendedStickiness` y `SpeedCap`. No hay que cruzar dos objetos para balancear un cruce.
- **Los 20 props se quedan sin datos de balance.** Solo necesitan saber a qué zona pertenecen. Son decoración con una función, y esa función solo se dispara una vez.
- **La física solo entra en juego en la muerte** (§6.3), que es el único momento en que el servidor toma la autoridad del personaje. Durante el juego normal no hay fuerzas en absoluto.

⚠️ **Lo que se pierde, y hay que compensarlo en presentación:** la fuerza lateral era lo que hacía que el área *se sintiera* una aspiradora y no un campo de lentitud. Sin ella, el área es «voy más despacio y mi número baja», que se lee como un debuff genérico. La compensación no es física, es VFX — ver §6.4.1.

### 4.4 El grifo de Wins: repetir la corrida es intencionado

**Decisión de diseño (Camilo, 17-sep): una vez sobrevives la zona 10, puedes repetirla cuantas veces quieras hasta que renazcas.** No es un agujero que tapar; es el carril de farmeo de Wins del mundo.

```
corrida completa ≈ 10 zonas × 7,5 s + 10 pasillos × ~4 s ≈ 115 s
250 Wins / 2 min ≈ 125 Wins/min ≈ 7.500 Wins/hora
```

**Lo que lo acota son dos cosas, y las dos ya existen:**

1. **El tiempo de la corrida.** El pedestal devuelve al inicio, así que cada cobro cuesta recorrer el mundo entero otra vez.
2. **El Rebirth.** Es lo único que pone la Stickiness a cero, así que renacer **te cierra el acceso a las zonas profundas** hasta volver a farmear el total. El jugador elige entre seguir ordeñando la zona 10 o renacer y perder el acceso a cambio del multiplicador. **Esa es una decisión de economía de verdad, y sale gratis del diseño.**

**Lo que sí hay que hacer:** con 7.500 Wins/hora como referencia, **revisar los precios de Desert y Lava**, que hoy están calibrados contra un grifo completamente distinto. Para comparar, la escalera de wraps entera de World 1 cuesta 1.205 Wins — diez minutos de corridas.

Si al modelarlo el ritmo sale demasiado alto para los mundos 2 y 3, los diales por orden de preferencia son:

1. Bajar el `SpeedCap` (corridas más largas, y además más tensas)
2. Alargar los pasillos entre zonas
3. Subir los precios de Desert y Lava
4. Tocar la escalera de Wins — **el último recurso**, porque §3.2 demuestra que su forma ya es correcta

### 4.5 Trails y auras: el tope les quita la mitad de su función

⚠️ **Decisión pendiente, y hay que tomarla antes de la Fase 4.**

Hoy un trail hace tres cosas: suma a `TrailAddition` (multiplicador de Stickiness), da hasta **+90 % de WalkSpeed**, y sube el `PickupRadius`. El aura hace lo equivalente con `AuraMultiplier` y **+80 %**. De hecho `MaximumWithBonuses = Maximum × 2.70` existe justo por esos dos bonus.

**Con **`SpeedCap = 22.4`**, el bonus de velocidad de los dos vale exactamente cero dentro de un área.** Y las áreas pasan a ser el juego. Un jugador que se gastó Wins en el trail tier 15 no nota nada en la parte nueva.

Es la misma clase de error que el proyecto ya cometió tres veces con las unidades absolutas, pero al revés: **la recompensa no se queda pequeña porque la economía creció, se queda inútil porque quitamos el sitio donde importaba.**

#### Lo que sobrevive intacto, y es más de lo que parece

|  | Sigue funcionando |
| --- | --- |
| `TrailAddition`** / **`AuraMultiplier` | Suben el multiplicador → farmeas más rápido en el lobby → Total más alto → zonas más profundas. **Ayudan, pero indirectamente** |
| `PickupRadius` | Los powerups son pickups: más radio = **agarrarlos sin desviarte tanto**. Beneficio directo dentro del área, y **no hay que tocar nada** |

#### Por qué NO devolverles la velocidad, ni por encima del tope

La razón no es de balance, es de **diseño de nivel**. Si las velocidades varían, **el coste del desvío es distinto para cada jugador**, y toda la §5.1 —*«la línea rápida es segura y pobre, el desvío es rico y caro»*— depende de que el desvío cueste lo mismo para todos. Con un trail al +90 %, el desvío es casi gratis y la zona deja de tener decisión.

#### La palanca que sí encaja: dos ejes distintos, no uno compartido

**El argumento más fuerte para separarlos es que evita que se compongan.** Si trail y aura dieran los dos resistencia, un jugador con los dos tier 15 los multiplicaría y atravesaría cualquier techo que se le pusiera — que es exactamente el problema que la cadena `Maximum → MaximumWithBonuses → MaximumWithGamePass → MaximumWithEvent` existe para contener en la velocidad. **Con dos ejes distintos, cada uno tiene su propio techo y nunca se suman.**

|  | Fantasía | Eje | Fórmula |
| --- | --- | --- | --- |
| **Trail** | *resisto la succión* | Tiempo | `D_efectivo = D_n × (1 − Resistance)` |
| **Aura** | *me recompongo* | Recuperación | `heal = BonusObjects × ganancia × (1 + Recovery)` |

**Y los dos verbos ya están en su arquitectura**: el trail **suma** (`TrailAddition`), el aura **multiplica** (`AuraMultiplier`). No hay que reinventar nada, solo extender el mismo gesto a la zona.

#### ⚠️ La resistencia necesita techo, igual que la velocidad

Esto es lo que faltaba y es lo que rompería el modo:

```
Resistance = 0,40  →  t_supervivencia × 1,67   (palanca real)
Resistance = 0,90  →  t_supervivencia × 10     (la zona 10 es gratis)
```

**La resistencia entra directamente en el denominador de la ecuación de supervivencia**, así que crece de forma no lineal: los últimos puntos valen muchísimo más que los primeros. Un `+90 %` como el que hoy da el trail en velocidad **haría el modo trivial**.

Estructura correcta, y es la que el proyecto ya usa para la velocidad:

```
Resistance = {
    Maximum = 0.40,          -- [PLACEHOLDER] hasta cronometrar la Fase 4
    -- los 15 tiers interpolan hasta ahí; el tier 15 toca el techo y no lo pasa
}
```

**La pendiente se calcula, no se elige** — misma regla que la escalera de velocidad del 16-sep: el tier 15 tiene que llegar al techo **justo ahí y no antes**, o los tiers altos se venden recortados.

#### La propiedad bonita del aura, que sale gratis

El powerup cura hacia el Total y **clampa en el Total** (§6.5). Eso significa que el bonus de recuperación **solo vale cuando estás lejos del Total**, o sea cuando estás en peligro.

**El aura vale más cuanto más profundo vas.** Es progresión que se siente sin que nadie la explique, y no hay que programarla: sale del clamp que ya está en el diseño.

#### Los VFX existentes NO se rehacen, y la razón está en su propio documento

`claude/vfx-auras-trails-2026-09-14.md` fija dos reglas de composición, y la segunda es:

> *«El aura describe al personaje; la estela describe su movimiento.»*

**Esa regla encaja con el reparto nuevo por accidente feliz:**

- La **estela** existe porque te mueves. El vacío se opone a tu movimiento. **Que la estela sea lo que resiste es coherente con lo que ya es.**
- El **aura** te describe a ti. **Que sea lo que te recompone es coherente con lo que ya es.**

Así que la escalera de identidad visual de 15 tiers —green, blue, purple, gold, ruby, cyan, amethyst, flame, frost, toxic, plasma, void, cosmic, galaxy, eternal— **se queda tal cual**, con sus budgets de relleno y su LOD. **Cero trabajo de arte nuevo para la identidad.**

#### Lo que sí es VFX nuevo: dos momentos de feedback

No identidad, sino **momentos**. Sin ellos el jugador tiene la mecánica y no la nota:

| Momento | Qué comunica | Cómo, barato |
| --- | --- | --- |
| **La resistencia está funcionando** | «mi estela está aguantando» | Las piezas recortadas vuelan **menos y más lento** hacia el prop (§6.4.1). Sale gratis: el ritmo del descarte ya es proporcional al drenaje |
| **El powerup cura de más** | «mi aura me recompuso» | Un estallido mayor en la recogida, y el recorte visual **revirtiendo** unas cuantas piezas de golpe |

#### Dos notas de implementación

El letrero calcula `Recommended` con **resistencia 0**, así que a un jugador equipado le sobra margen. Eso está bien: **el letrero miente en la dirección segura**, nunca al revés.

Y la cadena de techos de velocidad (`MaximumWithBonuses = 135`) **no se toca**: fuera de las áreas los bonus de velocidad siguen aplicando igual. El tope solo existe dentro.

---

## 5. Diseño de nivel: qué convierte una zona en un nivel y no en un cronómetro

Un pasillo recto de 168 studs con un drenaje es **un temporizador con gráficos**. Tres cosas lo convierten en un nivel, y las tres son baratas.

### 5.1 La regla que ordena el espacio

> **La línea rápida es segura y pobre. El desvío es rico y caro.**

El centro del área es la ruta directa: cruzas en 7,5 s y no ganas nada extra. Los **powerups van colocados hacia las paredes**, o sea hacia las aspiradoras. Ir a por uno cuesta segundos de combustible y te acerca a la succión; te devuelve Stickiness. **Esa es la decisión de la zona**, y se toma en el segundo 2 de cada cruce.

### 5.2 Legibilidad desde la entrada

Al pisar el área el jugador tiene que ver, **en menos de 2 segundos**:

1. **La salida**, al fondo y contrastada.
2. **Los powerups**, brillando, claramente fuera de la línea directa.
3. **Las aspiradoras**, a ambos lados, en movimiento.

Si algo de eso no se lee en el greybox, el arte no lo va a arreglar. Esa es la regla de este oficio y el proyecto ya la tiene escrita como *«si no es legible en grey box, el arte no lo arregla»*.

### 5.3 Bolsas seguras

Una o dos zonas dentro del área donde el drenaje baja o se anula — la sombra de un pilar, una plataforma elevada. Dan:

- un respiro a mitad del cruce (**ritmo**: tensión → alivio → tensión)
- una lectura táctica que premia mirar antes de correr
- un sitio donde decidir si seguir al powerup o cortar hacia la salida

Se implementan como un atributo `DrainMultiplier` en una parte hija del área, no como sistema aparte.

### 5.4 El ritmo de una corrida completa

| Tramo | Duración | Tensión | Qué pasa |
| --- | --- | --- | --- |
| Lobby | variable | ninguna | Farmeo. El número sube. Cero peligro |
| Entrada de zona | 2 s | media | Lees el letrero y la ruta |
| Cruce | 5–8 s | **alta** | La barra baja. Decides desvío o recto |
| Pasillo | 4 s | ninguna | Cura total. Pedestal, cintas. **Cobrar o seguir** |
| … ×10, escalando |  |  |  |
| Muerte o Finish |  | pico |  |

Diez ciclos de tensión-alivio en dos minutos. **Eso es lo que hoy no existe** — hoy son 36 minutos de meseta.

### 5.5 El lobby también es diseño de nivel, y es nuevo

Pasa de vestíbulo a **la mina**. Dos requisitos:

- **Tamaño y densidad suficientes** para sostener el ritmo actual (1,43–1,64 obj/s). Como mínimo el área de una zona (96 × 38 × 168); recomendado **1,5–2×**, con el número de objetos escalado en proporción. `ItemPlacementService` ya avisa solo cuando el área no da los slots pedidos — **ese aviso es el criterio, no la intuición.**
- **Gradiente visible de requisito.** Los objetos baratos cerca del spawn, los caros al fondo. Así el jugador *ve* su progresión sin leer nada: cada Rebirth le abre físicamente más lobby. Es gratis: el sistema de `RequiredStickiness` por objeto ya existe.

⚠️ **Y una comprobación que bloquea el arranque:** tiene que haber suficientes objetos elegibles a **Stickiness 0** o un jugador nuevo no puede empezar. Hoy eso lo garantizaba la primera sala.

---

## 6. Arquitectura técnica

### 6.1 Servicios nuevos

| Módulo | Dónde | Responsabilidad |
| --- | --- | --- |
| `VacuumZoneService` | `ServerScriptService/Server` | Autoridad: ocupación, drenaje, muerte, cura |
| `VacuumZoneController` | `StarterPlayerScripts/Client` | Presentación: reducción visual de assets, VFX, efectos de pantalla, succión |
| `ZonePowerupService` | `ServerScriptService/Server` | Powerups por jugador dentro de las áreas |
| `ZoneSignController` | `StarterPlayerScripts/Client` | Pinta los letreros authored |

### 6.2 `VacuumZoneService` — la pieza central

**Ocupación: sin consultas de física.** Con ≤10 áreas y ≤12 jugadores son 120 pruebas de punto-en-caja por tick. Es más barato, más determinista y **usa la posición que el servidor ya tiene** —nunca una que reporte el cliente—, que es el mismo principio que ya usa `PickupService` para validar pickups.

```ruby
local function isInside(position: Vector3, areaCFrame: CFrame, areaSize: Vector3): boolean
    local p = areaCFrame:PointToObjectSpace(position)
    return math.abs(p.X) <= areaSize.X * 0.5
       and math.abs(p.Y) <= areaSize.Y * 0.5
       and math.abs(p.Z) <= areaSize.Z * 0.5
end
```

**El tick reutiliza el patrón de **`PassiveStickinessService`: delta real transcurrido, autocorregido ante un frame lento, con `MaximumTickDeltaSeconds` por encima de `TickSeconds`.

**Máquina de estados por jugador:**

```
        FUERA  (Actual = Total, siempre)
          │  entra en la PRIMERA área
          ▼
       DENTRO ──────────────► Actual -= D × dt × DrainMultiplier
          │                   Actual += powerup  (clamp al Total)
          │                                    │
          │ sale de la ÚLTIMA área              │ Actual ≤ DeathThreshold
          ▼                                    ▼
      CURA TOTAL                            MURIENDO
      (Actual = Total)                 (control off, succión, caída)
      + CompletedZone_<id> si salió           │
        por el lado lejano                    │
          │                                   │
          └──────────────► FUERA ◄────────────┘
                     Actual = Total
                     + limpia los CompletedZone_* (pierde las Wins no bancadas)
```

**Curar es poner **`Actual = Total`**.** No hay snapshot que guardar ni que restaurar: el total ya está en el perfil y nunca lo tocó nadie. Con áreas solapadas, un contador de áreas ocupadas evita curar a mitad de camino — se cura al salir de la **última**, no de la primera.

> **La propiedad que hace robusto todo el sistema:** el **Total** vive en el perfil y solo lo mueven el lobby y el Rebirth. El **Actual** es un número en memoria que se replica para que lo pinte el HUD. Si se pierde —desconexión, caída del servidor, bug del servicio— **no se pierde nada**, porque al volver `Actual = Total` otra vez.

### 6.2.1 El `SpeedCap` va por el pipeline de perks, no por escritura directa

⚠️ **Trampa documentada en este proyecto.** `PerkService.computePerk` suma `+ permanent` **después** de `ApplyPerkBonus`, o sea fuera de `Maximum`, `MaximumWithBonuses`, `MaximumWithGamePass` y `MaximumWithEvent`.

Si `VacuumZoneService` escribe `Humanoid.WalkSpeed` a mano, **el siguiente recálculo de perks lo pisa**: subir de nivel, equipar un cosmético o el bono diario del daily devuelven al jugador a velocidad completa **a mitad del cruce**. Y eso no da error: da un jugador que de repente sobrevive una zona que no debería.

**El tope se aplica como última etapa del pipeline de perks**, leyendo un atributo replicado que pone el servicio:

```bash
-- VacuumZoneService, al entrar / salir del área
player:SetAttribute("VacuumSpeedCap", areaSpeedCap)   -- nil al salir

-- PerkService.computePerk, como ÚLTIMA operación
local cap = player:GetAttribute("VacuumSpeedCap")
if cap then walkSpeed = math.min(walkSpeed, cap) end
```

Así cualquier recálculo conserva el tope, y salir del área es borrar el atributo.

### 6.3 La muerte — el único momento en que actúa la aspiradora

1. El servidor detecta `Actual <= DeathThreshold` (1).
2. **Quita la autoridad de física al cliente**: `hrp:SetNetworkOwner(nil)`. Sin esto el cliente simula su propio personaje y la succión se ve distinta para cada uno.
3. `Humanoid.PlatformStand = true` y se aplica un `VectorForce` / `AlignPosition` hacia **el **`VacuumProp`** más cercano**. Es la **única** vez que un prop hace algo (§4.3).
4. El jugador cae fuera del mapa. **Los **`FailVolume`** ya existen** (`FailVolumeId`, agua a Y = −5, volumen a Y = −3): no hay que construir la caída, ya está.
5. Al tocar el FailVolume: limpiar los `CompletedZone_*`, `Actual = Total`, devolver el control y teletransportar al spawn del lobby con `FinishService.ReturnToStart`, que ya centraliza eso para el pedestal, el ReplayPad y el Rebirth.

### 6.4 La reducción visual de assets — **no destruir nada**

`AttachmentService` mantiene hasta 300 records lógicos y el cliente renderiza 110 propios y 20 por remoto. **Los records lógicos no se tocan.** Solo cambia cuántos se dibujan:

```ruby
-- Servidor: un solo atributo replicado
player:SetAttribute("VacuumVisibleRatio", actualStickiness / totalStickiness)

-- Cliente: AttachmentRenderer recorta al presupuesto
function AttachmentRenderer.SetVisibleRatio(ratio: number)
    local target = math.floor(ownBudget * math.clamp(ratio, 0, 1))
    -- oculta o devuelve al pool los que sobran; NO llama a Destroy
end
```

Si se destruyen, curar obliga a reenviar hasta 300 records y el jugador ve la bola reconstruirse a trompicones. Además el proyecto ya tiene documentado que vaciar la pila de golpe cuesta **10,6 ms de Lua** en escritorio y del orden de 50–100 ms en móvil — **eso, cada vez que alguien entra o sale de una zona, es inaceptable**. El recorte tiene que ser gradual y por pool.

#### 6.4.1 Y aquí se recupera la sensación de aspiradora, sin física

Al quitar la fuerza lateral (§4.3), el área se quedaría leyéndose como un campo de lentitud. **La compensación es que las piezas recortadas vuelen hacia el **`VacuumProp`** más cercano** en vez de desvanecerse en el sitio.

Con eso, el prop es **visiblemente la causa** de lo que le está pasando al jugador, y no hace falta tocarle el personaje: la succión se cuenta con los objetos, no con el input.

**Y la máquina ya existe.** `AttachmentRenderer` tiene la animación de descarte —la pieza expulsada se encoge y se desvanece en `Workspace.StickyDiscards`, movida por un `Heartbeat` compartido y desacoplada de la vida del personaje. Es cambiar el destino de esa animación: en vez de encogerse donde está, viaja hacia el prop. **Cero instancias nuevas, cero física, y el efecto escala solo con el ritmo del drenaje.**

### 6.5 `ZonePowerupService`

- **Por jugador**, como los collectibles: si fueran compartidos, el primero en llegar se los lleva todos y en un servidor lleno el área queda vacía. Reutilizar el patrón de sesión por (jugador, zona) de `RoomItemService`.
- **Validación autoritativa**: distancia contra la posición del servidor, personaje vivo, rate limit por token bucket. Es exactamente lo que ya hace `PickupService`; se copia el contrato.
- **El powerup CURA, no sube el máximo.** Es una poción: acerca el Actual al Total y **nunca lo pasa**. No toca el perfil, no toca el Total, y al salir del área da igual porque se cura entero de todos modos. Su valor está en **terminar el cruce**, no en hacerte más fuerte.

```
-- El bono se denomina en objetos equivalentes, nunca en Stickiness absoluta
local heal = powerup.BonusObjects * GameConfig.GetStickinessGain(player)
state.Actual = math.min(state.Actual + heal, state.Total)   -- ← el clamp es la mecánica
```

> Este proyecto ya ha cometido el error de las unidades absolutas **tres veces**: los charms a 4.000 Wins, los días 1–2 del daily, y los Playtime Rewards (`+225` contra un glue de `+2.055.000.000`). No hace falta una cuarta.

### 6.6 Contratos authored

Regla 12: se crea en el editor, el código lo localiza y lo valida. Si falta, **avisa y sigue** — nunca lo genera.

**Área aspiradora** — tag `VacuumZone`, BasePart invisible, `96 × 38 × 168`:

| Atributo | Tipo | Nota |
| --- | --- | --- |
| `ZoneId` | string | Los de siempre — el laboratorio es un place aparte, no hay con qué colisionar |
| `WorldId` | string | `World1` |
| `RecommendedStickiness` | number | **La cifra del letrero.** El drenaje se deriva de ella |
| `SpeedCap` | number | Tope de velocidad dentro. **Default 22.4** (§4.2). `0` o ausente = sin tope |
| `Order` | number | Para el letrero y el orden de la corrida |

**Todo lo que decide si el jugador sobrevive está en esta instancia y en ninguna otra** (§4.3).

**Bolsa segura** — parte hija del área, tag `VacuumSafePocket`, con `DrainMultiplier` (0 = refugio total).

**Aspiradora** — tag `VacuumProp`, `11 × 38 × 160`, **con **`ZoneId`** y nada más**. Es el destino de la succión de muerte (§6.3) y el destino de las piezas recortadas (§6.4.1), más el ancla de sus VFX. **Sin colisión** con el jugador y **sin ningún dato de balance**: es decorado con una función, y esa función solo se dispara una vez por corrida.

**Letrero** — authored en la entrada de cada zona, con `Title` y `Subtitle`:

```
              ZONE 4
         1,000 RECOMMENDED
```

⚠️ **El texto de un **`BillboardGui`** se mide una sola vez y se puede quedar en **`TextBounds = 0,0`, pintando el fondo sin los dígitos. Está documentado y hay arreglo: `ObjectLabelController.healLabel` reactiva `TextScaled` por tick sobre las etiquetas con tamaño pero medida cero. **Los letreros nuevos tienen que pasar por ese mismo camino**, o saldrán mudos exactamente como salió el cartel del pedestal.

### 6.7 El goteo pasivo se apaga dentro de las áreas

`PassiveStickinessService` concede 0,15 obj/s por la misma puerta que un pickup, o sea que **subiría el Total mientras el jugador está dentro de un área**. Dos motivos para apagarlo ahí:

- Rompe el modelo: el Total solo debe moverse en el lobby y con el Rebirth.
- Ensucia la matemática de `SurvivalSeconds`. A R0 son 0,15 obj/s contra un drenaje de 1,1 en la zona 1: **el 13 %**.

Es una guarda en `tickAll`, y **se junta con un pendiente que ya estaba escrito** — la puerta de Rest Zone de `claude/balance-goteo-pasivo-2026-09-16.md` §4.2. Los dos son el mismo cambio: *«no pagues el goteo a quien está en un sitio que ya tiene su propio canal».*

### 6.8 `GameConfig.VacuumZones`

```
VacuumZones = {
    Enabled = true,                 -- flag maestro de rollback (§0.4)

    TickSeconds = 0.25,             -- resolución del drenaje
    MaximumTickDeltaSeconds = 3,    -- SIEMPRE > TickSeconds
    SafetyMargin = 1.2,             -- margen sobre el cruce limpio.  EL DIAL DE DIFICULTAD
                                    -- D_n = Recommended_n / (area.Size.Z / SpeedCap × esto)
                                    -- ⚠️ se deriva de la geometría real, nunca de un 168 hardcodeado
    DeathThreshold = 1,

    DefaultSpeedCap = 22.4,         -- = LevelPerks.WalkSpeed.Base. El área lo puede sobreescribir
                                    -- ⚠️ se aplica por PerkService, no escribiendo WalkSpeed (§6.2.1)

    Death = {                       -- lo ÚNICO que hace un VacuumProp (§4.3)
        SuckSeconds = 1.2,
        PullAcceleration = 180,
        ReturnDelaySeconds = 0.6,
    },

    Visuals = {
        MinimumVisibleRatio = 0.0,
        WarnRatio = 0.35,           -- a partir de aquí, viñeta y aviso
        RatioLerpSeconds = 0.25,    -- que el recorte no sea un salto
        DiscardTowardProp = true,   -- las piezas recortadas vuelan al prop (§6.4.1)
    },

    Powerups = {
        RespawnSeconds = 12,
        MaximumPerArea = 4,
        Kinds = {
            BonusStickiness = { BonusObjects = 50 },   -- objetos equivalentes, §6.5
        },
    },
}
```

---

## 7. Casos borde — aquí es donde se rompe

Cada uno necesita una prueba explícita. Son los que este tipo de sistema falla siempre.

| Caso | Comportamiento correcto |
| --- | --- |
| Se desconecta dentro de un área | El **Actual** se descarta. **El perfil solo tenía el Total y nadie lo tocó.** Al volver, `Actual = Total` |
| **Sube de nivel, equipa un cosmético o cobra el bono diario dentro de un área** | El `SpeedCap` **se conserva**. Es el fallo de §6.2.1 y hay que probarlo explícitamente |
| Sale del área con el `VacuumSpeedCap` puesto | El atributo se borra y el perk recalcula a velocidad completa |
| El servidor cae dentro de un área | Igual. `BindToClose` no tiene que guardar nada del área |
| Muere y el personaje respawnea dentro del área | El spawn del lobby está fuera. Verificar que `ReturnToStart` no lo deja dentro |
| Dos áreas solapadas / pasa de zona a zona sin pisar pasillo | Contador de áreas ocupadas. Se cura al salir de la **última**, no de la primera |
| Sale del área **retrocediendo** | Se cura, pero **no** se marca `CompletedZone_<id>`. Retroceder no cuenta como cruzar |
| Renace (Rebirth) dentro de un área | El Rebirth pone el **Total** a 0 → muerte inmediata. **Bloquear el Rebirth dentro de un área** o forzar salida antes |
| Viaja de mundo dentro de un área | Salida forzada y cura antes del teleport |
| Recoge un powerup con el Actual ya en 0 | La muerte ya se disparó; el powerup se ignora. La muerte no se cancela a mitad |
| El powerup curaría por encima del Total | **Clamp al Total.** Nunca sube el máximo — y ese clamp es lo que hace que el aura valga más cuanto más peligro hay (§4.5) |
| Trail tier 15 + aura tier 15 a la vez | **No se componen**: ejes distintos, techos distintos (§4.5). Verificar que ninguno de los dos pasa de su `Maximum` |
| Entra con el Total a 0 (recién renacido) | Muere en el primer tick. Correcto, y el letrero ya se lo había dicho |
| El goteo pasivo tickea dentro del área | No debe (§6.7). Si tickea, sube el Total y rompe el modelo |
| Dos jugadores en la misma área | Estado y powerups por jugador. Ninguno ve ni toca lo del otro |
| Un jugador de **V2** entra en un área de V3 | No debería poder llegar. Verificar que los portales y spawns respetan el bucket (§0.3) |
| El cliente miente sobre su posición | No importa: la ocupación se calcula con la posición del servidor |

---

## 8. Instrumentación — sin esto no se puede balancear ni leer el A/B

Un modo de apuesta se afina con la distribución de resultados, no con la intuición. **Todos los eventos llevan el **`ExperimentBucket`** como CustomField** (§0.3) o el A/B no se puede segmentar.

| Evento | Campos | Para qué |
| --- | --- | --- |
| `ZoneEntered` | `zoneId`, `stickinessRatio` (total ÷ recomendado), `trailId`**, **`auraId` | **La curva de supervivencia.** Es el dato central — y con trail/aura se puede medir si la resistencia de §4.5 hace algo |
| `ZoneCleared` | `zoneId`, `secondsInside`, `remainingRatio` | Cuánto margen sobró de verdad |
| `ZoneDeath` | `zoneId`, `secondsInside`, `stickinessRatio`, `unbankedWins` | Dónde y con cuánto mueren |
| `WinsBanked` | `zoneId`, `amount`, `deepestZone` | **La decisión de push-your-luck, medida** |
| `PowerupCollected` | `zoneId`, `kind` | Si el desvío se usa o el diseño de §5.1 no funciona |

**Lo primero que hay que graficar:** supervivencia frente a `stickinessRatio`. Si al ratio 1,0 (exactamente lo recomendado) la supervivencia no está entre el 60 % y el 70 %, `SafetyMargin` está mal y es **un solo número** el que hay que mover.

**Y lo segundo, que es el A/B:** D1, duración de sesión y funnel `Onboarding`, partidos por bucket.

---

## 9. Qué se retira y qué se queda

⚠️ **Nada de esto toca producción hasta el port-back.** Y ojo: **las retiradas son la mitad que se olvida al portar** — ver el «montón C» de `claude/fase0-duplicado-w1v3-2026-09-17.md` §4.1.

| Sistema | En el modo nuevo |
| --- | --- |
| `ItemPlacementService` · `RoomItemService` · `CollectibleController` | **Se quedan**, sirviendo **solo al lobby**. Las 10 zonas no llevan `PlacementArea` |
| `PlacementArea` de las zonas | **Se borra.** Una sola, en el lobby |
| `BlockerService` / los blockers | **Se les retira el tag y los atributos.** El área aspiradora es la dificultad. Los arcos se quedan de decorado |
| `WinPedestalService` | **Se queda sin tocar.** Es la banca. Solo cambia quién pone `CompletedZone_*` (§2.3) |
| Rest Zones y cintas de los pasillos | **Se quedan.** Ahora son el refugio entre cruces, que es mejor papel del que tenían |
| `AttachmentService` | Se queda. Se le añade el recorte visual de §6.4 |
| Wraps, Rebirth, niveles, perks, charms, trails, auras | **Se quedan.** Son la progresión del lobby, y ahora la velocidad además es supervivencia |
| `FinishService.ReturnToStart` | Se queda. Lo reutiliza la muerte |
| `FailVolume` | Se queda. Es el suelo de la muerte y ya está construido |

---

## 10. Fases y orden de prioridad

Cada fase se juega antes de empezar la siguiente. Nada de arte hasta que el greybox se sostenga.

### El orden, y por qué es este

**La Fase 0 no es gameplay y bloquea literalmente todo** (§0.1: sin el `Scope` del DataStore, probar corrompe perfiles reales). Son horas, no días.

Después, el orden lo fija una sola idea: **una zona jugable de punta a punta antes que diez a medias.** La Fase 1 es el cuello de botella del proyecto —el servicio con la ocupación, el drenaje, la muerte y la cura— y de ella dependen todas las demás. Conviene empezarla el primer día y no repartirla.

La Fase 2 va **antes** de la 4 a propósito: si el jugador no entiende que está perdiendo algo *sin leer nada*, tener diez zonas solo multiplica la confusión por diez.

### Lo que puede ir en paralelo desde el minuto cero

Sin esperar a que exista una sola línea del servicio:

- **Congelar producción** y acordarlo por escrito (§0.3)
- **El lobby como mina** — Fase 3 es casi independiente: `PlacementArea`, `Geometry/Floor` y el gradiente de requisito
- **La decisión de trails y auras** (§4.5), que es diseño puro y bloquea su implementación
- **Los VFX de las aspiradoras** (§4.3)

### Lo que no se recorta si hay que recortar alcance

|  | Por qué |
| --- | --- |
| **El **`Scope`** del DataStore** (§0.1) | Sin él, probar corrompe perfiles reales de jugadores |
| **Apagar la analítica del laboratorio** (§0.2) | Sin él, se ensucia el funnel que hay que leer el día 20 |
| `CompletedZone_*`** al cruzar** (§2.3) | **Sin él ningún pedestal paga nunca** y no hay juego |
| **El **`SpeedCap`** por el pipeline de perks** (§6.2.1) | Sin él, un level-up a mitad de cruce rompe el balance en silencio |
| **El montón C del port-back** (`fase0` §4.1) | Sin él, producción queda en un estado que no existe en ningún place |

Lo primero que se cae, en este orden: las bolsas seguras (§5.3), la segunda clase de powerup, y el pulido de VFX.

| # | Fase | Contenido | Criterio para pasar |
| --- | --- | --- | --- |
| **0** | **Aislar el laboratorio** — detalle en `claude/fase0-duplicado-w1v3-2026-09-17.md` | `Scope` del DataStore, analítica apagada, producción congelada, censo base | Los tres puntos de §0 cerrados **antes** de la primera sesión de Play |
| **1** | Vertical slice de **una** zona | `VacuumZoneService` + drenaje + muerte + cura, en la zona 1 con `Recommended = 10` | Entras, la barra baja, mueres, vuelves con tu Total intacto. 20 ciclos sin fugas |
| **2** | Lectura visual | Recorte de assets, VFX, viñeta de aviso, succión de muerte | Un jugador nuevo entiende que está perdiendo algo **sin leer nada** |
| **3** | El lobby como mina | `PlacementArea` única, gradiente de requisito, objetos escalados | Se sostiene 1,43+ obj/s y hay objetos elegibles a Stickiness 0 |
| **4** | Las 10 zonas | Letreros, la escalera de §4, pedestales reconectados con `CompletedZone_*`. **Decidida la palanca de trails y auras (§4.5)** | Corrida completa cronometrada; el modelo dice \~115 s |
| **5** | Powerups y bolsas seguras | `ZonePowerupService`, `DrainMultiplier` | El desvío se usa. Si nadie se desvía, §5.1 falló |
| **6** | Instrumentación | Los 5 eventos de §8 | Se puede graficar supervivencia vs `stickinessRatio` |
| **7** | **Port-back a producción** | Los tres montones: código, instancias nuevas y **las borradas** | Checklist de `fase0-duplicado-w1v3` §7 completo, barrido de `CanTouch` vacío |

---

## 11. Riesgos

| # | Riesgo | Mitigación |
| --- | --- | --- |
| 1 | **El **`Scope`** del DataStore.** Olvidarlo hoy corrompe perfiles reales; portarlo al final vacía el perfil de todo el mundo | §0.1. Es el primer punto de la fase 0 y el último del port-back |
| 2 | **El port-back olvida las retiradas** y producción queda en un estado híbrido que no existe en ningún place | El «montón C» de `fase0-duplicado-w1v3` §4.1, sacado de un diff real y no de memoria |
| 3 | **El grifo de Wins descoloca los precios de Desert y Lava** | Modelarlo en la fase 4 con la corrida cronometrada de verdad. Diales en §4.3 |
| 4 | **El recorte de assets provoca tirones en móvil** | Nunca destruir; recortar por pool y con lerp. Es el hitch de 10,6 ms ya documentado |
| 5 | Un jugador nuevo no entiende por qué muere | Fase 2 antes que la 4. El letrero + la viñeta + los assets cayéndose tienen que bastar sin texto |
| 6 | **El **`SpeedCap`** se pierde a mitad del cruce** porque un recálculo de perks lo pisa | §6.2.1: se aplica como última etapa de `PerkService`, nunca escribiendo `WalkSpeed`. Probar subiendo de nivel **dentro** de un área |
| 7 | Nadie se desvía a por los powerups | Es un fallo de §5.1, no de balance. Se arregla acercando el powerup a la ruta o subiendo el bono |
| 8 | **Morir no cuesta nada y la tensión se evapora** | Lo único en juego son las Wins no bancadas: **vigilar **`WinsBanked`** — si todo el mundo cobra en la primera, el push-your-luck no está funcionando** |
| 9 | **La analítica del laboratorio ensucia el funnel de producción** justo cuando hay que leer el sprint D1 | §0.2: apagarla en el laboratorio antes de la primera corrida de prueba |
| 10 | **Deriva entre los dos places** durante el desarrollo | §0.3: congelar producción |
| 11 | **Trails y auras se quedan sin función dentro de las áreas** y el jugador siente que su compra no sirve | §4.5. Decidir la palanca **antes** de la Fase 4, y medirla con `trailId`/`auraId` en `ZoneEntered` |

---

## 12. Lo que este rework arregla, dicho con los datos que ya tenemos

El funnel dice que **el 73,11 % de los jugadores nuevos completa el onboarding y vuelve el 3,7 %**. El diagnóstico escrito el 15 de septiembre fue:

> *«La primera sesión funciona. El retorno no existe. El bucle cierra limpio cada dos minutos y no tiene nunca un cliffhanger.»*

Este rework es la respuesta directa a esa frase: **mete un resultado incierto cada siete segundos y una decisión de cobrar-o-seguir cada dos minutos.** Y no inventa sistemas — reutiliza los pedestales, los pasillos, las cintas, los FailVolumes, la escalera de blockers y la escalera de Wins, todos ya construidos y ya balanceados.

**Lo que cambia no es cuánto contenido hay. Es que por primera vez el jugador no sabe cómo va a acabar.**

Y como se construye en un laboratorio aparte, **se puede equivocar sin coste.** Producción sigue midiendo el sprint del 15; el modo nuevo se juega, se cronometra y se afina sin un solo jugador real en riesgo. Lo único que hay que hacer bien de verdad es el port-back.
