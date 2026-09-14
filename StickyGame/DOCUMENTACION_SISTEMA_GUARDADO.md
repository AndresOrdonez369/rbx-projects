# Sistema de guardado de `+1 EVERYTHING STICKS!`

**Estado documentado:** 14 de septiembre de 2026  
**Place ID:** `95828455414780`  
**Versión del perfil:** `SchemaVersion = 9`  
**Estado de despliegue:** implementado y probado en Roblox Studio; pendiente de publicación en producción.

## 1. Resumen ejecutivo

El juego separa el progreso visible del guardado persistente:

1. El servidor actualiza inmediatamente el estado autoritativo en memoria y los atributos del `Player`.
2. La interfaz y el gameplay reaccionan en el mismo instante; no esperan a DataStore.
3. El perfil se marca como modificado (`Dirty`).
4. Una cola por jugador agrupa los cambios frecuentes y guarda un único snapshot aproximadamente cada 120 segundos.
5. Compras, premios importantes y otros puntos críticos solicitan un guardado inmediato.
6. Al salir un jugador o cerrarse el servidor se hace un último guardado y se libera el bloqueo de sesión.

```text
Acción del jugador
      │
      ├─► Estado en memoria + atributos ─► HUD inmediato
      │
      └─► Perfil Dirty ─► cola escalonada ─► UpdateAsync ─► DataStore
                              ▲
                              └─ guardado inmediato si la acción es crítica
```

Este diseño evita una escritura por cada `+1`. Cientos o miles de cambios de una misma sesión se consolidan en un solo documento por jugador.

## 2. Componentes y fuentes de verdad

| Componente en Studio | Responsabilidad |
|---|---|
| `ReplicatedStorage.Shared.GameConfig` | Nombre del almacén, intervalos, límites, reintentos y bloqueo de sesión. |
| `ServerScriptService.Server.DataService` | Carga, normalización, perfiles en memoria, cola, escrituras, reintentos y liberación. |
| `ServerScriptService.Server.Main` | Inicializa los servicios y ejecuta su destrucción en orden inverso durante el cierre. |
| `ProgressionService` | Estado autoritativo de economía, mundos, wraps, cosméticos, charms y rebirth. |
| `PlaytimeService` y `PlaytimeRewardService` | Tiempo total y progreso/reclamos del tablero diario. |
| `PurchaseService`, `BoostService` y `DeathFlowService` | Recibos de Robux, boosts y créditos de revive idempotentes. |
| `OfflineGainsService`, `DailyRewardService`, `DontLeaveService` | Recompensas que modifican el perfil y fuerzan guardado cuando corresponde. |
| `TutorialService` y `MutationIndexService` | Progreso de tutorial y de Admin Abuse. |

Los módulos de respaldo que están dentro de `ServerStorage` no se ejecutan y no forman parte del sistema activo.

## 3. Configuración vigente

| Parámetro | Valor | Función |
|---|---:|---|
| `StoreName` | `StuckToYouProfile_v1` | Standard DataStore principal. |
| `KeyPrefix` | `Player_` | Produce claves como `Player_123456`. |
| `AutoSaveSeconds` | 120 s | Intervalo regular después de un guardado exitoso. |
| `AutoSaveInitialSpreadSeconds` | 60 s | Distribuye el primer turno entre 60 y 120 segundos después de cargar. |
| `AutoSaveQueueTickSeconds` | 1 s | Frecuencia con la que el trabajador revisa la cola. |
| `AutoSaveMaxConcurrent` | 1 | Máximo de autosaves automáticos simultáneos por servidor. |
| `AutoSaveFailureRetrySeconds` | 30 s | Próximo turno de un perfil cuyo guardado agotó los reintentos. |
| `MaxAttempts` | 3 | Intentos dentro de una operación de carga o guardado. |
| `RetryBaseSeconds` | 1 s | Base de la espera exponencial entre intentos. |
| `RetryJitterSeconds` | 0.25 s | Variación aleatoria para no sincronizar reintentos. |
| `RequestBudgetWaitSeconds` | 5 s | Espera máxima de presupuesto antes de fallar un intento. |
| `RequestBudgetPollSeconds` | 0.25 s | Frecuencia de consulta del presupuesto. |
| `SessionLockSeconds` | 300 s | Vigencia de un bloqueo perteneciente a otro servidor. |
| `UseStudioMockStore` | `true` | En Studio usa almacenamiento simulado; en producción siempre usa DataStore real. |

