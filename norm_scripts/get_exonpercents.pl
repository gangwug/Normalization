#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<3) {
    die "Usage: perl get_exonpercents.pl <sample directory> <cutoff> <outfile> [options]

<sample directory> 
<cutoff> cutoff %
<outfile> output exonpercents file with full path

option:
  -nu :  set this if you want to return only non-unique exonpercents, otherwise by default
         it will return unique exonpercents.

";
}

my $U = "true";
my $NU = "false";
for(my $i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$NU = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

my $total_u = 0;
my $total_nu = 0;
my $sampledir = $ARGV[0];
my @a = split("/", $sampledir);
my $dirname = $a[@a-1];
my $id = $dirname;
my $quantsfile_u = "$sampledir/EIJ/Unique/$id.filtered_u_exonquants";
my $quantsfile_nu = "$sampledir/EIJ/NU/$id.filtered_nu_exonquants";
my $temp_u = $quantsfile_u . ".temp";
my $temp_nu = $quantsfile_nu . ".temp";
my $cutoff = $ARGV[1];
my $outfile = $ARGV[2];
my $highfile = $outfile;
$highfile =~ s/.exonpercents.txt/.high_expressors_exon.txt/;

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if ((0 > $cutoff) || (100 < $cutoff)){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}

if($U eq "true"){
    open(INFILE_U, $quantsfile_u) or die "cannot find file '$quantsfile_u'\n";
    open(temp_u, ">$temp_u");
    while(my $line = <INFILE_U>){
	chomp($line);
	if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
	    next;
	}
	print temp_u "$line\n";
	my @a = split(/\t/, $line);
	my $quant = $a[2];
	$total_u = $total_u + $quant;
    }
    close(INFILE_U);
    close(temp_u);
}
if ($NU eq "true"){
    open(INFILE_NU, $quantsfile_nu) or die "cannot find file '$quantsfile_nu'\n";
    open(temp_nu, ">$temp_nu");
    while(my $line = <INFILE_NU>){
	chomp($line);
	if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
	    next;
	}
	print temp_nu "$line\n"; 
	my @a = split(/\t/, $line);
	my $quant = $a[2];
	$total_nu = $total_nu + $quant;
    }
    close(INFILE_NU);
    close(temp_nu);
}
if($U eq "true"){
    open(IN_U, $temp_u);
    open(OUT, ">$outfile");
    open(OUT2, ">$highfile");
    print OUT "exon\t%unique\n";
    print OUT2 "exon\t%unique\n";
    while(my $line_U = <IN_U>){
	chomp($line_U);
	
	my @au = split(/\t/, $line_U);
	my $exonu = $au[0];
	my $quantu = $au[2];
	my $percent_u = int(($quantu / $total_u)* 10000 ) / 100;
	
	print OUT "$exonu\t$percent_u\n";
	
	if ($percent_u >= $cutoff){
	    print OUT2 "$exonu\t$percent_u\n";
	}
    }
    close(IN_U);
    close(OUT);
    close(OUT2);
    `rm $temp_u`;
}
if($NU eq "true"){
    open(IN_NU, $temp_nu);
    open(OUT, ">$outfile");
    open(OUT2, ">$highfile");
    print OUT "exon\t%non-unique\n";
    print OUT2 "exon\t%non-unique\n";
    while(my $line_NU = <IN_NU>){
	chomp($line_NU);

	my @anu = split(/\t/, $line_NU);
	my $exonnu = $anu[0];
	my $quantnu = $anu[2];
	my $percent_nu = int(($quantnu / $total_nu)* 10000 ) / 100;
	
	print OUT "$exonnu\t$percent_nu\n";
	
	if ($percent_nu >= $cutoff){
	    print OUT2 "$exonnu\t$percent_nu\n";
	}
    }
    close(IN_NU);
    close(OUT);
    close(OUT2);
    `rm $temp_nu`;
}
#print "got here\n";

