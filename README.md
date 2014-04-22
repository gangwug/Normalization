# Normalization
### 0. Setting Up

#####A. Clone the repository
    
    git clone https://github.com/itmat/Normalization.git

#####B. Input Directory Structure
- Give `STUDY` directory a unique name.
- Make sure the alignment outputs(SAM files) are in each sample directory inside the `READS` folder.
- All alignment files (SAM files) MUST have the same name.
<pre>
STUDY
└── READS
    ├── Sample_1
    │   ├── fwd.fq/fa
    │   ├── rev.fq/fa
    │   └── Aligned.sam
    ├── Sample_2
    │   ├── fwd.fq/fa
    │   ├── rev.fq/fa
    │   └── Aligned.sam
    ├── Sample_3
    │   ├── fwd.fq/fa
    │   ├── rev.fq/fa
    │   └── Aligned.sam
    └── Sample_4
    	├── fwd.fq/fa
	├── rev.fq/fa
	└── Aligned.sam															          
</pre>

#####C. Configuration File
Obtain the `template.cfg` file from `Normalization/norm_script/` and modify as you need. Follow the instructions in the config file.

#####D. File of Sample Directories and Unaligned Reads
###### i. File of Sample Directories
Create a file &lt;sample dirs> with the names of the sample directories (without path, sorted by condition).

       e.g. the <sample dirs> file should look like this:
            Sample_1
            Sample_2
            Sample_3
            Sample_4

###### ii. File of Unaligned Reads (Forward only)
Create a file &lt;file of input forward fa/fq files> with full path of input forward fa or forward fq files.

       e.g. the <file of input forward fa/fq files> file should look like this:
            path/to/STUDY/READS/Sample_1/fwd.fq
            path/to/STUDY/READS/Sample_2/fwd.fq
            path/to/STUDY/READS/Sample_3/fwd.fq
            path/to/STUDY/READS/Sample_4/fwd.fq

#####E. Install [sam2cov](https://github.com/khayer/sam2cov/)
This is an optional step. You can use sam2cov to create coverage files and upload them to a Genome Browser. Currently, sam2cov only supports reads aligned with RUM or STAR.

     git clone https://github.com/khayer/sam2cov.git
     cd sam2cov
     make

#####F. Output Directory Structure
You will find all log files and shell scripts in `STUDY/logs` and `STUDY/shell_scripts` directory, respectively. Once you complete the normalization pipeline, your directory structure will look like this (before the Clean Up step):
<pre>
STUDY
│── READS
│   ├── Sample_1
│   │   ├── NU
│   │   └── Unique
│   ├── Sample_2
│   │   ├── NU
│   │   └── Unique
│   ├── Sample_3
│   │   ├── NU
│   │   └── Unique
│   └── Sample_4
│       ├── NU
│       └── Unique
│
│── STATS
│
│── NORMALIZED_DATA
│   ├── exonmappers
│   │    ├── MERGED
│   │    ├── NU
│   │    └── Unique
│   ├── notexonmappers
│   │    ├── MERGED
│   │    ├── NU
│   │    └── Unique
│   ├── FINAL_SAM
│   │    └── MERGED
│   ├── COV
│   │    └── MERGED
│   ├── SPREADSHEETS
│   └── JUNCTIONS
│
│── logs
│
└── shell_scripts
</pre>

### 1. RUN_NORMALIZATION


### 2. NORMALIZATION STEPS
#### 1) Run BLAST

##### A. Mapping Statistics
* **Get total number of reads from input fasta or fastq files**

         perl get_total_num_reads.pl <sample dirs> <loc> <file of input forward fa/fq files> [options]

	 * &lt;sample dirs> : a file with the names of the sample directories
	 * &lt;loc> : full path of the directory with the sample directories (`READS`)
	 * &lt;file of input forward fa/fq files> :  a file with the full path of input forward fa or forward fq files
	 * option : <br>
	  **-fa** : set this if the input files are in fasta format <br>
	  **-fq** : set this if the input files are in fastq format <br>
	  **-gz** : set this if the input files are compressed

 This will output a file called `total_num_reads.txt` to the `STUDY/STATS` directory.

