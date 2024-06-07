import groovy.json.JsonSlurper

process CHECKM2_DATABASEDOWNLOAD{
    tag "Single process"
    
    output:
    path"checkm2_db_v${db_version}.dmnd", emit: database

    script:
    zenodo_id = 5571251
    def jsonSlurper = new JsonSlurper()
    db_version = jsonSlurper.parseText(file("https://zenodo.org/api/records/${zenodo_id}").text).metadata.version
    """
    # Automatic download is broken when using singularity/apptainer (https://github.com/chklovski/CheckM2/issues/73)
    # So we download the database manually
    wget https://zenodo.org/records/${zenodo_id}/files/checkm2_database.tar.gz

    tar -xzf checkm2_database.tar.gz
    db_path=\$(find -name *.dmnd)
    MD5=\$(grep -o '\\.dmnd": "[^"]*"' CONTENTS.json | cut -d '"' -f 3)

    md5sum -c <<< "\$MD5  \$db_path"
    mv \$db_path checkm2_db_v${db_version}.dmnd
    """

}