import "DenovoGearPostProcessing.wdl" as DenovoGear_post

workflow DenovoGearPipeline {
	File father_bam
    File father_bam_bai
    File mother_bam
    File mother_bam_bai
    File child_bam
    File child_bam_bai
    File reference
    File reference_fai
    File reference_dict
    Array[Int] chromosome_ids
    Array[String] chromosomes = prefix("chr", chromosome_ids)
    File ped_file  
	File python_file
	  
	#Array[Int] chromosome_ids = [20,21,22]
	#Array[Int] chromosome_ids = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
	#Array[String] chromosomes = prefix("chr", chromosome_ids)
	  
	#File reference = "s3://vccri-giannoulatou-lab-clihad-deepvariant/demoref/GRCh38_full_analysis_set_plus_decoy_hla.fa"
	#File reference_fai = "s3://vccri-giannoulatou-lab-clihad-deepvariant/demoref/GRCh38_full_analysis_set_plus_decoy_hla.fa.fai"
	#File reference_dict = "s3://vccri-giannoulatou-lab-clihad-deepvariant/demoref/GRCh38_full_analysis_set_plus_decoy_hla.dict"
	  
	#File ped_file = "s3://vccri-giannoulatou-lab-denovo-mutations/simulated_data/1000G_CEPH_trio/output/TrioDenovo_GATK/CEPH_trio.ped"
	
#	File python_file = "s3://vccri-giannoulatou-lab-denovo-mutations/MetaDenovo/DenovoGear_numeric_genotype.py"
	  
	## Call samtools mpileup and DenovoGear caller tasks per chromosome as scatter parallelism.
	
    scatter (chromosome in chromosomes) {
      ## Call samtools mpileup task to generate bcf mpileup 
		call SamtoolsMpileup {
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
		
		## Call DenovoGear for each chromosome.
		call DenovoGearCaller {
			input:
				chromosome=chromosome,
				ped_file=ped_file,
				mpileup_file=SamtoolsMpileup.mpileup_file
		}
		
    }
	
	## Call CombineDenovoGearOutput task which combines all the output files from DenovoGear.
	call DenovoGear_post.CombineDenovoGearOutput as CombineDenovoGearOutput { 
		input: 
		DNGOutputFiles=DenovoGearCaller.dng_out 
	}

	## Call NumericGenotype to binarize genotype values of variants.
	call DenovoGear_post.NumericGenotype as NumericGenotype {
            input:
			python_file=python_file,
			DNG_file=CombineDenovoGearOutput.CombinedDNGOutput
    }
	
	## Call SelectDNMGenotype to select/filter variants with de novo mutation genotype.
	call DenovoGear_post.SelectDNMGenotype as SelectDNMGenotype {
			input:
			Numeric_Genotype_input=NumericGenotype.DenovoGear_NumericGenotype_output
	}
	
	## Call SplitSnpIndel to separate files from SNP and INDELs.
	call DenovoGear_post.SplitSnpIndel as SplitSnpIndel {
            input:
			Combined_DNG_Numeric_Genotype_file=SelectDNMGenotype.DenovoGear_DNM_Genotype_output
	}
	
	## Call ListOfDNMs to generate list of de novo mutations.
	call DenovoGear_post.ListOfDNMs as ListOfDNMs {
            input:
			DenovoGear_DNMs_file=SelectDNMGenotype.DenovoGear_DNM_Genotype_output,
			DenovoGear_snp_file=SplitSnpIndel.DenovoGear_snp_file,
			DenovoGear_indel_file=SplitSnpIndel.DenovoGear_indel_file
	}
	
	output {
		File CombinedDNGOutput = CombineDenovoGearOutput.CombinedDNGOutput
		File DenovoGear_NumericGenotype_output = NumericGenotype.DenovoGear_NumericGenotype_output
		File DenovoGear_DNM_Genotype_output = SelectDNMGenotype.DenovoGear_DNM_Genotype_output
		File DenovoGear_snp_file = SplitSnpIndel.DenovoGear_snp_file
		File DenovoGear_indel_file = SplitSnpIndel.DenovoGear_indel_file
		File DenovoGear_DNMs_file_output = ListOfDNMs.DenovoGear_DNMs_file_output
		File DenovoGear_list_of_snps_output = ListOfDNMs.DenovoGear_list_of_snps_output
		File DenovoGear_list_of_indels_output = ListOfDNMs.DenovoGear_list_of_indels_output
	
	}
	
	
}

## This is the pre-processing step required for DenovoGear caller.
## mpileup files are generated by samtools command. It is run for each chromosome.
## The task requires trio BAM files, reference files and chromosome name.
## Output bcf mpileup file is generated for each chromosome.

task SamtoolsMpileup {
        String chromosome
        File reference
		File reference_fai
        File father_bam
		File father_bam_bai
        File mother_bam
		File mother_bam_bai
		File child_bam
		File child_bam_bai
    
	runtime {
        docker: "biocontainers/samtools:v1.3.1_cv4"
        memory: "8GB"
        cpu: 2
        disks: "local-disk"
		maxRetries: 3
    }
    
	command {
		samtools mpileup \
			-r ${chromosome} \
			-t DP \
			-gf ${reference} \
			${child_bam} ${father_bam} ${mother_bam} \
			-o ${chromosome}.mpileup.bcf
	}
    
	output {
        File mpileup_file = "${chromosome}.mpileup.bcf"
    }
}

## This task runs DenovoGear caller per chromosome.
## It takes bcf mpileup generated from SamtoolsMpileup task and chromosome name.
## It generates VCF file for snp and indels separately for each chromosome.

task DenovoGearCaller {
		String chromosome
		File ped_file
		File mpileup_file
	
	runtime {
		docker: "mictro/vccri-denovogear:1.1.1-290-gce84763"
        memory: "32GB"
        cpu: 2
        disks: "local-disk"
		maxRetries: 3
	}
	
	
	command {
		/usr/local/denovo/dng/bin/dng dnm auto --ped ${ped_file} --bcf ${mpileup_file} --write ${chromosome}_dng.vcf > ${chromosome}_dng.out
	
	}
	
	output {
		File dng_vcf = "${chromosome}_dng.vcf"
		File dng_out = "${chromosome}_dng.out"
		
	}
	
}


