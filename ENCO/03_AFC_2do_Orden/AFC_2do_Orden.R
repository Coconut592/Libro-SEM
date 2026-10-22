# =============================================================================
# Libro SEM · ENCO
# 03 - AFC de segundo orden: Confianza del consumidor
# =============================================================================
# Sin referencia: el documento de INEGI no trae un modelo de segundo orden. Los
# cuatro factores del AFC (hogar hoy, hogar esperado, país, consumo y ahorro)
# correlacionan de .54 a .79, así que se prueba si los gobierna un factor general:
# la confianza del consumidor.
#   source("ENCO/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(foreign)
library(lavaan)

dir_salida <- "ENCO/03_AFC_2do_Orden/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo de primer orden (igual que en 02_AFC)
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

primer_orden <- '
  HOGA =~ P1 + P3
  HOGE =~ P2 + P4
  PAIS =~ P5 + P6 + P12 + P13
  CONS =~ P7 + P8 + P9 + P10 + P11 + P14 + P15'

# -----------------------------------------------------------------------
# Paso 2. Segundo orden: CONF =~ HOGA + HOGE + PAIS + CONS
# -----------------------------------------------------------------------
segundo_orden <- paste(primer_orden, "\n  CONF =~ HOGA + HOGE + PAIS + CONS")
fit1 <- cfa(primer_orden, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")
fit2 <- cfa(segundo_orden, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit2, "converged")                # TRUE

medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
tabla_ajuste <- rbind(ajuste(fit1, "1.er orden (4 factores)"), ajuste(fit2, "2.º orden (CONF)"))
tabla_ajuste
# 1.er orden: χ²(84) = 960, CFI .975, RMSEA .071; 2.º orden: χ²(86) = 952, CFI .975, RMSEA .070.
# A diferencia del EMOVI (3 factores, justo identificado), aquí el segundo orden SÍ se
# puede contrastar: 4 factores tienen 6 correlaciones y el segundo orden las
# reemplaza por 4 cargas, así que quedan 2 grados de libertad más.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_2do_orden.csv"), row.names = FALSE)

# Diferencia de χ² escalada (Satorra, 2000): ¿empeora el ajuste al pedir un factor general?
suppressMessages(lavTestLRT(fit1, fit2))    # Δχ²(2) = 19.2, p < .001: la prueba rechaza (con 2,050 casos),
                                             # pero CFI, TLI, RMSEA y SRMR no cambian (SRMR .048 contra .049)

# -----------------------------------------------------------------------
# Paso 3. Cargas de segundo orden y varianza explicada de cada factor
# -----------------------------------------------------------------------
s <- standardizedSolution(fit2)
g <- s[s$lhs == "CONF" & s$op == "=~", c("rhs", "est.std", "se", "pvalue")]
g[, 2:4] <- round(g[, 2:4], 3)
names(g) <- c("factor", "carga_CONF", "ee", "p")
g$R2 <- round(g$carga_CONF^2, 2)
g                                            # HOGA .85, HOGE .79, PAIS .68, CONS .92
# CONS (R2 = .84) es el factor que más se parece al general; PAIS el que menos (.47): es el
# que más varianza propia tiene (la economía del país no se reduce a la confianza del hogar).
# Varianzas residuales de los factores: si alguna fuera negativa o la carga pasara de
# 1, habría un caso Heywood.
round(diag(lavInspect(fit2, "est")$psi), 3)   # .23, .31, .29 y .12: todas positivas, no hay Heywood
write.csv(g, file.path(dir_salida, "cargas_segundo_orden.csv"), row.names = FALSE)

# Las cargas de primer orden casi no cambian respecto al AFC de primer orden
l1 <- standardizedSolution(fit1); l2 <- s
max(abs(l1$est.std[l1$op == "=~"] - l2$est.std[l2$op == "=~" & l2$lhs != "CONF"]))   # .001

# -----------------------------------------------------------------------
# Paso 4. ¿Hace falta el segundo orden? Contra un solo factor con los 15 ítems
# -----------------------------------------------------------------------
fit_1f <- cfa(paste("CONF =~", paste(items, collapse = " + ")), data = x, ordered = items,
              estimator = "WLSMV", missing = "pairwise")
ajuste(fit_1f, "1 factor con los 15 ítems")
# El factor único ajusta peor (CFI .889, RMSEA .146) que los cuatro factores con un general
# encima (CFI .975, RMSEA .070): la estructura de cuatro dimensiones es real.
