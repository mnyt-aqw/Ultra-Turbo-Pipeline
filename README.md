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

### Download containers

This script builds a custom container from the provided definition file
and pulls pre-built containers for all other tools used in the pipeline.

``` bash
cd Containers/
bash containers.sh
```

### Prerequisits

The only prerequisits you need to run this pipeline are
`Apptainer`/`Docker`, and `Nextflow`. The pipeline will install
everything else by it self.

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
script, This script is the same as `submit_sbatch.sh`:

``` bash
#!/usr/bin/env bash
#SBATCH -A C3SE2021-2-3 -p vera     # Add YOUR Project name and Partition/queue name.
#SBATCH -J {name}                   # Job name
#SBATCH -c 1                        # Number of CPU cores. You do not need more than 1 here
#SBATCH -t 24:00:00                 # Maximum runtime
#SBATCH --error={PATH}/job.%J.err   # Path to the error file
#SBATCH --output={PATH}/job.%J.out  # Path to the output file

# Unload all modules and load Nextflow
module purge
module load Nextflow

# Start the pipeline with specific version of Nextflow
NXF_VER=24.04.2 nextflow run main.nf -profile "cluster" -resume
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
    A[Input: Pod5/FASTQ files]

    subgraph Basecalling
        B[DORADO_BASECALL]
        B -->|BAM| C[DORADO_DEMULTIPLEX]
        C -->|Summary| D[PYCOQC]
        C -->|FASTQ| E[FILTLONG]
    end

    subgraph Assembly
        F[FLYE]
        F -->|Draft assembly| G[MEDAKA]
        G -->|Polished assembly| H[CHECKM2]
        G -->|Polished assembly| I[BUSCO]
    end

    subgraph Taxonomy
        J[GTDB_TK]
        K[MMSEQS2]
    end

    subgraph ARG_Mapping
        L[RGI]
    end

    subgraph BLASTX
        M[PRODIGAL]
        N[DIAMOND_MAKEDB]
        O[DIAMOND_BLASTP]
    end

    A -->|Pod5| B
    E -->|Filtered FASTQ| F
    G -->|Polished assembly| J
    G -->|Polished assembly| K
    G -->|Polished assembly| L
    G -->|Polished assembly| M
    M -->|Predicted genes| O
    N -->|Database| O
```

## Parameters

The pipeline parameters are defined in the `config` file. You can either
change each value on the command line like this
`--input_files {VAL} --databases {PATH}. Or by changing the values in the`nextflow.config\`
file.

<div>

> **Note**
>
> When ypu specify paths to files you can either use full paths. Or you
> can use reltive paths. But instead us specifying `"../../db/*.gz"`.
> You do it like this `"${projectDir}/../../db/*.gz"`. If you od that do
> **not** use singel quotes `'`, use doubble `"`.

</div>

### Mandatory

#### Input/output

- `input_files`: Path to input Pod5 files, or basecalled fasta files,
  depending on which modules you want to run. Use glob patterns like
  this `{PATH}/*pod5`

#### Machine options

- `clusterOptions`: Specifies additional cluster options, similar to the
  options used in an SBATCH script. For example, use
  `-A {PROJECT_NAME} -p {CLUSTER_NAME}` when running on a cluster. Leave
  this empty if not applicable. (Only if `-profile "cluster"`)
- `DORADO_device`: Specifies the device for running Dorado (e.g., “cpu”,
  “gpu”, “cuda:0”, “all”). Using a GPU is highly recommended as it
  significantly speeds up the process. For the Vera cluster, specify
  `cuda:0` to ensure proper GPU detection.(Only if `Basecalling:true`)
- `gpu_allocated`: Specifies the GPU allocation for running Dorado. For
  the Vera cluster, use `--gpus-per-node=V100:1` to allocate one V100
  GPU per process. Note that Dorado only supports V100 and A100 GPUs.
  (Only if `Basecalling:true`)

#### Process setting

- `DORADO_kit`: Kit name for barcodes.
- `mmseq2_db`: Name of MMseqs2 database. Read about the different
  options
  [here](https://github.com/soedinglab/mmseqs2/wiki#downloading-databases).
  (Only if `Taxonomy:true`)

### Which modules to tun

To run a module enter `true`. To skip it enter `false`. You can see what
module does what in the flow chart above.

- `Basecalling`: true
- `Assembly`: true
- `Taxonomy`: false
- `ARG_Mapping`: true
- `BLASTX`: false

### Settings wiht predefined defaults

#### Input/output

- `storeDir`: Directory to store intermediate files. `./Store`
- `directory_out`: Directory for final output. `./Results`
- `databases`: Path to protein fasta files. Can either be specified like
  this: `{PATH}/file.fasta`. Or if you have multiple files (can be as
  many as you like): `{PATH}/*.fasta`.

#### Process settings

- `diamond_id`: Minimum percent identity for DIAMOND BLASTP.
  `Default: 90 %`
- `diamond_subject_cov`: Minimum subject coverage for DIAMOND BLASTP.
  `Default 80 %`
- `filtlong_min_lenght`: Minimum length of reads to keep. `Default 6000`
- `filtlong_keep_percent`: Percent of the longest reads to keep.
  `Default 90 %`
- `DORADO_model`: Model for Dorado basecalling. This determines the
  accuracy and time it takes. Choose between three models:  
  `fast`: fast and less accurate.  
  `hac`: slower and more accurate.  
  `sup`: Slow and most accurate.  
- `GTDB_db`: URL for GTDB database. Default is downloading the latest
  version. `Default: v.220`.

The assembly related defaults are based on the valued identified by the
authors of [this](https://doi.org/10.1371/journal.pcbi.1010905) paper.

## Pipeline Outputs

The Ultra Turbo Pipeline generates several output files in the directory
specified by `params.directory_out` (default: “./Results”):

### Basecalling (Dorado/)

- \*.fa.gz: Demultiplexed sequence reads for each barcode
- dorado_summary.tsv: Summary statistics of the basecalling run

### Quality Control (pycoQC/)

- summary.html: Interactive report of sequencing run quality
- summary.json: Raw data of sequencing quality metrics

### Read Filtering (Filtlong/)

- \*\_trimmed.fq.gz: Filtered and trimmed high-quality reads

### Assembly (Flye/)

- \*.assembly.fa.gz: Final assembled genome sequences
- \*.assembly_graph.gfa.gz: Assembly graph in GFA format
- \*.assembly_info.txt: Statistics about the assembly
- \*.log: Log file of the Flye assembly process

### Assembly Polishing (Medaka/)

- \*.fa.gz: Polished genome assembly with reduced errors

### Assembly Quality Assessment (CheckM2/)

- quality_report.tsv: Completeness and contamination estimates of the
  assembly

### Gene Prediction (Prodigal/)

- \*.translations.faa: Predicted protein sequences
- \*.gbk: Gene annotations in GenBank format

### Antibiotic Resistance Gene Detection (RGI/)

- \*.txt: Identified antibiotic resistance genes and their annotations

### Protein Search (Diamond_Blastp/)

- \*\_diamond.tsv: Results of protein similarity searches

### Taxonomic Classification

GTDB_TK/: - gtdbtk.\*.summary.tsv: Taxonomic classification based on
GTDB - gtdbtk.log: Log file of the GTDB-Tk run

mmseqs2/: - \*\_taxonomy_lca.tsv: Taxonomic classification of contigs
using LCA algorithm
