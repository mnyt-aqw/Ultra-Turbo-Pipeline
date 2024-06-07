process PRODIGAL {
    tag "$sample"

    input:
    tuple val(sample), path(genome)
    
    output:
    tuple val(sample), path("${sample}.translations.faa"), emit: coding_regions
    tuple val(sample), path("${sample}.gbk")             , emit: gbk
    
    script:
    """
    gunzip ${genome} -c > file.fasta

    prodigal  \
    -i file.fasta \
    -o ${sample}.gbk \
    -a ${sample}.translations.faa \
    -p single

    rm file*
    """
}