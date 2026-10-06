# Blobs como recompensa: producción, propiedades y encaje con la máquina aspiradora

---

## 0. La decisión, en una frase

> **Un blob-recompensa no es un blob nuevo: es una CAPA que se pinta encima del blob que el jugador ya tiene.** La silueta y la animación siguen saliendo del wrap —o sea, siguen contando tu progreso—; el elemento cambia superficie, VFX y ritmo de movimiento.

De ahí salen las tres propiedades que hacen que esto funcione con un pool de solo 7 items por mundo:

|  |  |
| --- | --- |
| **La progresión sigue leyéndose** | La tesis del proyecto es *«la delta se ve sin leer un número, porque cambia la silueta del avatar»*. Un cosmético que reemplace la silueta **borra esa tesis**. Una capa no |
| **7 recompensas rinden como 56** | 7 elementos × 8 peldaños de wrap. El elemento que ganaste en el minuto 10 **vuelve a verse nuevo** cuando subes de glue, porque se repinta sobre una silueta más grande |
| **Un elemento nuevo = una fila de datos** | Cero código por variante. Es la arquitectura que `BLOBS_CAPACIDADES_Y_VARIEDAD` §6 ya propone, con un solo cambio: el elemento lo elige **el jugador**, no el wrapId |

---

## 1. Lo que ya está construido — verificado hoy

| Comprobación | Resultado |
| --- | --- |
| `GameConfig.WrapBlobs.TemplateByWrapId` | **30 wrapIds** → 24 plantillas |
| `ReplicatedStorage.Assets.WrapBlobs` | **24 plantillas** (8 niveles × 3 mundos) |
| `WrapBlobs.Prestige.ByTemplate` | **24 entradas**, **11 knobs** cada una: `ColorA ColorB AuraRate ParticleSize LightBrightness LightRange VisualScale EquipBurstCount AccentBurstCount Tier Title` |
| `WrapBlobs.Movement.AnimationByTemplate` | **24 entradas** |
| `WrapBlobs.Elements` | **no existe todavía** — es lo que hay que crear |
| Texturas de paleta | **3**, exactamente 8 blobs cada una: `95095740632696` (W1 verde) · `90129514680834` (W2 naranja) · `74715005870718` (W3 rojo) |
| `Lvl08_b` | `Size = 7,60 × 10,26 × 6,12` · **8 Bones** · 3 emisores (`PrestigeAura`, `PrestigeMist`, `PrestigeBurst`) |
| Material del blob | `SmoothPlastic`, `MaterialVariant`** vacío**, **sin **`SurfaceAppearance` |
| `Cosmetics.AuraAttachmentName` | `Core` — el ancla común de todo lo que emite un cosmético |
| `Cosmetics.ResetOnRebirth` | `false` — los cosméticos sobreviven al Rebirth |

### 1.1 ⭐ El desacople ya está hecho, y casi nadie lo sabe

```
Wraps.BlobSkinTravelsBetweenWorlds  = true
WrapBlobs.SkinAttributeName         = "BlobSkinWrapId"
```

**El aspecto del blob ya está separado de la ganancia del wrap** desde el 4 de septiembre (`claude/piel-de-blob-viaja-entre-mundos-2026-09-04.md`):

| Campo | Qué decide | Quién lo cambia | ¿Viaja entre mundos? |
| --- | --- | --- | --- |
| `StickyWrapId` | la **ganancia** por objeto | el jugador **y** los reequipados automáticos | no — cada mundo lo reajusta a su catálogo |
| `BlobSkinWrapId` | el **aspecto** del blob | **solo** el jugador, equipando a mano | **sí** |

Eso significa que **la mitad difícil de este trabajo ya está hecha y probada**: la ruta de "apariencia por jugador, persistida, que viaja, y que no puede dejar a nadie encallado con una ganancia inútil" existe, tiene su flag de rollback y tiene su tabla de verificación.

Lo que falta es un **tercer** concepto encima.

---

## 2. Los tres campos

```
StickyWrapId    →  ganancia por objeto          (economía; se reajusta por mundo)
BlobSkinWrapId  →  plantilla = silueta + tier    (progreso visible; viaja)
BlobElementId   →  superficie + VFX + movimiento ← NUEVO, sale de la máquina aspiradora
```

Tres campos, tres dueños, tres razones distintas para cambiar. Ninguno pisa a los otros.

### 2.1 El elemento cambia el **qué**. El tier cambia el **cuánto**

