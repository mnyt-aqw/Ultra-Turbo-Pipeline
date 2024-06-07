process ONT_FAST5_API {
    tag "$sample"
    
    input:
    tuple val(sample), path(read_files)

    output:
    path "*fasta.gz", emit: demultiplexed_fast5
    path "barcoding_summary.txt", emit: barcode_summary

    script:
    """
    demux_fast5 \
    --input ${read_files} \
    --save_path ./ \
    --summary_file barcoding_summary.txt \
    --threads ${task.cpus} \
    --compression gzip \
    ${params.ONT_FAST5_API}

        # Rename fast5 files based on parent directory name
    for dir in */; do
        if [ -d "\$dir" ]; then
            barcode=\$(basename "\$dir")
            for file in "\$dir"/*.fast5; do
                if [ -f "\$file" ]; then
                    new_name="\${file%.*}_\${barcode#barcode}.fast5"
                    mv "\$file" "\$new_name"
                fi
            done
        fi
    done
    
    """
}