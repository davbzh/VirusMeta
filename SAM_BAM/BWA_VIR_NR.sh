#!/bin/bash

#########################################################################################
#  BWA_NR
#  Copyright (c) 22/08/2013 Davit Bzhalava
##########################################################################################
#
#    Alligns row anassembled pairend sequences to quey fasta and estimates 
#    number reads alligned to each sequence in fasta file
#
#    ./BWA_NR.sh '/home/gsflx/HTSA/MySeq/test/aggregated_fasta/NR' 'aggegated_assembly_cdhit' 'preassembly1.fastq' preassembly2.fastq'
############################################################################################

##########################################################################################
#   prepare files
##########################################################################################
if [ -d $1 ]; then
   rm -r $1
fi

mkdir $1
export work_fasta=$(basename $2)

cp $2 $1/$work_fasta #copy query fasta in the working directory

##########################################################################################
#   perform BWA-MEM allignment and analyse the allignment
##########################################################################################
cd $1
/usr/local/bin/bwa index $work_fasta
/usr/local/bin/samtools faidx $work_fasta

/usr/local/bin/bwa mem $work_fasta $3 $4 -t 70 > aln-pe.sam

/usr/local/bin/samtools view -@ 70 -b -S aln-pe.sam > aln-pe.bam
/usr/local/bin/samtools sort -@ 70 aln-pe.bam aln-pe.sorted
/usr/local/bin/samtools view -@ 70 aln-pe.sorted.bam  | cut -f1,2,3,4,8,5,9 > $work_fasta.txt

#This is necessary for genomeview
#samtools sort aln-pe.bam aln-pe.sorted
#samtools index aln-pe.sorted.bam
###


scl enable python27 - << \EOF
#python /media/storage/HTS/VirusMeta/SAM_BAM/run_parallel_pysam.py --input_file=aln-pe.bam --query_fasta=$work_fasta  --result_file=$work_fasta.txt --jobs 70 --temp_directory=tmp
python /media/storage/HTS/VirusMeta/SAM_BAM/translate_pysam.py $work_fasta.txt  sam_final_$work_fasta.txt unmapped_$work_fasta.txt nr_ref_$work_fasta.txt
EOF

/usr/local/bin/samtools depth  aln-pe.sorted.bam > position_coverage.txt

#remove temporary directory
#rm -r tmp  
#remove working fasta
#rm $work_fasta*
rm *.sam
rm *.bam
