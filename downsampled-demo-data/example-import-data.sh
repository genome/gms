#!/bin/bash -x

#
# INTRODUCTION
#
# This script demonstrates how to add data to the system from the command-line,
# in preparation to launch analysis.
#

#
# ** NAMING NOTE
# 
# This example uses a downsampled copy of the "TST1" patient data
# described in the paper.  To avoid collision with the full test data,
# the patient has"ds1" appended to the name.  All other data embeds
# the patient identifier at the beginning.
#

echo "*"
echo "*"
echo "* Examine this script in your favorite editor for details on each step."
echo "*"
echo "*"

#
# Download downsampled data.
# A smaller set of reads allows the pipeline to run quickly, though usable
# results are unlikely without depth of converage.
#

INSTRUMENT_DATA_DIRECTORY='.'

echo Downloading downsampled instrument data to $INSTRUMENT_DATA_DIRECTORY
wget --no-directories --recursive --continue --no-parent --accept='*.bam' \
  --directory-prefix "$INSTRUMENT_DATA_DIRECTORY" \
  https://xfer.genome.wustl.edu/gxfer1/project/gms/testdata/bams/hcc1395_1tenth_percent/


#
# Add one individual to the system representing the research/clinical subject.
# - name: is an internal, unique, immutable, deidentified system name.
# - upn: can be the same, or contain an external global unique name.
# - common_name: allows a shorter, human-friendy name to be given which can
#      be updated over time as needed.
# - taxon: for all data in this experiment the preloaded "human" taxon is used.
#

INDIVIDUAL='H_NJ-HCC1395ds'
genome individual create                                                        \
    --name="$INDIVIDUAL"                                                        \
    --upn='HCC1395ds'                                                           \
    --common-name="TST1ds"                                                      \
    --gender=female                                                             \
    --taxon="name=human"

#
# The individual can now be found by the command line and web interfaces.
#

genome individual list "name='$INDIVIDUAL'"

#
# Add samples to the system, one for each case of DNA or RNA extraction. 
#
# [1] DNA from tumor  tissue : H_NJ-HCC1395-HCC1395
# [2] DNA from normal tissue : H_NJ-HCC1395-HCC1395_BL
# [3] RNA from tumor  tissue : H_NJ-HCC1395-HCC1395_RNA
# [4] RNA from normal tissue : H_NJ-HCC1395-HCC1395_BL_RNA
#
# The essential characteristics of each sample are:
# - extraction type: either "genomic dna" or "rna"
# - source: identify the individual from which the sample came
# - name: a unique immutable identifier (can be a barcode)
# - common name: a friendly name that can be updated liesure
# - extraction label: any unique name for the source tissue (can match "name")
# - tissue desc: describe the tissue (informational, does not affect processing)

SAMPLE_TUMOR='H_NJ-HCC1395ds-HCC1395'
genome sample create                                                            \
    --extraction-type='genomic dna'                                             \
    --source="name=$INDIVIDUAL"                                                 \
    --name=$SAMPLE_TUMOR                                                        \
    --common-name='tumor'                                                       \
    --extraction-label='HCC1395'                                                \
    --tissue-desc='epithelial'

SAMPLE_NORMAL='H_NJ-HCC1395ds-HCC1395_BL'
genome sample create                                                            \
    --extraction-type='genomic dna'                                             \
    --source="name=$INDIVIDUAL"                                                 \
    --name=$SAMPLE_NORMAL                                                       \
    --common-name='normal'                                                      \
    --extraction-label='HCC1395 BL'                                             \
    --tissue-desc='b lymphoblast'

SAMPLE_RNA_TUMOR='H_NJ-HCC1395ds-HCC1395_RNA'
genome sample create                                                            \
    --extraction-type='rna'                                                     \
    --source="name=$INDIVIDUAL"                                                 \
    --name=$SAMPLE_RNA_TUMOR                                                    \
    --common-name='tumor'                                                       \
    --extraction-label='HCC1395_RNA'                                            \
    --tissue-desc='epithelial'

SAMPLE_RNA_NORMAL='H_NJ-HCC1395ds-HCC1395_BL_RNA'
genome sample create                                                            \
  --extraction-type='rna'                                                       \
  --source="name=$INDIVIDUAL"                                                   \
  --name=$SAMPLE_RNA_NORMAL                                                     \
  --common-name='normal'                                                        \
  --extraction-label='HCC1395 BL_RNA'                                           \
  --tissue-desc='b lymphoblast'

