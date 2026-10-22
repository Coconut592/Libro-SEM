# =============================================================================
# Libro SEM · Violencia Veracruz
# 05 - Puntajes factoriales: los seis ámbitos y la violencia general
# =============================================================================
# Sin referencia propia. Se sigue EMOVI (ítems 0/1): puntajes EBM (empirical Bayes
# modal, el método de lavaan para ítems ordinales) de los seis ámbitos y del
# factor general (segundo orden), su determinación y una comparación con un
# índice simple (el conteo de hechos de violencia) y con la clase latente c_r.
# Los puntajes en "escala original" de los demás proyectos no aplican: con ítems 0/1
# no hay un ítem marcador cuyos puntos sirvan de escala.
#   source("Violencia_Veracruz/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Violencia_Veracruz/05_Puntajes_Factoriales/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo de segundo orden (igual que en 03)
# -----------------------------------------------------------------------
vera <- read.dta13("Violencia_Veracruz/data/BASE_ACLnew.dta", convert.factors = FALSE)
factores <- list(
  INF = c("p141", "p142", "p143", "p144"),
  FAM = c("p161", "p162", "p165"),
  PAR = c("p171", "p172", "p173", "p175", "p176"),
  TRA = c("p183", "p184", "p185", "p186"),
  COM = c("p191", "p192", "p193", "p194"),
  ESC = c("p201", "p202", "p203", "p204"))
items <- unlist(factores, use.names = FALSE)
vera <- vera[rowSums(!is.na(vera[, items])) > 0, ]    # 1,088 mujeres
modelo <- paste(c(sapply(names(factores), function(f) paste(f, "=~", paste(factores[[f]], collapse = " + "))),
                  "VIO =~ INF + FAM + PAR + TRA + COM + ESC"), collapse = "\n")
fit <- cfa(modelo, data = vera, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit, "converged")                 # TRUE

# -----------------------------------------------------------------------
# Paso 2. Puntajes (EBM)
# -----------------------------------------------------------------------
# Con missing = "pairwise" cada mujer recibe puntaje aunque se haya saltado un bloque.
# PERO quien no contestó NINGÚN ítem de un ámbito no tiene información para ese ámbito:
# el EBM le asignaría un valor apoyándose solo en los otros ámbitos. Se deja en NA.
# La violencia general (VIO) la tienen todas, porque se apoya en los ámbitos contestados.
puntajes <- as.data.frame(lavPredict(fit, method = "EBM"))[, c("INF", "FAM", "PAR", "TRA", "COM", "ESC", "VIO")]
sin_datos <- sapply(factores, function(it) rowSums(!is.na(vera[, it])) == 0)
colSums(sin_datos)                           # 0 infancia, 5 familia, 313 pareja, 249 trabajo, 7 comunidad, 57 escuela
for (f in names(factores)) puntajes[sin_datos[, f], f] <- NA
dim(puntajes)                                # 1,088 x 7
colSums(is.na(puntajes))
descriptivos <- t(sapply(puntajes, function(x) c(N = sum(!is.na(x)), media = mean(x, na.rm = TRUE),
                                                 de = sd(x, na.rm = TRUE), min = min(x, na.rm = TRUE),
                                                 max = max(x, na.rm = TRUE))))
round(descriptivos, 2)
# Medias de .17 a .23 (no 0), desviaciones de .40 a .59 y máximos de 1.9 a 2.3. El EBM da la moda de
# la posterior y la distribución es muy asimétrica (35% de las mujeres no reporta nada): la media queda
# arriba de 0, y el puntaje, que se encoge hacia la moda, es menos variable que un factor de varianza 1.
write.csv(round(descriptivos, 3), file.path(dir_salida, "descriptivos_puntajes.csv"))

