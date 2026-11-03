--[[
    Camp_ingenieria.lua  -  Módulo de Ingeniería para Campamento_server.lua  (v1.2)
    Objeto del campamento: Caja de munición.

    EFECTO: con el buff activo, cada golpe directo tiene un 2 % de probabilidad de provocar una
    EXPLOSIÓN de fuego en área alrededor del objetivo.
      daño de la explosión = daño del golpe x (0,5 + nivel / 80)
        nivel 20 -> 75 % del golpe   |   nivel 40 -> 100 %   |   nivel 80 -> 150 %
    Así se ajusta sola al nivel y al equipo de cada jugador.

    Requiere Campamento_server.lua (v6.0 o superior) en la misma carpeta lua_scripts.
    Usa el evento PLAYER_EVENT_ON_DEAL_DAMAGE (72) de mod-ale: (event, player, target, damage, damagetype)
]]

local CFG = {
    PROBABILIDAD_PCT = 2,      -- % de proc por golpe
    ENFRIAMIENTO     = 6,      -- segundos entre explosiones (por jugador)
    RADIO            = 8.0,    -- yardas alrededor del objetivo
    MAX_OBJETIVOS    = 5,      -- enemigos máximos por explosión
    BASE_MULT        = 0.5,    -- multiplicador = BASE_MULT + nivel / DIV_NIVEL
    DIV_NIVEL        = 80,
    ESCUELA_FUEGO    = 2,      -- SPELL_SCHOOL_FIRE
    -- ID de un hechizo real del cliente solo para que el registro de combate muestre un nombre.
    -- 0 = daño directo sin nombre. (Sin confirmar: pon 0 si el daño no sale bien.)
    SPELL_NOMBRE     = 0,
    -- EFECTO VISUAL: ID de un hechizo real del cliente que se lanza sobre el objetivo en cada explosión solo por
    -- su animación. 0 = sin efecto visual. Elige uno con ".camp efecto <ID>" (GM) mirando a un bicho.
    -- OJO: si ese hechizo hace daño por sí mismo, se sumará al de la explosión. Busca uno cosmético.
    SPELL_VISUAL     = 0,
    DEBUG_HOOK       = true,   -- PRUEBAS: avisa en el chat de que el evento de daño llega (máx. 1 vez cada 5 s)
}

local ultimoAviso = {}
local ultimoProc = {}      -- [guidLow] = os.time() de la última explosión
local enExplosion = false  -- evita que la propia explosión dispare otra

local function EsJugador(u)
    local ok, r = pcall(function() return u:ToPlayer() end)
    return ok and r ~= nil
end

local function AlHacerDanio(event, player, target, damage, damagetype)
    if enExplosion then return end
    if CFG.DEBUG_HOOK and player and Campamento and Campamento.Debug then
        local g = player:GetGUIDLow()
        local t = os.time()
        if not ultimoAviso[g] or t - ultimoAviso[g] >= 5 then
            ultimoAviso[g] = t
            local activo = Campamento.TieneBuff and Campamento.TieneBuff(player, "ingenieria")
            Campamento.Debug(player, string.format("evento de daño recibido (daño=%s, tipo=%s, buff ingeniería=%s)",
                tostring(damage), tostring(damagetype), tostring(activo)))
        end
    end
    if not Campamento or not Campamento.TieneBuff then return end
    if not player or not target or not damage or damage <= 0 then return end
    if not Campamento.TieneBuff(player, "ingenieria") then return end
    if EsJugador(target) then return end                       -- sin PvP
    if math.random(1, 100) > CFG.PROBABILIDAD_PCT then return end

    local ahora = os.time()
    local guid = player:GetGUIDLow()
    if ultimoProc[guid] and ahora - ultimoProc[guid] < CFG.ENFRIAMIENTO then return end
    ultimoProc[guid] = ahora

    local mult = CFG.BASE_MULT + player:GetLevel() / CFG.DIV_NIVEL
    local dano = math.max(1, math.floor(damage * mult))

    -- objetivos: el golpeado primero y luego los enemigos cercanos a él
    local lista, vistos = { target }, {}
    vistos[target:GetGUIDLow()] = true
    local ok, cerca = pcall(function() return player:GetUnfriendlyUnitsInRange(40) end)
    if ok and cerca then
        for _, u in pairs(cerca) do
            if #lista >= CFG.MAX_OBJETIVOS then break end
            local g = u:GetGUIDLow()
            if not vistos[g] and u:IsAlive() and not EsJugador(u) then
                local okd, d = pcall(function() return u:GetDistance(target) end)
                if okd and d and d <= CFG.RADIO then
                    vistos[g] = true
                    lista[#lista + 1] = u
                end
            end
        end
    end

    enExplosion = true
    if CFG.SPELL_VISUAL and CFG.SPELL_VISUAL > 0 then
        pcall(function() player:CastSpell(target, CFG.SPELL_VISUAL, true) end)
    end
    local golpeados = 0
    for _, u in ipairs(lista) do
        local oka = pcall(function()
            player:DealDamage(u, dano, false, CFG.ESCUELA_FUEGO, CFG.SPELL_NOMBRE)
        end)
        if oka then golpeados = golpeados + 1 end
    end
    enExplosion = false

    Campamento.Debug(player, string.format("¡Explosión de ingeniería! %d enemigo(s), %d de daño cada uno (golpe %d x%.2f).",
        golpeados, dano, damage, mult))
end

RegisterPlayerEvent(72, AlHacerDanio)   -- PLAYER_EVENT_ON_DEAL_DAMAGE
print("[Campamento] Camp_ingenieria.lua cargado.")
