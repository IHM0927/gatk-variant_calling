version 1.0

workflow VariantRecalibrator {

  input {
    File input_vcf
    File input_vcf_index
    File reference
    File reference_index
    File reference_dict

    # SNP resources
    File hapmap
    File hapmap_index
    File omni
    File omni_index
    File snp_1000g
    File snp_1000g_index
    File dbsnp
    File dbsnp_index

    # INDEL resources
    File mills
    File mills_index

    Int memory_gb = 32
    Int disk_gb = 200
    Int cpu = 4
    Int preemptible = 1
  }

  call RunVariantRecalibrator_SNP {
    input:
      input_vcf       = input_vcf,
      input_vcf_index = input_vcf_index,
      reference       = reference,
      reference_index = reference_index,
      reference_dict  = reference_dict,
      hapmap          = hapmap,
      hapmap_index    = hapmap_index,
      omni            = omni,
      omni_index      = omni_index,
      snp_1000g       = snp_1000g,
      snp_1000g_index = snp_1000g_index,
      dbsnp           = dbsnp,
      dbsnp_index     = dbsnp_index,
      memory_gb       = memory_gb,
      disk_gb         = disk_gb,
      cpu             = cpu,
      preemptible     = preemptible
  }

  call RunVariantRecalibrator_INDEL {
    input:
      input_vcf       = input_vcf,
      input_vcf_index = input_vcf_index,
      reference       = reference,
      reference_index = reference_index,
      reference_dict  = reference_dict,
      dbsnp           = dbsnp,
      dbsnp_index     = dbsnp_index,
      mills           = mills,
      mills_index     = mills_index,
      memory_gb       = memory_gb,
      disk_gb         = disk_gb,
      cpu             = cpu,
      preemptible     = preemptible
  }

  output {
    File snp_recal    = RunVariantRecalibrator_SNP.recal
    File snp_tranches = RunVariantRecalibrator_SNP.tranches
    File indel_recal    = RunVariantRecalibrator_INDEL.recal
    File indel_tranches = RunVariantRecalibrator_INDEL.tranches
  }
}

task RunVariantRecalibrator_SNP {

  input {
    File input_vcf
    File input_vcf_index
    File reference
    File reference_index
    File reference_dict
    File hapmap
    File hapmap_index
    File omni
    File omni_index
    File snp_1000g
    File snp_1000g_index
    File dbsnp
    File dbsnp_index

    Int memory_gb
    Int disk_gb
    Int cpu
    Int preemptible
  }

  command <<<
    set -euo pipefail

    gatk VariantRecalibrator \
      --reference ~{reference} \
      --variant ~{input_vcf} \
      --resource:hapmap,known=false,training=true,truth=true,prior=15.0 ~{hapmap} \
      --resource:omni,known=false,training=true,truth=false,prior=12.0 ~{omni} \
      --resource:1000G,known=false,training=true,truth=false,prior=10.0 ~{snp_1000g} \
      --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ~{dbsnp} \
      -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff \
      -mode SNP \
      --output output_SNP.recal \
      --tranches-file output_SNP.tranches
  >>>

  runtime {
    docker:      "broadinstitute/gatk:4.6.2.0"
    memory:      "~{memory_gb} GB"
    disks:       "local-disk ~{disk_gb} HDD"
    cpu:         cpu
    preemptible: preemptible
  }

  output {
    File recal   = "output_SNP.recal"
    File tranches = "output_SNP.tranches"
  }
}

task RunVariantRecalibrator_INDEL {

  input {
    File input_vcf
    File input_vcf_index
    File reference
    File reference_index
    File reference_dict
    File dbsnp
    File dbsnp_index
    File mills
    File mills_index

    Int memory_gb
    Int disk_gb
    Int cpu
    Int preemptible
  }

  command <<<
    set -euo pipefail

    gatk VariantRecalibrator \
      --reference ~{reference} \
      --variant ~{input_vcf} \
      --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ~{dbsnp} \
      --resource:mills,known=true,training=true,truth=true,prior=12.0 ~{mills} \
      -an QD -an DP -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff \
      -mode INDEL \
      --output output_INDEL.recal \
      --tranches-file output_INDEL.tranches
  >>>

  runtime {
    docker:      "broadinstitute/gatk:4.6.2.0"
    memory:      "~{memory_gb} GB"
    disks:       "local-disk ~{disk_gb} HDD"
    cpu:         cpu
    preemptible: preemptible
  }

  output {
    File recal    = "output_INDEL.recal"
    File tranches = "output_INDEL.tranches"
  }
}
