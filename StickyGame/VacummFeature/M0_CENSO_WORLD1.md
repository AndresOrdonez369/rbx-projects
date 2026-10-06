# M0 — El antes de World 1

**Fase M0 del plan.** Base contra la que se compara M1 (retirar el requisito de recogida).
**Estado:** censo hecho y verificado contra el place. **La corrida cronometrada sigue pendiente** — ver §5.

---

## 1. Por qué el censo va antes que el cronómetro

El plan decía «corrida cronometrada de las 10 salas, censo de duración por sala». Empezar por el censo en vez de por el cronómetro resultó ser lo correcto, porque destapó **tres cosas que habrían hecho que el cronómetro midiera contra un número equivocado**.

---

## 2. El censo

| # | Sala | Objetos `GameConfig` | Objetos **Workspace** | Sep. cfg | Sep. **ws** | Pool authored | Entrada | Blocker | Requisitos |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | ToyRoom | 32 | 32 | 8 | 8 | 4 | 0 | 10 | 0 / 3 / 5 / 10 |
| 2 | Bedroom | 32 | 32 | 8 | 8 | 4 | 10 | 100 | 10 / 30 / 60 / 80 |
| 3 | Kitchen | 32 | 32 | 8 | 8 | 4 | 100 | 350 | 100 / 160 / 220 / 290 |
| 4 | Zone4 | 32 | 32 | 8 | 8 | 4 | 350 | 1.000 | 350 / 510 / 680 / 840 |
| 5 | Zone5 | 32 | 32 | 8 | **5,25** | 4 | 1.000 | 3.000 | 1.000 / 1.500 / 2.000 / 2.500 |
| 6 | Zone6 | 32 | 32 | 8 | 8 | 4 | 3.000 | 9.000 | 3.000 / 4.500 / 6.000 / 7.500 |
| 7 | Zone7 | 32 | **20** | 8 | **9,5** | 6 | 9.000 | 30.000 | 9.000 / 14.000 / 19.500 / 25.000 |
| 8 | Zone8 | 32 | **20** | 8 | **10** | 10 | 30.000 | 75.000 | 30.000 / 41.000 / 52.500 / 64.000 |
| 9 | Zone9 | 32 | **20** | 8 | **9,25** | 9 | 75.000 | 150.000 | 75.000 / 94.000 / 113.000 / 131.000 |
| 10 | Zone10 | 32 | **10** | 8 | **16** | 9 | 150.000 | 330.000 | 150.000 / 195.000 / 240.000 / 285.000 |

`Collection.RespawnSeconds = 2` · `MinimumEligibleActivePerZone = 4` · `RequireStickinessForPickup = nil` (no existe; M1 lo crea)

---

## 3. ⚠️ Hallazgo 1: `GameConfig` miente sobre cuatro salas

`RoomSettingsReader` declara su precedencia en su propia cabecera:

```
Zones.<Zone>.RoomSettings (authored)  ->  GameConfig.Zones  ->  GameConfig.Placement
```

**El Workspace gana.** Y en las salas 7 a 10 el Workspace dice **20, 20, 20 y 10** objetos donde `GameConfig` dice 32, con separaciones de 9,25 a 16 studs en vez de 8.

Eso coincide exactamente con lo que el documento de la máquina cuenta —*«las salas tardías ya usan props grandes: bajaron de 32 a 20 y a 10»*— pero **`GameConfig` nunca se actualizó**. Es la misma clase de divergencia que el proyecto ya arrastra con los blockers de World 1.

> **Consecuencia directa para M0:** cualquiera que calcule la duración de World 1 leyendo `GameConfig` se equivoca en **4 de las 10 salas**, y justo en las cuatro más largas. El censo de arriba usa el Workspace, que es lo que el juego ejecuta.

**Y una consecuencia para M1 que no es obvia:** el impacto de retirar el requisito **no es uniforme**. En una sala de 10 objetos con separación de 16 studs, el jugador ya está caminando entre objeto y objeto; en una de 32 con separación de 8, no. Retirar la puerta acorta mucho más donde hay muchos objetos juntos.

---