Esta es la regla que mantiene viva la lectura de progresión, y es la única que hay que respetar al escribir la tabla:

| El **tier** (del wrap) aporta | El **elemento** (del jugador) aporta |
| --- | --- |
| `VisualScale` — lo grande que es | La **paleta** (filas 0–3 del atlas, §3) |
| `AuraRate`, `ParticleSize` — cuánto emite | El **material** y el `MaterialVariant` |
| `LightBrightness`, `LightRange` — cuánto ilumina | El **carácter** de los emisores: forma, dirección, arrastre, textura |
| `EquipBurstCount`, `AccentBurstCount` | El perfil de `BoneMotion` |
| `Title` (`FRESH` … `TRANSCENDENT`) | El sonido |

**El elemento nunca escribe un valor absoluto de tier: lo multiplica.** `AuraRate` de un blob de fuego tier 8 es `10 × factorFuego`, no `14`. Con eso:

- Un blob de fuego **tier 1 y uno tier 8 se siguen distinguiendo a diez metros.**
- Y si mañana alguien rebalancea la escalera de prestigio, los 7 elementos la siguen sin tocarlos.

Es exactamente la disciplina que `blobs-color-por-mundo` ya aplicó cuando creó las 16 entradas de W2/W3: **se derivaron con un bucle desde el tier base, no se escribieron a mano**, precisamente para que los mundos no divergieran en silencio la primera vez que alguien tocara un rate.

### 2.2 ⚠️ La trampa que este proyecto ya pisó una vez

Cuando se desdobló `StickyWrapId` en dos campos, casi se cuela un bug que habría dejado la piel **pegada para siempre**: `TryEquipWrap` cortaba con `if state.StickyWrapId == wrapId then return "AlreadyEquipped"`, y la única acción capaz de cambiar la piel era justo la que se rechazaba.

> **Regla que quedó escrita, y que ahora aplica otra vez:** al desdoblar un campo en dos —o en tres— hay que **revisar todos los cortocircuitos que comparaban contra el campo viejo**. Un `AlreadyEquipped` que antes era exacto pasa a ser una verdad parcial.

Al añadir `BlobElementId` hay que barrer, como mínimo: `TryEquipWrap`, `TryBuyWrap`, `GrantWrap`, `effectiveBlobSkinId`, `TrySetWorld`, `TryRebirth` y `WrapBlobService.currentWrapId`.

### 2.3 Por qué NO dejar que el elemento reemplace la silueta

Es la petición que va a salir sola («¿y un blob con forma de dragón?»), y hay que poder decir que no con un argumento:

1. **Un mesh generado por IA no viene rigged.** Un blob nuevo desde prompt pierde las 8 animaciones de movimiento y deja de moverse como un blob. Es la regla de oro del documento de capacidades.
2. **Se pierde la lectura de progreso.** Si tu silueta ya no dice qué glue llevas, el juego pierde la única cosa que el competidor no puede copiar.
3. **No hace falta.** Con paleta + material + VFX + ritmo de movimiento, fuego / agua / tierra se leen como tres criaturas distintas compartiendo esqueleto. Eso está en §5 del documento de capacidades y es cierto.

**La silueta sí se puede extender** —piezas añadidas soldadas a los huesos— y ahí es donde entra el épico (§5). Extender no es reemplazar.

---

## 3. ⚠️ Corrección: un color de blob **no** es un `Color3`

El documento de la máquina dice que los colores de blob son \*«coste de arte casi nulo: un `Color3`

- material»\*. **Eso es falso, y está demostrado que es falso.**

### Dónde vive el color

`MeshPart.Color` vale `Smoky grey` en las 24 plantillas **y el mesh lo ignora, porque tiene **`TextureID`. Todo el color está en una **textura de paleta compartida**, verificada hoy:

```
512 × 512   ·   rejilla de 4 columnas × 6 filas   ·   24 colores planos
```

| Fila | Contenido | Valores leídos hoy (centro de celda) | Tratamiento |
| --- | --- | --- | --- |
| **0–3** | rampa del cuerpo, 16 tonos de claro a oscuro | — | **se recolorea** |
| **4** | rampa dorada / ámbar | `146,108,7` · `189,145,4` · `242,169,9` · `198,183,87` | **idéntica al píxel** |
| **5** | grises, blanco y negro — **los ojos** | `198,186,171` · `216,206,195` · `255,255,255` · `0,0,0` | **idéntica al píxel** |

