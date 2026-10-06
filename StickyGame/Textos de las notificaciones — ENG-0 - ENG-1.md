# Textos de las notificaciones — ENG\-0 / ENG\-1

## 1. Las seis entradas del catálogo

### `rebirth_celebration` · Hero · Priority 90

El frame que hoy dice `0 Stickiness`. Celebra lo ganado y nombra lo siguiente.

| Campo | Texto |
| --- | --- |
| `Headline` | `{multiplier}x STICKINESS!` |
| `Subline` | `NEXT BLOCKER: {required}` |

```
                    7.9x STICKINESS!
                   NEXT BLOCKER: 350
```

*Glosa: «¡7,9× de Stickiness! Siguiente blocker: 350».*

> **El parámetro es un número, no un nombre.** Los blockers se llaman todos `Blocker` a propósito (§6), así que `NEXT BLOCKER: TOY CHEST 0 / 350` no aportaría nada y el `0` es redundante — justo después de un Rebirth la Stickiness siempre es 0. Lo único informativo es **cuánto falta**.

> El multiplicador es lo que **acaba de ganar**; la Stickiness en `0` es lo que acaba de perder. Enseñar primero lo ganado es el ticket entero.

**Alternativas si **`{multiplier}x`** se lee raro:** `REBIRTH {multiplier}x!` · `NOW {multiplier}x STICKIER!`

---

### `offline_claim` · Card · Priority 70

Al volver, cuando hay algo esperando.

| Campo | Texto |
| --- | --- |
| `Title` | `WHILE YOU WERE AWAY` |
| `Message` | `Your blob kept collecting. You got {objects} objects!` |
| Botón | `COLLECT` |

*Glosa: «Mientras no estabas — tu blob siguió recogiendo. ¡Tienes 2.880 objetos!»*

---

### `offline_promise` · Card · Priority 60 · `Once = true`

**La más importante de las seis.** Es la única que se ve **antes** de irse, y es lo único que hoy le dice a un jugador nuevo que vale la pena volver mañana.

| Campo | Texto |
| --- | --- |
| `Title` | `YOUR BLOB NEVER STOPS` |
| `Message` | `It keeps collecting after you leave, up to 8 hours. Come back tomorrow for {objects} objects!` |

*Glosa: «Tu blob nunca para — sigue recogiendo después de que te vayas, hasta 8 horas. ¡Vuelve mañana por 2.880 objetos!»*

> `Come back tomorrow`** es la frase que justifica el ticket.** Si se recorta el mensaje, esa parte no se toca.

---

### `favorite_prompt` · Card · Priority 40 · `Once = true`

| Campo | Texto |
| --- | --- |
| `Title` | `LIKE THE GAME?` |
| `Message` | `Tap the Roblox logo and hit ⭐ Favorite so you can find us again!` |

*Glosa: «¿Te gusta el juego? Toca el logo de Roblox y dale a ⭐ Favorito para encontrarnos otra vez».*

> **Verificar el ⭐ en una captura antes de publicar.** Está documentado en `PROJECT_MEMORY.md`: 🫧 salía como hueco en blanco con FredokaOne mientras 👑 🏆 👟 ⚡ ✨ 🔁 💧 se pintaban bien. Un emoji que falta **no da error ni warning**: solo deja la frase coja.
> 
> **Versión sin emoji, por si acaso:** `Tap the Roblox logo and hit Favorite so you can find us again!`

---

### `charm_unlocked` · Toast · Priority 30

| Campo | Texto |
| --- | --- |
| `Message` | `{charmName} unlocked!` |

*Glosa: «¡Sticky Sprout desbloqueado!»*

---

### `world_unlocked` · Hero · Priority 85

| Campo | Texto |
| --- | --- |
| `Headline` | `{worldName} UNLOCKED!` |
| `Subline` | `GO THROUGH THE PORTAL` |

*Glosa: «¡Desierto desbloqueado! Cruza el portal».*

> La `Subline` no es decorativa: sin ella el jugador se queda sin saber **qué hacer ahora**, que es justo el problema que tiene el juego al cerrar cada bucle.

---

## 2. El "Don't Leave Yet" — es una escalera, no una frase

El sistema ya existe y ya funciona en móvil. Lo que hay que cambiar es **qué ofrece**: hoy da un regalo genérico. Debe ofrecer **lo que el jugador está dejando a medias**, con su nombre y su reloj.

Por eso son tres mensajes con prioridad, no uno. El servidor elige el primero que aplique:

|  | Condición | `Title` | `Message` |
| --- | --- | --- | --- |
| **1** | Le falta **menos del 25 %** para el siguiente blocker | `ALMOST THERE!` | `You're {remaining} away from the next blocker. Stay and break it!` |
| **2** | Falta **menos de 5 min** para un hito de Playtime Rewards | `{time} TO GO!` | `Your next Playtime Reward is almost ready. Don't lose it!` |
| **3** | Ninguna de las anteriores | `YOUR BLOB KEEPS GOING` | `It collects while you're away — up to 8 hours. Your daily reward resets in {time}.` |

| Botón | Texto |
| --- | --- |
| Quedarse | `KEEP PLAYING` |
| Irse | `LEAVE` |

*Glosas: 1 «¡Casi! Te faltan 400 para el cofre de juguetes. Quédate y rómpelo». · 2 «¡2:30 y ya! Tu siguiente premio de Playtime está casi listo. ¡No lo pierdas!» · 3 «Tu blob sigue — recoge mientras no estás, hasta 8 horas. Tu premio diario se reinicia en 14:32».*

