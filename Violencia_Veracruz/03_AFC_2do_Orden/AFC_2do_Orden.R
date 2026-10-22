# =============================================================================
# Libro SEM · Violencia Veracruz
# 03 - AFC de segundo orden: violencia contra las mujeres
# =============================================================================
# Sin referencia: Scripts.do no hace segundo orden. Los seis ámbitos del AFC
# (infancia, familia, pareja, trabajo, comunidad y escuela) correlacionan de .31 a
# .60, así que se prueba si los gobierna un factor general: la violencia
# contra las mujeres. A diferencia de EMOVI (tres factores, segundo orden
# justo identificado), con seis factores el segundo orden SÍ se puede
# contrastar contra el primer orden: tiene 9 grados de libertad más.
#   source("Violencia_Veracruz/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Violencia_Veracruz/03_AFC_2do_Orden/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo de primer orden (igual que en 02_AFC)
# -----------------------------------------------------------------------
vera <- read.dta13("Violencia_Veracruz/data/BASE_ACLnew.dta", convert.factors = FALSE)
items <- c("p141", "p142", "p143", "p144", "p161", "p162", "p165", "p171", "p172", "p173", "p175", "p176",
           "p183", "p184", "p185", "p186", "p191", "p192", "p193", "p194", "p201", "p202", "p203", "p204")
vera <- vera[rowSums(!is.na(vera[, items])) > 0, ]    # 1,088 mujeres

primer_orden <- '
  INF =~ p141 + p142 + p143 + p144
  FAM =~ p161 + p162 + p165
  PAR =~ p171 + p172 + p173 + p175 + p176
  TRA =~ p183 + p184 + p185 + p186
  COM =~ p191 + p192 + p193 + p194
  ESC =~ p201 + p202 + p203 + p204'

# -----------------------------------------------------------------------
# Paso 2. Segundo orden: VIO =~ INF + FAM + PAR + TRA + COM + ESC
# -----------------------------------------------------------------------
segundo_orden <- paste(primer_orden, "\n  VIO =~ INF + FAM + PAR + TRA + COM + ESC")
fit1 <- cfa(primer_orden, data = vera, ordered = items, estimator = "WLSMV", missing = "pairwise")
fit2 <- cfa(segundo_orden, data = vera, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit2, "converged")                # TRUE
lavInspect(fit2, "post.check")               # TRUE: sin varianzas negativas

medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
tabla_ajuste <- rbind(ajuste(fit1, "1.er orden (6 factores)"), ajuste(fit2, "2.º orden (VIO)"))
tabla_ajuste
# Primer orden: chi2(237) = 332.3, CFI .987, RMSEA .019. Segundo orden: chi2(246) = 345.3,
# CFI .987, RMSEA .019, SRMR .114: casi igual con 9 parámetros menos (15 correlaciones
# entre factores se reemplazan por 6 cargas).
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_2do_orden.csv"), row.names = FALSE)

# ¿Pierde ajuste al imponer un solo factor general? Diferencia de chi2 escalada (Satorra, 2000)
lavTestLRT(fit1, fit2)
# Delta chi2 = 16.9 (9 gl), p = .051; ΔCFI = .000 y ΔRMSEA = .000. El criterio de Chen (2007)
# (ΔCFI de -.010 o menos) se cumple de sobra y la chi2 queda justo en el límite: el
# factor general explica las correlaciones entre ámbitos sin perder ajuste que valga la pena.

# -----------------------------------------------------------------------
# Paso 3. Cargas de segundo orden y varianza explicada de cada ámbito
# -----------------------------------------------------------------------
s <- standardizedSolution(fit2)
g <- s[s$lhs == "VIO" & s$op == "=~", c("rhs", "est.std", "se", "pvalue")]
g[, 2:4] <- round(g[, 2:4], 3)
names(g) <- c("ambito", "carga_VIO", "ee", "p")
g$R2 <- round(g$carga_VIO^2, 2)
g
# Familia .78, pareja .70, infancia .69, trabajo .67, comunidad .58 y escuela .56. Todas
# significativas y ninguna cerca de 1. R2 = varianza del ámbito que explica el factor general:
# de 31% (escuela) a 61% (familia); queda entre 39% y 69% propia de cada ámbito. No hay caso Heywood.
write.csv(g, file.path(dir_salida, "cargas_segundo_orden.csv"), row.names = FALSE)

# Las cargas de primer orden casi no cambian respecto al AFC de primer orden (hasta .016)
l1 <- standardizedSolution(fit1); l2 <- s
round(max(abs(l1$est.std[l1$op == "=~"] - l2$est.std[l2$op == "=~" & l2$lhs != "VIO"])), 3)

# -----------------------------------------------------------------------
# Paso 4. ¿Hace falta el segundo orden? Contra un solo factor con los 24 ítems
# -----------------------------------------------------------------------
fit_1f <- cfa(paste("VIO =~", paste(items, collapse = " + ")), data = vera, ordered = items,
              estimator = "WLSMV", missing = "pairwise")
ajuste(fit_1f, "1 factor")
# El factor único ajusta mucho peor (CFI .847, RMSEA .065) que los seis ámbitos con un
# general encima (CFI .987, RMSEA .019): los ámbitos son reales, y el general los resume.
