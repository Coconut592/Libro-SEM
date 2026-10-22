# =============================================================================
# Libro SEM · Violencia Veracruz
# 02 - Análisis Factorial Confirmatorio (AFC) de primer orden
# =============================================================================
# Sin referencia: Scripts.do lleva los 24 ítems a un análisis de clases latentes
# (Mplus) y no hace AFC. Aquí se confirma la estructura de seis ámbitos de
# violencia que da el cuestionario (infancia, familia, pareja, trabajo,
# comunidad y escuela) y que el AFE recupera en gran parte, y se compara con
# la solución de cinco factores del AFE (familia y trabajo juntos) y con un
# solo factor.
#   source("Violencia_Veracruz/02_AFC/AFC.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Violencia_Veracruz/02_AFC/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos (igual que en el AFE): 1,088 mujeres, 24 ítems 0/1
# -----------------------------------------------------------------------
vera <- read.dta13("Violencia_Veracruz/data/BASE_ACLnew.dta", convert.factors = FALSE)
items <- c("p141", "p142", "p143", "p144", "p161", "p162", "p165", "p171", "p172", "p173", "p175", "p176",
           "p183", "p184", "p185", "p186", "p191", "p192", "p193", "p194", "p201", "p202", "p203", "p204")
vera <- vera[rowSums(!is.na(vera[, items])) > 0, ]    # quita el renglón huérfano id 907 (sin ítems)
nrow(vera)                                   # 1,088

# -----------------------------------------------------------------------
# Paso 2. El modelo: un factor por ámbito del cuestionario
# -----------------------------------------------------------------------
# INF = violencia en la infancia          COM = violencia en la comunidad (la calle)
# FAM = violencia familiar (último año)   ESC = violencia en la escuela
# PAR = violencia de pareja (último año)  TRA = violencia en el trabajo
modelo <- '
  INF =~ p141 + p142 + p143 + p144
  FAM =~ p161 + p162 + p165
  PAR =~ p171 + p172 + p173 + p175 + p176
  TRA =~ p183 + p184 + p185 + p186
  COM =~ p191 + p192 + p193 + p194
  ESC =~ p201 + p202 + p203 + p204'

# -----------------------------------------------------------------------
# Paso 3. Estimar: ítems 0/1 como ordinales (WLSMV)
# -----------------------------------------------------------------------
# missing = "pairwise" usa las parejas de respuestas disponibles: no se pierden las
# mujeres que se saltan pareja, trabajo o escuela (con listwise quedan 505).
# lavaan no tiene FIML con ítems ordinales; ver 07_FIML.
fit <- cfa(modelo, data = vera, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit, "converged")                 # TRUE
lavInspect(fit, "post.check")                # TRUE: solución admisible (sin varianzas negativas)
lavInspect(fit, "nobs")                      # 1,088

medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
ajuste(fit, "6 ámbitos (pairwise)")          # chi2(237) = 332, CFI .987, TLI .985, RMSEA .019, SRMR .110

# Alternativas y robustez
modelo5 <- '
  INF    =~ p141 + p142 + p143 + p144
  FAMTRA =~ p161 + p162 + p165 + p183 + p184 + p185 + p186
  PAR    =~ p171 + p172 + p173 + p175 + p176
  COM    =~ p191 + p192 + p193 + p194
  ESC    =~ p201 + p202 + p203 + p204'
fit5 <- cfa(modelo5, data = vera, ordered = items, estimator = "WLSMV", missing = "pairwise")
fit_1f <- cfa(paste("VIO =~", paste(items, collapse = " + ")), data = vera, ordered = items,
              estimator = "WLSMV", missing = "pairwise")
fit_lw <- cfa(modelo, data = vera, ordered = items, estimator = "WLSMV")   # solo las 505 sin faltantes
tabla_ajuste <- rbind(ajuste(fit, "6 ámbitos (pairwise)"), ajuste(fit_lw, "6 ámbitos (listwise)"),
                      ajuste(fit5, "5 factores (familia + trabajo)"), ajuste(fit_1f, "1 factor"))
