# =============================================================================
# Libro SEM · ENCO
# 02 - Análisis Factorial Confirmatorio (AFC) de primer orden
# =============================================================================
# Sin referencia: el documento de INEGI no trae un modelo. Se confirma la
# estructura de cuatro factores que salió del AFE (01), con los 2,050 casos de
# agosto de 2026. Incluye la prueba de sensibilidad al ponderador que respalda la
# decisión de no ponderar.
#   source("ENCO/02_AFC/AFC.R")
# =============================================================================

library(foreign)
library(lavaan)

dir_salida <- "ENCO/02_AFC/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos (igual que en el AFE): 15 ítems, "No sabe" a faltante, mayor = más confianza
# -----------------------------------------------------------------------
cb <- read.dbf("ENCO/data/encocb_0826.DBF", as.is = TRUE)
items <- paste0("P", 1:15)
codigo_NS <- c(P1 = 6, P2 = 6, P3 = 6, P4 = 6, P5 = 6, P6 = 6, P7 = 4, P8 = 4, P9 = 3, P10 = 3,
               P11 = 6, P12 = 7, P13 = 6, P14 = 4, P15 = 4)
maximo    <- c(P1 = 5, P2 = 5, P3 = 5, P4 = 5, P5 = 5, P6 = 5, P7 = 3, P8 = 3, P9 = 2, P10 = 2,
               P11 = 5, P12 = 6, P13 = 5, P14 = 3, P15 = 3)
x <- cb[, items]
x[] <- lapply(x, as.integer)
for (v in items) x[[v]][x[[v]] == codigo_NS[[v]]] <- NA
x$P10[cb$P10 == "4"] <- NA
for (v in items) x[[v]] <- maximo[[v]] + 1L - x[[v]]

# -----------------------------------------------------------------------
# Paso 2. El modelo: cada ítem en el factor donde más carga en el AFE
# -----------------------------------------------------------------------
# HOGA = situación del hogar hoy        HOGE = situación del hogar dentro de 12 meses
# PAIS = economía del país              CONS = consumo, ahorro y planes de compra
# P11 (condiciones para ahorrar) carga en tres factores en el AFE (.41, .24 y .21);
# se deja en CONS, donde más carga y donde tiene más sentido (decisión del proyecto).
modelo <- '
  HOGA =~ P1 + P3
  HOGE =~ P2 + P4
  PAIS =~ P5 + P6 + P12 + P13
  CONS =~ P7 + P8 + P9 + P10 + P11 + P14 + P15'

# -----------------------------------------------------------------------
# Paso 3. Estimar: ítems ordinales (WLSMV)
# -----------------------------------------------------------------------
# missing = "pairwise" usa las parejas de respuestas disponibles: no se pierden las
# 115 personas con algún "No sabe". lavaan no tiene FIML con ítems ordinales; ver 07_FIML.
fit <- cfa(modelo, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit, "converged")                 # TRUE
lavInspect(fit, "nobs")                      # 2,050

medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
ajuste(fit, "4 factores (pairwise)")         # χ²(84) = 960, CFI .975, TLI .969, RMSEA .071, SRMR .048

# Alternativas: solo los 1,935 completos (listwise), sin P11, 5 factores (P14 y P15
# aparte) y un solo factor con los 15 ítems.
fit_lw <- cfa(modelo, data = x, ordered = items, estimator = "WLSMV")
fit_sin11 <- cfa(sub(" \\+ P11", "", modelo), data = x, ordered = setdiff(items, "P11"),
                 estimator = "WLSMV", missing = "pairwise")
modelo5 <- '
  HOGA =~ P1 + P3
  HOGE =~ P2 + P4
  PAIS =~ P5 + P6 + P12 + P13
  CONS =~ P7 + P8 + P9 + P10 + P11
  PLAN =~ P14 + P15'
