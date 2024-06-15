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
    --device ${params.DORADO_device} \
    --trim none \
    --kit-name ${params.DORADO_kit} \
    > ${reads}.bam

    
    """
}