version 1.0

workflow metaCaller_MetaCaller {
    
	input {
        File father_bam = "s3://vccri-giannoulatou-lab-clihad-deepvariant/CEPH-trio/bams/NA12891.bam"
        File father_bam_bai = "s3://vccri-giannoulatou-lab-clihad-deepvariant/CEPH-trio/bams/NA12891.bam.bai"
       
        File mother_bam = "s3://vccri-giannoulatou-lab-clihad-deepvariant/CEPH-trio/bams/NA12892.bam"
        File mother_bam_bai = "s3://vccri-giannoulatou-lab-clihad-deepvariant/CEPH-trio/bams/NA12892.bam.bai"
       
        File child_bam = "s3://vccri-giannoulatou-lab-clihad-deepvariant/CEPH-trio/bams/NA12878.bam"
        File child_bam_bai = "s3://vccri-giannoulatou-lab-clihad-deepvariant/CEPH-trio/bams/NA12878.bam.bai"
       
        File reference = "s3://vccri-giannoulatou-lab-clihad-deepvariant/demoref/GRCh38_full_analysis_set_plus_decoy_hla.fa"
        File reference_fai = "s3://vccri-giannoulatou-lab-clihad-deepvariant/demoref/GRCh38_full_analysis_set_plus_decoy_hla.fa.fai"
        File reference_dict = "s3://vccri-giannoulatou-lab-clihad-deepvariant/demoref/GRCh38_full_analysis_set_plus_decoy_hla.dict"
       
        Array[Int] chromosome_ids =  [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
        Array[String] chromosomes = prefix("chr", chromosome_ids)
		
		File gatk_vcf = "s3://anushi-eagle-simulator-data/simulated_data/1000G_CEPH_trio/output/CEPH-trio-gatk4-bp-co_called_filterd.vqsr.DBN_filtered.vcf"
        File gatk_vcf_idx = "s3://anushi-eagle-simulator-data/simulated_data/1000G_CEPH_trio/output/CEPH-trio-gatk4-bp-co_called_filterd.vqsr.DBN_filtered.vcf.idx"
		File ped_file = "s3://anushi-eagle-simulator-data/simulated_data/1000G_CEPH_trio/output/CEPH_trio.ped"
    }

    scatter (chromosome in chromosomes) {
        call samtools_mpileup_VarScan2 {
            input:
                chromosome=chromosome,
                reference=reference,
				reference_fai=reference_fai,
                father_bam=father_bam,
				father_bam_bai=father_bam_bai,
                mother_bam=mother_bam,
				mother_bam_bai=mother_bam_bai,
				child_bam=child_bam,
				child_bam_bai=child_bam_bai
        }
		
		call varscan2_caller {
			input:
				chromosome=chromosome,
				mpileup_file=samtools_mpileup_VarScan2.mpileup_file
		}
		
		call samtools_mpileup_DenovoGear {
            input:
                chromosome=chromosome,
                reference=reference,
				reference_fai=reference_fai,
                father_bam=father_bam,
				father_bam_bai=father_bam_bai,
                mother_bam=mother_bam,
				mother_bam_bai=mother_bam_bai,
				child_bam=child_bam,
				child_bam_bai=child_bam_bai
        }
		
		call DenovoGear_caller {
			input:
				chromosome=chromosome,
				ped_file=ped_file,
				mpileup_file=samtools_mpileup_DenovoGear.mpileup_file
		}
		
    }
	
	call run_triodenovo {
            input:
                gatk_vcf=gatk_vcf,
				gatk_vcf_idx=gatk_vcf_idx,
                ped_file=ped_file
        }
		
	call run_pbt {
            input:
                gatk_vcf=gatk_vcf,
				gatk_vcf_idx=gatk_vcf_idx,
                ped_file=ped_file,
				reference=reference,
				reference_fai=reference_fai,
				reference_dict=reference_dict
        }
	
}


task samtools_mpileup_VarScan2 {
    input {
        String chromosome
        File reference
		File reference_fai
        File father_bam
		File father_bam_bai
        File mother_bam
		File mother_bam_bai
		File child_bam
		File child_bam_bai
    }
    
	runtime {
        docker: "biocontainers/samtools:v1.3.1_cv4"
        memory: "4GB"
        cpu: 2
        disks: "local-disk"
    }
    
	command {
		samtools mpileup \
			-r ${chromosome} \
			-B -q 1 \
			-f ${reference} \
			${father_bam} ${mother_bam} ${child_bam} \
			-o ${chromosome}.varscan2.mpileup.bcf
	}
    
	output {
        File mpileup_file = "${chromosome}.varscan2.mpileup.bcf"
    }
}

task varscan2_caller {
	input {
		String chromosome
		File mpileup_file
	}
	
	runtime {
		docker: "quay.io/biocontainers/varscan:2.4.2--2"
        memory: "4GB"
        cpu: 2
        disks: "local-disk"
	}
	
	
	command {
		varscan trio ${mpileup_file} ${chromosome}_varscan2 \
		--min-coverage 10 \
		--min-var-freq 0.20 \
		--p-value 0.05 \
		-adj-var-freq 0.05 \
		-adj-p-value 0.15
	
	}
	
	output {
		File snp_varscan_file = "${chromosome}_varscan2.snp.vcf"
		File indel_varscan_file = "${chromosome}_varscan2.indel.vcf"
	
	}
	
}

task samtools_mpileup_DenovoGear {
    input {
        String chromosome
        File reference
		File reference_fai
        File father_bam
		File father_bam_bai
        File mother_bam
		File mother_bam_bai
		File child_bam
		File child_bam_bai
    }
    
	runtime {
        docker: "biocontainers/samtools:v1.3.1_cv4"
        memory: "4GB"
        cpu: 2
        disks: "local-disk"
    }
    
	command {
		samtools mpileup \
			-r ${chromosome} \
			-t DP \
			-gf ${reference} \
			${child_bam} ${father_bam} ${mother_bam} \
			-o ${chromosome}.denovogear.mpileup.bcf
	}
    
	output {
        File mpileup_file = "${chromosome}.denovogear.mpileup.bcf"
    }
}

task DenovoGear_caller {
	input {
		String chromosome
		File ped_file
		File mpileup_file
	}
	
	runtime {
		docker: "mictro/vccri-denovogear:1.1.1-290-gce84763"
        memory: "32GB"
        cpu: 2
        disks: "local-disk"
	}
	
	
	command {
		/usr/local/denovo/dng/bin/dng dnm auto --ped ${ped_file} --bcf ${mpileup_file} --write ${chromosome}_dng.vcf > ${chromosome}_dng.out
	
	}
	
	output {
		File dng_vcf = "${chromosome}_dng.vcf"
		File dng_out = "${chromosome}_dng.out"
		
	}
	
}


task run_triodenovo {
    input {
        File gatk_vcf
		File gatk_vcf_idx
		File ped_file
    }
    
	runtime {
        docker: "spashleyfu/ubuntu20_triodenovo:0.0.6"
        memory: "4GB"
        cpu: 2
        disks: "local-disk"
    }
    
	command {
		triodenovo --ped ${ped_file} --in_vcf ${gatk_vcf} --out_vcf GATK_triodenovo.vcf
	}
    
	output {
        File triodenovo_output_vcf_file = "GATK_triodenovo.vcf"
	}
}

task run_pbt {
    input {
        File gatk_vcf
		File gatk_vcf_idx
		File ped_file
		File reference
		File reference_fai
		File reference_dict
    }
    
	runtime {
        docker: "broadinstitute/gatk3:3.8-0"
        memory: "4GB"
        cpu: 2
        disks: "local-disk"
    }
    
	command {
		java -jar /usr/GenomeAnalysisTK.jar -T PhaseByTransmission -R ${reference} -V ${gatk_vcf} -ped ${ped_file} \
		-o CEPH_trio_GATK_PBT.vcf \
		--MendelianViolationsFile CEPH_trio_GATK_PBT_mendel_violations.out
	}
    
	output {
        File pbt_output_vcf_file = "CEPH_trio_GATK_PBT.vcf"
		File mendelViolations_file = "CEPH_trio_GATK_PBT_mendel_violations.out"
	}
}

