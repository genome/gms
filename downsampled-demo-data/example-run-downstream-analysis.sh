#!/bin/bash -x

#
# INTRODUCTION
#
#

echo "*"
echo "*"
echo "Examine this script in your favorite editor for background on each command."
echo "*"
echo "*"


#
# Now define the higher-order models.
#
# These take the above models as inputs, and
# produce derivative, cross-sample analysis.
#


# Input models from example-run-initial-analysis.sh:

MODEL_TUMOR_REFALIGN_WGS='hcc1395-tumor-refalign-wgs-ds'
MODEL_NORMAL_REFALIGN_WGS='hcc1395-normal-refalign-wgs-ds'
MODEL_TUMOR_REFALIGN_EXOME='hcc1395-tumor-refalign-exome-ds'
MODEL_NORMAL_REFALIGN_EXOME='hcc1395-normal-refalign-exome-ds'
MODEL_TUMOR_RNASEQ='hcc1395-tumor-rnaseq-ds'
MODEL_NORMAL_RNASEQ='hcc1395-normal-rnaseq-ds'


# Somatic variation analysis using tumor+normal WGS data:

MODEL_SOMATIC_VARIATION_WGS='hcc1395-somatic-wgs-ds'
genome model define somatic-variation                                           \
    --model-name="$MODEL_SOMATIC_VARIATION_WGS"                                 \
    --subject="$SAMPLE_TUMOR"                                                   \
    --processing-profile="$PROCESSING_PROFILE_SOMATIC_VARIATION_WGS"            \
    --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
    --previously-discovered-variations="model_name=$GENOME_BUILD_DBSNP"         \
    --tumor-model="$MODEL_TUMOR_REFALIGN_WGS"                                   \
    --normal-model="$MODEL_NORMAL_REFALIGN_WGS"

genome model build start "name='$MODEL_SOMATIC_VARIATION_WGS'"


# Somatic variation analysis of the tumor and normal exome data:

MODEL_SOMATIC_VARIATION_EXOME='hcc1395-somatic-exome-ds'
genome model define somatic-variation                                           \
    --model-name="$MODEL_SOMATIC_VARIATION_EXOME"                               \
    --subject="$SAMPLE_TUMOR"                                                   \
    --processing-profile="$PROCESSING_PROFILE_SOMATIC_VARIATION_EXOME"          \
    --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
    --previously-discovered-variations="model_name=$GENOME_BUILD_DBSNP"         \
    --normal-model="$MODEL_NORMAL_REFALIGN_EXOME"                               \
    --tumor-model="$MODEL_TUMOR_REFALIGN_EXOME"

genome model build start "name='$MODEL_SOMATIC_VARIATION_EXOME'"

# Differential expression analysis:
# (The API on this currently requires model IDs instead of names.)

MODEL_DIFFERENTIAL_EXPRESSION='hcc1395-differential-expression-ds'
INPUT_MODEL_TUMOR_RNASEQ_ID=`genome model list name='$MODEL_TUMOR_RNASEQ' --show id --noheaders`
INPUT_MODEL_NORMAL_RNASEQ_ID=`genome model list name='$MODEL_NORMAL_RNASEQ' --show id --noheaders`

genome model define differential-expression                                     \
    --model-name="$MODEL_DIFFERENTIAL_EXPRESSION"                               \
    --subject="$INDIVIDUAL"                                                     \
    --processing-profile="$PROCESSING_PROFILE_DIFF_EXP"                         \
    --annotation-build="model_name=$GENOME_BUILD_ANNOTATION"                    \
    --reference-sequence-build="model_name=$GENOME_BUILD_REFERENCE"             \
    --condition-labels-string='normal,tumor'                                    \
    --condition-model-ids-string="$INPUT_MODEL_NORMAL_RNASEQ_ID $INPUT_MODEL_TUMOR_RNASEQ_ID"

genome model build start "name='$MODEL_DIFFERENTIAL_EXPRESSION'"

#
# The final model converges all of the above higher-order models
# into one that coverges approaches, intersects results, and produces
# a large number of reports.
#
# Note: the above models can run in parallel with each other, but this
# must run after the others complete.  If run early, it will produce analysis
# for the data available, but will need a re-build to get the full data.
#

genome model define clin-seq                                                    \
    --name='hcc1395-clinseq-ds'                                                 \
    --processing-profile="$PROCESSING_PROFILE_CLININCAL_SEQUENCING"             \
    --cancer-annotation-db="$ANNOTATION_DB_COSMIC"                              \
    --cancer-annotation-db="$ANNOTATION_DB_TGI_CANCER"                          \
    --misc-annotation-db="$ANNOTATION_DB_TGI_MISC"                              \
    --de-model="$MODEL_DIFFERENTIAL_EXPRESSION"                                 \
    --tumor-rnaseq-model="$MODEL_TUMOR_RNASEQ"                                  \
    --normal-rnaseq-model="$MODEL_NORMAL_RNASEQ"                                \
    --exome-model="$MODEL_SOMATIC_VARIATION_EXOME"                              \
    --wgs-model="$MODEL_SOMATIC_VARIATION_WGS"

genome model build start "name='hcc1395-clinseq-ds'"

#
# CONCLUSION
#
# The above commands configure and launch analysis.
# 
# An alternative is to use the helper tool: genome model clin-seq advise --allow-imported --individual='common_name=TST1ds'
#
# See the instructions on the web site to understand the data produced:
# http://github.com/genome/gms
# 

