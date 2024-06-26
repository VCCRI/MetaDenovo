import "PhasebytransmissionPipeline.wdl" as PBT_p
import "TrioDenovoPipeline.wdl" as TrioDenovo_p
import "VarScan2Pipeline.wdl" as VarScan2_p
import "DenovoGearPipeline.wdl" as DenovoGear_p
import "ConsensusDNMs.wdl" as consensusDNM_p

workflow MetaDenovo_workflow {
	 
	  File mother_bam
	  File mother_bam_bai
	  File father_bam
	  File father_bam_bai
	  File child_bam
	  File child_bam_bai
	  Array[Int] chromosome_ids
	  File reference
	  File reference_fai
	  File reference_dict
	  File ped_file
	  File gatk_vcf
	  File python_file
	  File selectDNMGenotype_program
	  
	  ## Call workflow of Phasebytransmission caller
		call PBT_p.PhasebytransmissionPipeline as PBT_p {
			input:
			gatk_vcf=gatk_vcf,
			ped_file=ped_file,
##			snpSiftJar=snpSiftJar,
			reference=reference,
			reference_fai=reference_fai,
			reference_dict=reference_dict
		}
	
		
		## Call workflow of TrioDenovo caller
		call TrioDenovo_p.TrioDenovoPipeline as TrioDenovo_p {
			input:
			gatk_vcf=gatk_vcf,
			ped_file=ped_file,
##			snpSiftJar=snpSiftJar,
			selectDNMGenotype_program=selectDNMGenotype_program
		}
		
		
		## Call workflow of DenovoGear caller
		call DenovoGear_p.DenovoGearPipeline as DenovoGear_p {
		input:
		chromosome_ids=chromosome_ids,
		reference=reference,
		reference_fai=reference_fai,
		reference_dict=reference_dict,
        father_bam=father_bam,
		father_bam_bai=father_bam_bai,
        mother_bam=mother_bam,
		mother_bam_bai=mother_bam_bai,
		child_bam=child_bam,
		child_bam_bai=child_bam_bai,
		python_file=python_file,
		ped_file=ped_file
	}
	
	## Call workflow of VarScan2 caller
		call VarScan2_p.VarScan2Pipeline as VarScan2_p {
		input:
##		snpSiftJar=snpSiftJar,
		chromosome_ids=chromosome_ids,
		reference=reference,
		reference_fai=reference_fai,
		reference_dict=reference_dict,
        father_bam=father_bam,
		father_bam_bai=father_bam_bai,
        mother_bam=mother_bam,
		mother_bam_bai=mother_bam_bai,
		child_bam=child_bam,
		child_bam_bai=child_bam_bai
	}
	
	## Call callConsensusDNMs to generate output files for consensus of de novo SNPs using four, three, two and one callers.
	call consensusDNM_p.callConsensusDNMs as consensusDNM_snv {
		input:
		variant_type = "SNP",
		PBT_file = PBT_p.PBT_listof_dnSNPs_file,
		TrioDenovo_file = TrioDenovo_p.TrioDenovo_list_of_snps_output,
		varScan2_file = VarScan2_p.VarScan2_list_of_snps_output,
		DenovoGear_file = DenovoGear_p.DenovoGear_list_of_snps_output
	}
	
	## Call callConsensusDNMs to generate output files for consensus of de novo INDELs using four, three, two and one callers.
	call consensusDNM_p.callConsensusDNMs as consensusDNM_indel {
		input:
		variant_type = "INDEL",
		PBT_file = PBT_p.PBT_listof_dnINDELs_file,
		TrioDenovo_file = TrioDenovo_p.TrioDenovo_list_of_indels_output,
		varScan2_file = VarScan2_p.VarScan2_list_of_indels_output,
		DenovoGear_file = DenovoGear_p.DenovoGear_list_of_indels_output
	}
	
	## Output files generated by the MetaDenovo workflow.
	output {
		File pbt_output_vcf_file = PBT_p.pbt_output_vcf_file
		File mendelViolations_file = PBT_p.mendelViolations_file
		File PBT_DNMs_list_Mendel_Violations = PBT_p.PBT_DNMs_list_Mendel_Violations
		File PBT_output_file_annotated = PBT_p.PBT_output_file_annotated
		File PBT_GenoType_Filtered = PBT_p.PBT_GenoType_Filtered
		File bgzip_output_file = PBT_p.bgzip_output_file
		File bgzip_index_file = PBT_p.bgzip_index_file
		File PBT_Variant_Annotated_Mendel_Violations = PBT_p.PBT_Variant_Annotated_Mendel_Violations
		File PBT_listof_dnSNPs_file = PBT_p.PBT_listof_dnSNPs_file
		File PBT_listof_dnINDELs_file = PBT_p.PBT_listof_dnINDELs_file
		File triodenovo_output_vcf_file = TrioDenovo_p.triodenovo_output_vcf_file
		File Triodenovo_output_DQ_datatype = TrioDenovo_p.Triodenovo_output_DQ_datatype
		File Triodenovo_chr1_22_vcf = TrioDenovo_p.Triodenovo_chr1_22_vcf
		File Triodenovo_output_file_annotated = TrioDenovo_p.Triodenovo_output_file_annotated
		File Triodenovo_selected_dnSNV = TrioDenovo_p.Triodenovo_selected_dnSNV
		File TrioDenovo_listof_allDNMs_file = TrioDenovo_p.TrioDenovo_listof_allDNMs_file
		File TrioDenovo_list_of_snps_output = TrioDenovo_p.TrioDenovo_list_of_snps_output
		File TrioDenovo_list_of_indels_output = TrioDenovo_p.TrioDenovo_list_of_indels_output
		File CombinedDNGOutput = DenovoGear_p.CombinedDNGOutput
		File DenovoGear_NumericGenotype_output = DenovoGear_p.DenovoGear_NumericGenotype_output
		File DenovoGear_DNM_Genotype_output = DenovoGear_p.DenovoGear_DNM_Genotype_output
		File DenovoGear_snp_file = DenovoGear_p.DenovoGear_snp_file
		File DenovoGear_indel_file = DenovoGear_p.DenovoGear_indel_file
		File DenovoGear_DNMs_file_output = DenovoGear_p.DenovoGear_DNMs_file_output
		File DenovoGear_list_of_snps_output = DenovoGear_p.DenovoGear_list_of_snps_output
		File DenovoGear_list_of_indels_output = DenovoGear_p.DenovoGear_list_of_indels_output
		File VarScan2_snp_combined = VarScan2_p.VarScan2_snp_combined
		File VarScan2_indel_combined = VarScan2_p.VarScan2_indel_combined
		File VarScan2_snp_DNMs_file = VarScan2_p.VarScan2_snp_DNMs_file 
		File VarScan2_indel_DNMs_file = VarScan2_p.VarScan2_indel_DNMs_file
		File VarScan2_list_of_snps_output = VarScan2_p.VarScan2_list_of_snps_output
		File VarScan2_list_of_indels_output = VarScan2_p.VarScan2_list_of_indels_output
		Array[File] consensus_output_snp_files = consensusDNM_snv.output_text_files
		Array[File] consensus_output_indel_files = consensusDNM_indel.output_text_files
	}
   
}

