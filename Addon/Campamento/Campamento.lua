--[[
    Campamento - addon para WoW 3.3.5a  (v1.23)
      - Boton en el minimapa: clic = abrir/cerrar el panel, arrastrar = moverlo alrededor del minimapa.
      - Panel: titulo con el dueño del campamento, circulos con las profesiones colocadas (3, 4 o 5),
        y a la derecha la lista de profesiones con el bufo que dan. Clic en una fila = colocar tu objeto.
      - El servidor envia el estado como un mensaje de sistema "CAMPDATA#..." que el addon oculta del chat.

    Comandos:
      /campamento            abre o cierra el panel
      /campamento test       muestra un campamento de prueba (para comprobar el aspecto sin servidor)
      /campamento buffs      muestra un buff de prueba en la fila de buffs
      /campamento debug      escribe en el chat cada mensaje CAMPDATA recibido del servidor
      /campamento minimapa   muestra u oculta el boton del minimapa
]]

----------------------------------------------------------------------
-- Ajustes de aspecto (retocalos si algo no te cuadra)
----------------------------------------------------------------------
local TAM      = 56    -- tamaño del circulo
local GAP      = 10    -- separacion entre circulos
local ICONO    = 36    -- tamaño del icono dentro del circulo
local ICONO_X, ICONO_Y = 13, -9   -- posicion del icono respecto al anillo
local BORDE    = 95    -- tamaño del anillo dorado
local CENTRO_X = 173   -- centro de la zona izquierda del panel
local CIRCULOS_Y = -170

local ICONO_MINIMAPA = "Interface\\Icons\\Spell_Fire_Fire"   -- icono del boton del minimapa
local ANGULO_INICIAL = 215                                     -- posicion inicial en el minimapa (grados)

