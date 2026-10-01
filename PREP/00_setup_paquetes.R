# =============================================================================
# Libro SEM · PREP
# 00 - Instalación y carga de paquetes
# =============================================================================
# Paquetes base (los mismos que en Tren_de_Guadalajara); se ajustarán si hace falta.

paquetes <- c(
  "readstata13", # leer la base de Stata (.dta)
  "psych",       # AFE (fa), KMO, Bartlett, alfa de Cronbach
  "nFactors",    # análisis paralelo
  "ggplot2",     # gráfica de codo
  "sem",         # AFC con specifyModel (primera forma del script de referencia)
  "lavaan",      # AFC, 2do orden, puntajes factoriales, FIML
  "semPlot"      # diagramas de los modelos
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

invisible(lapply(paquetes, instalar_si_falta))

cat("Paquetes listos para PREP:\n")
cat(paste("-", paquetes), sep = "\n")
