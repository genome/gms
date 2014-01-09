#This directory contains files used to create a custom R installation
#This included specifing a particular version of R and a list of all CRAN and Bioconductor packages
#It also includes some ad hoc packages that must be compiled from source and are not otherwise available

#'packages.r.lst' includes all ubuntu packages that are needed to install R with the desired features 
#These ubuntu packages are installed during execution of the sGMS Makefile (make target 'done-host/pkgs')

#'install_custom_r.sh' creates dirs and installs R from source
#It then runs additional scripts to install R packages from CRAN and Bioconductor
#It also includes code to install a few ad hoc R scripts that are not available elsewhere
#Everything to do with the R installation (except Ubuntu packages) winds up in a single directory
#To uninstall you can simply remove this directory and run this script again (using sudo)

#'install_r_packages.R' contains commands for R CRAN and Bioconductor packages

#'test_r_packages.R' contains basic tests to run at the end of the installation
#This will test that all packages can be loaded, print out system info, and test certain fundamental R capabilities



