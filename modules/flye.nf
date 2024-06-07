process FLYE {
    tag "$sample"
    
    input:
    tuple val(sample), path(reads)

    output:
    tuple val(sample), path("${sample}*.fasta.gz"), emit: assembly
    tuple val(sample), path("${sample}*.gfa.gz")  , emit: gfa
    tuple val(sample), path("${sample}*.gv.gz")   , emit: gv
    tuple val(sample), path("${sample}*.txt")     , emit: txt
    tuple val(sample), path("${sample}.log")     , emit: log
    tuple val(sample), path("${sample}*.json")    , emit: json

    script:
    """
    flye \\
        --nano-hq \\
        $reads \\
        --out-dir . \\
        --threads $task.cpus \\
        

    gzip -c assembly.fasta > ${sample}.assembly.fasta.gz
    gzip -c assembly_graph.gfa > ${sample}.assembly_graph.gfa.gz
    gzip -c assembly_graph.gv > ${sample}.assembly_graph.gv.gz
    mv assembly_info.txt ${sample}.assembly_info.txt
    mv params.json ${sample}.params.json
    mv flye.log ${sample}.log
    """
}