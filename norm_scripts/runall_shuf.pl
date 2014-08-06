#!/usr/bin/env perl

$USAGE =  "\nUsage: perl runall_shuf.pl <sample_dirs> <loc> [options]

where
<sample_dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the dir with the sample dirs

will output the same number of rows from each file in <loc>/<dirs>/Unique
of the same type. (ditto for NU)

The output file names will be modified from the input file names.

** If the maximum line count in `STUDY/READS/linecounts*txt` is > 50,000,000, use -mem option (6G for 60 million lines, 7G for 70 million lines, 8G for 80 million lines, etc).

option:  
 -u  :  set this if you want to return only unique mappers, otherwise by default it will return both unique and non-unique mappers

 -nu  :  set this if you want to return only non-unique mappers, otherwise by default it will return both unique and non-unique mappers

 -depthE <n> : This is the number of exonmappers file used for normalization.
               By default, <n> = 20.

 -depthI <n> : This is the number of intronmappers file used for normalization.
               By default, <n> = 10. 

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command  (e.g. -q, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. plus, 6G)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -h : print usage

";
if (@ARGV <2){
    die $USAGE;
}

$U = 'true';
$NU = 'true';
$numargs_u_nu = 0;
$i_exon = 20;
$i_intron = 10;
$njobs = 200;
$replace_mem = "false";
$submit = "";
$request_memory_option = "";
$mem = "";
$jobname_option = "";
$numargs = 0;
for ($i=2; $i<@ARGV; $i++){
    $option_found = "false";
    $option_u_nu = "false";
    if ($ARGV[$i] eq '-max_jobs'){
	$option_found = "true";
	$njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-u'){
	$NU = "false";
	$option_found = "true";
	$option_u_nu = "true";
	$numargs_u_nu++;
    }
    if ($ARGV[$i] eq '-nu'){
	$U = "false";
	$option_found = "true";
	$option_u_nu = "true";
	$numargs_u_nu++;
    }
    if ($ARGV[$i] eq '-depthE'){
	$i_exon = $ARGV[$i+1];
	if ($i_exon !~ /(\d+$)/ ){
	    die "-depthE <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-depthI'){
	$i_intron = $ARGV[$i+1];
	if ($i_intron !~ /(\d+$)/ ){
	    die "-depthI <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
	$status = "bjobs";
	$request_memory_option = "-q";
	$mem = "plus";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
	$jobname_option = "-N";
	$status = "qstat";
	$request_memory_option = "-l h_vmem=";
	$mem = "6G";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs++;
        $option_found = "true";
	$argv_all = $ARGV[$i+1];
        @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $request_memory_option = $a[2];
        $mem = $a[3];
        $status = $a[4];
	$i++;
        if ($submit =~ /^-/ | $submit eq "" | $jobname_option eq "" | $status eq "" | $request_memory_option eq "" | $mem eq ""){
            die "please provide \"<submit>, <jobname_option>, <request_memory_option> ,<queue_name_for_6G>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
	    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option> ,<queue_name_for_6G>,<status>\".\n";
        }
    }
    if ($ARGV[$i] eq '-mem'){
        $option_found = "true";
        $new_mem = $ARGV[$i+1];
        $replace_mem = "true";
        $i++;
        if ($new_mem eq ""){
            die "please provide a queue name.\n";
        }
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>\".\n";
}
if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

if ($replace_mem eq "true"){
    $mem = $new_mem;
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/runall_shuf.pl//;

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study = $fields[@fields-2];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}
%LINECOUNTS;

if ($option_u_nu eq 'false'){
    #EXON
    $exonuniques = "false";
    $exonnu = "false";
    $warnUE = "";
    $warnNUE = "";
    for($i=1; $i<=$i_exon; $i++) {
	open(INFILE, $ARGV[0]);  # file of dirs
	$minEU[$i] = 1000000000000;
	$minENU[$i] = 1000000000000;
	while($dirname = <INFILE>) {
	    chomp($dirname);
	    $id = $dirname;
	    if(-e "$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam") {
		$N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam`;
		$exonuniques = "true";
	    } else {
		die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
#	    $warnUE = $warnUE . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    $LINECOUNTS{"EU.$id.$i"} = $N;
	    if($N < $minEU[$i]) {
		$minEU[$i] = $N;
	    }
	    if(-e "$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam") {
		$N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam`;
		$exonnu = "true";
	    } else {
		die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
#	     $warnNUE = $warnNUE . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    $LINECOUNTS{"ENU.$id.$i"} = $N;
	    if($N < $minENU[$i]) {
		$minENU[$i] = $N;
	    }
	}
	close(INFILE);
#    print "minEU[$i] = $minEU[$i]\n";
#    print "minENU[$i] = $minENU[$i]\n";
    }
    if($exonuniques eq 'true' && $warnUE =~ /\S/) {
	die "$warnUE\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
    }
    if($exonnu eq 'true' && $warnNUE =~ /\S/) {
	die "$warnNUE\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
    }
#INTRON
    if ($i_intron ne '0'){
	$intronuniques = "false";
	$intronnu = "false";
	$warnUI = "";
	$warnNUI = "";
	for($i=1; $i<=$i_intron; $i++) {
	    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";  # file of dirs
	    $minIU[$i] = 1000000000000;
	    $minINU[$i] = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		if(-e "$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam`;
		    $intronuniques = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
#	    $warnUI = $warnUI . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		$LINECOUNTS{"IU.$id.$i"} = $N;
		if($N < $minIU[$i]) {
		    $minIU[$i] = $N;
		}
		if(-e "$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam`;
		    $intronnu = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
#	    $warnNUI = $warnNUI . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		$LINECOUNTS{"INU.$id.$i"} = $N;
		if($N < $minINU[$i]) {
		    $minINU[$i] = $N;
		}
	    }
	    close(INFILE);
#    print "minIU[$i] = $minIU[$i]\n";
#    print "minINU[$i] = $minINU[$i]\n";
	}
	if($intronuniques eq 'true' && $warnUI =~ /\S/) {
	    die "$warnUI\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
	if($intronnu eq 'true' && $warnNUI =~ /\S/) {
	    die "$warnNUI\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
	
	#INTERGENIC
	$iguniques = "false";
	$ignu = "false";
	$warnUIG = "";
	$warnNUIG = "";
	open(INFILE, $ARGV[0]);  # file of dirs
	$minIGU = 1000000000000;
	$minIGNU = 1000000000000;
	while($dirname = <INFILE>) {
	    chomp($dirname);
	    $id = $dirname;
	    if(-e "$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam") {
		$N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam`;
		$iguniques = "true";
	    } else {
		die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
#	$warnUIG = $warnUIG . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    $LINECOUNTS{"IGU.$id"} = $N;
	    if($N < $minIGU) {
		$minIGU = $N;
	    }
	    if(-e "$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam") {
		$N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam`;
		$ignu = "true";
	    } else {
		die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
#	$warnNUIG = $warnNUIG . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    $LINECOUNTS{"IGNU.$id"} = $N;
	    if($N < $minIGNU) {
		$minIGNU = $N;
	    }
	}
	close(INFILE);
#print "minIGU = $minIGU\n";
#print "minIGNU = $minIGNU\n";
	if($iguniques eq 'true' && $warnUIG =~ /\S/) {
	die "$warnUIG\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
	if($ignu eq 'true' && $warnNUIG =~ /\S/) {
	    die "$warnNUIG\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
    }
}
else{
    if ($U eq 'true'){
	#EXON
	$exonuniques = "false";
	$warnUE = "";
	for($i=1; $i<=$i_exon; $i++) {
	    open(INFILE, $ARGV[0]);  # file of dirs
	    $minEU[$i] = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		if(-e "$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam`;
		    $exonuniques = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
#	    $warnUE = $warnUE . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		$LINECOUNTS{"EU.$id.$i"} = $N;
		if($N < $minEU[$i]) {
		    $minEU[$i] = $N;
		}
	    }
	    close(INFILE);
	}
	if($exonuniques eq 'true' && $warnUE =~ /\S/) {
	    die "$warnUE\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}

	if ($i_intron ne '0'){
	#INTRON
	    $intronuniques = "false";
	    $warnUI = "";
	    for($i=1; $i<=$i_intron; $i++) {
		open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";  # file of dirs
		$minIU[$i] = 1000000000000;
		while($dirname = <INFILE>) {
		    chomp($dirname);
		    $id = $dirname;
		    if(-e "$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam") {
			$N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam`;
			$intronuniques = "true";
		    } else {
			die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
#	    $warnUI = $warnUI . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
		    }
		    if($N !~ /line count/) {
			die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    $LINECOUNTS{"IU.$id.$i"} = $N;
		    if($N < $minIU[$i]) {
			$minIU[$i] = $N;
		    }
		}
		close(INFILE);
#    print "minIU[$i] = $minIU[$i]\n";
#    print "minINU[$i] = $minINU[$i]\n";
	    }
	    if($intronuniques eq 'true' && $warnUI =~ /\S/) {
		die "$warnUI\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	    }
	    
	    #INTERGENIC
	    $iguniques = "false";
	    $warnUIG = "";
	    open(INFILE, $ARGV[0]);  # file of dirs
	    $minIGU = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		if(-e "$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam") {
		    $N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam`;
		$iguniques = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
#	$warnUIG = $warnUIG . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		$LINECOUNTS{"IGU.$id"} = $N;
		if($N < $minIGU) {
		    $minIGU = $N;
		}
	    }
	    close(INFILE);
	    if($iguniques eq 'true' && $warnUIG =~ /\S/) {
		die "$warnUIG\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	    }
	}
    }
    if ($NU eq 'true'){
	#EXON
	$exonnu = "false";
	$warnNUE = "";
	for($i=1; $i<=$i_exon; $i++) {
	    open(INFILE, $ARGV[0]);  # file of dirs
	    $minENU[$i] = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		if(-e "$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam`;
		    $exonnu = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
#	     $warnNUE = $warnNUE . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		$LINECOUNTS{"ENU.$id.$i"} = $N;
		if($N < $minENU[$i]) {
		    $minENU[$i] = $N;
		}
	    }
	close(INFILE);
#    print "minEU[$i] = $minEU[$i]\n";
#    print "minENU[$i] = $minENU[$i]\n";
	}
	if($exonnu eq 'true' && $warnNUE =~ /\S/) {
	    die "$warnNUE\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
	
	if ($i_intron ne '0'){
#INTRON
	    $intronnu = "false";
	    $warnNUI = "";
	    for($i=1; $i<=$i_intron; $i++) {
		open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";  # file of dirs
		$minINU[$i] = 1000000000000;
		while($dirname = <INFILE>) {
		    chomp($dirname);
		    $id = $dirname;
		    if(-e "$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam") {
			$N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam`;
			$intronnu = "true";
		    } else {
			die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
#	    $warnNUI = $warnNUI . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
		    }
		    if($N !~ /line count/) {
			die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    $LINECOUNTS{"INU.$id.$i"} = $N;
		    if($N < $minINU[$i]) {
			$minINU[$i] = $N;
		    }
		}
		close(INFILE);
#    print "minIU[$i] = $minIU[$i]\n";
#    print "minINU[$i] = $minINU[$i]\n";
	    }
	    if($intronnu eq 'true' && $warnNUI =~ /\S/) {
		die "$warnNUI\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	    }
	    
	    #INTERGENIC
	    $ignu = "false";
	    $warnNUIG = "";
	    open(INFILE, $ARGV[0]);  # file of dirs
	    $minIGNU = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		if(-e "$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam") {
		    $N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam`;
		    $ignu = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
#	$warnNUIG = $warnNUIG . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		$LINECOUNTS{"IGNU.$id"} = $N;
		if($N < $minIGNU) {
		    $minIGNU = $N;
		}
	    }
	    close(INFILE);
#print "minIGU = $minIGU\n";
#print "minIGNU = $minIGNU\n";
	    if($ignu eq 'true' && $warnNUIG =~ /\S/) {
		die "$warnNUIG\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	    }
	}
    }
}

##run shuf

for($i=1; $i<=$i_exon; $i++) {
    open(INFILE, $ARGV[0]);
    while($dirname = <INFILE>) {
	chomp($dirname);
	$id = $dirname;
	$for_lc = "EU.$id.$i";
	$total_lc = $LINECOUNTS{$for_lc};
	$numU = $minEU[$i];
	$numNU = $minENU[$i];
	$filenameU = "$id.filtered_u_exonmappers.$i.sam";
	$outfileU = $filenameU;
	$outfileU =~ s/.sam/_shuf_$numU.sam/;
	$filenameNU = "$id.filtered_nu_exonmappers.$i.sam";
	$outfileNU = $filenameNU;
	$outfileNU =~ s/.sam/_shuf_$numNU.sam/;
	$dirU = $dirname . "/Unique";
	$dirNU = $dirname . "/NU";
	$shfileU[$i] = "$shdir/a" . $id . "exonmappers.u_runshuf.$i.sh";
	$shfileNU[$i] = "$shdir/a" . $id . "exonmappers.nu_runshuf.$i.sh";
	$jobname = "$study.shuf";
	$lognameU[$i] = "$logdir/exonmappers.$id.u_shuf.$i";
	$lognameNU[$i] = "$logdir/exonmappers.$id.nu_shuf.$i";
	if($exonuniques eq 'true') {
	    if (($total_lc ne '0') && ($numU ne '0')){
		open(OUTFILEU, ">$shfileU[$i]");
		print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/$filenameU $total_lc $numU > $LOC/$dirU/$outfileU\n";
		print OUTFILEU "echo \"got here\"\n";
		close(OUTFILEU);
		while(qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU[$i].out -e $lognameU[$i].err < $shfileU[$i]`;
	    }
	}
	if($exonnu eq 'true') {
	    $for_lc =~ s/EU/ENU/g;
	    $total_lc = $LINECOUNTS{$for_lc};
	    if (($total_lc ne '0') && ($numNU ne '0')){
		open(OUTFILENU, ">$shfileNU[$i]");
		print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/$filenameNU $total_lc $numNU > $LOC/$dirNU/$outfileNU\n";
		print OUTFILENU "echo \"got here\"\n";;
		close(OUTFILENU);
		while(qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU[$i].out -e $lognameNU[$i].err < $shfileNU[$i]`;
	    }
	}
    }
}
close(INFILE);

#intronmappers
for($i=1; $i<=$i_intron; $i++) {
    open(INFILE, $ARGV[0]);
    while($dirname = <INFILE>) {
	chomp($dirname);
	$id = $dirname;
	$for_lc = "IU.$id.$i";
	$total_lc = $LINECOUNTS{$for_lc};
	$numU = $minIU[$i];
	$numNU = $minINU[$i];
	$filenameU = "$id.filtered_u_notexonmappers_intronmappers.$i.sam";
	$outfileU = $filenameU;
	$outfileU =~ s/.sam/_shuf_$numU.sam/;
	$filenameNU = "$id.filtered_nu_notexonmappers_intronmappers.$i.sam";
	$outfileNU = $filenameNU;
	$outfileNU =~ s/.sam/_shuf_$numNU.sam/;
	$dirU = $dirname . "/Unique";
	$dirNU = $dirname . "/NU";
	$shfileU[$i] = "$shdir/a" . $id . "intronmappers.u_runshuf.$i.sh";
	$shfileNU[$i] = "$shdir/a" . $id . "intronmappers.nu_runshuf.$i.sh";
	$jobname = "$study.shuf";
	$lognameU[$i] = "$logdir/intronmappers.$id.u_shuf.$i";
	$lognameNU[$i] = "$logdir/intronmappers.$id.nu_shuf.$i";
	if($intronuniques eq 'true') {
            if (($total_lc ne '0') && ($numU ne '0')){
		open(OUTFILEU, ">$shfileU[$i]");
		print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/$filenameU $total_lc $numU > $LOC/$dirU/$outfileU\n";
		print OUTFILEU "echo \"got here\"\n";;
		close(OUTFILEU);
		while(qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU[$i].out -e $lognameU[$i].err < $shfileU[$i]`;
	    }
	}
	if($intronnu eq 'true') {
	    $for_lc =~ s/IU/INU/g;
	    $total_lc = $LINECOUNTS{$for_lc};
            if (($total_lc ne '0') && ($numNU ne '0')){
		open(OUTFILENU, ">$shfileNU[$i]");
		print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/$filenameNU $total_lc $numNU > $LOC/$dirNU/$outfileNU\n";
		print OUTFILENU "echo \"got here\"\n";;
		close(OUTFILENU);
		while(qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU[$i].out -e $lognameNU[$i].err < $shfileNU[$i]`;
	    }
	}
    }
    close(INFILE);
}

#intergenicmappers
open(INFILE, $ARGV[0]);
while($dirname = <INFILE>) {
    chomp($dirname);
    $id = $dirname;
    $for_lc = "IGU.$id";
    $total_lc = $LINECOUNTS{$for_lc};
    $numU = $minIGU;
    $numNU = $minIGNU;
    $filenameU = "$id.filtered_u_notexonmappers_intergenicmappers.sam";
    $outfileU = "$id.intergenicmappers.norm_u.sam";
    $filenameNU = "$id.filtered_nu_notexonmappers_intergenicmappers.sam";
    $outfileNU = "$id.intergenicmappers.norm_nu.sam";
    $dirU = $dirname . "/Unique";
    $dirNU = $dirname . "/NU";
    $shfileU = "$shdir/a" . $id . "intergenic.u_runshuf.sh";
    $shfileNU = "$shdir/a" . $id . "intergenic.nu_runshuf.sh";
    $jobname = "$study.shuf";
    $lognameU = "$logdir/intergenic.$id.u_shuf";
    $lognameNU = "$logdir/intergenic.$id.nu_shuf";
    if($iguniques eq 'true') {
	if (($total_lc ne '0') && ($numU ne '0')){
	    open(OUTFILEU, ">$shfileU");
	    print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/$filenameU $total_lc $numU > $LOC/$dirU/$outfileU\n";
	    print OUTFILEU "echo \"got here\"\n";;
	    close(OUTFILEU);
	    while(qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU.out -e $lognameU.err < $shfileU`;
	}
    }
    if($ignu eq 'true') {
	$for_lc =~ s/IGU/IGNU/g;
	$total_lc = $LINECOUNTS{$for_lc};
	if (($total_lc ne '0') && ($numNU ne '0')){
	    open(OUTFILENU, ">$shfileNU");
	    print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/$filenameNU $total_lc $numNU > $LOC/$dirNU/$outfileNU\n";
	    print OUTFILENU "echo \"got here\"\n";
	    close(OUTFILENU);
	    while(qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU.out -e $lognameNU.err < $shfileNU`;
	}
    }
}
close(INFILE);
print "got here\n";