> La regla que protege la identidad del personaje
> 
> **Las filas 4 y 5 no se tocan nunca.** Ahí está la cara. Un elemento que recolorea la fila 5 deja al blob con los ojos del color del elemento, y deja de ser el mismo personaje disfrazado para pasar a ser otra cosa. **Los 21 items comparten cara.**

### Y por qué tintar no es una salida

- El `MeshPart` con `TextureID` ignora `Color`.
- Y aunque no lo ignorara, **un tinte es una multiplicación**: no existe multiplicador que convierta un verde (canal rojo ≈ 0) en naranja. Y teñiría los ojos.

### La curva perceptual, que ya está resuelta

El primer intento de recolorear a naranja y rojo salió **terracota y granate**. No fue un error de cálculo: a igual `V` en HSV, un verde saturado se percibe mucho más luminoso. La corrección, ya validada contra dos texturas en producción:

```
v' = 1 - (1 - v)^1.9          -- levanta los medios sin romper el orden de la rampa
W2 naranja     -> tono 27°, saturación ×1,15
W3 rojo fuego  -> tono  8°, saturación ×1,18
```

> **Regla general del proyecto, ya escrita:** *rotar el tono nunca basta; hay que compensar la luminosidad percibida o el color sale apagado.*

**Coste real de un color de blob: no es cero, pero sí es barato y es enteramente automatizable.** Son tres números (tono, saturación, curva) y un proceso de imagen. Lo que no es, es una propiedad.

---

## 4. ⭐ El hallazgo: la paleta se puede pintar **en runtime**, sin subir ningún asset

Esto lo probé hoy en el place, y cambia la economía de producción de toda la feature:

```
AssetService:CreateEditableImage({Size = ...})           →  OK
EditableImage:WritePixelsBuffer(...)                     →  OK
Content.fromObject(editableImage)                        →  existe
MeshPart.TextureContent = Content.fromObject(img)        →  OK
AssetService:CreateEditableImageAsync(<atlas base>)      →  OK, 512×512, 24 colores leídos
```

Es decir: **se puede leer el atlas base, rotarle el tono a las filas 0–3 con la curva de arriba, y asignárselo al blob del jugador — todo en caliente, sin subir nada y sin pasar por moderación.**

### Las dos vías, y cuándo usar cada una

|  | **Vía A — paleta en runtime** ⭐ | **Vía B — atlas subido** |
| --- | --- | --- |
| Qué es un color nuevo | **Tres números en **`GameConfig` | Un PNG generado, subido y moderado |
| Assets nuevos | **0** | 1 textura por color |
| Memoria de textura | 1 `EditableImage` por paleta **en uso** | 1 textura por color **existente** |
| Iteración | instantánea — cambiar un número y volver a entrar | subir, esperar indexado, reapuntar |
| Moderación | ninguna | cada PNG pasa por Roblox |
| Riesgo | API relativamente nueva; hay que medir en móvil | ninguno — **es lo que ya está en producción** |

**Recomendación: probar la vía A como primer experimento de la fase 0, porque si funciona en móvil el coste de arte de los 12 colores comunes de los tres mundos se va a cero.** Y la vía B se queda como fallback garantizado: ya hay dos texturas hechas por ese camino, funcionando en producción.

### ⚠️ Lo que hay que medir antes de casarse con la vía A

1. **Móvil de verdad.** `EditableImage` tiene su propio presupuesto de memoria y este proyecto **nunca ha cerrado una verificación en Android**. Es el hueco de siempre.
2. **Cuántas vivas a la vez.** 12 jugadores con 12 elementos distintos = 12 `EditableImage`. Hay que cachear **por elemento, no por jugador** — dos jugadores con el mismo elemento comparten imagen.
3. **El tamaño.** El atlas son 24 rectángulos planos; **no necesita 512²**. Se mantuvo ese tamaño en su día para no arriesgar sangrado entre celdas por filtrado bilineal, pero a 128² son **1/16 de la memoria**. Un test de una tarde decide si los 21 items caben en un pañuelo.
4. **Qué pasa al cambiar de personaje**, morir, viajar y reconectar. La imagen tiene que soltarse.

---

## 5. Los 7 items de cada mundo

### La pirámide de rareza es la pirámide de coste de producción

Esa coincidencia no es casualidad y conviene mantenerla: **lo más raro es también lo que más costó hacer**, así que el jugador está reconociendo trabajo real cuando le toca.

