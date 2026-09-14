# Admin Abuse: Diseño de Evento Global Automático de Recolección y Mutaciones

**Experiencia:** `+1 Everything Sticks`  
**Duración:** 24 horas  
**Operación:** Completamente automática  
**Admin Boost:** Activo durante todo el evento  
**Loop secundario:** 15 minutos  
**Valores numéricos:** `[POR VALIDAR]`

## 1. Resumen

Admin Abuse es un evento global de 24 horas que acelera el loop principal de colección y permite encontrar versiones Gold, Neon, Rainbow y Admin de los objetos normales.

Durante toda la ventana permanece activo **Admin Boost**. Encima de este modificador base se repite un loop compuesto por:

```
Magnet Overdrive → Mutation Frenzy → Chaos Combo
```

El evento no requiere que un administrador esté conectado. Su inicio, rotación, jackpot y cierre funcionan automáticamente mediante horarios globales.

La fantasía del jugador es:

> “Los admins rompieron las reglas y el mundo está generando objetos imposibles.”

## 2. Alcance

### Incluido

- Evento automático de 24 horas.
- Admin Boost permanente.
- Loop secundario de 15 minutos.
- Magnet Overdrive.
- Mutation Frenzy.
- Chaos Combo.
- Rare Spawn Director.
- Objetos Gold, Neon, Rainbow y Admin.
- Jackpot automático.
- Index permanente de descubrimientos.
- Recompensas de participación y progreso del Index.
- Seguridad, telemetría y optimización móvil.

### Excluido

- Sticky Rain.
- Giant Drop.
- Panel administrativo.
- Sistema de vitrinas.
- Salas de exhibición.
- Colocación manual de objetos.
- Almacenamiento persistente de modelos físicos.
- Activación manual necesaria para operar el evento.
- Moneda temporal exclusiva del evento.

El sistema conserva únicamente un `EmergencyStop` técnico.

## 3. Objetivos

- Crear un evento especial, caótico y compartible.
- Acelerar temporalmente el loop de recolección.
- Motivar varias sesiones durante las 24 horas.
- Dar valor adicional a objetos normalmente comunes.
- Incentivar el progreso del Index.
- Mantener una experiencia completa para jugadores gratuitos.
- Evitar que el evento invalide la progresión normal.
- Funcionar correctamente en servidores nuevos y existentes.

## 4. Principios

- El servidor controla spawns, multiplicadores y recompensas.
- El cliente únicamente presenta UI, audio y VFX.
- Admin Boost se mantiene activo durante toda la ventana.
- Solo existe un modificador secundario a la vez, excepto durante Chaos Combo.
- El evento nunca elimina progreso.
- Las mutaciones se aplican a objetos existentes.
- El Index registra descubrimientos, pero no funciona como vitrina.
- Ninguna recompensa requiere permanecer conectado durante 24 horas.
- Todos los valores económicos permanecen centralizados y configurables.

## 5. Estructura del evento

```
ADMIN ABUSE — 24 HORAS
│
├── Capa permanente
│   └── Admin Boost
│
└── Loop automático de 15 minutos
    ├── Magnet Overdrive — 5 min
    ├── Mutation Frenzy — 5 min
    └── Chaos Combo — 5 min
```

El loop secundario se repite 96 veces durante las 24 horas.

## 6. Ventana global de 24 horas

Mientras el evento esté activo, todos los servidores reciben:

- Multiplicador global de Admin Boost.
- Mayor frecuencia de objetos normales.
- Probabilidad base de mutaciones.
- Acceso al Index del evento.
- Progreso de participación.
- UI con tiempo restante.
- Loop automático de modificadores secundarios.
- Oportunidades periódicas de jackpot.

Un servidor abierto a mitad del evento calcula automáticamente:

- Tiempo restante.
- Posición actual del loop.
- Modificador secundario activo.
- Configuración vigente de spawns y multiplicadores.

## 7. Admin Boost permanente

Admin Boost comienza con el evento y permanece activo hasta su finalización.

No forma parte del loop secundario y no se reinicia al cambiar de modificador.

### Efectos

