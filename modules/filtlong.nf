// Filtlong filtering
process FILTLONG {
    tag "$sample"
    publishDir "${params.outdir}/filtlong", mode: 'copy'
    
    input:
    tuple val(sample), path(reads)
    
    output:
    tuple val(sample), path("${sample}_trimmed.fastq.gz") , emit: reads
    
    script:
    """
    filtlong \
    --min_length ${params.filtlong_min_lenght} \
    --keep_percent ${params.filtlong_keep_percent} \
    ${reads} \
    | gzip > ${sample}_trimmed.fastq.gz
    """
}