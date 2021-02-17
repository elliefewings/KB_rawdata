# Single Cell RNAseq Toolkit

### Wrappers for submission of cellranger counts and citeseq counts to qsub system

## Cellranger Counts Wrapper

## Requirements
This wrapper requires the installation of Cellranger Counts.
On the BioQuant cluster, this is sourced from the bio/cellranger/3.0.2 module.
It can also be accessed from a conda environment by setting the `-c` flag 

## Usage

This wrapper was written with the intention of being used on the University of Heidelberg BioQuant cluster

```
$ ./cellranger.sh

Program: Cellranger count

Version: 0.1

Usage: ./cellranger.sh -i <input file or directory> -r <reference trancriptome> -o <output location>[optional] -s <sequencing chemistry>[optional] -c <conda environment>[optional] -h <help>

Options:
        -i      Input: Path to directory containing all fastqs or file containing list of directories with fastqs, one directory per line [required]
        -r      Reference transcriptome: Path to directory containing reference transcriptome [required]
        -o      Output directory: Path to location where output will be generated [default=/home/bq_efewings]
        -s      Sequencing chemistry: Sequencing chemistry used in assay (see cellranger count --chemistry options for details). Should be left on 'autodetect' mode (default) unless error occurs [default=auto]
        -c      Conda environment: Name of conda environment with Cellranger installed (unless it is available on path or from module) [default=module]
        -h      Help: Does what it says on the tin
```
## Input

The input `-i` can be either the path to one directory containing multiple fastqs, or the path to a text file containing a list of directories that contain fastqs for individual samples. When supplying a file containing a list of fastq-containing directories, it is assumed that the directory name is the name of the sample to be analysed. 

Example input file:
```
$head input.txt
/home/directory/sample1
/home/directory/sample2
/home/directory/sample3

$ ls /home/directory/sample1
sample1_S1_L001_R1_001.fastq.gz sample1_S1_L001_R2_001.fastq.gz
sample1_S1_L002_R1_001.fastq.gz sample1_S1_L002_R2_001.fastq.gz

```
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

### Output files 
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
A successful `cellranger count` run should conclude with a message similar to this (this will be found in the log file written in the output directory):
```
Waiting 6 seconds for UI to do final refresh.
Pipestance completed successfully!


yyyy-mm-dd hh:mm:ss Shutting down.
Saving pipestance info to "tiny/tiny.mri.tgz"
```
The output of the pipeline will be contained in the output directory specified above. There will be a subfolder named with the samples you specified and the date they were run (e.g. sample1_20200101, sample2_20200101). Each subfolder will contain an `outs` directory containing the main pipeline output files:

| File Name        | Description           |
| ------------- |-------------|
| web_summary.html | Run summary metrics and charts in HTML format |
| metrics_summary.csv | Run summary metrics in CSV format |
| possorted_genome_bam.bam | Reads aligned to the genome and transcriptome annotated with barcode information |
| possorted_genome_bam.bam.bai | Index for possorted_genome_bam.bam |
| filtered_feature_bc_matrix | Filtered feature-barcode matrices containing only cellular barcodes in MEX format. (In Targeted Gene Expression samples, the non-targeted genes are not present.) |
| filtered_feature_bc_matrix_h5.h5 | Filtered feature-barcode matrices containing only cellular barcodes in HDF5 format. (In Targeted Gene Expression samples, the non-targeted genes are not present.) |
| raw_feature_bc_matrices | Unfiltered feature-barcode matrices containing all barcodes in MEX format |
| raw_feature_bc_matrix_h5.h5 | Unfiltered feature-barcode matrices containing all barcodes in HDF5 format |
| analysis | Secondary analysis data including dimensionality reduction, cell clustering, and differential expression |
| molecule_info.h5 | Molecule-level information used by cellranger aggr to aggregate samples into larger datasets |
| cloupe.cloupe | Loupe Browser visualization and analysis file |
| feature_reference.csv | (Feature Barcode only) Feature Reference CSV file |
| target_panel.csv | (Targeted GEX only) Targed panel CSV file |

