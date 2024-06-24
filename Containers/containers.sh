#!/bin/bash

# Build contaier from def file
apptainer build dorado.sif apptainer.def

# Define the containers and their respective names
declare -A containers
containers=(
    ["Filtlong"]="quay.io/biocontainers/filtlong:0.2.1--hdcf5f25_3"
    ["PycoQC"]="quay.io/biocontainers/pycoqc:2.5.2--py_0"
    ["Flye"]="quay.io/biocontainers/flye:2.9.3--py39hd65a603_1"
    ["Medaka"]="quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0"
    ["CheckM2"]="quay.io/biocontainers/checkm2:1.0.1--pyh7cba7a3_0"
    ["Diamond"]="quay.io/biocontainers/diamond:2.1.9--h43eeafb_0"
    ["GTDBTK"]="quay.io/biocontainers/gtdbtk:2.4.0--pyhdfd78af_1"
    ["MMseqs2"]="quay.io/biocontainers/mmseqs2:15.6f452--pl5321h6a68c12_2"
    ["RGI"]="quay.io/biocontainers/rgi:6.0.3--pyha8f3691_1"
    ["Biopython"]="quay.io/biocontainers/biopython:1.79"
)

# Pull each container and save it with the specified name
for name in "${!containers[@]}"; do
    echo "Pulling container for $name..."
    apptainer pull $name.sif docker://${containers[$name]}
done

echo "All containers have been pulled and saved!"