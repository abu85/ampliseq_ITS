#!/bin/bash
#SBATCH -A naiss2024-22-116
#SBATCH -p core -n 2
#SBATCH -t 24:00:00
#SBATCH -J subsample_v2
#SBATCH --mail-user=abu.siddique@slu.se
#SBATCH --mail-type=ALL

module load bioinfo-tools

echo "sybsampling job started at $(date)"

INPUT_DIR="/proj/uppstore2018171/abu/tanasp/P22702/01-Ampliseq-Analysis/input/"
OUTPUT_DIR="/proj/uppstore2018171/abu/tanasp/P22702/01-Ampliseq-Analysis/subsampled_v2/"
READS=68017

mkdir -p $OUTPUT_DIR

for file in $INPUT_DIR/*_R1_001.fastq.gz; do
    base=$(basename $file _R1_001.fastq.gz)
    r1_file=$file
    r2_file=${INPUT_DIR}/${base}_R2_001.fastq.gz

    if [ -f $r2_file ]; then
        total_reads=$(zcat $r1_file | echo $((`wc -l`/4)))
        if [ $total_reads -ge $READS ]; then
            seqtk sample -s100 $r1_file $READS > ${OUTPUT_DIR}/${base}_R1_001.fastq.gz
            seqtk sample -s100 $r2_file $READS > ${OUTPUT_DIR}/${base}_R2_001.fastq.gz
            echo "Subsampled $r1_file and $r2_file to ${READS} reads each."
        else
            echo "Skipped $base as it has fewer than $READS reads."
        fi
    else
        echo "Paired file for $r1_file not found. Skipping."
    fi
done

echo "sybsampling job finished at $(date)"


## this file was located in cat /home/abusiddi/SLUBI/scripts/subsample_v2.sh 
