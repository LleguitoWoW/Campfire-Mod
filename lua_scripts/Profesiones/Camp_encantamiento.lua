--[[
    Camp_encantamiento.lua  -  Módulo de Encantamiento para Campamento_server.lua  (v1)
    Objeto del campamento: Gema flotante.

    EFECTO (mientras dura el buff del campamento):
      +2 %  a todas las estadísticas
      +5 %  de armadura
      +N    a todas las resistencias mágicas, con N = nivel x 0,5
              (nivel 20 -> 10  |  nivel 40 -> 20  |  nivel 60 -> 30  |  nivel 80 -> 40)
    Las resistencias dan siempre una reducción parecida (~7 %) sea cual sea el nivel, porque el límite
    de resistencia del juego crece con el nivel. Los porcentajes escalan solos con el equipo.
    Cuando el jugador sube de nivel, el aura se renueva con los valores nuevos.

    REQUIERE el hechizo propio 900003 (Campamento_spells.sql en la base de datos del MUNDO y reinicio
    del worldserver). Requiere Campamento_server.lua v6.1 o superior.
]]

local CFG = {
    SPELL_ID      = 900003,
    INTERVALO_MS  = 3000,
    STATS_PCT     = 2,
    ARMADURA_PCT  = 5,
    RESIST_POR_NIVEL = 0.5,
    DEBUG_AURA    = true,   -- PRUEBAS: avisa en el chat al poner, renovar o quitar el aura
}

local nivelAplicado = {}   -- [guidLow] = nivel con el que se lanzó el aura
local avisadoFallo = {}

local function Aplicar(p)
    local nivel = p:GetLevel()
    local resist = math.max(1, math.floor(nivel * CFG.RESIST_POR_NIVEL))

    if p:HasAura(CFG.SPELL_ID) then p:RemoveAura(CFG.SPELL_ID) end

    -- 1) valores calculados con CastCustomSpell
    pcall(function() p:CastCustomSpell(p, CFG.SPELL_ID, true, CFG.STATS_PCT, CFG.ARMADURA_PCT, resist) end)
    -- 2) si no se pudo, aura con los valores por defecto del SQL
    local metodo = "CastCustomSpell"
    if not p:HasAura(CFG.SPELL_ID) then
        pcall(function() p:AddAura(CFG.SPELL_ID, p) end)
        metodo = "AddAura (valores del SQL)"
    end

    if p:HasAura(CFG.SPELL_ID) then
        nivelAplicado[p:GetGUIDLow()] = nivel
        if CFG.DEBUG_AURA then
            Campamento.Debug(p, string.format("Encantamiento: aura puesta con %s (+%d%% stats, +%d%% armadura, +%d resistencias).",
                metodo, CFG.STATS_PCT, CFG.ARMADURA_PCT, resist))
        end
    else
        local g = p:GetGUIDLow()
        if not avisadoFallo[g] then
            avisadoFallo[g] = true
            Campamento.Debug(p, "Encantamiento: NO se pudo poner el hechizo " .. CFG.SPELL_ID .. ". ¿Ejecutaste el SQL y reiniciaste el worldserver?")
            print("[Campamento] AVISO: el hechizo " .. CFG.SPELL_ID .. " no se pudo aplicar (falta Campamento_spells.sql / reinicio).")
        end
    end
end

local function Sincronizar(p)
    local activo = Campamento.TieneBuff(p, "encantamiento")
    local tiene = p:HasAura(CFG.SPELL_ID)
    local guid = p:GetGUIDLow()

    if activo and (not tiene or nivelAplicado[guid] ~= p:GetLevel()) then
        Aplicar(p)
    elseif not activo and tiene then
        p:RemoveAura(CFG.SPELL_ID)
        nivelAplicado[guid] = nil
        if CFG.DEBUG_AURA then Campamento.Debug(p, "Encantamiento: aura quitada.") end
    end
end

local function Tick()
    if not Campamento or not Campamento.TieneBuff then return end
    local jugadores = GetPlayersInWorld()
    if not jugadores then return end
    for _, p in pairs(jugadores) do
        if p:IsAlive() then pcall(Sincronizar, p) end
    end
end

CreateLuaEvent(Tick, CFG.INTERVALO_MS, 0)   -- repetir indefinidamente
print("[Campamento] Camp_encantamiento.lua cargado.")
