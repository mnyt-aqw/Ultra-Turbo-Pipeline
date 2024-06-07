process MEDAKA {
    tag "$sample"

    input:
    tuple val(sample), path(assembly),  path(reads)
    

    output:
    tuple val(sample), path("${sample}.fa.gz"), emit: polished

    script:
    """
    gunzip ${assembly} -c > assembly.fasta
    gunzip ${reads} -c > reads.fasta

        medaka_consensus \
        -t $task.cpus \
        -i reads.fasta \
        -d assembly.fasta \
        -o output/

    mv output/consensus.fasta ${sample}.fa

    rm -r output assembly.fasta reads.fasta
    gzip -n ${sample}.fa
    """
}