# Blobs — Capacidades técnicas y variedad alcanzable

> Documento de exploración, no de implementación. Revisión hecha sobre el place
> `+1 ¡TODO SE PEGA!` (placeId 95828455414780) vía MCP de Roblox Studio, en modo Edit.
> Estado: nada modificado. Todo lo de abajo está verificado contra el DataModel real.

---

## 1. Qué son los blobs hoy

**24 blobs** viven en `ReplicatedStorage.Assets.WrapBlobs` = **8 niveles × 3 mundos**
(`Lvl01..08_b`, `W2_Lvl01..08_b`, `W3_Lvl01..08_b`), mapeados a **30 wrapIds** distintos
a través de `GameConfig.WrapBlobs.TemplateByWrapId`.

Un blob **no es un mesh muerto**: es un `MeshPart` con esqueleto (skinned mesh).

```
Lvl08_b  (MeshPart, skinned)
├── root (Bone)
│   └── spine_01 → spine_02 → spine_03 → spine_04 → spine_05
│                                                    ├── Left
│                                                    └── Right
├── PrestigeVFX (Attachment)
│   └── PrestigeGlow (PointLight)
├── PrestigeAura  (ParticleEmitter)
├── PrestigeMist  (ParticleEmitter)   ← solo tiers altos
└── PrestigeBurst (ParticleEmitter)   ← solo tiers altos
```

Los niveles bajos (`Lvl01_b`) tienen cadena corta (`root → spine_01..04`) y solo
`PrestigeAura`. Los niveles altos añaden `spine_05` + `Left`/`Right` y dos emisores más.

Atributos por blob (ejemplo real de `W3_Lvl08_b`):

```
PrestigeTier = 8              PrestigeTitle = "TRANSCENDENT"
PrestigeVisualScale = 1.17    PrestigeBaseSize = (7.60, 10.26, 6.12)
BlobLevel = 8                 BlobWorld = "W3"
BlobBaseTemplate = "Lvl08_b"  SkeletalSourceModel = "SK_Glue_Lvl_08"
SkeletalAnimationTier = 8     TemplateName = "W3_Lvl08_b"
```

### 1.1 El look ya está dirigido por datos

Esto es lo más importante del hallazgo: **la arquitectura para hacer docenas de blobs
distintos ya existe**. Solo está siendo usada para "prestigio" en vez de para "elementos".

`GameConfig.WrapBlobs.Prestige.ByTemplate` tiene **11–13 knobs por blob**:

| Knob | Ejemplo `Lvl01_b` | Ejemplo `W3_Lvl08_b` |
|---|---|---|
| `ColorA` | `0.72, 1.00, 0.59` | `1.00, 0.80, 0.22` |
| `ColorB` | `1, 1, 1` | `1.00, 1.00, 0.92` |
| `AuraRate` | `0.8` | `10` |
| `ParticleSize` | `0.22` | `0.68` |
| `LightBrightness` | `0` | `0.9` |
| `LightRange` | `0` | `12` |
| `VisualScale` | `1` | `1.17` |
| `MistRate` | — | `6` |
| `MistTemplate` | — | `aura_eternal` |
| `EquipBurstCount` | `4` | `42` |
| `AccentBurstCount` | `0` | `14` |
| `Tier` / `Title` | `1` / `FRESH` | `8` / `TRANSCENDENT` |

Además `GameConfig.WrapBlobs.Movement.AnimationByTemplate` mapea cada template a una de
**8 animaciones** (`AN_Glue_Lvl_01..08_Move`) en `ReplicatedStorage.Assets.WrapBlobAnimations`,
con playback atado a la velocidad del Humanoid (`MinPlaybackSpeed 0.65` → `MaxPlaybackSpeed 1.75`,
`MovementThreshold 0.1`, `FadeSeconds 0.12`).

El punto de entrada para cualquier variación visual es `applyPrestige()` en
`ServerScriptService.Server.WrapBlobService` (~1.313 líneas).

---

## 2. Lo que SÍ se puede hacer

### 2.1 Animarlos — sí, por dos vías

