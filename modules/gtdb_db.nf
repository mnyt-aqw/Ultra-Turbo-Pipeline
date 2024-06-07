process GTDB_TK_MAKEDB {
    tag "$db_name"

    output:
    path ("*") , emit: db_files

    script:
    """
    wget ${params.GTDB_db} 
    tar -xvzf *
    rm *tar.gz
    """
}