# All of these are visible by the command line now:

genome sample list "source.name='$INDIVIDUAL'"
genome sample list "source.name='$INDIVIDUAL' and extraction_type='rna'"
genome sample list "source.name='$INDIVIDUAL' and common_name like '%tumor'"

#
# DNA Fragment Libraries:
#
# Each sample will have one or more libraries of DNA fragments in the system.
# A library represents a specific set of DNA fragments, with expected 
# fragment size, and possibly stranding data (for RNA).
# 
# It is often useful to create multiple independent fragment libraries
# from the same sample, typically with different fragment sizes.  It is
# important to record this acurately before and connect all reads
# to the correct library for fully empowered analysis.
#

# Three libraries from the tumor DNA used for WGS sequencing.

LIBRARY_TUMOR_1='H_NJ-HCC1395ds-HCC1395-lig2-lib1'
genome library create                                                           \
  --name="$LIBRARY_TUMOR_1"                                                     \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='271'                                                  \
  --library-insert-size='390'

LIBRARY_TUMOR_2='H_NJ-HCC1395ds-HCC1395-lig2-lib2'
genome library create                                                           \
  --name="$LIBRARY_TUMOR_2"                                                     \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='390'                                                  \
  --library-insert-size='509'

LIBRARY_TUMOR_3='H_NJ-HCC1395-HCC1395-lig2-lib3ds'
genome library create                                                           \
  --name="$LIBRARY_TUMOR_3"                                                     \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='550'                                                  \
  --library-insert-size='669'

# Three libraries of normal DNA used for WGS sequencing.

LIBRARY_NORMAL_1='H_NJ-HCC1395-HCC1395_BL-lig2-lib1ds'
genome library create                                                           \
  --name="$LIBRARY_NORMAL_1"                                                    \
  --sample="$SAMPLE_NORMAL"                                                     \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='266'                                                  \
  --library-insert-size='385'

LIBRARY_NORMAL_2='H_NJ-HCC1395-HCC1395_BL-lig2-lib2ds'
genome library create                                                           \
  --name="$LIBRARY_NORMAL_2"                                                    \
  --sample="$SAMPLE_NORMAL"                                                     \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='381'                                                  \
  --library-insert-size='500'

LIBRARY_NORMAL_3='H_NJ-HCC1395-HCC1395_BL-lig2-lib3ds'
genome library create                                                           \
  --name="$LIBRARY_NORMAL_3"                                                    \
  --sample="$SAMPLE_NORMAL"                                                     \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='557'                                                  \
  --library-insert-size='676'

# One library of tumor DNA used for exome sequencing.

CAPTURE_LIBRARY_TUMOR='libgroup-2891242741ds'
genome library create                                                           \
  --name="$CAPTURE_LIBRARY_TUMOR"                                               \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --library-insert-size='364-400'

# One library of normal DNA used for exome sequencing.

CAPTURE_LIBRARY_NORMAL='libgroup-2891242742ds'
genome library create                                                           \
  --name="$CAPTURE_LIBRARY_NORMAL"                                              \
  --sample="$SAMPLE_NORMAL"                                                     \
  --protocol='Illumina Library Construction'                                    \
  --library-insert-size='364-400'

# Oner libarary of tumor RNA.

LIBRARY_RNA_TUMOR='H_NJ-HCC1395ds-HCC1395_RNAds-lib1'
genome library create                                                           \
  --name="$LIBRARY_RNA_TUMOR"                                                   \
  --sample="$SAMPLE_RNA_TUMOR"                                                  \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='264'                                                  \
  --library-insert-size='383'                                                   \
  --transcript-strand='unstranded'

# One library of normal RNA.

LIBRARY_RNA_NORMAL='H_NJ-HCC1395ds-HCC1395_BL_RNA-lib1'
genome library create                                                           \
  --name="$LIBRARY_RNA_NORMAL"                                                  \
  --sample="$SAMPLE_RNA_NORMAL"                                                 \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='364'                                                  \
  --library-insert-size='483'                                                   \
  --transcript-strand='unstranded'

# Each is listable once created:

