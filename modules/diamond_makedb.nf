process DIAMOND_MAKEDB {
    tag "$sample"

    input:
    tuple val(db_name), path(fasta)

    output:
    tuple val(db_name), path("${db_name}.dmnd"), emit: database

    script:
    """
    diamond makedb --in $fasta -d ${db_name}
    """
}