fit5 <- cfa(modelo5, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")
fit1 <- cfa(paste("G =~", paste(items, collapse = " + ")), data = x, ordered = items,
            estimator = "WLSMV", missing = "pairwise")
tabla_ajuste <- rbind(ajuste(fit, "4 factores (pairwise)"), ajuste(fit_lw, "4 factores (listwise)"),
                      ajuste(fit_sin11, "4 factores sin P11"), ajuste(fit5, "5 factores (PLAN aparte)"),
                      ajuste(fit1, "1 factor con los 15 ítems"))
tabla_ajuste
# Listwise (1,935) da lo mismo: CFI .974, RMSEA .073. Sin P11 el ajuste mejora (CFI .981, RMSEA
# .065), pero P11 se deja (decisión del proyecto). Con 5 factores: CFI .979, RMSEA .067 (poco
# más). Un solo factor ajusta peor (CFI .889, RMSEA .146): la estructura de cuatro dimensiones
# es real. El RMSEA de .071 es el punto flojo del modelo.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas y correlaciones entre factores
# -----------------------------------------------------------------------
s <- standardizedSolution(fit)
cargas <- s[s$op == "=~", c("lhs", "rhs", "est.std", "se")]
cargas[, c("est.std", "se")] <- round(cargas[, c("est.std", "se")], 3)
names(cargas) <- c("factor", "item", "carga", "ee")
cargas
range(cargas$carga)                          # de .48 (P12) a .91 (P1); sin varianzas negativas
round(lavInspect(fit, "cor.lv"), 2)          # HOGA-CONS .79 es la mayor; PAIS con los demás, de .54 a .62
write.csv(cargas, file.path(dir_salida, "cargas_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Índices de modificación (solo para ver, no se modifica el modelo)
# -----------------------------------------------------------------------
mi <- modindices(fit, sort. = TRUE, maximum.number = 8)
mi[, c("lhs", "op", "rhs", "mi")]
# Los mayores: P11 cargaría también en HOGE (123) y en PAIS (99), y los residuales P14-P15 (103),
# P5-P6 (69) y P9-P10 (68): parejas de preguntas muy parecidas. No se agregan: el ajuste ya es
# bueno y el modelo quedaría a la medida de estos datos.

# -----------------------------------------------------------------------
# Paso 6. Sensibilidad al diseño muestral: ¿importa ponderar? (decisión del proyecto: no)
# -----------------------------------------------------------------------
# FACTOR es el factor de expansión (población de 18+). Se estima el MISMO modelo
# ordinal con y sin ponderador y se compara. lavaan aplica sampling.weights con
# WLSMV, pero con ítems categóricos no admite `cluster` (categorical + clustered is
# not supported yet), así que la UPM no se puede tomar en cuenta aquí.
w <- as.numeric(cb$FACTOR)
c(min = min(w), max = max(w), razon = round(max(w) / min(w), 1))     # 18 a 1
round(length(w) * sum(w^2) / sum(w)^2, 2)    # efecto de diseño por pesos (Kish)
x_w <- cbind(x, w = w)
fit_w <- cfa(modelo, data = x_w, ordered = items, estimator = "WLSMV", missing = "pairwise",
             sampling.weights = "w")
sw <- standardizedSolution(fit_w)
libres <- parameterEstimates(fit)$op == "=~" & parameterEstimates(fit)$se > 0     # sin las cargas marcadoras
comparacion <- data.frame(
  indicador = c("CFI", "RMSEA", "máx. diferencia en cargas estandarizadas",
                "máx. diferencia en correlaciones entre factores",
                "razón de errores estándar de las cargas (con / sin ponderador, promedio)"),
  sin_ponderador = c(round(fitMeasures(fit, "cfi.scaled"), 3), round(fitMeasures(fit, "rmsea.scaled"), 3), NA, NA, NA),
  con_ponderador = c(round(fitMeasures(fit_w, "cfi.scaled"), 3), round(fitMeasures(fit_w, "rmsea.scaled"), 3),
                     round(max(abs(s$est.std[s$op == "=~"] - sw$est.std[sw$op == "=~"])), 3),
                     round(max(abs(lavInspect(fit, "cor.lv") - lavInspect(fit_w, "cor.lv"))), 3),
                     round(mean(parameterEstimates(fit_w)$se[libres] / parameterEstimates(fit)$se[libres]), 2)))
comparacion
# Mismo ajuste, mismas cargas (hasta .02) y mismas correlaciones entre factores (hasta
# .03): no se pondera. El ponderador sirve para estimaciones DESCRIPTIVAS de la población
# (ver 05, medias de los puntajes), no para estimar las relaciones entre ítems.
write.csv(comparacion, file.path(dir_salida, "sensibilidad_ponderador.csv"), row.names = FALSE)
