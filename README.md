# 🔥 Campamento — Camp system for AzerothCore 3.3.5a

**🌐 Language / Idioma:** [🇪🇸 Español](#-español) · [🇬🇧 English](#-english)

---

<a id="-español"></a>
# 🇪🇸 Español

Sistema de **campamentos con beneficios por profesión** para servidores AzerothCore (WotLK 3.3.5a) con [mod-ale](https://github.com/azerothcore/mod-ale).
Inspirado en el artículo de Blizzard *"Reuníos alrededor de la hoguera en World of Warcraft: Forever"*.

Está pensado para servidores **offline con bots (playerbots)**: los bots quedan fuera del sistema y solo lo usan los jugadores reales.

## ¿Qué es?

Cuando un jugador enciende una **Hoguera básica** (la de Cocina) se forma un **campamento**. El líder coloca objetos de profesión alrededor del fuego, usando las profesiones de los miembros de su grupo que estén cerca. Quien se sienta junto al fuego durante **1 minuto** recibe **el beneficio de cada profesión colocada durante 1 hora**.

| Parte | Qué es | Dónde va |
|---|---|---|
| `Campamento_server.lua` | Script principal: campamentos, grupo, cooldown, objetos visuales, comandos y API para los módulos | `lua_scripts` |
| `Camp_<profesión>.lua` (13 archivos) | Un módulo por profesión con su beneficio | `lua_scripts` |
| `Campamento_spells.sql` | Hechizos propios (auras) que usan algunos módulos | Base de datos **world** |
| `Campamento/` | Addon de cliente: panel del campamento, rango de Cocina, botón de minimapa y fila de buffs | `Interface\AddOns` |

## Cómo funciona

1. **Se forma el campamento.** Un jugador de **nivel 20 o más** lanza *Hoguera básica* (hechizo 818). Por debajo de nivel 20 es solo una hoguera para cocinar.
2. **Huecos según Cocina.** El número de objetos que caben depende de la habilidad de Cocina de quien enciende el fuego:

   | Cocina | Rango de campamento | Huecos |
   |---|---|---|
   | 1 – 224 | 1 | 3 |
   | 225 – 299 | 2 | 4 |
   | 300+ | 3 | 5 |

   El panel del addon muestra tu Cocina actual y **cuántos puntos faltan para el siguiente rango**.
3. **El líder coloca los objetos** con `.camp poner <profesión>` o con un clic en el panel. Puede usar las profesiones (habilidad 20 o más) de los miembros de su grupo que estén a 60 yardas o menos. Quien aporta el objeto recibe el cooldown (por defecto 1 hora). No se puede colocar en combate.
4. **Aparecen objetos visuales** alrededor de la hoguera (un modelo distinto por profesión). Desaparecen cuando termina el campamento (5 minutos).
5. **Sentarse junto al fuego.** Quien se queda sentado 1 minuto a menos de 15 yardas recibe los beneficios durante 1 hora. Se mantienen aunque te alejes.
6. **El addon lo muestra.** El servidor manda mensajes de sistema ocultos (`CAMPDATA#…`, `CAMPPOOL#…`, `CAMPBUFF#…`, `CAMPCOCINA#…`) que el addon recoge para dibujar el panel, las profesiones disponibles, el rango de Cocina y la fila de buffs con cuenta atrás.

### Arquitectura de módulos

`Campamento_server.lua` expone una pequeña API global que usan los módulos:

```lua
Campamento.TieneBuff(player, "ingenieria")  -- ¿tiene ese buff activo?
Campamento.Debug(player, "texto")           -- mensaje de depuración en el chat
```

Cada `Camp_<profesión>.lua` es independiente: si uno falla, el resto sigue funcionando.

## Beneficios por profesión

Los porcentajes se calculan sobre tus estadísticas, así que **escalan solos con el nivel y el equipo**.

| Profesión | Objeto | Beneficio |
|---|---|---|
| **Herrería** | Fragua | +3 % fuerza y agilidad |
| **Alquimia** | Laboratorio de alquimia | Cada 5 s regenera maná = maná máximo × (1 + nivel/80) %. Si la clase no usa maná, regenera vida |
| **Encantamiento** | Gema flotante | +2 % a todas las estadísticas, +5 % armadura, resistencias mágicas = nivel × 0,5 |
| **Herboristería** | Ramo de flores | +10 a todas las habilidades de profesión |
| **Sastrería** | Cajas de vendas | +2 % espíritu, +5 % daño de hechizos, +5 % sanación *(solo misma facción)* |
| **Peletería** | Tienda de campaña | +10 % experiencia y +10 % reputación |
| **Minería** | Buzón | +5 % poder de ataque |
| **Desuello** | Secadero de carne | +2 % probabilidad de golpe crítico |
| **Ingeniería** | Caja de munición | 2 % por golpe de provocar una explosión de fuego en área: daño del golpe × (0,5 + nivel/80), 8 yardas, máx. 5 enemigos, 6 s de enfriamiento |
| **Joyería** | Caja precintada | +15 % velocidad a pie, +20 % montado (+10 % si eres paladín con Aura de cruzado) |
| **Primeros auxilios** | Cajas de suministros | +5 % vida máxima |
| **Pesca** | Pescado del día | +5 % a todas las estadísticas |
| **Inscripción** | Orbe de Grishnath | Al recoger un objeto, copia extra: 5 % común, 3 % poco común, 2 % raro |

> Los valores son un punto de partida y se ajustan en la sección `CFG` de cada módulo.

## Requisitos

- **AzerothCore** (3.3.5a) con el módulo **[mod-ale](https://github.com/azerothcore/mod-ale)**.
- Cliente 3.3.5a (build 12340) para el addon.
- Acceso a la base de datos **world** (para el SQL).

> ⚠️ mod-ale **no es compatible con el Eluna original**. Los scripts están escritos para su API.

## Instalación

### 1. Servidor

1. Copia en `lua_scripts`: `Campamento_server.lua` y los 13 archivos `Camp_*.lua`.
2. Ejecuta `Campamento_spells.sql` en la base de datos **world** (`acore_world`).
3. **Reinicia el worldserver.** Es imprescindible para cargar los hechizos nuevos; un `.reload` no basta.

> Si tenías un `campamento.lua` antiguo en `lua_scripts`, bórralo para evitar scripts duplicados.

### 2. Cliente (addon)

1. Copia la carpeta `Campamento` en `Interface\AddOns`.
2. En la pantalla de personajes, comprueba que **Campamento** aparece activado.
3. Entra al juego. Debe aparecer un botón en el minimapa.

## Comandos

### Para todos los jugadores

| Comando | Qué hace |
|---|---|
| `.camp ayuda` | Lista las profesiones |
| `.camp estado` | Estado del campamento más cercano |
| `.camp poner <profesión>` | Coloca el objeto de esa profesión |
| `.camp cocina` | Envía al addon tu Cocina y lo que falta para el siguiente rango |

### Addon (`/campamento`)

| Comando | Qué hace |
|---|---|
| `/campamento` | Abre o cierra el panel |
| `/campamento minimapa` | Muestra u oculta el botón del minimapa |
| `/campamento buffs` | Muestra buffs de prueba en la fila (sin servidor) |
| `/campamento test` | Campamento de prueba solo visual |
| `/campamento debug` | Escribe en el chat los mensajes recibidos del servidor |

La fila de buffs se mueve con **Mayús + arrastrar**.

### Solo GM (pruebas)

| Comando | Qué hace |
|---|---|
| `.camp crear` | Crea un campamento sin lanzar el hechizo |
| `.camp dar <profesión>` | Activa el buff de un módulo directamente |
| `.camp resetcd` / `.camp cd <seg>` | Borra los cooldowns / cambia el cooldown (0 = sin cooldown) |
| `.camp multi` | Permite colocar varios objetos por jugador |
| `.camp objetos` | Lista el modelo visual de cada profesión |
| `.camp buscar <texto>` | Busca modelos (gameobjects) por nombre en inglés |
| `.camp probar <id>` | Muestra 30 s un modelo delante de ti |
| `.camp modelo <profesión> <id>` | Fija el modelo de una profesión (0 = quitarlo) |
| `.camp efecto <id> [v1] [v2]` | Lanza un hechizo sobre tu objetivo, para probar efectos visuales |
| `.camp debug` | Muestra el ID de cada hechizo que lanzas |

## Configuración

Ajustes principales al principio de `Campamento_server.lua` (`CFG`):

| Ajuste | Por defecto | Descripción |
|---|---|---|
| `NIVEL_PERSONAJE` | 20 | Nivel mínimo para formar un campamento |
| `NIVEL_HABILIDAD` | 20 | Habilidad mínima de la profesión para colocar su objeto |
| `RADIO` | 15 | Yardas para recibir los beneficios |
| `RADIO_GRUPO` | 60 | Yardas máximas a las que un miembro del grupo puede aportar |
| `DURACION_CAMPAMENTO` | 300 | Segundos que dura el campamento |
| `TIEMPO_SENTADO` | 60 | Segundos sentado para recibir los beneficios |
| `DURACION_BUFF` | 3600 | Segundos que dura cada beneficio |
| `COOLDOWN_SEGUNDOS` | 3600 | Cooldown de quien aporta un objeto (0 = sin cooldown) |
| `HUECOS_POR_COCINA` | 3 / 4 / 5 | Huecos según la habilidad de Cocina (el panel lo lee de aquí) |
| `SOLO_LIDER_COLOCA` | true | Solo el líder coloca objetos |
| `PREFIJOS_BOT` | `rndbot` | Prefijo de las cuentas de bots, excluidas del sistema |
| `DEBUG_BUFFS` | true | Avisos de depuración en el chat al activarse o caducar un buff |

Cada módulo tiene su propia sección `CFG`. Los avisos de depuración se desactivan con `DEBUG_AURA = false` (o la variante equivalente) en cada módulo y con `DEBUG_BUFFS = false` en el script principal.

## Hechizos propios (`Campamento_spells.sql`)

| ID | Uso |
|---|---|
| 900002 | Herrería |
| 900003 | Encantamiento |
| 900004 – 900008 | Herboristería (5 hechizos, 3 profesiones cada uno) |
| 900009 | Minería |
| 900010 | Desuello |
| 900011 | Sastrería |
| 900012 | Joyería |
| 900013 | Primeros auxilios |
| 900016 | Pesca |

Los valores finales los fija cada módulo al lanzar el hechizo (`CastCustomSpell`); los del SQL son el valor por defecto. Si cambias un ID, cámbialo también en el módulo.

## Limitaciones conocidas

- **Los hechizos propios no salen en la barra de buffs oficial.** El cliente no conoce esos IDs (haría falta parchear `Spell.dbc`). Para eso existe la fila de buffs del addon, con icono, tiempo restante y descripción.
- **La explosión de ingeniería no tiene animación.** El daño se aplica directamente. Se puede añadir un efecto cosmético con `SPELL_VISUAL` en `Camp_ingenieria.lua` (se elige con `.camp efecto <id>`).
- **Los buffs de módulo no sobreviven a un reinicio del servidor.** Se mantienen en memoria; tras reiniciar, hay que volver a sentarse en un campamento.
- Algunos IDs de hechizos externos (como el Aura de cruzado, 32223) están puestos de memoria: compruébalos con `.lookup spell` si algo no responde.
- Los bots (cuentas `rndbot…`) no participan: no forman campamentos, no reciben beneficios ni activan los efectos.

## Solución de problemas

| Síntoma | Posible causa |
|---|---|
| El cliente dice que el addon es incompatible | `Campamento.toc` vacío o mal colocado (debe empezar por `## Interface: 30300`) |
| No aparece el botón del minimapa | Addon desactivado o carpeta mal colocada (`AddOns\Campamento\Campamento.toc`) |
| Un módulo avisa de que no puede poner el hechizo | No se ejecutó el SQL o falta reiniciar el worldserver |
| Los objetos visuales no coinciden | Elige otro modelo con `.camp buscar`, `.camp probar` y `.camp modelo` |
| No pasa nada al encender la hoguera | Nivel menor de 20, o el script no está cargado (revisa la consola al arrancar) |
| El panel dice "Cocina: consultando…" | Aún no ha llegado la respuesta del servidor; ciérralo y ábrelo de nuevo |

## Estructura del proyecto

```
.
├── README.md
├── Campamento_spells.sql
├── lua_scripts/
│   ├── Campamento_server.lua
│   ├── Camp_alquimia.lua        ├── Camp_mineria.lua
│   ├── Camp_desuello.lua        ├── Camp_peleteria.lua
│   ├── Camp_encantamiento.lua   ├── Camp_pesca.lua
│   ├── Camp_herboristeria.lua   ├── Camp_primerosauxilios.lua
│   ├── Camp_herreria.lua        ├── Camp_sastreria.lua
│   ├── Camp_ingenieria.lua
│   ├── Camp_inscripcion.lua
│   └── Camp_joyeria.lua
└── Campamento/              (addon)
    ├── Campamento.toc
    └── Campamento.lua
```

## Estado

Proyecto en desarrollo y pruebas. Los valores de equilibrio son ajustables y pueden cambiar.

[⬆ Volver arriba / Back to top](#-campamento--camp-system-for-azerothcore-335a)

---

<a id="-english"></a>
# 🇬🇧 English

A **camp system with profession-based benefits** for AzerothCore (WotLK 3.3.5a) servers running [mod-ale](https://github.com/azerothcore/mod-ale).
Inspired by Blizzard's article *"Gather Around the Campfire in World of Warcraft: Forever"*.

It is designed for **offline servers full of bots (playerbots)**: bots are excluded from the system and only real players use it.

## What is it?

When a player lights a **Basic Campfire** (the Cooking one), a **camp** is formed. The camp leader places profession objects around the fire, using the professions of nearby party members. Anyone who sits by the fire for **1 minute** receives **the benefit of every placed profession for 1 hour**.

| Part | What it is | Where it goes |
|---|---|---|
| `Campamento_server.lua` | Main script: camps, party logic, cooldown, visual objects, commands and the module API | `lua_scripts` |
| `Camp_<profession>.lua` (13 files) | One module per profession with its benefit | `lua_scripts` |
| `Campamento_spells.sql` | Custom spells (auras) used by some modules | **world** database |
| `Campamento/` | Client addon: camp panel, Cooking rank, minimap button and buff row | `Interface\AddOns` |

## How it works

1. **The camp is formed.** A player of **level 20 or higher** casts *Basic Campfire* (spell 818). Below level 20 it is just a cooking fire.
2. **Slots depend on Cooking.** The number of objects that fit depends on the Cooking skill of whoever lights the fire:

   | Cooking | Camp rank | Slots |
   |---|---|---|
   | 1 – 224 | 1 | 3 |
   | 225 – 299 | 2 | 4 |
   | 300+ | 3 | 5 |

   The addon panel shows your current Cooking and **how many points are missing for the next rank**.
3. **The leader places the objects** with `.camp poner <profession>` (`poner` = "place") or by clicking in the panel. They can use the professions (skill 20 or higher) of party members within 60 yards. Whoever provides the object receives the cooldown (1 hour by default). Objects cannot be placed in combat.
4. **Visual objects appear** around the fire (a different model per profession). They disappear when the camp ends (5 minutes).
5. **Sit by the fire.** Anyone who stays seated for 1 minute within 15 yards receives the benefits for 1 hour. They stay even if you walk away.
6. **The addon displays it.** The server sends hidden system messages (`CAMPDATA#…`, `CAMPPOOL#…`, `CAMPBUFF#…`, `CAMPCOCINA#…`) that the addon picks up to draw the panel, the available professions, the Cooking rank and the buff row with countdowns.

### Module architecture

`Campamento_server.lua` exposes a small global API used by the modules:

```lua
Campamento.TieneBuff(player, "ingenieria")  -- does the player have that buff active?
Campamento.Debug(player, "text")            -- debug message in chat
```

Every `Camp_<profession>.lua` is independent: if one fails, the rest keep working.

## Benefits by profession

Percentages are applied on top of your stats, so they **scale automatically with level and gear**.

| Profession | Object | Benefit |
|---|---|---|
| **Blacksmithing** (`herreria`) | Forge | +3% Strength and Agility |
| **Alchemy** (`alquimia`) | Alchemy lab | Every 5 s restores mana = max mana × (1 + level/80)%. Classes without mana regenerate health instead |
| **Enchanting** (`encantamiento`) | Floating gem | +2% to all stats, +5% armor, magic resistances = level × 0.5 |
| **Herbalism** (`herboristeria`) | Bouquet of flowers | +10 to all profession skills |
| **Tailoring** (`sastreria`) | Bandage crates | +2% Spirit, +5% spell damage, +5% healing *(same faction only)* |
| **Leatherworking** (`peleteria`) | Camp tent | +10% experience and +10% reputation |
| **Mining** (`mineria`) | Mailbox | +5% attack power |
| **Skinning** (`desuello`) | Meat rack | +2% critical strike chance |
| **Engineering** (`ingenieria`) | Ammo box | 2% chance per hit to trigger an area fire explosion: hit damage × (0.5 + level/80), 8 yards, max 5 enemies, 6 s internal cooldown |
| **Jewelcrafting** (`joyeria`) | Sealed crate | +15% movement speed on foot, +20% mounted (+10% for paladins with Crusader Aura) |
| **First Aid** (`primerosauxilios`) | Supply crates | +5% max health |
| **Fishing** (`pesca`) | Fish of the day | +5% to all stats |
| **Inscription** (`inscripcion`) | Grishnath's orb | When looting an item, chance of an extra copy: 5% common, 3% uncommon, 2% rare |

> Values are a starting point and can be tuned in each module's `CFG` section.

## Requirements

- **AzerothCore** (3.3.5a) with the **[mod-ale](https://github.com/azerothcore/mod-ale)** module.
- A 3.3.5a client (build 12340) for the addon.
- Access to the **world** database (for the SQL file).

> ⚠️ mod-ale is **not compatible with the original Eluna**. The scripts are written for its API.

## Installation

### 1. Server

1. Copy to `lua_scripts`: `Campamento_server.lua` and the 13 `Camp_*.lua` files.
2. Run `Campamento_spells.sql` on the **world** database (`acore_world`).
3. **Restart the worldserver.** This is required to load the new spells; a `.reload` is not enough.

> If you had an old `campamento.lua` in `lua_scripts`, delete it to avoid duplicated scripts.

### 2. Client (addon)

1. Copy the `Campamento` folder into `Interface\AddOns`.
2. On the character screen, check that **Campamento** is enabled.
3. Log in. A minimap button should appear.

## Commands

### For all players

| Command | What it does |
|---|---|
| `.camp ayuda` | Lists the professions |
| `.camp estado` | Status of the nearest camp |
| `.camp poner <profession>` | Places that profession's object |
| `.camp cocina` | Sends your Cooking skill and the points left for the next rank to the addon |

### Addon (`/campamento`)

| Command | What it does |
|---|---|
| `/campamento` | Opens or closes the panel |
| `/campamento minimapa` | Shows or hides the minimap button |
| `/campamento buffs` | Shows test buffs in the row (no server needed) |
| `/campamento test` | Visual-only test camp |
| `/campamento debug` | Prints every message received from the server in chat |

The buff row can be moved with **Shift + drag**.

### GM only (testing)

| Command | What it does |
|---|---|
| `.camp crear` | Creates a camp without casting the spell |
| `.camp dar <profession>` | Activates a module's buff directly |
| `.camp resetcd` / `.camp cd <sec>` | Clears all cooldowns / changes the cooldown (0 = no cooldown) |
| `.camp multi` | Allows several objects per player |
| `.camp objetos` | Lists the visual model of each profession |
| `.camp buscar <text>` | Searches models (gameobjects) by English name |
| `.camp probar <id>` | Shows a model in front of you for 30 s |
| `.camp modelo <profession> <id>` | Sets a profession's model (0 = remove it) |
| `.camp efecto <id> [v1] [v2]` | Casts a spell on your target, to test visual effects |
| `.camp debug` | Shows the ID of every spell you cast |

## Configuration

Main settings at the top of `Campamento_server.lua` (`CFG`):

| Setting | Default | Description |
|---|---|---|
| `NIVEL_PERSONAJE` | 20 | Minimum character level to form a camp |
| `NIVEL_HABILIDAD` | 20 | Minimum profession skill to place its object |
| `RADIO` | 15 | Yards to receive the benefits |
| `RADIO_GRUPO` | 60 | Max yards at which a party member can contribute |
| `DURACION_CAMPAMENTO` | 300 | Seconds the camp lasts |
| `TIEMPO_SENTADO` | 60 | Seconds seated to receive the benefits |
| `DURACION_BUFF` | 3600 | Seconds each benefit lasts |
| `COOLDOWN_SEGUNDOS` | 3600 | Cooldown for whoever provides an object (0 = none) |
| `HUECOS_POR_COCINA` | 3 / 4 / 5 | Slots by Cooking skill (the panel reads it from here) |
| `SOLO_LIDER_COLOCA` | true | Only the leader places objects |
| `PREFIJOS_BOT` | `rndbot` | Bot account prefix, excluded from the system |
| `DEBUG_BUFFS` | true | Chat debug notices when a buff activates or expires |

Each module has its own `CFG` section. Debug notices are turned off with `DEBUG_AURA = false` (or the equivalent) in each module and `DEBUG_BUFFS = false` in the main script.

## Custom spells (`Campamento_spells.sql`)

| ID | Used by |
|---|---|
| 900002 | Blacksmithing |
| 900003 | Enchanting |
| 900004 – 900008 | Herbalism (5 spells, 3 professions each) |
| 900009 | Mining |
| 900010 | Skinning |
| 900011 | Tailoring |
| 900012 | Jewelcrafting |
| 900013 | First Aid |
| 900016 | Fishing |

Final values are set by each module when casting the spell (`CastCustomSpell`); the SQL values are only defaults. If you change an ID, change it in the module too.

## Known limitations

- **Custom spells do not appear in the default buff bar.** The client does not know those IDs (patching `Spell.dbc` would be needed). That is why the addon has its own buff row, with icon, remaining time and description.
- **The Engineering explosion has no animation.** The damage is applied directly. A cosmetic effect can be added with `SPELL_VISUAL` in `Camp_ingenieria.lua` (pick one with `.camp efecto <id>`).
- **Module buffs do not survive a server restart.** They are kept in memory; after a restart, players must sit at a camp again.
- Some external spell IDs (such as Crusader Aura, 32223) were written from memory: check them with `.lookup spell` if something does not respond.
- Bots (`rndbot…` accounts) do not take part: they do not form camps, receive benefits or trigger effects.

## Troubleshooting

| Symptom | Possible cause |
|---|---|
| The client says the addon is incompatible | `Campamento.toc` is empty or misplaced (it must start with `## Interface: 30300`) |
| No minimap button | Addon disabled or wrong folder (`AddOns\Campamento\Campamento.toc`) |
| A module warns it cannot apply the spell | The SQL was not run, or the worldserver was not restarted |
| Visual objects do not match | Pick another model with `.camp buscar`, `.camp probar` and `.camp modelo` |
| Nothing happens when lighting the fire | Level below 20, or the script is not loaded (check the console at startup) |
| The panel says "Cocina: consultando…" | The server reply has not arrived yet; close and reopen the panel |

## Project structure

```
.
├── README.md
├── Campamento_spells.sql
├── lua_scripts/
│   ├── Campamento_server.lua
│   ├── Camp_alquimia.lua        ├── Camp_mineria.lua
│   ├── Camp_desuello.lua        ├── Camp_peleteria.lua
│   ├── Camp_encantamiento.lua   ├── Camp_pesca.lua
│   ├── Camp_herboristeria.lua   ├── Camp_primerosauxilios.lua
│   ├── Camp_herreria.lua        ├── Camp_sastreria.lua
│   ├── Camp_ingenieria.lua
│   ├── Camp_inscripcion.lua
│   └── Camp_joyeria.lua
└── Campamento/              (addon)
    ├── Campamento.toc
    └── Campamento.lua
```

<img width="842" height="555" alt="1" src="https://github.com/user-attachments/assets/83685126-3f68-4dab-8c4a-e1dbbc2d15b5" />


## Status

Work in progress and under testing. Balance values are tunable and may change.

[⬆ Back to top / Volver arriba](#-campamento--camp-system-for-azerothcore-335a)
