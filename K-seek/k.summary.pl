#!/usr/bin/perl

use strict;

my $dir = $ARGV[0];
my $out = $ARGV[1];

my(%kmers,%kmerdata);

my @files = `ls -1 $dir/*.rep.total`;
foreach my $file (@files) {
	chomp($file);
	print "opening $file\n";
	open INF,"$file" or die "can't open file $file: $!";;
	while (<INF>) {
		chomp($_);
		my(@F) = split /\t/, $_;
		$kmerdata{$file}{$F[0]} = $F[1];
		$kmers{$F[0]} = 1;
	}
	close INF;
}

my %bchronlyfreq;
open INF,"bchronly.tsv";
while (<INF>) {
	chomp($_);
	my(@F) = split /\t/, $_;
	$bchronlyfreq{"$F[0]|$F[1]"} = $F[3];
}
close INF;

my %kmerDone;
foreach my $kmer (sort keys %kmers) {
	next if $kmerDone{$kmer} == 1;
	my $revComp = reverse $kmer;
	$revComp =~ tr/AGCT/TCGA/;

	$kmerDone{$kmer} = 1;
	$kmerDone{$revComp} = 1;
	my $kmerSum;
	foreach my $file (@files) {
		$kmerSum += $kmerdata{$file}{$kmer};
		$kmerSum += $kmerdata{$file}{$revComp};
	}

	my $kmerFreqBchrOnly = "na";
	$kmerFreqBchrOnly = $bchronlyfreq{"$kmer|$revComp"} if $bchronlyfreq{"$kmer|$revComp"} > 0;
	$kmerFreqBchrOnly = $bchronlyfreq{"$revComp|$kmer"} if $bchronlyfreq{"$revComp|$kmer"} > 0;

	print "$kmer\t$revComp\t$kmerSum\t$kmerFreqBchrOnly\n";
}