- Multiplicador global de progreso.
- Aumento de la frecuencia normal de objetos.
- Probabilidad base de Gold, Neon y Rainbow.
- Activación del Rare Spawn Director.
- Progreso de participación.
- Acceso a descubrimientos del Index.

```
AdminBoost.Active = EventActive
```

Variables principales:

```
AdminBoostMultiplier
AdminBoostSpawnRate
BaseMutationWeights
```

## 8. Loop secundario

| Minuto | Modificador |
| --- | --- |
| 00–05 | **Magnet Overdrive** |
| 05–10 | **Mutation Frenzy** |
| 10–15 | **Chaos Combo** |

Cuando finaliza Chaos Combo, el loop regresa automáticamente a Magnet Overdrive. Admin Boost nunca se desactiva durante esta transición.

## 9. Magnet Overdrive

Magnet Overdrive se superpone a Admin Boost durante cinco minutos.

### Efectos

- Aumenta el radio de atracción.
- Facilita recoger objetos normales y mutados.
- Muestra un indicador visual alrededor del jugador.
- Utiliza el radio temporal para la validación del servidor.
- No aumenta directamente los pesos de rareza.
- No añade otro multiplicador de progreso.

Ejemplo:

```
Multiplicador = AdminBoostMultiplier
Spawn rate = AdminBoostSpawnRate
Mutation weights = BaseMutationWeights
Magnet radius = OverdriveMagnetRadius
```

Al terminar la fase, el radio vuelve a su valor normal de Admin Boost.

## 10. Mutation Frenzy

Mutation Frenzy aumenta temporalmente la presencia de objetos Gold, Neon y Rainbow.

### Efectos

- Multiplica los pesos de las mutaciones.
- Aumenta la velocidad del presupuesto de rareza.
- Reduce temporalmente los tiempos máximos de sequía.
- Mantiene un límite de mutaciones activas.
- Conserva el multiplicador permanente de Admin Boost.
- Mantiene el radio magnético normal.

Ejemplo:

```
Multiplicador = AdminBoostMultiplier
Spawn rate = AdminBoostSpawnRate
Mutation weights = BaseMutationWeights × FrenzyModifier
Magnet radius = NormalMagnetRadius
```

Mutation Frenzy no convierte todos los objetos en raros. El Rare Spawn Director continúa controlando la frecuencia.

## 11. Chaos Combo

Chaos Combo es el clímax del loop.

### Efectos

- Activa Magnet Overdrive.
- Activa Mutation Frenzy.
- Mantiene Admin Boost.
- Ejecuta un roll automático de jackpot.
- Puede garantizar una oportunidad Rainbow.
- Puede generar un objeto Admin cuando se cumple su intervalo o pity.

Ejemplo:

```
Multiplicador = AdminBoostMultiplier
Spawn rate = AdminBoostSpawnRate
Mutation weights = BaseMutationWeights × FrenzyModifier
Magnet radius = OverdriveMagnetRadius
JackpotRoll = true
```

Chaos Combo no añade un segundo multiplicador general. Esto evita acumulaciones económicas difíciles de controlar.

Sticky Rain no puede ser seleccionado como parte del combo.

## 12. Resolución de modificadores

La configuración efectiva combina dos capas:

```
Configuración efectiva =
Admin Boost permanente
+ modificador secundario actual
```

El sistema no multiplica ciegamente todos los valores. Cada propiedad define cómo se combina:

| Propiedad | Admin Boost | Modificador secundario |
| --- | --- | --- |
| Progreso | Define el multiplicador | No se acumula |
| Spawn normal | Define la tasa base | Generalmente no se acumula |
| Radio magnético | Valor normal | Overdrive lo reemplaza |
| Pesos de mutación | Valores base | Frenzy los multiplica |
| Jackpot | Inactivo | Chaos Combo lo habilita |

## 13. Rare Spawn Director

Los objetos raros son controlados por un sistema autoritativo llamado `Rare Spawn Director`.

No se tira una probabilidad independiente por cada objeto normal. Una alta densidad de objetos podría generar cantidades impredecibles de mutaciones.

El director utiliza un presupuesto controlado.

### Flujo

```
Acumular presupuesto
        ↓
Comprobar límites
        ↓
Seleccionar rareza
        ↓
Seleccionar objeto base
        ↓
Seleccionar zona válida
        ↓
Mostrar advertencia
        ↓
Activar objeto
        ↓
Recoger o expirar
        ↓
Recompensar y limpiar
```