| Rareza | Nº | Qué es técnicamente | Coste | Peso (de §4.4 del doc de la máquina) |
| --- | --- | --- | --- | --- |
| **Común** | 4 | **Paleta.** Filas 0–3 recoloreadas. Nada más | casi nulo con la vía A | 18 % cada uno |
| **Raro** | 2 | **Elemento.** Paleta + `MaterialVariant` + perfil de emisores + `BoneMotion` | medio | 11 % cada uno |
| **Épico** | 1 | **Elemento + piezas.** Lo anterior más MeshParts soldados a los huesos | alto | 6 % |

### Propuesta de los 21

|  | **World 1 · Bosque** (base verde) | **World 2 · Desierto** (base naranja) | **World 3 · Lava** (base rojo) |
| --- | --- | --- | --- |
| **C** | Musgo | Arena | Ceniza |
| **C** | Miel | Terracota | Azufre |
| **C** | Savia | Oro | Obsidiana |
| **C** | Corteza | Turquesa | Magma |
| **R** | **Hoja** — mate, venas, aura de esporas, respiración lenta | **Vidrio de arena** — translúcido, reflectance alto, wobble cristalino | **Brasa** — emisión pulsante, *flicker* asimétrico en los huesos |
| **R** | **Rocío** — translúcido, gotas que caen, wobble líquido, se aplana al caer | **Cactus** — mate, huesos casi rígidos, *thump* pesado por paso | **Obsidiana fracturada** — negro con vetas que brillan al correr |
| **É** | **Micelio** — bioluminiscente, esporas, **hongos brotando de los huesos** | **Tormenta** — remolino de arena **orbitando** el cuerpo | **Fénix** — **alas de partículas + anillos orbitales** de fuego |

**Los 21 comparten silueta, rig, animación de caminar y cara.** Lo único que cambia es superficie, VFX y ritmo. Esa es la receta del documento de capacidades y es la que impide que 21 blobs se conviertan en 21 juegos distintos.

### Y el tema es del mundo, lo que convierte llevarlo a otro mundo en un flex

Un blob de Lava paseándose por el Bosque **ya funciona hoy** — es literalmente lo que `BlobSkinTravelsBetweenWorlds` existe para permitir, y la tabla de verificación de aquel día lo demuestra paso a paso. Los elementos heredan esa propiedad gratis: **son la prueba visible de que has estado donde el otro no ha llegado.**

---

## 6. Cómo ayudo yo — herramienta por herramienta

### Lo que puedo hacer solo, desde aquí

| Paso | Cómo |
| --- | --- |
| **Auditar** el estado real antes de tocar nada | `execute_luau` en solo lectura — es lo que hice para escribir §1 |
| **Montar el banco de pruebas**: duplicados de `Lvl01_b` / `Lvl04_b` / `Lvl08_b` en `ServerStorage` | `execute_luau` |
| **Calcular las paletas** (rotación de tono + curva perceptual, respetando filas 4 y 5) | Python aquí, fuera de Studio, con el atlas leído por `CreateEditableImageAsync` |
| **Aplicarlas** y verlas en el blob, sin subir nada | `EditableImage` + `Content.fromObject` (§4) |
| **Generar materiales PBR** (roca, hielo, corteza de lava) | `generate_material` → `MaterialVariant` |
| **Generar las piezas del épico** (cuernos, hongos, cristales) | `generate_mesh` / `generate_procedural_model` |
| **Escribir la tabla **`Elements`**, el servicio y el controlador** | `multi_edit`, `script_read`, `script_grep` |
| **Ver el resultado en movimiento** | `start_stop_play` → `character_navigation` → `screen_capture` |
| **Medir** | `execute_luau` sobre `Stats.PhysicsStepTimeMs`, `InstanceCount`, memoria por categoría |

### Lo que necesita a una persona, y conviene saberlo desde el principio

|  | Por qué |
| --- | --- |
| ⚠️ **Guardar y publicar el Place** | El MCP **no expone Save/Publish**. Es el paso que más veces se ha olvidado en este proyecto y aparece como pendiente en cinco documentos distintos |
| ⚠️ **Decidir dónde se construye** | **Studio está abierto ahora mismo en producción** (`95828455414780`). Existe el place laboratorio `123113535376730`. Yo no toco producción sin que lo digas |
| **Subir imágenes**, si se va por la vía B | `upload_image` solo acepta URLs http/https. Yo genero los PNG y te los dejo en tu carpeta; el import lo haces tú en el Asset Manager |
| ⭐ **El juicio visual** | Es la lección más dura de la sesión de VFX: *«el relleno estaba dentro de budget todo el rato. Lo que falló fue la composición, y eso sólo lo ve un ojo.»* Yo puedo decirte si cabe en presupuesto; no puedo decirte si se ve bien |

