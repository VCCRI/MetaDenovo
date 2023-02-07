import "PhasebytransmissionPipeline.wdl" as PBT_p
import "TrioDenovoPipeline.wdl" as TrioDenovo_p
import "VarScan2Pipeline.wdl" as VarScan2_p
import "DenovoGearPipeline.wdl" as DenovoGear_p
import "ConsensusDNMs.wdl" as consensusDNM_p

workflow MetaDenovo_workflow {
	 
	  File mother_bam = "path-of-mother-bam-file"
	  File mother_bam_bai = "path-of-mother-bam-index-file"
  
	  File father_bam = "path-of-father-bam-file"
	  File father_bam_bai = "path-of-father-bam-index-file"

	  File child_bam = "path-of-child-bam-file"
	  File child_bam_bai = "path-of-child-bam-index-file"
	  
	  Array[Int] chromosome_ids = [20,21,22]
	  ##Array[Int] chromosome_ids = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
	  
	  File reference = "path-of-reference-file"
	  File reference_fai = "path-of-reference-index-file"
	  File reference_dict = "path-of-reference-dictionary-file"
	  
	  File ped_file = "path-of-pedigree-file"
	  File gatk_vcf = path-of-VCF-file
	  File snpSiftJar = "s3://anushi-eagle-simulator-data/softwares/snpEff/SnpSift.jar"
	  File python_file = "s3://vccri-gwfcore-mictro/MetaDenovo/DenovoGear_numeric_genotype.py"
	  File Consensus_DNM_script = "s3://vccri-gwfcore-mictro/MetaDenovo/MetaDenovoConsensusDNMs.sh"
	  
	 
	## Call workflow of Phasebytransmission caller
	call PBT_p.PhasebytransmissionPipeline as PBT_p {
		input:
		gatk_vcf=gatk_vcf,
		#gatk_vcf_idx=gatk_vcf_idx,
        ped_file=ped_file,
		reference=reference,
		reference_fai=reference_fai,
		reference_dict=reference_dict,
		snpSiftJar=snpSiftJar
	}
	
	## Call workflow of TrioDenovo caller
	call TrioDenovo_p.TrioDenovoPipeline as TrioDenovo_p {
		input:
		gatk_vcf=gatk_vcf,
		#gatk_vcf_idx=gatk_vcf_idx,
        ped_file=ped_file,
		snpSiftJar=snpSiftJar
	}
	
	## Call workflow of VarScan2 caller
	call VarScan2_p.VarScan2Pipeline as VarScan2_p {
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
		snpSiftJar=snpSiftJar
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
	
	## Call callConsensusDNMs to generate output files for consensus of de novo SNPs using four, three, two and one callers.
	call consensusDNM_p.callConsensusDNMs as consensusDNM_snv {
		input:
		variant_type = "SNP",
		Consensus_DNM_script = Consensus_DNM_script,
		PBT_file = PBT_p.PBT_listof_dnSNPs_file,
		TrioDenovo_file = TrioDenovo_p.TrioDenovo_list_of_snps_output,
		varScan2_file = VarScan2_p.VarScan2_list_of_snps_output,
		DenovoGear_file = DenovoGear_p.DenovoGear_list_of_snps_output
	}
	
	## Call callConsensusDNMs to generate output files for consensus of de novo INDELs using four, three, two and one callers.
	call consensusDNM_p.callConsensusDNMs as consensusDNM_indel {
		input:
		variant_type = "INDEL",
		Consensus_DNM_script = Consensus_DNM_script,
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
		File TrioDenovo_listof_allDNMs_file = TrioDenovo_p.TrioDenovo_listof_allDNMs_file
		File TrioDenovo_list_of_snps_output = TrioDenovo_p.TrioDenovo_list_of_snps_output
		File TrioDenovo_list_of_indels_output = TrioDenovo_p.TrioDenovo_list_of_indels_output
		File VarScan2_snp_combined = VarScan2_p.VarScan2_snp_combined
		File VarScan2_indel_combined = VarScan2_p.VarScan2_indel_combined
		File VarScan2_snp_DNMs_file = VarScan2_p.VarScan2_snp_DNMs_file 
		File VarScan2_indel_DNMs_file = VarScan2_p.VarScan2_indel_DNMs_file
		File VarScan2_list_of_snps_output = VarScan2_p.VarScan2_list_of_snps_output
		File VarScan2_list_of_indels_output = VarScan2_p.VarScan2_list_of_indels_output
		File CombinedDNGOutput = DenovoGear_p.CombinedDNGOutput
		File DenovoGear_NumericGenotype_output = DenovoGear_p.DenovoGear_NumericGenotype_output
		File DenovoGear_DNM_Genotype_output = DenovoGear_p.DenovoGear_DNM_Genotype_output
		File DenovoGear_snp_file = DenovoGear_p.DenovoGear_snp_file
		File DenovoGear_indel_file = DenovoGear_p.DenovoGear_indel_file
		File DenovoGear_DNMs_file_output = DenovoGear_p.DenovoGear_DNMs_file_output
		File DenovoGear_list_of_snps_output = DenovoGear_p.DenovoGear_list_of_snps_output
		File DenovoGear_list_of_indels_output = DenovoGear_p.DenovoGear_list_of_indels_output
		File MetaDenovo_three_callers_SNP = "MetaDenovo_three_callers_SNP.txt"
		File MetaDenovo_two_callers_SNP = "MetaDenovo_two_callers_SNP.txt"
		File MetaDenovo_one_callers_SNP = "MetaDenovo_one_callers_SNP.txt"
		File MetaDenovo_four_callers_INDEL = "MetaDenovo_four_callers_INDEL.txt"
		File MetaDenovo_three_callers_INDEL = "MetaDenovo_three_callers_INDEL.txt"
		File MetaDenovo_two_callers_INDEL = "MetaDenovo_two_callers_INDEL.txt"
		File MetaDenovo_one_callers_INDEL = "MetaDenovo_one_callers_INDEL.txt"
	}
   
}
