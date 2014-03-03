#!/bin/bash
#Install a custom version of R and R packages needed
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script dir is:" $DIR

#Check environment
if [ -z "$GENOME_SW" ]; then
  echo "GENOME_SW is not set, attempting to source /etc/genome.conf"
  if [ -e "/etc/genome.conf" ]; 
  then
    source "/etc/genome.conf"
  else
    echo "Could not source because /etc/genome.conf is not present"
  fi
fi  
[ -z "$GENOME_SW" ] && echo "GENOME_SW is not set " && exit 1;
echo "GENOME_SW is:" $GENOME_SW

#Set the R version to install
export R_VERSION="R-2.15.2"
echo "INSTALLING R VERSION" $R_VERSION

#Create the installation location
export R_BASE_DIR="$GENOME_SW/R"
[ ! -d $R_BASE_DIR ] && mkdir $R_BASE_DIR && echo echo "Creating base R dir"
export R_INSTALL_DIR="$R_BASE_DIR/$R_VERSION"

#Make sure this version of R is not already there
[ -d $R_INSTALL_DIR ] && echo "Already installed this version of R?:" $R_INSTALL_DIR && exit 0

#Install a specific version of R to custom location
cd $R_BASE_DIR
wget http://cran.r-project.org/src/base/R-2/$R_VERSION.tar.gz
tar -zxvf $R_VERSION.tar.gz
[ ! -d $R_INSTALL_DIR ] && echo "R_INSTALL_DIR missing:" $R_INSTALL_DIR && exit 1
cd $R_INSTALL_DIR
./configure --prefix=$R_INSTALL_DIR/ --enable-memory-profiling --with-tcltk --with-cairo --with-libpng --with-jpeglib --with-libtiff
make
make install

#Make this first version of R to use in PATH
export PATH=$GENOME_SW/R/$R_VERSION/bin:$PATH

#Note adding R's bin to PATH can be dangerous because there are binaries in there with generic names
#Some of these like 'pager' can cause problems by over-riding /usr/bin/pager
#To be more precise we will create a new bin with just 'R' and 'Rscript' and add *that* to PATH
mkdir $R_INSTALL_DIR/bin_safe/
cp $R_INSTALL_DIR/bin/R $R_INSTALL_DIR/bin_safe/
cp $R_INSTALL_DIR/bin/Rscript $R_INSTALL_DIR/bin_safe/

#Make sure the R bin was successfully installed where expected
export R_BIN="$R_INSTALL_DIR/bin_safe/R"
[ ! -e $R_BIN ] && echo "R_BIN missing:" $R_BIN && exit 1

#Install R libraries manually within a subdir of the R installation dir
echo "INSTALLING R LIBRARIES THAT MUST BE HANDLED MANUALLY"
mkdir $R_INSTALL_DIR/custom_packages
export CUSTOM_DIR="$GENOME_SW/R/$R_VERSION/custom_packages"
echo "Directory for custom packages is " $CUSTOM_DIR

#Install R CRAN packages from static archives
#Document original location of static archives
#wget http://cran.r-project.org/src/contrib/$package.tar.gz #latest version
#wget http://cran.r-project.org/src/contrib/Archive/$package/$package.tar.gz #archived versions
echo "INSTALLING ALL CRAN DEPENDENCIES FROM ARCHIVES"
echo $CUSTOM_DIR
cd $CUSTOM_DIR
echo "DOWNLOADING ARCHIVES FOR EACH CRAN LIBRARY"
wget https://xfer.genome.wustl.edu/gxfer1/project/gms/testdata/GMS1/setup/archive-files/r-cran-archives-2014-02-26.tar.gz
tar -zxvf r-cran-archives-2014-02-26.tar.gz

