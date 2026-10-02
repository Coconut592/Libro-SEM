# =============================================================================
# Libro SEM · PREP
# 02 - Análisis Factorial Confirmatorio (AFC)
# =============================================================================
# Referencias: CFA_Espacio_Publico.inp, CFA_Hogares.inp, cfa_espacio_publico.pdf y Laboratorios 2 y 5.
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/02_AFC/AFC.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(semPlot)
library(psych)
library(nFactors)
library(ggplot2)
dir_salida <- "PREP/02_AFC/output"

# -----------------------------------------------------------------------
# Paso 1. Datos
# -----------------------------------------------------------------------
# convert.factors = FALSE evita que Stata convierta las escalas 1-10 en factores.
prep <- read.dta13("PREP/data/PREP.dta", convert.factors = FALSE)
prep$id <- seq_len(nrow(prep))          # la base no trae id: se usa el número de fila
prep$estado <- prep$ID_MPIO %/% 1000    # clave INEGI: estado (1-32) * 1000 + municipio

items_ep  <- c("b11", "b12", "b13", "b14", "b15", "b16", "b17", "b18", "b21", "b22", "b26")
items_hog <- c(sprintf("c%02d", 1:9), sprintf("d%02d", 1:9), sprintf("e%02d", 1:5), sprintf("f%02d", 1:2))
items_g   <- sprintf("g%02d", 1:12)

# En los bloques c a f el "99 = Ns/Nc" viene como valor: se pasa a faltante.
# (b14-b18 se usan en su versión original: mayor = más seguro, como B18r-B21r del piloto.)
for (v in items_hog) prep[[v]][prep[[v]] %in% 99] <- NA

# Equivalencias piloto -> base (por contenido; ver 00_Diagnostico/README.md)
m_ep <- 'EVEP  =~ b11 + b12 + b13
         SEGEP =~ b14 + b15 + b16 + b17 + b18
         ACTEP =~ b21 + b22 + b26'
m_hog <- 'IP  =~ c01 + c02 + c03 + c04 + c05 + c06
          SG  =~ c07 + c08 + c09
          CS  =~ d01 + d02 + d03 + d04 + d05 + d06 + d07 + d08 + d09
          INF =~ e01 + e02 + e03 + e04 + e05
          SR  =~ f01 + f02'
m_g <- 'PART =~ g01 + g02 + g03 + g04
        RECH =~ g06 + g07 + g08
        INTV =~ g09 + g10 + g11 + g12'
modelos <- list(EP = m_ep, Hogares = m_hog, G = m_g)
items_modelo <- list(EP = items_ep, Hogares = items_hog, G = setdiff(items_g, "g05"))
# lavaan ignora a quien no tiene ningún ítem del modelo; aquí se quitan para saber cuántos quedan
con_info <- function(items) prep[rowSums(!is.na(prep[, items])) > 0, ]
datos <- lapply(items_modelo, con_info)
medidas <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- function(fit, nombre) {
  m <- round(as.numeric(fitMeasures(fit, medidas)), 3)
  data.frame(modelo = nombre, N = lavInspect(fit, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}

# -----------------------------------------------------------------------
# Paso 2. AFC de cada bloque con MLR y FIML (como Mplus)
# -----------------------------------------------------------------------
# "=~" se lee "se mide por"; lavaan fija en 1 la carga del primer ítem de cada
# factor. MLR corrige la no normalidad (ítems 1-10 con asimetría); missing = "fiml"
# usa a todo respondiente con al menos un ítem (ver 07_FIML). Hogares tarda ~1 min.
fits <- list()
for (nm in names(modelos))
  fits[[nm]] <- cfa(modelos[[nm]], data = datos[[nm]], estimator = "MLR", missing = "fiml")
lapply(fits, lavInspect, "converged")
summary(fits$EP, fit.measures = TRUE, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 3. Bondad de ajuste (Hu y Bentler, 1999)
# -----------------------------------------------------------------------
# CFI y TLI >= .95 (aceptable >= .90), RMSEA <= .06 (aceptable <= .08), SRMR <= .08.
tabla_ajuste <- do.call(rbind, lapply(names(fits), function(nm) ajuste(fits[[nm]], nm)))
tabla_ajuste
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas y correlaciones entre factores
# -----------------------------------------------------------------------
sol <- do.call(rbind, lapply(names(fits), function(nm) {
  s <- standardizedSolution(fits[[nm]])
  s <- s[s$op == "=~" | (s$op == "~~" & s$lhs != s$rhs), ]   # cargas y correlaciones
  data.frame(bloque = nm, s[, c("lhs", "op", "rhs", "est.std", "se", "pvalue")])
}))
sol$est.std <- round(sol$est.std, 3)
sol[sol$op == "=~", ]                    # cargas: todas >= .46
sol[sol$op == "~~", ]                    # INF-SR = .77 es la correlación más alta
write.csv(sol, file.path(dir_salida, "solucion_estandarizada_AFC.csv"), row.names = FALSE)

# Índices de modificación del modelo de Hogares (los más grandes)
mi <- modindices(fits$Hogares, sort. = TRUE, maximum.number = 8)
mi[, c("lhs", "op", "rhs", "mi", "epc")]

# -----------------------------------------------------------------------
# Paso 5. Los respondientes están agrupados en espacios
# -----------------------------------------------------------------------
# Con ~30 respondientes por espacio e ICC ~ .21, los errores estándar sin corregir
# quedan cortos. cluster = "espacio" los corrige (~37% mayores) y el ajuste no cambia.
fit_cl <- cfa(m_ep, data = datos$EP, estimator = "MLR", missing = "fiml", cluster = "espacio")
ajuste(fit_cl, "EP con cluster")
se_cargas <- function(f) { p <- parameterEstimates(f); mean(p$se[p$op == "=~" & p$se > 0]) }
se_cargas(fit_cl) / se_cargas(fits$EP)

# -----------------------------------------------------------------------
# Paso 6. Diagramas
# -----------------------------------------------------------------------
for (nm in names(fits)) {
  png(file.path(dir_salida, paste0("diagrama_AFC_", nm, ".png")), width = 1100, height = 650)
  semPaths(fits[[nm]], whatLabels = "std", edge.label.cex = 0.9, layout = "tree2")
  dev.off()
}