### ⚠️ Tres reglas de herramienta que evitan destrozos

1. `generate_texture`** no se usa sobre el cuerpo del blob. Nunca.** Reemplaza la fuente *in-place*, puede romper la jerarquía de huesos, y produce textura orgánica — lo contrario de un atlas de 24 celdas planas donde la fila 5 son los ojos. **Sí se puede usar sobre las piezas del épico**, que son MeshParts aparte y no están rigged.
2. **Las mallas de IA son para accesorios, jamás para el cuerpo.** El cuerpo tiene que conservar sus 8 huesos y sus 8 animaciones. Un accesorio soldado a un hueso no necesita rig.
3. **Backup antes de la primera escritura**, con nombre y fecha, como los seis `CosmeticVfxBackup_2026091*`. Es lo que permitió deshacer el mapeo invertido de texturas sin perder una sesión entera.

---

## 7. Presupuesto — nadie ha presupuestado **tres** cosméticos a la vez

Este es el riesgo que no está en ninguno de los documentos previos, y es real: en el estado final, un mismo personaje lleva **aura + estela + elemento de blob + la bola de objetos**, y los cuatro emiten a la vez, alrededor del mismo `Attachment Core`.

Lo que ya está medido y hay que respetar:

| Restricción | Número | De dónde sale |
| --- | --- | --- |
| Relleno de aura + estela a tope | **\~174 studs²** | `vfx-auras-trails` |
| La cámara vive a | **\~13 studs** del personaje, FOV 82 | ídem — una capa orientada a cámara de \>10 studs **envuelve la cámara** |
| Coste de una parte en la asamblea móvil | **\~1,4 µs / parte / paso de física** | `PROJECT_MEMORY`, medido |
| `Highlight` por cliente | **31 como máximo, sin API para subirlo** | ídem |
| Emisores ya en el place | 3.751 `ParticleEmitter` · 2.288 `Beam` · 626 `PointLight` | `BLOBS_CAPACIDADES_Y_VARIEDAD` |

### Las cuatro reglas que salen de ahí

1. **El elemento tiene su propio presupuesto de relleno y es el más pequeño de los tres.** Propuesta: **≤ 60 studs²** `[PH]`, contra los \~146 del aura tier 15. El elemento describe la superficie del blob, no compite con el aura por la silueta.
2. ⚠️ **Prohibido **`Highlight`**.** Un outline de color por elemento parece la forma obvia de hacer «obsidiana con vetas» y es exactamente lo que revienta el tope de 31: 12 jugadores + el highlight de foco de pickup + los blockers. **Las vetas se hacen con textura o con emisión, no con **`Highlight`**.**
3. ⚠️ `VisualScale`** del elemento infla el aura sin que nadie lo pida.** `CosmeticVfxController` escala los cosméticos midiendo `character:GetBoundingBox()` con `clamp(sqrt(ancho / 4,3), 1,0, 2,6)`. Un elemento que agrande el blob **agranda el aura con él**, y el pase de Eternal a 17 studs ya blanqueó la pantalla una vez. **El elemento no escala el cuerpo: eso es del tier.**
4. **Los emisores del elemento tienen que usar los nombres de capa que el LOD ya conoce** (`Body`, `Motes`, `Accent`/`Bolts`, `Orbit`, `Light`). `CosmeticVfxController` recorta **por nombre**, así que una capa que los respete entra en el LOD por distancia y por presupuesto de auras cercanas **sin tocar una línea de código**. Una capa con nombre nuevo cae en la prioridad 2 por defecto y nunca se recorta cuando debería.

### Y el épico es el único que toca física

Las piezas soldadas a los huesos son `BasePart` dentro de la asamblea del personaje, o sea el mismo impuesto permanente de **1,4 µs por parte y por paso** que ya se midió con la bola. Seis piezas × 12 jugadores = 72 partes extra en movimiento.

**Por eso el épico se hace con partículas y **`Beam`** siempre que se pueda, y con partes solo cuando la silueta lo exija.** Los anillos orbitales del Fénix son `Beam` entre `Attachment`s — que es exactamente como están hechas las órbitas de las auras tier 9+, y cuestan cero física.

---

## 8. ⚠️ El blob vive **dentro** de la bola

Nadie lo ha dicho en voz alta y condiciona el diseño de los 21 items:

```
Blob:               ~4,3 studs de ancho
Bola a 300 piezas:  13 studs de diámetro, +4,58 studs sobre el torso
```

**En el juego tardío el blob está enterrado.** Un cosmético que se lea solo por la silueta es un cosmético que el jugador compró y no ve.

### Las tres consecuencias de diseño

1. **La identidad de un elemento la llevan el color y los VFX, no el detalle de la superficie.** Los emisores salen del `Attachment Core` y se leen **fuera** de la bola. La textura fina no.
2. **Las piezas del épico tienen que vivir fuera del radio de la bola** — a \~7–9 studs, no pegadas al cuerpo. Los anillos del Fénix funcionan; unos cuernos de 1 stud sobre la cabeza no se verían jamás.
3. **Los comunes (paleta pura) son los que más sufren.** Un cambio de paleta con la bola llena se nota poco. Mitigación: que la paleta del elemento **tiña también **`ColorA`**/**`ColorB`** del aura de prestigio** — hoy el aura conserva el color base por decisión de diseño, y `blobs-color-por-mundo` §7.4 deja anotado que cambiarlo *«es solo *`ColorA`*/*`ColorB`* en las entradas derivadas»*.

### ⭐ Y la sinergia que sale gratis

**La máquina aspiradora vacía la bola.** O sea que **el momento en que el blob se ve mejor en toda la sesión es exactamente el segundo anterior al revelado del premio.**

Eso no hay que construirlo: está en la secuencia de §4.2 del documento de la máquina. Solo hay que **no desperdiciarlo**: la cámara del revelado tiene que encuadrar al blob desnudo, y si el premio es un elemento, aplicarlo **ahí mismo, en vivo, con la bola todavía vacía**. Es el mejor escaparate posible y ya está pagado.

---

## 9. Arquitectura

### 9.1 `GameConfig.WrapBlobs.Elements`

```
Elements = {
    Ember = {
        Rarity   = "Rare",
        World    = "World3",
        Palette  = { Hue = 8, SatScale = 1.18, ValueCurve = 1.9 },  -- filas 0-3. §3
        Material = { Base = Enum.Material.CrackedLava, Variant = "Ember_PBR" },
        Emitters = {                       -- MULTIPLICADORES sobre el tier, no valores absolutos
            Body   = { RateScale = 1.0, SizeScale = 1.0, LightEmission = 0.55 },
            Motes  = { RateScale = 1.4, Texture = "STAR", Drag = 0.2 },
        },
        BoneMotion = "flicker",            -- perfil del modulo cliente
        Sound      = "Feedback/Audio/StepEmber",
        FillBudget = 48,                   -- studs^2. Tope propio del elemento (§7)
    },
    -- ...
}

ElementDefaults = {                        -- lo que se ve sin elemento equipado: hoy
    World1 = "Base", World2 = "Base", World3 = "Base",
}
```

⚠️ **Derivar, no duplicar.** Si un elemento existe en los tres mundos, sus entradas se generan con un bucle desde una definición única — igual que las 16 entradas de `Prestige.ByTemplate` de W2 y W3. Escribirlas a mano deja copias del mismo balance que divergen en silencio la primera vez que alguien toca un rate.

### 9.2 Resolución

```ruby
-- Un solo sitio decide qué se ve. Punto de enganche: applyPrestige() en WrapBlobService.
local function resolveBlobLook(state)
    local wrapId   = effectiveBlobSkinId(state)            -- ya existe
    local template = GameConfig.WrapBlobs.TemplateByWrapId[wrapId]
    local tier     = GameConfig.WrapBlobs.Prestige.ByTemplate[template]
    local element  = GameConfig.WrapBlobs.Elements[state.BlobElementId]
                     or GameConfig.WrapBlobs.Elements[defaultFor(template)]
    return template, tier, element                          -- silueta, cuánto, qué
end
```

`effectiveBlobSkinId` ya valida que el wrap siga en el inventario y en el catálogo. **El elemento necesita exactamente la misma validación**: un `BlobElementId` que no se posee, o que ya no está en el catálogo, cae al default con un `warn`. Una sola regla, y no quedan estados imposibles.

### 9.3 `BlobMotionController` (cliente)

