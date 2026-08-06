# Reglas permanentes de desarrollo — Stuck to You

Estas reglas aplican a toda persona o agente que trabaje en este proyecto, en cualquier sesión.

## 1. Funcionalidad y pruebas

- Ninguna tarea se marca terminada sin una prueba proporcional al riesgo.
- Probar en Roblox Studio siempre que la herramienta o el estado del lugar lo permita.
- Para gameplay, verificar al menos el camino exitoso, el rechazo/estado inválido y la limpieza o reinicio.
- Registrar en `PLAN_MVP.md` qué se probó y el resultado; no usar checks basados solo en inspección visual del código.
- Si algo no puede probarse, dejarlo explícitamente como pendiente y explicar el bloqueo.

## 2. Rendimiento y ciclo de vida

- Evitar memory leaks, event leaks y crecimiento ilimitado de tablas, instancias, tareas o conexiones.
- Toda conexión persistente debe tener dueño y método de limpieza, o un ciclo de vida igual al del servidor/script claramente justificado.
- Limpiar estado por jugador en `PlayerRemoving` y estado por instancia cuando la instancia desaparece.
- Preferir pools y reutilización para objetos frecuentes; evitar crear/destruir instancias en loops de alta frecuencia.
- Todos los límites de rendimiento deben ser explícitos y configurables.
- No usar loops infinitos de polling cuando existen eventos; ningún loop frecuente sin condición de salida.
- Validar en servidor todo progreso, premio, compra, requisito y transición importante.

## 3. Arquitectura escalable y desacoplada

- Separar configuración, estado, reglas de dominio, presentación y acceso al mundo.
- Los valores de balance viven en `GameConfig`; cambiar balance no debe exigir editar servicios o UI.
- Los servicios exponen APIs pequeñas y no deben depender de detalles visuales o jerarquías rígidas cuando tags/attributes/config resuelven el problema.
- Preferir módulos reutilizables con dependencias explícitas e inicialización/limpieza claras.
- Evitar referencias circulares entre servicios.
- La UI observa estado replicado y eventos; nunca concede progreso.
- Construir el sistema mínimo correcto. Reutilizable no significa abstraer prematuramente cada línea.

## 4. Reutilización futura

- Código, módulos, servicios, tags y atributos en inglés; documentación de proyecto en español.
- Cada sistema nuevo debe poder entenderse desde su API, configuración y breve nota técnica.
- Evitar nombres o dependencias innecesariamente atados a una única sala si el concepto sirve para otras zonas o juegos.
- Cuando un sistema sea portable, documentar qué carpeta copiar, qué configuración reemplazar y qué contratos requiere.

## 5. UI y modelos editables en Studio

- Toda UI permanente debe existir como una jerarquía authored de `ScreenGui`, `BillboardGui`, `SurfaceGui` u otras instancias visibles y editables desde Roblox Studio.
- El código puede localizar, enlazar, mostrar, ocultar, actualizar o clonar esas plantillas, pero no debe construir por código la jerarquía visual permanente ni decidir su layout base.
- Todo modelo o prop reutilizable debe tener una plantilla authored visible en el DataModel de Studio, para que pueda colocarse y modificarse manualmente en el editor.
- Los sistemas runtime deben referenciar o clonar la plantilla correspondiente; no deben reconstruir por código la geometría permanente del modelo.
- Las instancias puramente transitorias o técnicas solo se permiten cuando no representan UI, arte o modelos editables y su ciclo de vida y limpieza están documentados.
- Si un sistema requiere una plantilla, debe validar su contrato y fallar de forma explícita si falta; no debe sustituirla silenciosamente con UI o geometría generada por código.

### 5.1 Regla dura: si es fijo, se crea en el editor

**Todo lo que el jugador ve —en la UI o en el mundo— y existe en cantidad fija y conocida debe estar creado a mano en el DataModel, visible en el Explorer. El código nunca lo instancia en runtime.** Esto incluye carteles, billboards, letreros, paneles, iconos, marcadores y cualquier adorno de un objeto que ya está colocado en el mapa.

El criterio es *quién decide el aspecto*:

| Caso | Dónde nace la instancia |
| --- | --- |
| Cantidad fija y conocida (8 placas → 8 carteles) | **Authored, una por una**, hija del objeto al que pertenece |
| Cantidad variable en runtime (objetos que aparecen y desaparecen) | Plantilla authored que el código clona |
| Lista repetida a partir de configuración | Plantilla authored de una fila que el código clona |

Aunque el contenido sea distinto por jugador, **eso no justifica crear la instancia por código**: las escrituras del cliente sobre instancias del Workspace son locales, así que un cartel authored y compartido puede mostrar texto y color distintos a cada jugador. El código solo escribe texto, color y visibilidad; **el tamaño, la posición, el offset, la fuente y el layout son del editor**.

Motivo: si el cartel nace en runtime, cambiar su tamaño o subirlo unos studs obliga a editar código en vez de arrastrarlo en Studio, que es justo lo que esta regla existe para evitar.

## 6. Seguimiento

- `PLAN_MVP.md` es el tablero de alcance y progreso.
- `PROJECT_MEMORY.md` guarda estado, decisiones, pruebas y próximos pasos.
- Actualizar ambos al cerrar una fase verificable.
- Inspeccionar el lugar antes de editar y preservar trabajo existente que no esté dentro del cambio solicitado.