La espera entre los tres intentos es aproximadamente `1–1.25 s` y luego `2–2.25 s`. El tercer fallo termina la operación; la cola conserva el perfil y vuelve a intentarlo 30 segundos después.

## 4. Documento persistido

Cada jugador ocupa una clave:

```text
Player_<UserId>
```

El valor tiene este sobre lógico:

```lua
{
    Data = ProfileData,
    Session = {
        JobId = game.JobId,
        PlaceId = game.PlaceId,
        UpdatedAt = os.time(),
    },
}
```

Mientras el jugador está conectado, `Session` identifica al servidor propietario. En el guardado de salida se escribe `Session = nil` para liberar el perfil.

### Campos del perfil

| Área | Campos persistidos |
|---|---|
| Progresión | `SchemaVersion`, `Wins`, `Rebirths`, `Stickiness`, `TotalCollectedThisRebirth`, `BestRunSeconds` |
| Wraps y apariencia | `OwnedWrapIds`, `EquippedWrapId`, `BlobSkinWrapId` |
| Zonas y cosméticos | `OwnedRestZoneIds`, `OwnedTrailIds`, `EquippedTrailId`, `OwnedAuraIds`, `EquippedAuraId` |
| Charms | `OwnedCharms`, `EquippedCharmIds`, `CharmShopCycle`, `CharmShopRefreshes`, `CharmShopBought`, `CharmRebirthBonus` |
| Mundos | `CurrentWorldId`, `UnlockedWorldIds` |
| Históricos | `TotalWinsEarned`, `TotalStickinessEarned`, `TotalPlaytimeSeconds` |
| Monetización | `ProcessedReceiptIds`, `ReviveCredits`, `BoostExpiry` |
| Tutorial | `TutorialCompleted`, `TutorialStepId`, `TutorialVersion`, `TutorialBaseline` |
| Ganancia offline | `LastSeenAt` |
| Recompensas diarias | `DailySpeedBonus`, `DailyLastClaimAt`, `DailyStreak`, `DailyCycle`, `DailyShields`, `DailyBestStreak` |
| Recompensas por tiempo | `PlaytimeRewardDayIndex`, `PlaytimeRewardSeconds`, `PlaytimeRewardClaimMask` |
| Don't Leave Yet | `DontLeaveLastClaimDay`, `DontLeaveSpeedUntil` |
| Admin Abuse | `AdminAbuse.Index`, `AdminAbuse.Collected`, `AdminAbuse.Milestones`, `AdminAbuse.Runs` |

`AdminAbuse.Runs` conserva, por ventana, `Cycles`, `AdminPity`, `Rewards` y `LastSeenAt`.

### Normalización y migración

Todo documento leído pasa por `normalizeProfile` antes de usarse. La normalización:

- aplica valores por defecto a campos ausentes;
- elimina valores con tipo incorrecto, `NaN`, negativos o fuera de límites;
- valida identificadores contra los catálogos actuales;
- evita que se equipe algo que el jugador no posee;
- limita listas, contadores y registros de Admin Abuse;
- reinicia datos diarios cuando el día o ciclo ya no corresponde;
- conserva como monotónicos los históricos que nunca deben bajar;
- acepta formatos antiguos de charms y los convierte al formato actual;
- aplica las migraciones económicas históricas de esquema 4 y 5;
- devuelve siempre un documento con `SchemaVersion = 9`.

