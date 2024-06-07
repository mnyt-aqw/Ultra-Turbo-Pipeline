process DIAMOND_BLASTP {
    tag "$sample"
    
    input:
    tuple val(sample), path(assembly), val(db_name), path(database)

    output:
    path "${sample}_${db_name}_diamond.tsv", emit: diamond_out

    script:
    """
    diamond blastp \\
    --db $database \\
    --query $assembly \\
    --out ${sample}_${db_name}_diamond.tsv \\
    --outfmt 6 \\
    -p $task.cpus \\
    -k0 \\
    --id ${params.diamond_id} \\
    --subject-cover ${params.diamond_subject_cov} 
    """
}