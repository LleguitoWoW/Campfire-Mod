--[[
    Campamento_server.lua  -  Sistema de campamento para AzerothCore 3.3.5a (Eluna / mod-eluna)  -  v7.6
    Inspirado en "Reuníos alrededor de la hoguera" (WoW: Forever).

    Funcionamiento:
      1. Un jugador lanza "Hoguera básica" (hechizo 818 de Cocina). Se registra un campamento
         en ese punto durante CFG.DURACION_CAMPAMENTO segundos. Los huecos disponibles
         dependen de la habilidad de Cocina de quien la enciende (CFG.HUECOS_POR_COCINA).
      2. El LÍDER del campamento (quien enciende la hoguera) coloca los objetos con
         ".camp poner <profesion>". Puede usar cualquier profesión (nivel >= 20) de los
         miembros de su grupo que estén cerca: esa persona "aporta" el objeto y es ella
         quien recibe el cooldown. No se puede en combate. Con SOLO_LIDER_COLOCA = false
         cada miembro cercano puede colocar también el suyo.
      3. Quien permanezca SENTADO cerca 1 minuto recibe los beneficios (1 hora).
         El rango del beneficio depende del nivel de quien lo recibe. Si sube de nivel
         y le corresponde un rango mejor, se actualiza la próxima vez que se siente
         en un campamento (conserva el tiempo restante del buff anterior).
      4. Los bots (cuentas que empiezan por "rndbot") quedan fuera de todo el sistema.
      5. Cada objeto colocado aparece como un objeto visual alrededor de la hoguera y
         desaparece cuando termina el campamento (ver OBJETOS_VISUALES).

    Comandos:
      .camp ayuda            lista de profesiones
      .camp estado           estado del campamento más cercano
      .camp poner <prof.>    coloca tu objeto de profesión
      .camp resetcd          (solo GM) borra todos los cooldowns
      .camp cd <segundos>    (solo GM) cambia el cooldown sin recargar (0 = sin cooldown)
      .camp crear            (solo GM) crea un campamento aquí sin lanzar el hechizo (para pruebas)
      .camp debug            (solo GM) muestra en el juego el ID de cada hechizo que lanzas
      .camp multi            (solo GM) permite colocar varios objetos por jugador (modo pruebas)
      .camp objetos          (solo GM) lista qué modelo visual tiene cada profesión
      .camp buscar <texto>   (solo GM) busca modelos (gameobjects) por nombre en inglés
      .camp probar <id>      (solo GM) muestra 30 s ese modelo delante de ti
      .camp modelo <prof.> <id>  (solo GM) fija el modelo de una profesión (se guarda; id 0 = quitarlo)

    Instalación: copiar a lua_scripts y ejecutar ".reload eluna".
]]

----------------------------------------------------------------------
-- CONFIGURACIÓN (todo lo que vas a querer tocar en las pruebas)
----------------------------------------------------------------------
local CFG = {
    -- Hechizos que crean un campamento. 818 = Basic Campfire (Cocina).
    -- Si tu hoguera usa otro ID, actívalo con ".camp debug", lanza la hoguera y añádelo aquí.
    SPELLS_HOGUERA      = { [818] = true },
    DEBUG               = false,
    DEBUG_BUFFS         = true,   -- avisa en el chat cuando un buff se activa o caduca (para pruebas)

    -- true = cada jugador puede colocar UN solo objeto por campamento (como en el artículo).
    -- Para pruebas en solitario: ".camp multi" lo desactiva sin recargar.
    UN_OBJETO_POR_JUGADOR = true,

    -- true = solo el líder (quien enciende la hoguera) coloca objetos, usando las profesiones
    -- de los miembros de su grupo. false = además, cada miembro cercano puede colocar el suyo.
    SOLO_LIDER_COLOCA     = true,
    RADIO_GRUPO           = 60.0,   -- yardas: los miembros del grupo deben estar así de cerca para aportar
    RADIO               = 15.0,   -- yardas
    DURACION_CAMPAMENTO = 300,    -- segundos que dura el campamento
    TIEMPO_SENTADO      = 60,     -- segundos sentado para recibir beneficios
    DURACION_BUFF       = 3600,   -- segundos
    NIVEL_PERSONAJE     = 20,     -- nivel de personaje mínimo para formar campamento (antes es solo una hoguera)
    NIVEL_HABILIDAD     = 20,     -- habilidad mínima de la profesión para poner objeto
    TICK_MS             = 5000,

    COOLDOWN_SEGUNDOS   = 3600,   -- cooldown compartido al colocar objeto (0 = sin cooldown)

    BLOQUEAR_BOTS       = true,
    PREFIJOS_BOT        = { "rndbot" },   -- prefijos de nombre de cuenta (en minúsculas)

    SKILL_COCINA        = 185,
    -- { habilidad mínima de Cocina, huecos }. Se aplica el último tramo alcanzado.
    -- 1 = Aprendiz, 225 = Artesano, 300 = Maestro
    HUECOS_POR_COCINA   = { {1, 3}, {225, 4}, {300, 5} },

    -- Peletería (Tienda de campamento): experiencia extra por matar mientras dura el buff
    PELETERIA_XP_EXTRA_PCT = 10,
    -- Ingeniería (Robot regenerador): % de vida máxima que se cura en cada tick (TICK_MS)
    INGENIERIA_REGEN_PCT   = 1.0,
    -- Joyería (Vitrina de gemas): % extra de reputación al ganarla mientras dura el buff
    JOYERIA_REP_EXTRA_PCT  = 10,

    -- Objetos visuales alrededor de la hoguera
    OBJETOS_VISUALES       = true,
    RADIO_OBJETOS          = 2.0,   -- distancia a la hoguera en yardas
}

