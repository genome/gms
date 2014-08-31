#!/bin/bash -x

#
# INTRODUCTION
#
# This script demonstrates how to add data to the system from the command-line,
# in preparation to launch analysis.
#

#Set the instrument data directory to where bam files were downloaded
INSTRUMENT_DATA_DIRECTORY='/opt/bam'

#
# Add one individual to the system representing the research/clinical subject.
# - name: is an internal, unique, immutable, deidentified system name.
# - upn: can be the same, or contain an external global unique name.
# - common_name: allows a shorter, human-friendy name to be given which can
#      be updated over time as needed.
# - taxon: for all data in this experiment the preloaded "human" taxon is used.
#

INDIVIDUAL='HCC1143'
genome individual create                                                        \
    --name="$INDIVIDUAL"                                                        \
    --upn='HCC1143'                                                           \
    --common-name="HCC1143"                                                      \
    --gender=female                                                             \
    --taxon="name=human"

#
# The individual can now be found by the command line and web interfaces.
#

genome individual list "name='$INDIVIDUAL'"

#
# Add samples to the system, one for each case of DNA or RNA extraction. 
#
# [1] DNA from tumor  tissue : HCC1143_DNA
# [2] DNA from normal tissue : HCC1143BL_DNA
# [3] RNA from tumor  tissue : HCC1143_RNA
#
# The essential characteristics of each sample are:
# - extraction type: either "genomic dna" or "rna"
# - source: identify the individual from which the sample came
# - name: a unique immutable identifier (can be a barcode)
# - common name: a friendly name that can be updated liesure
# - extraction label: any unique name for the source tissue (can match "name")
# - tissue desc: describe the tissue (informational, does not affect processing)

SAMPLE_TUMOR='HCC1143_DNA'
genome sample create                                                            \
    --extraction-type='genomic dna'                                             \
    --source="name=$INDIVIDUAL"                                                 \
    --name=$SAMPLE_TUMOR                                                        \
    --common-name='tumor'                                                       \
    --extraction-label='HCC1143_DNA'                                                \
    --tissue-desc='epithelial'

SAMPLE_NORMAL='HCC1143BL_DNA'
genome sample create                                                            \
    --extraction-type='genomic dna'                                             \
    --source="name=$INDIVIDUAL"                                                 \
    --name=$SAMPLE_NORMAL                                                       \
    --common-name='normal'                                                      \
    --extraction-label='HCC1143BL_DNA'                                             \
    --tissue-desc='b lymphoblast'

SAMPLE_RNA_TUMOR='HCC1143_RNA'
genome sample create                                                            \
    --extraction-type='rna'                                                     \
    --source="name=$INDIVIDUAL"                                                 \
    --name=$SAMPLE_RNA_TUMOR                                                    \
    --common-name='tumor'                                                       \
    --extraction-label='HCC1143_RNA'                                            \
    --tissue-desc='epithelial'

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

# One library of tumor DNA was used for exome sequencing.
# NOTE: From the GEO sample page for library construction we can learn that the targeted library insert size was 150bp.

CAPTURE_LIBRARY_TUMOR='HCC1143-capture-lib1'
genome library create                                                           \
  --name="$CAPTURE_LIBRARY_TUMOR"                                               \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --library-insert-size='150'

# One library of normal DNA used for exome sequencing.

CAPTURE_LIBRARY_NORMAL='HCC1143BL-capture-lib1'
genome library create                                                           \
  --name="$CAPTURE_LIBRARY_NORMAL"                                              \
  --sample="$SAMPLE_NORMAL"                                                     \
  --protocol='Illumina Library Construction'                                    \
  --library-insert-size='150'

# One library of tumor RNA.

LIBRARY_RNA_TUMOR='HCC1143_RNA-lib1'
genome library create                                                           \
  --name="$LIBRARY_RNA_TUMOR"                                                   \
  --sample="$SAMPLE_RNA_TUMOR"                                                  \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='150'                                                  \
  --library-insert-size='150'                                                   \
  --transcript-strand='unstranded'

# Each is listable once created:

genome library list "sample.patient.common_name='HCC1143'"
genome library list "sample.name='$SAMPLE_TUMOR' and library_insert_size > 100"

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
# The GMS prefers reads to be in BAM format (pre alignment), for efficiency.
# Note that the flow_cell_id, lane, and index sequence are extracted from
# the BAM name automatically.
#
# Note that the number of clusters can be obtained from "# of Spots" the SRA record pages

genome instrument-data import basic                                             \
    --description='tumor rna 1'                                                 \
    --import-source-name='GEO_SRA'                                               \
    --instrument-data-properties='clusters=25116917'                           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/SRR925702_1.bam"   \
    --library="$LIBRARY_RNA_TUMOR"

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
    --import-source-name='GEO_SRA'                                                         \
    --instrument-data-properties="clusters=72512840,target_region_set_name=$TARGET_SET" \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/SRR925765_1.bam"             \
    --library="$CAPTURE_LIBRARY_TUMOR"

genome instrument-data import basic                                                       \
    --description='normal exome 1'                                                        \
    --import-source-name='GEO_SRA'                                                         \
    --instrument-data-properties="clusters=36138317,target_region_set_name=$TARGET_SET" \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/SRR925766_1.bam"             \
    --library="$CAPTURE_LIBRARY_NORMAL"

# All instrument-data is listable as above, and can be filtered by params.
genome instrument-data list imported "sample.patient.common_name='HCC1143' and sample.extraction_type = 'genomic dna'"
genome instrument-data list imported "sample.patient.common_name='HCC1143' and sample.extraction_type = 'rna'"

#
# CONCLUSION
#
# We now have imported a variety of sets of reads from the Illumina sequencer,
# along with background metadata.
#
# See the next script: example-run-initial-analysis.sh to run analysis.
# An alternative is to use the helper tool: genome model clin-seq advise --allow-imported --individual='common_name=HCC1143'
# 

