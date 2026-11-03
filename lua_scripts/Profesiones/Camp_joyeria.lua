--[[
    Camp_joyeria.lua  -  Módulo de Joyería para Campamento_server.lua  (v1)
    Objeto del campamento: Caja precintada.

    EFECTO (mientras dura el buff del campamento):
      +15 % de velocidad de movimiento a pie
      +20 % de velocidad montado (también volando), que se SUMA a la de la montura
      Paladín con Aura de cruzado activa: +10 % en lugar de +20 % montado, porque ya tiene su +20 %.
    No varía con el nivel.

    REQUIERE el hechizo propio 900012 (Campamento_spells.sql en la base de datos del MUNDO y reinicio
    del worldserver). Requiere Campamento_server.lua v6.1 o superior.
]]

local CFG = {
    SPELL_ID           = 900012,
    PIE_PCT            = 15,
    MONTURA_PCT        = 20,
    MONTURA_CRUZADO_PCT = 10,
    SPELL_CRUZADO      = 32223,   -- Aura de cruzado
    INTERVALO_MS       = 3000,
    DEBUG_AURA         = true,    -- PRUEBAS: avisa en el chat al poner, cambiar o quitar el aura
}

local modoAplicado = {}   -- [guidLow] = "normal" | "cruzado"
local avisadoFallo = {}

local function ModoActual(p)
    if p:HasAura(CFG.SPELL_CRUZADO) then return "cruzado" end
    return "normal"
end

local function Poner(p, modo)
    local montura = (modo == "cruzado") and CFG.MONTURA_CRUZADO_PCT or CFG.MONTURA_PCT

    if p:HasAura(CFG.SPELL_ID) then p:RemoveAura(CFG.SPELL_ID) end

    -- 1) con CastCustomSpell, para fijar los tres valores
    pcall(function() p:CastCustomSpell(p, CFG.SPELL_ID, true, CFG.PIE_PCT, montura, montura) end)
    local metodo = "CastCustomSpell"
    -- 2) si no se pudo, con los valores por defecto del SQL
    if not p:HasAura(CFG.SPELL_ID) then
        pcall(function() p:AddAura(CFG.SPELL_ID, p) end)
        metodo = "AddAura (valores del SQL)"
    end

    if p:HasAura(CFG.SPELL_ID) then
        modoAplicado[p:GetGUIDLow()] = modo
        if CFG.DEBUG_AURA then
            Campamento.Debug(p, string.format("Joyería: +%d%% a pie y +%d%% montado (%s) puestos con %s.",
                CFG.PIE_PCT, montura, modo == "cruzado" and "Aura de cruzado" or "normal", metodo))
        end
    else
        local g = p:GetGUIDLow()
        if not avisadoFallo[g] then
            avisadoFallo[g] = true
            Campamento.Debug(p, "Joyería: NO se pudo poner el hechizo " .. CFG.SPELL_ID .. ". ¿Ejecutaste el SQL y reiniciaste el worldserver?")
            print("[Campamento] AVISO: el hechizo " .. CFG.SPELL_ID .. " no se pudo aplicar (falta Campamento_spells.sql / reinicio).")
        end
    end
end

local function Sincronizar(p)
    local activo = Campamento.TieneBuff(p, "joyeria")
    local tiene = p:HasAura(CFG.SPELL_ID)
    local guid = p:GetGUIDLow()

    if activo then
        local modo = ModoActual(p)
        if not tiene or modoAplicado[guid] ~= modo then
            Poner(p, modo)
        end
    elseif tiene then
        p:RemoveAura(CFG.SPELL_ID)
        modoAplicado[guid] = nil
        if CFG.DEBUG_AURA then Campamento.Debug(p, "Joyería: aura quitada.") end
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
print("[Campamento] Camp_joyeria.lua cargado.")
