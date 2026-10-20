# =============================================================================
# Libro SEM · EMOVI
# 05 - Puntajes factoriales: índice de riqueza del hogar de origen
# =============================================================================
# Referencia: la tesis (Anexo 2) obtiene el índice de riqueza (`ind_or`, de -1.389
# a 1.755) como puntaje de un CFA binario y lo compara con un índice por
# componentes principales (correlación .93). Aquí se calculan los puntajes de los
# tres factores y del factor general (segundo orden) y se hace la misma comparación.
#   source("EMOVI/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "EMOVI/05_Puntajes_Factoriales/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo de segundo orden (igual que en 03)
# -----------------------------------------------------------------------
emovi <- read.dta13("EMOVI/data/entrevistado_2023_CDMX.dta", convert.factors = FALSE)
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])
riqueza <- c(rango("p26", "a", "e"), rango("p29", "a", "g"), rango("p31", "a", "o"), rango("p32", "a", "o"))
for (v in riqueza) emovi[[v]] <- ifelse(emovi[[v]] == 1, 1, ifelse(emovi[[v]] == 2, 0, NA))

modelo <- '
  ESP =~ p29a + p29b + p29c + p29d + p29e + p29f + p26e + p31f + p31g + p32a
  BAS =~ p26a + p26c + p26d + p29g + p31a + p31b + p31c + p31d + p31e + p31m + p31o + p32e + p32f + p32h
  TEC =~ p31h + p31i + p31j + p31k + p31l
  RIQ =~ ESP + BAS + TEC'
items <- unlist(regmatches(modelo, gregexpr("p[0-9]+[a-o]", modelo)))
fit <- cfa(modelo, data = emovi, ordered = items, estimator = "WLSMV", missing = "pairwise")

# -----------------------------------------------------------------------
# Paso 2. Puntajes (EBM, el método de lavaan para ítems ordinales)
# -----------------------------------------------------------------------
# Con missing = "pairwise" cada entrevistado recibe puntaje aunque haya contestado
# NS en algún ítem: los 740.
puntajes <- as.data.frame(lavPredict(fit, method = "EBM"))
dim(puntajes)                                # 740 x 4 (ESP, BAS, TEC, RIQ)
colSums(is.na(puntajes))                     # 0
round(sapply(puntajes, function(x) c(media = mean(x), de = sd(x), min = min(x), max = max(x))), 2)
# Media cercana a 0 y desviación de .7 a .8: la escala es la de un factor con
# varianza 1, y el puntaje (que se encoge hacia la media) es menos variable.

# -----------------------------------------------------------------------
# Paso 3. Contra un índice simple y uno por componentes principales (como la tesis)
# -----------------------------------------------------------------------
X <- emovi[, items]
suma <- rowMeans(X, na.rm = TRUE)            # proporción de bienes que tenía el hogar
completos <- complete.cases(X)
pca <- prcomp(X[completos, ], scale. = TRUE)
cp1 <- pca$x[, 1] * sign(cor(pca$x[, 1], suma[completos]))   # el signo de un componente es arbitrario
comparacion <- data.frame(
  contra = c("Proporción de bienes (media de los 29 ítems)", "Primer componente principal (casos completos)"),
  r = round(c(cor(puntajes$RIQ, suma), cor(puntajes$RIQ[completos], cp1)), 3))
comparacion
# RIQ correlaciona .98 con la proporción de bienes y .98 con el PCA (la tesis: .93).
write.csv(comparacion, file.path(dir_salida, "comparacion_indices.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. ¿Tiene sentido el índice? Promedio por nivel educativo de los padres
# -----------------------------------------------------------------------
# El puntaje debe subir con la educación del padre (educp: 1 primaria o menos ...
# 4 profesional) y con la de la madre (educm).
round(tapply(puntajes$RIQ, emovi$educp, mean), 2)
round(tapply(puntajes$RIQ, emovi$educm, mean), 2)
# educp sube en cada nivel; educm sube hasta preparatoria (.64) y queda igual en
# profesional (.62, con solo 32 madres en esa categoría).

# -----------------------------------------------------------------------
# Paso 5. Guardar los puntajes con el folio del entrevistado
# -----------------------------------------------------------------------
salida <- data.frame(index = emovi$index, puntajes)
write.csv(salida, file.path(dir_salida, "puntajes_riqueza.csv"), row.names = FALSE)
head(salida)