### Conversión de spawns

Cuando sea posible, el director convierte un próximo spawn normal en una mutación:

```
Spawn normal previsto
        ↓
Rare Spawn Director selecciona una mutación
        ↓
El objeto aparece como Gold, Neon o Rainbow
```

Esto mantiene estable la cantidad de objetos físicos.

### Presupuesto de rareza

El presupuesto aumenta según:

- Tiempo transcurrido.
- Número de jugadores activos.
- Modificador secundario actual.
- Tiempo desde el último spawn raro.
- Cantidad de mutaciones activas.
- Rendimiento del servidor.

Cada rareza tiene un coste. El director solo puede generarla cuando existe suficiente presupuesto.

Los servidores con más jugadores reciben una frecuencia ligeramente mayor, pero no de forma lineal.

## 14. Protección contra mala suerte

Cada rareza tiene un contador de sequía independiente.

```
Peso efectivo =
peso base × modificador de fase × bonus por sequía
```

Si una rareza lleva demasiado tiempo sin aparecer:

1. Su peso aumenta gradualmente.
2. Alcanza una garantía después del límite configurado.
3. Aparece cuando existe un punto válido.
4. Su contador se reinicia.

El objeto Admin utiliza un pity basado en ciclos completos.

## 15. Ciclo de vida de un objeto raro

```
Reserved → Warning → Active → Claimed | Expired → Cleanup
```

- **Reserved:** se seleccionan objeto, mutación y ubicación.
- **Warning:** aparece una señal previa.
- **Active:** el objeto puede recogerse.
- **Claimed:** el servidor confirma al ganador.
- **Expired:** se termina el tiempo disponible.
- **Cleanup:** se eliminan modelo, marcadores, audio y conexiones.

Tiempo recomendado:

```
RareObjectLifetime = 45–90 segundos [POR VALIDAR]
```

Si el objeto expira, una parte de su presupuesto puede regresar al director.

## 16. Sistema de mutaciones

Una mutación es una capa aplicada a cualquier objeto normal.

```
Objeto base + MutationId → objeto mutado
```

El objeto conserva:

- Nombre.
- Modelo.
- Categoría.
- Hitbox.
- Comportamiento de adhesión.
- Entrada base del Index.

La mutación modifica:

- Material.
- Color.
- VFX y audio.
- Rareza.
- Multiplicador.
- Entrada de mutación en el Index.

La ganancia se calcula mediante:

```
Ganancia final =
+1 × AdminBoostMultiplier × MutationMultiplier
```

## 17. Objetos Gold

### Propósito

Gold es la mutación de entrada: reconocible, relativamente frecuente y valiosa.

### Apariencia

- Material metálico dorado.
- Destellos suaves.
- Icono de estrella.
- Efecto dorado breve al recogerlo.

### Comportamiento

- Puede aparecer durante todo el evento.
- No genera un anuncio global.
- Puede mostrar una notificación local.
- Conserva su material al adherirse.
- Desbloquea la variante Gold en el Index.

### Multiplicador

```
GoldMultiplier = ×2 [POR VALIDAR]
```

Ejemplo:

```
Golden Chair
+1 × AdminBoostMultiplier × 2
```

## 18. Objetos Neon

### Propósito

Neon crea una pequeña carrera entre jugadores cercanos.

### Apariencia

- Material Neon.
- Color seleccionado de una paleta controlada.
- Outline pulsante.
- Pequeño haz vertical.
- Sonido ambiental reconocible.
- Icono de rayo.

### Comportamiento

- Es menos frecuente que Gold.
- Produce un anuncio dentro de su zona.
- Su peso aumenta durante Mutation Frenzy.
- Conserva su apariencia al adherirse.
- Desbloquea la variante Neon en el Index.

### Multiplicador

```
NeonMultiplier = ×5 [POR VALIDAR]
```

Ejemplo:

```
Neon Traffic Cone
+1 × AdminBoostMultiplier × 5
```

## 19. Objetos Rainbow

### Propósito

Rainbow crea un momento raro y compartible para todo el servidor.

