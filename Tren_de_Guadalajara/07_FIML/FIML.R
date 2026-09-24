# =============================================================================
# Libro SEM · Tren de Guadalajara
# 06 - AFC con datos faltantes: FIML
# =============================================================================
# Referencias: AFE_CFA.R (missing = "fiml"), CFA_Tren.inp / tren.inp (Mplus
# usa FIML por defecto con MLR) y SEM02_Ejemplo_AFE-AFC.pdf (láminas 9-12).
#
# Nota: en AFE_CFA.R el modelo con missing = "fiml" se ajusta sobre
# tren_reducido, que ya solo tiene registros completos, así que FIML no
# cambia nada. Aquí se usa la base completa (306 usuarios), como en Mplus.
#   source("Tren_de_Guadalajara/07_FIML/FIML.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Tren_de_Guadalajara/07_FIML/output"

# -----------------------------------------------------------------------
# Paso 1. ¿Cuántos datos faltan y dónde?
# -----------------------------------------------------------------------
tren <- read.dta13("Tren_de_Guadalajara/data/imsctren2006.dta")
items <- c("p4", "p5", "p61", "p62", "p63", "p64", "p71", "p73", "p74", "p75")

colSums(is.na(tren[, items]))           # p63: 107 y p64: 128 faltantes
sum(complete.cases(tren[, items]))      # solo 170 de 306 están completos
# Con eliminación por lista (listwise) se pierde el 44% de la muestra.

# Patrones de faltantes (1 = falta)
patrones <- table(apply(is.na(tren[, items]) * 1, 1, paste, collapse = ""))
sort(patrones, decreasing = TRUE)

# -----------------------------------------------------------------------
# Paso 2. ¿Son faltantes completamente al azar (MCAR)?
# -----------------------------------------------------------------------
# FIML es insesgado si los datos son MCAR o MAR (la probabilidad de faltar
# depende solo de variables observadas). Si fueran MCAR, quienes no
# responden la tarjeta no deberían diferir en los demás ítems.
tren$falta_tarjeta <- is.na(tren$p63) & is.na(tren$p64)
otros <- c("p4", "p5", "p61", "p62", "p71", "p73", "p74", "p75")
comparacion <- data.frame(
  responde_tarjeta    = sapply(otros, function(v) mean(tren[[v]][!tren$falta_tarjeta], na.rm = TRUE)),
  no_responde_tarjeta = sapply(otros, function(v) mean(tren[[v]][tren$falta_tarjeta], na.rm = TRUE)),
  p_valor             = sapply(otros, function(v) t.test(tren[[v]] ~ tren$falta_tarjeta)$p.value))
round(comparacion, 3)
# Quienes no responden la tarjeta califican mejor el confort (p71, p73, p75):
# los faltantes NO son MCAR y el listwise puede sesgar. Como esa diferencia
# está en variables observadas del modelo, FIML la aprovecha (supuesto MAR).

# -----------------------------------------------------------------------
# Paso 3. Modelo con eliminación por lista vs FIML
# -----------------------------------------------------------------------
modelo <- 'acceso  =~ NA*p4 + 1*p5 + p61 + p62
           tarjeta =~ 1*p63 + p64
           confort =~ NA*p71 + p73 + p74 + 1*p75'

# a) Listwise: solo los 170 completos
fit_listwise <- sem(modelo, data = tren[complete.cases(tren[, items]), ], estimator = "MLR")
# b) FIML: los 306 usuarios. Cada caso aporta a la verosimilitud con los
#    ítems que sí respondió (missing = "fiml"). Es lo que hace Mplus con
#    ESTIMATOR = MLR y MISSING ARE .
fit_fiml <- sem(modelo, data = tren, estimator = "MLR", missing = "fiml")
summary(fit_fiml, fit.measures = TRUE, standardized = TRUE)

# Cobertura: proporción de casos con información para cada par de ítems.
# Mplus pide al menos 0.10; aquí la mínima es 0.57 (p64 con p61).
round(lavInspect(fit_fiml, "coverage"), 2)

# -----------------------------------------------------------------------
# Paso 4. Comparar ajuste y cargas
# -----------------------------------------------------------------------
medidas <- c("ntotal", "chisq", "chisq.scaled", "df", "cfi", "tli", "rmsea",
             "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- rbind(listwise = fitMeasures(fit_listwise, medidas),
                FIML     = fitMeasures(fit_fiml, medidas))
round(ajuste, 3)
# CFI = .920, TLI = .887, RMSEA = .102 y SRMR = .069 en FIML son los
# valores que reporta Mplus en el PDF.

# Cargas y correlaciones entre factores de cada modelo (el de FIML trae
# además los interceptos, por eso se une por el nombre del parámetro)
solucion <- function(fit) {
  std <- standardizedSolution(fit)
  std <- std[std$op == "=~" | (std$op == "~~" & std$lhs != std$rhs &
                                 std$lhs %in% c("acceso", "tarjeta", "confort")), ]
  data.frame(parametro = paste(std$lhs, std$op, std$rhs), est = std$est.std, ee = std$se)
}
cargas <- merge(solucion(fit_listwise), solucion(fit_fiml), by = "parametro",
                suffixes = c("_listwise", "_FIML"), sort = FALSE)
cargas[, -1] <- round(cargas[, -1], 3)
cargas
# Las cargas con FIML son las del PDF (p4 .612, p5 .808, ..., p75 .877).

write.csv(round(ajuste, 3), file.path(dir_salida, "ajuste_listwise_vs_FIML.csv"))
write.csv(cargas, file.path(dir_salida, "cargas_listwise_vs_FIML.csv"), row.names = FALSE)
