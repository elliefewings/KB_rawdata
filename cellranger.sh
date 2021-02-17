#!/bin/bash

# Submission script accepting arguments for cellranger counts function
# Ellie Fewings, 22Jul2020

# Running:
# ./cellranger.sh -i <input file or directory> -r <reference trancriptome> -o <output location>[optional] -s <sequencing chemistry>[optional] -h <help>

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
  echo "Usage: ./cellranger.sh -i <input file or directory> -r <reference trancriptome> -o <output location>[optional] -s <sequencing chemistry>[optional] -h <help>"
  echo ""
  echo "Options:"
      echo -e "\t-i\tInput: Path to directory containing all fastqs or file containing list of directories with fastqs, one directory per line [required]"
      echo -e "\t-r\tReference transcriptome: Path to directory containing reference transcriptome [required]"
      echo -e "\t-o\tOutput directory: Path to location where output will be generated [default=$HOME]"
      echo -e "\t-s\tSequencing chemistry: Sequencing chemistry used in assay (see cellranger count --chemistry options for details). Should be left on 'autodetect' mode (default) unless error occurs [default=auto]"
      echo -e "\t-h\tHelp: Does what it says on the tin"
  echo ""
}

# Set default chemistry and output location
chem="auto"
output="$HOME"

# Accept arguments specified by user
while getopts "i:r:o:s:h" opt; do
  case $opt in
    i ) input="$OPTARG"
    ;;
    r ) ref="$OPTARG"
    ;;
    o ) output="$OPTARG"
    ;;
    s ) chem="$OPTARG"
    ;;
    h ) helpFunction ; exit 0
    ;;
    * ) echo "Incorrect arguments" ; helpFunction ; abort
    ;;
  esac
done

