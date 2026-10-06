# Catálogo de blobs — World 1 · Bosque

**Fase P del plan.** Siete fichas producibles: 4 comunes, 2 raros, 1 épico.
**Estado:** los 4 comunes están **pintados y validados a ojo** (2026-09-19). Los 2 raros y el épico están especificados pero **no producidos** — eso es la fase G.

---

## 0. Lo que la prueba de los cuatro verdes enseñó

La fase P existe para una cosa: **pintar los 4 comunes juntos antes de producirlos.** Se hizo, y la primera ronda **falló 3 de 4**. Merece quedar escrito, porque son errores que se habrían descubierto a mitad de producción.

### 0.1 ⚠️ La curva de valor va en los dos sentidos, y los documentos solo cuentan uno

```
v' = 1 - (1 - v)^c
```

| `c` | Efecto |
| --- | --- |
| `c > 1` | **aclara** los medios — es lo que `1,9` hace en W2 y W3 |
| `c = 1` | no toca nada |
| `c < 1` | **oscurece** |

Los dos documentos describen `1,9` como *«levanta los medios sin romper el orden de la rampa»*, que es cierto, pero **nunca dicen que por debajo de 1 oscurece**. En la primera ronda se pusieron curvas `1,35` y `1,10` a Musgo y Corteza esperando tonos apagados y **salieron más claros que la base**: un musgo brillante y una corteza color crema. La mitad de una paleta de bosque necesita oscurecer, así que esto no es un detalle.

### 0.2 ⭐ Dos colores se separan por saturación y valor, no solo por tono

`CORTEZA` está a **22°** y el naranja de World 2 a **27°**: cinco grados. Y aun así no se parecen en nada, porque Corteza va a `sat 0,60 / curva 0,50` y W2 a `sat 1,15 / curva 1,90`. Uno es un marrón oscuro y el otro un naranja encendido.

> **Regla que sale de ahí:** rotar el tono es solo uno de los tres diales. Cuando dos items caen cerca en tono —y con 21 items va a pasar— **se separan bajando saturación y valor a uno de los dos**, no forzando el tono a un sitio donde no quiere estar.

### 0.3 ⚠️ Y una restricción que ningún documento escribe: **no invadir la paleta de otro mundo**

El documento de blobs presume que llevarte un blob de Lava al Bosque es un flex: *«la prueba visible de que has estado donde el otro no ha llegado»*. Eso **solo funciona si los comunes del Bosque no se parecen al naranja de Desierto ni al rojo de Lava.** Un común de W1 color terracota destruye esa propiedad para los 21 items a la vez.

Por eso la propuesta original de comunes no sirve tal cual: **`Terracota` y `Oro` están en la columna de W2, y `Miel` y `Corteza` en la de W1, y las cuatro caen en la misma banda de tono.**

**Regla:** los comunes de un mundo se pintan **con las referencias de los otros dos mundos en el mismo cuadro**. Se hizo así y es la única forma de verlo.

### 0.4 Qué se cambió respecto a la propuesta original

| Original | Qué pasó | Ahora |
| --- | --- | --- |
| Musgo | Salió más claro que la base. Leía como «verde brillante», no como musgo | **MUSGO** con curva `0,60` — verde oscuro apagado |
| Miel | Correcto | **MIEL**, sin cambios de concepto |
| **Savia** | **Indistinguible de Miel.** 9° de diferencia, los dos amarillos | ❌ **Fuera.** Sustituida |
| Corteza | Salió color crema | **CORTEZA** con `sat 0,60 / curva 0,50` — marrón oscuro de verdad |
| — | Hacía falta un cuarto que no fuera ni verde ni cálido | ⭐ **VERDÍN**, verde azulado. Es el único de los cuatro en banda fría, y es lo que hace que los cuatro se lean de un vistazo |

---

## 1. Los cuatro comunes — ✅ validados

Peso **18 %** cada uno. Todos son **paleta pura**: filas 0–3 recoloreadas y nada más. Cero emisores, cero material, cero movimiento propio. `FillBudget = 0`.

### MUSGO
```
Id            MossW1                    Rareza  Común (18 %)     Mundo  World1
Qué es        Paleta
Paleta        Hue 100°  ·  SatScale 0,65  ·  ValueCurve 0,60     (filas 0-3)
Resultado     claro  95,140, 72          oscuro  19, 32, 12
ColorA/B      #5F8C48 / #132014          -> tiñen tambien el aura de prestigio
Material      SmoothPlastic (sin cambios)
Claves        Blobs.Item.MossW1.Name · .Kind · Blobs.Rarity.Common
Acepta si     Se distingue de W1_BASE a 10 studs con la bola a 300 piezas
```