> El caso **1** es el más fuerte de los tres y el más barato: el dato ya está en pantalla, en `BlockerProgress`. Un jugador al que le faltan 400 de 350 tiene una razón concreta para no irse, y es la única versión de este pop-up que no suena a súplica.

---

## 3. La notificación de Roblox (ENG-1) — 99 caracteres, límite duro

Es lo único que el jugador va a ver **fuera del juego**. Va en el notification string asset del Creator Dashboard.

**Recomendada — el número primero:**

```
{objects} objects are waiting! Your blob kept collecting while you were away.
```

`73 caracteres` con `{objects} = "2,880"`. Deja margen para un número de hasta \~25 caracteres, que cubre hasta la escala de Lava (`1.79Qa`).

*Glosa: «¡Te esperan 2.880 objetos! Tu blob siguió recogiendo mientras no estabas».*

**Alternativa, si se prefiere la frase completa antes del número:**

```
Your blob collected {objects} objects while you were away!
```

`55 caracteres`.

> **Por qué el número primero:** una notificación se lee en la pantalla de bloqueo, de reojo y truncada. La cifra es la recompensa; ponerla al final es tirarla.

**Tres reglas para este texto, porque no se puede corregir en caliente:**

1. **Contar los caracteres con el número más largo posible**, no con `{objects}`.
2. **No prometer nada que el juego no entregue en el primer frame.** Si dice 2.880 objetos, al entrar tiene que haber 2.880.
3. Solo un tiro al día por jugador. Este es el mensaje.

---

## 4. Presupuesto de caracteres por campo

Aproximado, para que diseño no escriba algo que no cabe. Medido sobre teléfono en horizontal.

| Campo | Máximo cómodo | Máximo absoluto |
| --- | --- | --- |
| Hero `Headline` | 24 | 30 |
| Hero `Subline` | 32 | 40 |
| Card `Title` | 24 | 30 |
| Card `Message` | 90 | 120 |
| Card botón | 10 | 14 |
| Toast `Message` | 40 | 55 |
| Notificación de Roblox | — | **99 (duro)** |

**Prueba siempre con la versión más larga real.** Un texto que solo funciona corto no sirve: el `{objects}` de un jugador de Lava tiene el doble de dígitos que el de uno de Forest.

---

## 5. Reglas de estilo para esta audiencia

El juego se muestra a **menores de 13 desde el 9 de septiembre**, y la mayoría de Roblox no tiene el inglés como lengua materna.

| Sí | No |
| --- | --- |
| Frases de menos de 12 palabras | Subordinadas |
| Verbo al principio (`Tap`, `Come back`, `Stay`) | Voz pasiva |
| El número como protagonista | El número escondido al final |
| Palabras del juego que ya conocen (`blob`, `collect`, `stick`, `objects`, `Rebirth`) | Vocabulario nuevo |
| Una idea por mensaje | Dos cosas a la vez |
| Ironía cero | Chistes que dependen del idioma |

---

## 6. Los blockers se llaman `Blocker`, y está bien

`GameConfig.BlockerDisplayName` vale `"Blocker"`** en las 30 zonas. Es deliberado, no una pasada de contenido pendiente.** `ToyChest`, `Bed` y `Refrigerator` son **nombres placeholder** del prototipo; el arte no es definitivo y del 4 al 10 son arcos genéricos del kit (`SM_Level_1_Gate_01`).

**Nombrarlos ahora sería peor que no nombrarlos:** un cartel que dice `TOY CHEST` delante de un arco de piedra le enseña al jugador algo que no está viendo. Es el mismo tipo de error que corregir `BlockerDisplayName` "por completitud" — se arregla cuando exista el arte, no antes.

> **Corrección a documentos anteriores.** El `claude/eng-sprint-d1-2026-09-15.md` §6.2 decía que `BlockerDisplayName` «necesita una pasada de contenido de diseño». **No la necesita.** Queda corregido allí.

Consecuencia para los textos de esta página:

| Antes | Ahora |
| --- | --- |
| `NEXT: {nextGoal}` con nombre y progreso | `NEXT BLOCKER: {required}` — solo el número |
| `You're {remaining} away from {nextGoal}` | `You're {remaining} away from the next blocker` |

Y el `BlockerProgress` del HUD (ENG-2 §6.2) ya dice `BLOCKER 9,400 / 30,000`, que es correcto tal cual. **No hay nada que escribir ahí.**

### Cuando exista el arte

Ese es el momento de volver. Y conviene hacerlo bien de una vez:

- Los nombres deberían entrar como **claves de localización**, no como strings a mano — `PROJECT_MEMORY.md` ya lo señala.
- Un blocker con nombre propio y silueta reconocible es lo que vende el género. El `claude/plan-trailer-2026-09-09.md` lo tiene como el *money shot*: **rojo → farmeo → verde → absorción**, y que el blocker quede pegado a la bola. Hoy esa historia existe en el gameplay pero no en el nombre.

---

## 7. Dos parámetros más que conviene confirmar

Mismo criterio que los blockers: **si el nombre es placeholder, no se enseña.**

| Parámetro | Valor actual | ¿Es definitivo? |
| --- | --- | --- |
| `{worldName}` | `Forest`, `Desert`, `Lava` | Parecen definitivos (están en `GameConfig.Worlds` y en las specs de los tres mundos). **Confirmar** |
| `{charmName}` | `StickySprout`, `CozyPillow`, `TinyMagnet`, `LuckyCoin`, `RenewalSeed` | Parecen definitivos. **Confirmar** |

Si alguno resulta ser placeholder, los repuestos son:

- `world_unlocked` → `Headline: WORLD {n} UNLOCKED!`
- `charm_unlocked` → `Message: New charm unlocked!`
