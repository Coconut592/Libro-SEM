# =============================================================================
# Libro SEM · Violencia Guerrero
# 00 - Exploración de la base y viabilidad de cada análisis
# =============================================================================
# No hay script de referencia, ni PDF, ni diccionario: solo el .dta
# (cap4_GRO.dta). Todo lo que se sabe de las variables sale de sus etiquetas y
# de los propios datos. Este script responde: ¿qué hay en la base y qué
# análisis (AFE, AFC, 2do orden, confiabilidad y validez, puntajes,
# invarianza, FIML) se pueden hacer con ella?
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("Violencia_Guerrero/00_Exploracion/Exploracion.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)
library(ggplot2)

dir_salida <- "Violencia_Guerrero/00_Exploracion/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Leer la base
# -----------------------------------------------------------------------
# 294 personas y 47 columnas: folio y 46 ítems. El .dta no trae etiquetas de
# valor ni variables de grupo (sexo, edad, municipio...).
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
dim(guerrero)
items <- setdiff(names(guerrero), "folio")

# Todos los ítems son escalas de 1 a 10 (valores enteros)
range(guerrero[, items], na.rm = TRUE)
all(guerrero[, items] == round(guerrero[, items]), na.rm = TRUE)

# Nadie contesta todo igual: no hay respuestas en línea recta (straight-lining)
sum(apply(guerrero[, items], 1, sd, na.rm = TRUE) == 0, na.rm = TRUE)

# -----------------------------------------------------------------------
# Paso 2. Diccionario: bloques de contenido y descriptivos
# -----------------------------------------------------------------------
# Los bloques salen de la redacción de las etiquetas (a1-a24 son seis
# dominios de cuatro ítems; b, c y f son percepciones sobre vecinos,
# autoridades, seguridad y gobierno). Los nombres de los ítems saltan números
# (b5-b8, c9-c10...): la base trae solo una selección de la encuesta.
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

d <- describe(guerrero[, items])
diccionario <- data.frame(
  variable = items,
  etiqueta = trimws(varlabel(guerrero)[items]),
  bloque = bloque[items],
  n = d$n,
  faltantes_pct = round(100 * (1 - d$n / nrow(guerrero)), 1),
  media = d$mean, de = d$sd, asimetria = d$skew, curtosis = d$kurtosis,
  min = d$min, max = d$max)
diccionario[, 6:11] <- round(diccionario[, 6:11], 2)
print(diccionario, row.names = FALSE)
write.csv(diccionario, file.path(dir_salida, "diccionario_variables.csv"), row.names = FALSE)
# Casi todos los ítems tienen asimetría negativa (las calificaciones se
# cargan hacia 8-10) y los de confianza y desempeño la tienen positiva (se
# cargan hacia 1-3). Se trabajan como continuos con MLR (ver 02_AFC).

# -----------------------------------------------------------------------
# Paso 3. El folio: duplicados y huecos
# -----------------------------------------------------------------------
# El folio no es un identificador único: 3 folios aparecen dos veces.
repetidos <- unique(guerrero$folio[duplicated(guerrero$folio)])
repetidos

# ¿Son la misma encuesta capturada dos veces o personas distintas? Se cuentan
# los ítems contestados en ambos renglones y cuántos coinciden.
coincidencia <- t(sapply(repetidos, function(f) {
  r <- guerrero[guerrero$folio == f, items]
  a <- as.numeric(unlist(r[1, ])); b <- as.numeric(unlist(r[2, ]))
  ambos <- !is.na(a) & !is.na(b)
  c(folio = f, items_en_ambos = sum(ambos), iguales = sum(a[ambos] == b[ambos]))
}))
coincidencia
# 135 y 137: solo coinciden 12 de 44 y 10 de 40 respuestas (lo normal con
# escalas cargadas hacia 8-10), parecen personas distintas con el folio
# repetido por error de captura. 292: 39 de 41 respuestas idénticas, casi
# seguro es la misma encuesta capturada dos veces. Se conservan los 294
# renglones (más abajo se comprueba que quitar uno no cambia nada).

# Folios que faltan entre 1 y 325 (encuestas descartadas o no capturadas)
length(setdiff(seq_len(max(guerrero$folio)), guerrero$folio))

# El folio NO es solo un número de control: 12 de 46 ítems se relacionan con
# él (se esperarían ~2 por azar). Parece reflejar el orden o el lote del
# levantamiento, y no se sabe qué significa.
p_folio <- sapply(items, function(v) {
  ok <- !is.na(guerrero[[v]])
  cor.test(guerrero$folio[ok], guerrero[[v]][ok], method = "spearman", exact = FALSE)$p.value
})
sum(p_folio < .05)
names(p_folio)[p_folio < .05]
# Por cuartos de folio, la proporción de personas sin pareja (más abajo) es
# de ~26-30% en los tres primeros cuartos y de 12% en el último
cuarto <- cut(guerrero$folio, quantile(guerrero$folio, 0:4 / 4), include.lowest = TRUE,
              labels = c("Q1", "Q2", "Q3", "Q4"))
round(100 * tapply(rowSums(is.na(guerrero[, factores$pareja])) == 4, cuarto, mean), 1)

# -----------------------------------------------------------------------
# Paso 4. Datos faltantes
# -----------------------------------------------------------------------
sort(colSums(is.na(guerrero[, items])), decreasing = TRUE)[1:12]

# Solo 160 de 294 personas (54%) contestaron los 46 ítems
sum(complete.cases(guerrero[, items]))
table(rowSums(is.na(guerrero[, items])))

# Por instrumento: a1-a24 (satisfacción) y b, c, f (violencia y clima social)
sum(complete.cases(guerrero[, unlist(factores[1:6])]))
sum(complete.cases(guerrero[, unlist(factores[7:12])]))

# Los faltantes de pareja (a1-a4) son ESTRUCTURALES: 71 personas no
# contestan ninguno de los cuatro ítems (casi seguro no tienen pareja).
guerrero$sin_pareja <- rowSums(!is.na(guerrero[, factores$pareja])) == 0
table(guerrero$sin_pareja)
table(rowSums(!is.na(guerrero[, factores$pareja])))   # 4 ítems contestados: 218

# Los demás faltantes (c6: 38, c8: 23, c13: 16, familia: 10-12) son
# esporádicos, salvo que quien no tiene pareja también deja en blanco los
# ítems de familia con más frecuencia.
faltan_grupo <- sapply(items, function(v) tapply(is.na(guerrero[[v]]), guerrero$sin_pareja, mean) * 100)
rownames(faltan_grupo) <- c("con_pareja", "sin_pareja")
round(faltan_grupo[, apply(faltan_grupo, 2, max) > 8], 1)

# ¿Quien no tiene pareja responde distinto en lo demás? Casi no: se compara
# con la misma prueba t del proyecto del Tren.
otros <- setdiff(items, factores$pareja)
comparacion <- data.frame(
  con_pareja = sapply(otros, function(v) mean(guerrero[[v]][!guerrero$sin_pareja], na.rm = TRUE)),
  sin_pareja = sapply(otros, function(v) mean(guerrero[[v]][guerrero$sin_pareja], na.rm = TRUE)),
  p_valor    = sapply(otros, function(v) t.test(guerrero[[v]] ~ guerrero$sin_pareja)$p.value))
round(comparacion[comparacion$p_valor < .05, ], 3)
sum(comparacion$p_valor < .05)    # 1 de 42 (por azar se esperarían ~2)
write.csv(round(comparacion, 3), file.path(dir_salida, "comparacion_con_sin_pareja.csv"))

# -----------------------------------------------------------------------
# Paso 5. Estructura de correlaciones: ¿forman bloques los ítems?
# -----------------------------------------------------------------------
# Correlaciones por pares (cada par usa a todas las personas que contestaron
# ambos ítems). Si los bloques de contenido son reales, los ítems de un
# bloque deben correlacionar más entre sí que con los demás.
R <- cor(guerrero[, items], use = "pairwise.complete.obs")
dentro_fuera <- t(sapply(factores, function(v) {
  r <- R[v, v]
  c(k = length(v), r_dentro = mean(r[upper.tri(r)]), r_min_dentro = min(r[upper.tri(r)]),
    r_fuera = mean(R[v, setdiff(colnames(R), v)]))
}))
round(dentro_fuera, 3)
write.csv(round(dentro_fuera, 3), file.path(dir_salida, "correlaciones_dentro_fuera.csv"))

# Correlación media entre pares de bloques (diagonal = dentro del bloque)
entre <- sapply(names(factores), function(a) sapply(names(factores), function(b) {
  r <- R[factores[[a]], factores[[b]]]
  if (a == b) mean(r[upper.tri(r)]) else mean(r)
}))
round(entre, 2)
write.csv(round(entre, 3), file.path(dir_salida, "correlaciones_entre_bloques.csv"))
# Dentro de cada bloque: .53 a .76. Entre bloques: casi siempre < .30, y los
# seis dominios de satisfacción (a1-a24) se relacionan entre sí (.12 a .43):
# eso sugiere un factor general de satisfacción (ver 03_AFC_2do_Orden).

# Mapa de calor: se ven los 12 bloques sobre la diagonal
R_larga <- as.data.frame(as.table(R))
names(R_larga) <- c("x", "y", "r")
R_larga$x <- factor(R_larga$x, levels = items)
R_larga$y <- factor(R_larga$y, levels = rev(items))
p <- ggplot(R_larga, aes(x, y, fill = r)) + geom_tile() +
  scale_fill_gradient2(low = "firebrick", mid = "white", high = "steelblue",
                       midpoint = 0, limits = c(-1, 1)) +
  labs(title = "Correlaciones entre los 46 ítems (por pares)", x = NULL, y = NULL) +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, size = 7),
        axis.text.y = element_text(size = 7))