* **Mapping statistics**

         perl runall_sam2mappingstats.pl <sample dirs> <loc> <sam file name> <total_num_reads?> [options]

       * &lt;sample dirs> : a file with the names of the sample directories
       * &lt;loc> : full path of the directory with the sample directories (`READS`)
       * &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
       * &lt;total_num_reads?> : if you have the total_num_reads.txt file, use "true" If not, use "false"
       * option : <br>
         **-lsf** : set this if you want to submit batch jobs to LSF<br>
         **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
	 **-other &lt;submit> &lt;jobname_option> &lt;request_memory_option> &lt;queue_name_for_30G>** : <br>
	 	  set this if you're not on LSF or SGE cluster

  	         &lt;submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)<br>
       		 &lt;jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)<br>
		 &lt;request_memory_option> : is option for requesting resources for batch job submission command (e.g. -q, -l h_vmem=)<br>
		 &lt;queue_name_for_30G> : is queue name for 30G (e.g. max_mem30, 30G)<br>
	 **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 30G)
 
 This will output `*mappingstats.txt` file of all samples to each sample directory. The following script will parse the `*mappingstats.txt` files and output a table with summary info across all samples.

__[NORMALIZATION FACTORS] Mapping stats summary__

     perl getstats.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
      	  
This will output `mappingstats_summary.txt` file to `STUDY/STATS` directory. This file contains the following normalization factors: 

 1. Total number of reads 
 2. Percent mitochondrial 
 3. Percent non-unique mappers 
 4. Percent of forward and reverse reads that overlap

##### B. BLAST

      perl runall_runblast.pl <sample dirs> <loc> <samfile name> <blast dir> <db> [options]

> `runblast.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;samfile name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* &lt;blast dir> : full path of the blast directory

> BLAST is at : `Normalization/norm_scripts/ncbi-blast-2.2.27+/`

* &lt;db> : full path of the database

> ribomouse db is available : `Normalization/norm_scripts/ncbi-blast-2.2.27+/ribomouse`

* option : <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other &lt;submit> &lt;jobname_option> &lt;request_memory_option> &lt;queue_name_for_6G>** : set this if you're not on LSF or SGE clust\
er<br>
          &lt;submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)<br>
          &lt;jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)<br>
          &lt;request_memory_option> : is option for requesting resources for batch job submission command (e.g. -q, -l h_vmem=)<br>
          &lt;queue_name_for_6G> : is queue name for 6G (e.g. plus, 6G)<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)

This outputs `*ribosomalids.txt` of samples to each sample directory (`STUDY/READS/Sample*/`).

__[NORMALIZATION FACTOR] Ribo percents__

     perl runall_get_ribo_percents.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

It assumes there are files of ribosomal ids output from runblast.pl each with suffix "ribosomalids.txt" in each sample directory. This will output `ribosomal_counts.txt` and `ribo_percents.txt` to `READS` directory.

### 2. Run Filter
This step removes all rows from input sam file except those that satisfy all of the following:

  1. Unique mapper / Non-Unique mapper
  2. Both forward and reverse map consistently
  3. id not in the `*ribosomalids.txt` file
  4. Only on a numbered chromosome, X or Y
  5. Is a forward mapper (script outputs forward mappers only)

Run the following command. By default it will return both unique and non-unique mappers.

    perl runall_filter.pl <sample dirs> <loc> <sam file name> [options]

> `filter_sam.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* option:<br>
  **-u** : set this if you want to return only unique mappers<br>
  **-nu** :  set this if you want to return only non-unique mappers<br>
  **-se** :  set this if the data is single end, otherwise by default it will assume it's a paired end data <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This creates directories called `STUDY/READS/Sample*/Unique` and/or `STUDY/READS/Sample*/NU` and outputs `filtered.sam` files of all samples to the directories created. 

### 3. Quantify Exons
##### A. Create Master List of Exons
Get master list of exons from a UCSC gene info file.

    perl get_master_list_of_exons_from_geneinfofile.pl <gene info file> <loc>

* &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name.
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This outputs a file called `master_list_of_exons.txt` to the `READS` directory.

##### B. Get Novel Exons
Create a study-specific master list of exons by adding novel exons from the study to the `master_list_of_exons.txt` file.

* **Make Junctions Files**

 Run the following command with option **-samfilename &lt;sam file name>**.

         perl runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

    * &lt;sample dirs> : a file with the names of the sample directories
    * &lt;loc> : full path of the directory with the sample directories (`READS`)
    * &lt;genes> : gene information file
    * &lt;genome> : genome sequence one-line fasta file
    * option : <br>
      **-samfilename &lt;s>** : set this to create junctions files using unfiltered aligned samfile. &lt;s> is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam) and all sam files in each sample directory should have the same name<br>
      **-u**  :  set this if you want to return only unique junctions files, otherwise by default it will return merged(unique+non-unique) junctions files<br>
      **-nu** :  set this if you want to return only non-unique files, otherwise by default it will return merged(unique+non-unique) junctions files<br>
      **-bsub** : set this if you want to submit batch jobs to LSF<br>
      **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

 This will output `*junctions_hq.bed`, `*junctions_all.bed` and `*junctions_all.rum` to `Sample*/Unique` and `Sample*/NU` directory of all samples.

