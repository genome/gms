#!/usr/bin/env bash

INSTRUMENT_DATA_DIRECTORY='.'
DEFINE_MODELS=1

function get_genome_model_id {
    local MODEL_NAME=$1
    genome model list --show id "name='$MODEL_NAME'"|tail --line=+3
}


#
# INTRODUCTION
#
# This bash script demonstrates how a user of GMS can import instrument
# data and configure GMS to process the instrument data by defining
# a series of models on the imported instrument data.
#
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


# Download instrument data to current directory
wget --no-directories --recursive --continue --no-parent --accept='*.bam'   \
https://xfer.genome.wustl.edu/gxfer1/project/gms/testdata/bams/hcc1395_1tenth_percent/


#
# 1) DECLARATION OF EXISTING DATABASE ENTITIES
#
# These declarations enumerate entities that already exist in the
# database.  These entities have been imported by the
# `genome model import metadata` command and are required for
# at least some of the steps in this data import script.
#
# The interesting entities imported by the metadata import are the
# Processing Profiles, Genome Model Builds, and Annotation Databases.
# There is also an taxon record for Human imported by the metadata
# import process.
#
# Processing Profile Identifiers
#
PROCESSING_PROFILE_MICROARRAY='infinium wugc'
PROCESSING_PROFILE_REFERENCE_ALIGNMENT='Default Reference Alignment'
PROCESSING_PROFILE_RNA_SEQ='Default Ovation V2 RNA-seq'
PROCESSING_PROFILE_DIFF_EXP='cuffcompare/cuffdiff 2.0.2 protein_coding only'
PROCESSING_PROFILE_SOMATIC_VARIATION_EXOME='Default Somatic Variation Exome'
PROCESSING_PROFILE_SOMATIC_VARIATION_WGS='Default Somatic Variation WGS'
PROCESSING_PROFILE_CLININCAL_SEQUENCING='Default Clinical Sequencing'
#
# Genome Model Builds
#
GENOME_BUILD_ANNOTATION='NCBI-human.ensembl'    #build id 124434505
GENOME_BUILD_REFERENCE='GRCh37-lite'            #build id 106942997
GENOME_BUILD_DBSNP='dbsnp-GRCh37-lite-build37'  #build id 127786607
#
# Annotation Databases
#
ANNOTATION_DB_COSMIC='cosmic/61.1'
ANNOTATION_DB_TGI_CANCER='tgi/cancer-annotation/human/build37-20130401.1'
ANNOTATION_DB_TGI_MISC='tgi/misc-annotation/human/build37-20130113.1'
#
# Taxon
#
HUMAN_TAXON='human'
#
# Feature List
#
NIMBLEGEN_V3='NimbleGen v3 Capture Chip Set'
#



#
# 2) CREATE A DATABASE ENTITY FOR AN INDIVIDUAL
#
INDIVIDUAL='H_NJ-HCC1395ds'
genome individual create                                                        \
    --name="$INDIVIDUAL"                                                        \
    --upn='HCC1395ds'                                                             \
    --common-name="TST1ds"                                                        \
    --gender=female                                                             \
    --taxon="name=$HUMAN_TAXON"
#



#
# 3) CREATE DATABASE ENTITIES FOR EACH SAMPLE OF THE INDIVIDUAL
#
# In this example we create four entities in the database.  The four
# samples are:
# [1] RNA from normal tissue : H_NJ-HCC1395-HCC1395_BL_RNA
# [2] RNA from tumor  tissue : H_NJ-HCC1395-HCC1395_RNA
# [3] Tumor  tissue sample   : H_NJ-HCC1395-HCC1395
# [4] Normal tissue sample   : H_NJ-HCC1395-HCC1395_BL
#
# RNA From Normal Tissue
#
SAMPLE_RNA_NORMAL='H_NJ-HCC1395-HCC1395_BL_RNAds'
genome sample create                                                            \
  --name=$SAMPLE_RNA_NORMAL                                                     \
  --source="name=$INDIVIDUAL"                                                   \
  --common-name='normal'                                                        \
  --tissue-desc='b lymphoblast'                                                 \
  --extraction-type='rna'                                                       \
  --extraction-label='HCC1395 BL_RNA'                                           \
  --cell-type='primary'                                                         \
  --age=43

LIBRARY_RNA_NORMAL='Pooled_RNA_2891006726-mR1-cD1-lg1-lib1ds'
genome library create                                                           \
  --name="$LIBRARY_RNA_NORMAL"                                                  \
  --sample="$SAMPLE_RNA_NORMAL"                                                 \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='364'                                                  \
  --library-insert-size='483'                                                   \
  --transcript-strand='unstranded'