p
ggsave(file.path(dir_salida, "mapa_correlaciones.png"), p, width = 9, height = 8, dpi = 150)

# -----------------------------------------------------------------------
# Paso 6. Distribución de los ítems
# -----------------------------------------------------------------------
png(file.path(dir_salida, "histogramas_items.png"), width = 1500, height = 1700, res = 130)
par(mfrow = c(8, 6), mar = c(2, 2, 2, 1))
for (v in items) hist(guerrero[[v]], breaks = 0:10 + .5, main = v, xlab = "", ylab = "", col = "lightblue")
dev.off()

# Frecuencia de cada valor (1 a 10) en cada ítem
frec <- sapply(items, function(v) tabulate(guerrero[[v]], nbins = 10))
rownames(frec) <- 1:10
round(100 * rowSums(frec) / sum(frec), 1)     # % de todas las respuestas en cada valor

# Efecto suelo (% que contesta 1) en confianza y desempeño, y efecto techo
# (% que contesta 10) en pareja, familia, personal y trabajo
suelo <- 100 * frec["1", ] / colSums(frec)
techo <- 100 * frec["10", ] / colSums(frec)
round(range(suelo[c(factores$confianza, factores$desempeno)]), 1)
round(range(techo[unlist(factores[c("pareja", "familia", "personal", "trabajo")])]), 1)

