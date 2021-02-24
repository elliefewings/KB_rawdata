#!/bin/bash
## Run count function of cell ranger align, process and quantify scATACseq data. Takes one directory containing all fastqs. Output location is optional. If not supplied, output will be stored in home directory.
## For easy usage, submit job with ./cellranger.sh script
## Usage: sbatch --export=sample=${sample},ref=${ref},outdir=${outdir}[optional],inputatac=${inputatac},log=${log},conda=${conda} ./slurm_cellranger_atac.sh

# Job Name
#SBATCH --job-name=cellranger_count.$sample
# Resources, ... and one node with 4 processors:
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem 64000
#SBATCH --mail-user=eleanor.fewings@bioquant.uni-heidelberg.de

# Source bashrc
source ~/.bashrc

# Load cellranger module
module load bio/cellranger/3.0.2

# Load conda environment if requested
if [[ ! -z ${conda}  ]]; then
  conda activate ${conda}
fi

# Create sample slog
slog="${outdir}/${sample}/logs/${sample}_cellranger_atac.slog"

#################
## Cell Ranger ##
#################

echo "" >> ${slog}
echo "------------------" >> ${slog}
echo " Cell Ranger ATAC " >> ${slog}
echo "------------------" >> ${slog}
echo "" >> ${slog}

echo "Ready to run Cell Ranger ATAC" >> ${slog}
echo "" >> ${slog}
# Removed version printing as it is done automatically by cellranger
#echo "$(cellranger-atac count --version)" >> ${slog}
#echo "" >> ${slog}

# Change to output directory
cd ${outdir}/${sample}

# Run cell ranger per sample
echo "  Running Cell Ranger ATAC on: ${sample}" >> ${slog}

cellranger-atac count --id="${sample}_ATAC" \
                 --reference=${ref} \
                 --fastqs=${inputatac} \
                 --sample=${sample} \
                 --jobmode=local \
                 --localcores=8 \
                 --localmem=57 &>> ${slog}

echo "Cell ranger ATAC complete: $(date +%T)" >> ${slog}

