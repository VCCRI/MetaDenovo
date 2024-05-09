workflow PhasebytransmissionPipeline {
	File gatk_vcf
	File ped_file
	File snpSiftJar
	File reference
	File reference_fai
	File reference_dict
	
 	
        ## Call RunPhasebytranmission task to run Phasebytranmission callers.
		call RunPhasebytranmission {
            input:
                gatk_vcf=gatk_vcf,
				ped_file=ped_file,
				reference=reference,
				reference_fai=reference_fai,
				reference_dict=reference_dict
        }	

		## Call MendelViolationsListDNMs task to generate list of de novo mutations with Mendelian Violations.
		call MendelViolationsListDNMs {
            input:
			Mendel_Violations_file=RunPhasebytranmission.mendelViolations_file
		}
		
		## Call AnnotatePBTVcf task to annotate variant type in VCF file.
##		call AnnotatePBTVcf1a {
##				input:
##				PBT_vcf=RunPhasebytranmission.pbt_output_vcf_file
##			}

		call AnnotatePBTVcf1 {
				input:
				snpSiftJar=snpSiftJar,
				PBT_vcf=RunPhasebytranmission.pbt_output_vcf_file
			}
		
		## Call FilterDNMGenotypePattern task to filter variants with genotype pattern of de novo mutation from VCF file.
		
##		call FilterDNMGenotypePattern1a {
##				input:
##				PBT_output_file_annotated=AnnotatePBTVcf1.PBT_output_file_annotated
##			}
##			
		call FilterDNMGenotypePattern1 {
				input:
				snpSiftJar=snpSiftJar,
				PBT_output_file_annotated=AnnotatePBTVcf1.PBT_output_file_annotated
			}
			
		## Call RunBgzip task to bgzip and index VCF file.
		call RunBgzip {
				input:
				input_vcf=FilterDNMGenotypePattern1.PBT_GenoType_Filtered
			}
			
		## Call FilterMendelViolationsPBTVcf task to filter variants with mendelian violations from VCF file.
		call FilterMendelViolationsPBTVcf {
			input:
			input_mendel_violations=MendelViolationsListDNMs.PBT_DNMs_list_Mendel_Violations,
			input_vcf=RunBgzip.bgzip_output_file,
			input_index_vcf=RunBgzip.bgzip_index_file
		}
		
		## Call ListOfDNMs to generate list of de novo mutations.
		call ListOfDNMs {
				input:
				input_vcf=FilterMendelViolationsPBTVcf.PBT_Variant_Annotated_Mendel_Violations
			}
			
	output {
		File pbt_output_vcf_file = RunPhasebytranmission.pbt_output_vcf_file
		File mendelViolations_file = RunPhasebytranmission.mendelViolations_file
		File PBT_DNMs_list_Mendel_Violations = MendelViolationsListDNMs.PBT_DNMs_list_Mendel_Violations
		File PBT_output_file_annotated = AnnotatePBTVcf1.PBT_output_file_annotated
		File PBT_GenoType_Filtered = FilterDNMGenotypePattern1.PBT_GenoType_Filtered
		File bgzip_output_file = RunBgzip.bgzip_output_file
		File bgzip_index_file = RunBgzip.bgzip_index_file
		File PBT_Variant_Annotated_Mendel_Violations = FilterMendelViolationsPBTVcf.PBT_Variant_Annotated_Mendel_Violations
		File PBT_listof_dnSNPs_file = ListOfDNMs.PBT_listof_dnSNPs_file
		File PBT_listof_dnINDELs_file = ListOfDNMs.PBT_listof_dnINDELs_file
	}

}

## Run Phasebytranmission caller. 
## It takes VCF file, pedigree file and reference files as input.

task RunPhasebytranmission {
		File gatk_vcf
		File ped_file
		File reference
		File reference_fai
		File reference_dict
    
	runtime {
        docker: "broadinstitute/gatk3:3.8-0"
        memory: "4GB"
        cpu: 2
        disks: "local-disk"
    }
    
	command {
		java -jar /usr/GenomeAnalysisTK.jar -T PhaseByTransmission -R ${reference} -V ${gatk_vcf} -ped ${ped_file} \
		-o GATK_PBT.vcf \
		--MendelianViolationsFile GATK_PBT_mendel_violations.out
	}
    
	output {
        File pbt_output_vcf_file = "GATK_PBT.vcf"
		File mendelViolations_file = "GATK_PBT_mendel_violations.out"
	}
}

## Filters out variants with ChrX, ChrY and ChrM from Mendel Violations file generated by Phasebytranmission caller.
## Then generates list of variants (de novo mutations) with chromosome and position in tab delimited format.

