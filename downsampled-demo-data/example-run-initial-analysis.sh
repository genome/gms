#!/bin/bash -x

#
# INTRODUCTION
#
# This script describes how to run analysis for data imported by
# example-import-data.sh.
#

echo "*"
echo "*"
echo "Examine this script in your favorite editor for background on each command."
echo "*"
echo "*"


#
# Each analysis of a given genome sample creates a "model" of that genome,
# with a processing profile describing the exact analysis methods in detail.
#
# The following samples from example-import-data.sh are processed below:
#

SAMPLE_TUMOR='H_NJ-HCC1395ds-HCC1395'
SAMPLE_NORMAL='H_NJ-HCC1395ds-HCC1395_BL'
SAMPLE_RNA_TUMOR='H_NJ-HCC1395ds-HCC1395_RNA'
SAMPLE_RNA_NORMAL='H_NJ-HCC1395ds-HCC1395_BL_RNA'

#
# We will define a model for each sample, assign all of the data for
# to the respective models, then "build" the model.  The result will be our
# state of belief about the sequence and features of the given genome,
# according to the processing profile, given the data.
#

# These processing profiles  were imported into the system at installation time:

PROCESSING_PROFILE_MICROARRAY='infinium wugc'
PROCESSING_PROFILE_REFERENCE_ALIGNMENT='Default Reference Alignment'
PROCESSING_PROFILE_RNA_SEQ='Default Ovation V2 RNA-seq'
PROCESSING_PROFILE_DIFF_EXP='cuffcompare/cuffdiff 2.0.2 protein_coding only'
PROCESSING_PROFILE_SOMATIC_VARIATION_EXOME='Default Somatic Variation Exome'
PROCESSING_PROFILE_SOMATIC_VARIATION_WGS='Default Somatic Variation WGS'
PROCESSING_PROFILE_CLININCAL_SEQUENCING='Default Clinical Sequencing'

#
# Other inputs/params used below:
#
# Each model below will take instrument-data from the genome in question
# as inputs.  The reads are converged with other input data, including
# reference sequences and annotation, to create a final product.
#

# The other data sets are identified by the following, and explained below.

GENOME_BUILD_REFERENCE='GRCh37-lite'            #build id 106942997
GENOME_BUILD_ANNOTATION='NCBI-human.ensembl'    #build id 124434505
GENOME_BUILD_DBSNP='dbsnp-GRCh37-lite-build37'  #build id 127786607
ANNOTATION_DB_COSMIC='cosmic/61.1'
ANNOTATION_DB_TGI_CANCER='tgi/cancer-annotation/human/build37-20130401.1'
ANNOTATION_DB_TGI_MISC='tgi/misc-annotation/human/build37-20130113.1'
CAPTURE_TARGET_REGIONS='NimbleGen v3 Capture Chip Set'

# Look at any of these individually, or list them in bulk:

genome processing-profile view "name='Default Somatic Variation WGS'"
genome processing-profile list reference-alignment "name='Default Ovation V2 RNA-seq'"


# If we had microarray data for this sample we would process it first.
# The results can be an input to QC downstream analysis.
# 
# MODEL_MICROARRAY_TUMOR='hcc1395-tumor-snparray'
# genome model define genotype-microarray                                       \
#     --model-name="$MODEL_MICROARRAY_TUMOR"                                    \
#     --processing-profile="$PROCESSING_PROFILE_MICROARRAY"                     \
#     --subject="$SAMPLE_TUMOR"                                                 \
#     --instrument-data='2891080777'                                            \
#     --reference="$GENOME_BUILD_REFERENCE"                                     \
#     --dbsnp-build="$GENOME_BUILD_DBSNP"
#
# MODEL_MICROARRAY_NORMAL='hcc1395-normal-snparray'
# genome model define genotype-microarray                                       \
#     --model-name="$MODEL_MICROARRAY_NORMAL"                                   \
#     --processing-profile="$PROCESSING_PROFILE_MICROARRAY"                     \
#     --subject="$SAMPLE_NORMAL"                                                \
#     --instrument-data='2891080776'                                            \
#     --reference="$GENOME_BUILD_REFERENCE"                                     \
#     --dbsnp-build="$GENOME_BUILD_DBSNP"
#     #alteratively, can these just point to the model directly (instead of the model's build)?
#     #or perhaps it doesn't matter since these builds come with the system right now
#
# genome model build start "name in ['$MODEL_MICROARRAY_TUMOR', '$MODEL_MICROARRAY_NORMAL']

#
# Start by defining a model of the tumor DNA using WGS data only.
# The model of exome data, done below, will use processing tuned for capture.
#

