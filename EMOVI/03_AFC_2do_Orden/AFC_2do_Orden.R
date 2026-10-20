# =============================================================================
# Libro SEM · EMOVI
# 03 - AFC de segundo orden: Riqueza del hogar de origen
# =============================================================================
# Sin referencia: la tesis usa un solo factor de riqueza (Anexo 2) y no hace
# segundo orden. Los tres factores del AFC (espacios, servicios y bienes básicos,
# tecnología) correlacionan de .69 a .81, así que se prueba si los gobierna un
# factor general: la riqueza del hogar de origen.
#   source("EMOVI/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "EMOVI/03_AFC_2do_Orden/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo de primer orden (igual que en 02_AFC)
# -----------------------------------------------------------------------
emovi <- read.dta13("EMOVI/data/entrevistado_2023_CDMX.dta", convert.factors = FALSE)
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])
riqueza <- c(rango("p26", "a", "e"), rango("p29", "a", "g"), rango("p31", "a", "o"), rango("p32", "a", "o"))
for (v in riqueza) emovi[[v]] <- ifelse(emovi[[v]] == 1, 1, ifelse(emovi[[v]] == 2, 0, NA))

primer_orden <- '
  ESP =~ p29a + p29b + p29c + p29d + p29e + p29f + p26e + p31f + p31g + p32a
  BAS =~ p26a + p26c + p26d + p29g + p31a + p31b + p31c + p31d + p31e + p31m + p31o + p32e + p32f + p32h
  TEC =~ p31h + p31i + p31j + p31k + p31l'
items <- unlist(regmatches(primer_orden, gregexpr("p[0-9]+[a-o]", primer_orden)))

# -----------------------------------------------------------------------
# Paso 2. Segundo orden: RIQ =~ ESP + BAS + TEC
# -----------------------------------------------------------------------
segundo_orden <- paste(primer_orden, "\n  RIQ =~ ESP + BAS + TEC")
fit1 <- cfa(primer_orden, data = emovi, ordered = items, estimator = "WLSMV", missing = "pairwise")
fit2 <- cfa(segundo_orden, data = emovi, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit2, "converged")                # TRUE

medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
tabla_ajuste <- rbind(ajuste(fit1, "1.er orden (3 factores)"), ajuste(fit2, "2.º orden (RIQ)"))
tabla_ajuste
# Con tres factores de primer orden el de segundo orden queda JUSTO IDENTIFICADO:
# 3 correlaciones entre factores se reemplazan por 3 cargas, así que los grados de
# libertad y el ajuste son idénticos (chi2(374) = 801, CFI .975). El segundo orden
# no se puede contrastar contra el primero con estos datos: es una forma más
# parsimoniosa de describir las mismas correlaciones, no una mejora de ajuste.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_2do_orden.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Cargas de segundo orden y varianza explicada de cada factor
# -----------------------------------------------------------------------
s <- standardizedSolution(fit2)
g <- s[s$lhs == "RIQ" & s$op == "=~", c("rhs", "est.std", "se", "pvalue")]
g[, 2:4] <- round(g[, 2:4], 3)
names(g) <- c("factor", "carga_RIQ", "ee", "p")
g$R2 <- round(g$carga_RIQ^2, 2)
g                                            # ESP .84, BAS .97, TEC .83
# BAS casi no tiene varianza propia (R2 = .94): es el factor que más se parece al
# general. Una carga tan cerca de 1 pide cuidado, pero no pasa de 1 (no es Heywood).
write.csv(g, file.path(dir_salida, "cargas_segundo_orden.csv"), row.names = FALSE)

# Las cargas de primer orden no cambian respecto al AFC de primer orden
l1 <- standardizedSolution(fit1); l2 <- s
max(abs(l1$est.std[l1$op == "=~"] - l2$est.std[l2$op == "=~" & l2$lhs != "RIQ"]))   # ~0

# -----------------------------------------------------------------------
# Paso 4. ¿Hace falta el segundo orden? Contra un solo factor con los 29 ítems
# -----------------------------------------------------------------------
fit_1f <- cfa(paste("RIQ =~", paste(items, collapse = " + ")), data = emovi, ordered = items,
              estimator = "WLSMV", missing = "pairwise")
ajuste(fit_1f, "1 factor")
# El factor único ajusta peor (CFI .952, RMSEA .054) que los tres factores con un
# general encima (CFI .975, RMSEA .039): la estructura de tres dimensiones es real.
