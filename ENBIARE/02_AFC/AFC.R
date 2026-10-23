# =============================================================================
# Libro SEM · ENBIARE
# 02 - Análisis Factorial Confirmatorio (AFC)
# =============================================================================
# Sin referencia: la estructura sale del AFE (01_AFE) y del contenido de los ítems.
# Dos modelos de primer orden: satisfacción con 17 aspectos (5 factores, principal) y
# confianza en 11 personas e instituciones (5 factores, segunda).
#   source("ENBIARE/02_AFC/AFC.R")
# =============================================================================

library(psych)
library(GPArotation)
library(lavaan)
library(semPlot)

dir_salida <- "ENBIARE/02_AFC/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelos
# -----------------------------------------------------------------------
enb <- read.csv("ENBIARE/data/conjunto_de_datos_tenbiare_enbiare_2021.csv",
                fileEncoding = "latin1", na.strings = c("", " "), quote = "\"",
                comment.char = "", stringsAsFactors = FALSE)
names(enb) <- tolower(names(enb))

# "=~" se lee "se mide por"; lavaan fija en 1 la carga del primer ítem de cada factor.
m_sat <- '
  NIV =~ pa3_01 + pa3_02 + pa3_03 + pa3_08   # nivel de vida, salud, logros, perspectivas
  REL =~ pa3_04 + pa3_05 + pa3_06 + pa3_07   # relaciones personales, vida social, familiar y afectiva
  AUT =~ pa3_09 + pa3_10 + pa3_12            # tiempo libre, libertad para decidir, actividad principal
  BAR =~ pa3_13 + pa3_14                     # vivienda y vecindario
  CIU =~ pa3_11 + pa3_15 + pa3_16 + pa3_17   # seguridad, ciudad, servicios públicos y país'
m_conf <- '
  INT =~ pb1_01 + pb1_02                     # la mayoría de la gente y la que conoce
  POL =~ pb1_04 + pb1_05                     # policía municipal y estatal
  MIL =~ pb1_06 + pb1_07                     # Guardia Nacional y Ejército y Marina
  JUS =~ pb1_08 + pb1_09                     # ministerio público y juzgados
  PLT =~ pb1_10 + pb1_11 + pb1_12            # cámaras, partidos y funcionarios'
modelos <- list(SAT = m_sat, CONF = m_conf)    # pb1_03 (medios) queda fuera, ver 01_AFE