### Apariencia

- Ciclo gradual de colores.
- Aura visible a distancia.
- Marcador sobre el objeto.
- Sonido de aparición global.
- Icono multicolor.
- Efecto especial de recolección.

### Comportamiento

- Tiene una probabilidad natural baja.
- Su aparición se anuncia a todo el servidor.
- Posee protección contra sequías prolongadas.
- Chaos Combo puede garantizar una oportunidad.
- Conserva su apariencia al adherirse.
- Desbloquea la variante Rainbow en el Index.

### Multiplicador

```
RainbowMultiplier = ×10 [POR VALIDAR]
```

Ejemplo:

```
Rainbow Sofa
+1 × AdminBoostMultiplier × 10
```

## 20. Objeto Admin

El objeto Admin es el jackpot máximo del evento.

### Apariencia

- Material exclusivo.
- Símbolo Admin.
- Aura visible desde varias zonas.
- Cuenta regresiva.
- Sonido exclusivo.
- Anuncio global.

### Comportamiento

- No forma parte del spawn común.
- Solo aparece mediante pity o intervalo automático.
- Chaos Combo ejecuta su roll.
- Existe un límite por servidor.
- Puede entregar un cosmético adicional.
- Desbloquea su variante en el Index.

### Multiplicador

```
AdminMultiplier = ×25 [POR VALIDAR]
```

Su frecuencia se controla mediante:

```
AdminJackpotIntervalCycles
AdminPityCycles
AdminSpawnLimit
```

## 21. Recolección y adhesión

Cuando un jugador recoge una mutación:

1. El servidor valida el intento.
2. Marca el objeto como reclamado.
3. Calcula y entrega la ganancia.
4. Actualiza el Index.
5. Adhiere el modelo si existe capacidad visual.
6. Reproduce el feedback correspondiente.

El objeto conserva temporalmente su apariencia especial mientras está pegado al personaje.

Si se alcanza el límite visual:

- La recompensa se entrega normalmente.
- El Index se actualiza.
- El contador aumenta.
- El modelo físico adicional puede omitirse.

No existe una vitrina ni almacenamiento persistente de modelos.

## 22. Index

El Index es un catálogo permanente de descubrimientos.

Su función es registrar qué objetos y mutaciones encontró el jugador. No permite colocar, mover o exhibir modelos físicos.

### Estructura

Cada objeto base puede contener:

```
Chair
├── Gold
├── Neon
├── Rainbow
└── Admin
```

### Entrada bloqueada

Antes de descubrirse:

- Aparece como silueta.
- Su mutación permanece oculta.
- Puede ocultarse el nombre completo.
- No revela necesariamente dónde encontrarla.

### Entrada desbloqueada

Después de recogerla:

- Muestra nombre y mutación.
- Muestra su icono.
- Registra la cantidad recogida.
- Puede mostrar la fecha del primer descubrimiento.
- Actualiza el porcentaje de completitud.

### Desbloqueo autoritativo

```
SuccessfulCollection
        ↓
IndexService.Unlock(BaseObjectId, MutationId)
        ↓
Guardar descubrimiento
        ↓
Notificar al cliente
```

El cliente nunca puede desbloquear entradas directamente.

### Progreso del Index

Puede mostrar:

- Objetos base descubiertos.
- Variantes Gold.
- Variantes Neon.
- Variantes Rainbow.
- Variantes Admin.
- Porcentaje total completado.
- Cantidad de duplicados.

### Recompensas

Hitos sugeridos:

- Primera mutación.
- `25%` completado.
- `50%` completado.
- `75%` completado.
- `100%` completado.
- Todas las variantes de una categoría.

Recompensas recomendadas:

- Títulos.
- Auras.
- Badges.
- Efectos visuales.
- Cosméticos.

El Index permanece después de salir, hacer rebirth o terminar el evento.

## 23. Datos persistentes

Se guardan identificadores y contadores compactos:

```
EventParticipation
AdminAbuseCyclesCompleted

GoldCollected
NeonCollected
RainbowCollected
AdminCollected

IndexDiscoveries
IndexCounts
ClaimedMilestoneRewards
```

Ejemplo conceptual:

