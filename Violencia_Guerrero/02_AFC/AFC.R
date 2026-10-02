# =============================================================================
# Libro SEM · Violencia Guerrero
# 02 - Análisis Factorial Confirmatorio (AFC)
# =============================================================================
# Sin script de referencia (ver 00_Exploracion). Se prueba el modelo que
# recupera el AFE (01_AFE): 12 factores correlacionados con los 46 ítems, cada
# ítem en un solo factor. Se estima con MLR y FIML sobre las 294 personas: con
# 46 ítems solo 160 están completas y el modelo tiene 158 parámetros, así que
# la eliminación por lista dejaría un caso por parámetro y sin las personas
# sin pareja (ver 07_FIML).
#   source("Violencia_Guerrero/02_AFC/AFC.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)
library(semPlot)

dir_salida <- "Violencia_Guerrero/02_AFC/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: las 294 personas
# -----------------------------------------------------------------------
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
items <- setdiff(names(guerrero), "folio")
nrow(guerrero)
sum(complete.cases(guerrero[, items]))     # solo 160 contestan los 46 ítems

# -----------------------------------------------------------------------
# Paso 2. AFC del modelo de 12 factores (MLR + FIML)
# -----------------------------------------------------------------------
# "=~" se lee "se mide por". Por defecto lavaan fija en 1 la carga del primer
# ítem de cada factor para darle escala, y deja que todos los factores
# correlacionen (como el AFE oblicuo). Los primeros seis factores son los
# dominios de la satisfacción con la vida (a1-a24) y los otros seis las
# percepciones sobre vecinos, autoridades, seguridad y gobierno (b, c, f).
modelo <- '
  pareja      =~ a1 + a2 + a3 + a4
  familia     =~ a5 + a6 + a7 + a8
  economia    =~ a9 + a10 + a11 + a12
  social      =~ a13 + a14 + a15 + a16
  personal    =~ a17 + a18 + a19 + a20
  trabajo     =~ a21 + a22 + a23 + a24
  cohesion    =~ b1 + b2 + b3 + b4 + b9
  confianza   =~ b10 + b11 + b12 + b13
  inseguridad =~ c4 + c5 + c6 + c7 + c8
  riesgo      =~ c11 + c12 + c13
  libertad    =~ c19 + c20
  desempeno   =~ f2 + f3 + f4'