- Escribe `Bone.Transform` sobre `spine_01..05` + `Left`/`Right`, **componiéndose encima** de la animación de caminar, sin reemplazarla.
- ⚠️ **Aplicar por la izquierda sobre el **`CFrame`** authored, nunca acumulando.** Acumular deriva —es la lección exacta de las órbitas de las auras, donde acumular perdía el desfase que hacía que los arcos se cruzaran.
- ⚠️ **Un solo **`Heartbeat`** compartido** para todos los blobs, no uno por blob. Es el patrón que ya usan `AttachmentRenderer` y `stepOrbits`.
- **LOD por distancia**, con los mismos umbrales que los cosméticos (documentados como 80/150/240 studs, 45/85/140 en móvil — confirmar contra el controlador). El blob del jugador local nunca se recorta.
- Se registra **después de **`AttachmentRenderer`, como `CosmeticVfxController`, porque necesita el personaje ya montado.

### 9.4 Persistencia e integración con la máquina

| Campo | Dónde | Nota |
| --- | --- | --- |
| `OwnedCosmeticIds` | perfil, **ya especificado** en el doc de la máquina §6.4 | Cadena separada por comas — los atributos no admiten tablas |
| `BlobElementId` | perfil + atributo replicado | Vale `""` = sin elemento. Es lo que trae cualquier perfil anterior, así que la migración **es el comportamiento que el jugador ya conoce** |

`BlobSkinService` —que el doc de la máquina ya nombraba— es quien concede y equipa. El premio de la máquina es un id en `OwnedCosmeticIds` con `Kind = "BlobElement"`; equiparlo escribe `BlobElementId`. **Cero superficie nueva de red:** el patrón de `RequestWrap` (el cliente solo pide, el servidor decide si compra o equipa) se copia tal cual.

**Dónde se equipa:** la pestaña `BLOBS` del inventario — cuarta pestaña, mismo patrón de filas que `WRAPS`, detallada en §5 del documento de la máquina. Dos apuntes que salen de ahí y que tocan a este documento:

- ⭐ **La fila **`ORIGINAL`** es la única vía de quitarse un elemento** (`BlobElementId = ""`), y es exactamente el camino que el cortocircuito `AlreadyEquipped` bloqueó una vez con la piel (§2.2). **Hay que probarla explícitamente**, no asumirla.
- **El icono de cada fila es una silueta de blob en gris teñida con el **`ColorA`** del elemento**, así que un elemento nuevo no necesita arte de UI: lo hereda al declarar su paleta. Un `ViewportFrame` por fila queda descartado — 21 vistas 3D vivas en una lista que scrollea.

### 9.5 Casos borde

| Caso | Comportamiento correcto |
| --- | --- |
| Equipa un elemento y viaja de mundo | **Se conserva.** Es identidad, igual que la piel |
| Equipa un elemento y renace | **Se conserva.** `Cosmetics.ResetOnRebirth = false`, verificado hoy |
| Equipa un elemento y cambia de wrap | El elemento se **repinta** sobre la silueta nueva. Es la propiedad que hace que 7 rindan como 56 |
| `BlobElementId` apunta a algo que no posee | Cae al default con `warn`. Misma regla que `effectiveBlobSkinId` |
| Muere / respawnea con elemento puesto | El blob se reconstruye con el elemento. La `EditableImage` se reusa desde la caché **por elemento** |
| Dos jugadores con el mismo elemento | **Una sola **`EditableImage`** compartida.** Cachear por elemento, nunca por jugador |
| Un jugador ve el elemento de otro | El blob se crea en servidor y replica; la paleta en runtime es **cliente**, así que hay que aplicarla a los blobs remotos también. ⚠️ **Probarlo con 2 jugadores** — es el pendiente nº 6 que quedó abierto con la piel |

---

## 10. Fases

| # | Fase | Contenido | Criterio para pasar |
| --- | --- | --- | --- |
| **0** | **Decidir dónde y hacer backup** | Place laboratorio o producción con respaldo. `BlobElementsBackup_<fecha>` en `ServerStorage` | Escrito y acordado. **Studio está abierto en producción ahora mismo** |
| **1** | ⭐ **El test de la vía A** | Leer el atlas, recolorear filas 0–3 con la curva, aplicarlo por `EditableImage` a un duplicado, mirarlo | Se ve un blob de otro color **con los ojos intactos**. Decide si los comunes cuestan cero o cuestan un PNG cada uno |
| **2** | **Un elemento, tres siluetas** | `Ember` sobre `Lvl01_b`, `Lvl04_b` y `Lvl08_b`, en movimiento | **La apuesta entera del documento**: ¿se lee como el mismo elemento en los tres, y se distingue el tier? Si no, el modelo de capa no sirve y hay que saberlo aquí |
| **3** | **La tabla y el enganche** | `Elements`, `resolveBlobLook`, `BlobElementId`, validación, barrido de cortocircuitos (§2.2) | Equipar, viajar, renacer, morir y reconectar conservan el elemento |
| **4** | `BlobMotionController` | Perfiles de `BoneMotion`, Heartbeat compartido, LOD | 12 blobs con motion sin mover el frame time |
| **5** | **Los 7 de World 1** | 4 paletas + 2 elementos + 1 épico | Encaja con el pool de §4.4 del doc de la máquina |
| **6** | **Presupuesto** | Aura tier 15 + estela tier 15 + elemento + bola a 300, en **móvil** | El hueco de verificación de siempre. Sin esto no se publica |

