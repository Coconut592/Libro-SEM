# =============================================================================
# Libro SEM · PREP
# 03 - AFC de segundo orden
# =============================================================================
# Referencia: Laboratorio 3 (G =~ f1 + f2 + f3 en lavaan).
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(semPlot)
library(psych)
library(nFactors)
library(ggplot2)
dir_salida <- "PREP/03_AFC_2do_Orden/output"

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
# Paso 2. Primer orden y segundo orden, bloque por bloque
# -----------------------------------------------------------------------
# Como en el Lab 3, el factor de segundo orden se define igual que uno de primer
# orden: CAL =~ EVEP + SEGEP + ACTEP. std.lv = TRUE fija su varianza en 1.
# (En Hogares, con la carga marcadora por defecto el modelo NO converge.)
m_2o <- list(
  EP      = paste(m_ep,  "\n CALEP =~ EVEP + SEGEP + ACTEP"),
  Hogares = paste(m_hog, "\n ENT =~ IP + SG + CS + INF + SR"))   # tarda ~1 min

fit1 <- list(); fit2 <- list()
for (nm in names(m_2o)) {
  fit1[[nm]] <- cfa(modelos[[nm]], data = datos[[nm]], estimator = "MLR", missing = "fiml")
  fit2[[nm]] <- cfa(m_2o[[nm]], data = datos[[nm]], estimator = "MLR", missing = "fiml", std.lv = TRUE)
}

# -----------------------------------------------------------------------
# Paso 3. Solución estandarizada del segundo orden
# -----------------------------------------------------------------------
cargas_2o <- do.call(rbind, lapply(names(fit2), function(nm) {
  s <- standardizedSolution(fit2[[nm]])
  d <- s[s$op == "=~" & s$lhs %in% c("CALEP", "ENT"), c("lhs", "rhs", "est.std", "pvalue")]
  d$disturbio <- round(1 - d$est.std^2, 3)      # varianza del factor no explicada por G
  d$bloque <- nm; d
}))
cargas_2o$est.std <- round(cargas_2o$est.std, 3)
cargas_2o     # EP: .86, .58, .75; Hogares: IP -.38, SG .60, CS .46, INF .85, SR .89
write.csv(cargas_2o, file.path(dir_salida, "cargas_2do_orden.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Comparación con el primer orden
# -----------------------------------------------------------------------
# EP: 3 factores de primer orden -> el de segundo orden queda justo identificado
# (mismos gl y mismo ajuste; no se puede contrastar). Hogares: 5 factores -> sí.
tabla <- rbind(ajuste(fit1$EP, "EP 1er orden"), ajuste(fit2$EP, "EP 2do orden"),
               ajuste(fit1$Hogares, "Hogares 1er orden"), ajuste(fit2$Hogares, "Hogares 2do orden"))
tabla
write.csv(tabla, file.path(dir_salida, "ajuste_1er_vs_2do_orden.csv"), row.names = FALSE)
# Con N tan grande la diferencia de chi-cuadrada siempre sale significativa; se
# mira la caída de CFI (Chen, 2007: <= .01 es aceptable).
lavTestLRT(fit1$Hogares, fit2$Hogares)

# -----------------------------------------------------------------------
# Paso 5. ¿Tiene sentido un segundo orden en el bloque G?
# -----------------------------------------------------------------------
# Los 3 factores casi no se correlacionan (.05, .20, -.10): no hay un factor general.
fit_g <- cfa(m_g, data = datos$G, estimator = "MLR", missing = "fiml")
round(lavInspect(fit_g, "cor.lv"), 2)

# -----------------------------------------------------------------------
# Paso 6. Diagramas
# -----------------------------------------------------------------------
for (nm in names(fit2)) {
  png(file.path(dir_salida, paste0("diagrama_2do_orden_", nm, ".png")), width = 1100, height = 700)
  semPaths(fit2[[nm]], whatLabels = "std", edge.label.cex = 0.9, layout = "tree2")
  dev.off()
}