echo "INSTALLING CRAN LIBRARIES FROM PACKAGE ARCHIVES"
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library bitops_1.0-4.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Cairo_1.4-8.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library caTools_1.11.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library iterators_1.0.3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library multicore_0.1-3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library foreach_1.3.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library doMC_1.2.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library e1071_1.6-1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mclust_3.4.11.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library modeltools_0.2-17.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mvtnorm_0.9-96.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library multcomp_1.2-5.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library flexmix_2.3-3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library fpc_2.0-3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Hmisc_3.8-3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library intervals_0.13.3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mixdist_0.5-4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mixtools_0.4.5.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library filehash_2.2-1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library colorspace_1.0-1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library digest_0.4.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library RColorBrewer_1.0-2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library proto_0.3-10.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library itertools_0.1-1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library plyr_1.8.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library reshape_0.8.4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library memoise_0.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gtable_0.1.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library stringr_0.6.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library dichromat_2.0-0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library munsell_0.4.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library labeling_0.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library scales_0.2.3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library reshape2_1.2.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library ggplot2_0.9.3.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library nortest_1.0-2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library h5r_1.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library plotrix_3.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library scatterplot3d_0.3-31.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library SKAT_0.75.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library statmod_1.4.9.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library xtable_1.5-5.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library getopt_1.17.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gtools_2.6.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gdata_2.8.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gplots_2.8.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library pbh5.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library DBI_0.2-7.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library RSQLite_0.11.4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library fastcluster_1.1.13.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library XML_3.98-1.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library RCurl_1.95-4.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library nleqslv_2.1.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library locfit_1.5-9.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library ash_1.0-14.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library rgl_0.93.996.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library misc3d_0.8-4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library ks_1.8.13.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library hdrcde_3.1.tar.gz

echo "DOWNLOADING ARCHIVES FOR EACH BIOCONDUCTOR LIBRARY"
wget https://xfer.genome.wustl.edu/gxfer1/project/gms/testdata/GMS1/setup/archive-files/r-bioc-archives-2014-02-26.tar.gz
tar -zxvf r-bioc-archives-2014-02-26.tar.gz

echo "INSTALLING BIOCONDUCTOR LIBRARIES FROM PACKAGE ARCHIVES"
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library BiocGenerics_0.4.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Biobase_2.18.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library BiocInstaller_1.8.3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library preprocessCore_1.20.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library zlibbioc_1.4.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library affyio_1.26.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library affy_1.36.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library IRanges_1.16.6.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library GenomicRanges_1.10.7.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Biostrings_2.26.3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Rsamtools_1.10.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library BSgenome_1.26.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library rtracklayer_1.18.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library AnnotationDbi_1.20.7.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library biomaRt_2.14.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library GenomicFeatures_1.10.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library biovizBase_1.6.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Gviz_1.2.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library cummeRbund_2.0.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library DNAcopy_1.32.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library limma_3.14.4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library edgeR_3.0.8.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library annotate_1.36.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library genefilter_1.40.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library geneplotter_1.36.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library GenomeGraphs_1.18.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library methylumi_2.4.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library lumi_2.10.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library multtest_2.14.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library ChemmineR_2.10.9.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gcrma_2.30.0.tar.gz

#Install R libraries needed from within an R session
#echo "INSTALLING R LIBRARIES FROM WITHIN AN R SESSION"
#echo "Script dir is " $DIR
#$R_BIN CMD BATCH $DIR/install_r_packages.R $R_INSTALL_DIR/install_r_packages.stdout

#CopyCat relies on some bioconductor packages
echo "INSTALLING COPYCAT"
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library copyCat_1.6.2.tar.gz

#Test that all R packages can load
echo "TESTING THAT ALL R PACKAGES CAN LOAD"
$R_BIN CMD BATCH $DIR/test_r_packages.R $R_INSTALL_DIR/test_r_packages.stdout

#Make sure 'cairo' is used for bitmap creation instead of 'Xlib' by creating a setting in a .Rprofile file
bash -c 'echo options\(bitmapType = \"cairo\"\) > $R_INSTALL_DIR/etc/.Rprofile'

#Display the result of the final test
cat $R_INSTALL_DIR/test_r_packages.stdout | grep "\[1\]"

