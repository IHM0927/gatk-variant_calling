version 1.0

workflow ApplyVQSR {

  input {
    File input_vcf
    File input_vcf_index
    File reference
    File reference_index
    File reference_dict

    File snp_recal
    File snp_recal_index
    File snp_tranches
    File indel_recal
    File indel_recal_index
    File indel_tranches

    Float snp_filter_level   = 99.0
    Float indel_filter_level = 99.0

    Int memory_gb = 32
    Int disk_gb = 200
    Int cpu = 4
    Int preemptible = 1
  }

  call RunApplyVQSR_SNP {
    input:
      input_vcf        = input_vcf,
      input_vcf_index  = input_vcf_index,
      reference        = reference,
      reference_index  = reference_index,
      reference_dict   = reference_dict,
      snp_recal        = snp_recal,
      snp_recal_index  = snp_recal_index,
      snp_tranches     = snp_tranches,
      filter_level     = snp_filter_level,
      memory_gb        = memory_gb,
      disk_gb          = disk_gb,
      cpu              = cpu,
      preemptible      = preemptible
  }

  call RunApplyVQSR_INDEL {
    input:
      input_vcf          = RunApplyVQSR_SNP.output_vcf,
      input_vcf_index    = RunApplyVQSR_SNP.output_vcf_index,
      reference          = reference,
      reference_index    = reference_index,
      reference_dict     = reference_dict,
      indel_recal        = indel_recal,
      indel_recal_index  = indel_recal_index,
      indel_tranches     = indel_tranches,
      filter_level       = indel_filter_level,
      memory_gb          = memory_gb,
      disk_gb            = disk_gb,
      cpu                = cpu,
      preemptible        = preemptible
  }

  output {
    File vqsr_vcf       = RunApplyVQSR_INDEL.output_vcf
    File vqsr_vcf_index = RunApplyVQSR_INDEL.output_vcf_index
  }
}

task RunApplyVQSR_SNP {

  input {
    File input_vcf
    File input_vcf_index
    File reference
    File reference_index
    File reference_dict
    File snp_recal
    File snp_recal_index
    File snp_tranches
    Float filter_level

    Int memory_gb
    Int disk_gb
    Int cpu
    Int preemptible
  }

  command <<<
    set -euo pipefail

    gatk ApplyVQSR \
      --reference ~{reference} \
      --variant ~{input_vcf} \
      --output output_SNP_filtered.vcf.gz \
      --truth-sensitivity-filter-level ~{filter_level} \
      --tranches-file ~{snp_tranches} \
      --recal-file ~{snp_recal} \
      -mode SNP
  >>>

  runtime {
    docker:      "broadinstitute/gatk:4.6.2.0"
    memory:      "~{memory_gb} GB"
    disks:       "local-disk ~{disk_gb} HDD"
    cpu:         cpu
    preemptible: preemptible
  }

  output {
    File output_vcf       = "output_SNP_filtered.vcf.gz"
    File output_vcf_index = "output_SNP_filtered.vcf.gz.tbi"
  }
}

task RunApplyVQSR_INDEL {

  input {
    File input_vcf
    File input_vcf_index
    File reference
    File reference_index
    File reference_dict
    File indel_recal
    File indel_recal_index
    File indel_tranches
    Float filter_level

    Int memory_gb
    Int disk_gb
    Int cpu
    Int preemptible
  }

  command <<<
    set -euo pipefail

    gatk ApplyVQSR \
      --reference ~{reference} \
      --variant ~{input_vcf} \
      --output output_INDEL_filtered.vcf.gz \
      --truth-sensitivity-filter-level ~{filter_level} \
      --tranches-file ~{indel_tranches} \
      --recal-file ~{indel_recal} \
      -mode INDEL
  >>>

  runtime {
    docker:      "broadinstitute/gatk:4.6.2.0"
    memory:      "~{memory_gb} GB"
    disks:       "local-disk ~{disk_gb} HDD"
    cpu:         cpu
    preemptible: preemptible
  }

  output {
    File output_vcf       = "output_INDEL_filtered.vcf.gz"
    File output_vcf_index = "output_INDEL_filtered.vcf.gz.tbi"
  }
}
