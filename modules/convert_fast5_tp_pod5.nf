process CONV_fast5_POD5 {
    tag "$sample"

    input:
    tuple val(sample), path(signal_files)
    
    output:
    tuple val(sample), path("*.pod5"), emit: pod5
    tuple val(sample), path("${sample}_summary.tsv"), emit: summary
    
    script:
    """
    # If input is fast5
    # First convert to pod5
    if [[ "${signal_files}" == *.fast5 ]]; then
        pod5 convert fast5 ${signal_files}  --output . 
        mv output.pod5 ${sample}.pod5
       # pod5 view ${sample}.pod5 --include "read_id, channel" --output ${sample}_summary.tsv
       # pod5 subset ${sample}.pod5 --summary ${sample}_summary.tsv --columns channel --output split_by_channel
    fi

   # If input is pod5
   if [[ "${signal_files}" == *.pod5 ]]; then
       pod5 view ${sample}.pod5 --include "read_id, channel" --output ${sample}_summary.tsv
       pod5 subset ${sample}.pod5 --summary ${sample}_summary.tsv --columns channel --output split_by_channel
   fi

    # Rename demultiplexed files
    for file in split_by_channel/*.pod5; do
        channel=\$(basename \$file | cut -d'-' -f2 | cut -d'.' -f1)
        mv \$file ${sample}-\${channel}.pod5
    done
#
    rm -r split_by_channel

    """
}


