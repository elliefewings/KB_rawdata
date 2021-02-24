#!/bin/bash
## Run count function of cell ranger align, process and quantify scRNAseq data. Takes one directory containing all fastqs. Output location is optional. If not supplied, output will be stored in home directory.
## For easy usage, submit job with ./cellranger.sh script
## Usage: sbatch --export=sample=${sample},ref=${refr},outdir=${outdir}[optional],input=${input},log=${log},chem=${chem},conda=${conda} ./slurm_cellranger_count.sh

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
slog="${outdir}/${sample}/logs/${sample}_cellranger.slog"

#################
## Cell Ranger ##
#################

echo "" >> ${slog}
echo "-------------" >> ${slog}
echo " Cell Ranger " >> ${slog}
echo "-------------" >> ${slog}
echo "" >> ${slog}

echo "Ready to run Cell Ranger" >> ${slog}
echo "" >> ${slog}
# Removed version printing as it is done automatically by cellranger
#echo "$(cellranger count --version)" >> ${slog}
#echo "" >> ${slog}

# Change to output directory
cd ${outdir}/${sample}

# Run cell ranger per sample
echo "  Running Cell Ranger on: ${sample}" >> ${slog}

cellranger count --id="${sample}_RNA" \
                 --transcriptome=${ref} \
                 --fastqs=${input} \
                 --sample=${sample} \
                 --expect-cells=3000 \
                 --chemistry=${chem} \
                 --jobmode=local \
                 --localcores=8 \
                 --localmem=57 &>> ${slog}

echo "Cell ranger complete: $(date +%T)" >> ${slog}
