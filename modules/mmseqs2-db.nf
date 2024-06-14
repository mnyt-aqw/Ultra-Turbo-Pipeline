process MMSEQS2_MAKEDB {
    tag "$db_name"
    
    input:
    val db_name
    
    output:
    tuple val(db_name), path("*"), emit: mmseqs_db
    
    script:
    """
    mmseqs databases $db_name  db tmp --threads ${task.cpus}   
    """
}