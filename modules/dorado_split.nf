// Dorado basecalling
process DORADO_SPLIT {
    tag "$sample"

    input:
    //tuple val(sample), path(bam)
    //
    //output:
    //tuple val(sample), path("${sample}_barcode*.fq.gz"), emit: reads
    //tuple val(sample), path("${sample}_summary.tsv"), emit: summary

    path bam 
    //
    output:
    path("*barcode*.fq.gz"),         emit: barcoded_reads
    path("unclassified.fq.gz"),      emit: unclassified_reads
    path("dorado_summary.tsv"),      emit: summary
    
    script:
    """
    samtools merge -@ ${task.cpus} merged.bam *.bam

    ${params.Dorado} demux \
    --no-classify \
    --output-dir demultiplexed/ \
    merged.bam

 
    ${params.Dorado} summary merged.bam  > dorado_summary.tsv

    for bam_file in demultiplexed/*.bam; do
        base_name=\$(basename "\$bam_file" .bam)
        ${params.Dorado} trim "\$bam_file" --emit-fastq > "\${base_name}.fq"
    done

    gzip *.fq
    """
}

    // #  ${params.Dorado} summary merged.bam  > ${sample}_summary.tsv
    //#for bam_file in demultiplexed/*.bam; do
    //#    base_name=\$(basename "\$bam_file" .bam)
    //#    ${params.Dorado} trim "\$bam_file" --emit-fastq > "\${base_name}.fq"
    //#done
//
    //#for fq_file in *.fq; do
    //#    barcode=\$(echo "\$fq_file" | sed 's/.*barcode/barcode/')
    //# #   mv "\$fq_file" "${sample}_\${barcode}"
    //# mv "\$fq_file" "${sample}_\${barcode}"
    //done
    //gzip *.fq