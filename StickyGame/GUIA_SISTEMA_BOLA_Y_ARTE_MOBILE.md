# Guía rápida — Bola pegajosa y arte mobile-first

**Proyecto:** Exposición Pegajosa / Sticky Game  
**PlaceId:** `95828455414780`  
**Última actualización:** 2026-08-13  
**Principio:** **bola infinita, coste finito**.

> La cantidad recogida debe sentirse siempre creciente, pero nunca debe equivaler a la cantidad de
> piezas físicas o renderizadas. El contador, el historial lógico y la presentación visual tienen
> presupuestos distintos.

## 1. Estado actual del sistema

### Vigente y probado en Studio

- El servidor conserva hasta **300 records lógicos** por jugador.
- El servidor no crea geometría, parts ni welds cosméticos para la bola.
- Cada cliente muestra hasta **110 proxies propios** y **20 por jugador remoto cercano**.
- El cliente tiene un techo de **320 proxies creados** y un máximo teórico de 250 activos con ocho
  jugadores (`110 + 7 × 20`).
- Los remotos se muestran a 90 studs y se ocultan a 110 studs, evaluados a 4 Hz.
- Cada proxy authored contiene exactamente una `BasePart`; hay 29 plantillas actuales.
- Los proxies no colisionan, no reciben touch/query, no proyectan sombra y son `Massless`.
- Un stress de 300 altas a ~96/s terminó estable en 110 parts y 110 welds locales, sin geometría
  cosmética en servidor.

Los presupuestos `110`, `20`, `320` y las distancias `90/110` siguen siendo
**`[PLACEHOLDER]` hasta certificar ocho jugadores en Android low-end**. Además, estos cambios están
en el DataModel abierto y todavía requieren guardar/publicar manualmente el Place.

### Implementado; pendiente de prueba manual de gameplay

Esta última capa ya está creada en el DataModel de Studio:

1. `TotalCollectedThisRebirth`: contador autoritativo y persistente que sigue creciendo después de
   los 300 records y solo vuelve a cero al hacer Rebirth.
2. `PileCollectedCount`: ordinal de la bola actual; vuelve a cero cuando la pila se limpia por
   muerte, Replay, pedestal o Rebirth.
3. Crecimiento Katamari por capas: mantiene el tamaño de cada objeto y aumenta gradualmente el
   radio ocupado por objetos nuevos, sin reubicar o resoldar toda la bola.
4. Detección de recogida por barrido a alta velocidad y validación equivalente con posiciones
   observadas por el servidor; el cliente nunca envía los extremos del segmento.
5. Vuelo adaptativo: duración de `0,30 s` a baja velocidad, hasta `0,08 s`, y colocación inmediata
   desde `60 studs/s`.
6. `ObjectCounter` y `PulseScale` authored en `StarterGui.StickyHUD.CounterStack`.
7. Las 20 salas authored muestran 32 objetos simultáneos, con techo de renderer de 60.

El Place pasó un smoke test de arranque sin errores de sintaxis o inicialización. La suite de
gameplay, Android low-end, MicroProfiler, guardado y publicación queda a cargo del desarrollador.

## 2. Lo que entiende el jugador

- Cada recogida cuenta, aunque la bola ya esté visualmente llena.
- La bola se ve densa pronto y continúa creciendo de forma legible por capas.
- Al llenarse el presupuesto visual, un objeto nuevo reemplaza a uno antiguo; no se añade otra
  pieza móvil.
- Los blockers y records marcados como protegidos permanecen visibles; el tamaño por sí solo no
  concede protección.
- Una aura de velocidad no cambia las reglas ni vacía la fantasía: recoge lo atravesado y resume
  la celebración con un efecto agregado.

La gratificación viene de cuatro señales simultáneas, no de 300 cuerpos físicos:

1. número que siempre sube;
2. silueta cada vez mayor;
3. objetos nuevos visibles en la superficie;
4. sonido/VFX agregado que aumenta de intensidad con rachas e hitos.

## 3. Los tres presupuestos

