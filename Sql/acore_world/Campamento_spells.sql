-- Campamento: hechizos propios (servidor). Ejecutar en la base de datos del MUNDO (acore_world).
-- Después hay que REINICIAR el worldserver para que los cargue.
-- Si algún nombre de columna da error, mira DESCRIBE spell_dbc; y ajusta el nombre.
-- Si el ID ya lo usas para otra cosa, cámbialo aquí y en Camp_herreria.lua (SPELL_ID).

-- 900001 (Silla de campamento, desuello) ya no se usa: se borra por limpieza.
DELETE FROM spell_dbc WHERE ID IN (900001, 900002, 900003, 900004, 900005, 900006, 900007, 900008, 900009, 900010, 900011, 900012, 900013, 900014, 900015, 900016);

-- 900002: Herrería -> +3% de fuerza y +3% de agilidad (aura 137 = MOD_TOTAL_STAT_PERCENTAGE)
--   EffectBasePoints = porcentaje - 1  (2 = +3%)   |   EffectMiscValue: 0 = fuerza, 1 = agilidad
--   DurationIndex 21 = infinita (la quita el módulo cuando caduca el buff del campamento)
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1,
    Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900002, 1, 21, 1, -1, 1,
    6, 2, 1, 137, 0,
    6, 2, 1, 137, 1,
    'Acero templado', 'Aumenta un 3% la fuerza y la agilidad.');

-- 900003: Encantamiento -> estadísticas %, armadura % y resistencias (planas).
--   Los valores reales los pone Camp_encantamiento.lua al lanzarlo (según el nivel); los de aquí son
--   solo el valor por defecto si ese método no funcionara.
--   Efecto 1: aura 137, misc -1  = todas las estadísticas (%)
--   Efecto 2: aura 101, misc 1   = armadura (%)
--   Efecto 3: aura 22,  misc 126 = resistencia plana a fuego, naturaleza, escarcha, sombras, arcano y sagrado
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1,
    Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2,
    Effect_3, EffectBasePoints_3, ImplicitTargetA_3, EffectAura_3, EffectMiscValue_3,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900003, 1, 21, 1, -1, 1,
    6, 2, 1, 137, -1,
    6, 5, 1, 101, 1,
    6, 20, 1, 22, 126,
    'Laud encantado', 'Aumenta las estadisticas, la armadura y las resistencias.');

-- 900004..900008: Herboristería -> +10 a todas las profesiones (aura 30 = MOD_SKILL, misc = ID de la habilidad).
--   Hacen falta 5 hechizos porque cada uno solo tiene 3 efectos. Camp_herboristeria.lua los lanza juntos.
--   171 alquimia, 164 herrería, 333 encantamiento, 202 ingeniería, 182 herboristería, 773 inscripción,
--   755 joyería, 165 peletería, 186 minería, 393 desuello, 197 sastrería, 185 cocina, 356 pesca, 129 primeros auxilios
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask, Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1, Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2, Effect_3, EffectBasePoints_3, ImplicitTargetA_3, EffectAura_3, EffectMiscValue_3, Name_Lang_enUS, Description_Lang_enUS)
VALUES (900004, 1, 21, 1, -1, 1, 6, 10, 1, 30, 171, 6, 10, 1, 30, 164, 6, 10, 1, 30, 333, 'Cosecha diestra', 'Aumenta tus habilidades de profesion.');
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask, Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1, Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2, Effect_3, EffectBasePoints_3, ImplicitTargetA_3, EffectAura_3, EffectMiscValue_3, Name_Lang_enUS, Description_Lang_enUS)
VALUES (900005, 1, 21, 1, -1, 1, 6, 10, 1, 30, 202, 6, 10, 1, 30, 182, 6, 10, 1, 30, 773, 'Cosecha diestra', 'Aumenta tus habilidades de profesion.');
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask, Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1, Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2, Effect_3, EffectBasePoints_3, ImplicitTargetA_3, EffectAura_3, EffectMiscValue_3, Name_Lang_enUS, Description_Lang_enUS)
VALUES (900006, 1, 21, 1, -1, 1, 6, 10, 1, 30, 755, 6, 10, 1, 30, 165, 6, 10, 1, 30, 186, 'Cosecha diestra', 'Aumenta tus habilidades de profesion.');
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask, Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1, Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2, Effect_3, EffectBasePoints_3, ImplicitTargetA_3, EffectAura_3, EffectMiscValue_3, Name_Lang_enUS, Description_Lang_enUS)
VALUES (900007, 1, 21, 1, -1, 1, 6, 10, 1, 30, 393, 6, 10, 1, 30, 197, 6, 10, 1, 30, 185, 'Cosecha diestra', 'Aumenta tus habilidades de profesion.');
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask, Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1, Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2, Effect_3, EffectBasePoints_3, ImplicitTargetA_3, EffectAura_3, EffectMiscValue_3, Name_Lang_enUS, Description_Lang_enUS)
VALUES (900008, 1, 21, 1, -1, 1, 6, 10, 1, 30, 356, 6, 10, 1, 30, 129, 0, 0, 0, 0, 0, 'Cosecha diestra', 'Aumenta tus habilidades de profesion.');