# -----------------------------------------------------------------------
# Paso 3. Determinación de los puntajes (FSDETERMINACY)
# -----------------------------------------------------------------------
# Correlación entre el puntaje y el factor verdadero, para quien contestó todos los ítems:
#   rho² = diag(C' Σ⁻¹ C) / var(factor),  C = covarianza de cada ítem con el factor.
# Se calcula con las covarianzas implicadas por el modelo (sobre las respuestas latentes), que
# valen para el puntaje lineal de regresión; para el EBM es una aproximación. >= .90 es lo que se pide.
L1 <- lavInspect(fit, "est")$lambda[items, names(factores)]       # cargas de primer orden
cov_lv <- lavInspect(fit, "cov.lv")[c(names(factores), "VIO"), c(names(factores), "VIO")]
Sigma <- lavInspect(fit, "implied")$cov[items, items]
C <- L1 %*% cov_lv[names(factores), ]                              # covarianza ítem-factor (24 x 7)
determinacion <- sqrt(diag(t(C) %*% solve(Sigma) %*% C) / diag(cov_lv))
round(determinacion, 3)
# De .90 (VIO) a .98 (INF): INF .981, PAR .974, FAM .969, ESC .962, COM .937, TRA .936 y VIO .903. Todos
# pasan de .90, VIO apenas (es el único que depende de los seis ámbitos a la vez).
write.csv(data.frame(factor = names(determinacion), determinacion = round(determinacion, 3)),
          file.path(dir_salida, "determinacion_puntajes.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Contra un índice simple: el conteo de hechos de violencia
# -----------------------------------------------------------------------
n_si <- rowSums(vera[, items], na.rm = TRUE)                       # cuántos de los 24 hechos reporta
prop_si <- rowMeans(vera[, items], na.rm = TRUE)                   # proporción de los que contestó
comparacion <- data.frame(
  contra = c("Conteo de hechos (Sí) de los 24 ítems", "Proporción de Sí entre los ítems contestados"),
  spearman = round(c(cor(puntajes$VIO, n_si, method = "spearman"), cor(puntajes$VIO, prop_si, method = "spearman")), 3),
  pearson = round(c(cor(puntajes$VIO, n_si), cor(puntajes$VIO, prop_si)), 3))
comparacion
# VIO correlaciona .955 (Pearson) y .96 (Spearman) con el conteo de hechos y casi igual con la proporción.
# El puntaje se parece mucho al conteo, pero pesa distinto: un hecho raro (p184) cuenta más que uno
# frecuente (p141) y no castiga a quien se saltó bloques.
write.csv(comparacion, file.path(dir_salida, "comparacion_indices.csv"), row.names = FALSE)

# Qué tanto se repiten los puntajes: ¿cuántas mujeres comparten el mismo?
sin_hechos <- n_si == 0
c(mujeres_sin_ningun_hecho = sum(sin_hechos), pct = round(100 * mean(sin_hechos), 1),
  patrones_de_respuesta = nrow(unique(vera[, items])),
  puntajes_distintos_VIO = length(unique(round(puntajes$VIO, 6))))
# Hay 507 patrones de respuesta distintos en las 1,088 mujeres (el puntaje es una función del patrón).
# 384 mujeres (35.3%) no reportan ningún hecho y casi comparten el mismo puntaje (-0.23 a -0.14, según
# los bloques que se saltaron): en la parte baja la escala no distingue (efecto suelo). El puntaje
# separa a las que sí reportan, no a las que no.
round(tapply(puntajes$VIO, sin_hechos, summary)[["TRUE"]], 2)

# -----------------------------------------------------------------------
# Paso 5. ¿Tiene sentido el puntaje? Promedio por clase latente y por escolaridad
# -----------------------------------------------------------------------
round(tapply(puntajes$VIO, vera$c_r, mean), 2)       # clase 1: -0.05, clase 2: 0.43, clase 3: 0.82
round(cor(puntajes$VIO, vera$c_r, method = "spearman"), 2)   # .78 (no es independiente: c_r sale de los mismos ítems)
round(tapply(puntajes$VIO, vera$p4, mean), 2)        # baja con la escolaridad: .29, .26, .18, .13 y .03 (1 ninguna ... 5 universidad)

# -----------------------------------------------------------------------
# Paso 6. Guardar los puntajes con el id de la mujer
# -----------------------------------------------------------------------
salida <- data.frame(id = vera$id, c_r = vera$c_r, round(puntajes, 4))
write.csv(salida, file.path(dir_salida, "puntajes_violencia.csv"), row.names = FALSE)
head(salida)
