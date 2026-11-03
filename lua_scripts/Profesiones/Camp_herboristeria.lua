--[[
    Camp_herboristeria.lua  -  Módulo de Herboristería para Campamento_server.lua  (v1)
    Objeto del campamento: Ramo de flores.

    EFECTO: +10 a TODAS las habilidades de profesión (principales y secundarias) mientras dura el buff.
    No incluye velocidad de recolección: en 3.3.5 no existe un aura que acelere solo la recolección, el
    único disponible acelera TODOS los hechizos.

    REQUIERE los hechizos propios 900004-900008 (Campamento_spells.sql en la base de datos del MUNDO y
    reinicio del worldserver). Requiere Campamento_server.lua v6.1 o superior.
]]

local CFG = {
    SPELLS       = { 900004, 900005, 900006, 900007, 900008 },
    BONUS        = 10,
    INTERVALO_MS = 3000,
    DEBUG_AURA   = true,   -- PRUEBAS: avisa en el chat al poner o quitar los auras
}

local avisadoFallo = {}

local function TieneAlguna(p)
    for _, id in ipairs(CFG.SPELLS) do
        if p:HasAura(id) then return true end
    end
    return false
end

local function Quitar(p)
    for _, id in ipairs(CFG.SPELLS) do
        if p:HasAura(id) then p:RemoveAura(id) end
    end
end

local function Poner(p)
    local puestos = 0
    for _, id in ipairs(CFG.SPELLS) do
        pcall(function() p:CastCustomSpell(p, id, true, CFG.BONUS, CFG.BONUS, CFG.BONUS) end)
        if not p:HasAura(id) then pcall(function() p:AddAura(id, p) end) end
        if p:HasAura(id) then puestos = puestos + 1 end
    end
    if puestos == #CFG.SPELLS then
        if CFG.DEBUG_AURA then Campamento.Debug(p, string.format("Herboristería: +%d a todas las profesiones (%d auras puestas).", CFG.BONUS, puestos)) end
    else
        local g = p:GetGUIDLow()
        if not avisadoFallo[g] then
            avisadoFallo[g] = true
            Campamento.Debug(p, string.format("Herboristería: solo se pusieron %d de %d auras. ¿Ejecutaste el SQL y reiniciaste el worldserver?", puestos, #CFG.SPELLS))
            print("[Campamento] AVISO: no se pudieron aplicar todos los hechizos de herboristería (falta Campamento_spells.sql / reinicio).")
        end
    end
end

local function Sincronizar(p)
    local activo = Campamento.TieneBuff(p, "herboristeria")
    local tiene = TieneAlguna(p)

    if activo and not tiene then
        Poner(p)
    elseif not activo and tiene then
        Quitar(p)
        if CFG.DEBUG_AURA then Campamento.Debug(p, "Herboristería: auras quitadas.") end
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
print("[Campamento] Camp_herboristeria.lua cargado.")