```
IndexDiscoveries = {
    ["Chair:Gold"] = true,
    ["Cone:Neon"] = true,
    ["Sofa:Rainbow"] = true
}
```

No se guardan:

- Modelos físicos.
- Posiciones.
- Objetos colocados.
- Vitrinas.
- Salas de exhibición.
- Estado visual de colecciones físicas.

## 24. Validación de recolección

El servidor verifica:

- Que el objeto existe.
- Que sigue activo.
- Que pertenece al `eventRunId` vigente.
- Que todavía no fue reclamado.
- Que el jugador está dentro del rango permitido.
- Que el rango corresponde al modificador activo.
- Que el objeto no expiró.
- Que la recompensa no fue entregada antes.

El objeto se bloquea como reclamado antes de modificar los datos del jugador.

## 25. Balance económico

Objetivo inicial:

```
Ganancia media durante Admin Abuse =
1.5×–2× la tasa normal [POR VALIDAR]
```

Los multiplicadores individuales pueden ser mayores porque sus objetos aparecen con menor frecuencia.

Controles:

- Presupuesto de rareza.
- Límites por zona.
- Límite global del servidor.
- Pity por tier.
- Intervalo del jackpot.
- Multiplicadores centralizados.
- Validación única.
- Telemetría por fuente.
- Configuración versionada.
- Posibilidad de rollback.

Se deben simular:

- Jugador casual.
- Jugador frecuente.
- Grinder.
- Jugador que participa varias horas.
- Jugador que entra únicamente durante Chaos Combo.
- Jugador que participa en varios ciclos separados.

## 26. Distribución espacial

- Los objetos usan puntos de spawn validados.
- No aparecen dentro de paredes.
- No bloquean portales, salidas o spawns.
- Se priorizan moderadamente las zonas con jugadores.
- Una zona no recibe todos los raros consecutivos.
- Neon y Rainbow son visibles desde rutas principales.
- Rainbow y Admin reciben marcadores claros.
- El sistema no favorece repetidamente al mismo jugador.

## 27. UI del evento

La interfaz presenta dos niveles de información:

```
ADMIN ABUSE: 18h 42m restantes
MUTATION FRENZY: 03m 16s restantes
```

### Temporizador principal

Muestra:

- Tiempo restante de las 24 horas.
- Multiplicador de Admin Boost.
- Progreso general de participación.

### Temporizador secundario

Muestra:

- Modificador actual.
- Tiempo hasta el siguiente modificador.
- Icono correspondiente.
- Aviso breve al cambiar de fase.

El cambio de fase no debe bloquear controles ni cubrir información importante.

## 28. Automatización

Configuración mínima:

```
EventId
Version
Enabled
EmergencyStop
StartTime
EndTime

AdminBoostMultiplier
AdminBoostSpawnRate

OverlayCycleDuration
MagnetOverdriveDuration
MutationFrenzyDuration
ChaosComboDuration

OverdriveMagnetRadius
FrenzyMutationModifier
ChaosJackpotEnabled

MutationWeights
MutationMultipliers
DroughtGuarantees

AdminJackpotIntervalCycles
AdminPityCycles
RewardProfile
```

Cálculo del loop:

```
EventElapsed = CurrentTime - StartTime
LoopPosition = EventElapsed % 900 segundos
OverlayPhase = phaseAt(LoopPosition)
```

Estados principales:

```
EventActive = true
BaseModifier = AdminBoost
OverlayModifier = Magnet | Mutation | Chaos
```

## 29. Finalización

Cuando se alcanza `EndTime`:

1. Se detiene el loop secundario.
2. Se cancelan nuevos spawns raros.
3. Se procesan reclamaciones ya confirmadas.
4. Se eliminan objetos del evento no reclamados.
5. Se desactiva Admin Boost.
6. Se restauran multiplicadores y radios normales.
7. Se elimina la UI.
8. Se ejecuta el cleanup.
9. El progreso del Index permanece guardado.

## 30. Arquitectura

```
Event Configuration
        ↓
Event Scheduler
        ↓
Event Orchestrator
   ├── Admin Boost Controller
   ├── Overlay Phase Controller
   ├── Rare Spawn Director
   ├── Reward Service
   ├── Index Service
   └── Analytics Service
        ↓
Client UI / VFX / Audio / Index
```

