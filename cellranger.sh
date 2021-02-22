#!/bin/bash

# Submission script accepting arguments for cellranger counts function
# Ellie Fewings, 22Jul2020

# Running:
# ./cellranger.sh -i <input RNA directory> -a <input ATAC directory> -r <reference trancriptome> -m <reference chromatome> -o <output location>[optional] -s <sequencing chemistry>[optional] -c <conda environment>[optional] -h <help>

# Source bashrc
source ~/.bashrc

# Set abort function
abort()
{
    echo "Uh oh. An error occurred."
    echo ""
    echo "Exiting..."
    exit 2
}

trap 'abort' SIGINT SIGTERM

set -e

# Set help function
helpFunction()
{
  echo ""
  echo "Program: Cellranger count"
  echo ""
  echo "Version: 0.1"
  echo ""
  echo "Usage: ./cellranger.sh -i <input RNA directory> -a <input ATAC directory> -r <reference trancriptome> -m <reference chromatome> -o <output location>[optional] -s <sequencing chemistry>[optional] -c <conda environment>[optional] -h <help>"
  echo ""
  echo "Options:"
      echo -e "\t-i\tInput RNA: Path to directory containing all RNA fastqs [required]"
      echo -e "\t-a\tInput ATAC: Path to directory containing all ATAC fastqs [required]"
      echo -e "\t-r\tReference transcriptome: Path to directory containing reference transcriptome for RNA [required]"
      echo -e "\t-m\tReference chromatome: Path to directory containing reference transcriptome for ATAC [required]"
      echo -e "\t-o\tOutput directory: Path to location where output will be generated [default=$HOME]"
      echo -e "\t-s\tSequencing chemistry: Sequencing chemistry used in assay (see cellranger count --chemistry options for details). Should be left on 'autodetect' mode (default) unless error occurs [default=auto]"
      echo -e "\t-c\tConda environment: Name of conda environment with Cellranger installed (unless it is available on path or from module) [default=module]"
      echo -e "\t-h\tHelp: Does what it says on the tin"
  echo ""
}

# Set default chemistry and output location
chem="auto"
output="$HOME"

# Accept arguments specified by user
while getopts "i:a:r:m:o:s:c:h" opt; do
  case $opt in
    i ) input="$OPTARG"
    ;;
    a ) inputatac="$OPTARG"
    ;;
    r ) refr="$OPTARG"
    ;;
    m ) refa="$OPTARG"
    ;;
    o ) output="$OPTARG"
    ;;
    s ) chem="$OPTARG"
    ;;
    c ) conda="$OPTARG"
    ;;
    h ) helpFunction ; exit 0
    ;;
    * ) echo "Incorrect arguments" ; helpFunction ; abort
    ;;
  esac
done