* **Get Novel Exons**

 This takes `*junctions_all.rum` files as input.

         perl runall_get_novel_exons.pl <sample dirs> <loc> <sam file name> [options]


    * &lt;sample dirs> : a file with the names of the sample directories
    * &lt;loc> : full path of the directory with the sample directories (`READS`)
    * &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
    * options : <br>
     **-min <n>** : size of inferred exon, min is set at 10 by default<br>
     **-max <n>** : size of inferred exon, max is set at 2000 by default

 This outputs `*list_of_novel_exons.txt` file of all samples to each sample directory. It also outputs `master_list_of_exons.*STUDY*.txt` file to `READS` directory.

##### C. [optional step] : Filter Other High Expressors
This is an extra filter step that removes highly expressed exons.

I. Run Quantify exons

Run the following command with **&lt;output sam?> = false**. By default this will return unique exonmappers. Use -NU-only to get non-unique exonmappers:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : `master_list_of_exons.*STUDY*.txt` file
* &lt;output sam?> : false
* option:<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-se** :  set this if the data is single end, otherwise by default it will assume it's a paired end data 

This will output `exonquants` file of all samples to `Unique` and/or `NU` directory in each sample directory.


II. Get High Expressors

    perl runall_get_high_expressors.pl <sample dirs> <loc> <cutoff> <annotation file> <exons> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;cutoff> : cutoff % value 
* &lt;annotation file> : downloaded from UCSC known-gene track including at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease, protein and gene fields from the Linked Tables table

> annotation file for mm9 and hg19 available: `Normalization/norm_scripts/ucsc_known_hg19` and `Normalization/norm_scripts/ucsc_known_hg19`

* &lt;exons> : `master_list_of_exons.*STUDY*.txt` file
* option:<br>
  **-u**  :  set this if you want to return only unique exonpercents, otherwise by default it will return both unique and non-unique exonpercents.<br>
  **-nu** :  set this if you want to return only non-unique exonpercents, otherwise by default it will return both unique and non-unique exonpercents.<br>
  **-bsub** : set this if you want to submit batch jobs to LSF.<br>
  **-qsub** : set this if you want to submit batch jobs to Sun Grid Engine.

This will output `*exonpercents.txt` and `*high_expressors_annot.txt` files of all samples to each sample directory. It will also output `annotated_master_list_of_exons.*STUDY*.txt` to `STUDY/READS` directory.

III. Filter High Expressors

     perl filter_high_expressors.pl <sample dirs> <loc> <exons>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : `master_list_of_exons.*STUDY*.txt` file

This will output a text file called `filtered_master_list_of_exons.*STUDY*.txt` to `STUDY/READS` directory.

__[NORMALIZATION FACTOR] High expressor exonpercent__

     perl get_percent_high_expressor.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

This will output `percent_high_expressor_Unique.txt` and/or `percent_high_expressor_NU.txt` depending on the option provided to `READS` directory.

##### D. Run quantify exons