### MIEL
```
Id            HoneyW1                   Rareza  Común (18 %)     Mundo  World1
Qué es        Paleta
Paleta        Hue 40°  ·  SatScale 1,25  ·  ValueCurve 2,00
Resultado     claro 237,164, 17          oscuro  92, 61,  0
ColorA/B      #EDA411 / #5C3D00
Material      SmoothPlastic
Claves        Blobs.Item.HoneyW1.Name · .Kind · Blobs.Rarity.Common
Acepta si     No se confunde con la fila 4 del atlas (la rampa dorada, que NO se toca)
⚠️            Es el más cercano al naranja de W2. Verificado en el mismo cuadro: separa.
              Si algún día se mueve el tono de W2, se revisa este.
```

### CORTEZA
```
Id            BarkW1                    Rareza  Común (18 %)     Mundo  World1
Qué es        Paleta
Paleta        Hue 22°  ·  SatScale 0,60  ·  ValueCurve 0,50
Resultado     claro 123, 88, 68          oscuro  27, 17, 11
ColorA/B      #7B5844 / #1B110B
Material      SmoothPlastic
Claves        Blobs.Item.BarkW1.Name · .Kind · Blobs.Rarity.Common
⚠️            22° está a 5° del naranja de W2 y NO se parecen, porque van a saturación y
              valor opuestos (§0.2). Es el caso que demuestra la regla.
Acepta si     No se pierde contra el suelo del Bosque. Es el más oscuro de los cuatro.
```

### VERDÍN
```
Id            VerdigrisW1               Rareza  Común (18 %)     Mundo  World1
Qué es        Paleta
Paleta        Hue 168°  ·  SatScale 0,90  ·  ValueCurve 1,60
Resultado     claro  74,224,194          oscuro  10, 77, 63
ColorA/B      #4AE0C2 / #0A4D3F
Material      SmoothPlastic
Claves        Blobs.Item.VerdigrisW1.Name · .Kind · Blobs.Rarity.Common
⚠️            Es el más llamativo de los cuatro y puede leerse como raro. Si en la prueba
              con la bola llena destaca demasiado, bajar SatScale a 0,72 antes que cambiar
              el tono: el tono es lo que lo separa de los otros tres.
Acepta si     Sigue leyéndose como común al lado de HOJA y ROCÍO
```

---

## 2. Los dos raros — especificados, sin producir

Peso **11 %** cada uno. Paleta + material + perfil de emisores + perfil de `BoneMotion` + sonido.

### ⚠️ La regla de degradación, que aplica a los dos

Medido en B0: **los tiers 1–3 tienen 5 huesos (`root`, `spine_01..04`) y UN emisor (`PrestigeAura`). Los tiers 4–8 tienen 8 huesos y tres emisores.**

> Toda ficha de raro y de épico declara **qué se ve con 1 emisor y qué con 3**, y su `BoneMotion` nombra solo huesos que existen en los 8 tiers, o dice explícitamente qué se pierde. Un perfil que pida `PrestigeMist` en un tier 1 **no da error: no hace nada.**

### HOJA
```
Id            LeafW1                    Rareza  Raro (11 %)      Mundo  World1
Qué es        Elemento (paleta + material + VFX + movimiento)

Paleta        Hue 88°  ·  SatScale 0,85  ·  ValueCurve 1,15      verde hoja, mate
ColorA/B      #8FBF4A / #2D4715
Material      Base Enum.Material.Grass   ·  Variant "Leaf_PBR"  (fase G)
              Reflectance 0 — es lo que lo separa de MUSGO, que comparte banda de tono

Emisores      MULTIPLICADORES sobre lo authored, nunca valores absolutos
  con 3 capas (tier 4-8)
    PrestigeAura  Body    RateScale 0,9  SizeScale 1,0  LightEmission 0,15
    PrestigeMist  Motes   RateScale 1,3  SizeScale 0,8  Drag 0,6   -> esporas que flotan
    PrestigeBurst Accent  RateScale 0,8  SizeScale 1,1
  con 1 capa (tier 1-3)
    PrestigeAura  Body    RateScale 1,1  SizeScale 1,0  Drag 0,4
    -> las esporas se pliegan dentro del aura. Se pierde el flotar, se conserva el verde mate.

BoneMotion    "breathe"  ·  root + spine_01..04   (existe en los 8 tiers)
              respiracion lenta, amplitud baja. NO usa spine_05/Left/Right, asi que
              se ve igual en tier 1 que en tier 8.
Sonido        Feedback/Audio/StepLeaf   (paso amortiguado)
FillBudget    34 studs^2
Claves        Blobs.Item.LeafW1.Name · .Kind · Blobs.Rarity.Rare
Acepta si     Se distingue de MUSGO **en movimiento**. Comparten banda de tono a proposito:
              lo que los separa es material mate + esporas + respiracion. Si no se separan,
              HOJA cambia de tono, no MUSGO (el comun manda, es mas barato de mover).
```

