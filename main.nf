#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Modules

// Basecall reads from each channel individually
include { DORADO_BASECALL } from './modules/dorado_basecall'

// Combine all base-called channels per flow cell and output fastq and a summary file for PYCOQC
include { DORADO_DEMULTIPLEX } from './modules/dorado_demultiplex'

// Filtering and quality control
include { FILTLONG } from './modules/filtlong'

// Visualize quality metrics
include { PYCOQC } from './modules/pycoQC'

// Assembly
include { FLYE } from './modules/flye'

// Assembly polishing
include { MEDAKA } from './modules/medaka' 

// Determine assembly quality
include { CHECKM2_DATABASEDOWNLOAD } from './modules/checkm2_download_db'
include { CHECKM2 } from './modules/checkm2'
include { BUSCO } from './modules/busco'

// Mapping of ARGS
include { RGI } from './modules/rgi'

// Screen for MGEs etc
include { PRODIGAL } from './modules/prodigal' 
include { DIAMOND_MAKEDB } from './modules/diamond_makedb'
include { DIAMOND_BLASTP } from './modules/diamond_blastp'

// Taxonomic classification
include { GTDB_TK_MAKEDB } from './modules/gtdb_db'
include { GTDB_TK } from './modules/gtdb_tk'

include { MMSEQS2_MAKEDB } from './modules/mmseqs2-db'
include { MMSEQS2_CLASSIFY } from './modules/mmseqs2'

// Main workflow
workflow {
    Channel
        .fromFilePairs(params.input_files, size: 1)
        .set { read_ch }

    // Run basecalling
    if (params.Basecalling) {
        DORADO_BASECALL(read_ch)
        DORADO_DEMULTIPLEX(DORADO_BASECALL.out.bam.map { it[1] }.collect())
        barcoded = DORADO_DEMULTIPLEX.out.barcoded_reads.flatten()
            .map { file -> [file.baseName, file] }
        PYCOQC(DORADO_DEMULTIPLEX.out.summary)
        FILTLONG(barcoded)
        barcoded_reads_ch = FILTLONG.out.reads
    } else {
        barcoded_reads_ch = Channel.fromPath(params.input_files)
            .map { file -> [file.baseName, file] }
    }

    // Assemble, polishing and assembly quality control
    if (params.Assembly) {
        FLYE(barcoded_reads_ch)
        read_assembly_ch = FLYE.out.assembly.join(barcoded_reads_ch)
        MEDAKA(read_assembly_ch)
        CHECKM2_DATABASEDOWNLOAD()
        CHECKM2(MEDAKA.out.polished.map { it[1] }.collect(), CHECKM2_DATABASEDOWNLOAD.out.database)
        // BUSCO is not finished yet
        // BUSCO(MEDAKA.out.polished.map { it[1] }.collect())
    }

    // Taxonomic assignment
    if (params.Taxonomy) {
        MMSEQS2_MAKEDB(params.mmseq2_db)
        MMSEQS2_CLASSIFY(MMSEQS2_MAKEDB.out.mmseqs_db, MEDAKA.out.polished)
        GTDB_TK_MAKEDB()
        GTDB_TK(GTDB_TK_MAKEDB.out.db_files, MEDAKA.out.polished.map { it[1] }.collect())
        GTDB_TK(params.path_gtdb_tk_db, MEDAKA.out.polished.map { it[1] }.collect())
    }

    // Run RGI to identify ARGs
    if (params.ARG_Mapping) {
        RGI(MEDAKA.out.polished)
    }

    // Run Diamond (blastX) with whatever db you decide on
    if (params.BLASTX) {
        Channel
            .fromPath(params.databases)
            .map { file -> tuple(file.simpleName, file) }
            .set { databases_ch }

        PRODIGAL(MEDAKA.out.polished)
        DIAMOND_MAKEDB(databases_ch)
        DIAMOND_BLASTP(PRODIGAL.out.coding_regions.combine(DIAMOND_MAKEDB.out.database))
    }

}