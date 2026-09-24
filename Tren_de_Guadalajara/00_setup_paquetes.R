# =============================================================================
# Libro SEM · Tren de Guadalajara
# 00 - Instalación y carga de paquetes
# =============================================================================
# Son los paquetes del script de referencia AFE_CFA.R.

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

cat("Paquetes listos para Tren de Guadalajara:\n")
cat(paste("-", paquetes), sep = "\n")
