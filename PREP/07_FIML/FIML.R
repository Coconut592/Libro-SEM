# =============================================================================
# Libro SEM · PREP
# 07 - Datos faltantes: listwise vs FIML
# =============================================================================
# Referencias: TYPE = H1 missing de Mplus (cfa_espacio_publico.pdf), EFA_Hogares.inp y missing = 'fiml' de los Labs 4 y 5.
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/07_FIML/FIML.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(psych)
library(nFactors)
library(ggplot2)
dir_salida <- "PREP/07_FIML/output"

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
# Paso 2. ¿Cuánto falta?
# -----------------------------------------------------------------------
todos <- c(items_ep, items_hog, items_g)
faltantes <- data.frame(item = todos, n_NA = colSums(is.na(prep[, todos])),
                        pct_NA = round(100 * colMeans(is.na(prep[, todos])), 1))
faltantes[order(-faltantes$pct_NA), ][1:8, ]       # b21, b22 (~33%) y b18 (22%)
write.csv(faltantes, file.path(dir_salida, "faltantes_por_item.csv"), row.names = FALSE)

# Casos completos por bloque: lo que conservaría un análisis listwise
completos <- sapply(list(EP = items_ep, Hogares = items_hog, G = items_g),
                    function(it) sum(complete.cases(prep[, it])))
completos
round(100 * completos / nrow(prep), 1)

# Patrones de faltantes del espacio público (Mplus: "number of missing data patterns")
patron <- apply(is.na(prep[, items_ep]), 1, function(r) paste(as.integer(r), collapse = ""))
length(unique(patron))
head(sort(table(patron), decreasing = TRUE), 5)

# 428 respondientes no tienen NINGÚN ítem del espacio público, casi todos en espacios
# completos (en 10 espacios nadie tiene el bloque B). Parece un bloque no aplicado.
sin_ep <- rowSums(!is.na(prep[, items_ep])) == 0
sum(sin_ep)
tab <- table(prep$espacio[sin_ep]); length(tab)
sum(tab == table(prep$espacio)[names(tab)])

# -----------------------------------------------------------------------
# Paso 3. ¿Faltan al azar? Comparación con los demás ítems
# -----------------------------------------------------------------------
# Si b21 faltante se asocia con otros ítems observados, no es MCAR (a lo más MAR,
# que es lo que supone FIML). Se compara la media de los demás ítems entre quienes
# contestan y no contestan b21 (t de Welch).
otros <- setdiff(c(items_ep, items_hog), c("b21", "b22"))
prueba <- t(sapply(otros, function(v) {
  tt <- try(t.test(prep[[v]] ~ is.na(prep$b21)), silent = TRUE)
  if (inherits(tt, "try-error")) c(dif = NA, p = NA) else c(dif = unname(diff(tt$estimate)), p = tt$p.value)
}))
sum(prueba[, "p"] < .001, na.rm = TRUE)            # cuántos ítems difieren (p < .001)
length(otros)
round(prueba[order(prueba[, "p"]), ][1:6, ], 3)
# ¿"No sé" o salto de pregunta? Si quien no contesta b21 sí contesta b26, parece "no sé".
round(prop.table(table(b21_falta = is.na(prep$b21), b26_contesta = !is.na(prep$b26)), 1), 3)

# -----------------------------------------------------------------------
# Paso 4. Cobertura de covarianzas (como la tabla de Mplus)
# -----------------------------------------------------------------------
fit_ep <- cfa(m_ep, data = datos$EP, estimator = "MLR", missing = "fiml")
cob <- lavInspect(fit_ep, "coverage")
round(min(cob), 3)                    # Mplus pide al menos .10
round(cob, 2)

# -----------------------------------------------------------------------
# Paso 5. Listwise vs FIML en los tres bloques (MLR)
# -----------------------------------------------------------------------
# FIML no imputa: cada caso aporta a la verosimilitud con los ítems que sí respondió.
comparar <- function(nm) {
  lw <- cfa(modelos[[nm]], data = prep, estimator = "MLR", missing = "listwise")
  fi <- cfa(modelos[[nm]], data = datos[[nm]], estimator = "MLR", missing = "fiml")
  a <- standardizedSolution(lw); b <- standardizedSolution(fi)
  dif <- max(abs(a$est.std[a$op == "=~"] - b$est.std[b$op == "=~"]))
  list(ajuste = rbind(ajuste(lw, paste(nm, "listwise")), ajuste(fi, paste(nm, "FIML"))),
       dif_cargas = round(dif, 3),
       cargas = data.frame(bloque = nm, item = a$rhs[a$op == "=~"],
                           listwise = round(a$est.std[a$op == "=~"], 3),
                           fiml = round(b$est.std[b$op == "=~"], 3)))
}
res <- lapply(names(modelos), comparar)          # Hogares tarda ~1 min
names(res) <- names(modelos)
tabla <- do.call(rbind, lapply(res, `[[`, "ajuste"))
rownames(tabla) <- NULL
tabla
sapply(res, `[[`, "dif_cargas")                  # diferencia máxima en cargas estandarizadas
write.csv(tabla, file.path(dir_salida, "ajuste_listwise_vs_FIML.csv"), row.names = FALSE)
write.csv(do.call(rbind, lapply(res, `[[`, "cargas")),
          file.path(dir_salida, "cargas_listwise_vs_FIML.csv"), row.names = FALSE)

# Supuesto a discutir: FIML supone que los faltantes dependen solo de lo observado
# (MAR). Si en los 10 espacios sin bloque B la pregunta "no aplica", FIML estimaría
# calificaciones para un espacio que no se evaluó. Falta el cuestionario para saberlo.
