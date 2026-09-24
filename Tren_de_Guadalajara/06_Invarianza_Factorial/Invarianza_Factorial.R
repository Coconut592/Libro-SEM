# =============================================================================
# Libro SEM · Tren de Guadalajara
# 06 - Invarianza factorial (AFC multigrupo)
# =============================================================================
# Este ejercicio NO viene en los archivos de referencia (AFE_CFA.R, .inp,
# PDF). Se sigue la secuencia estándar de invarianza de medición
# (Meredith, 1993; Vandenberg y Lance, 2000; Chen, 2007): configural ->
# métrica -> escalar -> estricta.
#
# Grupo: el .dta no trae sexo, línea ni estación. La única agrupación que
# se puede construir es si el usuario respondió las preguntas de la
# tarjeta (p63/p64) o no. Limitaciones en el README de esta carpeta.
#   source("Tren_de_Guadalajara/06_Invarianza_Factorial/Invarianza_Factorial.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Tren_de_Guadalajara/06_Invarianza_Factorial/output"

# -----------------------------------------------------------------------
# Paso 1. Datos y variable de grupo
# -----------------------------------------------------------------------
tren <- read.dta13("Tren_de_Guadalajara/data/imsctren2006.dta")
tren$grupo <- ifelse(is.na(tren$p63) & is.na(tren$p64),
                     "No responde tarjeta", "Responde tarjeta")
table(tren$grupo)   # 104 y 202

# -----------------------------------------------------------------------
# Paso 2. Modelo: solo Acceso y Confort
# -----------------------------------------------------------------------
# El factor Tarjeta no se puede estimar en quien no respondió p63 ni p64,
# así que la invarianza se prueba en los otros dos factores. Se usan los
# 306 usuarios con FIML y MLR, como en Mplus (casi no hay faltantes en
# estos 8 ítems).
modelo <- 'acceso  =~ p4 + p5 + p61 + p62
           confort =~ p71 + p73 + p74 + p75'

# -----------------------------------------------------------------------
# Paso 3. Requisito: el modelo debe ajustar en cada grupo por separado
# -----------------------------------------------------------------------
medidas <- c("chisq.scaled", "df", "pvalue.scaled", "cfi.robust",
             "tli.robust", "rmsea.robust", "srmr")
por_grupo <- sapply(split(tren, tren$grupo), function(d)
  fitMeasures(sem(modelo, data = d, estimator = "MLR", missing = "fiml"), medidas))
round(por_grupo, 3)

# -----------------------------------------------------------------------
# Paso 4. Secuencia de modelos anidados
# -----------------------------------------------------------------------
# group = "grupo" estima el modelo en ambos grupos a la vez; group.equal
# agrega restricciones de igualdad entre grupos.
# a) Configural: misma estructura (mismos ítems en cada factor), todo libre
configural <- sem(modelo, data = tren, group = "grupo",
                  estimator = "MLR", missing = "fiml")
# b) Métrica (débil): cargas iguales -> los ítems se relacionan igual con el factor
metrica <- sem(modelo, data = tren, group = "grupo", estimator = "MLR",
               missing = "fiml", group.equal = "loadings")
# c) Escalar (fuerte): + interceptos iguales -> permite comparar medias latentes
escalar <- sem(modelo, data = tren, group = "grupo", estimator = "MLR",
               missing = "fiml", group.equal = c("loadings", "intercepts"))
# d) Estricta: + varianzas residuales iguales
estricta <- sem(modelo, data = tren, group = "grupo", estimator = "MLR",
                missing = "fiml", group.equal = c("loadings", "intercepts", "residuals"))

summary(configural, fit.measures = TRUE, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 5. Comparar los modelos
# -----------------------------------------------------------------------
# - Diferencia de chi-cuadrada escalada (Satorra-Bentler), por usar MLR.
# - Chen (2007): se acepta el nivel de invarianza si el CFI no baja más de
#   .010 y el RMSEA no sube más de .015 respecto al modelo anterior.
modelos <- list(configural = configural, metrica = metrica,
                escalar = escalar, estricta = estricta)
ajuste <- t(sapply(modelos, fitMeasures, medidas))
ajuste <- cbind(ajuste,
                delta_cfi   = c(NA, diff(ajuste[, "cfi.robust"])),
                delta_rmsea = c(NA, diff(ajuste[, "rmsea.robust"])))
round(ajuste, 3)

lavTestLRT(configural, metrica, escalar, estricta)

# -----------------------------------------------------------------------
# Paso 6. ¿Qué parámetro rompe la invarianza?
# -----------------------------------------------------------------------
# lavTestScore prueba liberar cada restricción de igualdad. Un valor grande
# de X2 indica el parámetro que difiere entre grupos.
# (Con MLR lavaan avisa que usa la prueba score ordinaria: es orientativa.)
prueba <- lavTestScore(escalar)$uni
restricciones <- parTable(escalar)[, c("plabel", "lhs", "op", "rhs")]
prueba$parametro <- with(restricciones[match(prueba$lhs, restricciones$plabel), ],
                         paste(lhs, op, rhs))
prueba[order(-prueba$X2), c("parametro", "X2", "df", "p.value")]

write.csv(round(ajuste, 3), file.path(dir_salida, "ajuste_invarianza.csv"))
