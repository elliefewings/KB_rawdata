#!/bin/bash
## Run pileup over the expressed alleles in single-cell or bulk RNA-seq data, which can be directly used for donor deconvolution in multiplexed single-cell RNA-seq data
## For easy usage, submit job with ./cellranger.sh script
## Usage: sbatch --export=sample=${sample},vcf=${vcf},outdir=${outdir},tmp_dir=${tmp_dir},conda=${conda} ./slurm_cellSNP.sh

# Job Name
#SBATCH --job-name=cellSNP.$sample
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
slog="${tmp_dir}/${sample}_cellSNP.slog"

#Create new outdir
outsamp="${outdir}/${sample}_cellSNP"

#Find bam from RNA
bam="${outdir}/${sample}_RNA/outs/possorted_genome_bam.bam"

#Find barcode from RNA
barcode="${outdir}/${sample}_RNA/outs/filtered_feature_bc_matrix/barcodes.tsv.gz"

#############
## CellSNP ##
#############

echo "" >> ${slog}
echo "---------" >> ${slog}
echo " CellSNP " >> ${slog}
echo "---------" >> ${slog}
echo "" >> ${slog}

echo "Ready to run CellSNP" >> ${slog}
echo "" >> ${slog}

# Change to output directory
cd ${outdir}

# Run cell ranger per sample
echo "  Running CellSNP on: ${sample}" >> ${slog}

cellSNP -s ${bam} -b ${barcode} -O ${outsamp} -R ${vcf} -p 7 --minMAF 0.1 --minCOUNT 20

echo "CellSNP complete: $(date +%T)" >> ${slog}