| Capa | Para qué sirve | Presupuesto | Qué ocurre al llenarse |
| --- | --- | --- | --- |
| Contador de Rebirth | Gratificación acumulada | `TotalCollectedThisRebirth`, saturación visual/configurable en 1.000.000 | No se pierden pickups ni progreso; solo se limita el número mostrado |
| Ring lógico del servidor | Snapshot y reconstrucción reciente | 300 records | Sale el normal más antiguo; `TotalCollectedThisRebirth` continúa |
| Ordinal de pila | Crecimiento de la bola visible actual | `PileCollectedCount`, máximo configurable 1.000.000 | Se reinicia al limpiar la bola |
| Presentación visual cliente | Silueta Katamari con coste acotado | Propio 110, remoto 20 | Entra el nuevo y se recicla un proxy existente |

No usar `LogicalAttachmentCount` como récord total: hoy representa cuántos records sobreviven en
el ring y, por diseño, llega como máximo a 300. El contador de corrida objetivo debe ser una cifra
separada y autoritativa.

### Orden de reemplazo

1. Conservar blockers u objetos protegidos mientras exista capacidad.
2. Conservar los objetos normales más recientes: son los que el jugador acaba de reconocer.
3. Reemplazar el normal más antiguo cuando entra uno nuevo y ya hay 110 propios.
4. Al reducir la presentación remota a 20, usar el mismo principio: protegidos primero, recientes
   después.
5. Si todos los records disponibles son protegidos, no sacrificar silenciosamente un blocker: ese
   caso debe probarse manualmente antes de producir contenido que pueda superar el presupuesto.

El reemplazo debe reutilizar el modelo del pool. No destruir y clonar en cada pickup, y nunca
crecer tablas o colas sin límite.

## 4. Silueta Katamari por capas

El tamaño aparente no debe depender linealmente del número de parts. Con 110 proxies se puede
comunicar una bola mucho mayor si la distribución ocupa bien el volumen.

### Distribución recomendada

- Usar una distribución determinista casi uniforme —por ejemplo, espiral/Fibonacci— para evitar
  anillos y huecos evidentes.
- Comprimir un poco el eje vertical para proteger cámara y lectura del avatar.
- Mantener una ventana frontal superior alrededor de cabeza/cámara.
- Orientar cada pieza de manera determinista, con la cara reconocible hacia fuera cuando aplique.
- Reservar piezas grandes o de silueta fuerte como landmarks; no llenar todo con ruido pequeño.
- Permitir interpenetración visual: los proxies no tienen colisión y no ensanchan la cápsula del
  personaje.

### Capas de crecimiento implementadas

| Momento de corrida | Lectura buscada | Tratamiento |
| --- | --- | --- |
| 0–24 | “Ya se está pegando” | Núcleo compacto, objetos separados y reconocibles |
| 25–109 | “Estoy formando una bola” | Llenar superficie y cerrar huecos |
| 110–299 | “La bola está grande” | Presupuesto lleno; reemplazo continuo en la capa exterior |
| 300–999 | “Sigue creciendo” | Los objetos nuevos nacen más afuera; los antiguos migran al reciclarse |
| 1.000+ | “Modo gigante” | Escala radial máxima de 1,75; coste estable |

No ejecutar un “growth step” que recorra, escale y vuelva a soldar los 110 objetos. El cambio de
radio se aplica solamente al proxy que entra o se recicla. Tras aproximadamente un presupuesto
completo de pickups, toda la superficie habrá migrado al nuevo tamaño sin un pico de CPU.

Mantener el tamaño individual actual de los props. La escala radial progresa de `1,0` a `1,75`
entre los ordinales 1 y 1.000, con exponente `0,55`. Solo cambia el `CFrame` radial del proxy que
entra; nunca se llama `ScaleTo` para hacer crecer los objetos ni se reconstruyen los 110 existentes.

## 5. Auras y velocidad alta

Moverse rápido no aumenta el número de welds: el límite de 110 propios sigue protegiendo el coste
base. Los riesgos nuevos son otros:

