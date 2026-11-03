--[[
    Camp_mineria.lua  -  Módulo de Minería para Campamento_server.lua  (v1)
    Objeto del campamento: Buzón.

    EFECTO: +5 % de poder de ataque (cuerpo a cuerpo y a distancia) mientras dura el buff.
    Es un porcentaje sobre tu poder de ataque, así que escala solo con el nivel y el equipo.
    Los lanzadores de hechizos puros no ganan nada con el poder de ataque.

    REQUIERE el hechizo propio 900009 (Campamento_spells.sql en la base de datos del MUNDO y reinicio
    del worldserver). Requiere Campamento_server.lua v6.1 o superior.
]]

local CFG = {
    SPELL_ID     = 900009,
    PCT          = 5,
    INTERVALO_MS = 3000,
    DEBUG_AURA   = true,   -- PRUEBAS: avisa en el chat al poner o quitar el aura
}

local avisadoFallo = {}

local function Poner(p)
    -- 1) con CastCustomSpell, para que el valor sea exactamente CFG.PCT
    pcall(function() p:CastCustomSpell(p, CFG.SPELL_ID, true, CFG.PCT, CFG.PCT) end)
    local metodo = "CastCustomSpell"
    -- 2) si no se pudo, con los valores por defecto del SQL
    if not p:HasAura(CFG.SPELL_ID) then
        pcall(function() p:AddAura(CFG.SPELL_ID, p) end)
        metodo = "AddAura (valores del SQL)"
    end

    if p:HasAura(CFG.SPELL_ID) then
        if CFG.DEBUG_AURA then Campamento.Debug(p, string.format("Minería: +%d%% de poder de ataque puesto con %s.", CFG.PCT, metodo)) end
    else
        local g = p:GetGUIDLow()
        if not avisadoFallo[g] then
            avisadoFallo[g] = true
            Campamento.Debug(p, "Minería: NO se pudo poner el hechizo " .. CFG.SPELL_ID .. ". ¿Ejecutaste el SQL y reiniciaste el worldserver?")
            print("[Campamento] AVISO: el hechizo " .. CFG.SPELL_ID .. " no se pudo aplicar (falta Campamento_spells.sql / reinicio).")
        end
    end
end

local function Sincronizar(p)
    local activo = Campamento.TieneBuff(p, "mineria")
    local tiene = p:HasAura(CFG.SPELL_ID)

    if activo and not tiene then
        Poner(p)
    elseif not activo and tiene then
        p:RemoveAura(CFG.SPELL_ID)
        if CFG.DEBUG_AURA then Campamento.Debug(p, "Minería: aura quitada.") end
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
print("[Campamento] Camp_mineria.lua cargado.")
