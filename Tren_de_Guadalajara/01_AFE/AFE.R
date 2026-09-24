# =============================================================================
# Libro SEM · Tren de Guadalajara
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# Referencias: AFE_CFA.R (primer ejemplo) y SEM02_Ejemplo_AFE-AFC.pdf.
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("Tren_de_Guadalajara/01_AFE/AFE.R")
# =============================================================================

library(readstata13)
library(psych)
library(nFactors)
library(ggplot2)

dir_salida <- "Tren_de_Guadalajara/01_AFE/output"

# -----------------------------------------------------------------------
# Paso 1. Leer la base y quedarse con registros completos
# -----------------------------------------------------------------------
# read.dta13 lee el archivo de Stata. La base tiene 306 usuarios y 13
# columnas: id y los 12 ítems de satisfacción (escala 1 a 10).
tren <- read.dta13("Tren_de_Guadalajara/data/imsctren2006.dta")
head(tren)
colSums(is.na(tren))   # p63 y p64 (tarjeta) concentran los faltantes

# Igual que en la referencia, se usan únicamente registros completos
# (complete.cases): quedan 170 usuarios. El uso de todos los casos con
# FIML se trabaja en la carpeta 06_FIML.
tren <- tren[complete.cases(tren), ]
nrow(tren)             # 170

# -----------------------------------------------------------------------
# Paso 2. ¿Tiene sentido factorizar? KMO y prueba de Bartlett
# -----------------------------------------------------------------------
# KMO > 0.8 indica que las correlaciones parciales son pequeñas frente a
# las correlaciones totales (buena adecuación muestral).
KMO(tren[, -1])
# Bartlett: H0 = la matriz de correlaciones es la identidad. Rechazarla
# indica que los ítems están correlacionados y se pueden agrupar.
cortest.bartlett(cor(tren[, -1]), n = nrow(tren))

# -----------------------------------------------------------------------
# Paso 3. Componentes principales: ¿cuántos factores podemos encontrar?
# -----------------------------------------------------------------------
componentes_principales <- prcomp(tren[, -1], scale. = TRUE)  # scale.=T estandariza las variables
eigenvalores <- (componentes_principales$sdev)^2
eigenvalores                                  # criterio de Kaiser: eigenvalores > 1

varianza <- eigenvalores / sum(eigenvalores)  # varianza explicada
varianza_acumulada <- cumsum(varianza)        # varianza acumulada
round(varianza_acumulada, 3)

# -----------------------------------------------------------------------
# Paso 4. Análisis paralelo y gráfica de codo
# -----------------------------------------------------------------------
# parallel() simula matrices de correlación de datos aleatorios con el
# mismo número de sujetos (subject) y variables (var); rep = réplicas,
# cent = percentil de la distribución de eigenvalores. Se retienen los
# factores cuyo eigenvalor observado supera al simulado.
set.seed(2006)
ap <- parallel(subject = nrow(tren),
               var = ncol(tren[, -1]), rep = 100, cent = .05)

data <- data.frame(numero_componentes = seq(1, ncol(tren[, -1])),
                   eigenvalores = eigenvalores, paralelo = ap$eigen$qevpea)
data

p <- ggplot(data, aes(x = numero_componentes, y = eigenvalores)) +
  geom_line(col = "red") + labs(title = "Gráfica de codo")
p <- p + geom_hline(yintercept = 1) +
  geom_line(aes(y = paralelo), col = "blue", linetype = 2)
p <- p + annotate("text", x = 3, y = 1, label = "Punto Corte")
p
ggsave(file.path(dir_salida, "grafica_codo.png"), p, width = 7, height = 5, dpi = 150)

# -----------------------------------------------------------------------
# Paso 5. AFE por máxima verosimilitud con rotación varimax
# -----------------------------------------------------------------------
# fm = "ml" método de estimación; nfactors = número de factores;
# residuals = TRUE muestra los residuales; rotate = tipo de rotación;
# min.err = precisión del ajuste; max.iter = número de iteraciones;
# scores = TRUE calcula puntajes.
AF <- fa(r = tren[, -1], fm = "ml", nfactors = 3, residuals = TRUE, rotate = "varimax",
         n.obs = nrow(tren[, -1]), min.err = 0.00001, max.iter = 5000, scores = TRUE)
AF
AF$loadings             # cargas factoriales
AF$communality          # comunalidades (varianza de cada ítem explicada por los factores)

cargas <- data.frame(unclass(AF$loadings), comunalidad = AF$communality)
round(cargas, 3)
write.csv(round(cargas, 3), file.path(dir_salida, "cargas_AFE.csv"))

# -----------------------------------------------------------------------
# Paso 6. Interpretación y depuración de ítems para el AFC
# -----------------------------------------------------------------------
# - ML2: p4, p5, p61, p62                 -> Acceso
# - ML3: p63, p64                         -> Tarjeta
# - ML1: p71, p73, p74, p75               -> Confort
# - p72 (tiempo de traslado): comunalidad muy baja (0.17), el factor casi
#   no la explica.
# - p8 (tiempo de espera): carga cruzada en dos factores (0.42 y 0.48).
# Por eso p72 y p8 se eliminan del AFC (carpeta 02_AFC).