MODEL_TUMOR_REFALIGN_WGS='hcc1395-tumor-refalign-wgs-ds'
genome model define reference-alignment                                         \
    --model-name="$MODEL_TUMOR_REFALIGN_WGS"                                    \
    --subject="$SAMPLE_TUMOR"                                                   \
    --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
    --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"
    #--genotype-microarray="$MODEL_MICROARRAY_TUMOR"

# Now add all five lanes of tumor DNA data intended for WGS analysis.
# (No capture probes were used, which require special analysis.)

genome model instrument-data assign                                             \
    --model="$MODEL_TUMOR_REFALIGN_WGS"                                         \
    --instrument-data="description ike 'tumor wgs %'"

# And start building on the compute cluster, running the associated workflow:

genome model build start "name='$MODEL_TUMOR_REFALIGN_WGS'"

#
# Now do the same for the normal WGS data.
# Define, add three lanes of the normal WGS lanes of data, and start building.
#

MODEL_NORMAL_REFALIGN_WGS='hcc1395-normal-refalign-wgs-ds'
genome model define reference-alignment                                         \
    --model-name="$MODEL_NORMAL_REFALIGN_WGS"                                   \
    --subject="$SAMPLE_NORMAL"                                                  \
    --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
    --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
    #--genotype-microarray='TODO: :2891230330'

genome model instrument-data assign                                             \
    --model="$MODEL_NORMAL_REFALIGN_WGS"                                        \
    --instrument-data="description like 'normal wgs %'"

genome model build start "name='$MODEL_NORMAL_REFALIGN_WGS'"

#
# Next define the other models that process reads directly.
# As above, we define a model for the genome of each sample,
# and assign all of the appropriate data.
#

MODEL_TUMOR_REFALIGN_EXOME='hcc1395-tumor-refalign-exome-ds'
genome model define reference-alignment                                         \
    --model-name="$MODEL_TUMOR_REFALIGN_EXOME"                                  \
    --subject="$SAMPLE_TUMOR"                                                   \
    --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
    --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
    --region-of-interest-set-name="$CAPTURE_TARGET_REGIONS"                     \
    --target-region-set-name="$CAPTURE_TARGET_REGIONS"                          \
    #--genotype-microarray="$MODEL_MICROARRAY_TUMOR"

genome model instrument-data assign                                             \
    --model="$MODEL_TUMOR_REFALIGN_EXOME"                                       \
    --instrument-data="description='tumor exome 1'"

genome model build start "name='$MODEL_TUMOR_REFALIGN_EXOME'"

#

MODEL_NORMAL_REFALIGN_EXOME='hcc1395-normal-refalign-exome-ds'
genome model define reference-alignment                                         \
    --model-name="$MODEL_NORMAL_REFALIGN_EXOME"                                 \
    --subject="$SAMPLE_NORMAL"                                                  \
    --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
    --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
    --region-of-interest-set-name="$CAPTURE_TARGET_REGIONS"                     \
    --target-region-set-name="$CAPTURE_TARGET_REGIONS"
    #--genotype-microarray='TODO: :2891230330'

genome model instrument-data assign                                             \
    --model="$MODEL_NORMAL_REFALIGN_EXOME"                                      \
    --instrument-data="description='normal exome 1'"

genome model build start "name='$MODEL_NORMAL_REFALIGN_EXOME'"

#

MODEL_TUMOR_RNASEQ='hcc1395-tumor-rnaseq-ds'
genome model define rna-seq                                                     \
    --model-name="$MODEL_TUMOR_RNASEQ"                                          \
    --subject="$SAMPLE_RNA_TUMOR"                                               \
    --processing-profile="$PROCESSING_PROFILE_RNA_SEQ"                          \
    --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --instrument-data="sample_name=$SAMPLE_RNA_TUMOR"

genome model instrument-data assign                                             \
    --model="$MODEL_TUMOR_RNASEQ"                                               \
    --instrument-data="description='normal exome 1'"

genome model build start "name='$MODEL_TUMOR_RNASEQ'"

#

MODEL_NORMAL_RNASEQ='hcc1395-normal-rnaseq-ds'
genome model define rna-seq                                                     \
    --model-name="$MODEL_NORMAL_RNASEQ"                                         \
    --subject="$SAMPLE_RNA_NORMAL"                                              \
    --processing-profile="$PROCESSING_PROFILE_RNA_SEQ"                          \
    --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --instrument-data="sample_name=$SAMPLE_RNA_NORMAL"


genome model instrument-data assign                                             \
    --model="$MODEL_NORMAL_RNASEQ"                                              \
    --instrument-data="description='normal exome 1'"

genome model build start "name='$MODEL_NORMAL_RNASEQ'"


#
# CONCLUSION
#
# The above commands configure and launch direct analysis of
# instrument data.
#
# Next we will monitor the build process, and then use
# those models as inputs to higher-order models:
#
# example-monitor-builds.sh
# example-run-downstream-analysis.sh
# 

