Ultra Turbo Pipeline
================

## Overview

This pipeline processes Nanopore sequencing files, assembles them,
assesses the quality of the assemblies, performs taxonomic
classification, and searches for genes, including antibiotic resistance
genes using RGI. The pipeline uses Nextflow for orchestration and
supports Conda and Apptainer environments for software dependencies.

## How to run the pipeline

### Fetch the pipeline

The easiest way to download the pipeline is to clone this GitHub repo to
a local directory on a local machine, cluster, or server like the
example below.

``` bash
git clone https://github.com/mnyt-aqw/Ultra-Turbo-Pipeline.git
```

### Build container

Most containers for this pipeline are publicly available on various
container repositories. There is however one that you should build
locally. Go to the `Container` directory and execute this command

``` bash
apptainer build apptainer.sif apptainer.def
```

### Start pipeline

To start the pipeline, execute this line:

``` bash
NXF_VER=24.04.2 nextflow run main.nf --profile {server or cluster} {other args}
```

This will download a specific version of Nextflow, and you will have to
specify if you run the pipeline on a server or cluster. If you want to
resume the pipeline, use the `-resume`flag. The pipeline will then
ignore processes it has already finished.

#### SLURM

When running Nextflow on a SLURM-managed cluster, Nextflow submits its
own jobs with the resources specified in the configuration file. Each
process in the pipeline can have specific resource requirements (e.g.,
CPUs, time) defined in nextflow.config. Nextflow handles the job
submission, management, and resource allocation automatically.

If you need to submit jobs on a cluster like Vera using an SBATCH
script, you can use a script like this:

``` bash
#!/usr/bin/env bash
#SBATCH -A C3SE2021-2-3 -p vera     # Add YOUR Project name and Partition/queue name.
#SBATCH -J {name}                   # Job name
#SBATCH -c 1                        # Number of CPU cores. You do not need more than 1 here
#SBATCH -t 24:00:00                 # Maximum runtime
#SBATCH --error={PATH}/job.%J.err   # Path to the error file
#SBATCH --output={PATH}/job.%J.out  # Path to the output file

# Unload unwanted packages and load Nextflow
module purge
module load Nextflow

# Start the pipeline with specific version of Nextflow
NXF_VER=24.04.2 nextflow run main.nf -profile "cluster"
```

If you need to change the resources allocated to each process, open the
`nextflow.config` file and change the values.

``` groovy
process {
    withName:PRODIGAL {
        cpus = 1 // nr CPUs
        time = '1m' // max duration
        container = "${projectDir}/Containers/apptainer.sif" // container
        storeDir = "${params.storeDir}/Prodigal/" // where to store cache
        publishDir = "${params.directory_out}/Prodigal/" // where to publish results
    }
}
```

## Workflow

1.  **Basecalling**
    - **DORADO_BASECALL**: Converts raw Pod5 files to basecalled BAM
      files.
    - **DORADO_DEMULTIPLEX**: Splits the BAM files into barcoded reads
      and provides a summary for quality control.
    - **PYCOQC**: Generates quality control metrics from the basecalling
      summary.
    - **FILTLONG**: Filters and trims the reads to ensure high quality.
2.  **Assembly**
    - **FLYE**: Assembles the filtered reads into contigs.
    - **MEDAKA**: Polishes the assembly to correct errors.
    - **CHECKM2_DATABASEDOWNLOAD**: Downloads the CheckM2 database.
    - **CHECKM2**: Assesses the quality of the assembly.
3.  **ARG_Mapping**
    - **RGI**: Screens for antibiotic resistance genes.
4.  **BLASTX**
    - **PRODIGAL**: Predicts coding regions in the assembly.
    - **DIAMOND_MAKEDB**: Creates a DIAMOND database.
    - **DIAMOND_BLASTP**: Screens for genes using the DIAMOND tool.
5.  **Taxonomy**
    - **GTDB_TK_MAKEDB**: Downloads and prepares the GTDB-TK database.
    - **GTDB_TK**: Classifies the assembly based on the GTDB-TK
      database.
    - **MMSEQS2_MAKEDB**: Creates an MMseqs2 database.
    - **MMSEQS2_CLASSIFY**: Classifies the assembly using MMseqs2.

## Pipeline Workflow

``` mermaid
graph TD
    C[Basecall reads with Dorado]
    C --> D[Demultiplex]
    D --> E[Filter and quality control reads with Filtlong]
    D --> F[Visualize quality metrics with PycoQC]
    E --> G[Assemble genome with Flye]
    G --> H[Polish assembly with Medaka]
    H --> I[Determine assembly quality with CheckM2]
    H --> J[Map antibiotic resistance genes with RGI]
    H --> K[Predict genes with Prodigal]
    K --> L[Search predicted genes against databases with Diamond]
    H --> M[Taxonomically classify genome with GTDB-Tk]
    H --> N[Classify individual contigs with MMseqs2]

    subgraph Basecalling
        C
        D
        F
    end

    subgraph Assembly
        E
        G
        H
        I
    end

    subgraph ARG_Mapping
        J
    end

    subgraph BLASTX
        K
        L
    end

    subgraph Taxonomy
        M
        N
    end
```

## Parameters

The pipeline parameters are defined in the `config` file. You can either
change each value on the command line like this
`--input_files {VAL} --databases {PATH}. Or by changing the values in the`nextflow.config\`
file.

### Input/output

- `input_files`: Path to input Pod5 files, or basecalled fasta files,
  depending on which modules you want to run. Use glob patterns like
  this `{PATH}/*pod5`
- `storeDir`: Directory to store intermediate files. `./Store`
- `directory_out`: Directory for final output. `./Results`
- `databases`: Path to protein fasta files. Can either be specified like
  this: `{PATH}/file.fasta`. Or if you have multiple files (can be as
  many as you like): `{PATH}/*.fasta`.

### Machine options

- `clusterOptions`: Same as `-A {PROJECT_NAME} -p {CLUSTER_NAME}` in the
  SBATCH script of run in a cluster. Otherwise empty.
- `DORADO_device`: Device for Dorado (e.g., “cpu”, “gpu”, “cuda:0”,
  “all”). GPU is much faster and is therefore the preferred option if
  available. To choose that on Vera select “cuda:0”. Otherwise it won’t
  properly detect the GPUs.
- `gpu_allocated`: If you want to run Dorado using a GPU you can specify
  which one here. If you run the pipeline on the Vera cluster you write
  `--gpus-per-node=V100:1`. This will allocate one V100 GPU per process.
  Dorado only works on V100 and A100 GPUs.

### Process settings

- `diamond_id`: Minimum percent identity for DIAMOND BLASTP.
  `Default: 90 %`
- `diamond_subject_cov`: Minimum subject coverage for DIAMOND BLASTP.
  `Default 80 %`
- `filtlong_min_lenght`: Minimum length of reads to keep. `Default 6000`
- `filtlong_keep_percent`: Percent of the longest reads to keep.
  `Default 90 %`
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

### Which modules to tun

To run a module enter `true`. To skip it enter `false`. You can see what
module does what in the flow chart above.

- `Basecalling`: true
- `Assembly`: true
- `Taxonomy`: false
- `ARG_Mapping`: true
- `BLASTX`: false
