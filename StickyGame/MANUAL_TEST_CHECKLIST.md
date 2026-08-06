# Stuck to You — Checklist manual del lunes

Ejecutar en Roblox Studio con **Play**, sin comandos ni herramientas de automatización. Duración estimada: 5–8 minutos.

## Recorrido principal

- [ ] Al aparecer: HUD muestra Stickiness 0, Level 1 y `TOY CHEST 0 / 50`.
- [ ] Objetos requisito 0 son verdes; 5/12/25 empiezan rojos.
- [ ] Tocar un objeto rojo no aumenta Stickiness y muestra cuánto falta.
- [ ] Tocar objetos verdes los oculta, suma Stickiness, agrega una pieza a la pila y reaparecen cerca de 2 s después.
- [ ] Al llegar a Stickiness 30 se desbloquea Strong Glue y los pickups siguientes otorgan +3.
- [ ] La pila crece sin trabar el movimiento, lanzar al personaje ni tapar completamente la cámara.
- [ ] Antes de 50, el Toy Chest permanece rojo, bloquea el paso y muestra `NEED X MORE` al tocarlo.
- [ ] En 50 o más, todo el Toy Chest y su número se vuelven verdes.
- [ ] Al tocarlo, el chest se absorbe, aparece `ZONE OPEN!`, el HUD cambia a Bed y puedes caminar hasta `BEDROOM NEXT`.

## Reset y estabilidad

- [ ] Usa **Reset Character**: Stickiness vuelve a 0, Level a 1, desaparece la pila y Toy Chest vuelve rojo y bloqueando.
- [ ] Recoge objetos rápidamente durante 20–30 s: no hay premios dobles evidentes, congelamientos ni piezas con colisión.
- [ ] Revisa **Output**: no debe haber errores rojos de `StuckToYou`, `Main`, services o controllers.

## Medición requerida

- [ ] Cronometra desde que puedes moverte hasta absorber Toy Chest, jugando por primera vez sin optimizar la ruta.

**Resultado esperado:** 45–60 segundos. Anota aquí el resultado: `_____ s`.

- Menos de 45 s: bajar `TotalObjects` de la sala o subir `MinSeparationStuds`.
- Más de 60 s: subir `TotalObjects` o bajar `MinSeparationStuds`.
- No cambiar fórmulas dentro de servicios; cualquier ajuste va en `Zones/<Zone>/RoomSettings` o en `GameConfig`.

---

## Objetos per-player — prueba con 2 jugadores (pendiente)

Requiere `Test > Clients and Servers > Players: 2 > Start`. No se puede ejecutar desde la herramienta MCP.

### Aislamiento entre jugadores

- [ ] Ambos jugadores aparecen en Toy Room y cada uno ve objetos en posiciones distintas.
- [ ] En la ventana del jugador A, el Explorer muestra `Workspace/LocalCollectibles` con 12 hijos. En la de B, otros 12 con posiciones diferentes.
- [ ] En la ventana del **servidor**, `Workspace` no tiene ningún `LocalCollectibles`: los objetos solo existen en cada cliente.
- [ ] El jugador A recoge un objeto: su Stickiness sube y el objeto desaparece **solo en su pantalla**.
- [ ] El jugador B no ve desaparecer nada y sus objetos siguen todos disponibles.
- [ ] B recoge el objeto que está en la misma zona del mapa donde A ya recogió: se le concede normalmente.
- [ ] Ambos completan Toy Room sin que ninguno se quede esperando objetos.

### Reparto y colocación

- [ ] Los objetos de cada sala son de los tipos listados en `Zones/<Zone>/RoomSettings/ObjectPool` y aparecen en cantidades parecidas entre sí.
- [ ] Los objetos están repartidos por toda la sala, no en fila ni amontonados.
- [ ] Ningún objeto queda dentro de un mueble, dentro de una pared, ni encima del blocker.
- [ ] Al entrar a Bedroom, los objetos de Toy Room desaparecen y aparecen los de Bedroom.

### Configuración manual desde el editor

- [ ] Cambiar `Zones/ToyRoom/RoomSettings/TotalObjects` a 24 y volver a jugar: aparecen 24 objetos por jugador.
- [ ] Añadir un `ObjectValue` nuevo en `ObjectPool` apuntando a otra plantilla de `ReplicatedStorage/Assets/Collectibles`: ese tipo empieza a aparecer y el reparto se reajusta solo.
- [ ] Mover o redimensionar `Zones/ToyRoom/PlacementArea`: los objetos se colocan dentro del nuevo volumen.
- [ ] Vaciar `ObjectPool`: la consola avisa explícitamente y no aparecen objetos, en vez de sustituirlos en silencio.
- [ ] Borrar `PlacementArea` de una sala: la consola avisa y esa sala se queda sin objetos, sin romper las demás.
- [ ] Si una sala aparece **vacía de objetos**, mirar la consola: `produced 0 slots` significa que falta `Zones/<Zona>/Geometry/Floor`, no que haya que bajar `TotalObjects`.

### Elegibilidad visible

- [ ] **Todos** los objetos de la sala muestran su estado, sin excepciones: los que puedes recoger se ven a color pleno y sólidos, los que no se ven oscurecidos y semitransparentes.
- [ ] Un objeto oscurecido sigue reconociéndose por su forma y su tono (una esfera roja oscura sigue leyéndose como esfera roja).
- [ ] Al cruzar un umbral de Stickiness, todos los objetos de ese tier pasan a color pleno a la vez.
- [ ] Solo el objeto más cercano lleva contorno resaltado, y el contorno sigue al jugador.
- [ ] Subir `TotalObjects` a 40 o más no deja ningún objeto sin estado visual.

