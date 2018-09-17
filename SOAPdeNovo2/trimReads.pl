#!/usr/bin/perl

#Given a .fastq file trim reads using sickle and scythe

use strict;

## Programs 
my $scythe = "/home/dem/bin/scythe/scythe";
my $sickle = "/home/dem/bin/sickle/sickle";

my @files = qw/ BchrReads.highDepth.f.fastq BchrReads.highDepth.r.fastq BchrReads.unmapped.f.fastq BchrReads.unmapped.r.fastq /;

foreach my $fastqFile (@files) {
	my $cmd = "$scythe -n 1 -q sanger -a /home/dem/bin/scythe/truseq_adapters.fasta -o $fastqFile.scythe $fastqFile";
	print "[".localtime()."] $cmd\n";
	`$cmd`;
}

my $cmd = "$sickle pe -f BchrReads.highDepth.f.fastq.scythe -r BchrReads.highDepth.r.fastq.scythe -t sanger -o BchrReads.highDepth.f.sickle.fastq -p BchrReads.highDepth.r.sickle.fastq -s BchrReads.highDepth.se.sickle.fastq -l 40 -q 30";
print "[".localtime()."] $cmd\n";
`$cmd`;

my $cmd = "$sickle pe -f BchrReads.unmapped.f.fastq.scythe -r BchrReads.unmapped.r.fastq.scythe -t sanger -o BchrReads.unmapped.f.sickle.fastq -p BchrReads.unmapped.r.sickle.fastq -s BchrReads.unmapped.se.sickle.fastq -l 40 -q 30";
print "[".localtime()."] $cmd\n";
`$cmd`;