Los campos añadidos después de esas migraciones son aditivos: un perfil anterior obtiene valores seguros por defecto sin necesitar reescribir todas las claves de antemano.

## 5. Carga de un jugador

`DataService` se inicializa al comienzo de `Main`, después del transporte de telemetría y antes de los servicios que consumen perfiles.

Al entrar un jugador:

1. `beginLoad` evita iniciar dos cargas para el mismo jugador.
2. Se crea o reutiliza una señal para quienes estén esperando el perfil.
3. `loadPlayer` calcula la clave `Player_<UserId>`.
4. Antes de `UpdateAsync`, se comprueba que exista presupuesto de lectura y escritura.
5. La transformación examina el bloqueo anterior.
6. Si otro `JobId` actualizó la sesión hace menos de 300 segundos, no toma el perfil.
7. Si el bloqueo está libre, vencido o pertenece al mismo servidor, normaliza los datos y escribe la sesión actual.
8. Se realizan hasta tres intentos con backoff y jitter.
9. Al completar, se crea el `ProfileRecord` en memoria y se publican `DataLoaded = true` y `DataLoadFailed = false`.

Si la carga no se logra:

- se publica `DataLoadFailed = true`;
- se despierta a cualquier servicio que estuviera esperando;
- se registra una advertencia;
- en producción se expulsa al jugador en vez de entregarle valores por defecto que luego podrían sobrescribir su progreso real.

La carga usa `UpdateAsync`, no `GetAsync`, porque leer el perfil y adquirir el bloqueo deben ocurrir como una sola operación atómica.

## 6. Estado del perfil en memoria

Además de `Data`, cada `ProfileRecord` conserva:

| Campo interno | Significado |
|---|---|
| `Dirty` | Existe una revisión que todavía puede requerir persistencia. |
| `CanSave` | La sesión aún acepta mutaciones y guardados normales. |
| `Revision` | Número lógico que aumenta con cada mutación. |
| `PersistedRevision` | Revisión más alta confirmada por DataStore. |
| `SaveInProgress` | Hay un escritor trabajando sobre esa clave. |
| `ReleaseRequested` | Comenzó la salida; se cerró la puerta a nuevas mutaciones. |
| `Released` | DataStore confirmó el guardado con `Session = nil`. |
| `LastAttemptedRevision` | Snapshot del intento más reciente. |
| `LastSaveSucceeded` | Resultado del intento más reciente. |
| `ActiveWriters` | Escritores actuales de esa clave; debe permanecer en 0 o 1. |
| `MaxConcurrentWriters` | Máximo observado, usado para pruebas. |
| `NextAutoSaveAt` | Instante monotónico del próximo turno automático. |
| `SaveSignal` | Despierta a llamadas que esperan al escritor activo. |

## 7. Cómo se modifica el progreso

### `UpdateProfile(player, patch)`

Recibe un parche con solo los campos que cambian. Valida y normaliza cada valor, actualiza la copia en memoria, incrementa `Revision` y marca `Dirty = true`. No llama por sí solo a DataStore.

Se usa para cambios estructurados: compras, inventarios, mundos, boosts, tutorial, recompensas y otros estados de perfil.

### `MarkProfileDirty(player)`

Es la ruta barata para cambios muy frecuentes. Solo incrementa la revisión y marca el perfil como pendiente. No copia listas ni realiza una petición de red.

Se usa para:

- Stickiness ganada por objetos o fuentes pasivas;
- cantidad de objetos recogidos;
- tiempo jugado total.

Los valores actuales viven como atributos autoritativos del `Player`. Justo antes de crear un snapshot, `synchronizeHotFields` copia al perfil:

- `TotalCollectedThisRebirth`;
- `Stickiness`;
- `TotalStickinessEarned`;
- `TotalPlaytimeSeconds`;
- día, segundos y máscara de recompensas de playtime.

