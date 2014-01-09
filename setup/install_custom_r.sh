#!/bin/bash
#Install a custom version of R and R packages needed
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script dir is " $DIR

#Install a specific version of R to custom location
export R_VERSION="R-2.15.2"
echo "INSTALLING R VERSION" $R_VERSION
mkdir -p $GENOME_SW/R/
cd $GENOME_SW/R/
wget http://cran.r-project.org/src/base/R-2/$R_VERSION.tar.gz
tar -zxvf $R_VERSION.tar.gz
cd $GENOME_SW/R/$R_VERSION
./configure --prefix=$GENOME_SW/R/$R_VERSION/ --enable-memory-profiling --with-tcltk
make
make install

#Make this first version of R to use in PATH
export PATH=$GENOME_SW/R/R_$VERSION/bin:$PATH

#Install R libraries needed from within an R session
echo "INSTALLING R LIBRARIES FROM WITHIN AN R SESSION"
echo "Script dir is " $DIR
$GENOME_SW/R/$R_VERSION/bin/R CMD BATCH $DIR/install_r_packages.R $GENOME_SW/R/$R_VERSION/install_r_packages.stdout

#Install R libraries that must be handled manually
echo "INSTALLING R LIBRARIES THAT MUST BE HANDLED MANUALLY"
mkdir $GENOME_SW/R/$R_VERSION/custom_packages
export CUSTOM_DIR="$GENOME_SW/R/$R_VERSION/custom_packages"
echo "Directory for custom packages is " $CUSTOM_DIR

#Install CopyCat R package manually -> 'copyCat'
echo $CUSTOM_DIR
cd $CUSTOM_DIR
git clone https://github.com/chrisamiller/copyCat.git
cd $CUSTOM_DIR/copyCat
export COPYCAT_VERSION=$(grep "Version" copyCat/DESCRIPTION | awk '{print $2}')
$GENOME_SW/R/$R_VERSION/bin/R CMD build copyCat
$GENOME_SW/R/$R_VERSION/bin/R CMD INSTALL --library=$GENOME_SW/R/$R_VERSION/lib/R/library copyCat_$COPYCAT_VERSION.tar.gz

#Install 'gplots' package manually -> 'gplots'
cd $CUSTOM_DIR
wget http://cran.r-project.org/src/contrib/Archive/gplots/gplots_2.8.0.tar.gz
#/opt/gms/B6H2915/sw/apps/R/R-2.15.2/lib/R/library
$GENOME_SW/R/$R_VERSION/bin/R CMD INSTALL --library=$GENOME_SW/R/$R_VERSION/lib/R/library gplots_2.8.0.tar.gz

#Install pbh5 package -> 'pbh5'
cd $CUSTOM_DIR
git clone https://github.com/PacificBiosciences/R-pbh5.git
tar -cf pbh5.tar R-pbh5/
gzip pbh5.tar
$GENOME_SW/R/$R_VERSION/bin/R CMD INSTALL --library=$GENOME_SW/R/$R_VERSION/lib/R/library pbh5.tar.gz

#Test that all R packages can load
echo "TESTING THAT ALL R PACKAGES CAN LOAD"
$GENOME_SW/R/$R_VERSION/bin/R CMD BATCH $DIR/test_r_packages.R $GENOME_SW/R/$R_VERSION/test_r_packages.stdout

#Make sure 'cairo' is used for bitmap creation instead of 'Xlib' by creating a setting in a .Rprofile file
bash -c 'echo options\(bitmapType = \"cairo\"\) > /opt/gms/XNQB947/sw/apps/R/R-2.15.2/etc/.Rprofile'

#Display the result of the final test
cat $GENOME_SW/R/$R_VERSION/test_r_packages.stdout | grep "\[1\]"


