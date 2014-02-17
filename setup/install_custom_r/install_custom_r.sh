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
echo "INSTALLING ALL CRAN DEPENDENCIES FROM ARCHIVES"
echo $CUSTOM_DIR
cd $CUSTOM_DIR
echo "DOWNLOADING ARCHIVES FOR EACH CRAN LIBRARY"
wget http://genome.wustl.edu/pub/software/gms/testdata/GMS1/setup/archive-files/r-cran-archives-2014-02-15.tar.gz
tar -zxvf r-cran-archives-2014-02-15.tar.gz

#Document original location of static archives
#wget http://cran.r-project.org/src/contrib/Archive/bitops/bitops_1.0-4.1.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/Cairo/Cairo_1.4-8.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/caTools/caTools_1.11.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/iterators/iterators_1.0.3.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/multicore/multicore_0.1-3.tar.gz 
#wget http://cran.r-project.org/src/contrib/Archive/foreach/foreach_1.3.0.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/doMC/doMC_1.2.0.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/class/class_7.3-4.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/e1071/e1071_1.6-1.tar.gz 
#wget http://cran.r-project.org/src/contrib/Archive/mclust/mclust_3.4.11.tar.gz 
#wget http://cran.r-project.org/src/contrib/Archive/modeltools/modeltools_0.2-17.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/mvtnorm/mvtnorm_0.9-96.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/multcomp/multcomp_1.2-5.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/flexmix/flexmix_2.3-3.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/fpc/fpc_2.0-3.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/Hmisc/Hmisc_3.8-3.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/intervals/intervals_0.13.3.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/Matrix/Matrix_1.0-6.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/mgcv/mgcv_1.7-19.tar.gz
#wget http://cran.r-project.org/src/contrib/mixdist_0.5-4.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/mixtools/mixtools_0.4.5.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/filehash/filehash_2.2-1.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/colorspace/colorspace_1.0-1.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/digest/digest_0.4.2.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/RColorBrewer/RColorBrewer_1.0-2.tar.gz
#wget http://cran.r-project.org/src/contrib/proto_0.3-10.tar.gz
#wget http://cran.r-project.org/src/contrib/itertools_0.1-1.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/plyr/plyr_1.4.tar.gz
#wget http://cran.r-project.org/src/contrib/reshape_0.8.4.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/ggplot2/ggplot2_0.8.9.tar.gz
#wget http://cran.r-project.org/src/contrib/nortest_1.0-2.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/h5r/h5r_1.2.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/plotrix/plotrix_3.1.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/scatterplot3d/scatterplot3d_0.3-31.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/SKAT/SKAT_0.75.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/statmod/statmod_1.4.9.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/xtable/xtable_1.5-5.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/getopt/getopt_1.17.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/gtools/gtools_2.6.2.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/gdata/gdata_2.8.1.tar.gz
#wget http://cran.r-project.org/src/contrib/Archive/gplots/gplots_2.8.0.tar.gz

echo "INSTALLING EACH ARCHIVE"
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library bitops_1.0-4.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Cairo_1.4-8.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library caTools_1.11.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library iterators_1.0.3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library multicore_0.1-3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library foreach_1.3.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library doMC_1.2.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library class_7.3-4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library e1071_1.6-1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mclust_3.4.11.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library modeltools_0.2-17.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mvtnorm_0.9-96.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library multcomp_1.2-5.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library flexmix_2.3-3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library fpc_2.0-3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Hmisc_3.8-3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library intervals_0.13.3.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library Matrix_1.0-6.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mgcv_1.7-19.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mixdist_0.5-4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library mixtools_0.4.5.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library filehash_2.2-1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library colorspace_1.0-1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library digest_0.4.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library RColorBrewer_1.0-2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library proto_0.3-10.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library itertools_0.1-1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library plyr_1.4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library reshape_0.8.4.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library ggplot2_0.8.9.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library nortest_1.0-2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library h5r_1.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library plotrix_3.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library scatterplot3d_0.3-31.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library SKAT_0.75.tar.gz #unable to find 0.73
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library statmod_1.4.9.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library xtable_1.5-5.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library getopt_1.17.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gtools_2.6.2.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gdata_2.8.1.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gplots_2.8.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library pbh5.tar.gz

#Install R libraries needed from within an R session
echo "INSTALLING R LIBRARIES FROM WITHIN AN R SESSION"
echo "Script dir is " $DIR
$R_BIN CMD BATCH $DIR/install_r_packages.R $R_INSTALL_DIR/install_r_packages.stdout

#Reinstall plyr library that for some reason is being upgraded by Bioconductor despite being told not to
cd $CUSTOM_DIR
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library plyr_1.4.tar.gz

#CopyCat relies on some bioconductor packages
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library copyCat_1.6.2.tar.gz

#Install CopyCat R package manually -> 'copyCat'
#echo "INSTALLING COPYCAT MANUALLY"
#echo $CUSTOM_DIR
#cd $CUSTOM_DIR
#git clone https://github.com/chrisamiller/copyCat.git
#cd $CUSTOM_DIR/copyCat
#export COPYCAT_VERSION=$(grep "Version" copyCat/DESCRIPTION | awk '{print $2}')
#$R_BIN CMD build copyCat
#$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library copyCat_$COPYCAT_VERSION.tar.gz

#Install pbh5 package -> 'pbh5'
#echo "INSTALLING PBH5 MANUALLY"
#cd $CUSTOM_DIR
#git clone https://github.com/PacificBiosciences/R-pbh5.git
#tar -cf pbh5.tar R-pbh5/
#gzip pbh5.tar
#$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library pbh5.tar.gz

#Test that all R packages can load
echo "TESTING THAT ALL R PACKAGES CAN LOAD"
$R_BIN CMD BATCH $DIR/test_r_packages.R $R_INSTALL_DIR/test_r_packages.stdout

#Make sure 'cairo' is used for bitmap creation instead of 'Xlib' by creating a setting in a .Rprofile file
bash -c 'echo options\(bitmapType = \"cairo\"\) > $R_INSTALL_DIR/etc/.Rprofile'

#Display the result of the final test
cat $R_INSTALL_DIR/test_r_packages.stdout | grep "\[1\]"


