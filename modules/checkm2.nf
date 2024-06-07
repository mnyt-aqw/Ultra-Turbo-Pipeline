process CHECKM2 {
    tag "Single process"

    input:
    path genomes
    path db

    output:
    path "quality_report.tsv" ,emit: checkm2_report


    script:
    """
    checkm2 \
        predict \
        --input . \
        --output-directory output/ \
        --threads ${task.cpus} \
        --database_path ${db} \
        -x  fa.gz

    mv output/quality_report.tsv .
    rm -r output
    """
}