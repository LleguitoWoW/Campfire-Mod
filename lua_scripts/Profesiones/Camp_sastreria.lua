--[[
    Camp_sastreria.lua  -  Módulo de Sastrería para Campamento_server.lua  (v1)
    Objeto del campamento: Cajas de vendas.

    EFECTO (mientras dura el buff del campamento):
      +2 % de espíritu
      +5 % de daño de hechizos (escuelas mágicas) y +5 % de sanación
    Son porcentajes, así que escalan solos con el nivel y el equipo. Solo reciben el buff los jugadores
    de la misma facción que quien colocó el objeto (ver 'faccion' en Campamento_server.lua).

    REQUIERE el hechizo propio 900011 (Campamento_spells.sql en la base de datos del MUNDO y reinicio
    del worldserver). Requiere Campamento_server.lua v6.1 o superior.
]]

local CFG = {
    SPELL_ID     = 900011,
    ESPIRITU_PCT = 2,
    DANIO_PCT    = 5,
    SANACION_PCT = 5,
    INTERVALO_MS = 3000,
    DEBUG_AURA   = true,   -- PRUEBAS: avisa en el chat al poner o quitar el aura
}

local avisadoFallo = {}

local function Poner(p)
    -- 1) con CastCustomSpell, para que el valor sea exactamente CFG.PCT
    pcall(function() p:CastCustomSpell(p, CFG.SPELL_ID, true, CFG.ESPIRITU_PCT, CFG.DANIO_PCT, CFG.SANACION_PCT) end)
    local metodo = "CastCustomSpell"
    -- 2) si no se pudo, con los valores por defecto del SQL
    if not p:HasAura(CFG.SPELL_ID) then
        pcall(function() p:AddAura(CFG.SPELL_ID, p) end)
        metodo = "AddAura (valores del SQL)"
    end

    if p:HasAura(CFG.SPELL_ID) then
        if CFG.DEBUG_AURA then Campamento.Debug(p, string.format("Sastrería: +%d%% espíritu, +%d%% daño y +%d%% sanación puestos con %s.", CFG.ESPIRITU_PCT, CFG.DANIO_PCT, CFG.SANACION_PCT, metodo)) end
    else
        local g = p:GetGUIDLow()
        if not avisadoFallo[g] then
            avisadoFallo[g] = true
            Campamento.Debug(p, "Sastrería: NO se pudo poner el hechizo " .. CFG.SPELL_ID .. ". ¿Ejecutaste el SQL y reiniciaste el worldserver?")
            print("[Campamento] AVISO: el hechizo " .. CFG.SPELL_ID .. " no se pudo aplicar (falta Campamento_spells.sql / reinicio).")
        end
    end
end

local function Sincronizar(p)
    local activo = Campamento.TieneBuff(p, "sastreria")
    local tiene = p:HasAura(CFG.SPELL_ID)

    if activo and not tiene then
        Poner(p)
    elseif not activo and tiene then
        p:RemoveAura(CFG.SPELL_ID)
        if CFG.DEBUG_AURA then Campamento.Debug(p, "Sastrería: aura quitada.") end
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
print("[Campamento] Camp_sastreria.lua cargado.")