tabla_ajuste
# Los seis ámbitos ajustan muy bien en CFI, TLI y RMSEA; el SRMR (.110) no (ver paso 6).
# Con listwise (505 mujeres) el ajuste es algo peor (CFI .976, RMSEA .024). Un solo
# factor no sirve (CFI .847, RMSEA .065): la violencia no es una sola dimensión.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_AFC.csv"), row.names = FALSE)

# 6 ámbitos contra 5 factores (familia y trabajo juntos): diferencia de chi2 escalada
lavTestLRT(fit, fit5)
# Delta chi2 = 16.1 (5 gl), p = .007: los seis ámbitos ajustan mejor. Se conserva trabajo
# como factor propio (es un ámbito del cuestionario y correlaciona .60 con familia, no 1).

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas
# -----------------------------------------------------------------------
s <- standardizedSolution(fit)
cargas <- s[s$op == "=~", c("lhs", "rhs", "est.std", "se")]
cargas[, c("est.std", "se")] <- round(cargas[, c("est.std", "se")], 3)
names(cargas) <- c("factor", "item", "carga", "ee")
cargas
range(cargas$carga)                          # de .47 (p193) a .96 (p141)
cargas[cargas$ee > .08, ]                    # p184, p185, p186 (trabajo) y p194: pocos casos "Sí", errores grandes
cargas[cargas$carga < .60, ]                 # p193 (.47) y p194 (.48): las más flojas, en comunidad
write.csv(cargas, file.path(dir_salida, "cargas_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Correlaciones entre factores
# -----------------------------------------------------------------------
cor_factores <- round(lavInspect(fit, "cor.lv"), 2)
cor_factores                                 # de .31 a .60 (familia-trabajo)
write.csv(cor_factores, file.path(dir_salida, "correlaciones_factores.csv"))

# -----------------------------------------------------------------------
# Paso 6. ¿Por qué el SRMR es alto (.110)?
# -----------------------------------------------------------------------
# El SRMR resume los residuos de TODAS las correlaciones policóricas. Las parejas de ítems con
# 5 mujeres o menos que digan "Sí" en ambos (65 de 276) tienen correlaciones inestables
# (ver 00_Diagnostico), y sus residuos son enormes (hasta -.53).
res <- lavResiduals(fit, type = "cor")$cov
n11 <- outer(items, items, Vectorize(function(a, b) sum(vera[[a]] == 1 & vera[[b]] == 1, na.rm = TRUE)))
dimnames(n11) <- list(items, items)
i <- which(lower.tri(res), arr.ind = TRUE)
r <- data.frame(a = items[i[, 1]], b = items[i[, 2]], residuo = res[i], n_si_si = n11[i])
c(SRMR = round(fitMeasures(fit, "srmr"), 3),
  sin_pares_dispersos = round(sqrt(mean(r$residuo[r$n_si_si > 5]^2)), 3),
  solo_pares_dispersos = round(sqrt(mean(r$residuo[r$n_si_si <= 5]^2)), 3))
# .110 con todas las parejas; .092 sin las 65 casi vacías (.167 en ellas). Sigue arriba de .08,
# así que el SRMR se reporta como una debilidad del modelo y no se maquilla.
head(r[order(-abs(r$residuo)), ], 6)         # p202-p185, p203-p194, p202-p194: parejas casi vacías

# -----------------------------------------------------------------------
# Paso 7. Índices de modificación (solo para ver, no se modifica el modelo)
# -----------------------------------------------------------------------
mi <- modindices(fit, sort. = TRUE, maximum.number = 8)
mi[, c("lhs", "op", "rhs", "mi", "epc")]
# El mayor es un residual entre dos ítems raros de ámbitos distintos (p194-p202, MI = 17.1) y
# ninguno pasa de eso; los demás son cargas cruzadas y residuales de parejas casi vacías
# (p185-p194, PAR =~ p186) o dentro del mismo ámbito (p193-p194, p161-p162). No se agrega nada.