----------------------------------------------------------------------
-- Rangos tomados de los pergaminos de tu base de datos (item_template).
-- patron: expresión regular (MySQL REGEXP) sobre el nombre en inglés del objeto.
-- Devuelve { {nivel requerido, ID del hechizo de uso}, ... } ordenado por nivel.
----------------------------------------------------------------------
local function RangosDesdePergaminos(patron)
    local rangos = {}
    local ok, q = pcall(function()
        return WorldDBQuery("SELECT MIN(RequiredLevel), spellid_1 FROM item_template WHERE name REGEXP '" .. patron .. "' AND spellid_1 > 0 GROUP BY spellid_1 ORDER BY MIN(RequiredLevel)")
    end)
    if ok and q then
        repeat
            rangos[#rangos + 1] = { q:GetUInt32(0), q:GetUInt32(1) }
        until not q:NextRow()
    end
    if #rangos == 0 then
        print("[Campamento] AVISO: no se encontraron pergaminos para " .. patron)
    end
    return rangos
end

----------------------------------------------------------------------
-- FUNCIONES DE PROFESIÓN
-- Tipo aura (por defecto): rangos = { {nivel mínimo del RECEPTOR, ID de hechizo}, ... }
--   de menor a mayor. Si el receptor no llega al primer nivel, no recibe nada.
--   Verifica los IDs con ".lookup spell" antes de usarlos en serio.
-- Tipo "xp" y "regen": efectos gestionados por el propio script (sin hechizos).
----------------------------------------------------------------------
local FUNCIONES = {
    primerosauxilios = { nombre = "Cajas de suministros", skill = 129, modulo = true },   -- módulo Camp_primerosauxilios.lua (hechizos 900013-900015)

    -- Encantamiento: la gestiona su propio archivo (Camp_encantamiento.lua). Hechizo propio 900003.
    encantamiento    = { nombre = "Gema flotante", skill = 333, modulo = true },

    -- Herboristería: la gestiona su propio archivo (Camp_herboristeria.lua). Hechizos propios 900004-900008.
    herboristeria    = { nombre = "Ramo de flores", skill = 182, modulo = true },

    -- Alquimia: la gestiona su propio archivo (Camp_alquimia.lua). Sin hechizo de aura.
    alquimia         = { nombre = "Laboratorio de alquimia", skill = 171, modulo = true },
    -- Herrería: la gestiona su propio archivo (Camp_herreria.lua). Hechizo propio 900002 (Campamento_spells.sql).
    herreria         = { nombre = "Fragua", skill = 164, modulo = true },
    -- Espíritu divino (6 rangos). Sin confirmar: 14818, 14819, 27841 y 48073.
    sastreria        = { nombre = "Cajas de vendas", skill = 197, faccion = true, modulo = true },   -- módulo Camp_sastreria.lua (hechizo 900011)

    pesca            = { nombre = "Pescado del día", skill = 356, modulo = true },   -- módulo Camp_pesca.lua (hechizo 900016)

    -- Hechizo PROPIO (+2% crítico con ataques y hechizos). Hay que crearlo antes con Campamento_spells.sql
    -- y reiniciar el worldserver. Si cambias el ID, cámbialo también en el SQL.
    desuello         = { nombre = "Secadero de carne", skill = 393, modulo = true },   -- módulo Camp_desuello.lua (hechizo 900010)  -- Bendición de poderío (poder de ataque)

    -- Efectos propios del script
    -- Peletería: la gestiona su propio archivo (Camp_peleteria.lua). Sin hechizos.
    peleteria        = { nombre = "Tienda de campaña", skill = 165, modulo = true },
    -- Ingeniería: la gestiona su propio archivo (Camp_ingenieria.lua). Sin hechizo de aura.
    ingenieria       = { nombre = "Caja de munición", skill = 202, modulo = true },

    -- Pergaminos (rangos leídos de tu base de datos, igual que la herrería)
    mineria          = { nombre = "Buzón", skill = 186, modulo = true },   -- módulo Camp_mineria.lua (hechizo 900009)
    inscripcion      = { nombre = "Orbe de Grishnath", skill = 773, modulo = true },   -- módulo Camp_inscripcion.lua (sin hechizos)
    -- Efecto propio del script: reputación extra
    joyeria          = { nombre = "Caja precintada", skill = 755, modulo = true },   -- módulo Camp_joyeria.lua (hechizo 900012)
}

----------------------------------------------------------------------
-- OBJETOS VISUALES
-- Cada profesión puede tener un modelo (gameobject_template.entry). Se decide así:
--   1) 'buscar' = nombres EXACTOS en inglés que se prueban por orden. Son solo suposiciones:
--      si no existe ninguno, la profesión queda sin modelo (no se coge nada "parecido").
--   2) Lo que elijas con ".camp modelo <profesión> <id>" se guarda en la base de datos
--      (tabla campamento_modelos, en characters) y manda sobre lo anterior.
-- Para elegir: ".camp buscar <texto>", ".camp probar <id>" y, si te gusta, ".camp modelo ...".
----------------------------------------------------------------------
local OBJETOS_VISUALES = {
    -- 'fijo' = entry elegido por ti. '.camp modelo' (base de datos) sigue mandando sobre él.
    herreria         = { fijo = 1749 },     -- Forge
    alquimia         = { fijo = 183848 },   -- Alchemy Lab
    desuello         = { fijo = 176454 },   -- Meat Rack
    herboristeria    = { fijo = 181063 },   -- Flowers for Tony
    encantamiento    = { fijo = 181447 },   -- Signaling Gem
    primerosauxilios = { fijo = 188234 },   -- Cargo Boxes
    pesca            = { fijo = 181143 },   -- Fish of the Day
    sastreria        = { fijo = 181129 },   -- Front Line Bandage Crates
    peleteria        = { fijo = 181254 },   -- Argent Dawn Buffer Tent
    ingenieria       = { fijo = 191139 },   -- WotLK Light Ammo Box
    mineria          = { fijo = 177044 },   -- Mailbox
    joyeria          = { fijo = 178324 },   -- DANGER! Do Not Open! Move Along!
    inscripcion      = { fijo = 185185 },   -- Grishnath Orb
}

