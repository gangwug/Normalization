#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "Usage: perl get_percent_high_expressor.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return unique stats.

";
}
my $U = "true";
my $NU = "false";
my $option_found = "false";
for(my $i=2; $i<@ARGV; $i++) {
    if($ARGV[$i] eq '-nu') {
        $U = "false";
        $NU = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";
unless (-d "$stats_dir/EXON_INTRON_JUNCTION/"){
    `mkdir -p $stats_dir/EXON_INTRON_JUNCTION`;}
my $outfileU = "$stats_dir/EXON_INTRON_JUNCTION/percent_high_expressor_exon_Unique.txt";
my $outfileNU = "$stats_dir/EXON_INTRON_JUNCTION/percent_high_expressor_exon_NU.txt";
my %HIGH_EXON;
open(INFILE, "<$ARGV[0]");
my @dirs = <INFILE>;
close(INFILE);
foreach my $dir (@dirs){
    chomp($dir);
    my $id = $dir;
    my $file = "$LOC/$dir/$id.high_expressors_exon_annot.txt";
    open(IN, "<$file");
    my @exons = <IN>;
    close(IN);
    foreach my $exon (@exons){
	chomp($exon);
	if ($exon =~ /^exon/){
	    next;
	}
	my @e = split(" ", $exon);
	my $name = $e[0];
	my $symbol_list = $e[3];
	my @s = split(',' , $symbol_list);
	my @symbol = ();
	for (my $i=0;$i<@s;$i++){
	    push(@symbol,$s[$i]);
	}
	my %hash = map {$_ => 1} @symbol;
	my @list = keys %hash;
	my $symlist = join(',',@list);
	$HIGH_EXON{$name} =  $symlist;
    }
}

my $firstrow = "exon";
my $lastrow = "gene";
while (my ($key, $value) = each (%HIGH_EXON)){
    $firstrow = $firstrow . "\t$key";
    $lastrow = $lastrow . "\t$value";
}

if ($U eq "true"){
    if(-e $outfileU){
	`rm $outfileU`;
    }
    open(OUTU, ">>$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    print OUTU "$firstrow\n";	
}
if ($NU eq "true"){
    if(-e $outfileNU){
	`rm $outfileNU`;
    }
    open(OUTNU, ">>$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    print OUTNU "$firstrow\n";
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $line;
    my $rowU = "$id\t";
    my $rowNU = "$id\t";
    foreach my $exon (keys %HIGH_EXON){
	chomp($exon);
	$exon =~ s/exon://;
	my $exonpercent = "$LOC/$dir/$id.exonpercents.txt";
	my $value = `grep -w $exon $exonpercent`;
	my @v = split(" ", $value);
	my $val = $v[1];
	if ($U eq "true"){
	    $rowU = $rowU . "$val\t";
	}
	if ($NU eq "true"){
	    $rowNU = $rowNU . "$val\t";
	}
    }
    if($U eq "true") {
	print OUTU "$rowU\n";
    }
    if ($NU eq "true"){
	print OUTNU "$rowNU\n";
    }
}
if ($U eq "true"){
    print OUTU "$lastrow\n";
    close(OUTU);
}
if ($NU eq "true"){
    print OUTNU "$lastrow\n";
    close(OUTNU);
}
close(INFILE);
print "got here\n";
