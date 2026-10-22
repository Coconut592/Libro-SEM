# =============================================================================
# Libro SEM · Violencia Veracruz
# 00 - Instalación y carga de paquetes
# =============================================================================
# Referencias: el script de Stata (Scripts.do) que acompaña a la base y los
# demás proyectos del libro. Son los paquetes que usan el diagnóstico y los 7
# ejercicios.

paquetes <- c(
  "readstata13", # leer la base de Stata (.dta)
  "psych",       # AFE (fa), KMO, tetracóricas, análisis paralelo, alfa de Cronbach (KR-20)
  "GPArotation", # rotación oblimin del AFE (la usa psych::fa)
  "lavaan",      # AFE ordinal, AFC, 2do orden, puntajes factoriales, invarianza, FIML
  "MASS"         # polr: la regresión logística ordinal (ologit de Stata) del diagnóstico
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

invisible(lapply(paquetes, instalar_si_falta))

cat("Paquetes listos para Violencia Veracruz:\n")
cat(paste("-", paquetes), sep = "\n")