- **Animación procedural por huesos** (`Bone.Transform` desde el cliente, sobre la cadena
  `spine_01..05` + `Left`/`Right`). Habilita: wobble gelatinoso, squash & stretch al saltar,
  respiración en idle, latido, "derretirse" al parar, temblor, inflarse al recoger.
  Se compone **encima** de la animación de caminar existente, sin reemplazarla.
- **Control del playback existente**: velocidad, fade, blending, ya conectado a la velocidad
  del personaje.

### 2.2 VFX por blob — sí, y es lo más barato

Creables y configurables por código: `ParticleEmitter` (Shape, Squash, Drag, Acceleration,
FlipbookLayout, EmissionDirection, Orientation, LightEmission…), `Trail`, `Beam`,
`Highlight` (outline de color), `PointLight`, `SurfaceLight`, `Sparkles`, `Smoke`, `Fire`,
atmósfera local, distorsión de cámara, shake, sonido posicional.
Todos atables a eventos: equipar, correr, saltar, recoger, subir de tier.

### 2.3 Color, texturas y materiales

| Qué | Cómo | Coste |
|---|---|---|
| Color / tinte | `Part.Color`, `Transparency`, `Reflectance` | instantáneo, gratis |
| Material PBR nuevo | `generate_material` (IA) → `MaterialVariant` | minutos |
| Textura nueva del mesh | `generate_texture` (IA, prompt o imagen de referencia) | minutos |
| `SurfaceAppearance` (Color/Normal/Roughness/Metalness) | manual, requiere imágenes subidas | requiere assets |
| Traer texturas/meshes del Creator Store o inventario | `search_asset` + `insert_asset` | rápido |

Hoy los blobs usan solo `TextureID` + `Color` + `Material.SmoothPlastic`, sin
`SurfaceAppearance` y sin `MaterialVariant`. Hay margen entero ahí.

### 2.4 Tamaño y proporción — control total

`Size`, escala no uniforme (aplastado, alargado, gigante), `PivotOffset`, y **escala por hueso**
(cabezón, base ancha, punta fina).

⚠️ El servicio ya recalcula `PrestigeBaseSize × VisualScale` y ajusta el offset vertical
(`part.CFrame += Vector3.new(0, verticalGrowth * 0.5, 0)` en displays). Hay que entrar por ahí
y no pisar ese cálculo.

### 2.5 Estructura

- **Añadir piezas**: cuernos, ojos, burbujas, cristales, anillos orbitando → MeshParts o
  primitivas soldadas a los huesos. `segment_mesh` puede partir un blob existente en hasta
  5 piezas nombradas.
- **Mallas nuevas desde cero**: `generate_mesh` / `generate_procedural_model` (prompt o imagen).
- **Verificación visual**: `screen_capture`, y se puede entrar en Play, mover el personaje
  y capturar para confirmar el resultado en movimiento.

---

## 3. Lo que NO se puede (límites reales)

1. **No se pueden subir animaciones keyframe nuevas.** No existe tool de upload de animación;
   el Animation Editor es trabajo manual. → La animación procedural por huesos cubre
   prácticamente todo lo que se quiere para blobs, y no consume uploads.
2. **Un mesh generado por IA no viene rigged.** Un blob nuevo desde prompt pierde las 8
   animaciones de movimiento.
   **Regla de oro: reusar las 8 siluetas rigged existentes como base** y variar todo lo demás.
   Ahí es exactamente donde se conserva "la esencia de blob".
3. **`generate_texture` reemplaza la fuente in-place.** Hay que probarlo sobre un duplicado
   antes de tocar un asset real, para confirmar que no destruye la jerarquía de huesos.
4. **No se generan imágenes 2D desde prompt** (solo retexturizado de meshes o materiales PBR).
5. **Presupuesto de performance.** El place ya contiene:

   | Clase | Instancias |
   |---|---|
   | ParticleEmitter | 3.751 |
   | Beam | 2.288 |
   | SurfaceAppearance | 2.120 |
   | PointLight | 626 |
   | Highlight | 192 |
   | Trail | 91 |
   | MaterialVariant | 10 |

   `GUIA_SISTEMA_BOLA_Y_ARTE_MOBILE.md` fija el principio **"bola infinita, coste finito"**.
   Los blobs locos se hacen con *pocos emisores bien diseñados*, no con 12 cada uno.
   Los blobs ya vienen optimizados para mobile: `CastShadow=false`, `CanCollide=false`,
   `CanQuery=false`, `CanTouch=false`, `Massless=true`. Eso no se toca.