## 4. ⚠️ Hallazgo 2: el «25 %» es 25 % en unas salas y 40 % en otras

Esto **corrige lo que yo mismo escribí** en la primera pasada del plan, que generalizó de más.

| Salas | `CollectibleRequirementWeights` | Reparto por escalón | Elegible al entrar |
| --- | --- | --- | --- |
| **1 a 3** | `4 / 3 / 2 / 1` | 40 / 30 / 20 / 10 % | **40 %** |
| **4 a 10** | **no existe** | equitativo | **25 %** |

`ItemPlanner.requirementWeights` solo usa los pesos si `#configured == requirementCount`; con cero pesos configurados cae al reparto equitativo. Las salas 4 a 10 no declaran pesos ni en `GameConfig` ni en el Workspace, y las bandas de `ZoneCollectibleRequirementBands` solo reescriben World 2 y World 3.

> Así que el *«solo el 25 % de los objetos son elegibles al entrar»* del documento de la máquina **es correcto para las salas 4 a 10** y **optimista para las tres primeras**, donde en realidad es el 40 %.
>
> Importa porque las tres primeras son justo donde el embudo pierde el 39,6 % de las vueltas. El cambio de M1 se nota **menos** ahí de lo que el documento supone, y **tanto como supone** en las siete restantes.

---

## 5. ⚠️ Hallazgo 3: el proyecto tiene dos duraciones de World 1 y no se parecen

Cada zona declara un `ExpectedSeconds`, y sumados dan:

```
580 a 855 segundos   =   9,7 a 14,2 minutos
```

El documento de la máquina trabaja con **~35,7 min** para World 1, y sobre esa cifra está construido todo el encaje de la máquina (precio 850, pool completado al ~108 % del mundo).

**Son dos números que difieren entre 2,5× y 3,7×**, y no se puede saber cuál gobierna sin cronometrar. Las dos posibilidades tienen consecuencias distintas:

| Si la buena es… | Entonces |
| --- | --- |
| **~35,7 min** | `ExpectedSeconds` es una estimación vieja que nadie ha actualizado, y no debe usarse para nada |
| **~10–14 min** | El precio de 850 ♻ deja el pool a menos de la mitad al acabar el mundo, y el encaje de §4.6 del documento de la máquina hay que rehacerlo |

> **Esto sube el valor de la corrida cronometrada:** ya no sirve solo para medir el Δ de M1. Sirve para saber cuál de los dos números del proyecto es el verdadero, y eso decide el precio de la máquina.

---

## 6. Lo que falta: la corrida

El censo da el *qué*; el cronómetro da el *cuánto*. Falta el cuánto, y hay un problema práctico que conviene decir en voz alta.

**Una vuelta completa a World 1 no se puede automatizar en un rato.** Las salas 7 a 10 piden 30.000, 75.000, 150.000 y 330.000 de Stickiness, y eso solo se alcanza subiendo la escalera de wraps, que se compra con Wins. Conducir el personaje con navegación para farmear eso son decenas de minutos reales y muchísimas llamadas.

### La versión barata y decisiva: **solo la sala 1, dos veces**

| | |
| --- | --- |
| **Qué** | Cronometrar `ToyRoom` con el requisito puesto y con el requisito quitado, misma cuenta y mismo wrap |
| **Por qué esa sala** | Necesita 10 de Stickiness con `BasicGlue` (+1/objeto): son **diez objetos**, no treinta mil. Se mide en segundos, no en horas |
| **Por qué vale** | Es donde el embudo pierde el 39,6 % de las vueltas. Si el cambio tiene que notarse en algún sitio, es ahí |
| **Y además** | Es una de las tres salas con pesos `4/3/2/1`, o sea la que menos debería cambiar (40 % ya elegible). **Si incluso ahí el Δ es grande, en las otras siete será mayor** — es un suelo, no un techo |

⚠️ **Lo que esta versión NO da:** la duración total de World 1, o sea no resuelve el hallazgo 3. Para eso hace falta una vuelta completa jugada por una persona, con el cronómetro por sala.

### Y lo que se engancha gratis a esa corrida

