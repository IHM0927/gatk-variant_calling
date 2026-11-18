version 1.0

workflow HaplotypeCaller_Male {

  input {
    Array[File] input_cram
    Array[File] input_cram_index
    File reference
    File reference_index
    File reference_dict
    File dbsnp
    File dbsnp_index
    File ploidy_regions
    String sample_name
    String output_gvcf = "~{sample_name}.applyRecalibration.g.vcf.gz"

    Int memory_gb = 32
    Int disk_gb = 200
    Int cpu = 4
    Int preemptible = 1
  }

  call RunHaplotypeCaller_Male {
    input:
      input_cram       = input_cram,
      input_cram_index = input_cram_index,
      reference        = reference,
      reference_index  = reference_index,
      reference_dict   = reference_dict,
      dbsnp            = dbsnp,
      dbsnp_index      = dbsnp_index,
      ploidy_regions   = ploidy_regions,
      output_gvcf      = output_gvcf,
      memory_gb        = memory_gb,
      disk_gb          = disk_gb,
      cpu              = cpu,
      preemptible      = preemptible
  }

  output {
    File gvcf       = RunHaplotypeCaller_Male.gvcf
    File gvcf_index = RunHaplotypeCaller_Male.gvcf_index
  }
}

task RunHaplotypeCaller_Male {

  input {
    Array[File] input_cram
    Array[File] input_cram_index
    File reference
    File reference_index
    File reference_dict
    File dbsnp
    File dbsnp_index
    File ploidy_regions
    String output_gvcf

    Int memory_gb
    Int disk_gb
    Int cpu
    Int preemptible
  }

  command <<<
    set -euo pipefail

    gatk HaplotypeCaller \
      --input ~{sep=' --input ' input_cram} \
      --reference ~{reference} \
      --dbsnp ~{dbsnp} \
      --output ~{output_gvcf} \
      --annotate-with-num-discovered-alleles true \
      --ploidy-regions ~{ploidy_regions} \
      -ERC GVCF \
      -L chrX \
      -L chrY
  >>>

  runtime {
    docker:      "broadinstitute/gatk:4.6.2.0"
    memory:      "~{memory_gb} GB"
    disks:       "local-disk ~{disk_gb} HDD"
    cpu:         cpu
    preemptible: preemptible
  }

  output {
    File gvcf       = output_gvcf
    File gvcf_index = "~{output_gvcf}.tbi"
  }
}