### Lo que no se recorta

|  | Por qué |
| --- | --- |
| **El test de 2 jugadores** | La paleta en runtime es cliente. Si los blobs remotos no se pintan, el cosmético **no lo ve nadie más que tú** — y la mitad del valor de un cosmético es que lo vean |
| **Las filas 4 y 5 intactas** (§3) | Es la cara del personaje |
| **La prohibición de **`Highlight` (§7) | Falla en silencio y se lleva por delante marcas de otros sistemas |
| **La fase 2** | Es la que valida o tumba la idea entera, y cuesta una tarde |

---

## 11. Riesgos

| # | Riesgo | Gravedad | Mitigación |
| --- | --- | --- | --- |
| 1 | `EditableImage`** no rinde en móvil** y la vía A se cae | 🟠 alta | §4. Es la fase 1 precisamente para saberlo antes de diseñar 21 items encima. Fallback probado: la vía B ya está en producción |
| 2 | **La paleta no se aplica a los blobs remotos** y el cosmético solo lo ve su dueño | 🟠 alta | §9.5. Test con 2 jugadores; es el pendiente que la piel dejó abierto en septiembre |
| 3 | **Un elemento recolorea la fila 5** y el blob pierde la cara | 🟠 alta | §3. La función de recoloreo **recibe el rango de filas**, no la imagen entera. Test de píxel: 8 celdas de las filas 4–5 idénticas al original |
| 4 | **El elemento pisa la lectura de tier** y todos los blobs se ven iguales | 🟠 alta | §2.1. El elemento **multiplica**, nunca asigna. Fase 2 lo comprueba a ojo |
| 5 | **El aura se infla** porque el elemento agrandó el blob | 🟡 media | §7. El elemento no toca la escala del cuerpo |
| 6 | **Se usa **`Highlight` para las vetas del épico y se revienta el tope de 31 | 🟡 media | §7. Textura o emisión |
| 7 | **El épico mete 6 partes por jugador** en la asamblea móvil | 🟡 media | §7. `Beam` y partículas primero; partes solo si la silueta lo exige, y medido |
| 8 | **Un cortocircuito viejo deja el elemento pegado** | 🟡 media | §2.2. Es el bug del `AlreadyEquipped`, que ya pasó una vez con dos campos y ahora hay tres |
| 9 | **Los comunes no se notan** con la bola llena | 🟡 media | §8. La paleta tiñe también `ColorA`/`ColorB` del aura de prestigio |
| 10 | **Se publica sin guardar** | 🟡 media | El MCP no expone Save/Publish. Aparece como pendiente en cinco documentos del proyecto |

---

## 12. Qué hay que corregir en el documento de la máquina

`claude/residuo-aspiradora-cosmeticos-2026-09-18.md` queda actualizado con esto:

| § | Decía | Dice ahora |
| --- | --- | --- |
| **4.5** | *«Colores de blob → coste de arte casi nulo: un *`Color3`* + material»* | **Falso.** El color vive en un atlas de paleta; un color es una recoloración de las filas 0–3, por runtime (vía A) o por PNG subido (vía B). Barato y automatizable, pero no gratis |
| **4.5** | *«Blobs con silueta propia → malla nueva, coste alto»* | **No hay mallas nuevas.** Las 8 siluetas rigged son intocables; el épico **extiende** con piezas soldadas a los huesos |
| **4.6** | Las **variantes** como forma de estirar el pool en W2 y W3 | Siguen valiendo, y ahora tienen una implementación obvia: una variante es **otra rotación de tono sobre la misma paleta**, o sea el mismo mecanismo de §3 aplicado dos veces |
| **nuevo** | — | El revelado de un elemento debe ocurrir **con la bola ya vacía** (§8): es el único momento de la sesión en que el blob se ve entero |
