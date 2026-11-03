--[[
    Camp_primerosauxilios.lua  -  Módulo de Primeros auxilios para Campamento_server.lua  (v2)
    Objeto del campamento: Cajas de suministros.

    EFECTO: +5 % de vida máxima mientras dura el buff del campamento.
    Es un porcentaje, así que escala solo con el nivel y el equipo.

    REQUIERE el hechizo propio 900013 (Campamento_spells.sql en la base de datos del MUNDO y reinicio
    del worldserver). Requiere Campamento_server.lua v6.1 o superior.
]]

local CFG = {
    SPELL_ID     = 900013,
    INTERVALO_MS = 3000,
    DEBUG_AURA   = true,   -- PRUEBAS: avisa en el chat al poner o quitar el aura
}

local avisadoFallo = {}

local function Sincronizar(p)
    local activo = Campamento.TieneBuff(p, "primerosauxilios")
    local tiene = p:HasAura(CFG.SPELL_ID)

    if activo and not tiene then
        pcall(function() p:AddAura(CFG.SPELL_ID, p) end)
        if p:HasAura(CFG.SPELL_ID) then
            if CFG.DEBUG_AURA then Campamento.Debug(p, "Primeros auxilios: +5% de vida máxima puesto.") end
        else
            local g = p:GetGUIDLow()
            if not avisadoFallo[g] then
                avisadoFallo[g] = true
                Campamento.Debug(p, "Primeros auxilios: NO se pudo poner el hechizo " .. CFG.SPELL_ID .. ". ¿Ejecutaste el SQL y reiniciaste el worldserver?")
                print("[Campamento] AVISO: el hechizo " .. CFG.SPELL_ID .. " no se pudo aplicar (falta Campamento_spells.sql / reinicio).")
            end
        end
    elseif not activo and tiene then
        p:RemoveAura(CFG.SPELL_ID)
        if CFG.DEBUG_AURA then Campamento.Debug(p, "Primeros auxilios: aura de vida quitada.") end
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
print("[Campamento] Camp_primerosauxilios.lua cargado.")