### Tarjetas de requisito

- [ ] **Ninguna tarjeta aparece en negro y sin número.** Dos formas de forzarlo: agachar la cámara a ras de suelo mirando la sala a lo largo, y **recoger objetos de espaldas y girarse de golpe** (los que reaparecen fuera de cámara son los que se enganchan).
- [ ] El número llena la tarjeta; si se ve diminuto, comprobar que la etiqueta tenga `TextScaled` **y** `TextWrapped` en `true`: apagar uno apaga el otro en silencio.
- [ ] Las tarjetas de los objetos lejanos se ven más pequeñas que las de los cercanos, no todas del mismo tamaño.
- [ ] Cuando dos tarjetas se cruzan en pantalla, la que queda delante es la del objeto más cercano.
- [ ] Los objetos a más de 50 studs no muestran tarjeta, pero se siguen distinguiendo por color y transparencia si se pueden agarrar o no.
- [ ] A distancia de juego normal el número se lee sin esfuerzo.

### Pedestales de Win

- [ ] Al salir de cada sala hay un pasillo corto con un pedestal dorado y su número visible (`1 WIN`, `3 WINS`, `10 WINS`).
- [ ] Se puede caminar alrededor del pedestal sin pisarlo y seguir hacia la sala siguiente.
- [ ] Pisar un pedestal sin haber limpiado esa sala no da nada y no reinicia.
- [ ] Pisarlo tras limpiar la sala suma las Wins del cartel, vacía la pila y devuelve al inicio.
- [ ] Pasar de largo el de 1 y cobrar el de 3 da exactamente 3, no 4.
- [ ] Al absorber el Refrigerator el jugador **no** es teletransportado: sale caminando y puede elegir el pedestal de 10.
- [ ] Quien pasa de largo el pedestal de 10 llega a la FinishZone y el ReplayPad y el panel de Rebirth siguen funcionando.
- [ ] Las Wins se conservan al reiniciar y tras un Rebirth.

### Coherencia de la pila

- [ ] Recoger una esfera pega una esfera al personaje; recoger un bloque pega un bloque. El orden de la pila sigue el orden de recogida.
- [ ] Los objetos pegados conservan su color; no se vuelven todos del mismo tono.
- [ ] Objetos de distinto tamaño en el suelo quedan de tamaño parecido pegados al personaje.
- [ ] Al recoger, el objeto viaja desde el suelo hasta el cuerpo en vez de aparecer de golpe, y llega bien aunque estés caminando.
- [ ] Al llegar a 36 piezas, cada nueva recogida hace que la más antigua se encoja y se desvanezca, y la nueva ocupa su lugar.
- [ ] La pila nunca deja de responder a las recogidas: sigues viendo pegarse lo último que agarras por muchos objetos que lleves.
- [ ] Pasando de 36 objetos, la pila crece un poco y ninguna pieza se despega ni sale volando.
- [ ] La pila no tapa la cámara ni la cabeza del personaje.
- [ ] Al absorber un blocker desaparece **entero**, sin dejar ninguna pieza suelta en la puerta. Comprobarlo en las tres salas, sobre todo con la cama del Bedroom.
- [ ] Al absorber un blocker, una copia reducida de ese mismo mueble vuela hasta el cuerpo y se queda pegada.
- [ ] El blocker pegado se ve más grande que un objeto normal, pero no tapa la cámara.
- [ ] La copia pegada no muestra su cartel de requisito ni se comporta como bloqueador.
- [ ] Tras absorber los tres blockers, los tres siguen pegados aunque recojas muchos objetos después.
- [ ] Al morir o hacer replay la pila desaparece por completo, incluidos los blockers, y `Workspace/StickyDiscards` queda vacío.

### Gratificación (audio, partículas, popups)

- [ ] Cada recogida suena, saca una chispa y un `+N` verde que sube y se desvanece.
- [ ] El popup y la chispa salen **cuando la pieza aterriza en el cuerpo**, no antes.
- [ ] Recoger en racha sube el tono del sonido; parar un segundo lo devuelve al tono base.
- [ ] Tocar un objeto que no puedes agarrar suena distinto y corta la racha.
- [ ] Subir de nivel suena, saca `LEVEL N` y da una sacudida corta de cámara.
- [ ] Absorber un blocker da whoosh, estallido grande y sacudida; la cámara vuelve a su sitio sola.
- [ ] Morir o resetear a mitad de una sacudida **no** deja la cámara desplazada.
- [ ] Tras un minuto recogiendo sin parar, `Workspace/FeedbackEffects` sigue con el mismo número de hijos.
- [ ] Los cuatro sonidos suenan (no hay silencio por asset no cargado). Ajustables en `Assets/Feedback/Audio`.

### Sticky Wraps visibles

- [ ] El `+N` de cada recogida cambia de color al mejorar de pegamento: blanco, verde, azul, morado.
- [ ] Al desbloquear un wrap sale su nombre en su color (`STRONG GLUE!`) con sonido y sacudida.
- [ ] Al desbloquearlo suena **una sola vez**: no se solapa con el aviso de subida de nivel.
- [ ] El nombre del pegamento en el HUD va en su propio color.
- [ ] Tras un reset a BasicGlue **no** se celebra nada.

### Rendimiento y limpieza

- [ ] Con los dos jugadores dentro, `Output` no muestra errores rojos.
- [ ] Un jugador sale de la partida: no quedan objetos suyos ni errores en el servidor.
