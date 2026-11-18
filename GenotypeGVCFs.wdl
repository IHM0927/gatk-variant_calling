version 1.0

workflow GenotypeGVCFs {

  input {
    File genomicsdb_tar
    File reference
    File reference_index
    File reference_dict
    File dbsnp
    File dbsnp_index
    Array[File] interval_lists
    String output_prefix = "output"

    Int memory_gb = 32
    Int disk_gb = 200
    Int cpu = 4
    Int preemptible = 1
  }

  scatter (interval in interval_lists) {
    call RunGenotypeGVCFs {
      input:
        genomicsdb_tar  = genomicsdb_tar,
        reference       = reference,
        reference_index = reference_index,
        reference_dict  = reference_dict,
        dbsnp           = dbsnp,
        dbsnp_index     = dbsnp_index,
        interval        = interval,
        output_prefix   = output_prefix,
        memory_gb       = memory_gb,
        disk_gb         = disk_gb,
        cpu             = cpu,
        preemptible     = preemptible
    }
  }

  output {
    Array[File] genotyped_vcfs       = RunGenotypeGVCFs.genotyped_vcf
    Array[File] genotyped_vcf_index  = RunGenotypeGVCFs.genotyped_vcf_index
  }
}

task RunGenotypeGVCFs {

  input {
    File genomicsdb_tar
    File reference
    File reference_index
    File reference_dict
    File dbsnp
    File dbsnp_index
    File interval
    String output_prefix

    Int memory_gb
    Int disk_gb
    Int cpu
    Int preemptible
  }

  String interval_name = basename(interval, ".interval_list")
  String output_vcf    = "~{output_prefix}_~{interval_name}.vcf.gz"

  command <<<
    set -euo pipefail

    # genomicsdb tar 풀기
    tar -xzf ~{genomicsdb_tar}
    DB_NAME=$(tar -tzf ~{genomicsdb_tar} | head -1 | cut -f1 -d"/")

    gatk --java-options "-Xmx20g -Xms20g \
      -XX:+UseG1GC -XX:G1HeapRegionSize=32m \
      -XX:ParallelGCThreads=3 \
      -XX:MaxDirectMemorySize=1g" \
      GenotypeGVCFs \
      --reference ~{reference} \
      --variant gendb://$DB_NAME \
      --output ~{output_vcf} \
      --intervals ~{interval} \
      --dbsnp ~{dbsnp} \
      --genomicsdb-shared-posixfs-optimizations true \
      --tmp-dir /tmp
  >>>

  runtime {
    docker:      "broadinstitute/gatk:4.6.2.0"
    memory:      "~{memory_gb} GB"
    disks:       "local-disk ~{disk_gb} HDD"
    cpu:         cpu
    preemptible: preemptible
  }

  output {
    File genotyped_vcf       = output_vcf
    File genotyped_vcf_index = "~{output_vcf}.tbi"
  }
}