genome instrument-data import basic                                             \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=170049877'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_C2DBEACXX_3.bam"          \
    --library="$LIBRARY_RNA_NORMAL"

MODEL_NORMAL_RNASEQ='hcc1395-normal-rnaseq-ds'
if (( $DEFINE_MODELS ))
then
    genome model define rna-seq                                                     \
       --model-name="$MODEL_NORMAL_RNASEQ"                                         \
       --subject="$SAMPLE_RNA_NORMAL"                                              \
       --processing-profile="$PROCESSING_PROFILE_RNA_SEQ"                          \
       --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
       --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
       --instrument-data="sample_name=$SAMPLE_RNA_NORMAL"
       # LATER ON ANOTHER MODEL WILL REFERENCE THIS ONE
       # 1) that model's id is 18177dd5eca44514a47f367d9804e17a hcc1395-clinseq
       # 2) that model's id is abeb5a3cddb94374afffd617684fa49a hcc1395-differential-expression
fi
#
# RNA From Tumor Tissue
#
SAMPLE_RNA_TUMOR='H_NJ-HCC1395-HCC1395_RNAds'
genome sample create                                                            \
    --name=$SAMPLE_RNA_TUMOR                                                    \
    --source="name=$INDIVIDUAL"                                                 \
    --common-name='tumor'                                                       \
    --tissue-desc='epithelial'                                                  \
    --extraction-type='rna'                                                     \
    --extraction-label='HCC1395_RNA'

LIBRARY_RNA_TUMOR='Pooled_RNA_2891007020-mRNA2-cDNA-1-lig1-lib1ds'
genome library create                                                           \
  --name="$LIBRARY_RNA_TUMOR"                                                   \
  --sample="$SAMPLE_RNA_TUMOR"                                                  \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='264'                                                  \
  --library-insert-size='383'                                                   \
  --transcript-strand='unstranded'

genome instrument-data import basic                                             \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=156248832'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_C1TD1ACXX_8_ACAGTG.bam"   \
    --library="$LIBRARY_RNA_TUMOR"

MODEL_TUMOR_RNASEQ='hcc1395-tumor-rnaseq-ds'
if (( $DEFINE_MODELS ))
then
    genome model define rna-seq                                                     \
        --model-name="$MODEL_TUMOR_RNASEQ"                                          \
        --subject="$SAMPLE_RNA_TUMOR"                                               \
        --processing-profile="$PROCESSING_PROFILE_RNA_SEQ"                          \
        --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
        --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
        --instrument-data="sample_name=$SAMPLE_RNA_TUMOR"
        # LATER ON ANOTHER MODEL WILL REFERENCE THIS ONE
        # 1) that model's id is 18177dd5eca44514a47f367d9804e17a hcc1395-clinseq
        # 2) that model's id is abeb5a3cddb94374afffd617684fa49a hcc1395-differential-expression
fi
#
# Tumor Tissue Sample
#
SAMPLE_TUMOR='H_NJ-HCC1395-HCC1395ds'
genome sample create                                                            \
    --name=$SAMPLE_TUMOR                                                        \
    --source="name=$INDIVIDUAL"                                                 \
    --common-name='tumor'                                                       \
    --tissue-desc='epithelial'                                                  \
    --extraction-type='genomic dna'                                             \
    --extraction-label='HCC1395'

LIBRARY_TUMOR_1='H_NJ-HCC1395-HCC1395-lig2-lib1ds'
genome library create                                                           \
  --name="$LIBRARY_TUMOR_1"                                                     \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='271'                                                  \
  --library-insert-size='390'

genome instrument-data import basic                                             \
    --description='tumor wgs 1'                                                 \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=188429464'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_1.bam"          \
    --library="$LIBRARY_TUMOR_1"

genome instrument-data import basic                                             \
    --description='tumor wgs 4'                                                 \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=193216396'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_2.bam"          \
    --library="$LIBRARY_TUMOR_1"

LIBRARY_TUMOR_2='H_NJ-HCC1395-HCC1395-lig2-lib2ds'
genome library create                                                           \
  --name="$LIBRARY_TUMOR_2"                                                     \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='390'                                                  \
  --library-insert-size='509'

genome instrument-data import basic                                             \
    --description='tumor wgs 5'                                                 \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=189430115'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_3.bam"          \
    --library="$LIBRARY_TUMOR_2"

genome instrument-data import basic                                             \
    --description='tumor wgs 3'                                                 \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=190192103'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_4.bam"          \
    --library="$LIBRARY_TUMOR_2"

LIBRARY_TUMOR_3='H_NJ-HCC1395-HCC1395-lig2-lib3ds'
genome library create                                                           \
  --name="$LIBRARY_TUMOR_3"                                                     \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='550'                                                  \
  --library-insert-size='669'

