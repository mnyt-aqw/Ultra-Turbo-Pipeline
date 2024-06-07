// Dorado basecalling
process DORADO {
    tag "$sample"

    input:
    tuple val(sample), path(reads)
    
    output:
    tuple val(sample), path("*.fq.gz"), emit: reads
    tuple val(sample), path("${sample}_summary.tsv"), emit: summary
    
    script:
    """
    dorado basecaller \
    ${params.DORADO_model} \
    ${reads} \
    --device ${params.DORADO_device} \
    --trim none \
    --kit-name ${params.DORADO_kit} \

    > ${sample}.bam

    dorado demux \
    --output-dir demultiplexed/ \
    ${sample}.bam

    dorado summary ${sample}.bam > ${sample}_summary.tsv
    
    for bam_file in demultiplexed/*.bam; do
        base_name=\$(basename "\$bam_file" .bam)
        dorado trim "\$bam_file" --emit-fastq > "\${base_name}.fq"
    done
    mv demultiplexed/*.fq .

    gzip *.fq
    """
}