----------------------------------------------------------------------
-- Profesiones (la clave debe coincidir con la del script del servidor)
----------------------------------------------------------------------
local PROFESIONES = {
    { clave = "herreria",         prof = "Herrería",          objeto = "Fragua",           efecto = "+3% fuerza y agilidad",                  icono = "Interface\\Icons\\Trade_BlackSmithing",
      buffIcono = "Interface\\Icons\\Spell_Nature_Strength", buffNombre = "Acero templado",
      buffDesc = "Aumenta un 3% tu fuerza y tu agilidad." },
    { clave = "alquimia",         prof = "Alquimia",          objeto = "Laboratorio de alquimia",              efecto = "Regeneración de maná (o vida)",    icono = "Interface\\Icons\\Trade_Alchemy",
      buffIcono = "Interface\\Icons\\Spell_Holy_SealOfWisdom", buffNombre = "Elixir de maná",
      buffDesc = "Regenera cada 5 s entre el 1,25% y el 2% de tu maná máximo según tu nivel. Si tu clase no usa maná, regenera ese porcentaje de vida." },
    { clave = "encantamiento",    prof = "Encantamiento",     objeto = "Gema flotante",            efecto = "Estadísticas, armadura y resistencias", icono = "Interface\\Icons\\Trade_Engraving",
      buffIcono = "Interface\\Icons\\Spell_Nature_Regeneration", buffNombre = "Laúd encantado",
      buffDesc = "Aumenta un 2% todas tus estadísticas, un 5% tu armadura y todas tus resistencias mágicas (nivel x 0,5)." },
    { clave = "herboristeria",    prof = "Herboristería",     objeto = "Ramo de flores",          efecto = "+10 a todas las profesiones",               icono = "Interface\\Icons\\Trade_Herbalism",
      buffIcono = "Interface\\Icons\\Spell_Nature_NatureTouchGrow", buffNombre = "Cosecha diestra",
      buffDesc = "Aumenta en 10 tus habilidades de todas las profesiones." },
    { clave = "sastreria",        prof = "Sastrería",         objeto = "Cajas de vendas",     efecto = "Espíritu, daño de hechizos y sanación",   icono = "Interface\\Icons\\Trade_Tailoring",
      buffIcono = "Interface\\Icons\\Spell_Holy_DivineSpirit", buffNombre = "Estandarte de facción",
      buffDesc = "Aumenta un 2% tu espíritu y un 5% tu daño de hechizos y tu sanación. Solo si eres de la misma facción que quien colocó el objeto." },
    { clave = "primerosauxilios", prof = "Primeros auxilios", objeto = "Cajas de suministros", efecto = "+5% vida máxima",              icono = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
      buffIcono = "Interface\\Icons\\Spell_Holy_Heal", buffNombre = "Botiquín de campaña",
      buffDesc = "Aumenta un 5% tu vida máxima." },
    { clave = "pesca",            prof = "Pesca",             objeto = "Pescado del día",        efecto = "+5% a todas las estadísticas",            icono = "Interface\\Icons\\Trade_Fishing",
      buffIcono = "Interface\\Icons\\Spell_Magic_MageArmor", buffNombre = "Banquete del pescador",
      buffDesc = "Aumenta un 5% todas tus estadísticas." },
    { clave = "desuello",         prof = "Desuello",          objeto = "Secadero de carne",       efecto = "+2% probabilidad de crítico",     icono = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
      buffIcono = "Interface\\Icons\\Ability_CriticalStrike", buffNombre = "Instinto del desollador",
      buffDesc = "Aumenta un 2% tu probabilidad de golpe crítico con ataques, hechizos y curaciones." },
    { clave = "peleteria",        prof = "Peletería",         objeto = "Tienda de campaña",      efecto = "+10% experiencia y reputación",       icono = "Interface\\Icons\\Trade_LeatherWorking",
      buffIcono = "Interface\\Icons\\INV_Misc_Book_09", buffNombre = "Veterano de campaña",
      buffDesc = "Aumenta un 10% la experiencia (bichos, misiones, exploración) y la reputación que ganas." },
    { clave = "ingenieria",       prof = "Ingeniería",        objeto = "Caja de munición",         efecto = "Explosión de fuego al golpear",    icono = "Interface\\Icons\\Trade_Engineering",
      buffIcono = "Interface\\Icons\\Spell_Fire_SelfDestruct", buffNombre = "Munición explosiva",
      buffDesc = "2% de probabilidad al golpear de provocar una explosión de fuego en área (del 50% al 150% del golpe según tu nivel)." },
    { clave = "mineria",          prof = "Minería",           objeto = "Buzón",           efecto = "+5% poder de ataque",                icono = "Interface\\Icons\\Trade_Mining",
      buffIcono = "Interface\\Icons\\Ability_Warrior_BattleShout", buffNombre = "Veta de poder",
      buffDesc = "Aumenta un 5% tu poder de ataque, cuerpo a cuerpo y a distancia." },
    { clave = "joyeria",          prof = "Joyería",           objeto = "Caja precintada",          efecto = "+15% velocidad (+20% montado)",        icono = "Interface\\Icons\\INV_Misc_Gem_01",
      buffIcono = "Interface\\Icons\\Ability_Rogue_Sprint", buffNombre = "Pies ligeros",
      buffDesc = "Aumenta un 15% tu velocidad de movimiento y un 20% montado (10% si eres paladín con Aura de cruzado)." },
    { clave = "inscripcion",      prof = "Inscripción",       objeto = "Orbe de Grishnath",           efecto = "Copia extra de objetos",                icono = "Interface\\Icons\\INV_Inscription_Tradeskill01",
      buffIcono = "Interface\\Icons\\INV_Misc_Gift_01", buffNombre = "Suerte de escriba",
      buffDesc = "Al recoger un objeto, probabilidad de encontrar una copia extra: 5% común, 3% poco común, 2% raro." },
}

local POR_CLAVE = {}
for _, p in ipairs(PROFESIONES) do POR_CLAVE[p.clave] = p end