# Check minimum number of arguments
if [ $# -lt 4 ]; then
  echo "Not enough arguments"
  helpFunction
  abort
fi

# If bam or intervals are missing report help function
if [[ "${input}" == "" || "${inputatac}" == "" || "${refr}" == "" || "${refa}" == ""  ]]; then
  echo "Incorrect arguments."
  echo "Input and references are required."
  helpFunction
  abort
else
  input=$(realpath "${input}")
  inputatac=$(realpath "${inputatac}")
  refr=$(realpath "${refr}")
  refa=$(realpath "${refa}")
fi

################
## Create log ##
################

# Create directory for log and output
if [[ -z ${output} ]]; then
    outdir="${HOME}/cellranger_output_$(date +%Y%m%d)"
else
    outdir="${output}/cellranger_output_$(date +%Y%m%d)"
fi

mkdir -p ${outdir}

log="${outdir}/cellranger_count_$(date +%Y%m%d).log"

# Report to log
echo "Running ./cellranger_count.sh" > ${log}
echo "" >> ${log}
echo "------------" >> ${log}
echo " Submission " >> ${log}
echo "------------" >> ${log}
echo "" >> ${log}
echo "Job name: cellranger_count" >> ${log}
echo "Time of submission: $(date +"%T %D")" >> ${log}
echo "Resources allocated: nodes=1:ppn=8" >> ${log}
echo "User: ${USER}" >> ${log}
echo "Log: ${log}" >> ${log}
echo "Input RNA: ${input}" >> ${log}
echo "Input ATAC: ${inputatac}" >> ${log}
echo "Reference trancriptome: ${refr}" >> ${log}
echo "Reference chromatome: ${refa}" >> ${log}
echo "Sequencing chemistry: ${chem}" >> ${log}
echo "Conda environment: ${conda}" >> ${log}
echo "Output: ${outdir}" >> ${log}

###########
## Input ##
###########

echo "" >> ${log}
echo "-------" >> ${log}
echo " Input " >> ${log}
echo "-------" >> ${log}
echo "" >> ${log}

# Check if input is directory
if [[ -d ${input} && -d ${inputatac} ]] ; then
    nfq=$(ls -1 ${input}/*fastq.gz | wc -l)
    nfqa=$(ls -1 ${inputatac}/*fastq.gz | wc -l)
    # Check if RNA directory contains fastqs
    if [ ${nfq} -gt 0 ] ; then 
      echo "Input RNA directory contains ${nfq} fastq files" >> ${log}
    else 
      echo "ERROR: Input RNA directory contains no fastq files" >> ${log}
      exit 1
    fi
        # Check if directory contains fastqs
    if [ ${nfqa} -gt 0 ] ; then 
      echo "Input ATAC directory contains ${nfqa} fastq files" >> ${log}
    else 
      echo "ERROR: Input ATAC directory contains no fastq files" >> ${log}
      exit 1
    fi
# Check if input is file
else 
  echo "ERROR: Input is not a directory" >> ${log}
  exit 1
fi


##################
## Format input ##
##################

# Create temporary directory
tmp_dir=$(mktemp -d -p ${outdir})

echo "" >> ${log}
echo "Checking format of fastq files..." >> ${log}
echo "" >> ${log}

# Create list of unique samples on which to run analysis
echo "  Creating list of samples on which to run analysis" >> ${log}
tfile="${tmp_dir}/samples.rna.tmp.txt"
sfile="${tmp_dir}/samples.rna.txt"

tfileatac="${tmp_dir}/samples.atac.tmp.txt"
sfileatac="${tmp_dir}/samples.atac.txt"

# Formatting data for input into cellranger. Gather files into one directory and rename if necassary

# Search through fastqs for list of samples
for fq in $(ls -1 ${input}/*fastq.gz) ; do

  #Extract sample name
  sample=$(basename ${fq} | sed 's/_L.*/_/g' | sed 's/_S[1-9]*_//g' | sed 's/_[1-9].fastq.gz//g' | sed 's/_$//')
  echo -e "${sample}\t${input}/${fq}" >> ${tfile}

  # Find name of read pair file
  if [[ ${fq} == *"_R1"* ]] ; then
    pair=$(echo ${fq} | sed 's+_R1+_R2+')
  elif [[ ${fq} == *"_R2"* ]] ; then
    pair=$(echo ${fq} | sed 's+_R2+_R1+')
  fi
  # Check if read pair file exists
  if [ ! -f ${pair} ] ; then 
    echo "  ERROR: Read pair doesn't exist for fastq: ${fq}" >> ${log}
    echo "  Please check if pair exists and manually rename if files don't fit normal naming conventions (i.e. R1, R2)" >> ${log}
    exit 1
  fi
  
done

# Search through fastqs for list of samples
for fq in $(ls -1 ${inputatac}/*fastq.gz) ; do

  #Extract sample name
  sample=$(basename ${fq} | sed 's/_L.*/_/g' | sed 's/_S[1-9]*_//g' | sed 's/_[1-9].fastq.gz//g' | sed 's/_$//')
  echo -e "${sample}\t${inputatac}/${fq}" >> ${tfileatac}

  # Find name of read pair file
  if [[ ${fq} == *"_R1"* ]] ; then
    pair=$(echo ${fq} | sed 's+_R1+_R2+')
  elif [[ ${fq} == *"_R2"* ]] ; then
    pair=$(echo ${fq} | sed 's+_R2+_R1+')
  fi
  # Check if read pair file exists
  if [ ! -f ${pair} ] ; then 
    echo "  ERROR: Read pair doesn't exist for fastq: ${fq}" >> ${log}
    echo "  Please check if pair exists and manually rename if files don't fit normal naming conventions (i.e. R1, R2)" >> ${log}
    exit 1
  fi
  
done

# Remove duplicates from samples file
cut ${tfile} -f1 | sort -u > ${sfile}
cut ${tfileatac} -f1 | sort -u > ${sfileatac}

echo "" >> ${log}
echo "Completed all file checks: $(date +%T)" >> ${log}
echo "" >> ${log}



# Submit job to cluster
loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#Submit RNA
while read sample ; do
  echo "Submitting RNA job to cluster: ${sample}" >> ${log}
  sbatch --export=sample=${sample},ref=${refr},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},chem=${chem},conda=${conda} "${loc}/slurm/slurm_cellranger_count.sh"
done < ${sfile}

#Submit ATAC
while read sample ; do
  echo "Submitting ATAC job to cluster: ${sample}" >> ${log}
  sbatch --export=sample=${sample},ref=${refa},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},conda=${conda} "${loc}/slurm/slurm_cellranger_atac.sh"
done < ${sfileatac}


