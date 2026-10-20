# =============================================================================
# Libro SEM · EMOVI
# 02 - Análisis Factorial Confirmatorio (AFC) de primer orden
# =============================================================================
# Referencia: la tesis (Sánchez Flores, 2019) confirma con un CFA binario (WLSMV)
# el índice de riqueza del hogar de origen (Anexo 2: KR-20 .88, RMSEA .05, CFI .99,
# n = 17,665, 12 ítems en un factor). Aquí se confirma la estructura de tres
# factores que salió del AFE, con la CDMX de 2023 (n = 740).
#   source("EMOVI/02_AFC/AFC.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "EMOVI/02_AFC/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos (igual que en el AFE): 29 ítems de riqueza del hogar de origen
# -----------------------------------------------------------------------
emovi <- read.dta13("EMOVI/data/entrevistado_2023_CDMX.dta", convert.factors = FALSE)
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])
riqueza <- c(rango("p26", "a", "e"), rango("p29", "a", "g"), rango("p31", "a", "o"), rango("p32", "a", "o"))
for (v in riqueza) emovi[[v]] <- ifelse(emovi[[v]] == 1, 1, ifelse(emovi[[v]] == 2, 0, NA))   # 1 Sí, 0 No, NS = NA

# -----------------------------------------------------------------------
# Paso 2. El modelo: cada ítem en el factor donde más carga en el AFE
# -----------------------------------------------------------------------
# ESP = espacios de la vivienda   BAS = servicios y bienes básicos   TEC = tecnología y confort
# p29a (sala) y p26c (baño) cargaban casi igual en dos factores; se dejan donde
# tienen más sentido: la sala con los espacios y el baño con los servicios.
modelo <- '
  ESP =~ p29a + p29b + p29c + p29d + p29e + p29f + p26e + p31f + p31g + p32a
  BAS =~ p26a + p26c + p26d + p29g + p31a + p31b + p31c + p31d + p31e + p31m + p31o + p32e + p32f + p32h
  TEC =~ p31h + p31i + p31j + p31k + p31l'
items <- unlist(regmatches(modelo, gregexpr("p[0-9]+[a-o]", modelo)))
length(items)                                # 29

# -----------------------------------------------------------------------
# Paso 3. Estimar: ítems binarios como ordinales (WLSMV)
# -----------------------------------------------------------------------
# missing = "pairwise" usa las parejas de respuestas disponibles: no se pierden los
# 89 entrevistados con algún NS (con listwise quedan 651). lavaan no tiene FIML
# con ítems ordinales; ver 07_FIML.
fit <- cfa(modelo, data = emovi, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit, "converged")                 # TRUE
lavInspect(fit, "nobs")                      # 740

medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
ajuste(fit, "3 factores (pairwise)")         # chi2(374) = 801, CFI .975, TLI .973, RMSEA .039, SRMR .081

# Robustez: solo los 651 sin ningún NS (listwise) y un solo factor con los 29 ítems
fit_lw <- cfa(modelo, data = emovi, ordered = items, estimator = "WLSMV")
fit_1f <- cfa(paste("RIQ =~", paste(items, collapse = " + ")), data = emovi, ordered = items,
              estimator = "WLSMV", missing = "pairwise")
tabla_ajuste <- rbind(ajuste(fit, "3 factores (pairwise)"), ajuste(fit_lw, "3 factores (listwise)"),
                      ajuste(fit_1f, "1 factor"))
tabla_ajuste
# Los tres factores ajustan mejor que uno solo; listwise da lo mismo.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas y correlaciones entre factores
# -----------------------------------------------------------------------
s <- standardizedSolution(fit)
cargas <- s[s$op == "=~", c("lhs", "rhs", "est.std", "se")]
cargas[, c("est.std", "se")] <- round(cargas[, c("est.std", "se")], 3)
names(cargas) <- c("factor", "item", "carga", "ee")
cargas                                       # de .42 (p29c) a .96 (p31l)
range(cargas$carga)
round(lavInspect(fit, "cor.lv"), 2)          # ESP-BAS .81, ESP-TEC .69, BAS-TEC .81
write.csv(cargas, file.path(dir_salida, "cargas_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Índices de modificación (solo para ver, no se modifica el modelo)
# -----------------------------------------------------------------------
# Los mayores son residuales entre ítems del mismo bloque (p29d-p29e, p32e-p32f):
# parejas de preguntas muy parecidas. No se agregan: el ajuste ya es bueno.
mi <- modindices(fit, sort. = TRUE, maximum.number = 8)
mi[, c("lhs", "op", "rhs", "mi")]
