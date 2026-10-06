# =============================================================================
# Libro SEM · Habilidades Políticas
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# Sin referencia: el capítulo y la presentación pasan directo al AFC y no
# hacen AFE. Aquí se hace con la misma receta que en los otros proyectos
# (KMO, Bartlett, eigenvalores, análisis paralelo, ML con rotación oblimin)
# para responder una pregunta: ¿recuperan los datos, sin decirles la teoría,
# los cuatro factores de Ferris?
#   source("Habilidades_Politicas/01_AFE/AFE.R")
# =============================================================================

library(readstata13)
library(psych)
library(GPArotation)
library(ggplot2)

dir_salida <- "Habilidades_Politicas/01_AFE/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: 356 estudiantes, 15 ítems (Likert de 1 a 7), sin faltantes
# -----------------------------------------------------------------------
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
# Se ordenan los ítems por factor teórico (la base los trae en otro orden)
teoria <- list(HR = c("HR1", "HR2", "HR3", "HR4", "HR6"),
               SA = c("SA7", "SA8", "SA9"),
               AS = c("AS10", "AS11", "AS13", "AS14"),
               II = c("II16", "II17", "II18"))
items <- unlist(teoria)
datos <- hp[, items]
dim(datos)

# -----------------------------------------------------------------------
# Paso 2. ¿Tiene sentido factorizar? KMO y prueba de Bartlett
# -----------------------------------------------------------------------
# KMO > .80 es "meritorio" y > .90 "maravilloso" (Kaiser).
KMO(datos)
# Bartlett: H0 = la matriz de correlaciones es la identidad.
cortest.bartlett(cor(datos), n = nrow(datos))
# KMO global .92 (todos los ítems entre .89 y .95) y Bartlett p < .001: los
# ítems comparten mucha varianza.

# -----------------------------------------------------------------------
# Paso 3. Eigenvalores: ¿cuántos factores?
# -----------------------------------------------------------------------
eigenvalores <- eigen(cor(datos))$values
round(eigenvalores, 2)
round(cumsum(eigenvalores) / sum(eigenvalores), 3)
# Criterio de Kaiser (eigenvalor > 1): TRES componentes (6.71, 1.25, 1.09);
# el primero explica el 45% de la varianza y el cuarto ya es .79. Con un
# primer eigenvalor tan grande hay un factor general fuerte.

# -----------------------------------------------------------------------
# Paso 4. Análisis paralelo y gráfica de codo
# -----------------------------------------------------------------------
# Se retienen los factores cuyo eigenvalor supera al de datos aleatorios con
# el mismo número de personas y de variables.
set.seed(2015)
# Con 100 réplicas el resultado cambia entre 3 y 4 según la semilla (el cuarto
# factor está en el límite); con 500 sale 3 con todas las semillas probadas.
ap <- fa.parallel(datos, fm = "ml", fa = "both", n.iter = 500, plot = FALSE)
ap$nfact    # factores (AFE): 3
ap$ncomp    # componentes (PCA): 1
round(ap$fa.values[1:5], 3)   # eigenvalores observados del AFE: 6.13, .66, .48, .22, .09
round(ap$fa.sim[1:5], 3)      # simulados:                       .61, .30, .24, .19, .14
# El criterio de psych recomienda 3 factores; el cuarto eigenvalor observado
# (.22) queda apenas sobre la media simulada (.19), así que no se descarta.

# Dos paneles: componentes principales (eigenvalores de la matriz de
# correlaciones) y factores (eigenvalores del AFE por ML), cada uno contra lo
# que daría el azar.
k <- length(eigenvalores)
grafica <- data.frame(
  panel = rep(c("Componentes (PCA)", "Factores (AFE, ML)"), each = 2 * k),
  serie = rep(rep(c("Observado", "Simulado (paralelo)"), each = k), 2),
  numero = rep(seq_len(k), 4),
  eigenvalor = c(ap$pc.values, ap$pc.sim, ap$fa.values, ap$fa.sim))