----------------------------------------------------------------------
-- Estado
----------------------------------------------------------------------
local estado  = nil     -- { dueno, expira, maxHuecos, slots = { {clave, jugador} }, activos = { clave = jugador }, demo }
local cerrado = false   -- el jugador cerro el panel a mano estando en un campamento
local manual  = false   -- el panel se abrio a mano (boton o comando), se queda aunque no haya campamento
local eco     = false   -- /campamento debug

local function Aviso(texto)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[Campamento]|r " .. texto)
end

local function ParsearMensaje(msg)
    if msg == "CAMPDATA#NONE" then return nil, true end
    local dueno, restante, huecos, resto = msg:match("^CAMPDATA#([^#]*)#(%d+)#(%d+)#(.*)$")
    if not dueno then return nil, false end

    local e = {
        dueno     = dueno,
        expira    = GetTime() + tonumber(restante),
        maxHuecos = tonumber(huecos),
        slots     = {},
        activos   = {},
    }
    for clave, jugador in resto:gmatch("([^:;]+):([^;]*)") do
        e.slots[#e.slots + 1] = { clave = clave, jugador = jugador }
        e.activos[clave] = jugador
    end
    return e, true
end

-- CAMPPOOL#modo#clave=jugador;clave=jugador
-- modo: L = eres el lider, M = miembro que coloca lo suyo, X = no puedes colocar
local function ParsearPool(msg)
    local modo, resto = msg:match("^CAMPPOOL#(%a)#(.*)$")
    if not modo then return nil end
    local disp = {}
    for clave, nombre in resto:gmatch("([^=;]+)=([^;]*)") do
        disp[clave] = nombre
    end
    return modo, disp
end

----------------------------------------------------------------------
-- Panel
----------------------------------------------------------------------
local f = CreateFrame("Frame", "CampamentoFrame", UIParent)
f:SetWidth(640)
f:SetHeight(440)
f:SetPoint("CENTER", 0, 60)
f:SetFrameStrata("MEDIUM")
f:SetClampedToScreen(true)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
f:Hide()

f.titulo = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
f.titulo:SetPoint("TOP", f, "TOP", 0, -20)

f.tiempo = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
f.tiempo:SetPoint("TOP", f.titulo, "BOTTOM", 0, -6)

f.vacio = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.vacio:SetPoint("CENTER", f, "TOPLEFT", CENTRO_X, CIRCULOS_Y - 28)
f.vacio:SetWidth(280)
f.vacio:SetText("No hay ningún campamento cerca.\n\nEnciende una hoguera con Cocina\npara formar uno.")
f.vacio:Hide()

f.ayuda = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
f.ayuda:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 28, 24)
f.ayuda:SetWidth(300)
f.ayuda:SetJustifyH("LEFT")

-- Cocina: habilidad actual y lo que falta para el siguiente rango de campamento
f.cocina = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
f.cocina:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 28, 50)
f.cocina:SetWidth(300)
f.cocina:SetJustifyH("LEFT")
f.cocina:SetText("|cffaaaaaaCocina: consultando...|r")

local cocina = nil   -- { valor, huecos, rango, siguiente, sigHuecos }

local function ActualizarCocina()
    if not cocina then return end
    local c = cocina
    local linea1 = string.format("|cffffd100Cocina %d|r  -  Rango %d de campamento (%d huecos)", c.valor, c.rango, c.huecos)
    local linea2
    if c.siguiente > 0 then
        linea2 = string.format("|cff66ccffFaltan %d puntos de Cocina (%d) para el rango %d: %d huecos|r",
            math.max(0, c.siguiente - c.valor), c.siguiente, c.rango + 1, c.sigHuecos)
    else
        linea2 = "|cff66ff66Rango máximo de campamento alcanzado|r"
    end
    f.cocina:SetText(linea1 .. "\n" .. linea2)
end

local ultimaPeticionCocina = 0
f:SetScript("OnShow", function()
    if GetTime() - ultimaPeticionCocina > 2 then
        ultimaPeticionCocina = GetTime()
        SendChatMessage(".camp cocina", "SAY")
    end
end)

