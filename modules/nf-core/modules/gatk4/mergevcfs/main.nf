process GATK4_MERGEVCFS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::gatk4=4.2.6.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.6.1--hdfd78af_0':
        'quay.io/biocontainers/gatk4:4.2.6.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(vcf)
    path  dict

    output:
    tuple val(meta), path('*.vcf.gz'), emit: vcf
    path  "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_list = vcf.collect{ "--INPUT $it"}.join(' ')
    def reference_command = dict ? "--SEQUENCE_DICTIONARY $dict" : ""

    def avail_mem = 3
    if (!task.memory) {
        log.info '[GATK MergeVcfs] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.giga * 0.8).intValue()
    }
    """
    gatk --java-options "-Xmx${avail_mem}g" MergeVcfs \\
        $input_list \\
        --OUTPUT ${prefix}.vcf.gz \\
        $reference_command \\
        --TMP_DIR . \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
