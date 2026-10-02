# =============================================================================
# Libro SEM · Violencia Guerrero
# 06 - Invarianza factorial (AFC multigrupo)
# =============================================================================
# Sin referencia propia. Se sigue la secuencia estándar de invarianza de
# medición (Meredith, 1993; Vandenberg y Lance, 2000; Chen, 2007): configural
# -> métrica -> escalar -> estricta, igual que en el Tren.
#
# Grupo: el .dta no trae sexo, edad ni municipio. La única agrupación que se
# puede construir es si la persona contestó los ítems de pareja (a1-a4) o no:
# "Con pareja" (223) contra "Sin pareja" (71). Es la misma idea que
# "responde tarjeta" en el Tren. Limitaciones en el README de esta carpeta.
#   source("Violencia_Guerrero/06_Invarianza_Factorial/Invarianza_Factorial.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Violencia_Guerrero/06_Invarianza_Factorial/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y variable de grupo
# -----------------------------------------------------------------------
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
sin_pareja <- rowSums(!is.na(guerrero[, paste0("a", 1:4)])) == 0
guerrero$grupo <- factor(ifelse(sin_pareja, "Sin pareja", "Con pareja"),
                         levels = c("Con pareja", "Sin pareja"))
table(guerrero$grupo)   # 223 y 71

# El primer nivel es el grupo de referencia: en el modelo escalar sus medias
# latentes valen 0 y las del otro grupo se estiman contra ellas.

# -----------------------------------------------------------------------
# Paso 2. Modelos: ¿cuáles se pueden probar?
# -----------------------------------------------------------------------
# El factor pareja no existe para quien no contestó a1-a4, así que se excluye.
# Con 71 personas en el grupo pequeño no todos los modelos son estimables
# (ver el paso 3), y se usan dos:
#   A. Satisfacción: cinco dominios (familia, economía, vida social, bienestar
#      personal y trabajo), 20 ítems.
#   B. Institucional: cohesión vecinal, confianza en las autoridades y
#      desempeño del gobierno, 12 ítems.
modelo_A <- '
  familia  =~ a5 + a6 + a7 + a8
  economia =~ a9 + a10 + a11 + a12
  social   =~ a13 + a14 + a15 + a16
  personal =~ a17 + a18 + a19 + a20
  trabajo  =~ a21 + a22 + a23 + a24'
modelo_B <- '
  cohesion  =~ b1 + b2 + b3 + b4 + b9
  confianza =~ b10 + b11 + b12 + b13
  desempeno =~ f2 + f3 + f4'

# -----------------------------------------------------------------------
# Paso 3. Requisito: el modelo debe ajustar en cada grupo por separado
# -----------------------------------------------------------------------
# Se usan los 294 con FIML y MLR (ver 02_AFC y 07_FIML).
medidas <- c("chisq.scaled", "df", "pvalue.scaled", "cfi.robust",
             "tli.robust", "rmsea.robust", "srmr")
por_grupo <- function(modelo) {
  t(sapply(split(guerrero, guerrero$grupo), function(d)
    c(n = nrow(d), fitMeasures(cfa(modelo, data = d, estimator = "MLR", missing = "fiml"), medidas))))
}
round(por_grupo(modelo_A), 3)
round(por_grupo(modelo_B), 3)
# En "Con pareja" ajustan bien los dos. En "Sin pareja" (71 personas) el
# modelo B ajusta bien (CFI .94) y el A de forma marginal (CFI .90, RMSEA .10).

# El modelo de los seis factores de violencia y clima NO se puede probar:
# en el grupo "Sin pareja" la solución es inadmisible (varianzas negativas).
# Los avisos de lavaan (matriz de varianzas no definida positiva, varianzas
# negativas) son justamente el diagnóstico.
modelo_C <- '
  cohesion    =~ b1 + b2 + b3 + b4 + b9
  confianza   =~ b10 + b11 + b12 + b13
  inseguridad =~ c4 + c5 + c6 + c7 + c8
  riesgo      =~ c11 + c12 + c13
  libertad    =~ c19 + c20
  desempeno   =~ f2 + f3 + f4'
fit_C_sin <- cfa(modelo_C, data = guerrero[guerrero$grupo == "Sin pareja", ],
                 estimator = "MLR", missing = "fiml")
lavInspect(fit_C_sin, "post.check")   # FALSE: solución inadmisible