### ROCÍO
```
Id            DewW1                     Rareza  Raro (11 %)      Mundo  World1
Qué es        Elemento (paleta + material + VFX + movimiento)

Paleta        Hue 202°  ·  SatScale 0,35  ·  ValueCurve 2,40     casi blanco azulado
ColorA/B      #CFE6F2 / #43606E
Material      Base Enum.Material.Glass  ·  Transparency 0,32  ·  Reflectance 0,28

⚠️ Tension con VERDIN, y resuelta a proposito
              VERDIN ya ocupa la banda fria. ROCIO NO compite por el tono: va casi
              desaturado y su identidad son la TRANSPARENCIA, las gotas y el wobble.
              Un blob que se ve a traves no se confunde con uno opaco, tenga el tono
              que tenga. Si aun asi chocan, se baja SatScale de ROCIO a 0,20.

Emisores
  con 3 capas
    PrestigeAura  Body    RateScale 0,7  SizeScale 1,0  LightEmission 0,40
    PrestigeMist  Motes   RateScale 1,5  Acceleration Y negativa  -> gotas que caen
    PrestigeBurst Accent  RateScale 1,2  SizeScale 1,3            -> salpicadura al aterrizar
  con 1 capa
    PrestigeAura  Body    RateScale 1,0  Acceleration Y negativa
    -> se conservan las gotas, se pierde la salpicadura. La transparencia es lo que
       carga la identidad en tier bajo, y esa no depende de emisores.

BoneMotion    "wobble"  ·  root + spine_01..04
              inercia liquida, amplitud alta y lenta. Se aplana al caer.
Sonido        Feedback/Audio/StepDew
FillBudget    41 studs^2
Claves        Blobs.Item.DewW1.Name · .Kind · Blobs.Rarity.Rare
⚠️            Transparency en el cuerpo puede pelearse con el LOD de attachments cuando la
              bola esta llena. Medir en M7, no antes.
Acepta si     Se lee como agua a 10 studs sin necesidad de ver las gotas
```

---

## 3. El épico — especificado, con un conflicto resuelto

### ⚠️ El conflicto que traía la propuesta original

El documento de blobs propone `Micelio — bioluminiscente, esporas, **hongos brotando de los huesos**`. Y en §8 del mismo documento dice que **las piezas del épico tienen que vivir a ~7–9 studs del cuerpo**, porque la bola a 300 piezas mide 13 studs de diámetro y entierra al blob.

**Las dos cosas no pueden ser verdad a la vez.** Unos hongos brotando de los huesos están pegados al cuerpo: en el juego tardío no se ven nunca.

### La salida: un épico de dos capas

No hay que elegir. Hay que **usar el momento que la máquina regala**:

| Capa | Qué es | Cuándo se ve |
| --- | --- | --- |
| **Cerca** — los hongos | MeshParts soldados a los huesos | En el revelado, **con la bola recién vaciada** (§4.2 del doc de la máquina). Es el único momento de la sesión en que el blob se ve entero, y ya está pagado |
| **Lejos** — el anillo de esporas | `Beam` + partículas orbitando a ~8 studs | **Siempre.** Es lo que lleva la identidad cuando la bola está llena |

**Y el orden de producción sale de ahí: primero el anillo, después los hongos.** El anillo es el que hace el trabajo el 90 % del tiempo, cuesta cero física, y si G4 se queda sin tiempo el épico sigue siendo un épico. Los hongos son el premio del primer plano.

```
Id            MyceliumW1                Rareza  Epico (6 %)      Mundo  World1
Qué es        Elemento + piezas

Paleta        Hue 150°  ·  SatScale 0,45  ·  ValueCurve 0,70     cuerpo apagado, casi gris verdoso
ColorA/B      #7FA98F / #1E3326
              -> el cuerpo va APAGADO a proposito: lo que brilla son las piezas y el anillo.
                 Un cuerpo brillante mas un anillo brillante es la composicion que
                 `vfx-auras-trails` prohibe (un elemento dominante + dos apoyos).
Material      Base Enum.Material.Slate  ·  Variant "Mycelium_PBR"

Capa LEJOS — se produce primero
    Orbit     Beam entre Attachments a ~8 studs, 3 arcos desfasados.
              Mismo patron que las orbitas de las auras tier 9+. CERO fisica.
              Emision bioluminiscente cian-verdosa, pulso lento.
    Motes     esporas sueltas que se desprenden del anillo, Drag alto

Capa CERCA — se produce despues, y es lo primero que se recorta
    4 a 6 hongos soldados a spine_01..04  (huesos que existen en los 8 tiers)
    generate_mesh / generate_procedural_model. generate_texture SI se puede usar aqui:
    son MeshParts aparte y no estan rigged.
    ⚠️ 6 piezas x 12 jugadores = 72 partes extra en la asamblea movil, a ~1,4 us por
       parte y por paso. Medir antes de subir de 4 piezas.

  con 1 capa (tier 1-3)
    El anillo NO depende de los emisores del blob: vive en sus propios Attachments.
    Asi que el epico se ve COMPLETO en los 8 tiers. Es la ventaja de colgarlo de
    Attachments propios en vez de multiplicar los emisores authored.

BoneMotion    "pulse"  ·  root + spine_01..04   latido lento sincronizado con el anillo
Sonido        Feedback/Audio/StepMycelium
FillBudget    58 studs^2   (el tope del elemento es 60 — es el unico que se acerca)
⚠️ Prohibido  Highlight para las vetas. Tope de 31 por cliente. Textura o emision.
Claves        Blobs.Item.MyceliumW1.Name · .Kind · Blobs.Rarity.Epic
Acepta si     1) El anillo se lee POR ENCIMA de la bola a 300 piezas, desde 13 studs de
                 camara con FOV 82.
              2) Los hongos se leen en el revelado, con la bola vacia.
              3) Con 12 jugadores el frame time no se mueve.
```