- **Tunneling:** cruzar un collectible entre dos ticks del sensor.
- **Ráfaga de animaciones:** muchos objetos intentando volar hacia una raíz que ya avanzó.
- **Carga de mundo/streaming:** entrar antes a regiones todavía no disponibles en el cliente.
- **Picos visuales:** particles, trails y sonidos emitidos una vez por cada objeto de la ráfaga.
- **Abuso:** confiar en posiciones o segmentos enviados por el cliente.

### Solución implementada; pendiente de validación manual

- El cliente prueba distancia contra el **segmento** entre la posición anterior y actual del
  `HumanoidRootPart`, no solo contra el punto actual.
- Limitar cada barrido a 24 studs. Un salto mayor invalida el historial y usa solamente la posición
  actual; nunca recorre una distancia arbitraria.
- El servidor muestrea a `0,05 s` y valida contra su propio segmento reciente de hasta `0,20 s`; no acepta
  endpoints proporcionados por el cliente.
- Conservar rate limit, requisito de Stickiness, estado de objeto y ownership como validaciones
  independientes.
- Reducir la duración desde `0,30 s` a partir de `32 studs/s`, hasta `0,08 s`, y hacer colocación
  inmediata desde `60 studs/s`.
- Conservar el límite actual de 24 vuelos simultáneos; las entradas extra se colocan directamente.
- Usar **un solo** trail/emitter de aura por jugador y agrupar pickups de una ventana corta en un
  burst. No adjuntar particle, light, trail ni sonido persistente a cada proxy.
- La aura nunca debe disparar un resize/re-weld global de la bola.

El test de seguridad obligatorio es atravesar un objeto a velocidad autorizada y recogerlo, pero
rechazar el mismo request tras un teletransporte fuera del barrido máximo.

## 6. Contrato para arte

Cada tipo recogible tiene dos representaciones. No reutilizar automáticamente el modelo rico del
suelo como proxy pegado.

### A. Modelo de suelo

Es la versión que el jugador inspecciona antes de recoger.

- Debe ser una plantilla authored visible en el DataModel, con ID registrado en configuración.
- Objetivo de 1–3 `BasePart` por prop `[PLACEHOLDER]`; preferir una sola cuando la silueta lo
  permita.
