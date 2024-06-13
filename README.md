Ultra Turbo Pipeline
================

# Ultra Turbo Pipeline

## Overview

This pipeline processes Nanopore sequencing files, assembles them,
assesses the quality of the assemblies, performs taxonomic
classification, and searches for genes, including antibiotic resistance
genes using RGI. The pipeline uses Nextflow for orchestration and
supports Conda and Apptainer (Singularity) environments for software
dependencies.

## How to run the pipeline

### Build container

Most containers for this pipeline are publicly available on various
container repositories. There is however one that you should build
locally. Go to the `Container` directory and execute this command
`apptainer build apptainer.sif apptainer.def`.

## Workflow

1.  **Basecalling and Demultiplexing**
    - **DORADO_BASECALL**: Converts raw Pod5 files to basecalled BAM
      files.
    - **DORADO_DEMULTIPLEX**: Splits the BAM files into barcoded reads
      and provides a summary for quality control.
2.  **Quality Control**
    - **PYCOQC**: Generates quality control metrics from the basecalling
      summary.
    - **FILTLONG**: Filters and trims the reads to ensure high quality.
3.  **Assembly and Polishing**
    - **FLYE**: Assembles the filtered reads into contigs.
    - **MEDAKA**: Polishes the assembly to correct errors.
4.  **Assembly Quality Assessment**
    - **CHECKM2_DATABASEDOWNLOAD**: Downloads the CheckM2 database.
    - **CHECKM2**: Assesses the quality of the assembly.
    - **BUSCO**: Evaluates the completeness of the assembly using
      Benchmarking Universal Single-Copy Orthologs.
5.  **Gene Screening**
    - **PRODIGAL**: Predicts coding regions in the assembly.
    - **DIAMOND_MAKEDB**: Creates a DIAMOND database (optional).
    - **DIAMOND_BLASTP**: Screens for genes using the DIAMOND tool
      (optional).
    - **RGI**: Screens for antibiotic resistance genes.
6.  **Taxonomic Classification**
    - **GTDB_TK_MAKEDB**: Downloads and prepares the GTDB-Tk database.
    - **GTDB_TK**: Classifies the assembly based on the GTDB-Tk
      database.
    - **MMSEQS2_MAKEDB**: Creates an MMseqs2 database.
    - **MMSEQS2_CLASSIFY**: Classifies the assembly using MMseqs2.

## Pipeline Workflow

``` mermaid
graph TD
    A[Convert fast5 to pod5] --> B[Basecall reads with Dorado]
    B --> C[Combine basecalled reads and output summary]
    C --> D[Filter and quality control reads with Filtlong]
    C --> E[Visualize quality metrics with PycoQC]
    D --> F[Assemble genome with Flye]
    F --> G[Polish assembly with Medaka]
    G --> H[Determine assembly quality with CheckM2 and BUSCO]
    G --> I[Map antibiotic resistance genes with RGI]
    G --> J[Predict genes with Prodigal]
    J --> K[Search predicted genes against databases with Diamond]
    G --> L[Taxonomically classify genome with GTDB-Tk]
    G --> M[Classify individual contigs with MMseqs2]
```

## Parameters

The pipeline parameters are defined in the `config` file:

- `reads`: Path to input Pod5 files.
- `databases`: Path to custom databases.
- `clusterOptions`: Additional cluster options.
- `storeDir`: Directory to store intermediate files.
- `directory_out`: Directory for final output.
- `diamond_id`: Minimum percent identity for DIAMOND BLASTP.
  `Default 90 %`
- `diamond_subject_cov`: Minimum subject coverage for DIAMOND BLASTP.
  `Default 80 %`
- `filtlong_min_lenght`: Minimum length of reads to keep. `Default 6000`
- `filtlong_keep_percent`: Percent of the longest reads to keep.
  `Default 90 %`
- `DORADO_device`: Device for Dorado (e.g., “cpu”, “gpu”). GPU is much
  faster and is therefore the preferred option if available.
- `DORADO_kit`: Kit name for barcodes.
- `DORADO_model`: Model for Dorado basecalling. This determines the
  accuracy and time it takes. Choose between three models:  
  `fast`: fast and less accurate.  
  `hac`: slower and more accurate.  
  `sup`: Slow and most accurate.  
- `GTDB_db`: URL for GTDB database. Default is downloading the latest
  version.
- `mmseq2_db`: Name of MMseqs2 database. Read about the different
  options
  [here](https://github.com/soedinglab/mmseqs2/wiki#downloading-databases).

The assembly related defaults are based on the valued identified by the
authors of [this](https://doi.org/10.1371/journal.pcbi.1010905) paper.

## Process Configuration

The pipeline includes specific configurations for each process, such as
CPU requirements, container images, and error handling strategies. For
example:

``` groovy
process {
    withName:PRODIGAL {
        cpus = 1 // nr CPUs
        time = '1m' // max duration
        container = "${projectDir}/Containers/apptainer.sif" // container
        storeDir = "${params.storeDir}/Prodigal/" // where to store cache
        publishDir = "${params.directory_out}/Prodigal/" // where to publish results
        maxRetries = 3 // nr times it retried process if it fails
    }

}
```