This step takes filtered sam files and splits them into 1, 2, 3 ... n exonmappers and notexonmappers (n = 20 if you don't use the -depth option).

Run the following command with **&lt;output sam?> = true**. By default this will return unique exonmappers. Use -NU-only to get non-unique exonmappers:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : the `filtered_master_list_of_exons.*STUDY*.txt` (or `master_list_of_exons.*STUDY*.txt` if you skipped step 3B)
* &lt;output sam?> : true
* option:<br>
  **-depth &lt;n>** : by default, it will output 20 exonmappers<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-se** :  set this if the data is single end, otherwise by default it will assume it's a paired end data <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This outputs multiple files of all samples: `exonmappers.(1, 2, 3, 4, ... n).sam`, `notexonmappers.sam`, and `exonquants` file to `Unique` / `NU` directory inside each sample directory. 

__[NORMALIZATION FACTOR] Exon to nonexon signal__

     perl get_exon2nonexon_signal_stats.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

This will output `exon2nonexon_signal_stats_Unique.txt` and/or `exon2nonexon_signal_stats_NU.txt` depending on the option provided to `READS` directory.


__[NORMALIZATION FACTOR] One exon vs multi exons__

    perl get_1exon_vs_multi_exon_stats.pl  <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

This will output `1exon_vs_multi_exon_stats_Unique.txt` and/or `1exon_vs_multi_exon_stats_NU.txt` depending on the option provided to `READS` directory.

### 4. Quantify Introns
##### A. Create Master List of Introns

    perl get_master_list_of_introns_from_geneinfofile.pl <gene info file> <loc>

* &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name.
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This outputs a txt file called `master_list_of_introns.txt` to `READS` directory.

##### B. Run quantify introns

This step takes `notexonmappers.sam` files and splits them into 1, 2, 3 ... n intronmappers and intergenicmappers files (n = 10 if you don't use the -depth option). 

Run the following command with **&lt;output sam?> = true**. By default this will return unique intronmappers. Use -NU-only to get non-unique intronmappers:

    perl runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

> `quantify_introns.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;introns> : the `master_list_of_introns.txt` file (with full path)
* &lt;output sam?> : true
* option : <br>
  **-depth &lt;n>** : by default, it will output 10 intronmappers<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine
 
This outputs multiple files of all samples: `intronmappers.(1, 2, 3, ... n).sam`, `intergenicmappers.sam`, and `intronquants` file to `Unique` / `NU` directory in each sample directory.

__[NORMALIZATION FACTOR] Percent of non-exonic signal that is intergenic (as opposed to intronic)__

    perl get_percent_intergenic.pl  <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

This will output `percent_intergenic_Unique.txt` and/or `percent_intergenic_NU.txt` depending on the option provided to `READS` directory.

### 5. Downsample

##### A. Run head 
This identifies minimum line count of each type of exonmappers/intronmappers/intergenicmappers and downsamples each file by taking the minimum line count of rows from each file.
      
      perl runall_head.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-depthE &lt;n>** : set the exonmapper depth (by default, n = 20). set this to 0 if you only want to return intronmappers and intergenic mappers<br>
  **-depthI &lt;n>** : set the intronmapper depth (by default, n = 10). set this to 0 if you only want to return exonmappers<br>
  **-u** : set this if you want to return only unique mappers, otherwise by default it will return both unique and non-uniqe mappers<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default it will return both unique and non-uniqe mappers<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.

This will output the same number of rows from each file in each `sample_dir/Unique` and/or `sample_dir/NU` directory of the same type.

##### B. Concatenate head files

      perl cat_headfiles.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
  **-u**  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

This will create `STUDY/NORMALIZED_DATA`, `STUDY/NORMALIZED_DATA/exonmappers`, and `STUDY/NORMALIZED_DATA/notexonmappers` directories and output normalized exonmappers, intronmappers and intergenic mappers of all samples to the directories created.

##### C. Merge normalized SAM files

      perl make_final_samfile.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
  **-u**  :  set this if you want to return only unique mappers, otherwise by default
         it will return merged final sam.<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default
         it will return merged final sam.

This will create `FINAL_SAM`. Then, depending on the option given, it will make `FINAL_SAM/Unique`, `FINAL_SAM/NU`, or `FINAL_SAM/MERGED` directory and output final sam files to the directories created. A tag will be added to each sequence indicating its type (XT:A:E for exonmappers, XT:A:I for intronmapper, and XT:A:G for intergenicmappers).

### 6. Run sam2junctions

By default, this will use merged final sam files as input. 
 
    perl runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;genes> :the RUM gene info file 
* &lt;genome> : the RUM genome sequene one-line fasta file 
* option:<br>
  **-u**  :  set this if you want to return only unique junctions files, otherwise by default it will return merged(unique+non-unique) junctions files.<br>
  **-nu** :  set this if you want to return only non-unique files, otherwise by default it will return merged(unique+non-unique) junctions files.<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine
 
This will create `STUDY/NORMALIZED_DATA/Junctions` directory and output `junctions_hq.bed`, `junctions_all.bed` and `junctions_all.rum` files of all samples.

### 7. Master table of features counts
#####A. Get Exonquants 
**a. Concatenate unique and non-unique normalized exonmappers**

If you want to quantify both Unique and Non-unique normalized exonmappers run this. If you're only interested in either Unique or Non-Unique exonmappers, go to step b.:

    perl cat_exonmappers_Unique_NU.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will create `NORMALIZED_DATA/exonmappers/MERGED` directory and output concatenated `exonmappers.norm.sam` file of all samples to the directory created.

**b. Run Quantify exons**

Run the following command with **&lt;output sam?> = false**. This will output merged exonquants by default. If merged exonmappers do not exist, it will output unique exonquants. Use -NU-only to get non-unique exonquants:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : the `filtered_master_list_of_exons.*STUDY*.txt` (or `master_list_of_exons.*STUDY*.txt` file if you skipped step 3B)
* &lt;output sam?> : false
* option:<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-se** :  set this if the data is single end, otherwise by default it will assume it's a paired end data <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine
  			  
This outputs `exonquants` file of all samples to `NORMALIZED_DATA/exonmappers/MERGED` (or `NORMALIZED_DATA/exonmappers/Unique` or `NORMALIZED_DATA/exonmappers/NU`).

#####B. Get Intronquants

Run the following command with **&lt;output sam?> = false**. By default this will return unique intronquants. Use -NU-only to get non-unique intronquants:

    perl runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

> `quantify_introns.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;introns> : the `master_list_of_introns.txt` file 
* &lt;output sam?> : false
* option:<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This outputs `intronquants` file of all samples to `NORMALIZED_DATA/notexonmappers/Unique` or `NORMALIZED_DATA/notexonmappers/NU`.

#####C. Make Final Spreadsheets
**a. Run quants2spreadsheet and juncs2spreadsheet**

     perl make_final_spreadsheets.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
  **-u**  :  set this if you want to return only unique, otherwise by default it will return min and max spreadsheets.<br>
  **-nu** :  set this if you want to return only non-unique, otherwise by default it will return min and max spreadsheets.<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This will output `list_of_exons_counts`, `master_list_of_introns_counts`, and `master_list_of_junctions_counts` files to `STUDY/NORMALIZED_DATA` directory. 

**b. Annotate `list_of_exons_counts`**
     
     perl run_annotate.pl <file of features files> <annotation file> <loc> [options]

> `annotate.pl` available for running one sample at a time

* &lt;file of features files> : a file with the names of the features files to be annotated

       	   e.g. the <file of feature files> file should look like this:
           	 list_of_exons_counts_MIN.txt
	    	 list_of_exons_counts_MAX.txt
	
* &lt;annotation file> : should be downloaded from UCSC known-gene track including at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease, protein and gene fields from the Linked Tables table
> annotation file for mm9 and hg19 available: `Normalization/norm_scripts/ucsc_known_hg19` and `Normalization/norm_scripts/ucsc_known_hg19`
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This will output `master_list_of_exons_counts` to `STUDY/NORMALIZED_DATA`.

**c. Filter low expressors**

     perl runall_filter_low_expressors.pl <file of quants files> <number_of_samples> <cutoff> <loc>

* &lt;file of quants files> : a file with the names of the quants file

         e.g. the <file of quants files> file should look like this:
	      master_list_of_exons_counts_MIN.txt
	      master_list_of_exons_counts_MAX.txt
	      master_list_of_introns_counts_MIN.txt
	      master_list_of_introns_counts_MAX.txt
	      master_list_of_junctions_counts_MIN.txt
	      master_list_of_junctions_counts_MAX.txt

* &lt;number_of_samples> : number of samples
* &lt;cutoff> : cutoff value
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will output `FINAL_master_list_of_exons_counts`, `FINAL_master_list_of_introns_counts`, `FINAL_master_list_of_junctions_counts` to `STUDY/NORMALIZED_DATA`.

###8. Data Visualization

Use sam2cov to create coverage files and upload them to a Genome Browser. Currently, sam2cov only supports reads aligned with RUM or STAR.

#####A. Install [sam2cov](https://github.com/khayer/sam2cov/)

     git clone https://github.com/khayer/sam2cov.git
     cd sam2cov
     make

#####B. Create Coverage Files

     perl runall_sam2cov.pl <sample dirs> <loc> <fai file> <sam2cov> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;fai file> : full path of fai file
* &lt;sam2cov> : full path of sam2cov 
* option : <br>
  **-u** : set this if you want to use only unique mappers to generate coverage files, otherwise by default it will use merged(unique+non-unique) mappers<br>
  **-nu** : set this if you want to use only non-unique mappers to generate coverage files, otherwise by default it will use merged(unique+non-unique) mappers<br>
  **-rum** : set this if you used RUM to align your reads<br>
  **-star** : set this if you used STAR to align your reads<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This will output `*Unique.cov` and `*NU.cov` files of all samples to `STUDY/NORMALIZED_DATA/FINAL_SAM/MERGED` or `STUDY/NORMALIZED_DATA/FINAL_SAM/Unique` or `STUDY/NORMALIZED_DATA/FINAL_SAM/NU`.

###9. Clean Up
#####A. Delete Intermediate SAM Files

     perl cleanup.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)

#####B. Convert SAM to BAM

     perl runall_sam2bam.pl <sample dirs> <loc> <sam file name> <fai file> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;sam file name> : name of the alignment sam file (e.g. RUM.sam, Aligned.out.sam)
* &lt;fai file> : full path of fai file 
* option : <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This will covert SAM to BAM and delete the SAM. 
 