genome instrument-data import basic                                             \
    --description='tumor wgs 2'                                                 \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=180487649'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_5.bam"          \
    --library="$LIBRARY_TUMOR_3"

CAPTURE_LIBRARY_TUMOR='libgroup-2891242741ds'
genome library create                                                           \
  --name="$CAPTURE_LIBRARY_TUMOR"                                               \
  --sample="$SAMPLE_TUMOR"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --library-insert-size='364-400'

genome instrument-data import basic                                             \
    --description='tumor exome 1'                                               \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=96056889,target_region_set_name="$NIMBLEGEN_V3"' \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_C1TD1ACXX_7_ATCACG.bam"   \
    --library="$CAPTURE_LIBRARY_TUMOR"

# IF WE HAD MICROARRAY DATA FOR THIS SAMPLE
# MODEL_MICROARRAY_TUMOR='hcc1395-tumor-snparray'
# genome model define genotype-microarray                                       \
#     --model-name="$MODEL_MICROARRAY_TUMOR"                                    \
#     --processing-profile="$PROCESSING_PROFILE_MICROARRAY"                     \
#     --subject="$SAMPLE_TUMOR"                                                 \
#     --instrument-data='2891080777'                                            \
#     --reference="$GENOME_BUILD_REFERENCE"                                     \
#     --dbsnp-build="$GENOME_BUILD_DBSNP"
#     #alteratively, can these just point to the model directly (instead of the model's build)?
#     #or perhaps it doesn't matter since these builds come with the system right now

MODEL_TUMOR_REFALIGN_WGS='hcc1395-tumor-refalign-wgs-ds'
if (( $DEFINE_MODELS ))
then
    genome model define reference-alignment                                         \
        --model-name="$MODEL_TUMOR_REFALIGN_WGS"                                    \
        --subject="$SAMPLE_TUMOR"                                                   \
        --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
        --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
        --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
        --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"
    #    --genotype-microarray="$MODEL_MICROARRAY_TUMOR"
        # Do all of these intrument data really belong here?
        # These instrument data assignments come from the metadata blob
        # These IDs need to be replaced with
        # LATER ON ANOTHER MODEL WILL REFERENCE THIS ONE
        # that model's id is 2891454547 hcc1395-somatic-wgs
    genome model instrument-data assign                                             \
        --model="$MODEL_TUMOR_REFALIGN_WGS"                                         \
        --instrument-data="description='tumor wgs 1'"
    genome model instrument-data assign                                             \
        --model="$MODEL_TUMOR_REFALIGN_WGS"                                         \
        --instrument-data="description='tumor wgs 2'"
    genome model instrument-data assign                                             \
        --model="$MODEL_TUMOR_REFALIGN_WGS"                                         \
        --instrument-data="description='tumor wgs 3'"
    genome model instrument-data assign                                             \
        --model="$MODEL_TUMOR_REFALIGN_WGS"                                         \
        --instrument-data="description='tumor wgs 4'"
    genome model instrument-data assign                                             \
        --model="$MODEL_TUMOR_REFALIGN_WGS"                                         \
        --instrument-data="description='tumor wgs 5'"
fi

MODEL_TUMOR_REFALIGN_EXOME='hcc1395-tumor-refalign-exome-ds'
if (( $DEFINE_MODELS ))
then
    genome model define reference-alignment                                         \
        --model-name="$MODEL_TUMOR_REFALIGN_EXOME"                                  \
        --subject="$SAMPLE_TUMOR"                                                   \
        --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
        --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
        --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
        --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
        --region-of-interest-set-name="$NIMBLEGEN_V3"                               \
        --target-region-set-name="$NIMBLEGEN_V3"                       \
    #    --genotype-microarray="$MODEL_MICROARRAY_TUMOR"
        # LATER ON ANOTHER MODEL WILL REFERENCE THIS ONE
        # that model's id is 2891407507 hcc1395-somatic-exome
    genome model instrument-data assign                                             \
        --model="$MODEL_TUMOR_REFALIGN_EXOME"                                       \
        --instrument-data="description='tumor exome 1'"
fi
#
# Normal Tissue Sample
#
SAMPLE_NORMAL='H_NJ-HCC1395-HCC1395_BLds'
genome sample create                                                            \
    --name=$SAMPLE_NORMAL                                                       \
    --source="name=$INDIVIDUAL"                                                 \
    --common-name='normal'                                                      \
    --tissue-desc='b lymphoblast'                                               \
    --extraction-type='genomic dna'                                             \
    --extraction-label='HCC1395 BL'