p <- ggplot(grafica, aes(x = numero, y = eigenvalor, colour = serie, linetype = serie)) +
  geom_line() + geom_point() +
  geom_hline(yintercept = 1, colour = "grey40") +
  facet_wrap(~ panel, scales = "free_y") +
  scale_colour_manual(values = c(Observado = "red", `Simulado (paralelo)` = "blue")) +
  labs(title = "Gráfica de codo y análisis paralelo",
       x = "Número de componentes o factores", y = "Eigenvalor",
       colour = NULL, linetype = NULL)
p
ggsave(file.path(dir_salida, "grafica_codo.png"), p, width = 9, height = 4.5, dpi = 150)

# -----------------------------------------------------------------------
# Paso 5. AFE por máxima verosimilitud con rotación oblimin, de 1 a 4 factores
# -----------------------------------------------------------------------
# Oblimin y no varimax: los factores de una teoría de habilidades se
# correlacionan (en el AFC: .66 a .89). ml = máxima verosimilitud.
ajuste_afe <- t(sapply(1:4, function(k) {
  a <- fa(datos, nfactors = k, fm = "ml", rotate = "oblimin", n.obs = nrow(datos))
  c(factores = k, chi2 = a$STATISTIC, gl = a$dof, p = a$PVAL, TLI = a$TLI,
    RMSEA = unname(a$RMSEA["RMSEA"]), BIC = a$BIC,
    varianza = sum(a$Vaccounted["Proportion Var", ]))
}))
round(ajuste_afe, 3)
# RMSEA: .108 (1 factor), .089, .065 y .054 (4 factores). TLI: .81, .87, .93 y
# .95. El BIC es el menor con 3 factores (-211): lo prefiere por sobre el de 4
# (-196). Los datos admiten 3 y 4 factores; el paralelo y el BIC dicen 3.

# -----------------------------------------------------------------------
# Paso 6. Tres factores
# -----------------------------------------------------------------------
af3 <- fa(datos, nfactors = 3, fm = "ml", rotate = "oblimin", n.obs = nrow(datos))
cargas3 <- data.frame(unclass(af3$loadings), comunalidad = af3$communality,
                      teoria = rep(names(teoria), lengths(teoria)))
round(cargas3[, 1:4], 2)
cargas3
round(af3$Phi, 2)   # correlaciones entre factores
# ML1 = HR (HR1-HR6, .54 a .80). ML2 = II (II16-II18, .68 a .85) con SA7 (.34).
# ML3 mezcla SA y AS (AS13, AS14, SA8, SA9): Astucia social y Sinceridad
# aparente no se separan. AS10 y AS11 cargan en dos factores (.31-.35 en HR).

# -----------------------------------------------------------------------
# Paso 7. Cuatro factores (los de la teoría)
# -----------------------------------------------------------------------
af4 <- fa(datos, nfactors = 4, fm = "ml", rotate = "oblimin", n.obs = nrow(datos))
cargas4 <- data.frame(unclass(af4$loadings), comunalidad = af4$communality,
                      teoria = rep(names(teoria), lengths(teoria)))
round(cargas4[, 1:5], 2)
round(af4$Phi, 2)
# Con 4 factores solo HR e II salen como en la teoría. El cuarto factor es
# casi un solo ítem (SA8, carga .96 y comunalidad 1.00: un caso Heywood, es
# decir, una solución impropia) y SA7 y SA9 se van a otros factores (II y AS).
round(af4$communality, 3)
# Para cada ítem: ¿en qué factor carga más?
asignado <- apply(abs(unclass(af4$loadings)), 1, which.max)
table(teoria = cargas4$teoria, factor_AFE = paste0("F", asignado))

# Ítems con carga >= .30 en más de un factor (cargas cruzadas)
cruzadas <- function(af) {
  l <- abs(unclass(af$loadings))
  names(which(rowSums(l >= .30) > 1))
}
cruzadas(af3)
cruzadas(af4)

# -----------------------------------------------------------------------
# Paso 8. Guardar resultados
# -----------------------------------------------------------------------
write.csv(round(ajuste_afe, 3), file.path(dir_salida, "ajuste_AFE_1_a_4_factores.csv"), row.names = FALSE)
write.csv(round(cargas3[, 1:4], 3), file.path(dir_salida, "cargas_AFE_3_factores.csv"))
write.csv(round(cargas4[, 1:5], 3), file.path(dir_salida, "cargas_AFE_4_factores.csv"))
