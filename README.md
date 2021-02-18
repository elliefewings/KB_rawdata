# Single Cell RNAseq Toolkit - Kidney Biopsy Project

### Wrappers for submission of cellranger counts and cellranger-atac counts to slurm a system

## Cellranger Counts Wrapper

## Requirements
This wrapper requires the installation of cellranger and cellranger-atac
On the BioQuant cluster, this is sourced from the bio/cellranger/3.0.2 module.
It can also be accessed from a conda environment by setting the `-c` flag 

## Usage

This wrapper was written with the intention of being used on the University of Heidelberg BioQuant cluster

```
$ ./cellranger.sh

Program: Cellranger count

Version: 0.1

Usage: ./cellranger.sh -i <input directory> -r <reference trancriptome> -a <reference chromatome> -o <output location>[optional] -s <sequencing chemistry>[optional] -c <conda environment>[optional]-h <help>

Options:
        -i      Input: Path to directory containing all fastqs or file containing list of directories with fastqs, one directory per line [required]
        -r      Reference transcriptome: Path to directory containing reference transcriptome [required]
        -o      Output directory: Path to location where output will be generated [default=/home/bq_efewings]
        -s      Sequencing chemistry: Sequencing chemistry used in assay (see cellranger count --chemistry options for details). Should be left on 'autodetect' mode (default) unless error occurs [default=auto]
        -c      Conda environment: Name of conda environment with Cellranger installed (unless it is available on path or from module) [default=module]
        -h      Help: Does what it says on the tin
```
## Input

The input `-i` is the path to a directory containing multiple fastqs


Example input directory:
```
$ ls /home/directory/input
sample1_S1_L001_R1_001.fastq.gz sample1_S1_L001_R2_001.fastq.gz
sample1_S1_L002_R1_001.fastq.gz sample1_S1_L002_R2_001.fastq.gz
sample2_S2_L001_R1_001.fastq.gz sample2_S2_L001_R2_001.fastq.gz
sample2_S2_L002_R1_001.fastq.gz sample2_S2_L002_R2_001.fastq.gz
sample3_S3_L001_R1_001.fastq.gz sample3_S3_L001_R2_001.fastq.gz
sample3_S3_L002_R1_001.fastq.gz sample3_S3_L002_R2_001.fastq.gz
```
## Reference

A reference transcriptome is required for alignment. [Prebuilt references](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest) for human (GRCh38) and mouse (mm10) are supplied by Cell Ranger.

You can also follow [instructions](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/tutorial_mr) to make your own reference.

A reference chromatome is required for the ATAC processing. [Prebuilt references](https://support.10xgenomics.com/single-cell-atac/software/downloads/latest) for human (GRCh38) and mouse (mm10) are supplied by Cell Ranger.

You can also follow [instructions](https://support.10xgenomics.com/single-cell-atac/software/pipelines/latest/advanced/references) to make your own reference.

## Sequencing Chemistry

It is recommended that you leave this setting on default unless an error occurs.

As default, Cell Ranger automatically detects assay configuration. However there may be occasions where automatic detection is not possible. In which case please specify one of the following with the `-c` option:

+ `threeprime` for Single Cell 3′,
+ `fiveprime` for Single Cell 5′,
+ `SC3Pv2` for Single Cell 3′ v2,
+ `SC3Pv3` for Single Cell 3′ v3,
+ `SC5P-PE` for Single Cell 5′ paired-end (both R1 and R2 are used for alignment),
+ `SC5P-R2` for Single Cell 5′ R2-only (where only R2 is used for alignment).
+ `SC3Pv1` for Single Cell 3′ v1. NOTE: this mode cannot be auto-detected. It must be set explicitly with this option

## Output

You can set an output directory with the `-o` option, by default data will be stored in your $HOME directory.

For each sample, an RNA and ATAC directory will be generated

### RNA Output files
### [From Cell Ranger guide](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/count)


```
Outputs:
- Run summary HTML:                         /opt/sample345/outs/web_summary.html
- Run summary CSV:                          /opt/sample345/outs/metrics_summary.csv
- BAM:                                      /opt/sample345/outs/possorted_genome_bam.bam
- BAM index:                                /opt/sample345/outs/possorted_genome_bam.bam.bai
- Filtered feature-barcode matrices MEX:    /opt/sample345/outs/filtered_feature_bc_matrix
- Filtered feature-barcode matrices HDF5:   /opt/sample345/outs/filtered_feature_bc_matrix.h5
- Unfiltered feature-barcode matrices MEX:  /opt/sample345/outs/raw_feature_bc_matrix
- Unfiltered feature-barcode matrices HDF5: /opt/sample345/outs/raw_feature_bc_matrix.h5
- Secondary analysis output CSV:            /opt/sample345/outs/analysis
- Per-molecule read information:            /opt/sample345/outs/molecule_info.h5
- CRISPR-specific analysis:                 null
- Loupe Browser file:                       /opt/sample345/outs/cloupe.cloupe
- Feature Reference:                        null
- Target Panel File:                        null

```

### ATAC Output files
### [From Cell Ranger guide](https://support.10xgenomics.com/single-cell-atac/software/pipelines/latest/using/count)


```
Outputs:
- Per-barcode fragment counts & metrics:        /opt/sample345/outs/singlecell.csv
- Position sorted BAM file:                     /opt/sample345/outs/possorted_bam.bam
- Position sorted BAM index:                    /opt/sample345/outs/possorted_bam.bam.bai
- Summary of all data metrics:                  /opt/sample345/outs/summary.json
- HTML file summarizing data & analysis:        /opt/sample345/outs/web_summary.html
- Bed file of all called peak locations:        /opt/sample345/outs/peaks.bed
- Raw peak barcode matrix in hdf5 format:       /opt/sample345/outs/raw_peak_bc_matrix.h5
- Raw peak barcode matrix in mex format:        /opt/sample345/outs/raw_peak_bc_matrix
- Directory of analysis files:                  /opt/sample345/outs/analysis
- Filtered peak barcode matrix in hdf5 format:  /opt/sample345/outs/filtered_peak_bc_matrix.h5
- Filtered peak barcode matrix:                 /opt/sample345/outs/filtered_peak_bc_matrix
- Barcoded and aligned fragment file:           /opt/sample345/outs/fragments.tsv.gz
- Fragment file index:                          /opt/sample345/outs/fragments.tsv.gz.tbi
- Filtered tf barcode matrix in hdf5 format:    /opt/sample345/outs/filtered_tf_bc_matrix.h5
- Filtered tf barcode matrix in mex format:     /opt/sample345/outs/filtered_tf_bc_matrix
- Loupe Cell Browser input file:                /opt/sample345/outs/cloupe.cloupe
- csv summarizing important metrics and values: /opt/sample345/outs/summary.csv
 
```