medidas <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- function(fit, nombre) {
  m <- round(as.numeric(fitMeasures(fit, medidas)), 3)
  data.frame(modelo = nombre, N = lavInspect(fit, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}

# -----------------------------------------------------------------------
# Paso 2. AFC de cada escala con MLR
# -----------------------------------------------------------------------
# MLR da errores estándar y χ² robustos a la no normalidad: las escalas 0-10 tienen
# asimetría hasta -2.5 y son de 11 categorías. No hay faltantes: no hace falta FIML.
fits <- lapply(modelos, function(m) cfa(m, data = enb, estimator = "MLR"))
sapply(fits, lavInspect, "converged")        # TRUE, TRUE
sapply(fits, function(f) suppressWarnings(lavInspect(f, "post.check")))   # TRUE: sin varianzas negativas
summary(fits$SAT, fit.measures = TRUE, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 3. Bondad de ajuste (Hu y Bentler, 1999)
# -----------------------------------------------------------------------
# CFI y TLI >= .95 (aceptable >= .90), RMSEA <= .06 (aceptable <= .08), SRMR <= .08.
# Con 31 mil casos la χ² siempre rechaza: se leen los índices.
tabla_ajuste <- do.call(rbind, lapply(names(fits), function(nm) ajuste(fits[[nm]], nm)))
tabla_ajuste
# SAT: CFI .952, TLI .941, RMSEA .047, SRMR .032 (χ² = 4,419, 109 gl). Buen ajuste.
# CONF: CFI .968, TLI .949, RMSEA .088, SRMR .027 (χ² = 5,468, 34 gl). CFI y SRMR buenos;
# el RMSEA sale alto porque tiene pocos gl (34): con modelos chicos el RMSEA se infla.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas y correlaciones entre factores
# -----------------------------------------------------------------------
sol <- do.call(rbind, lapply(names(fits), function(nm) {
  s <- standardizedSolution(fits[[nm]])
  s <- s[s$op == "=~" | (s$op == "~~" & s$lhs != s$rhs), ]   # cargas y correlaciones
  data.frame(escala = nm, s[, c("lhs", "op", "rhs", "est.std", "se", "pvalue")])
}))
sol$est.std <- round(sol$est.std, 3)
sol[sol$op == "=~", ]                        # SAT .55-.76; CONF .68-.96; todas significativas
sol[sol$op == "~~", ]                        # SAT: de .44 (REL-CIU) a .82 (NIV-REL); CONF: de .35 a .83 (JUS-PLT)
write.csv(sol, file.path(dir_salida, "solucion_estandarizada_AFC.csv"), row.names = FALSE)

# Índices de modificación (los más grandes) de cada modelo
for (nm in names(fits)) {
  cat("\n", nm, "\n")
  mi <- modindices(fits[[nm]], sort. = TRUE, maximum.number = 6)
  print(mi[, c("lhs", "op", "rhs", "mi", "epc")], row.names = FALSE)
}
# SAT: lo mayor es que la vivienda y el vecindario (BAR) carguen también en nivel de vida
# (MI 1,119) y en ciudad (784), y que pa3_14 covarie con pa3_15 (840) y pa3_03 con pa3_04 (825).
# CONF: lo mayor es que pb1_10 (cámaras) cargue también en justicia (MI 4,558), como ya
# mostraba el AFE (.38), y que pb1_11 y pb1_12 covarien (3,673). Con 31 mil casos todos los MI
# son grandes; no se agrega ninguno al modelo principal (estructura simple). Ver el paso 5b.

# -----------------------------------------------------------------------
# Paso 5. ¿Mejor que modelos más simples?
# -----------------------------------------------------------------------
# Cada modelo simple es un caso anidado del de cinco factores (fusionar factores = que
# su correlación sea 1), así que se compara con la χ² escalada (Satorra-Bentler) y con el BIC.
items_sat  <- sprintf("pa3_%02d", c(1:17))
items_conf <- sprintf("pb1_%02d", c(1, 2, 4:12))
simples <- list(
  "SAT 1 factor"  = paste("SAT =~", paste(items_sat, collapse = " + ")),
  "SAT 4 factores (BAR y CIU juntos)" = '
    NIV =~ pa3_01 + pa3_02 + pa3_03 + pa3_08
    REL =~ pa3_04 + pa3_05 + pa3_06 + pa3_07
    AUT =~ pa3_09 + pa3_10 + pa3_12
    ENT =~ pa3_11 + pa3_13 + pa3_14 + pa3_15 + pa3_16 + pa3_17',
  "CONF 1 factor" = paste("CONF =~", paste(items_conf, collapse = " + ")),
  "CONF 2 factores (personas | instituciones)" = '
    PER =~ pb1_01 + pb1_02
    INS =~ pb1_04 + pb1_05 + pb1_06 + pb1_07 + pb1_08 + pb1_09 + pb1_10 + pb1_11 + pb1_12',
  "CONF 4 factores (JUS y PLT juntos)" = '
    INT =~ pb1_01 + pb1_02
    POL =~ pb1_04 + pb1_05
    MIL =~ pb1_06 + pb1_07
    JUP =~ pb1_08 + pb1_09 + pb1_10 + pb1_11 + pb1_12')
fits_simples <- lapply(simples, function(m) cfa(m, data = enb, estimator = "MLR"))
comparacion <- do.call(rbind, c(
  lapply(names(fits_simples), function(nm) cbind(ajuste(fits_simples[[nm]], nm), BIC = round(BIC(fits_simples[[nm]])))),
  lapply(names(fits), function(nm) cbind(ajuste(fits[[nm]], paste(nm, "5 factores")), BIC = round(BIC(fits[[nm]]))))))
comparacion
# SAT: 1 factor CFI .786 y 4 factores .926 contra .952 de 5; el BIC más bajo es el de 5 factores.
# CONF: 1 factor .772, 2 factores .809 y 4 factores .929 contra .968 de 5; el BIC más bajo es el de 5.
lavTestLRT(fits$SAT, fits_simples[["SAT 4 factores (BAR y CIU juntos)"]])     # Δχ² escalada 2,181 (4 gl), p < .001
lavTestLRT(fits$CONF, fits_simples[["CONF 4 factores (JUS y PLT juntos)"]])   # Δχ² escalada 4,622 (4 gl), p < .001
write.csv(comparacion, file.path(dir_salida, "comparacion_modelos.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5b. Confianza: ¿y si pb1_10 carga en justicia y en política?
# -----------------------------------------------------------------------
# El AFE ya mostraba que pb1_10 (cámaras de diputados y senadores) carga .51 en política y
# .38 en justicia, y es el mayor índice de modificación (4,558). Se prueba una carga cruzada
# y, aparte, una covarianza residual entre pb1_11 y pb1_12 (partidos y funcionarios).
alternativas <- list(
  "CONF base (estructura simple)" = m_conf,
  "CONF + pb1_10 también en JUS"  = sub("JUS =~ pb1_08 \\+ pb1_09", "JUS =~ pb1_08 + pb1_09 + pb1_10", m_conf),
  "CONF + residual pb1_11 ~~ pb1_12" = paste(m_conf, "\n pb1_11 ~~ pb1_12"))
alt_fits <- lapply(alternativas, function(m) cfa(m, data = enb, estimator = "MLR"))
alt_tabla <- do.call(rbind, lapply(names(alt_fits), function(nm) ajuste(alt_fits[[nm]], nm)))
alt_tabla
# La carga cruzada sube el CFI a .985 y baja el RMSEA a .062; el residual, .982 y .067. Es una
# modificación sensata (cámaras legisla y también procura justicia), pero se deja el modelo de
# estructura simple como el principal y se reporta esta variante como sensibilidad.
write.csv(alt_tabla, file.path(dir_salida, "confianza_variantes.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 6. Sensibilidad: estimador y diseño muestral
# -----------------------------------------------------------------------
# (a) Ordinal (WLSMV): los 11 puntos como categorías en vez de continuos.
# (b) Conglomerado: cluster = UPM (4,704 UPM de 6.6 personas, ICC mediana .025).
# (c) Ponderador: sampling.weights = fac_ele (de 122 a 45,955; efecto de Kish 2.23).
# Se compara el ajuste, el error estándar medio de las cargas y cuánto cambian las cargas.
ep <- function(f) { p <- parameterEstimates(f); p$se[p$op == "=~" & p$se > 0] }
cs <- function(f) standardizedSolution(f)$est.std[standardizedSolution(f)$op == "=~"]
sensibilidad <- do.call(rbind, lapply(names(modelos), function(nm) {
  items <- if (nm == "SAT") items_sat else items_conf
  d_ord <- enb; d_ord[items] <- lapply(d_ord[items], ordered)
  f_ord <- cfa(modelos[[nm]], d_ord, ordered = items, estimator = "WLSMV")
  f_upm <- cfa(modelos[[nm]], enb, estimator = "MLR", cluster = "upm_dis")
  f_pes <- cfa(modelos[[nm]], enb, estimator = "MLR", sampling.weights = "fac_ele")
  base <- fits[[nm]]
  data.frame(escala = nm,
    variante = c("MLR (base)", "WLSMV (ordinal)", "MLR con cluster UPM", "MLR ponderado"),
    CFI = round(c(fitMeasures(base, "cfi.robust"), fitMeasures(f_ord, "cfi.scaled"),
                  fitMeasures(f_upm, "cfi.robust"), fitMeasures(f_pes, "cfi.robust")), 3),
    RMSEA = round(c(fitMeasures(base, "rmsea.robust"), fitMeasures(f_ord, "rmsea.scaled"),
                    fitMeasures(f_upm, "rmsea.robust"), fitMeasures(f_pes, "rmsea.robust")), 3),
    carga_media = round(c(mean(cs(base)), mean(cs(f_ord)), mean(cs(f_upm)), mean(cs(f_pes))), 3),
    dif_max_cargas = round(c(0, max(abs(cs(f_ord) - cs(base))), max(abs(cs(f_upm) - cs(base))),
                             max(abs(cs(f_pes) - cs(base)))), 3),
    razon_EE = round(c(1, NA, mean(ep(f_upm) / ep(base)), mean(ep(f_pes) / ep(base))), 2))
}))
sensibilidad
# El conglomerado no cambia nada (EE x1.01 y x1.02; cargas idénticas). Ponderar sube los EE x1.45
# y x1.51 y mueve las cargas hasta .014 (SAT) y .052 (CONF); el CFI casi no cambia. WLSMV mejora
# el ajuste (SAT .966, CONF .980) y sube las cargas (SAT: media .65 -> .71; hasta .12 en un ítem):
# las policóricas corrigen el techo de las respuestas; mismos factores. El RMSEA de WLSMV es más
# alto en CONF (.140), pero con esa escala de 11 puntos y pocos gl el RMSEA no es de fiar.
# Se trabaja con MLR sin ponderador (como EMOVI).
write.csv(sensibilidad, file.path(dir_salida, "sensibilidad_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 7. Validación cruzada: AFE en una mitad y AFC en la otra
# -----------------------------------------------------------------------
# El AFE (01) y este AFC usan las mismas 31,166 personas. Con tantos casos se puede
# partir la muestra: se explora la estructura en la mitad A, se comprueba que los ítems
# se agrupen igual que en el modelo, y se confirma el modelo en la mitad B.
set.seed(2021)
mitad <- sample(c("A", "B"), nrow(enb), replace = TRUE)
table(mitad)                                 # 15,513 y 15,653
valida <- function(nm, items, k) {
  modelo <- modelos[[nm]]
  asignado <- apply(abs(unclass(suppressWarnings(fa(cor(enb[mitad == "A", items]), nfactors = k, fm = "ml",
                      rotate = "oblimin"))$loadings)), 1, which.max)
  # factor del modelo al que pertenece cada ítem
  lineas <- grep("=~", strsplit(modelo, "\n")[[1]], value = TRUE)
  en_modelo <- unlist(lapply(seq_along(lineas), function(i)
    setNames(rep(i, length(regmatches(lineas[i], gregexpr("p[ab][0-9]_[0-9]+", lineas[i]))[[1]])),
             regmatches(lineas[i], gregexpr("p[ab][0-9]_[0-9]+", lineas[i]))[[1]])))
  igual <- all(tapply(asignado[names(en_modelo)], en_modelo, function(x) length(unique(x))) == 1) &&
    length(unique(tapply(asignado[names(en_modelo)], en_modelo, unique))) == k
  fb <- cfa(modelo, enb[mitad == "B", ], estimator = "MLR")
  rbind(cbind(ajuste(fb, paste(nm, "AFC en la mitad B")), AFE_A_igual_al_modelo = igual),
        cbind(ajuste(cfa(modelo, enb[mitad == "A", ], estimator = "MLR"), paste(nm, "AFC en la mitad A")),
              AFE_A_igual_al_modelo = igual))
}
validacion <- rbind(valida("SAT", items_sat, 5), valida("CONF", items_conf, 5))
validacion
# El AFE de la mitad A agrupa los ítems exactamente como el modelo en las dos escalas, y el AFC
# en la mitad B da el mismo ajuste que con todos (SAT CFI .95; CONF .97): la estructura se confirma
# en datos que no la generaron.
write.csv(validacion, file.path(dir_salida, "validacion_cruzada.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 8. Diagramas
# -----------------------------------------------------------------------
for (nm in names(fits)) {
  png(file.path(dir_salida, paste0("diagrama_AFC_", nm, ".png")), width = 1400, height = 700)
  semPaths(fits[[nm]], whatLabels = "std", edge.label.cex = 0.9, layout = "tree2")
  dev.off()
}