local divisor = f:CreateTexture(nil, "ARTWORK")
divisor:SetTexture(1, 1, 1, 0.15)
divisor:SetWidth(1)
divisor:SetPoint("TOPLEFT", f, "TOPLEFT", 345, -55)
divisor:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 345, 18)

----------------------------------------------------------------------
-- Circulos (zona central)
----------------------------------------------------------------------
local slots = {}

local function CrearSlot()
    local b = CreateFrame("Button", nil, f)
    b:SetWidth(TAM)
    b:SetHeight(TAM)

    b.icono = b:CreateTexture(nil, "BACKGROUND")
    b.icono:SetWidth(ICONO)
    b.icono:SetHeight(ICONO)
    b.icono:SetPoint("TOPLEFT", b, "TOPLEFT", ICONO_X, ICONO_Y)

    local borde = b:CreateTexture(nil, "OVERLAY")
    borde:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    borde:SetWidth(BORDE)
    borde:SetHeight(BORDE)
    borde:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)

    b.nombre = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.nombre:SetPoint("TOP", b, "BOTTOM", 0, -2)
    b.nombre:SetWidth(TAM + GAP)
    b.nombre:SetHeight(12)

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.info then
            GameTooltip:SetText(self.info.objeto, 1, 1, 1)
            GameTooltip:AddLine(self.info.efecto, 1, 0.82, 0)
            GameTooltip:AddLine("Colocado por " .. self.info.jugador, 0.7, 0.7, 0.7)
        else
            GameTooltip:SetText("Hueco libre", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

for i = 1, 5 do slots[i] = CrearSlot() end

----------------------------------------------------------------------
-- Lista de profesiones (zona derecha)
----------------------------------------------------------------------
local filas = {}

for i, p in ipairs(PROFESIONES) do
    local fila = CreateFrame("Button", nil, f)
    fila:SetWidth(272)
    fila:SetHeight(27)
    fila:SetPoint("TOPLEFT", f, "TOPLEFT", 354, -58 - (i - 1) * 28)
    fila:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    fila.clave = p.clave

    fila.icono = fila:CreateTexture(nil, "ARTWORK")
    fila.icono:SetWidth(24)
    fila.icono:SetHeight(24)
    fila.icono:SetPoint("LEFT", fila, "LEFT", 2, 0)
    fila.icono:SetTexture(p.icono)
    fila.icono:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    fila.linea1 = fila:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fila.linea1:SetPoint("TOPLEFT", fila.icono, "TOPRIGHT", 6, 1)
    fila.linea1:SetJustifyH("LEFT")

    fila.linea2 = fila:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fila.linea2:SetPoint("BOTTOMLEFT", fila.icono, "BOTTOMRIGHT", 6, -1)
    fila.linea2:SetJustifyH("LEFT")

    fila:SetScript("OnClick", function(self)
        if not estado then
            Aviso("No hay ningún campamento cerca.")
        elseif estado.demo then
            Aviso("Esto es solo una prueba visual.")
        elseif estado.modo == "X" then
            Aviso("Solo el líder del campamento (" .. estado.dueno .. ") puede colocar objetos.")
        elseif self.estado == "colocada" then
            Aviso("Ese objeto ya está colocado.")
        elseif self.estado ~= "disponible" then
            Aviso("Nadie del grupo cercano puede aportar " .. p.prof .. " ahora (profesión, cooldown u objeto ya colocado).")
        else
            SendChatMessage(".camp poner " .. self.clave, "SAY")
        end
    end)
    fila:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(p.objeto, 1, 1, 1)
        GameTooltip:AddLine(p.prof .. ": " .. p.efecto, 1, 0.82, 0)
        if self.estado == "disponible" then
            GameTooltip:AddLine("Disponible: lo aporta " .. (self.aporta or "?"), 0.5, 1, 0.5)
            GameTooltip:AddLine("Clic para colocarlo", 0.5, 1, 0.5)
        elseif self.estado == "colocada" then
            GameTooltip:AddLine("Ya colocado en este campamento", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("No disponible ahora", 1, 0.3, 0.3)
        end
        GameTooltip:Show()
    end)
    fila:SetScript("OnLeave", function() GameTooltip:Hide() end)

    filas[i] = fila
end

----------------------------------------------------------------------
-- Actualizar la interfaz con el estado actual
----------------------------------------------------------------------
local function PintarFilas()
    for i, p in ipairs(PROFESIONES) do
        local fila = filas[i]
        local dueno = estado and estado.activos[p.clave]
        local aporta = estado and estado.disp and estado.disp[p.clave]
        fila.linea1:SetText(p.prof .. " - " .. p.objeto)
        if dueno then
            fila.icono:SetAlpha(1)
            fila.icono:SetDesaturated(nil)
            fila.linea2:SetText(p.efecto .. "  |cff00ff00(colocado: " .. dueno .. ")|r")
            fila.estado = "colocada"
        elseif aporta then
            fila.icono:SetAlpha(1)
            fila.icono:SetDesaturated(nil)
            fila.linea2:SetText(p.efecto .. "  |cffffd100(disponible: " .. aporta .. ")|r")
            fila.estado = "disponible"
        else
            fila.icono:SetAlpha(0.4)
            fila.icono:SetDesaturated(1)
            fila.linea2:SetText("|cff999999" .. p.efecto .. "|r")
            fila.estado = "no"
        end
        fila.aporta = aporta
    end
end

local function Actualizar()
    PintarFilas()

    if not estado then
        f.titulo:SetText("Campamento")
        f.tiempo:SetText("")
        f.ayuda:SetText("")
        f.vacio:Show()
        for i = 1, 5 do slots[i]:Hide() end
        return
    end

    f.vacio:Hide()
    f.titulo:SetText("Campamento de " .. estado.dueno)

    if estado.demo then
        f.ayuda:SetText("Campamento de prueba (solo visual).")
    elseif estado.modo == "L" then
        f.ayuda:SetText("Eres el líder: pulsa una profesión disponible para colocarla.")
    elseif estado.modo == "M" then
        f.ayuda:SetText("Pulsa una profesión disponible para colocar tu objeto.")
    elseif estado.modo == "X" then
        f.ayuda:SetText("Solo el líder (" .. estado.dueno .. ") coloca los objetos.")
    else
        f.ayuda:SetText("")
    end

    local n = estado.maxHuecos
    if n > 5 then n = 5 end
    if n < 1 then n = 1 end
    local ancho = n * TAM + (n - 1) * GAP
    local x0 = CENTRO_X - ancho / 2

    for i = 1, 5 do
        local b = slots[i]
        if i <= n then
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", f, "TOPLEFT", x0 + (i - 1) * (TAM + GAP), CIRCULOS_Y)

            local s = estado.slots[i]
            local p = s and POR_CLAVE[s.clave]
            if p then
                SetPortraitToTexture(b.icono, p.icono)
                b.icono:SetAlpha(1)
                b.icono:SetDesaturated(nil)
                b.nombre:SetText(s.jugador)
                b.info = { objeto = p.objeto, efecto = p.efecto, jugador = s.jugador }
            else
                SetPortraitToTexture(b.icono, "Interface\\Icons\\INV_Misc_QuestionMark")
                b.icono:SetAlpha(0.35)
                b.icono:SetDesaturated(1)
                b.nombre:SetText("")
                b.info = nil
            end
            b:Show()
        else
            b:Hide()
        end
    end
end

local acum = 0
f:SetScript("OnUpdate", function(self, elapsed)
    acum = acum + elapsed
    if acum < 0.5 then return end
    acum = 0
    if estado then
        local r = math.max(0, math.floor(estado.expira - GetTime()))
        self.tiempo:SetText(string.format("Quedan %d:%02d", math.floor(r / 60), r % 60))
    end
end)

----------------------------------------------------------------------
-- Abrir / cerrar
----------------------------------------------------------------------
local function Cerrar()
    cerrado = true
    manual = false
    if estado and estado.demo then estado = nil end
    f:Hide()
end

local function Abrir()
    cerrado = false
    manual = true
    Actualizar()
    f:Show()
end

local function Alternar()
    if f:IsShown() then Cerrar() else Abrir() end
end

local cerrar = CreateFrame("Button", nil, f, "UIPanelCloseButton")
cerrar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
cerrar:SetScript("OnClick", Cerrar)

----------------------------------------------------------------------
-- Boton del minimapa
----------------------------------------------------------------------
local mb = CreateFrame("Button", "CampamentoMinimapButton", Minimap)
mb:SetWidth(31)
mb:SetHeight(31)
mb:SetFrameStrata("MEDIUM")
mb:SetFrameLevel(8)
mb:RegisterForClicks("LeftButtonUp")
mb:RegisterForDrag("LeftButton")
mb:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local mbIcono = mb:CreateTexture(nil, "BACKGROUND")
mbIcono:SetTexture(ICONO_MINIMAPA)
mbIcono:SetWidth(20)
mbIcono:SetHeight(20)
mbIcono:SetPoint("TOPLEFT", mb, "TOPLEFT", 7, -6)

local mbBorde = mb:CreateTexture(nil, "OVERLAY")
mbBorde:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mbBorde:SetWidth(53)
mbBorde:SetHeight(53)
mbBorde:SetPoint("TOPLEFT", mb, "TOPLEFT", 0, 0)

local function PosicionarBoton()
    local ang = math.rad((CampamentoDB and CampamentoDB.angulo) or ANGULO_INICIAL)
    local radio = (Minimap:GetWidth() / 2) + 10
    mb:ClearAllPoints()
    mb:SetPoint("CENTER", Minimap, "CENTER", math.cos(ang) * radio, math.sin(ang) * radio)
end
PosicionarBoton()

mb:SetScript("OnClick", function() Alternar() end)

mb:SetScript("OnDragStart", function(self)
    GameTooltip:Hide()
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local escala = Minimap:GetEffectiveScale()
        px, py = px / escala, py / escala
        CampamentoDB = CampamentoDB or {}
        CampamentoDB.angulo = math.deg(math.atan2(py - my, px - mx))
        PosicionarBoton()
    end)
end)
mb:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

