// Dorado basecalling
process DORADO_BASECALL {
    tag "$sample"

    input:
    tuple val(sample), path(reads)
    
    output:
    tuple val(sample), path("${reads}.bam"), emit: bam
    
    script:
    """
    dorado basecaller \
    ${params.DORADO_model} \
    ${reads} \
    --device cuda:0 \
    --trim none \
    --kit-name ${params.DORADO_kit} \
    > ${reads}.bam

    # --device ${params.DORADO_device} \
    """
}