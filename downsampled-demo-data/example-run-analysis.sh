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


# Each analysis of a given genome creates a "model" of that genome,
# with a processing profile describing the exact analysis methods
# in detail.
#
# We will define a model for each sample, assign all of the data for
# to the respective models, then "build" the model.  The result will be our
# state of belief about the sequence and features of the given genome,
# according to the processing profile, given the data.

#
# Other inputs/params used below:
#
# Each model we define below will take instrument-data or other inputs.
# It will also take a processing profile, describing the exact computational
# workflow.

# The other data sets are identified by the following, and explained below.

GENOME_BUILD_REFERENCE='GRCh37-lite'            #build id 106942997
GENOME_BUILD_ANNOTATION='NCBI-human.ensembl'    #build id 124434505
GENOME_BUILD_DBSNP='dbsnp-GRCh37-lite-build37'  #build id 127786607
ANNOTATION_DB_COSMIC='cosmic/61.1'
ANNOTATION_DB_TGI_CANCER='tgi/cancer-annotation/human/build37-20130401.1'
ANNOTATION_DB_TGI_MISC='tgi/misc-annotation/human/build37-20130113.1'
CAPTURE_TARGET_REGIONS='NimbleGen v3 Capture Chip Set'

# These processing profiles  were imported into the system at installation time:

PROCESSING_PROFILE_MICROARRAY='infinium wugc'
PROCESSING_PROFILE_REFERENCE_ALIGNMENT='Default Reference Alignment'
PROCESSING_PROFILE_RNA_SEQ='Default Ovation V2 RNA-seq'
PROCESSING_PROFILE_DIFF_EXP='cuffcompare/cuffdiff 2.0.2 protein_coding only'
PROCESSING_PROFILE_SOMATIC_VARIATION_EXOME='Default Somatic Variation Exome'
PROCESSING_PROFILE_SOMATIC_VARIATION_WGS='Default Somatic Variation WGS'
PROCESSING_PROFILE_CLININCAL_SEQUENCING='Default Clinical Sequencing'

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


# Start by defining a model of the tumor DNA using WGS data only.

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


# Now do the same for the normal WGS data.
# Define, add three lanes of the normal WGS lanes of data, and start building.

MODEL_REF_ALIGN_NORMAL_WGS='hcc1395-normal-refalign-wgs-ds'
genome model define reference-alignment                                         \
    --model-name="$MODEL_REF_ALIGN_NORMAL_WGS"                                  \
    --subject="$SAMPLE_NORMAL"                                                  \
    --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
    --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
    #--genotype-microarray='TODO: :2891230330'

genome model instrument-data assign                                             \
    --model="$MODEL_REF_ALIGN_NORMAL_WGS"                                       \
    --instrument-data="description like 'normal wgs %'"

genome model build start "name='$MODEL_REF_ALIGN_NORMAL_WGS'"


# Next define the other models that process reads directly.

MODEL_TUMOR_REFALIGN_EXOME='hcc1395-tumor-refalign-exome-ds'
genome model define reference-alignment                                         \
    --model-name="$MODEL_TUMOR_REFALIGN_EXOME"                                  \
    --subject="$SAMPLE_TUMOR"                                                   \
    --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
    --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
    --region-of-interest-set-name="$CAPTURE_TARGET_REGIONS"                               \
    --target-region-set-name="$CAPTURE_TARGET_REGIONS"                       \
    #--genotype-microarray="$MODEL_MICROARRAY_TUMOR"

genome model instrument-data assign                                             \
    --model="$MODEL_TUMOR_REFALIGN_EXOME"                                       \
    --instrument-data="description='tumor exome 1'"

MODEL_REF_ALIGN_NORMAL_EXOME='hcc1395-normal-refalign-exome-ds'
genome model define reference-alignment                                         \
    --model-name="$MODEL_REF_ALIGN_NORMAL_EXOME"                                \
    --subject="$SAMPLE_NORMAL"                                                  \
    --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
    --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
    --region-of-interest-set-name="$CAPTURE_TARGET_REGIONS"                               \
    --target-region-set-name="$CAPTURE_TARGET_REGIONS"
    #--genotype-microarray='TODO: :2891230330'

genome model instrument-data assign                                             \
    --model="$MODEL_REF_ALIGN_NORMAL_EXOME"                                     \
    --instrument-data="description='normal exome 1'"

MODEL_TUMOR_RNASEQ='hcc1395-tumor-rnaseq-ds'
genome model define rna-seq                                                     \
    --model-name="$MODEL_TUMOR_RNASEQ"                                          \
    --subject="$SAMPLE_RNA_TUMOR"                                               \
    --processing-profile="$PROCESSING_PROFILE_RNA_SEQ"                          \
    --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --instrument-data="sample_name=$SAMPLE_RNA_TUMOR"

