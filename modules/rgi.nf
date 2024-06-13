process RGI {
    tag "$sample"

    input:
    tuple val(sample), path(assembly)

    output:
    tuple val(sample), path("${sample}*.txt") , emit: tsv

    script:
    """
    rgi \\
        main \\
        --num_threads ${task.cpus} \\
        --output_file ${sample} \\
        --input_sequence ${assembly}
    """

}