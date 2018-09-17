#!/usr/bin/perl

use strict;

my $minReadDepth = 100; # isolate reads that align to regions with this read depth or greater

my $outputFastqF = "bchr_isolate.f.fastq";
my $outputFastqR = "bchr_isolate.r.fastq";
my $f_fastq = "/n/analysis/Hawley/slh/MOLNG-1468/ALAN4/s_1_1_ACAGTG.fastq.gz";
my $r_fastq = "/n/analysis/Hawley/slh/MOLNG-1468/ALAN4/s_1_2_ACAGTG.fastq.gz";
my $dm6 = "/n/projects/dem/dat/genome.dmel/dm6/dm6.fa";

# Steps:
# 1. align data to genome, isolate reads that don't align
#`/n/local/bin/bwa mem -t 30 $dm6 $f_fastq $r_fastq > B-chr-only.sam 2>/dev/null`;
#`/n/local/bin/samtools view -b B-chr-only.sam > B-chr-only.bam`;
#`/n/local/bin/samtools view -f4 B-chr-only.bam > B-chr-only.unmapped.sam`;

my(%unmappedReads,$countUnmappedReads,$countUnmappedReadPairs);
print "[".localtime()."] Opening B-chr-only.unmapped.sam\n";
open INF, "B-chr-only.unmapped.sam" or die "Can't open file: $!";
while (<INF>) {
	my(@F) = split /\t/, $_;
	$unmappedReads{$F[0]}++;
	$countUnmappedReads++;
	$countUnmappedReadPairs++ if $unmappedReads{$F[0]} == 2;
}
close INF;
print "[".localtime()."] Unmapped read count: $countUnmappedReads\n";
print "[".localtime()."] Unmapped read pairs: $countUnmappedReadPairs\n";
print "[".localtime()."] \n";

# 2. identify regions with depth of coverage > $minReadDepth, isolate those reads
my %readDepth;
print "[".localtime()."] Opening B-chr-only.coverage\n";
open INF,"/n/projects/dem/alignments/B-chr-only/B-chr-only.coverage" or die "Can't open file: $!";
while (<INF>) {
	chomp($_);
	my(@F) = split /\t/, $_;
	next unless $F[3] > $minReadDepth;

	foreach my $loc ($F[1]..$F[2]) {
		$readDepth{$F[0]}{$loc} = 1;
	}
}
close INF;

my(%highDepthReads,%chrLen);
print "[".localtime()."] Opening B-chr-only.sam\n";
open INF, "B-chr-only.sam" or die "Can't open file: $!";
while (<INF>) {
	if ($_ =~ /^\@SQ/) {
		my($chr,$len) = $_ =~ /SN\:(\w+)\tLN\:(\d+)/;
		$chrLen{$chr} = $len;
	} else {
		my(@F) = split /\t/, $_;
		#M01285:50:000000000-ALAN4:1:1101:16348:1352     83      chrX    2973930 40      17S19M115S
		
		my($chr,$loc) = ($F[2],$F[3]);
		my $skip = 1;
		foreach my $foo (-100,-50,50,100) {
			my $tmpLoc = $loc + $foo;
			$skip = 0 if $readDepth{$chr}{$tmpLoc} == 1;
		}
		next if $skip == 1;

		$highDepthReads{$F[0]} = 1;
	}
}

# 2a. percent of genome with high coverage
foreach my $chr (keys %readDepth) {
	my $count;
	foreach my $foo (keys %{$readDepth{$chr}}) {
		$count++;
	}

	my $percent = "na";
	if ($chrLen{$chr}) {
		$percent = sprintf("%0.1f", ($count/$chrLen{$chr}) * 100);
	}

	next if $percent == 0;
	next if $percent eq "na";
	print "\t$chr\t$count\t$chrLen{$chr}\t$percent \%\n";
}

# 3. output all fastq's
my($totalReads,$totalReadsForAssembly);
foreach my $fastq ($f_fastq,$r_fastq) {
	my($fastqFile) = $fastq =~ /\/(s_1_\d+_ACAGTG.fastq.gz)$/;
	
	my $fastqOut = "f.fastq";
	   $fastqOut = "r.fastq" if $fastqFile =~ /s_1_2/;
	
	my $cmd = "cp $fastq ./";
	`$cmd`;
	my $cmd = "gzip -d ./$fastqFile";
	`$cmd`;
	$fastqFile =~ s/\.gz//;

	open INF,"$fastqFile" or die "Can't open $fastqFile: $!";
	while (<INF>) {
		my $fastq1 = $_;
		my $fastq2 = <INF>;
		my $fastq3 = <INF>;
		my $fastq4 = <INF>;

		++$totalReads;

		chomp($fastq1);
		chomp($fastq2);
		chomp($fastq3);
		chomp($fastq4);

		my($readID) = $fastq1 =~ /\@(\S+)\s\d+\:/;

		my $skip = 0;
		$skip = 1 if $highDepthReads{$readID} == 1;
		$skip = 2 if $unmappedReads{$readID} == 1;
		next if $skip == 0;

		my $fastqOutputFile;
		   $fastqOutputFile = "BchrReads.highDepth.$fastqOut" if $skip == 1;
		   $fastqOutputFile = "BchrReads.unmapped.$fastqOut" if $skip == 2;

		open OUTF,">>./$fastqOutputFile";
		print OUTF "$fastq1\n$fastq2\n$fastq3\n$fastq4\n";
		close OUTF;

		++$totalReadsForAssembly;
	}

	my $cmd = "rm -f ./$fastqFile";
	`$cmd`;
}

print "[".localtime()."] Total reads: $totalReads\n";
print "[".localtime()."] Total read pairs: " . $totalReads / 2 . "\n";
print "[".localtime()."] \n";
print "[".localtime()."] Total reads for assembly: $totalReadsForAssembly\n";
print "[".localtime()."] Total read pairs for assembly: " . $totalReadsForAssembly / 2 . "\n";

# 4. quality trim reads