---

## 4. Los 7 ejes de variedad

| Eje | Rango disponible |
|---|---|
| **Silueta** | 8 siluetas base rigged × piezas añadidas (cuernos, ojos, orbitales) |
| **Escala** | global + por hueso: enano/gigante, aplastado, alargado, cabezón |
| **Superficie** | color, textura IA, material PBR, transparencia, reflectance, emisión |
| **VFX** | aura, mist, burst, trail, beam, highlight, luz, distorsión, atmósfera |
| **Movimiento** | wobble, squash&stretch, respiración, latido, temblor, derretirse, rebote |
| **Audio** | sonido de paso, de equipar, ambiente propio |
| **Reacción** | qué hace al recoger / saltar / correr / subir de tier |

---

## 5. Ejemplo: fuego / agua / tierra

### 🔥 Fuego
- **Superficie:** naranja-rojo, reflectance bajo, emisión alta, textura de carbón agrietado con vetas brillantes.
- **VFX:** aura de chispas ascendentes + humo negro tenue; trail de brasas al correr.
- **Luz:** PointLight parpadeante (ruido aplicado a `Brightness`).
- **Movimiento:** *flicker* rápido y asimétrico en los huesos, más rápido cuanto más corre; se encoge y estalla al saltar.

### 💧 Agua
- **Superficie:** `Transparency ≈ 0.35`, reflectance alto, material Glass/Ice.
- **VFX:** gotas que caen (`Acceleration` negativa) + salpicadura al aterrizar; decal de charco al detenerse.
- **Luz:** azul suave y estable.
- **Movimiento:** wobble lento y amplio (inercia líquida); se aplana al caer y rebota dos veces.

### 🪨 Tierra
- **Superficie:** opaco, material Rock/Slate, textura de roca con musgo.
- **VFX:** casi sin partículas (barato); polvo al caminar + piedritas orbitando.
- **Luz:** ninguna.
- **Movimiento:** huesos casi rígidos, "thump" pesado por paso, screen-shake mínimo; al saltar cae seco, sin rebote.

**Los tres comparten silueta, rig y animación de caminar → siguen leyéndose como blobs.**
Lo que cambia es superficie + VFX + ritmo de movimiento. Esa es la receta para hacer 30
sin romper la identidad.

---

## 6. Arquitectura propuesta

Extender `GameConfig.WrapBlobs` con una tabla `Elements` paralela a `Prestige.ByTemplate`:

```lua
Elements = {
    Fire = {
        Palette    = { ColorA = ..., ColorB = ... },
        Material   = { Base = Enum.Material.CrackedLava, Variant = "..." },
        Emitters   = { Aura = {...}, Mist = {...}, Trail = {...} },
        BoneMotion = "flicker",   -- perfil de animación procedural
        Sound      = "...",
    },
    Water = { ... },
    Earth = { ... },
}

ElementByWrapId = {
    W3_EmberGlue = "Fire",
    W2_OasisGlue = "Water",
    -- ...
}
```

Ventajas:

- **Un blob nuevo = una fila de datos.** Cero código nuevo por variante.
- Se **combina** con el tier de prestigio existente → 8 tiers × N elementos.
- El enganche es un solo punto: `applyPrestige()` en `WrapBlobService`.
- Los perfiles de `BoneMotion` son un módulo cliente aparte, reutilizable entre elementos.

---

## 7. Siguientes pasos posibles

1. **Prototipo de un solo blob elemental** en Studio (duplicado, sin tocar los assets reales),
   para validar en movimiento antes de definir la lista completa. ← recomendado
2. Test aislado de `generate_texture` sobre un duplicado, para confirmar si preserva los huesos.
3. Definir la lista completa de elementos y su asignación a los 30 wrapIds.
4. Medir el coste de los emisores propuestos contra el presupuesto de `PLAN_PERFORMANCE.md`.
