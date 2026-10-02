# =============================================================================
# Libro SEM · Violencia Guerrero
# 00 - Instalación y carga de paquetes
# =============================================================================
# No hay script de referencia para este proyecto: solo se tiene la base. Son los
# paquetes que usa el proyecto del Tren, sin `sem` ni `nFactors` (el análisis
# paralelo se hace con psych).

paquetes <- c(
  "readstata13", # leer la base de Stata (.dta)
  "psych",       # AFE (fa), KMO, Bartlett, análisis paralelo, alfa, Mardia
  "GPArotation", # rotación oblimin del AFE (la usa psych::fa)
  "ggplot2",     # gráficas (codo, mapa de correlaciones)
  "lavaan",      # AFC, 2do orden, puntajes factoriales, invarianza, FIML
  "semPlot"      # diagramas de los modelos
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

invisible(lapply(paquetes, instalar_si_falta))

cat("Paquetes listos para Violencia Guerrero:\n")
cat(paste("-", paquetes), sep = "\n")