## CITE-seq-counts Wrapper

## Requirements
This wrapper requires the installation of CITE-seq-counts.
You can install this to an environment as follows:
```
conda activate citeseqenv
pip install CITE-seq-Count==1.4.3
```
This installation can then be accessed from a conda environment by setting the `-c` flag 
## Usage

This wrapper was written with the intention of being used on the University of Heidelberg BioQuant cluster
```
Program: CITE-seq-Count

Version: 0.1

Usage: ./citeseq.sh -i <input file or directory> -o <output location>[optional] -t <hashtag oligos> -c <conda environment>[optional] -h <help>

Options:
        -i      Input: Path to directory containing all fastqs or file containing list of directories with fastqs, one directory per line [required]
        -o      Output directory: Path to location where output will be generated [default=HOME]
        -t      Path to csv containing hashtag antibody barcodes and respective names [required]
        -c      Conda environment: Name of conda environment with CITE-seq-Count installed (unless it is available on path) [default=PATH]
        -h      Help: Does what it says on the tin
```
## Input

The input `-i` can be either the path to one directory containing multiple hashtag fastqs, or the path to a text file containing a list of directories that contain fastqs for individual samples. When supplying a file containing a list of fastq-containing directories, it is assumed that the directory name is the name of the sample to be analysed. 

Example input file:
```
$head input.txt
/home/directory/sample1_HT
/home/directory/sample2_HT
/home/directory/sample3_HT

$ ls /home/directory/sample1
sample1_HT_S1_L001_R1_001.fastq.gz sample1_S1_L001_R2_001.fastq.gz
sample1_HT_S1_L002_R1_001.fastq.gz sample1_S1_L002_R2_001.fastq.gz

```
Example input directory:
```
$ ls /home/directory/input
sample1_HT_S1_L001_R1_001.fastq.gz sample1_HT_S1_L001_R2_001.fastq.gz
sample1_HT_S1_L002_R1_001.fastq.gz sample1_HT_S1_L002_R2_001.fastq.gz
sample2_HT_S2_L001_R1_001.fastq.gz sample2_HT_S2_L001_R2_001.fastq.gz
sample2_HT_S2_L002_R1_001.fastq.gz sample2_HT_S2_L002_R2_001.fastq.gz
sample3_HT_S3_L001_R1_001.fastq.gz sample3_HT_S3_L001_R2_001.fastq.gz
sample3_HT_S3_L002_R1_001.fastq.gz sample3_HT_S3_L002_R2_001.fastq.gz
```
## Hashtag Oligos
A comma separated file containing antibody barcodes and associated label names.
Example oligos file:
```
TTCCTGCCATTACTA,A0451
CCGTACCTCATTGTT,A0452
GGTAGATGTCCTCAG,A0453
TGGTGTCATTCTTGA,A0454
ATGATGAACAGCCAG,A0455
```
## Output

You can set an output directory with the `-o` option, by default data will be stored in your $HOME directory.

The output directory will contain a further directory (per sample) with output files

### Output files 
### [From CITE-seq-Count Documentation](https://hoohm.github.io/CITE-seq-Count/)

```
OUTFOLDER/
-- umi_count/
-- -- matrix.mtx.gz
-- -- features.tsv.gz
-- -- barcodes.tsv.gz
-- read_count/
-- -- matrix.mtx.gz
-- -- features.tsv.gz
-- -- barcodes.tsv.gz
-- unmapped.csv
-- run_report.yaml
```

Directories `read_count` and `umi_count` contain respectively the read counts and the collapsed umi counts. 

For analysis you should use the umi data. 

The read_count can be used to check if you have an overamplification or oversequencing issue with your protocol.

| File Name        | Description           |
| ------------- |-------------|
| features.tsv.gz | Contains the feature names, in this context our tags. |
| barcodes.tsv.gz | Contains the cell barcodes. |
| matrix.mtx.gz | Contains the actual values |
| unmapped.csv | Contains the top N tags that haven't been mapped. |
| run_report.yaml | Contains the parameters used for the run as well as some statistics. |
