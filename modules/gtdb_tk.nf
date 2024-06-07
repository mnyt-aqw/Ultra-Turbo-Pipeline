process GTDB_TK {
    tag "Single process"

    input:
    path db
    path assembly

    output:
    path "gtdbtk.*.summary.tsv"         , emit: summary
    path "gtdbtk.*.classify.tree.gz"    , emit: tree, optional: true
    path "gtdbtk.*.markers_summary.tsv" , emit: markers, optional: true
    path "gtdbtk.*.msa.fasta.gz"        , emit: msa, optional: true
    path "gtdbtk.*.user_msa.fasta.gz"   , emit: user_msa, optional: true
    path "gtdbtk.*.filtered.tsv"        , emit: filtered, optional: true
    path "gtdbtk.failed_genomes.tsv"    , emit: failed, optional: true
    path "gtdbtk.log"                   , emit: log
    path "gtdbtk.warnings.log"          , emit: warnings

    script:

    """
    export GTDBTK_DATA_PATH="$db"
    mkdir genomes
    
    #mv *.gz genomes/.

    gtdbtk classify_wf \
        --genome_dir . \
        --extension gz \
        --prefix gtdbtk \
        --mash_db gtdbtk_mash/ \
        --out_dir classified/ \
        --cpus ${task.cpus} 


    mv classified/* .
    rm -r classified/ 
    mv gtdbtk.log "gtdbtk.log"

    mv gtdbtk.warnings.log "gtdbtk.warnings.log"
    """
}