Esta sincronización se ejecuta antes de esperar a un escritor y otra vez después de la espera, para capturar cambios ocurridos mientras otra escritura estaba en curso.

### `CommitDailyReward`

Aplica en una sola revisión de memoria la recompensa y su marcador de reclamo. Verifica el último claim esperado y que el tutorial requerido esté completo. De esta forma no existe un estado intermedio donde se entregue el premio sin marcarlo como cobrado.

## 8. Cola escalonada de autosave

### Programación inicial

Al terminar la carga, cada jugador recibe un `NextAutoSaveAt` independiente entre 60 y 120 segundos. Esto evita que todos los perfiles de un servidor queden alineados.

### Trabajador de cola

Cada segundo, el trabajador:

1. Calcula cuántos espacios automáticos quedan disponibles.
2. Recorre los perfiles y busca el vencido más antiguo.
3. Solo considera jugadores presentes con perfil `Dirty`, escribible, no liberado y sin otro guardado activo.
4. Reserva el perfil poniendo temporalmente su turno en infinito para impedir una selección duplicada.
5. Inicia el guardado protegido por `pcall`.

Actualmente `AutoSaveMaxConcurrent = 1`, por lo que solo existe un autosave automático en vuelo por servidor.

### Después del intento

- **Éxito:** el próximo turno del jugador se fija a 120 segundos desde ese guardado.
- **Fallo después de tres intentos:** permanece `Dirty` y se programa para 30 segundos después.
- **Perfil limpio cuando vence:** no se escribe. Su turno queda vencido y el siguiente cambio será recogido rápidamente por la cola.
- **Guardado explícito exitoso:** también reinicia el reloj individual a 120 segundos, evitando un autosave redundante inmediatamente después.

El límite global de uno aplica a la cola automática. Los guardados críticos explícitos pueden ejecutarse en paralelo para jugadores distintos; la serialización por clave sigue evitando dos escritores sobre un mismo jugador.

## 9. Algoritmo de guardado

`SavePlayerAsync` delega en `savePlayer(player, false)`. El procedimiento es:

1. Verificar que exista perfil y que la sesión no esté liberada.
2. Si es un guardado de salida, activar `ReleaseRequested` y poner `CanSave = false` antes de esperar. Así ninguna mutación posterior puede reabrir la sesión.
3. Actualizar `LastSeenAt` cuando el cálculo de ganancias offline ya está listo.
4. Sincronizar los campos calientes.
5. Si otro escritor está activo, esperar `SaveSignal`.
6. Si ese escritor ya persistió la revisión solicitada, reutilizar su éxito.
7. Si falló esa misma revisión, devolver fallo sin generar una tormenta de reintentos idénticos.
8. Volver a sincronizar campos calientes.
9. Si no hay nada nuevo y no es una liberación, terminar sin escribir.
10. Crear una copia completa e inmutable del perfil y capturar su `snapshotRevision`.
11. Marcar `SaveInProgress` e iniciar hasta tres intentos.
12. Esperar presupuesto `StandardRead` y `StandardWrite` antes de cada `UpdateAsync` real.
13. Dentro de `UpdateAsync`, confirmar que la sesión aún pertenece al mismo `game.JobId`.
14. Escribir el snapshot y renovar `Session.UpdatedAt`, o escribir `Session = nil` al liberar.

### Éxito

- `PersistedRevision` avanza hasta la revisión del snapshot.
- `Dirty` solo se limpia si no apareció una revisión posterior mientras se escribía.
- se registra el resultado y se despiertan los escritores que esperaban;
- un guardado normal programa el próximo turno a 120 segundos;
- un guardado de salida marca `Released = true`.

### Fallo

- el perfil permanece `Dirty`;
- se conserva la revisión en memoria;
- se publica el resultado fallido;
- se programa un nuevo turno automático a no más de 30 segundos;
- se registra `[DataService] Failed to save <jugador>: <causa>`.