local function NombreGO(entry)
    local ok, q = pcall(function()
        return WorldDBQuery("SELECT name FROM gameobject_template WHERE entry = " .. math.floor(tonumber(entry) or 0))
    end)
    if ok and q then return q:GetString(0) end
    return nil
end

-- entry = nil borra la elección guardada
local function GuardarModelo(clave, entry)
    pcall(function()
        if entry then
            CharDBExecute("REPLACE INTO campamento_modelos (clave, entry) VALUES ('" .. clave .. "', " .. math.floor(entry) .. ")")
        else
            CharDBExecute("DELETE FROM campamento_modelos WHERE clave = '" .. clave .. "'")
        end
    end)
end

-- Crea un gameobject 30 s delante del jugador para ver cómo se ve
local function Previsualizar(player, entry)
    local o = player:GetO()
    local ok = pcall(function()
        return player:SummonGameObject(entry, player:GetX() + math.cos(o) * 2, player:GetY() + math.sin(o) * 2, player:GetZ(), o + math.pi, 30)
    end)
    return ok
end

local function ResolverObjetosVisuales()
    if not CFG.OBJETOS_VISUALES then return end

    pcall(function()
        CharDBExecute("CREATE TABLE IF NOT EXISTS campamento_modelos (clave VARCHAR(32) NOT NULL, entry INT UNSIGNED NOT NULL, PRIMARY KEY (clave))")
    end)

    -- 0) modelos fijos del script
    for clave, v in pairs(OBJETOS_VISUALES) do
        if v.fijo then
            v.entry = v.fijo
            v.nombreGO = (NombreGO(v.fijo) or "?") .. " [fijo]"
        end
    end

    -- 1) nombres exactos por defecto
    for clave, v in pairs(OBJETOS_VISUALES) do
        if not v.fijo and v.buscar and #v.buscar > 0 then
            local lista = {}
            for _, n in ipairs(v.buscar) do lista[#lista + 1] = "'" .. n .. "'" end
            local nombres = table.concat(lista, ",")
            local ok, q = pcall(function()
                return WorldDBQuery("SELECT entry, name FROM gameobject_template WHERE type IN (5,7,8) AND displayId > 0 AND name IN (" .. nombres .. ") ORDER BY FIELD(name," .. nombres .. "), entry LIMIT 1")
            end)
            if ok and q then
                v.entry = q:GetUInt32(0)
                v.nombreGO = q:GetString(1)
            end
        end
    end

    -- 2) elecciones guardadas con .camp modelo (mandan sobre lo anterior)
    local ok, q = pcall(function() return CharDBQuery("SELECT clave, entry FROM campamento_modelos") end)
    if ok and q then
        repeat
            local clave, entry = q:GetString(0), q:GetUInt32(1)
            if OBJETOS_VISUALES[clave] then
                OBJETOS_VISUALES[clave].entry = entry
                OBJETOS_VISUALES[clave].nombreGO = (NombreGO(entry) or "?") .. " [elegido]"
            end
        until not q:NextRow()
    end

    for clave, v in pairs(OBJETOS_VISUALES) do
        if v.entry then
            print(string.format("[Campamento] Modelo %s -> %d (%s)", clave, v.entry, v.nombreGO or "?"))
        else
            print("[Campamento] Sin modelo para " .. clave .. " (usa .camp buscar / .camp modelo)")
        end
    end
end
ResolverObjetosVisuales()

----------------------------------------------------------------------
-- Estado en memoria
----------------------------------------------------------------------
local camps        = {}   -- [id] = { mapa, x, y, z, expira, maxHuecos, slots = { {guid, jugador, nombre, clave, equipo} } }
local siguienteId  = 1
local sentado      = {}   -- [guidLow] = segundos sentado dentro de un campamento
local cooldowns    = {}   -- [guidLow] = timestamp de fin de cooldown
local botCache     = {}   -- [guidLow] = true/false
local enCamp       = {}   -- [guidLow] = true si el addon de ese jugador tiene un campamento abierto
local buffsScript  = {}   -- [guidLow] = { xp = timestamp_fin, regen = timestamp_fin }
local avisadoFallo = {}   -- ["guid:hechizo"] = true: avisos de aura no aplicada ya mostrados

----------------------------------------------------------------------
-- Utilidades
----------------------------------------------------------------------
local function Msg(player, texto)
    player:SendBroadcastMessage("|cff66ccff[Campamento]|r " .. texto)
end

