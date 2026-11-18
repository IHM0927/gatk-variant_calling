version 1.0

workflow GenomicsDBImport {

  input {
    Array[File] input_gvcfs
    Array[File] input_gvcfs_index
    Array[File] interval_lists
    String genomicsdb_workspace = "genomicsdb_workspace"

    Int memory_gb = 100
    Int disk_gb = 500
    Int cpu = 20
    Int preemptible = 0
  }

  call RunGenomicsDBImport {
    input:
      input_gvcfs           = input_gvcfs,
      input_gvcfs_index     = input_gvcfs_index,
      interval_lists        = interval_lists,
      genomicsdb_workspace  = genomicsdb_workspace,
      memory_gb             = memory_gb,
      disk_gb               = disk_gb,
      cpu                   = cpu,
      preemptible           = preemptible
  }

  output {
    File genomicsdb_tar = RunGenomicsDBImport.genomicsdb_tar
  }
}

task RunGenomicsDBImport {

  input {
    Array[File] input_gvcfs
    Array[File] input_gvcfs_index
    Array[File] interval_lists
    String genomicsdb_workspace

    Int memory_gb
    Int disk_gb
    Int cpu
    Int preemptible
  }

  command <<<
    set -euo pipefail

    # interval_list 파일들을 -L 인자로 변환
    INTERVAL_ARGS=$(for f in ~{sep=' ' interval_lists}; do echo "-L $f"; done | tr '\n' ' ')

    gatk --java-options "-Xmx80g -Xms20g" GenomicsDBImport \
      ~{sep=' ' prefix("-V ", input_gvcfs)} \
      --genomicsdb-workspace-path ~{genomicsdb_workspace} \
      $INTERVAL_ARGS \
      --batch-size 50 \
      --reader-threads ~{cpu} \
      --max-num-intervals-to-import-in-parallel 10 \
      --tmp-dir /tmp

    # Terra는 디렉토리를 output으로 못 받으므로 tar로 묶기
    tar -czf ~{genomicsdb_workspace}.tar.gz ~{genomicsdb_workspace}
  >>>

  runtime {
    docker:      "broadinstitute/gatk:4.6.2.0"
    memory:      "~{memory_gb} GB"
    disks:       "local-disk ~{disk_gb} HDD"
    cpu:         cpu
    preemptible: preemptible
  }

  output {
    File genomicsdb_tar = "~{genomicsdb_workspace}.tar.gz"
  }
}
