#!/bin/bash
## Prepare data for analysis of RNA velocity
## For easy usage, submit job with ./cellranger.sh script
## Usage: sbatch --export=sample=${sample},ref=${ref},outdir=${outdir},conda=${conda} ./slurm_velocyto.sh

# Job Name
#SBATCH --job-name=velocyto.$sample
# Resources, ... and one node with 4 processors:
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem 64000
#SBATCH --mail-user=eleanor.fewings@bioquant.uni-heidelberg.de

# Source bashrc
source ~/.bashrc

# Load conda environment if requested
if [[ ! -z ${conda}  ]]; then
  conda activate ${conda}
fi

# Create sample slog
slog="${outdir}/${sample}/logs/${sample}_velocyto.slog"

#Find bam from RNA
input="${outdir}/${sample}/${sample}_RNA"

##############
## velocyto ##
##############

echo "" >> ${slog}
echo "----------" >> ${slog}
echo " velocyto " >> ${slog}
echo "----------" >> ${slog}
echo "" >> ${slog}

echo "Ready to run velocyto" >> ${slog}
echo "" >> ${slog}


# Run velocyto
echo "  Running velocyto on: ${sample}" >> ${slog}

#NOTE: can add "-m repeat_msk.gtf" if needed

velocyto run10x ${input} ${ref}/genes/genes.gtf

echo "Velocyto complete: $(date +%T)" >> ${slog}

