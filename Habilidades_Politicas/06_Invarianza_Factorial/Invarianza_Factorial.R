# =============================================================================
# Libro SEM · Habilidades Políticas
# 06 - Invarianza factorial por género (AFC multigrupo)
# =============================================================================
# Este ejercicio NO viene en el capítulo ni en la presentación. Se sigue la
# secuencia estándar (Meredith, 1993; Vandenberg y Lance, 2000; Chen, 2007):
# configural -> métrica -> escalar -> estricta. A diferencia de los demás
# proyectos, aquí SÍ hay una variable de grupo sustantiva: Genero (161 hombres
# y 195 mujeres, según el capítulo). Se prueba (a) el modelo de cuatro
# factores y (b) el de segundo orden, que es el del capítulo.
#   source("Habilidades_Politicas/06_Invarianza_Factorial/Invarianza_Factorial.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Habilidades_Politicas/06_Invarianza_Factorial/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y variable de grupo
# -----------------------------------------------------------------------
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
# El .dta no trae etiquetas de valor. El capítulo reporta 161 hombres y 195
# mujeres, y la base trae 161 con 1 y 195 con 2: 1 = hombre, 2 = mujer.
hp$sexo <- factor(hp$Genero, levels = 1:2, labels = c("Hombre", "Mujer"))
table(hp$sexo)
# lavaan numera los grupos en el orden en que aparecen en los datos (no por
# los niveles del factor); la base empieza con una mujer. Se ordena para que
# el grupo 1 (referencia, media latente 0) sean los hombres y el 2 las mujeres.
hp <- hp[order(hp$sexo), ]

modelo_1er <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18'
modelo_2do <- paste(modelo_1er, 'HP =~ HR + SA + AS + II', sep = "\n")

# MLR por la no normalidad (ver 02_AFC). Los ítems son completos, así que
# FIML no cambiaría nada.
medidas <- c("chisq.scaled", "df", "pvalue.scaled", "cfi.robust", "tli.robust",
             "rmsea.robust", "srmr")

# -----------------------------------------------------------------------
# Paso 2. Requisito: el modelo debe ajustar en cada grupo por separado
# -----------------------------------------------------------------------
por_grupo <- sapply(split(hp, hp$sexo), function(d)
  fitMeasures(suppressWarnings(cfa(modelo_1er, data = d, estimator = "MLR")), medidas))
round(por_grupo, 3)
# El ajuste dentro de cada grupo es peor que con los 356 juntos (CFI .89 y
# .90, RMSEA .097 y .090 con MLR; con ML, CFI .87-.88 y RMSEA .10-.11): el
# modelo no ajusta del todo bien en ninguno de los dos. La secuencia de
# invarianza parte de un modelo configural de ajuste mediocre.
# Correlaciones entre factores en cada grupo
for (g in levels(hp$sexo))
  print(round(lavInspect(suppressWarnings(cfa(modelo_1er, data = hp[hp$sexo == g, ])),
                         "cor.lv"), 3))
# ADVERTENCIA: en los hombres la correlación SA-AS estimada es 1.05 (mayor
# que 1: solución inadmisible, lavaan avisa que la matriz de los factores no
# es definida positiva); en las mujeres es .68. En los hombres, SA y AS son
# indistinguibles.

# -----------------------------------------------------------------------
# Paso 3. Secuencia de modelos anidados (cuatro factores)
# -----------------------------------------------------------------------
# group.equal agrega restricciones de igualdad entre grupos.
secuencia <- function(modelo, estimador) {
  ajustar <- function(...) suppressWarnings(cfa(modelo, data = hp, group = "sexo",
                                                estimator = estimador, ...))
  list(configural = ajustar(),
       metrica    = ajustar(group.equal = "loadings"),
       escalar    = ajustar(group.equal = c("loadings", "intercepts")),
       estricta   = ajustar(group.equal = c("loadings", "intercepts", "residuals")))
}
modelos <- secuencia(modelo_1er, "MLR")
lavInspect(modelos$configural, "group.label")   # "Hombre" "Mujer": grupo 1 = hombres
stopifnot(identical(lavInspect(modelos$configural, "group.label"), c("Hombre", "Mujer")))