Los **4 comunes vistos con la bola llena** (pendiente de la fase P). Recogiendo en `ToyRoom` la bola se llena sola, y aplicar las cuatro paletas durante la corrida cuesta cero tiempo extra.

---

## 8. ⭐ Hallazgo 4: `ResidueValue` ya tiene dónde vivir, y hay DOS cosas llamadas `SizeTier`

Medido en el place, en `ToyRoom`, con los objetos ya renderizados:

```
reparto por escalón de requisito:  40 % / 29 % / 20 % / 11 %
esperado desde los pesos 4/3/2/1:  40 % / 30 % / 20 % / 10 %
```

El §4 queda **confirmado con datos vivos**, no solo leyendo la config.

### Las dos cosas que se llaman igual

| | Qué es | De dónde sale | Quién lo usa |
| --- | --- | --- | --- |
| **`GameConfig.GetCollectibleSizeTier(zoneId, requiredStickiness)`** | un **número** de 1 a 4 | **derivado del requisito** de la tabla de la zona | `PickupService` lo manda en el evento de recogida; el cliente lo convierte en tono y volumen |
| **El atributo `SizeTier` de la plantilla** | una **cadena**: `Small` · `Medium` · `Big` | **authored en el prop**, en `ReplicatedStorage.Assets.Collectibles` | nadie lo consume todavía |

Comparten nombre y significan cosas distintas. **Es una trampa con nombre y apellidos**, y conviene saberla antes de tocar nada de M2.

Inventario del atributo authored: **41 `Small` · 28 `Medium` · 22 `Big`** en las plantillas, más 24 `Medium` en props del Workspace. Las 55 de `ToyRoom` son todas `Small`, coherente con una primera sala de bellotas y setas.

### Por qué esto mejora el plan de M2

El documento propone authorizar `ResidueValue` por bracket de tamaño (XS/S/M/L/XL) sobre `GameConfig.CollectibleTypes`, que son 9 entradas. Pero **el prop ya declara su tamaño**, en 91 plantillas, y el propio documento insiste en que *«el valor vive en el prefab, no en una tabla paralela»*.

> ⭐ **Propuesta revisada para M2:** `ResidueValue` se deriva del atributo `SizeTier` **authored**, y el audio de recogida se repunta a lo mismo.
>
> Entonces **el tamaño del prop decide las tres cosas a la vez**: lo que ves (la etiqueta), lo que oyes (el tono) y lo que suma (el Residuo). Es exactamente el principio que el comentario de `GameConfig` ya declara —*«lo que se oye y lo que se ve coinciden por construcción»*— solo que hoy está atado a la tabla de requisitos, que es justo la que M1 vacía de sentido.

⚠️ **Lo que falta decidir:** el atributo authored tiene **tres** valores y el documento propone **cinco** brackets (1/2/3/5/8). O se mapea 3→3 (por ejemplo 1/3/8) o se añaden `Tiny` y `Huge` a las plantillas que lo merezcan. Es una decisión de arte, no de código, y entra en M2.

---

## 9. Resumen para el plan

| | |
| --- | --- |
| ✅ Censo de las 10 salas, verificado contra el place | hecho |
| ✅ `GameConfig` corregido de palabra: el Workspace manda en las salas 7–10 | documentado aquí, **no** tocado en código |
| ✅ Fracción elegible real por sala (40 % en 1–3, 25 % en 4–10) | hecho, y **confirmado con datos vivos**: 40/29/20/11 medido en ToyRoom |
| ✅ `SizeTier` authored como carril para `ResidueValue` | hallado (§8). Cambia el plan de M2, a mejor |
| ⏳ Corrida cronometrada | **pendiente** |
| ⏳ Cuál de las dos duraciones de World 1 es la buena | **pendiente, y decide el precio de la máquina** |
| ⏳ Los 4 comunes con la bola a 300 piezas | **pendiente, se engancha a la corrida** |

⚠️ **No se ha tocado `GameConfig` para arreglar el 32.** Cambiar esos números no afecta al juego —el Workspace gana igual— pero sí afectaría a cualquiera que los lea, y tocar la config de salas no es parte de esta feature. Queda anotado como deuda con nombre y sitio.
