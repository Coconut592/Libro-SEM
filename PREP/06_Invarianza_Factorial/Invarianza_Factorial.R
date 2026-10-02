# =============================================================================
# Libro SEM · PREP
# 06 - Invarianza factorial
# =============================================================================
# No viene en los archivos de referencia. Secuencia estándar: configural -> métrica -> escalar -> estricta (Meredith, 1993; Chen, 2007).
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/06_Invarianza_Factorial/Invarianza_Factorial.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(psych)
library(nFactors)
library(ggplot2)
dir_salida <- "PREP/06_Invarianza_Factorial/output"

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
# Paso 2. ¿Qué grupo? (ilustrativo: falta definirlo con el equipo del PREP)
# -----------------------------------------------------------------------
# La base no trae sexo, edad ni tipo de espacio. Lo único que agrupa es la clave del
# municipio, de la que sale el ESTADO. Se usan los tres con más respondientes:
# 15 (México), 30 (Veracruz) y 26 (Sonora). No es una hipótesis del estudio.
sort(table(prep$estado), decreasing = TRUE)[1:6]
estados <- c(15, 30, 26)

# -----------------------------------------------------------------------
# Paso 3. Secuencia de invarianza (MLR + FIML)
# -----------------------------------------------------------------------
# configural: misma estructura | métrica: + cargas iguales | escalar: + interceptos
# iguales (permite comparar medias de los factores) | estricta: + residuales iguales.
# Criterio de Chen (2007): se mantiene la invarianza si CFI cae <= .01 y RMSEA sube <= .015.
niveles <- list(configural = NULL, metrica = "loadings",
                escalar = c("loadings", "intercepts"),
                estricta = c("loadings", "intercepts", "residuals"))
secuencia <- function(nm, niveles) {
  d <- datos[[nm]][datos[[nm]]$estado %in% estados, ]
  d$estado <- factor(d$estado)
  ajustes <- lapply(niveles, function(ge) cfa(modelos[[nm]], data = d, group = "estado",
                                              estimator = "MLR", missing = "fiml", group.equal = ge))
  tab <- t(sapply(ajustes, function(f) round(as.numeric(fitMeasures(f, medidas)), 3)))
  colnames(tab) <- c("chisq", "gl", "CFI", "TLI", "RMSEA", "SRMR")
  tab <- data.frame(bloque = nm, N = nrow(d), nivel = names(niveles), tab, row.names = NULL)
  tab$dCFI <- c(NA, round(diff(tab$CFI), 3))
  tab$dRMSEA <- c(NA, round(diff(tab$RMSEA), 3))
  tab
}
res_ep  <- secuencia("EP", niveles)
res_g   <- secuencia("G", niveles)
res_hog <- secuencia("Hogares", niveles[1:3])      # el más lento (varios minutos)
res <- rbind(res_ep, res_g, res_hog)
res
write.csv(res, file.path(dir_salida, "invarianza_por_estado.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Si falla un nivel: ¿qué ítem es el responsable?
# -----------------------------------------------------------------------
# Con el modelo escalar de espacio público, la prueba de score dice qué restricción
# (carga o intercepto igual entre estados) empeora más el ajuste (invarianza parcial).
d <- datos$EP[datos$EP$estado %in% estados, ]; d$estado <- factor(d$estado)
f_esc <- cfa(m_ep, data = d, group = "estado", estimator = "MLR", missing = "fiml",
             group.equal = c("loadings", "intercepts"))
sc <- lavTestScore(f_esc)$uni
pt <- parTable(f_esc)
nombre <- function(p) { i <- match(p, pt$plabel); paste0(pt$lhs[i], pt$op[i], pt$rhs[i], " (grupo ", pt$group[i], ")") }
top <- sc[order(-sc$X2), ][1:6, ]
data.frame(restriccion = paste(nombre(top$lhs), "=", nombre(top$rhs)), X2 = round(top$X2, 1))

# -----------------------------------------------------------------------
# Paso 5. Sensibilidad: cinco estados en vez de tres (espacio público)
# -----------------------------------------------------------------------
estados <- c(15, 30, 26, 11, 25)
res5 <- secuencia("EP", niveles[1:3])
res5
write.csv(res5, file.path(dir_salida, "invarianza_EP_5_estados.csv"), row.names = FALSE)
