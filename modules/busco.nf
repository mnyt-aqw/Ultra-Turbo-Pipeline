process BUSCO {
    tag "$sample"

    input:
    path assembly

    output:
    path "busco/*-busco.batch_summary.txt"                , emit: batch_summary
    path "busco/short_summary.*.txt"                      , emit: short_summaries_txt   , optional: true
    path "busco/short_summary.*.json"                     , emit: short_summaries_json  , optional: true
    path "busco/*/run_*/full_table.tsv"                   , emit: full_table            , optional: true
    path "busco/*/run_*/missing_busco_list.tsv"           , emit: missing_busco_list    , optional: true
    path "busco/*/run_*/single_copy_proteins.faa"         , emit: single_copy_proteins  , optional: true
    path "busco/*/run_*/busco_sequences"                  , emit: seq_dir
    path "busco/*/translated_proteins"                    , emit: translated_dir        , optional: true
    path "busco"                                          , emit: busco_dir
    path "busco/busco_figure.png"                         , emit: busco_png

    script:
    """
    # unzip files
    for file in *.gz; do
        sample_id=\$(basename "\$file" | cut -d. -f1)
        gunzip -c "\$file" > "\${sample_id}.fasta"
    done

    mkdir assemblies/
    mv *.fasta assemblies/.

    busco \\
        --cpu ${task.cpus} \
        --in  assemblies/ \
        --out busco/ \
        --mode genome \
        --auto-lineage-prok \
        -f

    rm -r assemblies/

    #mv busco/batch_summary.txt busco/short_summary_all.txt 
#
    #generate_plot.py -wd busco/
    """
}