MODEL_NORMAL_RNASEQ='hcc1395-normal-rnaseq-ds'
genome model define rna-seq                                                     \
    --model-name="$MODEL_NORMAL_RNASEQ"                                         \
    --subject="$SAMPLE_RNA_NORMAL"                                              \
    --processing-profile="$PROCESSING_PROFILE_RNA_SEQ"                          \
    --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --instrument-data="sample_name=$SAMPLE_RNA_NORMAL"

#### RESUME HERE

#
# 4) DEFINE HIGHER-LEVEL MODELS
#

function get_genome_model_id {
    local MODEL_NAME=$1
    genome model list --show id "name='$MODEL_NAME'"|tail --line=+3
}


if (( $DEFINE_MODELS ))
then
    MODEL_NORMAL_RNASEQ_ID=$(get_genome_model_id $MODEL_NORMAL_RNASEQ)
    MODEL_TUMOR_RNASEQ_ID=$(get_genome_model_id $MODEL_TUMOR_RNASEQ)
    MODEL_DIFFERENTIAL_EXPRESSION='hcc1395-differential-expression-ds'
    genome model define differential-expression                                     \
        --model-name="$MODEL_DIFFERENTIAL_EXPRESSION"                               \
        --subject="$INDIVIDUAL"                                                     \
        --processing-profile="$PROCESSING_PROFILE_DIFF_EXP"                         \
        --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
        --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
        --condition-labels-string='normal,tumor'                                    \
        --condition-model-ids-string="$MODEL_NORMAL_RNASEQ_ID $MODEL_TUMOR_RNASEQ_ID"
    #
    MODEL_SOMATIC_VARIATION_EXOME='hcc1395-somatic-exome-ds'
    genome model define somatic-variation                                           \
        --model-name="$MODEL_SOMATIC_VARIATION_EXOME"                               \
        --subject="$SAMPLE_TUMOR"                                                   \
        --processing-profile="$PROCESSING_PROFILE_SOMATIC_VARIATION_EXOME"          \
        --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
        --previously-discovered-variations="model_name=$GENOME_BUILD_DBSNP"         \
        --normal-model="$MODEL_REF_ALIGN_NORMAL_EXOME"                              \
        --tumor-model="$MODEL_TUMOR_REFALIGN_EXOME"
    #
    MODEL_SOMATIC_VARIATION_WGS='hcc1395-somatic-wgs-ds'
    genome model define somatic-variation                                           \
        --model-name="$MODEL_SOMATIC_VARIATION_WGS"                                 \
        --subject="$SAMPLE_TUMOR"                                                   \
        --processing-profile="$PROCESSING_PROFILE_SOMATIC_VARIATION_WGS"            \
        --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
        --previously-discovered-variations="model_name=$GENOME_BUILD_DBSNP"         \
        --tumor-model="$MODEL_TUMOR_REFALIGN_WGS"                                   \
        --normal-model="$MODEL_REF_ALIGN_NORMAL_WGS"
    #
    genome model define clin-seq                                                    \
        --name='hcc1395-clinseq-ds'                                                    \
        --processing-profile="$PROCESSING_PROFILE_CLININCAL_SEQUENCING"             \
        --cancer-annotation-db="$ANNOTATION_DB_COSMIC"                              \
        --cancer-annotation-db="$ANNOTATION_DB_TGI_CANCER"                          \
        --misc-annotation-db="$ANNOTATION_DB_TGI_MISC"                              \
        --de-model="$MODEL_DIFFERENTIAL_EXPRESSION"                                 \
        --tumor-rnaseq-model="$MODEL_TUMOR_RNASEQ"                                  \
        --normal-rnaseq-model="$MODEL_NORMAL_RNASEQ"                                \
        --exome-model="$MODEL_SOMATIC_VARIATION_EXOME"                              \
        --wgs-model="$MODEL_SOMATIC_VARIATION_WGS"
    #
fi



#
# CONCLUSION
#
# Now a new individual, four samples, and several models have been created
# within GMS.  We are now ready to begin processing the data that we have imported
# by starting builds on the models that we have just defined.
#

####

# This process happens in a series of steps:
# 1) Declare database entities setup during `genome model import metadata`.
# 2) Create a database entity for an individual for which we have
#    several samples for which we would like instrument data imported.
# 3) Create database entities for each sample:
#    a) Create a database entity for the sample itself.
#    b) Create a database entity for each instrument data file
#       by importing the instrument data file into GMS.
#    c) Define models particular to the sample.
# 4) Define higher-level models which span multiple samples
#    by referring to lower-level models created for individual samples.
#
# When we are done with these steps, GMS will be ready to processes
# the data by running builds on the models that we have defined.
#