- Objetivo de 300–1.200 triángulos y techo de 1.500 `[PLACEHOLDER]`.
- Sin `Script`, `LocalScript`, `Humanoid`, constraints activos ni loops propios.
- Si no necesita física: anchored, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`.
- Labels, selección y feedback pertenecen al sistema compartido, no a cada prop.
- Puede conservar más detalle que el proxy, pero debe compartir mesh/textura cuando sea posible.

### B. Proxy de attachment

Es la versión multiplicada sobre personajes y, por tanto, el contrato duro.

- Ruta: `ReplicatedStorage.Assets.AttachmentProxies`.
- Un `Model` authored por ID registrado; exactamente **una** `BasePart` o `MeshPart` y una
  `PrimaryPart` válida.
- Objetivo de 80–250 triángulos; techo de 350 `[PLACEHOLDER]`.
- `Anchored=false`, `Massless=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false` y
  `CastShadow=false`.
- Para `MeshPart`: `CollisionFidelity=Box` y `RenderFidelity=Performance`.
- Cero constraints, attachments decorativos, bones, skinned meshes, humanoids, lights, particles,
  trails, beams, decals, guis o scripts dentro de la plantilla.
- Transparencia solamente 0 o 1. Evitar por completo capas parcialmente transparentes.
- Un material y una textura compartidos; `SurfaceAppearance` solo si es imprescindible y usando
  exactamente el mismo asset compartido.
- El renderer crea el weld técnico y administra el pool; arte no agrega lógica runtime.
- Si falta una plantilla o viola el contrato, el registry debe fallar explícitamente. No crear un
  cubo de fallback por código.

Los objetivos de triángulos son presupuestos internos, no límites documentados por Roblox, y por
eso permanecen `[PLACEHOLDER]` hasta medir arte representativo en el dispositivo base.

## 7. Variedad visual sin pagar por assets únicos

### Catálogo recomendado

- **8–12 tipos base por sala** `[PLACEHOLDER]`.
- **24–32 siluetas base en lanzamiento** entre todas las salas `[PLACEHOLDER]`.
- Obtener **48–64 variantes percibidas** `[PLACEHOLDER]` mediante escala, rotación, tinte y mezcla
  de pools, sin volver a subir el mismo mesh.
- Mantener una proporción inicial 70% comunes, 20% poco comunes y 10% landmarks
  `[PLACEHOLDER]`; ajustar por telemetría de reconocimiento y satisfacción.

La variedad debe venir primero de la silueta: bloque, esfera, cilindro, estrella, caja, botella,
utensilio, juguete. A escala pegada, una textura compleja se pierde; una silueta clara permanece.

### Texturas y materiales

- Preferir materiales integrados de Roblox: usan mucha menos memoria que texturas custom.
- Si se necesita arte custom, usar 1–2 atlas/trim sheets por tema `[PLACEHOLDER]`.
- Usar 128–256 px para proxies pequeños `[PLACEHOLDER]`; la guía oficial recomienda 256×256 para
  objetos de ~5×5 studs y normalmente no más de 512×512 salvo que ocupen mucho espacio en pantalla.
- Evitar 1024×1024 en proxies. Una textura 1024² usa cuatro veces la memoria gráfica de una 512².
- Reutilizar el **mismo** `MeshContent`, `TextureContent` y `SurfaceAppearance`; volver a subir el
  mismo archivo crea otro asset ID e impide batching/instancing.
- Para recolores, usar una textura común y tintes autorizados en lugar de una textura por color.
- No crear un `SurfaceAppearance` único por objeto. Evitar PBR en los proxies salvo que una prueba
  demuestre que aporta lectura suficiente para pagar sus mapas.
- Convertir assets reutilizables en packages y actualizar el package; no reimportar copias.

Roblox puede agrupar meshes idénticos en un draw call solo cuando comparten `MeshContent` y las
características de textura/material. “Se ven iguales” no basta si sus asset IDs son distintos.

## 8. Checklist de importación

Antes de entregar un objeto nuevo:

- [ ] El nombre e ID están en inglés y coinciden con `GameConfig`/registry.
- [ ] El mesh se subió una sola vez y las variantes son duplicados/packages de ese asset.
- [ ] Existe el modelo de suelo authored; no se genera por código.
- [ ] Existe el proxy authored en `AttachmentProxies`; no se genera por código.
- [ ] El proxy tiene exactamente una part y `PrimaryPart` válida.
- [ ] El proxy cumple los seis flags de física/render del contrato.
- [ ] `RenderFidelity=Performance` y `CollisionFidelity=Box` si es `MeshPart`.
- [ ] No contiene scripts, VFX, lights, decals, bones, guis ni constraints.
- [ ] Triángulos registrados desde Blender/Maya; Luau no ofrece un conteo de triángulos fiable para
  este gate.
- [ ] Mesh, textura y material pertenecen a la allowlist compartida del tema.
- [ ] La textura cabe en 256 px o tiene una excepción documentada `[PLACEHOLDER]`.
- [ ] Se lee como silueta a tamaño real del proxy y no tapa cabeza/cámara.
- [ ] Se probó mezclado con 109 piezas, no aislado en un viewport vacío.

## 9. Gate de arte

El registry runtime vigente valida el contrato estructural y físico básico del proxy. Las reglas
de allowlist, asset IDs duplicados y triángulos requieren todavía un gate DCC/CI; no están
implementadas automáticamente en Luau.

El validador de `AttachmentProxyTemplates` debe bloquear el arranque de desarrollo o CI cuando
encuentre:

- ID ausente, repetido o sin entrada de configuración;
- cero o más de una `BasePart`;
- `PrimaryPart` ausente o fuera del modelo;
- cualquier flag físico/render inseguro;
- descendants prohibidos;
- mesh/textura/material fuera de la allowlist;
- un nombre visualmente repetido con asset IDs diferentes;
- una plantilla registrada que no tenga proxy, o un proxy huérfano.

El recuento de triángulos se valida en el reporte de exportación del DCC y se adjunta al asset.
Hasta disponer de esa metadata, el gate debe marcarlo como revisión manual; no fingir precisión.

## 10. Benchmark móvil de aceptación

### Dispositivos y duración

- Un Android low-end representativo y un Android mid-end real; Studio Device Emulator no sustituye
  esta prueba.
- Soak de 10–15 minutos para observar thermal throttling.
- Tres repeticiones de 120–300 s por escenario, alternando el orden A/B.

### Matriz mínima

| Variable | Casos |
| --- | --- |
| Jugadores co-localizados | 1, 4 y 8 |
| Ring lógico por jugador | 0, 36, 110 y 300 |
| Presentación propia | 72, 96 y 110 `[PLACEHOLDER]` |
| Presentación remota | 8, 12 y 20 `[PLACEHOLDER]` |
| Movimiento | normal, aura máxima autorizada `[PLACEHOLDER]`, cambios bruscos de dirección |
| Fase | empty, fill, steady, ráfaga, clear, respawn, late join y salida de owner |
| Arte | primitivas actuales y set representativo final |

### Casos funcionales obligatorios

1. Pickup normal válido.
2. Barrido válido atravesando uno y varios objetos a velocidad máxima.
3. Rechazo por distancia/teletransporte, ID inválido, requisito insuficiente y rate limit.
4. Llegar a 110, superar 300 y comprobar que `TotalCollectedThisRebirth` sigue aumentando mientras
   el ring lógico permanece en 300.
5. Verificar reemplazo del normal más antiguo y persistencia de protegidos.
6. Death, respawn, pedestal, Replay, Rebirth y pickup concurrente durante clear.
7. Diez ciclos fill/clear sin crecimiento de instances, conexiones, colas ni memoria.

### Capturas y métricas

- MicroProfiler de cliente **y** servidor en empty/fill/steady/clear/late join.
- Frame time p50/p95/p99, no solo FPS medio.
- `PhysicsStep`, scripts (`CollectibleSensor`, `AttachmentRenderer`), render y spikes.
- Memoria total y categorías de instances, physics, meshes y textures.
- Draw calls, triángulos, parts, welds, activos/creados en el pool.
- Data send/receive durante fill, steady y late join.
- Pérdidas de pickup, latencia desde contacto hasta feedback y tamaño de cada burst.

Gate inicial: 30 FPS estables en low-end y p95 ≤33,3 ms, sin spike atribuible al renderer durante
clear o ráfagas `[PLACEHOLDER hasta prueba Android]`. Si falla, bajar en este orden:

1. presupuesto remoto;
2. distancia de LOD remoto;
3. presupuesto propio;
4. triángulos/texturas del proxy;
5. densidad de VFX agregado.

No bajar primero el contador ni la frecuencia de recompensas: son baratos y sostienen la fantasía.

## 11. Referencias oficiales de Roblox

- [Design for performance](https://create.roblox.com/docs/performance-optimization/design): dispositivo
  base, memoria móvil, streaming, materiales integrados, reutilización y código event-driven.
- [Improve performance](https://create.roblox.com/docs/performance-optimization/improve): instancing,
  asset IDs compartidos, draw calls, texturas, sombras, transparencia y flags de colisión.
- [Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware): por qué
  el emulador no representa RAM, temperatura, frame time ni latencia de un celular real.
- [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler): profiling de
  frame time y capturas desde dispositivos móviles.
- [Instance streaming](https://create.roblox.com/docs/workspace/streaming): memoria, réplica y riesgo
  de assemblies móviles con demasiadas instancias.
- [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications): tamaños
  de textura, UV y presupuestos PBR.

## Regla de decisión

Si una propuesta aumenta la gratificación pero también multiplica parts, welds, texturas, VFX o
trabajo por frame, primero traducirla a contador, silueta, reciclaje o feedback agregado. La bola
puede sentirse infinita; su coste debe permanecer acotado.