# Check minimum number of arguments
if [ $# -lt 2 ]; then
  echo "Not enough arguments"
  helpFunction
  abort
fi

# If bam or intervals are missing report help function
if [[ "${input}" == "" || "${ref}" == "" ]]; then
  echo "Incorrect arguments."
  echo "Input and reference are required."
  helpFunction
  abort
else
  input=$(realpath "${input}")
  ref=$(realpath "${ref}")
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
echo "Input: ${input}" >> ${log}
echo "Reference trancriptome: ${ref}" >> ${log}
echo "Sequencing chemistry: ${chem}" >> ${log}
echo "Output: ${outdir}" >> ${log}

###########
## Input ##
###########

echo "" >> ${log}
echo "-------" >> ${log}
echo " Input " >> ${log}
echo "-------" >> ${log}
echo "" >> ${log}

# Check if input is file or directory
if [[ -d ${input} ]] ; then
    nfq=$(ls -1 ${input}/*fastq.gz | wc -l)
    # Check if directory contains fastqs
    if [ ${nfq} -gt 0 ] ; then 
      echo "Input directory contains ${nfq} fastq files" >> ${log}
      intype="directory"
    else 
      echo "ERROR: Input directory contains no fastq files" >> ${log}
      exit 1
    fi
# Check if input is file
elif [[ -f ${input} ]] ; then
    # Create additional file containing all fastqs within the specified directories
    for fqdir in $(cat ${input}) ; do
      ls -1 ${fqdir}/*fastq.gz >> "${outdir}/fastqs.txt"
    done
    ndir=$(cat ${input} | wc -l)
    nfq=$(cat "${outdir}/fastqs.txt" | wc -l)
    # Check if directories contain fastqs
    if [ ${nfq} -gt 0 ] ; then 
      echo "Input file contains ${ndir} directories with a total of ${nfq} fastq files" >> ${log}
      intype="file"
    else 
      echo "ERROR: Input directories contain no fastq files" >> ${log}
      exit 1
    fi
# If input is not file or direcory, report error and exit
else
    echo "ERROR: input `${input}` is not valid. Please specify a directory containing fastqs or a file containing a list of directories with fastqs" >> ${log}
    exit 1
fi

##################
## Format input ##
##################

# Create temporary directory
tmp_dir=$(mktemp -d -p ${outdir})

echo "" >> ${log}
echo "Checking format of fastq files and renaming if necessary..." >> ${log}
echo "  Began: $(date +%T)" >> ${log}
echo "" >> ${log}

# Create list of unique samples on which to run analysis
echo "  Creating list of samples on which to run analysis" >> ${log}
tfile="${tmp_dir}/samples.tmp.txt"
sfile="${tmp_dir}/samples.txt"

# File containing old and new names for log purposes
names="${outdir}/renamed_fastqs_$(date +%Y%m%d).txt"
echo -e "OldFQ\tNewFQ" > ${names}
echo "  Any file name changes will be recorded in: ${names}" >> ${log}

# Formatting data for input into cellranger. Gather files into one directory and rename if necassary

# If input supplied is a file of multiple directories: move fastqs to tmp directory and reformat names to match BCL2FASTQ format
if [[ ${intype} == "file" ]] ; then
  while read fqdir ; do
    for fq in $(ls -1 ${fqdir}/*fastq.gz) ; do
        # Copy file straight over if name is in correct format
        if [[ ${fq} == *"_S"* ]] && [[ ${fq} == *"_L00"* ]] && [[ ( ${fq} == *"_R1"* ) || ( ${fq} == *"_R2"* ) || ( ${fq} == *"_I1"* )]] ; then
          sample=$(basename ${fq} | sed 's/_L.*/_/g' | sed 's/_S[1-9]*_//g' | sed 's/_[1-9].fastq.gz//g' | sed 's/_$//')
          echo -e "${sample}\t${tmpdir}/${fq}" >> ${tfile}
          rsync -a ${fq} ${tmp_dir}
        else
          echo "    Incorrect fastq naming format for ${fq}. Renaming file" >> ${log}
          # Infer sample name from directory name
          sample=$(basename ${fqdir})
          # Infer lane number
          if [ $(ls -1 ${fqdir}/*fastq.gz | wc -l) -gt 2 ] ; then
            oldlane=$(basename ${fq} | sed 's+.*L+L+' | cut -d'_' -f1)
            if [[ ${oldlane} == *"1" ]] ; then
              lane="L001"
            elif [[ ${oldlane} == *"2" ]] ; then
              lane="L002"
            elif [[ ${oldlane} == *"3" ]] ; then
              lane="L003"
            elif [[ ${oldlane} == *"4" ]] ; then
              lane="L004"
            else echo "  ERROR: Cannot infer lane number for renaming of file: ${fq}" >> ${log}
              echo "  Please manually rename file to contain lane number (i.e. L001)" >> ${log}
              exit 1
            fi
          else
            lane="L001"
          fi
          # Infer read number
          if [[ ( ${fq} == *"_I1"* ) ]] ; then
            read="I1"
          elif [[ ( ${fq} == *"_R1"* ) || ( ${fq} == *"_1_"* ) || ( ${fq} == *"_1."* ) ]] ; then
            read="R1"
          elif [[ ( ${fq} == *"_R2"* ) || ( ${fq} == *"_2_"* ) || ( ${fq} == *"_2."* ) ]] ; then
            read="R2"
          else echo "  ERROR: Cannot infer read number for renaming of file: ${fq}" >> ${log}
            echo "  Please manually rename file to contain read number (i.e. R1)" >> ${log}
            exit 1 
          fi
        # Copy file with new name to tmp directory and record name change
        newname="${tmp_dir}/${sample}_S1_${lane}_${read}_001.fastq.gz"
        echo -e "${fq}\t${newname}" >> ${names}
        rsync -a ${fq} ${newname}
        echo -e "${sample}\t${newname}" >> ${tfile}
      fi
    done
  done < ${input}
fi

# If input supplied is a directory: move fastqs to tmp directory and reformat names to match BCL2FASTQ format if necassary
if [[ ${intype} == "directory" ]] ; then
  for fq in $(ls -1 ${input}/*fastq.gz) ; do
    # Copy file if file name is in correct format
    if [[ ${fq} == *"_S"* ]] && [[ ${fq} == *"_L00"* ]] && [[ ( ${fq} == *"_R1"* ) || ( ${fq} == *"_R2"* ) || ( ${fq} == *"_I1"* ) ]] ; then
      sample=$(basename ${fq} | sed 's/_L.*/_/g' | sed 's/_S[1-9]*_//g' | sed 's/_[1-9].fastq.gz//g' | sed 's/_$//')
      echo -e "${sample}\t${tmpdir}/${fq}" >> ${tfile}
      rsync -a ${fq} ${tmp_dir}
    else
      echo "  Incorrect fastq naming format for ${fq}. Renaming file" >> ${log}
      # Infer sample name from previous file name
      sample=$(basename ${fq} | sed 's/_L.*/_/g' | sed 's/_S[1-9]*_//g' | sed 's/_[1-9].fastq.gz//g'  | sed 's/_$//')
      # Infer lane number
      if [ $(ls -1 ${input}/${sample}*fastq.gz | wc -l) -gt 2 ] ; then
        oldlane=$(basename ${fq} | sed 's+.*L+L+' | cut -d'_' -f1)
        if [[ ${oldlane} == *"1" ]] ; then
          lane="L001"
        elif [[ ${oldlane} == *"2" ]] ; then
          lane="L002"
        elif [[ ${oldlane} == *"3" ]] ; then
          lane="L003"
        elif [[ ${oldlane} == *"4" ]] ; then
          lane="L004"
        else echo "  ERROR: Cannot infer lane number for renaming of file: ${fq}" >> ${log}
          echo "  Please manually rename file to contain lane number (i.e. L001)" >> ${log}
          exit 1
        fi
      else
        lane="L001"
      fi
      # Infer read number
      if [[ ( ${fq} == *"_I1"* ) ]] ; then
        read="I1"
      elif [[ ( ${fq} == *"_R1"* ) || ( ${fq} == *"_1_"* ) || ( ${fq} == *"_1."* ) ]] ; then
        read="R1"
      elif [[ ( ${fq} == *"_R2"* ) || ( ${fq} == *"_2_"* ) || ( ${fq} == *"_2."* ) ]] ; then
        read="R2"
      else echo "  ERROR: Cannot infer read number for renaming of file: ${fq}" >> ${log}
        echo "  Please manually rename file to contain read number (i.e. R1)" >> ${log}
        exit 1 
      fi
      # Copy file with new name to tmp directory and record name change
      newname="${tmp_dir}/${sample}_S1_${lane}_${read}_001.fastq.gz"
      echo -e "${fq}\t${newname}" >> ${names}
      rsync -a ${fq} ${newname}
      echo -e "${sample}\t${newname}" >> ${tfile}
    fi
  done
fi

# Remove duplicates from samples file
cut ${tfile} -f1 | sort -u > ${sfile}

echo "" >> ${log}
echo "Finished moving and renaming fastqs" >> ${log}
echo "" >> ${log}

# Check new input directory for a R1 and R2 per sample and lane
echo "Checking if each file has a forward and reverse read pair..." >> ${log}
echo "" >> ${log}

for fq in $(ls -1 ${tmp_dir}/*fastq.gz) ; do
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

echo "Completed all file checks: $(date +%T)" >> ${log}
echo "" >> ${log}



# Submit job to cluster
loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

while read sample ; do
  echo "Submitting to cluster: ${sample}" >> ${log}
  sbatch --export=sample=${sample},ref=${ref},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},chem=${chem} "${loc}/slurm/slurm_cellranger_count.sh"
done < ${sfile}

