--[[
    Camp_inscripcion.lua  -  Módulo de Inscripción para Campamento_server.lua  (v1)
    Objeto del campamento: Orbe de Grishnath.

    EFECTO: con el buff activo, al recoger un objeto (botín de bichos, cofres...) hay una probabilidad
    de encontrar UNA COPIA EXTRA, según su calidad:
        común (blanco)       5 %
        poco común (verde)   3 %
        raro (azul)          2 %
    Las probabilidades bajan cuanto más valioso es el objeto. No afecta a grises, épicos, objetos de
    misión ni a bolsas. Si el objeto es apilable, la copia extra tiene la misma cantidad.
    No necesita hechizos ni SQL.

    Requiere Campamento_server.lua v6.1 o superior.
    Evento de mod-ale: PLAYER_EVENT_ON_LOOT_ITEM (32)  (event, player, item, count)
]]

local CFG = {
    PROBABILIDAD = { [1] = 5, [2] = 3, [3] = 2 },   -- % por calidad (1 común, 2 poco común, 3 raro)
    CLASE_MISION = 12,    -- clase de objeto "misión": se excluye
    AVISAR       = true,  -- mensaje cuando encuentras una copia extra
    DEBUG_TIRADAS = true, -- PRUEBAS: avisa en el chat de cada tirada
}

local enExtra = false   -- evita que la propia copia extra dispare otra tirada

local function EnlaceObjeto(item)
    local ok, link = pcall(function() return item:GetItemLink() end)
    if ok and link then return link end
    local ok2, entry = pcall(function() return item:GetEntry() end)
    return "objeto " .. tostring(ok2 and entry or "?")
end

local function AlRecogerObjeto(event, player, item, count)
    if enExtra then return end
    if not player or not item then return end
    if not Campamento or not Campamento.TieneBuff then return end
    if not Campamento.TieneBuff(player, "inscripcion") then return end

    local okq, calidad = pcall(function() return item:GetQuality() end)
    local prob = okq and CFG.PROBABILIDAD[calidad]
    if not prob then return end

    local okc, clase = pcall(function() return item:GetClass() end)
    if okc and (clase == CFG.CLASE_MISION or item:IsBag()) then return end

    local tirada = math.random(1, 100)
    if CFG.DEBUG_TIRADAS then
        Campamento.Debug(player, string.format("Inscripción: tirada %d (necesita <= %d) para %s.", tirada, prob, EnlaceObjeto(item)))
    end
    if tirada > prob then return end

    local okn, entry = pcall(function() return item:GetEntry() end)
    if not okn or not entry then return end

    enExtra = true
    local okadd, nuevo = pcall(function() return player:AddItem(entry, count or 1) end)
    enExtra = false

    if okadd and nuevo and CFG.AVISAR then
        player:SendBroadcastMessage("|cff66ccff[Campamento]|r ¡Tu suerte de escriba ha encontrado otro " .. EnlaceObjeto(item) .. "!")
    elseif CFG.DEBUG_TIRADAS then
        Campamento.Debug(player, "Inscripción: no se pudo añadir la copia extra (¿objeto único o bolsas llenas?).")
    end
end

RegisterPlayerEvent(32, AlRecogerObjeto)   -- PLAYER_EVENT_ON_LOOT_ITEM
print("[Campamento] Camp_inscripcion.lua cargado.")
