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

## Features

- Converts fast5 files to pod5 format and splits reads by channel for
  parallel processing.
- Basecalls reads from each channel individually using Dorado.
- Combines base-called reads and performs quality control using PycoQC
  and Filtlong.
- Assembles genomes with Flye and polishes assemblies with Medaka.
- Assesses assembly quality with CheckM2 and BUSCO.
- Screens for antimicrobial resistance genes (ARGs) and mobile genetic
  elements (MGEs).
- Performs taxonomic classification using GTDB-TK and MMSeqs2.

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

## Configuration parameters

The pipeline can be configured using the following parameters in
nextflow.config:

- `params.reads`: Path to the input reads (fast5 or pod5 format).

- `params.outdir`: Output directory for results.

- `params.dorado`: Boolean flag to enable or disable Dorado basecalling.

- `params.basecalled_reads`: Path to the basecalled reads.

- `params.databases`: Path to the databases for Diamond in protein
  format.

- `params.clusterOptions`: Cluster options for SLURM or other
  schedulers.

- `params.storeDir`: Directory to store intermediate files.

- `params.directory_out`: Directory to store final results.

- `params.diamond_id`: Minimum identity threshold for Diamond.

- `params.diamond_subject_cov`: Minimum subject coverage threshold for
  Diamond.

- `params.DORADO_model`: Choose between three models:  
  `fast`: fast and less accurate.  
  `hac`: slower and more accurate.  
  `sup`: Slow and most accurate.  

- `params.MEDAKA_model`: Medaka model to use for polishing.

- `params.filtlong_min_lenght`: Minimum read length for Filtlong.

- `params.filtlong_keep_percent`: Percentage of reads to keep for
  Filtlong.

- `params.DORADO_device`: Device to use for Dorado (e.g., CPU or GPU).

- `params.DORADO_kit`: Kit used for Dorado basecalling.

## Process Configuration

The pipeline includes specific configurations for each process, such as
CPU requirements, Conda environments, container images, and error
handling strategies. For example:

``` groovy
process {
    withName:CONV_fast5_POD5 {
        cpus = 1 // Nr Cores
        conda = ""
        container = "quay.io/sangerpathogens/pod5:0.3.6" // Name of container
        publishDir = "${params.directory_out}/Demultiplexed/" // Where output is published
        maxRetries = 3 // Nr of times Nextflow will retry if the process fails
        errorStrategy = { task.exitStatus in 137..140 ? 'retry' : 'terminate' }
    }
}
```