-- 900009: Minería -> +5% de poder de ataque cuerpo a cuerpo y a distancia
--   aura 166 = MOD_ATTACK_POWER_PCT (cuerpo a cuerpo), aura 167 = MOD_RANGED_ATTACK_POWER_PCT (distancia)
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1,
    Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900009, 1, 21, 1, -1, 1,
    6, 5, 1, 166, 0,
    6, 5, 1, 167, 0,
    'Veta de poder', 'Aumenta el poder de ataque.');

-- 900010: Desuello -> +2% de probabilidad de golpe crítico (cuerpo a cuerpo, distancia y hechizos)
--   aura 52 = MOD_CRIT_PERCENT (físico), aura 57 = MOD_SPELL_CRIT_CHANCE (hechizos y curaciones)
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1,
    Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900010, 1, 21, 1, -1, 1,
    6, 2, 1, 52, 0,
    6, 2, 1, 57, 127,
    'Instinto del desollador', 'Aumenta la probabilidad de golpe critico.');

-- 900011: Sastrería -> +2% de espíritu, +5% de daño de hechizos y +5% de sanación
--   Efecto 1: aura 137, misc 4   = espíritu (%)
--   Efecto 2: aura 79,  misc 126 = daño hecho (%) de todas las escuelas mágicas (no físico)
--   Efecto 3: aura 136, misc 0   = sanación hecha (%)
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1,
    Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2,
    Effect_3, EffectBasePoints_3, ImplicitTargetA_3, EffectAura_3, EffectMiscValue_3,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900011, 1, 21, 1, -1, 1,
    6, 2, 1, 137, 4,
    6, 5, 1, 79, 126,
    6, 5, 1, 136, 0,
    'Estandarte de faccion', 'Aumenta el espiritu, el dano de hechizos y la sanacion.');

-- 900012: Joyería -> velocidad de movimiento: +15% a pie, +20% montado (+10% si es paladín con Aura de cruzado)
--   Efecto 1: aura 31  = MOD_INCREASE_SPEED         (a pie; no se acumula con otros bonus de velocidad: gana el mayor)
--   Efecto 2: aura 130 = MOD_MOUNTED_SPEED_ALWAYS   (montado; SE ACUMULA con la montura y con el Aura de cruzado)
--   Efecto 3: aura 209 = MOD_MOUNTED_FLIGHT_SPEED_ALWAYS (montado volando; igual que el anterior)
--   Los valores reales los pone Camp_joyeria.lua al lanzarlo; estos son los de por defecto.
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1,
    Effect_2, EffectBasePoints_2, ImplicitTargetA_2, EffectAura_2, EffectMiscValue_2,
    Effect_3, EffectBasePoints_3, ImplicitTargetA_3, EffectAura_3, EffectMiscValue_3,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900012, 1, 21, 1, -1, 1,
    6, 15, 1, 31, 0,
    6, 20, 1, 130, 0,
    6, 20, 1, 209, 0,
    'Pies ligeros', 'Aumenta la velocidad de movimiento.');

-- 900013: Primeros auxilios -> +5% de vida máxima (aura 133 = MOD_INCREASE_HEALTH_PERCENT)
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900013, 1, 21, 1, -1, 1,
    6, 5, 1, 133, 0,
    'Botiquin de campana', 'Aumenta la vida maxima.');

-- 900014 y 900015: daño periódico (aura 3 = PERIODIC_DAMAGE) que el módulo aplica al enemigo con el proc.
--   900014 Hemorragia (físico, sangrado)   |   900015 Fuego lunar (arcano)
--   Duración 10 s (DurationIndex 1), un tick cada 3 s (EffectAuraPeriod = 3000), objetivo = enemigo (ImplicitTargetA 6).
--   El daño por tick lo fija Camp_primerosauxilios.lua al lanzarlo; el 1 de aquí es solo el valor por defecto.
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectAuraPeriod_1, EffectMiscValue_1,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900014, 1, 1, 6, -1, 1,
    6, 1, 6, 3, 3000, 0,
    'Hemorragia', 'Causa dano de sangrado con el tiempo.');

INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectAuraPeriod_1, EffectMiscValue_1,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900015, 1, 1, 6, -1, 64,
    6, 1, 6, 3, 3000, 0,
    'Fuego lunar', 'Causa dano arcano con el tiempo.');

-- 900016: Pesca -> +5% a todas las estadísticas (aura 137 = MOD_TOTAL_STAT_PERCENTAGE, misc -1 = todas)
INSERT INTO spell_dbc (ID, CastingTimeIndex, DurationIndex, RangeIndex, EquippedItemClass, SchoolMask,
    Effect_1, EffectBasePoints_1, ImplicitTargetA_1, EffectAura_1, EffectMiscValue_1,
    Name_Lang_enUS, Description_Lang_enUS)
VALUES (900016, 1, 21, 1, -1, 1,
    6, 5, 1, 137, -1,
    'Banquete del pescador', 'Aumenta todas las estadisticas.');

-- Comprobación:
-- SELECT ID, EffectAura_1, EffectMiscValue_1, EffectAura_2, EffectMiscValue_2, DurationIndex, Name_Lang_enUS FROM spell_dbc WHERE ID IN (900002, 900003, 900004, 900005, 900006, 900007, 900008, 900009, 900010, 900011, 900012, 900013, 900014, 900015, 900016);
