--[[
    Camp_alquimia.lua  -  Módulo de Alquimia para Campamento_server.lua  (v1)
    Objeto del campamento: Laboratorio de alquimia.

    EFECTO: con el buff activo, cada 5 segundos regenera maná:
      regeneración = maná máximo x (1 + nivel / 80) %
        nivel 20 -> 1,25 %   |   nivel 40 -> 1,5 %   |   nivel 80 -> 2 %
    Las clases sin maná (guerrero, pícaro, caballero de la muerte...) reciben el mismo
    porcentaje de su VIDA máxima en lugar de maná.

    Requiere Campamento_server.lua (v6.1 o superior) en la misma carpeta lua_scripts.
]]

local CFG = {
    INTERVALO_MS = 5000,
    BASE_PCT     = 1.0,    -- porcentaje = BASE_PCT + nivel / DIV_NIVEL
    DIV_NIVEL    = 80,
    VIDA_SI_NO_MANA = true,  -- las clases sin maná regeneran vida
    DEBUG_TICK   = false,  -- PRUEBAS: avisa en el chat de cada regeneración
}

local POWER_MANA = 0

local function Regenerar(p)
    local pct = CFG.BASE_PCT + p:GetLevel() / CFG.DIV_NIVEL
    local maxMana = p:GetMaxPower(POWER_MANA)

    if maxMana and maxMana > 0 then
        local actual = p:GetPower(POWER_MANA)
        if actual < maxMana then
            local suma = math.max(1, math.floor(maxMana * pct / 100))
            local nuevo = math.min(maxMana, actual + suma)
            p:SetPower(nuevo, POWER_MANA)
            if CFG.DEBUG_TICK then
                Campamento.Debug(p, string.format("Alquimia: +%d de maná (%.2f%% de %d)", nuevo - actual, pct, maxMana))
            end
        end
    elseif CFG.VIDA_SI_NO_MANA then
        local maxVida = p:GetMaxHealth()
        local vida = p:GetHealth()
        if vida < maxVida then
            local suma = math.max(1, math.floor(maxVida * pct / 100))
            p:SetHealth(math.min(maxVida, vida + suma))
            if CFG.DEBUG_TICK then
                Campamento.Debug(p, string.format("Alquimia: +%d de vida (%.2f%% de %d)", suma, pct, maxVida))
            end
        end
    end
end

local function Tick()
    if not Campamento or not Campamento.TieneBuff then return end
    local jugadores = GetPlayersInWorld()
    if not jugadores then return end
    for _, p in pairs(jugadores) do
        if p:IsAlive() and Campamento.TieneBuff(p, "alquimia") then
            pcall(Regenerar, p)
        end
    end
end

CreateLuaEvent(Tick, CFG.INTERVALO_MS, 0)   -- repetir indefinidamente
print("[Campamento] Camp_alquimia.lua cargado.")