genome library list "sample.patient.common_name='TST1ds'"
genome library list "sample.name='$SAMPLE_TUMOR' and original_insert_size > 300"

#
# Reads:
#
# Each "instrument data" can represent sequence reads, microarray data,
# or any other data emitted by a laboratory instrument to be used as 
# an input to analysis.  For this example all are Illumina NGS reads.
#
# For indexed data, there is one instrument data entry per
# flow cell + lane + index. For unindexed data, there is one per
# flow cell + lane.
#
# The GMS prefers reads to be in BAM format (pre alignmnet), for efficiency.
# Note that the flow_cell_id, lane, and index sequence are extracted from
# the BAM name automatically.
#

# The tumor has multiple WGS instrument data for the first two
# DNA fragment libraries:

genome instrument-data import basic                                             \
    --description='tumor wgs 1'                                                 \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=188429464'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_1.bam"          \
    --library="$LIBRARY_TUMOR_1"

genome instrument-data import basic                                             \
    --description='tumor wgs 2'                                                 \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=193216396'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_2.bam"          \
    --library="$LIBRARY_TUMOR_1"

genome instrument-data import basic                                             \
    --description='tumor wgs 3'                                                 \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=189430115'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_3.bam"          \
    --library="$LIBRARY_TUMOR_2"

genome instrument-data import basic                                             \
    --description='tumor wgs 4'                                                 \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=190192103'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_4.bam"          \
    --library="$LIBRARY_TUMOR_2"

# For the third tumor DNA library, there is one WGS instrument data.
# There is also only one exome capture instrument data for tumor and normal,
# and one for all of the normal libraries, wgs and exome, and for all RNA.

genome instrument-data import basic                                             \
    --description='tumor wgs 5'                                                 \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=180487649'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_5.bam"          \
    --library="$LIBRARY_TUMOR_3"

genome instrument-data import basic                                             \
    --description='normal wgs 1'                                                \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=168472676'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_6.bam"          \
    --library="$LIBRARY_NORMAL_1"

genome instrument-data import basic                                             \
    --description='normal wgs 2'                                                \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=175170815'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_7.bam"          \
    --library="$LIBRARY_NORMAL_2"

genome instrument-data import basic                                             \
    --description='normal wgs 3'                                                \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=171892537'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_8.bam"          \
    --library="$LIBRARY_NORMAL_3"

genome instrument-data import basic                                             \
    --description='tumor rna 1'                                                 \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=156248832'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_C1TD1ACXX_8_ACAGTG.bam"   \
    --library="$LIBRARY_RNA_TUMOR"

genome instrument-data import basic                                             \
    --description='normal rna 1'                                                \
    --import-source-name='TST1ds'                                               \
    --instrument-data-properties='clusters=170049877'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_C2DBEACXX_3.bam"          \
    --library="$LIBRARY_RNA_NORMAL"

#
# Note that for targeted data a "target_region_set_name" is specfied.
# The value is used to look-up a set of positions in the system
# which were pre-loaded during installation.
# 
# See "genome feature-list --help" for more details.
#

TARGET_SET='NimbleGen v3 Capture Chip Set'

genome instrument-data import basic                                                       \
    --description='tumor exome 1'                                                         \
    --import-source-name='TST1ds'                                                         \
    --instrument-data-properties='clusters=96056889,target_region_set_name="$TARGET_SET"' \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_C1TD1ACXX_7_ATCACG.bam"             \
    --library="$CAPTURE_LIBRARY_TUMOR"

genome instrument-data import basic                                                       \
    --description='normal exome 1'                                                        \
    --import-source-name='TST1ds'                                                         \
    --instrument-data-properties='clusters=77667085,target_region_set_name="$TARGET_SET"' \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_C1TD1ACXX_7_CGATGT.bam"             \
    --library="$CAPTURE_LIBRARY_NORMAL"

# All instrument-data is listable as above, and can be filtered by params.
genome instrument-data list imported "sample.patient.common_name='TST1ds' and sample.extraction_type = 'genomic dna'"
genome instrument-data list imported "sample.patient.common_name='TST1ds' and sample.extraction_type = 'rna'"

#
# CONCLUSION
#
# We now have imported a variety of sets of reads from the Illumina sequencer,
# along with background metadata.
#
# See the next script: example-run-analysis.sh to run analysis.
#

