process PYCOQC {
    tag "$summary"

    input:
    path summary

    output:
    path "summary.html", emit: html
    path "summary.json", emit: json

    script:
    """
    pycoQC \\
        -f ${summary} \\
        -o summary.html \\
        -j summary.json
    """
}