# -----------------------------------------------------------------------
# Paso 4. Secuencia de modelos anidados
# -----------------------------------------------------------------------
# group = "grupo" estima el modelo en ambos grupos a la vez; group.equal
# agrega restricciones de igualdad entre grupos.
#   configural: misma estructura (mismos ítems en cada factor), todo libre
#   métrica (débil): cargas iguales
#   escalar (fuerte): + interceptos iguales -> permite comparar medias latentes
#   estricta: + varianzas residuales iguales
secuencia <- function(modelo) {
  ajustar <- function(...) cfa(modelo, data = guerrero, group = "grupo",
                               estimator = "MLR", missing = "fiml", ...)
  list(configural = ajustar(),
       metrica    = ajustar(group.equal = "loadings"),
       escalar    = ajustar(group.equal = c("loadings", "intercepts")),
       estricta   = ajustar(group.equal = c("loadings", "intercepts", "residuals")))
}
mod_A <- secuencia(modelo_A)
mod_B <- secuencia(modelo_B)
summary(mod_A$configural, fit.measures = TRUE, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 5. Comparar los modelos
# -----------------------------------------------------------------------
# - Diferencia de chi-cuadrada escalada (Satorra-Bentler), por usar MLR.
# - Chen (2007): se acepta el nivel de invarianza si el CFI no baja más de
#   .010 y el RMSEA no sube más de .015 respecto al modelo anterior.
comparar <- function(modelos) {
  ajuste <- t(sapply(modelos, fitMeasures, medidas))
  cbind(ajuste,
        delta_cfi   = c(NA, diff(ajuste[, "cfi.robust"])),
        delta_rmsea = c(NA, diff(ajuste[, "rmsea.robust"])),
        delta_srmr  = c(NA, diff(ajuste[, "srmr"])))
}
ajuste_A <- comparar(mod_A)
ajuste_B <- comparar(mod_B)
round(ajuste_A, 3)
lavTestLRT(mod_A$configural, mod_A$metrica, mod_A$escalar, mod_A$estricta)
round(ajuste_B, 3)
lavTestLRT(mod_B$configural, mod_B$metrica, mod_B$escalar, mod_B$estricta)

# -----------------------------------------------------------------------
# Paso 6. ¿Qué parámetro rompe la invarianza?
# -----------------------------------------------------------------------
# lavTestScore prueba liberar cada restricción de igualdad. Un valor grande
# de X2 indica el parámetro que difiere entre grupos. Se aplica al modelo
# estricto del modelo A (el único nivel que no se sostiene).
# (Con MLR lavaan avisa que usa la prueba score ordinaria: es orientativa.)
prueba <- lavTestScore(mod_A$estricta)$uni
restricciones <- parTable(mod_A$estricta)[, c("plabel", "lhs", "op", "rhs")]
prueba$parametro <- with(restricciones[match(prueba$lhs, restricciones$plabel), ],
                         paste(lhs, op, rhs))
head(prueba[order(-prueba$X2), c("parametro", "X2", "df", "p.value")], 8)

# -----------------------------------------------------------------------
# Paso 7. Medias latentes: la razón de ser de la invarianza escalar
# -----------------------------------------------------------------------
# Si los ítems miden igual en los dos grupos (invarianza escalar), se pueden
# comparar las medias latentes. En el modelo escalar las del grupo de
# referencia ("Con pareja") valen 0 y las de "Sin pareja" se estiman contra
# ellas. La diferencia se expresa también en desviaciones estándar del factor
# del grupo de referencia.
medias_latentes <- function(escalar) {
  pe <- parameterEstimates(escalar)
  m <- pe[pe$op == "~1" & pe$lhs %in% lavNames(escalar, "lv") & pe$group == 2,
          c("lhs", "est", "se", "z", "pvalue")]
  psi_ref <- diag(lavInspect(escalar, "est")[[1]]$psi)
  m$d <- m$est / sqrt(psi_ref[m$lhs])
  names(m)[1] <- "factor"
  m
}
meds_A <- medias_latentes(mod_A$escalar)
meds_B <- medias_latentes(mod_B$escalar)
print(cbind(meds_A[1], round(meds_A[-1], 3)), row.names = FALSE)
print(cbind(meds_B[1], round(meds_B[-1], 3)), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 8. Guardar resultados
# -----------------------------------------------------------------------
write.csv(round(ajuste_A, 3), file.path(dir_salida, "ajuste_invarianza_satisfaccion.csv"))
write.csv(round(ajuste_B, 3), file.path(dir_salida, "ajuste_invarianza_institucional.csv"))
write.csv(rbind(cbind(modelo = "Satisfaccion", meds_A), cbind(modelo = "Institucional", meds_B)),
          file.path(dir_salida, "medias_latentes_sin_vs_con_pareja.csv"), row.names = FALSE)