# estimator = "MLR": máxima verosimilitud robusta (ver el paso 5);
# missing = "fiml": cada persona aporta con los ítems que sí contestó.
# Tarda alrededor de un minuto. summary() no pide fit.measures = TRUE porque
# con FIML y 46 ítems lavaan tarda más de 2 minutos en calcular las medidas
# robustas cada vez que se piden: se calculan una sola vez en el paso 3.
fit <- cfa(modelo, data = guerrero, estimator = "MLR", missing = "fiml")
summary(fit, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 3. Bondad de ajuste
# -----------------------------------------------------------------------
# Criterios usuales (Hu y Bentler, 1999): CFI y TLI >= 0.95 (aceptable
# >= 0.90), RMSEA <= 0.06 (aceptable <= 0.08), SRMR <= 0.08. Con MLR se
# reportan las versiones robustas (escaladas). Tarda un par de minutos.
medidas_fit <- fitMeasures(fit)
ajuste <- medidas_fit[c("chisq.scaled", "df", "pvalue.scaled", "cfi.robust",
                        "tli.robust", "rmsea.robust", "rmsea.ci.lower.robust",
                        "rmsea.ci.upper.robust", "srmr")]
round(ajuste, 3)

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas y correlaciones entre factores
# -----------------------------------------------------------------------
std <- standardizedSolution(fit)
cargas <- std[std$op == "=~", c("lhs", "rhs", "est.std", "se", "pvalue")]
names(cargas) <- c("factor", "item", "carga", "ee", "p")
cargas$r2 <- cargas$carga^2                  # varianza del ítem que explica el factor
print(cbind(cargas[, 1:2], round(cargas[, 3:6], 3)), row.names = FALSE)
range(cargas$carga)
all(cargas$p < .001)                         # todas significativas

# Cargas más bajas (las únicas menores que .70)
cargas[cargas$carga < .70, c("factor", "item", "carga")]

# Correlaciones entre los 12 factores
cor_factores <- lavInspect(fit, "cor.lv")
round(cor_factores, 2)
range(cor_factores[lower.tri(cor_factores)])
max(abs(cor_factores[lower.tri(cor_factores)]))   # la mayor, lejos de 1: no hay factores redundantes

# -----------------------------------------------------------------------
# Paso 5. Normalidad multivariada y estimador MLR
# -----------------------------------------------------------------------
# ML supone normalidad multivariada. Los ítems son escalas 1-10 con efecto
# techo o suelo (ver 00_Exploracion). La prueba de Mardia necesita datos
# completos: se hace con las 160 personas completas.
mardia(guerrero[complete.cases(guerrero[, items]), items], plot = FALSE)
# Se rechaza la normalidad, por eso MLR corrige la chi-cuadrada y los errores
# estándar (Yuan-Bentler). Con MLR lavaan reporta las dos versiones: el factor
# de escala dice cuánto infla la no normalidad a la chi-cuadrada estándar.
round(medidas_fit[c("chisq", "chisq.scaled", "chisq.scaling.factor",
                    "cfi", "cfi.robust", "rmsea", "rmsea.robust")], 3)

# -----------------------------------------------------------------------
# Paso 6. Modelos por instrumento
# -----------------------------------------------------------------------
# Los 12 factores salen de dos grupos de ítems que, por su numeración y su
# contenido, parecen dos secciones distintas del cuestionario: satisfacción con
# la vida (a1-a24) y violencia y clima social (b, c, f). Se ajusta cada uno
# por separado.
modelo_sat <- '
  pareja   =~ a1 + a2 + a3 + a4
  familia  =~ a5 + a6 + a7 + a8
  economia =~ a9 + a10 + a11 + a12
  social   =~ a13 + a14 + a15 + a16
  personal =~ a17 + a18 + a19 + a20
  trabajo  =~ a21 + a22 + a23 + a24'
modelo_vio <- '
  cohesion    =~ b1 + b2 + b3 + b4 + b9
  confianza   =~ b10 + b11 + b12 + b13
  inseguridad =~ c4 + c5 + c6 + c7 + c8
  riesgo      =~ c11 + c12 + c13
  libertad    =~ c19 + c20
  desempeno   =~ f2 + f3 + f4'
fit_sat <- cfa(modelo_sat, data = guerrero, estimator = "MLR", missing = "fiml")
fit_vio <- cfa(modelo_vio, data = guerrero, estimator = "MLR", missing = "fiml")

medidas <- c("ntotal", "npar", "chisq.scaled", "df", "cfi.robust", "tli.robust",
             "rmsea.robust", "srmr")
ajuste_modelos <- rbind(`12 factores` = medidas_fit[medidas],
                        `Satisfacción (6)` = fitMeasures(fit_sat, medidas),
                        `Violencia y clima (6)` = fitMeasures(fit_vio, medidas))
round(ajuste_modelos, 3)
# Los tres ajustan bien. Los de cada instrumento ajustan un poco mejor porque
# tienen menos ítems (el CFI cae al sumar ítems).

# -----------------------------------------------------------------------
# Paso 7. Sensibilidad: ¿y si los ítems se tratan como ordinales?
# -----------------------------------------------------------------------
# Tratar escalas de 10 puntos como continuas es un supuesto. Se repite cada
# instrumento como ordinal: WLSMV con correlaciones policóricas
# (missing = "pairwise" usa a cada persona en los pares que contestó). No hay
# FIML en WLSMV, así que esto es solo una verificación, no el modelo principal.
# (El modelo ordinal de los 12 factores a la vez tiene más de 500 parámetros
# con 294 personas y su matriz de varianzas queda singular; por eso se
# verifica por instrumento.)
ordinal <- function(modelo, fit_mlr) {
  fit_ord <- cfa(modelo, data = guerrero, ordered = lavNames(fit_mlr, "ov"),
                 estimator = "WLSMV", missing = "pairwise")
  a <- standardizedSolution(fit_mlr); a <- a$est.std[a$op == "=~"]
  b <- standardizedSolution(fit_ord); b <- b$est.std[b$op == "=~"]
  fm <- fitMeasures(fit_ord, c("cfi.scaled", "rmsea.scaled", "srmr"))
  c(cfi = fm[["cfi.scaled"]], rmsea = fm[["rmsea.scaled"]], srmr = fm[["srmr"]],
    carga_media_MLR = mean(a), carga_media_ordinal = mean(b),
    dif_media = mean(b - a), dif_max = max(abs(b - a)))
}
round(rbind(`Satisfacción (6)` = ordinal(modelo_sat, fit_sat),
            `Violencia y clima (6)` = ordinal(modelo_vio, fit_vio)), 3)
# Con el tratamiento ordinal el ajuste es igual o mejor y las cargas suben
# un poco (.02 a .03 en promedio): los ítems ordinales tienen menos atenuación.
# La estructura de factores es la misma.

# -----------------------------------------------------------------------
# Paso 8. Ajuste local: residuos e índices de modificación
# -----------------------------------------------------------------------
# Residuos de correlación (observada menos implicada por el modelo): cuántos
# superan |.10| y cuáles son los mayores. Con FIML la covarianza observada es
# la estimada por EM (lavInspect "sampstat"). Equivale a lavResiduals(fit,
# type = "cor.bollen"), que tarda más de un minuto.
S <- lavInspect(fit, "sampstat")$cov
Sigma <- fitted(fit)$cov
residuos <- cov2cor(S[rownames(Sigma), colnames(Sigma)]) - cov2cor(Sigma)
residuos[upper.tri(residuos, diag = TRUE)] <- NA
sum(abs(residuos) > .10, na.rm = TRUE)       # de 1,035 residuos
sum(!is.na(residuos))
round(max(abs(residuos), na.rm = TRUE), 3)
which(abs(residuos) == max(abs(residuos), na.rm = TRUE), arr.ind = TRUE)

# Índices de modificación: cuánto bajaría la chi-cuadrada si se liberara un
# parámetro (mi >= 10 llama la atención). Son para REVISAR el modelo, no para
# modificarlo a ciegas: se pierde la confirmación.
mi <- modindices(fit, sort. = TRUE, minimum.value = 10)
nrow(mi)
head(mi[, c("lhs", "op", "rhs", "mi", "epc")], 10)
# Los dos mayores están dentro del factor social: a13-a14 y a15-a16
# comparten más varianza de la que explica el factor, y entre los pares
# cruzados comparten menos. Se ve en las correlaciones: a13-a14 .76 y
# a15-a16 .77, contra .57-.60 entre pares.
round(cor(guerrero[, paste0("a", 13:16)], use = "pairwise.complete.obs"), 2)
round(cov2cor(fitted(fit)$cov[paste0("a", 13:16), paste0("a", 13:16)]), 2)
# a13-a14 (frecuencia y diversidad de actividades) y a15-a16 (tipo de
# personas y vida social en general) son pares de ítems de contenido más
# cercano. No se modifica el modelo: las cargas de social son .79-.82.

# -----------------------------------------------------------------------
# Paso 9. Guardar resultados y diagramas
# -----------------------------------------------------------------------
# cargas (=~) y correlaciones entre factores (~~ entre variables distintas)
sol <- std[std$op == "=~" | (std$op == "~~" & std$lhs != std$rhs), ]
write.csv(sol, file.path(dir_salida, "solucion_estandarizada_AFC.csv"), row.names = FALSE)
write.csv(round(ajuste_modelos, 3), file.path(dir_salida, "ajuste_modelos.csv"))
write.csv(round(cor_factores, 3), file.path(dir_salida, "correlaciones_factores_AFC.csv"))
write.csv(mi[, c("lhs", "op", "rhs", "mi", "epc")], file.path(dir_salida, "indices_modificacion.csv"), row.names = FALSE)

# Diagrama: layout = "circle" deja legibles las cargas. Se quitan las
# etiquetas de las correlaciones entre factores (están en la tabla): se
# dibujan solo como flechas dobles.
diagrama <- function(fit, archivo, ancho = 1600, alto = 900) {
  p <- semPaths(fit, whatLabels = "std", layout = "circle", residuals = FALSE,
                intercepts = FALSE, nCharNodes = 0, sizeMan = 5, sizeLat = 8,
                edge.label.cex = .9, DoNotPlot = TRUE)
  p$graphAttributes$Edges$labels[p$Edgelist$bidirectional] <- ""
  png(archivo, width = ancho, height = alto)
  plot(p)
  dev.off()
  plot(p)
}
diagrama(fit_sat, file.path(dir_salida, "diagrama_AFC_satisfaccion.png"))
diagrama(fit_vio, file.path(dir_salida, "diagrama_AFC_violencia_clima.png"))