---

## 4. Resumen y presupuesto

| # | Item | Rareza | Peso | Qué es | Coste | `FillBudget` |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **MUSGO** | Común | 18 % | paleta | 3 números | 0 |
| 2 | **MIEL** | Común | 18 % | paleta | 3 números | 0 |
| 3 | **CORTEZA** | Común | 18 % | paleta | 3 números | 0 |
| 4 | **VERDÍN** | Común | 18 % | paleta | 3 números | 0 |
| 5 | **HOJA** | Raro | 11 % | elemento | medio | 34 studs² |
| 6 | **ROCÍO** | Raro | 11 % | elemento | medio | 41 studs² |
| 7 | **MICELIO** | Épico | 6 % | elemento + piezas | alto | 58 studs² |

Suma de pesos: **100 %**. Cada común es exactamente **3×** más probable que el épico.

**Ningún item supera el tope de 60 studs² del elemento**, y solo el épico se acerca. El aura y la estela conservan sus ~174 studs² sin tocar.

### Suplentes, por si una ficha se cae

| Si se cae | Entra | Por qué |
| --- | --- | --- |
| **VERDÍN** (por llamativo) | **PINO** — hue 140, sat 0,55, curva 0,45 | Verde muy oscuro y frío. Cubre la banda fría sin brillar |
| **ROCÍO** (por `Transparency` en móvil) | **NIEBLA** — opaco, hue 200, sat 0,25, aura densa | Misma lectura fría y suave, sin transparencia |
| **MICELIO** (por coste) | **LUCIÉRNAGAS** — solo la capa lejos: anillo + motes, sin piezas | Es el épico sin su mitad cara. Sigue siendo el más raro y cuesta como un raro |

---

## 5. Lo que falta para cerrar la fase P

| | Estado |
| --- | --- |
| Los 4 comunes pintados y comparados entre sí | ✅ **hecho** |
| Comparados contra las referencias de W2 y W3 | ✅ **hecho** — ninguno invade |
| Las 7 fichas con sus campos y criterio de aceptación | ✅ **hecho** |
| Suplente por ficha | ✅ **hecho** |
| Presupuesto de relleno sumado | ✅ **hecho** |
| ⏳ **Los 4 comunes vistos con la bola a 300 piezas** | **pendiente** — ver abajo |

### ⭐ Dónde encaja la prueba de la bola llena

`AttachmentService` no expone ninguna vía para conceder piezas a mano (su API pública es `Init`, `Destroy`, `GetStats`, `ClearPlayerVisuals` y `_FlushPending`). Llenar la bola **exige jugar**: recoger de verdad, que es justo lo que la guarda de §3.4 del documento de la máquina existe para garantizar.

Así que no se fuerza: **se engancha a M0.** La fase M0 es una corrida cronometrada por las 10 salas de World 1, o sea que **la bola se llena sola** durante una prueba que ya hay que hacer. Aplicar los 4 comunes durante esa corrida cuesta cero tiempo extra y responde la pregunta en condiciones reales.

> **No se deja para M7.** M7 es la puerta de publicación; descubrir allí que un común no se ve con la bola llena obligaría a rehacer una ficha con todo lo demás construido encima.

### De paso, verificado hoy

`AttachmentService.Init` se engancha con `PickupService.ConnectCollected(onCollected)` — **exactamente la misma puerta** que el documento de la máquina manda usar para `ResidueService` (§3.4, §6.2). El patrón existe, está en uso, y `ResidueService` solo tiene que copiarlo.
| ⏳ **Los nombres finales en el `LocalizationTable`** | **pendiente** — fase L, pero las claves ya están nombradas aquí |
| ⏳ **Tu juicio visual sobre los cuatro** | **pendiente** — es lo único que no se puede medir |
