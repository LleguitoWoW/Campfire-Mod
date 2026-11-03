--[[
    Camp_herreria.lua  -  Módulo de Herrería para Campamento_server.lua  (v1)
    Objeto del campamento: Fragua.

    EFECTO: +3 % de fuerza y +3 % de agilidad mientras dura el buff del campamento.
    Es un porcentaje sobre tus estadísticas totales, así que escala solo con el nivel y el equipo:
    casi nada en nivel 20 y notable en nivel 80.

    REQUIERE el hechizo propio 900002 (archivo Campamento_spells.sql en la base de datos del MUNDO
    y reinicio del worldserver). Requiere Campamento_server.lua v6.1 o superior.
]]

local CFG = {
    SPELL_ID     = 900002,
    INTERVALO_MS = 3000,   -- cada cuánto se sincroniza el aura con el buff del campamento
    DEBUG_AURA   = true,   -- PRUEBAS: avisa en el chat al poner o quitar el aura
}

local avisadoFallo = {}

-- Pone el aura mientras el buff esté activo y la quita cuando caduca (o tras un reinicio)
local function Sincronizar(p)
    local activo = Campamento.TieneBuff(p, "herreria")
    local tiene = p:HasAura(CFG.SPELL_ID)

    if activo and not tiene then
        pcall(function() p:AddAura(CFG.SPELL_ID, p) end)
        if p:HasAura(CFG.SPELL_ID) then
            if CFG.DEBUG_AURA then Campamento.Debug(p, "Herrería: aura 'Acero templado' puesta (+3% fuerza y agilidad).") end
        else
            local g = p:GetGUIDLow()
            if not avisadoFallo[g] then
                avisadoFallo[g] = true
                Campamento.Debug(p, "Herrería: NO se pudo poner el hechizo " .. CFG.SPELL_ID .. ". ¿Ejecutaste el SQL y reiniciaste el worldserver?")
                print("[Campamento] AVISO: el hechizo " .. CFG.SPELL_ID .. " no se pudo aplicar (falta Campamento_spells.sql / reinicio).")
            end
        end
    elseif not activo and tiene then
        p:RemoveAura(CFG.SPELL_ID)
        if CFG.DEBUG_AURA then Campamento.Debug(p, "Herrería: aura 'Acero templado' quitada.") end
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
print("[Campamento] Camp_herreria.lua cargado.")