LIBRARY_NORMAL_1='H_NJ-HCC1395-HCC1395_BL-lig2-lib1ds'
genome library create                                                           \
  --name="$LIBRARY_NORMAL_1"                                                     \
  --sample="$SAMPLE_NORMAL"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='266'                                                  \
  --library-insert-size='385'

genome instrument-data import basic                                             \
    --description='normal wgs 1'                                                \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=168472676'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_6.bam"          \
    --library="$LIBRARY_NORMAL_1"

LIBRARY_NORMAL_2='H_NJ-HCC1395-HCC1395_BL-lig2-lib2ds'
genome library create                                                           \
  --name="$LIBRARY_NORMAL_2"                                                     \
  --sample="$SAMPLE_NORMAL"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='381'                                                  \
  --library-insert-size='500'

genome instrument-data import basic                                             \
    --description='normal wgs 2'                                                \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=175170815'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_7.bam"          \
    --library="$LIBRARY_NORMAL_2"

LIBRARY_NORMAL_3='H_NJ-HCC1395-HCC1395_BL-lig2-lib3ds'
genome library create                                                           \
  --name="$LIBRARY_NORMAL_3"                                                     \
  --sample="$SAMPLE_NORMAL"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --original-insert-size='557'                                                  \
  --library-insert-size='676'

genome instrument-data import basic                                             \
    --description='normal wgs 3'                                                \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=171892537'           \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_D1VCPACXX_8.bam"          \
    --library="$LIBRARY_NORMAL_3"

CAPTURE_LIBRARY_NORMAL='libgroup-2891242742ds'
genome library create                                                           \
  --name="$CAPTURE_LIBRARY_NORMAL"                                               \
  --sample="$SAMPLE_NORMAL"                                                      \
  --protocol='Illumina Library Construction'                                    \
  --library-insert-size='364-400'

genome instrument-data import basic                                             \
    --description='normal exome 1'                                                \
    --import-source-name='TST1ds'                                                  \
    --instrument-data-properties='clusters=77667085,target_region_set_name="$NIMBLEGEN_V3"' \
    --source-files="$INSTRUMENT_DATA_DIRECTORY/gerald_C1TD1ACXX_7_CGATGT.bam"   \
    --library="$CAPTURE_LIBRARY_NORMAL"

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

MODEL_REF_ALIGN_NORMAL_WGS='hcc1395-normal-refalign-wgs-ds'
if (( $DEFINE_MODELS ))
then
    genome model define reference-alignment                                         \
        --model-name="$MODEL_REF_ALIGN_NORMAL_WGS"                                  \
        --subject="$SAMPLE_NORMAL"                                                  \
        --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
        --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
        --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
        --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
    #    --genotype-microarray='TODO: :2891230330'
        # LATER ON ANOTHER MODEL WILL REFERENCE THIS ONE
        # that model's id is 2891454547 hcc1395-somatic-wgs
    genome model instrument-data assign                                             \
        --model="$MODEL_REF_ALIGN_NORMAL_WGS"                                       \
        --instrument-data="description='normal wgs 1'"
    genome model instrument-data assign                                             \
        --model="$MODEL_REF_ALIGN_NORMAL_WGS"                                       \
        --instrument-data="description='normal wgs 2'"
    genome model instrument-data assign                                             \
        --model="$MODEL_REF_ALIGN_NORMAL_WGS"                                       \
        --instrument-data="description='normal wgs 3'"
fi

MODEL_REF_ALIGN_NORMAL_EXOME='hcc1395-normal-refalign-exome-ds'
if (( $DEFINE_MODELS ))
then
    genome model define reference-alignment                                         \
        --model-name="$MODEL_REF_ALIGN_NORMAL_EXOME"                                \
        --subject="$SAMPLE_NORMAL"                                                  \
        --processing-profile-name="$PROCESSING_PROFILE_REFERENCE_ALIGNMENT"         \
        --annotation-reference-build="model_name=$GENOME_BUILD_ANNOTATION"          \
        --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
        --dbsnp-build="model_name=$GENOME_BUILD_DBSNP"                              \
        --region-of-interest-set-name="$NIMBLEGEN_V3"                               \
        --target-region-set-name="$NIMBLEGEN_V3"
    #    --genotype-microarray='TODO: :2891230330'
        # LATER ON ANOTHER MODEL WILL REFERENCE THIS ONE
        # that model's id is 2891407507 hcc1395-somatic-exome
    genome model instrument-data assign                                             \
        --model="$MODEL_REF_ALIGN_NORMAL_EXOME"                                     \
        --instrument-data="description='normal exome 1'"
    #
fi



#
# 4) DEFINE HIGHER-LEVEL MODELS
#
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
