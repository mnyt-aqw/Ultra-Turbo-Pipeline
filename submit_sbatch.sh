#!/usr/bin/env bash
#SBATCH -A {project_id} -p {queue_name} 
#SBATCH -J test_name
#SBATCH -c 1
#SBATCH -t 15:00:00
#SBATCH --error={PATH}/err/job.%J.err 
#SBATCH --output={PATH}/err/job.%J.out 

# Unload all modules and load Nextflow
module purge
module load Nextflow

NXF_VER=24.04.2 nextflow run main.nf -profile "cluster" -resume 