No forman parte de la arquitectura:

- Panel administrativo.
- `AdminCommandService`.
- Giant Drop.
- Sticky Rain.
- Sistema de vitrinas.

## 31. Emergency Stop

El sistema incluye únicamente un control técnico:

```
EmergencyStop = true | false
```

Al activarse:

- Detiene el loop.
- Impide nuevos spawns.
- Conserva recompensas confirmadas.
- Ejecuta cleanup.
- Desactiva Admin Boost.
- Mantiene intacto el Index.

No requiere una interfaz administrativa dentro del juego.

## 32. Rendimiento

Orden automático de degradación:

1. Reducir partículas decorativas.
2. Reducir frecuencia de animación Rainbow.
3. Ocultar haces lejanos.
4. Reducir densidad de objetos normales.
5. Reducir límite de mutaciones activas.
6. Mantener siempre recompensas e Index.

Medidas adicionales:

- Object pooling.
- Límites de objetos por zona.
- Efectos de recolección cortos.
- Animaciones agrupadas.
- Sin actualización Rainbow individual por frame.
- Cleanup obligatorio.
- Pruebas en móviles de gama baja.

## 33. Casos límite

- **Servidor abierto a mitad del evento:** recupera Admin Boost y la fase secundaria.
- **Jugador entra tarde:** recibe ambos temporizadores.
- **Cambio de fase durante una recogida:** se conserva el valor asignado al objeto cuando apareció.
- **Dos jugadores recogen simultáneamente:** solo una validación obtiene la recompensa.
- **Objeto expira durante el intento:** decide el servidor.
- **Punto inválido:** se selecciona otro sin perder el presupuesto.
- **Límite visual alcanzado:** se entrega progreso e Index sin añadir modelo.
- **Mensaje duplicado:** `eventRunId` impide duplicaciones.
- **Emergency Stop:** detiene ambas capas y ejecuta cleanup.
- **Error al guardar:** se reintenta sin duplicar la recompensa.
- **Fin durante Chaos Combo:** no aparecen nuevos objetos, pero se procesan reclamaciones confirmadas.

## 34. Telemetría

Registrar:

- Inicio y final del evento.
- Inicio y final de cada modificador.
- Participantes únicos.
- Ciclos completados.
- Tiempo jugado durante Admin Boost.
- Objetos recogidos por mutación.
- Nuevas entradas del Index.
- Porcentaje medio del Index.
- Tiempo entre spawns.
- Sequías y pity activados.
- Objetos expirados.
- Jackpots entregados.
- Duplicaciones rechazadas.
- Ganancia media y P90.
- Abandonos por modificador.
- Rendimiento por dispositivo.

## 35. Criterios de aceptación

- El evento dura 24 horas.
- Admin Boost permanece activo durante toda la ventana.
- El loop secundario dura 15 minutos.
- Magnet Overdrive, Mutation Frenzy y Chaos Combo rotan automáticamente.
- Chaos Combo combina correctamente Magnet y Mutation.
- El sistema no acumula multiplicadores generales inesperados.
- Sticky Rain no puede activarse.
- Giant Drop no está implementado.
- No existe panel administrativo.
- No existen dependencias con vitrinas.
- Gold, Neon, Rainbow y Admin funcionan correctamente.
- Un servidor nuevo recupera ambas capas.
- No pueden duplicarse objetos ni recompensas.
- El Index se actualiza y persiste.
- El Index no almacena modelos físicos.
- El cleanup restaura completamente el juego.
- El rendimiento se mantiene dentro del presupuesto móvil.

## 36. Variables pendientes de playtest

```
AdminBoostMultiplier
AdminBoostSpawnRate
OverdriveMagnetRadius
FrenzyMutationModifier

GoldMultiplier
NeonMultiplier
RainbowMultiplier
AdminMultiplier

GoldWeight
NeonWeight
RainbowWeight

RareBudgetRate
ActiveRareCap
RareObjectLifetime
DroughtGuaranteeTime

AdminJackpotIntervalCycles
AdminPityCycles
IndexMilestoneThresholds
```

Todos estos valores deben permanecer centralizados para ajustar el evento sin modificar su arquitectura.
