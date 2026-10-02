# =============================================================================
# Libro SEM · Violencia Guerrero
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# Misma secuencia que el AFE del Tren (KMO y Bartlett -> eigenvalores ->
# análisis paralelo -> AFE por máxima verosimilitud), con dos cambios que
# pide esta base (ver 00_Exploracion): se usa a las 294 personas con una
# matriz de correlaciones FIML (solo 160 contestan los 46 ítems) y una
# rotación oblicua (los factores correlacionan).
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("Violencia_Guerrero/01_AFE/AFE.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)    # lavCor: matriz de correlaciones con FIML
library(ggplot2)

dir_salida <- "Violencia_Guerrero/01_AFE/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Leer la base y calcular la matriz de correlaciones
# -----------------------------------------------------------------------
# 294 personas y 46 ítems (escalas de 1 a 10). El AFE de psych trabaja con
# una matriz de correlaciones.
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
items <- setdiff(names(guerrero), "folio")
x <- guerrero[, items]
n <- nrow(x)
n

# En el Tren se usaron solo los registros completos. Aquí serían 160 de 294
# (54%), así que en lugar de tirar casi la mitad de la muestra se estima la
# matriz con FIML: cada persona aporta con los ítems que sí contestó.
sum(complete.cases(x))
R <- as.matrix(lavCor(x, missing = "fiml", output = "cor"))

# Casi no difiere de la correlación por pares (diferencia media de unas
# centésimas; la mayor involucra a los ítems de pareja)
R_pares <- cor(x, use = "pairwise.complete.obs")
round(mean(abs(R - R_pares)[upper.tri(R)]), 4)
round(max(abs(R - R_pares)), 3)

# -----------------------------------------------------------------------
# Paso 2. ¿Tiene sentido factorizar? KMO y prueba de Bartlett
# -----------------------------------------------------------------------
# KMO > 0.8 indica buena adecuación muestral; cada ítem trae además su MSA
# individual (se revisan los menores de 0.70).
kmo <- KMO(R)
round(kmo$MSA, 3)
sort(round(kmo$MSAi, 3))[1:5]
# Bartlett: H0 = la matriz de correlaciones es la identidad. Con n = 294
# (aproximado: con datos faltantes el tamaño efectivo es algo menor).
cortest.bartlett(R, n = n)

# -----------------------------------------------------------------------
# Paso 3. Componentes principales: ¿cuántos factores podemos encontrar?
# -----------------------------------------------------------------------
# Los eigenvalores de la matriz de correlaciones son los de un análisis de
# componentes principales (como prcomp(scale. = TRUE) en el Tren).
eigenvalores <- eigen(R)$values
round(eigenvalores[1:15], 2)
sum(eigenvalores > 1)                         # criterio de Kaiser

varianza <- eigenvalores / sum(eigenvalores)  # varianza explicada
round(cumsum(varianza)[c(6, 12)], 3)          # acumulada con 6 y con 12 componentes

# -----------------------------------------------------------------------
# Paso 4. Análisis paralelo y gráfica de codo
# -----------------------------------------------------------------------
# fa.parallel() compara los eigenvalores observados con los de datos
# aleatorios del mismo tamaño (n.obs, número de ítems), 100 réplicas. Se
# retienen los que superan al percentil 95 de los simulados. fa = "both" hace
# la versión de componentes (como parallel() del Tren) y la de factores
# comunes, que es la que corresponde a un AFE. fa.parallel simula en varios
# núcleos y así ignora la semilla: con mc.cores = 1 el resultado se repite.
options(mc.cores = 1)
set.seed(2018)
ap <- fa.parallel(R, n.obs = n, fa = "both", fm = "ml", n.iter = 100,
                  quant = .95, plot = FALSE)
ap$ncomp                                      # componentes que superan al azar
ap$nfact                                      # factores que superan al azar

# Percentil 95 de los eigenvalores simulados (ap$values trae las 100
# réplicas: columnas C1-C46 de componentes y F1-F46 de factores). Ojo: ap$pc.sim
# es el promedio, no el percentil 95.
p95_comp <- apply(ap$values[, paste0("C", 1:ncol(x))], 2, quantile, probs = .95)
p95_fact <- apply(ap$values[, paste0("F", 1:ncol(x))], 2, quantile, probs = .95)

data <- rbind(
  data.frame(tipo = "Componentes principales", numero = 1:20,
             observado = ap$pc.values[1:20], paralelo = p95_comp[1:20]),
  data.frame(tipo = "Factores comunes", numero = 1:20,
             observado = ap$fa.values[1:20], paralelo = p95_fact[1:20]))
transform(data[data$numero %in% 7:14, ],
          observado = round(observado, 2), paralelo = round(paralelo, 2))

p <- ggplot(data, aes(x = numero, y = observado)) +
  geom_line(col = "red") + geom_point(col = "red", size = 1) +
  geom_line(aes(y = paralelo), col = "blue", linetype = 2) +
  geom_hline(data = data.frame(tipo = "Componentes principales", y = 1),
             aes(yintercept = y)) +
  facet_wrap(~ tipo, scales = "free_y") +
  labs(title = "Gráfica de codo y análisis paralelo (percentil 95)",
       x = "Número de componente o factor", y = "Eigenvalor")
p
ggsave(file.path(dir_salida, "grafica_codo.png"), p, width = 9, height = 5, dpi = 150)
# Rojo: observados. Azul punteado: percentil 95 de datos aleatorios. Línea
# negra: eigenvalor = 1 (criterio de Kaiser).

# -----------------------------------------------------------------------
# Paso 5. Comparar soluciones de 8 a 13 factores
# -----------------------------------------------------------------------
# Se ajusta el AFE por máxima verosimilitud (fm = "ml") con cada número de
# factores y se comparan RMSEA, TLI, SRMR y BIC. Además: la comunalidad mínima
# y cuántos ítems tienen comunalidad < .30 (ítems que los factores no
# explican), y cuántos factores no son el dominante de ningún ítem (factores
# "vacíos", sin interpretación posible).
ajuste_k <- t(sapply(8:13, function(k) {
  f <- fa(R, nfactors = k, n.obs = n, fm = "ml", rotate = "oblimin", max.iter = 5000)
  L <- unclass(f$loadings)
  c(factores = k, chi2 = f$STATISTIC, gl = f$dof, rmsea = f$RMSEA[["RMSEA"]],
    rmsea_inf = f$RMSEA[["lower"]], rmsea_sup = f$RMSEA[["upper"]],
    tli = f$TLI, srmr = f$rms, bic = f$BIC, comunalidad_min = min(f$communality),
    items_comun_menor_30 = sum(f$communality < .30),
    factores_vacios = k - length(unique(apply(abs(L), 1, which.max))))
}))
round(ajuste_k, 3)
write.csv(round(ajuste_k, 3), file.path(dir_salida, "comparacion_numero_factores.csv"), row.names = FALSE)
# El RMSEA y el TLI mejoran con cada factor y el BIC es mínimo con 11, pero
# con 11 hay 2 ítems sin explicar (c19 y c20, los de libertad, que no forman
# factor); con 12 aparece el factor de libertad y todos los ítems quedan
# explicados (comunalidad mínima .44); con 13 el factor adicional está vacío
# (ningún ítem carga en él >= .30). Con el criterio de Kaiser (12) y el
# análisis paralelo de factores (12), se elige 12.

# -----------------------------------------------------------------------
# Paso 6. AFE por máxima verosimilitud con rotación oblimin (12 factores)
# -----------------------------------------------------------------------
# fm = "ml" método de estimación; nfactors = número de factores; rotate =
# "oblimin" (oblicua): se permite que los factores correlacionen. En el Tren
# se usó varimax (ortogonal) porque lo pedía la referencia; aquí las
# correlaciones entre factores llegan a .49 (ver Phi), así que una rotación
# ortogonal las forzaría a cero y distorsionaría las cargas.
AF <- fa(r = R, nfactors = 12, n.obs = n, fm = "ml", rotate = "oblimin",
         min.err = 0.00001, max.iter = 5000)
AF
round(c(chi2 = AF$STATISTIC, gl = AF$dof, rmsea = AF$RMSEA[["RMSEA"]], tli = AF$TLI, srmr = AF$rms), 3)

cargas <- unclass(AF$loadings)    # matriz patrón (46 x 12)
AF$communality                    # comunalidades

# Correlaciones entre factores
round(AF$Phi, 2)
round(max(abs(AF$Phi[lower.tri(AF$Phi)])), 2)

# -----------------------------------------------------------------------
# Paso 7. Interpretación: ¿qué ítems forma cada factor?
# -----------------------------------------------------------------------
# Para cada ítem: factor donde carga más, esa carga y la segunda carga más
# alta (si fuera cercana, habría carga cruzada).
factores <- list(
  pareja      = c("a1", "a2", "a3", "a4"),
  familia     = c("a5", "a6", "a7", "a8"),
  economia    = c("a9", "a10", "a11", "a12"),
  social      = c("a13", "a14", "a15", "a16"),
  personal    = c("a17", "a18", "a19", "a20"),
  trabajo     = c("a21", "a22", "a23", "a24"),
  cohesion    = c("b1", "b2", "b3", "b4", "b9"),
  confianza   = c("b10", "b11", "b12", "b13"),
  inseguridad = c("c4", "c5", "c6", "c7", "c8"),
  riesgo      = c("c11", "c12", "c13"),
  libertad    = c("c19", "c20"),
  desempeno   = c("f2", "f3", "f4"))
bloque <- setNames(rep(names(factores), lengths(factores)), unlist(factores))
bloque <- bloque[items]

dominante <- apply(abs(cargas), 1, which.max)
table(bloque = bloque, factor = colnames(cargas)[dominante])    # un factor por bloque

# Los 12 factores coinciden uno a uno con los 12 bloques de contenido
# (ver 00_Exploracion): se les pone el nombre del bloque y se ordenan.
nombre_factor <- sapply(seq_len(ncol(cargas)), function(j)
  names(which.max(table(bloque[dominante == j]))))
anyDuplicated(nombre_factor)                                    # 0: ninguno repetido
colnames(cargas) <- nombre_factor
cargas <- cargas[, unique(bloque)]
Phi <- AF$Phi
dimnames(Phi) <- list(nombre_factor, nombre_factor)
Phi <- Phi[unique(bloque), unique(bloque)]

tabla <- data.frame(item = items, bloque = bloque,
                    carga = apply(abs(cargas), 1, max),
                    segunda_carga = apply(abs(cargas), 1, function(r) sort(r, decreasing = TRUE)[2]),
                    comunalidad = AF$communality[items])
tabla[, 3:5] <- round(tabla[, 3:5], 2)
print(tabla, row.names = FALSE)

# Criterios para depurar ítems: carga cruzada >= .30 o comunalidad < .30
sum(tabla$segunda_carga >= .30)
sum(tabla$comunalidad < .30)
tabla[order(tabla$comunalidad)[1:3], ]                          # los tres más débiles
# Los 46 ítems cargan en el factor de su bloque (>= .51), ninguno carga >= .30
# en otro y la comunalidad mínima es .44. No se elimina ningún ítem: el AFC
# (carpeta 02_AFC) se hace con los 46.

write.csv(data.frame(item = items, round(cargas, 3), comunalidad = round(AF$communality[items], 3)),
          file.path(dir_salida, "cargas_AFE.csv"), row.names = FALSE)
write.csv(round(Phi, 3), file.path(dir_salida, "correlaciones_factores_AFE.csv"))

# Mapa de las cargas (46 ítems x 12 factores)
cargas_larga <- as.data.frame(as.table(cargas))
names(cargas_larga) <- c("item", "factor", "carga")
cargas_larga$item <- factor(cargas_larga$item, levels = rev(items))
p_cargas <- ggplot(cargas_larga, aes(factor, item, fill = carga)) + geom_tile() +
  geom_text(aes(label = ifelse(abs(carga) >= .30, sprintf("%.2f", carga), "")), size = 2.3) +
  scale_fill_gradient2(low = "firebrick", mid = "white", high = "steelblue",
                       midpoint = 0, limits = c(-1, 1)) +
  labs(title = "Cargas del AFE (ML, oblimin, 12 factores)", x = NULL, y = NULL) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
p_cargas
ggsave(file.path(dir_salida, "mapa_cargas.png"), p_cargas, width = 8, height = 9, dpi = 150)
