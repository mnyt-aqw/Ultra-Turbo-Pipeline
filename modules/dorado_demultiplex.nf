// Dorado basecalling
process DORADO_DEMULTIPLEX {
    tag "$sample"

    input:
    path bam 

    output:
    path("*barcode*.fa.gz"),         emit: barcoded_reads
    path("unclassified.fa.gz"),      emit: unclassified_reads
    path("dorado_summary.tsv"),      emit: summary
    
    script:
    """
    samtools merge -@ ${task.cpus} merged.bam *.bam

    dorado demux \
    --no-classify \
    --output-dir demultiplexed/ \
    merged.bam

    dorado summary merged.bam  > dorado_summary.tsv

    for bam_file in demultiplexed/*.bam; do
        base_name=\$(basename "\$bam_file" .bam)
        dorado trim "\$bam_file" --emit-fastq > "\${base_name}.fa"
    done

    gzip *.fa
    """
}