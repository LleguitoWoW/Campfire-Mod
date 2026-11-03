--[[
    Camp_peleteria.lua  -  Módulo de Peletería para Campamento_server.lua  (v1)
    Objeto del campamento: Tienda de campaña.

    EFECTO (mientras dura el buff del campamento):
      +10 % de experiencia (matando bichos, misiones, exploración...)
      +10 % de reputación ganada
    Es un porcentaje, así que escala solo con el nivel y con lo que ganes. No necesita hechizos ni SQL.

    Requiere Campamento_server.lua v6.1 o superior.
    Eventos de mod-ale usados:
      PLAYER_EVENT_ON_GIVE_XP (12)            (event, player, amount, victim, source) -> nueva experiencia
      PLAYER_EVENT_ON_REPUTATION_CHANGE (15)  (event, player, factionId, standing, incremental) -> nueva reputación
]]

local CFG = {
    XP_PCT   = 10,
    REP_PCT  = 10,
    DEBUG_GANANCIAS = true,   -- PRUEBAS: avisa en el chat de cada bonus de experiencia o reputación
}

local function Activo(player)
    return player and Campamento and Campamento.TieneBuff and Campamento.TieneBuff(player, "peleteria")
end

local function AlDarXP(event, player, amount, victim, source)
    if not amount or amount <= 0 then return end
    if not Activo(player) then return end
    local nuevo = math.max(amount + 1, math.floor(amount * (1 + CFG.XP_PCT / 100) + 0.5))
    if CFG.DEBUG_GANANCIAS then
        Campamento.Debug(player, string.format("Peletería: experiencia %d -> %d (+%d%%).", amount, nuevo, CFG.XP_PCT))
    end
    return nuevo
end

-- 'incremental' = true cuando 'standing' es lo que se GANA ahora (no la reputación total).
local function AlCambiarReputacion(event, player, factionId, standing, incremental)
    if not standing or standing <= 0 then return end
    if incremental ~= true and incremental ~= 1 then return end   -- si no sabemos que es una ganancia, no tocamos nada
    if not Activo(player) then return end
    local nuevo = math.max(standing + 1, math.floor(standing * (1 + CFG.REP_PCT / 100) + 0.5))
    if CFG.DEBUG_GANANCIAS then
        Campamento.Debug(player, string.format("Peletería: reputación %d -> %d (facción %d, +%d%%).", standing, nuevo, factionId or 0, CFG.REP_PCT))
    end
    return nuevo
end

RegisterPlayerEvent(12, AlDarXP)                -- PLAYER_EVENT_ON_GIVE_XP
RegisterPlayerEvent(15, AlCambiarReputacion)    -- PLAYER_EVENT_ON_REPUTATION_CHANGE
print("[Campamento] Camp_peleteria.lua cargado.")
