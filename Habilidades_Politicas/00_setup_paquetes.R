# =============================================================================
# Libro SEM · Habilidades Políticas
# 00 - Instalación y carga de paquetes
# =============================================================================
# Referencias: el capítulo (PDF) y la presentación (PPTX) de López-Lemus y
# Zavala. El capítulo usa Mplus; la presentación repite el modelo en R con
# lavaan. Son los paquetes que usan los demás proyectos del libro.

paquetes <- c(
  "readstata13", # leer la base de Stata (.dta)
  "psych",       # AFE (fa), KMO, Bartlett, análisis paralelo, alfa, Mardia
  "GPArotation", # rotación oblimin del AFE (la usa psych::fa)
  "ggplot2",     # gráficas (codo, mapa de correlaciones)
  "lavaan",      # AFC, 2do orden, puntajes factoriales, invarianza
  "semPlot"      # diagramas de los modelos
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

invisible(lapply(paquetes, instalar_si_falta))

cat("Paquetes listos para Habilidades Políticas:\n")
cat(paste("-", paquetes), sep = "\n")