mb:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Campamento", 1, 1, 1)
    if estado and not estado.demo then
        GameTooltip:AddLine("Campamento de " .. estado.dueno, 0.5, 1, 0.5)
    else
        GameTooltip:AddLine("No hay ningún campamento cerca", 0.7, 0.7, 0.7)
    end
    GameTooltip:AddLine("Clic: abrir o cerrar el panel", 1, 0.82, 0)
    GameTooltip:AddLine("Arrastrar: mover el botón", 1, 0.82, 0)
    GameTooltip:Show()
end)
mb:SetScript("OnLeave", function() GameTooltip:Hide() end)

local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent", function(self, event, nombre)
    if nombre ~= "Campamento" then return end
    CampamentoDB = CampamentoDB or {}
    if CampamentoDB.buffPos then
        local bp = CampamentoDB.buffPos
        filaBuffs:ClearAllPoints()
        filaBuffs:SetPoint(bp[1], UIParent, bp[2], bp[3], bp[4])
    end
    PosicionarBoton()
    if CampamentoDB.oculto then mb:Hide() else mb:Show() end
    self:UnregisterEvent("ADDON_LOADED")
end)

----------------------------------------------------------------------
-- Fila de buffs activos (icono + tiempo restante)
-- El servidor envía:  CAMPBUFF#clave:segundos;clave:segundos   (o CAMPBUFF#NONE)
----------------------------------------------------------------------
local TAM_BUFF = 34
local buffs = {}   -- [clave] = GetTime() en que termina
local filaBuffs = CreateFrame("Frame", "CampamentoBuffsFrame", UIParent)
filaBuffs:SetWidth(TAM_BUFF)
filaBuffs:SetHeight(TAM_BUFF + 14)
filaBuffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -230, -20)
filaBuffs:SetClampedToScreen(true)
filaBuffs:SetMovable(true)
filaBuffs:EnableMouse(true)
filaBuffs:RegisterForDrag("LeftButton")
filaBuffs:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
filaBuffs:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local punto, _, relPunto, x, y = self:GetPoint()
    CampamentoDB = CampamentoDB or {}
    CampamentoDB.buffPos = { punto, relPunto, x, y }