# Apilamiento en 5: cuántas veces supera el 5 al promedio de 4 y 6. Si no
# hubiera preferencia por el punto medio, el cociente rondaría 1.
apilamiento <- frec["5", ] / colMeans(frec[c("4", "6"), ])
sum(apilamiento > 1.5)                        # 33 de 46 ítems
round(median(apilamiento), 2)

# -----------------------------------------------------------------------
# Paso 7. Sensibilidad: ¿importa el posible duplicado del folio 292?
# -----------------------------------------------------------------------
# Se ajustan los modelos de cada instrumento con los 294 casos y sin el
# segundo renglón del folio 292. Se compara la mayor diferencia en las
# cargas estandarizadas.
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
cargas_std <- function(modelo, datos) {
  fit <- cfa(modelo, data = datos, estimator = "MLR", missing = "fiml")
  s <- standardizedSolution(fit)
  s$est.std[s$op == "=~"]
}
sin_duplicado <- guerrero[-which(guerrero$folio == 292)[2], ]
nrow(sin_duplicado)
sapply(c(satisfaccion = modelo_sat, violencia_clima = modelo_vio), function(m)
  max(abs(cargas_std(m, guerrero) - cargas_std(m, sin_duplicado))))
# La diferencia máxima es menor que .005 (.002 y .0045): el duplicado no
# afecta, y se conservan los 294 casos tal como vienen en el .dta.