# -----------------------------------------------------------------------
# Paso 4. Comparar los modelos
# -----------------------------------------------------------------------
# - Diferencia de chi-cuadrada escalada (Satorra-Bentler), por usar MLR.
# - Chen (2007): se acepta el nivel de invarianza si el CFI no baja más de
#   .010 (.005 con muestras chicas o desiguales, como estas) y el RMSEA no
#   sube más de .015 respecto al modelo anterior.
tabla_ajuste <- function(modelos, med = medidas) {
  ajuste <- t(sapply(modelos, fitMeasures, med))
  cfi <- grep("^cfi", colnames(ajuste), value = TRUE)
  rmsea <- grep("^rmsea", colnames(ajuste), value = TRUE)
  cbind(ajuste,
        delta_cfi   = c(NA, diff(ajuste[, cfi])),
        delta_rmsea = c(NA, diff(ajuste[, rmsea])))
}
ajuste <- tabla_ajuste(modelos)
round(ajuste, 3)
lavTestLRT(modelos$configural, modelos$metrica, modelos$escalar, modelos$estricta,
           method = "satorra.bentler.2001")
# Métrica: Delta chi2 = 12.0 (11 gl), p = .36; escalar: 16.7 (11 gl), p = .12;
# estricta: 21.3 (15 gl), p = .13. ΔCFI nunca pasa de -.004 y el RMSEA baja.
# Se sostienen todos los niveles, incluida la estricta.
# Con ML (sin corrección) la estricta se rechaza (Delta chi2 = 31.2, 15 gl,
# p = .008; ΔCFI = -.007): el resultado depende del estimador. Se reporta MLR,
# que es el apropiado con estos datos no normales.
modelos_ml <- secuencia(modelo_1er, "ML")
ajuste_ml <- tabla_ajuste(modelos_ml, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr"))
round(ajuste_ml[, c("chisq", "df", "cfi", "rmsea", "delta_cfi")], 3)
lavTestLRT(modelos_ml$configural, modelos_ml$metrica, modelos_ml$escalar,
           modelos_ml$estricta)

# -----------------------------------------------------------------------
# Paso 5. Diferencias en las medias latentes (modelo escalar)
# -----------------------------------------------------------------------
# Con invarianza escalar se pueden comparar las medias de los factores: la de
# los hombres se fija en 0 y la de las mujeres se estima.
pe <- parameterEstimates(modelos$escalar)
medias <- pe[pe$op == "~1" & pe$lhs %in% c("HR", "SA", "AS", "II") & pe$group == 2,
             c("lhs", "est", "se", "z", "pvalue")]
medias
# d aproximada = diferencia de medias entre la desviación típica del factor
# en los hombres
vars_h <- diag(lavInspect(modelos$escalar, "cov.lv")[["Hombre"]])
medias$d <- medias$est / sqrt(vars_h[medias$lhs])
round(medias[, -1], 3)
# Las mujeres puntúan más en SA (+.31 en la escala del factor, p = .012,
# d = .30) y no difieren en HR (d = .03), AS (.16) ni II (.08). Con una
# corrección de Bonferroni por 4 comparaciones, SA queda en p = .048.

# -----------------------------------------------------------------------
# Paso 6. Invarianza del modelo de segundo orden (el del capítulo)
# -----------------------------------------------------------------------
# Secuencia (Chen, Sousa y West, 2005):
#  1 configural
#  2 cargas de primer orden iguales
#  3 + cargas de segundo orden iguales
#  4 + interceptos de los ítems iguales
#  5 + interceptos de las dimensiones iguales (la media de HP queda libre en
#      mujeres: así se estima la diferencia en HP)
#  6 + varianzas residuales de los ítems iguales
#  7 + varianzas residuales de las dimensiones (disturbios) iguales
# En lavaan, "loadings" incluye las cargas de segundo orden; para separar el
# paso 2 se liberan con group.partial.
ajustar2 <- function(modelo = modelo_2do, ...)
  suppressWarnings(cfa(modelo, data = hp, group = "sexo", estimator = "MLR", ...))
libres_2do <- c("HP =~ SA", "HP =~ AS", "HP =~ II")
# Para el paso 5 se fijan en 0 los interceptos de las dimensiones en los dos
# grupos y se libera solo el de HP en mujeres.
modelo_int2 <- paste(modelo_2do,
                     "HR ~ 0*1; SA ~ 0*1; AS ~ 0*1; II ~ 0*1; HP ~ c(0, NA)*1", sep = "\n")
modelos2 <- list(
  `1 configural`            = ajustar2(),
  `2 cargas 1er orden`      = ajustar2(group.equal = "loadings", group.partial = libres_2do),
  `3 + cargas 2do orden`    = ajustar2(group.equal = "loadings"),
  `4 + interceptos ítems`   = ajustar2(group.equal = c("loadings", "intercepts")),
  `5 + interceptos dimens.` = ajustar2(modelo_int2, group.equal = c("loadings", "intercepts")),
  `6 + residuos ítems`      = ajustar2(modelo_int2, group.equal = c("loadings", "intercepts", "residuals")),
  `7 + disturbios`          = ajustar2(modelo_int2, group.equal = c("loadings", "intercepts",
                                                                    "residuals", "lv.variances")))
ajuste2 <- tabla_ajuste(modelos2)
round(ajuste2, 3)
lavTestLRT(modelos2[[1]], modelos2[[2]], modelos2[[3]], modelos2[[4]], modelos2[[5]],
           modelos2[[6]], modelos2[[7]], method = "satorra.bentler.2001")
# Por los índices se sostienen los siete niveles: ΔCFI de 0 a -.003 y
# ΔRMSEA <= .001 en cada paso. Por la chi-cuadrada, solo el paso 3 (cargas de
# segundo orden iguales) se rechaza: Delta chi2 = 9.4, 3 gl, p = .025; los
# demás tienen p de .07 a .41.
# ¿Qué carga rompe el paso 3? La prueba score del modelo del paso 3:
prueba <- suppressWarnings(lavTestScore(modelos2[[3]])$uni)
restricciones <- parTable(modelos2[[3]])[, c("plabel", "lhs", "op", "rhs")]
prueba$parametro <- with(restricciones[match(prueba$lhs, restricciones$plabel), ],
                         paste(lhs, op, rhs))
head(prueba[order(-prueba$X2), c("parametro", "X2", "df", "p.value")], 4)
# HP =~ SA (X2 = 6.9, p = .009) y HP =~ II (6.3, p = .012), junto a SA9.
# Cargas de segundo orden estandarizadas en el modelo configural, por grupo:
std_conf2 <- standardizedSolution(modelos2[[1]])
std_conf2[std_conf2$lhs == "HP" & std_conf2$op == "=~", c("group", "rhs", "est.std", "se")]
# En los hombres SA carga 1.07 en HP (más de 1: solución impropia) y en las
# mujeres .79; II carga .77 en hombres y .82 en mujeres. HP "es" SA en los
# hombres.

# Diferencia en HP (modelo del paso 5: interceptos de las dimensiones iguales)
pe2 <- parameterEstimates(modelos2[[5]])
pe2[pe2$op == "~1" & pe2$lhs == "HP" & pe2$group == 2, c("lhs", "est", "se", "z", "pvalue")]
# Las mujeres puntúan +.135 más en HP (E.E. .085, p = .11). Equivale a
# d = .17 (la desviación típica de HP en hombres es .78): diferencia pequeña y
# no significativa.
sqrt(lavInspect(modelos2[[5]], "cov.lv")[["Hombre"]]["HP", "HP"])

# Disturbios por grupo en el modelo configural: ¿hay varianzas negativas?
std_conf <- standardizedSolution(modelos2[[1]])
std_conf[std_conf$op == "~~" & std_conf$lhs == std_conf$rhs &
           std_conf$lhs %in% c("HR", "SA", "AS", "II"), c("group", "lhs", "est.std")]
# En los hombres el disturbio de SA es NEGATIVO (-.15): caso Heywood. SA queda
# totalmente explicada por HP y la solución es impropia; el de AS es .04. En
# las mujeres todos los disturbios son positivos (.17 a .38).

# -----------------------------------------------------------------------
# Paso 7. Guardar resultados
# -----------------------------------------------------------------------
write.csv(round(ajuste, 3), file.path(dir_salida, "ajuste_invarianza_4_factores.csv"))
write.csv(round(ajuste2, 3), file.path(dir_salida, "ajuste_invarianza_2do_orden.csv"))
medias[, -1] <- round(medias[, -1], 3)
write.csv(medias, file.path(dir_salida, "medias_latentes_mujeres.csv"), row.names = FALSE)