Si `UpdateAsync` descubre que la sesión dejó de pertenecer al servidor, se cierran `CanSave` y la puerta de la sesión. El servidor deja de aceptar mutaciones para evitar sobrescribir al propietario legítimo.

## 10. Control de concurrencia

La serialización se realiza por jugador, no solo por cola:

```text
Revisión 10 comienza a guardarse
        │
        ├─ durante la escritura llega la revisión 11
        │
        └─ DataStore confirma la revisión 10
                  │
                  └─ PersistedRevision = 10, Revision = 11, Dirty continúa true
```

Si dos servicios llaman `SavePlayerAsync` sobre el mismo jugador:

- el primero se convierte en escritor;
- el segundo espera la señal;
- si el primero cubrió la revisión que el segundo necesitaba, el segundo reutiliza ese resultado;
- nunca se permite que un snapshot antiguo termine después y sobrescriba uno nuevo.

Las pruebas de Studio confirmaron `MaxConcurrentWriters = 1`.

## 11. Qué se guarda automáticamente y qué se guarda inmediatamente

### Agrupado por autosave

- Stickiness común y pasiva.
- Conteo de objetos recogidos.
- Tiempo total jugado.
- Progreso continuo de playtime.
- Cambios ordinarios que usan `UpdateProfile` sin solicitar luego un guardado explícito.
- La línea base de `LastSeenAt` cuando entrar no produjo una recompensa offline.

### Guardado inmediato o solicitado explícitamente

| Servicio | Casos principales |
|---|---|
| `ProgressionService` | Migración de wraps al cargar; concesión de Rest Zone; compras y grants de wraps, trails, auras y charms; refresh de tienda; skip de rebirth; desbloqueo o cambio de mundo; rebirth. |
| `BoostService` | Concesión de un boost, especialmente si viene de una compra. |
| `OfflineGainsService` | Solo cuando la recompensa offline es mayor que cero. |
| `DailyRewardService` | Reclamo de recompensa diaria. |
| `PlaytimeRewardService` | Reclamo de un hito de tiempo. |
| `DontLeaveService` | Reclamo de la recompensa correspondiente. |
| `TutorialService` | Finalización del tutorial. |
| `MutationIndexService` | Hitos y ciclos de participación de Admin Abuse. |
| `PurchaseService` | Marca persistente del `PurchaseId` antes de responder `PurchaseGranted`. |
| `DeathFlowService` | Concesión y consumo persistente de créditos de revive. |

Algunos puntos esperan el resultado porque no pueden confirmar una compra o consumo sin persistencia. Otros usan `task.spawn`: el gameplay continúa, pero un fallo deja el perfil pendiente para la cola o la salida.

### Recibos de Robux

`ProcessedReceiptIds` hace que el procesamiento sea idempotente:

1. Se comprueba si el `PurchaseId` ya fue procesado.
2. Se concede el producto una sola vez.
3. Se añade el identificador al historial y se guarda inmediatamente.
4. Solo después de confirmar el guardado, `PurchaseService` puede responder `PurchaseGranted`.
5. Si falla, responde `NotProcessedYet`; Roblox vuelve a entregar el recibo.

Los créditos de revive guardan juntos el `PurchaseId` y el crédito. Si el guardado falla, la mutación se revierte en memoria y se conserva un estado coherente.

## 12. Salida y cierre del servidor

### `PlayerRemoving`

`removePlayer`:

1. cancela una carga que siga pendiente;
2. llama `savePlayer(player, true)`;
3. escribe el último snapshot con `Session = nil`;
4. elimina el perfil en memoria;
5. destruye las señales asociadas.

### `BindToClose`

`Main` destruye los servicios en orden inverso. `DataService` fue inicializado al principio, por lo que se destruye casi al final. Esto permite que Playtime y los demás servicios publiquen sus últimos valores antes del guardado final.

Durante `DataService.Destroy`:

1. se marca el servicio como cerrándose;
2. se elimina el puente de pruebas;
3. se cancela el temporizador de la cola;
4. se desconectan eventos de jugadores;
5. se toma una lista estable de los perfiles;
6. se guardan y liberan uno por uno;
7. se cancelan cargas restantes y se destruyen señales;
8. se limpia la tabla de perfiles.

El cierre es *best effort*: Roblox limita el tiempo disponible para `BindToClose`. Una indisponibilidad prolongada de DataStore o un cierre instantáneo del proceso todavía pueden impedir el último guardado.

## 13. Garantías y límites reales

| Situación | Comportamiento actual |
|---|---|
| Salida normal | Intenta guardar inmediatamente y liberar la sesión. |
| Cierre normal del servidor | Intenta guardar todos los perfiles después de que los demás servicios publiquen su estado final. |
| Compra de Robux | Se confirma únicamente cuando el recibo y su efecto crítico quedaron persistidos. |
| Dos guardados del mismo jugador | Se serializan; no hay dos escritores simultáneos sobre la clave. |
| Cambio durante una escritura | La revisión nueva permanece `Dirty` y se guarda después. |
| Presupuesto temporalmente agotado | Espera hasta 5 segundos por intento y reintenta. |
| Tres fallos seguidos | Mantiene el perfil pendiente y la cola vuelve a intentar en 30 segundos. |
| Bloqueo de otro servidor | No carga ni sobrescribe; tras agotar intentos, expulsa al jugador en producción. |
| Caída abrupta del proceso | Puede perder cambios no críticos posteriores al último snapshot confirmado. |

### Ventana de posible pérdida

Después de un guardado exitoso, el siguiente checkpoint normal está previsto para 120 segundos. Puede añadirse una demora corta si varios perfiles vencen juntos, porque la cola automática procesa uno a la vez. Una salida normal, un cierre normal o un punto crítico reducen esa ventana al forzar otro guardado.

No hay actualmente un diario de recuperación en `MemoryStoreService`. Por tanto, el sistema reduce el riesgo mediante checkpoints y guardados críticos, pero no puede recuperar cambios que solo estaban en RAM si el proceso desaparece sin ejecutar `PlayerRemoving` ni `BindToClose`.

## 14. Observabilidad

### Atributos disponibles en el jugador

| Atributo | Uso |
|---|---|
| `DataLoaded` | El perfil quedó disponible. |
| `DataLoadFailed` | La carga segura falló. |
| `DataLastSaveSucceeded` | Resultado del último intento publicado. |
| `DataLastSaveAt` | Marca de tiempo del último guardado exitoso. |
| `DataSavePending` | Estado pendiente calculado al publicar el resultado de un intento. |

`DataSavePending` no se actualiza en cada llamada a `MarkProfileDirty`; refleja el estado cuando se publica un resultado de guardado. Para diagnóstico exacto en Studio debe consultarse también `DebugGetProfileState`.

### Diagnóstico exclusivo de Studio

- `DebugGetProfileState`: revisión actual, revisión persistida, Dirty, estado del escritor y próximo autosave.
- `DebugGetAutosaveState`: trabajador inicializado, ticks, autosaves en progreso y máximo concurrente.
- `DebugConfigureStudioMock`: introduce demora o fallos artificiales.
- `DebugForceAutosaveDue`: vence el turno de un perfil para probar la cola.
- `DebugGetStudioRecord`: inspecciona el documento simulado.
- `DataServiceDebugBridge`: permite ejecutar las pruebas contra la instancia real inicializada por `Main`.

En Studio, `useStudioMock()` evita tocar producción aunque `UseStudioMockStore = true`. En servidores publicados, `RunService:IsStudio()` es falso y se utiliza el Standard DataStore real.

### Creator Hub

Después de publicar deben observarse, como mínimo:

- `Write quota usage`, filtrado por `Data Store Type: Standard`;
- `Request count by API`, con desglose por operación;
- `Request count by API and status`;
- estado `StandardWriteExperienceThrottled`;
- picos de `UpdateAsync` y su distribución temporal.

