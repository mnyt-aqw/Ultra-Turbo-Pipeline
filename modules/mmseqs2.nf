process MMSEQS2_CLASSIFY {
    tag "$sample_id"

    input:
    tuple val(db_id), path(db)
    tuple val(sample_id), path(query_fasta)

    output:
    tuple val(sample_id), path("${sample_id}_taxonomy_lca.tsv"), emit: taxonomy

    script:
    """
    # Get the real path of the symlinked 'tmp' directory
    cp tmp/ -r temporary

    mmseqs easy-taxonomy ${query_fasta} db ${sample_id}_taxonomy temporary --threads ${task.cpus} --format-mode 0 --search-type 0
    """
}