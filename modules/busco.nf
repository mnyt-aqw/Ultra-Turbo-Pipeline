process BUSCO {
    tag "$sample"

    input:
    tuple val(meta), path(fasta, stageAs:'tmp_input/*')
    val mode                              // Required:    One of genome, proteins, or transcriptome
    val lineage                           // Required:    lineage to check against, "auto" enables --auto-lineage instead
    path busco_lineages_path              // Recommended: path to busco lineages - downloads if not set

    output:
    tuple val(sample), path("*-busco.batch_summary.txt")                , emit: batch_summary
    tuple val(sample), path("short_summary.*.txt")                      , emit: short_summaries_txt   , optional: true
    tuple val(sample), path("short_summary.*.json")                     , emit: short_summaries_json  , optional: true
    tuple val(sample), path("*-busco/*/run_*/full_table.tsv")           , emit: full_table            , optional: true
    tuple val(sample), path("*-busco/*/run_*/missing_busco_list.tsv")   , emit: missing_busco_list    , optional: true
    tuple val(sample), path("*-busco/*/run_*/single_copy_proteins.faa") , emit: single_copy_proteins  , optional: true
    tuple val(sample), path("*-busco/*/run_*/busco_sequences")          , emit: seq_dir
    tuple val(sample), path("*-busco/*/translated_proteins")            , emit: translated_dir        , optional: true
    tuple val(sample), path("*-busco")                                  , emit: busco_dir


    script:
    if ( mode !in [ 'genome', 'proteins', 'transcriptome' ] ) {
        error "Mode must be one of 'genome', 'proteins', or 'transcriptome'."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}-${lineage}"
    def busco_config = config_file ? "--config $config_file" : ''
    def busco_lineage = lineage.equals('auto') ? '--auto-lineage' : "--lineage_dataset ${lineage}"
    def busco_lineage_dir = busco_lineages_path ? "--download_path ${busco_lineages_path}" : ''
    """
    

    busco \\
        --cpu $task.cpus \\
        --in "\$INPUT_SEQS" \\
        --out ${prefix}-busco \\
        --mode $mode \\
        $busco_lineage \\
        $busco_lineage_dir \\
        $busco_config \\
        $args

    # clean up
    rm -rf "\$INPUT_SEQS"

    # Move files to avoid staging/publishing issues
    mv ${prefix}-busco/batch_summary.txt ${prefix}-busco.batch_summary.txt
    mv ${prefix}-busco/*/short_summary.*.{json,txt} . || echo "Short summaries were not available: No genes were found."

    generate_plot.py \\
        $args \\
        -wd busco
    """
}