`UpdateAsync` consume presupuesto de lectura y escritura. Los Ordered DataStores de rankings pertenecen a otro flujo y no deben confundirse con el perfil estándar descrito aquí.

## 15. Pruebas ejecutadas

Con el DataStore simulado de Studio se verificó:

- inicialización del trabajador real usado por `Main`;
- primer turno distribuido dentro del rango configurado;
- selección y persistencia de un perfil vencido;
- reprogramación cercana a 120 segundos después del éxito;
- máximo de un autosave automático concurrente;
- máximo de un escritor concurrente por jugador;
- mutación nueva mientras un snapshot anterior estaba en vuelo;
- permanencia de `Dirty` tras un fallo inyectado;
- recuperación mediante un intento posterior;
- cierre de la puerta de mutaciones antes de liberar la sesión;
- escritura final con `Session = nil`.

La suite devolvió `Passed = true` en concurrencia, recuperación de fallos y liberación. La advertencia de fallo observada durante la prueba fue inyectada deliberadamente.

Estas pruebas validan lógica y concurrencia; no sustituyen una prueba publicada con tráfico real para medir la cuota de Roblox.

## 16. Reglas para futuras modificaciones

1. Nunca llamar `SavePlayerAsync` por cada objeto recogido, tick pasivo o segundo de juego.
2. Para valores calientes, actualizar el estado autoritativo y llamar `MarkProfileDirty`.
3. Para cambios estructurados, usar `UpdateProfile` con un parche pequeño y validado.
4. Reservar el guardado explícito para dinero real, consumos irreversibles, premios importantes y checkpoints definidos.
5. No escribir DataStore desde el cliente ni confiar en cantidades enviadas por el cliente.
6. No sustituir `UpdateAsync` por `SetAsync` sin rediseñar la protección contra concurrencia.
7. Al añadir un campo persistente, actualizar como mínimo `ProfileData`, `copyProfile`, `normalizeProfile` y `UpdateProfile` o su API especializada.
8. Si el campo requiere migración destructiva o reinterpretación económica, incrementar el esquema y crear una migración idempotente.
9. Mantener `SessionLockSeconds` por encima del intervalo, la posible descarga de la cola y los reintentos.
10. Probar siempre fallo, concurrencia y liberación; un caso feliz por sí solo no valida persistencia.

## 17. Operación después de publicar

1. Publicar la versión de Studio.
2. Permitir que los servidores nuevos adopten el código; las sesiones antiguas continuarán con su versión previa hasta cerrarse.
3. Comparar al menos una a tres horas equivalentes de tráfico.
4. Confirmar que bajó el promedio de Standard Write y que los picos están más distribuidos.
5. Confirmar que `StandardWriteExperienceThrottled` desaparece o cae a un nivel residual.
6. Revisar advertencias `[DataService] Failed to save` y fallos de carga.
7. Si la cuota continúa alta, medir primero los guardados críticos por servicio antes de ampliar el intervalo.

## 18. Limitaciones pendientes y posibles mejoras

- La cola limita autosaves, pero no impone un límite global a los guardados críticos de jugadores distintos.
- `BindToClose` guarda perfiles secuencialmente y sigue sujeto al tiempo de cierre de Roblox.
- No existe todavía un journal temporal en MemoryStore para recuperar el progreso posterior al último checkpoint tras una caída instantánea.
- No hay una métrica de producción propia que etiquete cada escritura por motivo; hoy el origen se infiere por servicio y por las gráficas de Roblox.
- Las ediciones de `ModuleScript` pueden conservarse en la caché de `require` del modo Edit; las pruebas deben iniciar una sesión Play nueva para usar el código actualizado.

Estas limitaciones no invalidan el diseño actual. Definen el siguiente nivel de endurecimiento si el valor económico de segundos individuales de progreso justifica la complejidad adicional.

