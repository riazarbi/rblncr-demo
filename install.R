options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))
options(repos="https://packagemanager.rstudio.com/all/__linux__/focal/latest")
source("https://docs.posit.co/rspm/admin/check-user-agent.R")
Sys.setenv("NOT_CRAN" = TRUE)

packages <- c("arrow",
              "tidyr",
              "readr")

install.packages(packages)

remotes::install_github("riazarbi/rblncr")
