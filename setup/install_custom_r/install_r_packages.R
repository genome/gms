#Set mirror to get R packages from
r_package_repo="http://cran.wustl.edu"

#Display current lib paths known within R
.libPaths()


#List of CRAN packages
#cran_package_list = c('bitops', 'Cairo', 'caTools', 'doMC', 'e1071', 'foreach', 
#                      'fpc', 'Hmisc', 'intervals', 'Matrix', 'mgcv', 'mixdist', 
#                      'mixtools', 'multicore', 'nortest', 'h5r', 'plotrix',   
#                      'scatterplot3d', 'SKAT', 'statmod', 'xtable', 'getopt', 'gtools', 'gdata')

#List of Bioconductor packages
bioc_package_list = c('affy', 'Biobase', 'cummeRbund', 'DNAcopy', 'edgeR', 'limma', 'gcrma', 'genefilter', 
                      'geneplotter', 'GenomeGraphs', 'lumi', 'methylumi', 'multtest', 'preprocessCore', 'ChemmineR')

#package - installed within TGI - installed by BiocLite
#'affy' - affy_1.28.0 - affy_1.36.1
#'Biobase' - Biobase_2.18.0 - Biobase_2.18.0
#'cummeRbund' - cummeRbund_2.0.0 - cummeRbund_2.0.0
#'DNAcopy' - DNAcopy_1.24.0 - DNAcopy_1.32.0
#'edgeR' - edgeR_3.4.1 - edgeR_3.0.8
#'limma' - limma_3.18.3 - limma_3.14.4
#'genefilter' - genefilter_1.32.0 - genefilter_1.40.0
#'geneplotter' - geneplotter_1.28.0 - geneplotter_1.36.0
#'GenomeGraphs' - GenomeGraphs_1.10.0 - GenomeGraphs_1.18.0
#'lumi' - mgcv_1.7-19 - lumi_2.10.0
#'methylumi' - methylumi_1.6.1 - methylumi_2.4.0
#'multtest' - multtest_2.6.0 - multtest_2.14.0
#'preprocessCore' - preprocessCore_1.12.0 - preprocessCore_1.20.0
#'ChemmineR' - ChemmineR_2.9.0 - ChemmineR_2.10.9
#'gcrma' - does not load in TGI... - gcrma_2.30.0

#Create a function to install CRAN packages if they are not already installed (and then test for success)
pkgTestCran <- function(x){
  if (!require(x,character.only = TRUE)){
    install.packages(x,dep=TRUE,repos=r_package_repo)
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
}

#Create a function to install BioConductor packages if they are not already installed (and then test for success)
pkgTestBioc <- function(x){
  if (!require(x,character.only = TRUE)){
    biocLite(x,ask=FALSE,suppressUpdates=TRUE)
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
}

#Installation and test of CRAN packages
#Replaced with manual install of specific versions from archives
#for (cran_package_name in cran_package_list){
#  pkgTestCran(cran_package_name)
#}

#Installation and test of Bioconductor packages
source("http://bioconductor.org/biocLite.R")
for (bioc_package_name in bioc_package_list){
  pkgTestBioc(bioc_package_name);
}


#Documentation of desired R CRAN and Bioconductor packages
#r-base (= 2.15.2-1precise0) - already part of R install
#r-base-core (= 2.15.2-1precise0) - already part of R install
#r-recommended (= 2.15.2-1precise0) - already part of R install
#r-cran-bitops (>= 1.0-4.1-1cran1) -> 'bitops'
#r-cran-boot (= 1.3-5-1precise0) - must be installed separately -> 'boot'
#r-cran-cairo (>= 1.4-8-1cran1) - note R Cairo will not install unless ubunto Cairo libs are already installed -> 'Cairo'
#r-cran-catools (>= 1.11-1cran1) -> 'caTools'
#r-cran-colorspace (>= 1.0.1-1build1) -> 'colorspace'
#r-cran-copycat (>= 1.6-2) - must be installed separately -> 'copyCat'
#r-cran-domc (>= 1.2.0-2) -> 'doMC'
#r-cran-e1071 (>= 1.5-24-1cran1) -> 'e1071'
#r-cran-filehash (>= 2.1-1-1cran1) -> 'filehash'
#r-cran-foreach (>= 1.3.0-2) -> 'foreach'
#r-cran-fpc (>= 2.0-3) -> 'fpc'
#r-cran-ggplot2 (= 0.8.9-1cran1) -> 'ggplot2'
#r-cran-gplots (>= 2.8.0-1cran1) - must be installed separately -> 'gplots'
#r-cran-hmisc (>= 3.8) -> 'Hmisc'
#r-cran-intervals (>= 0.13.3-1cran1) -> 'intervals'
#r-cran-itertools (>= 0.1-1-1cran1) -> 'itertools'
#r-cran-matrix (= 1.0-6-1precise0) -> 'Matrix'
#r-cran-mgcv (>= 1.7-19-1precise0) -> 'mgcv'
#r-cran-mixdist (>= 0.5-4-2) -> 'mixdist'
#r-cran-mixtools (>= 0.4.5-1) -> 'mixtools'
#r-cran-multicore (>= 0.1-3-2) -> 'multicore'
#r-cran-nortest (>= 1.0-1cran1) -> 'nortest'
#r-cran-h5r (needed for the 'pbh5' package) -> 'h5r'
#r-cran-pbh5 (>= 2012.04.12-1) - must be installed separately -> 'pbh5'
#r-cran-plotrix (>= 3.1-1cran1) -> 'plotrix'
#r-cran-proto (>= 0.3-9.2) -> 'proto'
#r-cran-rcolorbrewer (>= 1.0-2-2) -> 'RColorBrewer'
#r-cran-scatterplot3d (>= 0.3-31-1cran1) -> 'scatterplot3d'
#r-cran-skat (>= 0.73) -> 'SKAT'
#r-cran-statmod (>= 1.4.9-1cran1) -> 'statmod'
#r-cran-xtable (>= 1.5.5-1) -> 'xtable'
#r-cran-getopt (>= 1.14-2) -> 'getopt'
#r-cran-gtools (needed by 'boot') -> 'gtools'
#r-cran-gdata (needed by 'boot') -> 'gdata'
#r-bioc-affy (>= 1.28.0-1cran1) -> 'affy'
#r-bioc-biobase (>= 2.10.0-1cran1) -> 'Biobase'
#r-bioc-cummerbund (>= 2.0.0-1) -> 'cummeRbund'
#r-bioc-dnacopy (>= 1.24.0-1cran1) -> 'DNAcopy'
#r-bioc-edger (= 3.4.1~tgi-1) -> 'edgeR'
#r-bioc-limma (= 3.18.3~tgi-1) -> 'limma'
#r-bioc-gcrma (>= 2.22.0-1cran1) -> 'gcrma'
#r-bioc-genefilter (>= 1.32.0-1cran1) -> 'genefilter'
#r-bioc-geneplotter (>= 1.28.0-1cran1) -> 'geneplotter'
#r-bioc-genomegraphs (>= 1.10.0-1cran1) -> 'GenomeGraphs'
#r-bioc-lumi (>= 1.6.3-1) -> 'lumi'
#r-bioc-methylumi (>= 1.6.1-1cran1) -> 'methylumi'
#r-bioc-multtest (>= 2.6.0-1cran1) -> 'multtest'
#r-bioc-preprocesscore (>= 1.12.0-1cran1) -> 'preprocessCore'
#r-cran-chemminer (>= 2.9.0-1) - actually 'ChemmineR' from bioC? -> 'ChemmineR'