task MendelViolationsListDNMs {
        File Mendel_Violations_file
	
    command {
		grep -v "chrM\|chrX\|chrY" ${Mendel_Violations_file} | grep "^chr" | cut -f1,2 | sort | uniq > PBT_chr_1_22_DNMs_list_Mendel_Violations_tab_delimited.txt
    }
 
    runtime {
        docker: "ubuntu:18.04"
        memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
   
    output {
        File PBT_DNMs_list_Mendel_Violations = "PBT_chr_1_22_DNMs_list_Mendel_Violations_tab_delimited.txt"
	}
}

## The VCF file generated by Phasebytranmission caller is annotated for variant type. 

task AnnotatePBTVcf1a {
        File PBT_vcf
 
    runtime {
        docker: "stephenturner/snpsift:latest"
        memory: "4GB"
        cpu: 1
        disks: "local-disk"
    }
	
    command {
        java -jar /snpEff/SnpSift.jar -h
    }
   
##   output {
##        File PBT_output_file_annotated = "PBT_output_file_annotated.vcf"
##	}
}

## Filter variants with de novo mutation genotype pattern (Child = 0/1, father = 0/0, mother = 0/0)
## Here 0/1 = heterozygous alternate and 0/0 = homozygous reference.

task FilterDNMGenotypePattern1a {
        File PBT_output_file_annotated
 
    runtime {
        docker: "stephenturner/snpsift:latest"
        memory: "4GB"
        cpu: 1
        disks: "local-disk"
    }
   
    command {
        java -jar /snpEff/SnpSift.jar filter "( GEN[0].GT == '0/1' ) & ( GEN[1].GT == '0/0' ) & ( GEN[2].GT == '0/0' )" ${PBT_output_file_annotated} > PBT_GenoType_Filtered.vcf
    }
 
    output {
        File PBT_GenoType_Filtered = "PBT_GenoType_Filtered.vcf"
	}
}

## The VCF file generated by Phasebytranmission caller is annotated for variant type. 

task AnnotatePBTVcf1 {
    	File snpSiftJar
        File PBT_vcf
	
    command {
        java -jar ${snpSiftJar} varType ${PBT_vcf} > PBT_output_file_annotated.vcf
    }
 
    runtime {
##        docker: "openjdk:11.0-jdk"
        docker: "stephenturner/snpsift:latest"
        memory: "4GB"
        cpu: 1
        disks: "local-disk"
    }
   
    output {
        File PBT_output_file_annotated = "PBT_output_file_annotated.vcf"
	}
}

## Filter variants with de novo mutation genotype pattern (Child = 0/1, father = 0/0, mother = 0/0)
## Here 0/1 = heterozygous alternate and 0/0 = homozygous reference.

task FilterDNMGenotypePattern1 {
    	File snpSiftJar
        File PBT_output_file_annotated
	
    command {
        java -jar ${snpSiftJar} filter "( GEN[0].GT == '0/1' ) & ( GEN[1].GT == '0/0' ) & ( GEN[2].GT == '0/0' )" ${PBT_output_file_annotated} > PBT_GenoType_Filtered.vcf
    }
 
    runtime {
        docker: "openjdk:11.0-jdk"
        memory: "4GB"
        cpu: 1
        disks: "local-disk"
    }
   
    output {
        File PBT_GenoType_Filtered = "PBT_GenoType_Filtered.vcf"
	}
}

## Run bgzip and tabix to compress and index VCF file.

task RunBgzip {
    	File input_vcf
	
    command {
        bgzip -c ${input_vcf} > PBT_GenoType_Filtered.vcf.gz ; tabix PBT_GenoType_Filtered.vcf.gz
	}
 
    runtime {
        docker: "quay.io/biocontainers/bcftools:1.10.2--hd2cd319_0"
        memory: "2GB"
        cpu: 1
        disks: "local-disk"
		
    }
   
    output {
        File bgzip_output_file = "PBT_GenoType_Filtered.vcf.gz"
		File bgzip_index_file = "PBT_GenoType_Filtered.vcf.gz.tbi"
	}
}

## Select Mendelian Violations variants from VCF file.
## It takes list of Mendelian Violations variants generated in MendelViolationsListDNMs task.

task FilterMendelViolationsPBTVcf {
    	File input_mendel_violations
		File input_vcf
		File input_index_vcf
	
    command {
        bcftools view -T ${input_mendel_violations} ${input_vcf} -O v -o PBT_Variant_Annotated_Mendel_Violations.vcf
	}
 
    runtime {
        docker: "quay.io/biocontainers/bcftools:1.10.2--hd2cd319_0"
        memory: "2GB"
        cpu: 1
        disks: "local-disk"
		
    }
   
    output {
        File PBT_Variant_Annotated_Mendel_Violations = "PBT_Variant_Annotated_Mendel_Violations.vcf"
	}
}

## Lists of de novo mutations with chromosome and position are generated for snps, indels and both.

task ListOfDNMs {
    	File input_vcf
	
	command {
		grep "VARTYPE=SNP\|VARTYPE=INS\|VARTYPE=DEL" ${input_vcf} | cut -f1,2 | sed 's/\t/|/g' | sort | uniq > PBT_listof_allDNMs_file.txt | \
	
		grep "VARTYPE=SNP" ${input_vcf} | cut -f1,2 | sed 's/\t/|/g' | sort | uniq > PBT_listof_dnSNPs_file.txt | \
		
		grep "VARTYPE=INS\|VARTYPE=DEL" ${input_vcf} | cut -f1,2 | sed 's/\t/|/g' | sort | uniq > PBT_listof_dnINDELs_file.txt
	}
  
	runtime {
        docker: "ubuntu:18.04"
		memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
	
	output {
		File PBT_listof_dnSNPs_file = "PBT_listof_dnSNPs_file.txt"
		File PBT_listof_dnINDELs_file = "PBT_listof_dnINDELs_file.txt"
    }
}

