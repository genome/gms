#Test R packages that should have been installed by now
.libPaths()

#List of packages installed properly (by install.packages or biocLite)
installed_package_list = c('bitops', 'Cairo', 'caTools', 'colorspace', 'doMC', 'e1071', 'filehash', 'foreach',
                           'fpc', 'ggplot2', 'Hmisc', 'intervals', 'itertools', 'Matrix', 'mgcv', 'mixdist',
                           'mixtools', 'multicore', 'nortest', 'h5r', 'plotrix', 'proto', 'RColorBrewer',
                           'scatterplot3d', 'SKAT', 'statmod', 'xtable', 'getopt', 'gtools', 'gdata',
                           'affy', 'Biobase', 'cummeRbund', 'DNAcopy', 'edgeR', 'limma', 'gcrma', 'genefilter',
                           'geneplotter', 'GenomeGraphs', 'lumi', 'methylumi', 'multtest', 'preprocessCore', 'ChemmineR',
                           'boot','copyCat', 'gplots', 'pbh5')

#Test packages installed properly (by install.packages or biocLite)
for (package_name in installed_package_list){
  if (!package_name %in% rownames(installed.packages())){
    message=paste("ERROR: ", package_name, " package not installed successfully", sep="")
    print(message)
  }else{
    message=paste(package_name, " loaded", sep="")
    print(message);
  }
}

#Display overall capabilities of this R installation
capabilities() 

#Will Cairo be used for PNGs as desired?
getOption("bitmapType")

#Test device types
png()
tiff()
jpeg()

#Print out complete session info
sessionInfo()