end)
filaBuffs:Hide()

local iconosBuff = {}

local function TextoTiempo(seg)
    if seg >= 3600 then return string.format("%dh", math.ceil(seg / 3600)) end
    if seg >= 60 then return string.format("%dm", math.ceil(seg / 60)) end
    return string.format("%ds", seg)
end

local function CrearIconoBuff(n)
    local b = CreateFrame("Frame", nil, filaBuffs)
    b:SetWidth(TAM_BUFF)
    b:SetHeight(TAM_BUFF + 14)
    b:EnableMouse(true)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetWidth(TAM_BUFF - 2)
    b.tex:SetHeight(TAM_BUFF - 2)
    b.tex:SetPoint("TOP", b, "TOP", 0, -1)
    b.borde = b:CreateTexture(nil, "OVERLAY")
    b.borde:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    b.borde:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    b.borde:SetVertexColor(0.3, 0.8, 0.3)
    b.borde:SetAllPoints(b.tex)
    b.tiempo = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.tiempo:SetPoint("TOP", b.tex, "BOTTOM", 0, -1)
    b:SetScript("OnEnter", function(self)
        local d = self.datos
        if not d then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(d.buffNombre or d.efecto or d.prof, 1, 1, 1)
        GameTooltip:AddLine(d.prof .. " - " .. d.objeto, 0.4, 0.8, 1)
        GameTooltip:AddLine(d.buffDesc or d.efecto or "", 1, 0.82, 0, 1)
        if buffs[d.clave] then
            local r = math.max(0, math.floor(buffs[d.clave] - GetTime()))
            GameTooltip:AddLine("Tiempo restante: " .. TextoTiempo(r), 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("Mayús + arrastrar: mover", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function() if IsShiftKeyDown() then filaBuffs:StartMoving() end end)
    b:SetScript("OnDragStop", function() filaBuffs:GetScript("OnDragStop")(filaBuffs) end)
    iconosBuff[n] = b
    return b
end

local function ActualizarBuffs()
    local ahora = GetTime()
    local lista = {}
    for clave, fin in pairs(buffs) do
        if fin <= ahora then
            buffs[clave] = nil
        elseif POR_CLAVE[clave] then
            lista[#lista + 1] = clave
        end
    end
    table.sort(lista)
    for n, clave in ipairs(lista) do
        local b = iconosBuff[n] or CrearIconoBuff(n)
        local d = POR_CLAVE[clave]
        b.datos = d
        b.tex:SetTexture(d.buffIcono or d.icono)
        b.tiempo:SetText(TextoTiempo(math.max(0, math.floor(buffs[clave] - ahora))))
        b:ClearAllPoints()
        b:SetPoint("TOPRIGHT", filaBuffs, "TOPRIGHT", -(n - 1) * (TAM_BUFF + 4), 0)
        b:Show()
    end
    for n = #lista + 1, #iconosBuff do iconosBuff[n]:Hide() end
    if #lista > 0 then filaBuffs:Show() else filaBuffs:Hide() end
end

local acumBuffs = 0
filaBuffs:SetScript("OnUpdate", function(self, elapsed)
    acumBuffs = acumBuffs + elapsed
    if acumBuffs < 0.5 then return end
    acumBuffs = 0
    ActualizarBuffs()
end)

local function ParsearBuffs(msg)
    if msg == "CAMPBUFF#NONE" then return {} end
    local resto = msg:match("^CAMPBUFF#(.*)$")
    if not resto then return nil end
    local t = {}
    for clave, seg in resto:gmatch("([^:;]+):(%d+)") do t[clave] = tonumber(seg) end
    return t
end

----------------------------------------------------------------------
-- Mensajes del servidor
----------------------------------------------------------------------
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg)
    if msg and (msg:find("^CAMPDATA#") or msg:find("^CAMPPOOL#") or msg:find("^CAMPBUFF#") or msg:find("^CAMPCOCINA#")) then return true end
    return false
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("CHAT_MSG_SYSTEM")
ev:SetScript("OnEvent", function(self, event, msg)
    if not msg then return end

    if msg:find("^CAMPPOOL#") then
        if eco then Aviso("recibido: " .. msg) end
        local modo, disp = ParsearPool(msg)
        if modo and estado and not estado.demo then
            estado.modo = modo
            estado.disp = disp
            Actualizar()
        end
        return
    end

    if msg:find("^CAMPCOCINA#") then
        if eco then Aviso("recibido: " .. msg) end
        local v, h, r, s, sh = msg:match("^CAMPCOCINA#(%d+)#(%d+)#(%d+)#(%d+)#(%d+)$")
        if v then
            cocina = { valor = tonumber(v), huecos = tonumber(h), rango = tonumber(r), siguiente = tonumber(s), sigHuecos = tonumber(sh) }
            ActualizarCocina()
        end
        return
    end

    if msg:find("^CAMPBUFF#") then
        if eco then Aviso("recibido: " .. msg) end
        local t = ParsearBuffs(msg)
        if t then
            local ahora = GetTime()
            buffs = {}
            for clave, seg in pairs(t) do buffs[clave] = ahora + seg end
            ActualizarBuffs()
        end
        return
    end

    if not msg:find("^CAMPDATA#") then return end
    if eco then Aviso("recibido: " .. msg) end

    local e, ok = ParsearMensaje(msg)
    if not ok then
        if eco then Aviso("mensaje con formato no válido") end
        return
    end

    if e then
        if not estado or estado.demo then cerrado = false end
        if estado and not estado.demo then
            e.modo = estado.modo
            e.disp = estado.disp
        end
        estado = e
        Actualizar()
        if not cerrado then f:Show() end
    else
        estado = nil
        cerrado = false
        if manual then Actualizar() else f:Hide() end
    end
end)

----------------------------------------------------------------------
-- Comandos
----------------------------------------------------------------------
SLASH_CAMPAMENTO1 = "/campamento"
SLASH_CAMPAMENTO2 = "/camppanel"
SlashCmdList["CAMPAMENTO"] = function(arg)
    arg = (arg or ""):lower():match("^%s*(%S*)") or ""

    if arg == "test" then
        estado = {
            dueno = UnitName("player"), expira = GetTime() + 300, maxHuecos = 4, demo = true, modo = "L",
            disp = { alquimia = "Compañero", herboristeria = UnitName("player") },
            slots = { { clave = "herreria", jugador = UnitName("player") }, { clave = "sastreria", jugador = "Compañero" } },
            activos = { herreria = UnitName("player"), sastreria = "Compañero" },
        }
        Abrir()
        Aviso("Campamento de prueba (solo visual). Cierra el panel para quitarlo.")
    elseif arg == "buffs" then
        local n = 0
        for _, d in ipairs(PROFESIONES) do
            if d.buffIcono then
                buffs[d.clave] = GetTime() + 3600
                n = n + 1
                Aviso(d.clave .. " -> " .. d.buffIcono)
            end
        end
        ActualizarBuffs()
        Aviso(n .. " buffs de prueba durante 1 h (los que tienen icono propio). Mayús + arrastrar mueve la fila.")
    elseif arg == "debug" then
        eco = not eco
        Aviso("Eco de mensajes del servidor: " .. (eco and "activado" or "desactivado"))
    elseif arg == "minimapa" then
        CampamentoDB = CampamentoDB or {}
        CampamentoDB.oculto = not CampamentoDB.oculto
        if CampamentoDB.oculto then mb:Hide() else mb:Show() end
        Aviso("Botón del minimapa " .. (CampamentoDB.oculto and "oculto" or "visible"))
    else
        Alternar()
    end
end