local function EsBot(player)
    if not CFG.BLOQUEAR_BOTS then return false end
    local guid = player:GetGUIDLow()
    local c = botCache[guid]
    if c ~= nil then return c end

    local esBot = false
    local ok, cuenta = pcall(function() return player:GetAccountName() end)
    if ok and cuenta then
        cuenta = cuenta:lower()
        for _, pref in ipairs(CFG.PREFIJOS_BOT) do
            if cuenta:sub(1, #pref) == pref then
                esBot = true
                break
            end
        end
    end
    botCache[guid] = esBot
    return esBot
end

local function Dist2D(p, c)
    local dx, dy = p:GetX() - c.x, p:GetY() - c.y
    return math.sqrt(dx * dx + dy * dy)
end

local function CampamentoCercano(player)
    local mejor, mejorD = nil, CFG.RADIO + 0.001
    for _, c in pairs(camps) do
        if c.mapa == player:GetMapId() then
            local d = Dist2D(player, c)
            if d <= mejorD and math.abs(player:GetZ() - c.z) < 10 then
                mejor, mejorD = c, d
            end
        end
    end
    return mejor
end

local function EstaSentado(player)
    local ok, estado = pcall(function() return player:GetStandState() end)
    -- 1..6 = sentado / silla (0 = de pie, 7 = muerto, 8 = arrodillado)
    return ok and estado ~= nil and estado >= 1 and estado <= 6
end

local function HuecosPorCocina(player)
    local nivel = player:GetSkillValue(CFG.SKILL_COCINA)
    local huecos = CFG.HUECOS_POR_COCINA[1][2]
    for _, t in ipairs(CFG.HUECOS_POR_COCINA) do
        if nivel >= t[1] then huecos = t[2] end
    end
    return huecos
end

----------------------------------------------------------------------
-- API PARA LOS MÓDULOS DE PROFESIÓN (Camp_<profesión>.lua)
-- Los módulos solo usan estas funciones, en el momento de ejecutar sus eventos:
--   Campamento.TieneBuff(player, clave)  -> true si el buff de esa profesión está activo
--   Campamento.Debug(player, texto)      -> mensaje de depuración en el chat
----------------------------------------------------------------------
Campamento = Campamento or {}
Campamento.activos = {}      -- [guidLow] = { [clave] = timestamp_fin }
Campamento.NOMBRES = {}      -- [clave] = nombre del objeto (para los mensajes)

function Campamento.TieneBuff(player, clave)
    local a = Campamento.activos[player:GetGUIDLow()]
    return a ~= nil and a[clave] ~= nil and a[clave] > os.time()
end

function Campamento.Debug(player, texto)
    if CFG.DEBUG_BUFFS then
        player:SendBroadcastMessage("|cff66ccff[Campamento]|r |cff999999(debug)|r " .. texto)
    end
end

-- Envía al addon la lista de buffs de módulo activos (clave:segundos restantes)
local function EnviarBuffs(player)
    local a = Campamento.activos[player:GetGUIDLow()]
    local ahora = os.time()
    local partes = {}
    if a then
        for clave, fin in pairs(a) do
            if fin > ahora then partes[#partes + 1] = clave .. ":" .. (fin - ahora) end
        end
    end
    if #partes == 0 then
        player:SendBroadcastMessage("CAMPBUFF#NONE")
    else
        player:SendBroadcastMessage("CAMPBUFF#" .. table.concat(partes, ";"))
    end
end

-- Activa (o mantiene) el buff de módulo. Devuelve true si se acaba de activar.
local function ActivarModulo(player, clave, f)
    local guid = player:GetGUIDLow()
    local a = Campamento.activos[guid]
    if not a then a = {}; Campamento.activos[guid] = a end
    local ahora = os.time()
    if a[clave] and a[clave] > ahora then return false end
    a[clave] = ahora + CFG.DURACION_BUFF
    EnviarBuffs(player)
    Campamento.Debug(player, string.format("Buff ACTIVADO: %s (%s) durante %d min.", clave, f.nombre, math.floor(CFG.DURACION_BUFF / 60)))
    return true
end

-- Caducidad de los buffs de módulo (con aviso de debug)
local function ProcesarModulos(jugadores, ahora)
    for _, p in pairs(jugadores) do
        local a = Campamento.activos[p:GetGUIDLow()]
        if a then
            for clave, fin in pairs(a) do
                if fin <= ahora then
                    a[clave] = nil
                    Campamento.Debug(p, "Buff CADUCADO: " .. clave)
                end
            end
            if next(a) == nil then Campamento.activos[p:GetGUIDLow()] = nil end
            EnviarBuffs(p)   -- sincroniza el addon (también tras /reload)
        end
    end
end

-- Envía al addon la habilidad de Cocina y lo que falta para el siguiente rango de campamento
--   CAMPCOCINA#habilidad#huecos#rango#siguienteHabilidad#siguientesHuecos   (siguiente = 0 si ya es el máximo)
local function EnviarCocina(player)
    local valor = player:GetSkillValue(CFG.SKILL_COCINA)
    local huecos, rango = CFG.HUECOS_POR_COCINA[1][2], 1
    for i, t in ipairs(CFG.HUECOS_POR_COCINA) do
        if valor >= t[1] then huecos = t[2]; rango = i end
    end
    local sig, sigHuecos = 0, 0
    local siguiente = CFG.HUECOS_POR_COCINA[rango + 1]
    if siguiente then sig, sigHuecos = siguiente[1], siguiente[2] end
    player:SendBroadcastMessage(string.format("CAMPCOCINA#%d#%d#%d#%d#%d", valor, huecos, rango, sig, sigHuecos))
end

-- Rango más alto cuyo nivel mínimo cumple el receptor (nil = nada)
local function AuraParaNivel(f, nivel)
    local elegido
    for _, r in ipairs(f.rangos) do
        if nivel >= r[1] then elegido = r[2] end
    end
    return elegido
end

local function AplicarBeneficio(player, f, clave)
    if f.modulo then ActivarModulo(player, clave, f) return end
    -- Efectos gestionados por el script (Peletería / Ingeniería)
    if f.tipo == "xp" or f.tipo == "regen" or f.tipo == "rep" then
        local guid = player:GetGUIDLow()
        local b = buffsScript[guid]
        if not b then
            b = {}
            buffsScript[guid] = b
        end
        local ahora = os.time()
        if not b[f.tipo] or b[f.tipo] <= ahora then
            b[f.tipo] = ahora + CFG.DURACION_BUFF
        end
        return
    end

    -- Efectos por aura, con el rango que corresponde al nivel actual
    local id = AuraParaNivel(f, player:GetLevel())
    if not id then return end
    if player:HasAura(id) then return end

    -- Si tiene otro rango de esta función, se sustituye conservando el tiempo restante
    local restante = CFG.DURACION_BUFF * 1000
    for _, r in ipairs(f.rangos) do
        if r[2] ~= id and player:HasAura(r[2]) then
            local ok, viejo = pcall(function() return player:GetAura(r[2]) end)
            if ok and viejo then
                local okd, d = pcall(function() return viejo:GetDuration() end)
                if okd and d and d > 0 then restante = d end
            end
            player:RemoveAura(r[2])
        end
    end

    local aura
    if f.lanzar then
        -- Las auras de área no suelen aplicarse con AddAura: se lanzan como hechizo (sin coste ni requisitos)
        pcall(function() player:CastSpell(player, id, true) end)
        local okg, a = pcall(function() return player:GetAura(id) end)
        if okg then aura = a end
    end
    if not aura then
        aura = player:AddAura(id, player)
    end
    if aura then
        pcall(function()
            aura:SetMaxDuration(restante)
            aura:SetDuration(restante)
        end)
    end

    -- Si el bufo no ha llegado a aplicarse, lo dejamos escrito en la consola (una sola vez)
    if not player:HasAura(id) then
        local k = player:GetGUIDLow() .. ":" .. id
        if not avisadoFallo[k] then
            avisadoFallo[k] = true
            print(string.format("[Campamento] AVISO: el hechizo %d (%s) no se pudo aplicar a %s", id, f.nombre, player:GetName()))
        end
    end
end

local function ListaProfesiones()
    local t = {}
    for clave in pairs(FUNCIONES) do t[#t + 1] = clave end
    table.sort(t)
    return table.concat(t, ", ")
end

-- ¿Ya hay un objeto de esta profesión colocado en el campamento?
local function YaColocada(camp, clave)
    for _, s in ipairs(camp.slots) do
        if s.clave == clave then return true end
    end
    return false
end

-- Jugadores reales del grupo (incluido el que llama), en el mismo mapa y cerca del campamento.
-- El que llama va primero: si puede aportar una profesión, la aporta él antes que nadie.
local function MiembrosDelGrupo(player, camp)
    local lista, vistos = {}, {}
    local function anadir(p)
        if not p then return end
        local g = p:GetGUIDLow()
        if vistos[g] or EsBot(p) then return end
        if p:GetMapId() ~= camp.mapa or Dist2D(p, camp) > CFG.RADIO_GRUPO then return end
        vistos[g] = true
        lista[#lista + 1] = p
    end
    anadir(player)
    local ok, grupo = pcall(function() return player:GetGroup() end)
    if ok and grupo then
        local ok2, miembros = pcall(function() return grupo:GetMembers() end)
        if ok2 and miembros then
            for _, m in pairs(miembros) do anadir(m) end
        end
    end
    return lista
end

-- ¿Puede este jugador aportar el objeto de esa profesión ahora? Devuelve true, o false + motivo.
local function PuedeAportar(p, clave, camp)
    local f = FUNCIONES[clave]
    if not f then return false, "profesion" end
    if p:GetSkillValue(f.skill) < CFG.NIVEL_HABILIDAD then return false, "habilidad" end
    local g = p:GetGUIDLow()
    if CFG.COOLDOWN_SEGUNDOS > 0 and (cooldowns[g] or 0) > os.time() then return false, "cooldown" end
    if CFG.UN_OBJETO_POR_JUGADOR then
        for _, s in ipairs(camp.slots) do
            if s.guid == g then return false, "ya" end
        end
    end
    return true
end

-- Profesiones que se pueden colocar ahora: { clave = jugador que la aportaría }
local function CalcularPool(camp, miembros)
    local pool = {}
    for clave in pairs(FUNCIONES) do
        if not YaColocada(camp, clave) then
            for _, m in ipairs(miembros) do
                if PuedeAportar(m, clave, camp) then
                    pool[clave] = m
                    break
                end
            end
        end
    end
    return pool
end

-- Crea el objeto visual de un slot, repartido en círculo alrededor de la hoguera
local function CrearObjetoVisual(player, camp, clave, indice)
    if not CFG.OBJETOS_VISUALES then return nil end
    local v = OBJETOS_VISUALES[clave]
    if not v or not v.entry then return nil end

    local a = (indice - 1) * (2 * math.pi / camp.maxHuecos)
    local x = camp.x + CFG.RADIO_OBJETOS * math.cos(a)
    local y = camp.y + CFG.RADIO_OBJETOS * math.sin(a)
    local z = camp.z   -- la altura a la que estaba el líder al encender la hoguera (como .gobject add)

    local o = a + math.pi   -- mirando a la hoguera
    local restante = math.max(1, camp.expira - os.time())
    local ok, go = pcall(function()
        return player:SummonGameObject(v.entry, x, y, z, o, restante)
    end)
    if ok then return go end
    return nil
end

-- Envía el estado del campamento al addon del jugador (mensaje de sistema que el addon oculta).
-- Formato: CAMPDATA#dueño#segundos_restantes#huecos#clave:jugador;clave:jugador
local function EnviarEstado(player, camp)
    if not camp then
        player:SendBroadcastMessage("CAMPDATA#NONE")
        return
    end
    local partes = {}
    for _, s in ipairs(camp.slots) do
        partes[#partes + 1] = s.clave .. ":" .. s.jugador
    end
    player:SendBroadcastMessage(string.format("CAMPDATA#%s#%d#%d#%s",
        camp.dueno, math.max(0, camp.expira - os.time()), camp.maxHuecos, table.concat(partes, ";")))

    -- Qué puede colocar este jugador: L = líder (todo su grupo), M = miembro que coloca lo suyo, X = nada
    local modo, pool = "X", {}
    if player:GetGUIDLow() == camp.duenoGuid then
        modo = "L"
        pool = CalcularPool(camp, MiembrosDelGrupo(player, camp))
    elseif not CFG.SOLO_LIDER_COLOCA then
        modo = "M"
        pool = CalcularPool(camp, { player })
    end
    local disp = {}
    for clave, quien in pairs(pool) do
        disp[#disp + 1] = clave .. "=" .. quien:GetName()
    end
    player:SendBroadcastMessage("CAMPPOOL#" .. modo .. "#" .. table.concat(disp, ";"))
    EnviarCocina(player)
end

----------------------------------------------------------------------
-- Crear campamento al lanzar la Hoguera básica
----------------------------------------------------------------------
local function CrearCampamento(player)
    local huecos = HuecosPorCocina(player)
    local id = siguienteId
    camps[id] = {
        mapa      = player:GetMapId(),
        x         = player:GetX(),
        y         = player:GetY(),
        z         = player:GetZ(),
        expira    = os.time() + CFG.DURACION_CAMPAMENTO,
        maxHuecos = huecos,
        dueno     = player:GetName(),
        duenoGuid = player:GetGUIDLow(),
        slots     = {},
    }
    siguienteId = id + 1
    EnviarEstado(player, camps[id])
    enCamp[player:GetGUIDLow()] = true
    Msg(player, string.format("Campamento formado con %d huecos. Usa |cffffff00.camp poner <profesión>|r (.camp ayuda)", huecos))
end

local function AlLanzarHechizo(event, player, spell, skipCheck)
    local id = spell:GetEntry()
    if CFG.DEBUG and player:IsGM() then
        Msg(player, "Hechizo lanzado: ID " .. id)
        print(string.format("[Campamento] %s lanzó el hechizo %d", player:GetName(), id))
    end
    if not CFG.SPELLS_HOGUERA[id] then return end
    if EsBot(player) then return end
    if player:GetLevel() < CFG.NIVEL_PERSONAJE then
        Msg(player, "Hasta el nivel " .. CFG.NIVEL_PERSONAJE .. " la hoguera es solo para cocinar. Podrás formar un campamento al llegar a ese nivel.")
        return
    end
    CrearCampamento(player)
end

----------------------------------------------------------------------
-- Comandos
----------------------------------------------------------------------
local function AlComando(event, player, command)
    local cmd, sub, arg, arg2, arg3 = command:lower():match("^(%S+)%s*(%S*)%s*(%S*)%s*(%S*)%s*(%S*)")
    if cmd ~= "camp" then return end   -- no es nuestro comando

    if EsBot(player) then return false end

    if sub == "" or sub == "ayuda" then
        Msg(player, "Profesiones disponibles: " .. ListaProfesiones())
        Msg(player, "Uso: .camp poner <profesión>  |  .camp estado")
        return false
    end

    -- Comandos de GM para pruebas
    if sub == "resetcd" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        cooldowns = {}
        Msg(player, "Todos los cooldowns de campamento borrados.")
        return false
    end
    if sub == "cd" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        local seg = tonumber(arg)
        if not seg or seg < 0 then
            Msg(player, "Uso: .camp cd <segundos>  (actual: " .. CFG.COOLDOWN_SEGUNDOS .. ")")
            return false
        end
        CFG.COOLDOWN_SEGUNDOS = seg
        Msg(player, "Cooldown de campamento ahora: " .. seg .. " s (hasta el próximo reload).")
        return false
    end

    if sub == "cocina" then
        EnviarCocina(player)
        return false
    end

    if sub == "efecto" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        local id = tonumber(arg)
        if not id then
            Msg(player, "Uso: .camp efecto <ID> [valor1] [valor2]  (sobre tu objetivo, o sobre ti si no tienes ninguno)")
            Msg(player, "Con valores se lanza como lo hacen los módulos (CastCustomSpell); sin valores, como un hechizo normal.")
            return false
        end
        id = math.floor(id)
        local objetivo = player:GetSelection() or player
        local b0, b1 = tonumber(arg2), tonumber(arg3)
        local ok
        if b0 then
            ok = pcall(function()
                if b1 then player:CastCustomSpell(objetivo, id, true, b0, b1) else player:CastCustomSpell(objetivo, id, true, b0) end
            end)
        else
            ok = pcall(function() player:CastSpell(objetivo, id, true) end)
        end
        local aplicado = false
        pcall(function() aplicado = objetivo:HasAura(id) end)
        Msg(player, string.format("Hechizo %d lanzado%s. Aura en el objetivo: %s.", id, b0 and " con valores" or "", aplicado and "SÍ" or "NO (puede ser un hechizo instantáneo sin aura)"))
        if not ok then Msg(player, "Error al lanzar el hechizo.") end
        return false
    end

    if sub == "dar" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        local f = FUNCIONES[arg]
        if not f or not f.modulo then Msg(player, "Uso: .camp dar <profesión con módulo> (ingenieria, alquimia, herreria, encantamiento, herboristeria, peleteria, mineria, desuello, sastreria, inscripcion, joyeria, primerosauxilios, pesca)") return false end
        Campamento.activos[player:GetGUIDLow()] = Campamento.activos[player:GetGUIDLow()] or {}
        Campamento.activos[player:GetGUIDLow()][arg] = nil
        ActivarModulo(player, arg, f)
        return false
    end

    if sub == "probar" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        local entry = tonumber(arg)
        if not entry then Msg(player, "Uso: .camp probar <ID de gameobject>") return false end
        if Previsualizar(player, math.floor(entry)) then
            Msg(player, "Objeto " .. math.floor(entry) .. " creado delante de ti durante 30 s. Si no lo ves, ese ID no tiene modelo visible.")
        else
            Msg(player, "Error al crear el objeto " .. math.floor(entry) .. ".")
        end
        return false
    end
    if sub == "buscar" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        local texto = (arg:gsub("[^%w_]", ""))
        if #texto < 3 then
            Msg(player, "Uso: .camp buscar <texto de 3+ letras en inglés>   ej: .camp buscar anvil")
            return false
        end
        local ok, q = pcall(function()
            return WorldDBQuery("SELECT entry, name FROM gameobject_template WHERE type IN (5,7,8) AND displayId > 0 AND name LIKE '%" .. texto .. "%' ORDER BY CHAR_LENGTH(name), entry LIMIT 12")
        end)
        if not ok or not q then
            Msg(player, "Sin resultados para '" .. texto .. "'.")
            return false
        end
        Msg(player, "Resultados (.camp probar <id> para verlo, .camp modelo <profesión> <id> para fijarlo):")
        repeat
            Msg(player, string.format("  %d   %s", q:GetUInt32(0), q:GetString(1)))
        until not q:NextRow()
        return false
    end
    if sub == "modelo" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        local v = OBJETOS_VISUALES[arg]
        if not v then
            Msg(player, "Uso: .camp modelo <profesión> <id>   (id 0 = quitar). Profesiones: " .. ListaProfesiones())
            return false
        end
        local entry = tonumber(arg2)
        if not entry then
            Msg(player, "Falta el ID. Usa .camp buscar <texto> para encontrar uno.")
            return false
        end
        entry = math.floor(entry)
        if entry <= 0 then
            v.entry = nil
            v.nombreGO = nil
            GuardarModelo(arg, nil)
            Msg(player, arg .. ": modelo quitado (no mostrará objeto).")
            return false
        end
        local nombre = NombreGO(entry)
        if not nombre then
            Msg(player, "El ID " .. entry .. " no existe en gameobject_template.")
            return false
        end
        v.entry = entry
        v.nombreGO = nombre .. " [elegido]"
        GuardarModelo(arg, entry)
        Previsualizar(player, entry)
        Msg(player, string.format("%s -> %d (%s). Guardado. Vista previa 30 s delante de ti.", arg, entry, nombre))
        return false
    end
    if sub == "multi" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        CFG.UN_OBJETO_POR_JUGADOR = not CFG.UN_OBJETO_POR_JUGADOR
        Msg(player, "Un solo objeto por jugador y campamento: " .. (CFG.UN_OBJETO_POR_JUGADOR and "SÍ" or "NO (modo pruebas)"))
        return false
    end
    if sub == "objetos" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        for clave, v in pairs(OBJETOS_VISUALES) do
            local d = v.entry and (v.entry .. " (" .. (v.nombreGO or "ID fijo") .. ")") or "SIN modelo"
            Msg(player, clave .. " -> " .. d)
        end
        return false
    end
    if sub == "crear" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        CrearCampamento(player)
        return false
    end
    if sub == "debug" then
        if not player:IsGM() then Msg(player, "Solo para GM.") return false end
        CFG.DEBUG = not CFG.DEBUG
        Msg(player, "Debug de hechizos: " .. (CFG.DEBUG and "ACTIVADO (lanza la hoguera y mira el ID)" or "desactivado"))
        return false
    end

    local camp = CampamentoCercano(player)
    if not camp then
        Msg(player, "No hay ninguna hoguera cerca. Crea una con Cocina (Hoguera básica).")
        return false
    end

    if sub == "estado" then
        local restante = math.max(0, camp.expira - os.time())
        Msg(player, string.format("Campamento: %d/%d objetos, quedan %d s.", #camp.slots, camp.maxHuecos, restante))
        for _, s in ipairs(camp.slots) do
            Msg(player, string.format(" - %s (de %s)", s.nombre, s.jugador))
        end
        return false
    end

    if sub == "poner" then
        if player:IsInCombat() then
            Msg(player, "No puedes colocar objetos en combate.")
            return false
        end

        local f = FUNCIONES[arg]
        if not f then
            Msg(player, "Profesión no válida. Opciones: " .. ListaProfesiones())
            return false
        end

        local guid = player:GetGUIDLow()
        local esLider = (guid == camp.duenoGuid)
        if not esLider and CFG.SOLO_LIDER_COLOCA then
            Msg(player, "Solo el líder del campamento (" .. camp.dueno .. ") puede colocar objetos.")
            return false
        end
        if #camp.slots >= camp.maxHuecos then
            Msg(player, "La hoguera ya tiene el máximo de objetos.")
            return false
        end
        if YaColocada(camp, arg) then
            Msg(player, "Ese objeto ya está colocado en este campamento.")
            return false
        end

        -- Quién aporta la profesión: el líder elige entre los miembros del grupo cercanos
        local proveedor
        if esLider then
            local alguienLaTiene = false
            for _, m in ipairs(MiembrosDelGrupo(player, camp)) do
                if PuedeAportar(m, arg, camp) then
                    proveedor = m
                    break
                end
                if m:GetSkillValue(f.skill) >= CFG.NIVEL_HABILIDAD then alguienLaTiene = true end
            end
            if not proveedor then
                if alguienLaTiene then
                    local extra = player:IsGM() and "  (pruebas: .camp cd 0 y .camp multi)" or ""
                    Msg(player, "Quien tiene esa profesión está en cooldown o ya colocó otro objeto aquí." .. extra)
                else
                    Msg(player, "Nadie del grupo cercano tiene esa profesión a nivel " .. CFG.NIVEL_HABILIDAD .. " o más.")
                end
                return false
            end
        else
            local ok, motivo = PuedeAportar(player, arg, camp)
            if not ok then
                if motivo == "habilidad" then
                    Msg(player, "Necesitas al menos nivel " .. CFG.NIVEL_HABILIDAD .. " de habilidad en esa profesión.")
                elseif motivo == "cooldown" then
                    local resta = cooldowns[guid] - os.time()
                    if resta >= 60 then
                        Msg(player, string.format("Tiempo de reutilización: %d min restantes.", math.ceil(resta / 60)))
                    else
                        Msg(player, string.format("Tiempo de reutilización: %d s restantes.", resta))
                    end
                else
                    Msg(player, "Ya has colocado un objeto en este campamento.")
                end
                return false
            end
            proveedor = player
        end

        local pGuid = proveedor:GetGUIDLow()
        local indice = #camp.slots + 1
        camp.slots[indice] = {
            guid = pGuid, jugador = proveedor:GetName(), nombre = f.nombre,
            clave = arg, equipo = proveedor:GetTeam(),
            visual = CrearObjetoVisual(player, camp, arg, indice),
        }
        if CFG.COOLDOWN_SEGUNDOS > 0 then
            cooldowns[pGuid] = os.time() + CFG.COOLDOWN_SEGUNDOS
        end
        EnviarEstado(player, camp)

        if CFG.OBJETOS_VISUALES and player:IsGM() and not camp.slots[indice].visual then
            local v = OBJETOS_VISUALES[arg]
            if not v or not v.entry then
                Msg(player, "Aviso: esta profesión no tiene modelo. Usa .camp buscar <texto> y .camp modelo " .. arg .. " <id>.")
            else
                Msg(player, "Aviso: el objeto visual (ID " .. v.entry .. ") no se creó o no se pudo confirmar. Prueba .camp probar " .. v.entry .. " o elige otro con .camp modelo.")
            end
        end

        if pGuid == guid then
            Msg(player, "Has colocado: |cff00ff00" .. f.nombre .. "|r. Siéntate cerca 1 minuto para recibir los beneficios.")
        else
            Msg(player, "Has colocado: |cff00ff00" .. f.nombre .. "|r, aportado por " .. proveedor:GetName() .. ".")
            Msg(proveedor, player:GetName() .. " ha colocado tu " .. f.nombre .. " en el campamento (tu cooldown ha empezado).")
        end
        return false
    end

    Msg(player, "Subcomando desconocido. Usa .camp ayuda")
    return false
end

----------------------------------------------------------------------
-- Efectos propios del script: regeneración (Ingeniería) y XP extra (Peletería)
----------------------------------------------------------------------
local function ProcesarBuffsScript(jugadores, ahora)
    for _, p in pairs(jugadores) do
        local guid = p:GetGUIDLow()
        local b = buffsScript[guid]
        if b then
            if b.regen and b.regen <= ahora then b.regen = nil end
            if b.xp and b.xp <= ahora then b.xp = nil end
            if b.rep and b.rep <= ahora then b.rep = nil end

            if not b.regen and not b.xp and not b.rep then
                buffsScript[guid] = nil
            elseif b.regen and p:IsAlive() then
                local max = p:GetMaxHealth()
                local vida = p:GetHealth()
                if vida < max then
                    local cura = math.max(1, math.floor(max * CFG.INGENIERIA_REGEN_PCT / 100))
                    p:SetHealth(math.min(max, vida + cura))
                end
            end
        end
    end
end

local function AlDarXP(event, player, amount, victim)
    local b = buffsScript[player:GetGUIDLow()]
    if b and b.xp and b.xp > os.time() then
        return math.floor(amount * (1 + CFG.PELETERIA_XP_EXTRA_PCT / 100))
    end
end

-- Joyería: más reputación al ganarla.
-- En AzerothCore 'incremental' es un booleano (true = 'standing' es lo que se gana ahora).
-- Si tu mod-eluna lo pasara de otra forma, no se toca nada para no estropear la reputación.
local function AlCambiarReputacion(event, player, factionId, standing, incremental)
    local b = buffsScript[player:GetGUIDLow()]
    if b and b.rep and b.rep > os.time() and incremental == true and standing and standing > 0 then
        return standing + math.floor(standing * CFG.JOYERIA_REP_EXTRA_PCT / 100)
    end
end

----------------------------------------------------------------------
-- Bucle principal: caducidad, beneficios de campamento y efectos del script
----------------------------------------------------------------------
local function Tick()
    local ahora = os.time()
    for id, c in pairs(camps) do
        if c.expira <= ahora then
            for _, s in ipairs(c.slots) do
                if s.visual then
                    pcall(function() s.visual:RemoveFromWorld(false) end)
                end
            end
            camps[id] = nil
        end
    end

    local hayCamps  = next(camps) ~= nil
    local hayScript = next(buffsScript) ~= nil or next(Campamento.activos) ~= nil
    if not hayCamps then sentado = {} end
    local hayEnCamp = next(enCamp) ~= nil
    if not hayCamps and not hayScript and not hayEnCamp then return end

    local jugadores = GetPlayersInWorld()
    if not jugadores then return end

    if hayCamps or hayEnCamp then
        local paso = CFG.TICK_MS / 1000
        for _, p in pairs(jugadores) do
            if not EsBot(p) then
                local guid = p:GetGUIDLow()
                local camp = p:IsAlive() and CampamentoCercano(p) or nil

                -- Estado para el addon: se envía mientras estés en el campamento y un NONE al salir
                if camp then
                    EnviarEstado(p, camp)
                    enCamp[guid] = true
                elseif enCamp[guid] then
                    EnviarEstado(p, nil)
                    enCamp[guid] = nil
                end

                if camp and EstaSentado(p) then
                    sentado[guid] = (sentado[guid] or 0) + paso
                    if sentado[guid] >= CFG.TIEMPO_SENTADO then
                        for _, s in ipairs(camp.slots) do
                            local f = FUNCIONES[s.clave]
                            if f and (not f.faccion or p:GetTeam() == s.equipo) then
                                AplicarBeneficio(p, f, s.clave)
                            end
                        end
                    end
                else
                    sentado[guid] = nil
                end
            end
        end
    end

    if hayScript or next(buffsScript) ~= nil then
        ProcesarBuffsScript(jugadores, ahora)
        ProcesarModulos(jugadores, ahora)
    end
end

----------------------------------------------------------------------
-- Registro de eventos (Eluna)
----------------------------------------------------------------------
RegisterPlayerEvent(5,  AlLanzarHechizo)  -- PLAYER_EVENT_ON_SPELL_CAST
RegisterPlayerEvent(12, AlDarXP)          -- PLAYER_EVENT_ON_GIVE_XP
RegisterPlayerEvent(15, AlCambiarReputacion)  -- PLAYER_EVENT_ON_REPUTATION_CHANGE
RegisterPlayerEvent(42, AlComando)        -- PLAYER_EVENT_ON_COMMAND
CreateLuaEvent(Tick, CFG.TICK_MS, 0)      -- repetir indefinidamente

print("[Campamento] Campamento_server.lua v7.6 cargado correctamente.")
