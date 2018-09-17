#!/usr/bin/perl

use strict;

my $pwd = `pwd`;
chomp($pwd);
my $logfile = "soap_assemblies.log";
my $soap63 = "/home/dem/bin/SOAPdenovo2-src-r240/SOAPdenovo-63mer";
my $soap127 = "/home/dem/bin/SOAPdenovo2-src-r240/SOAPdenovo-127mer";

foreach my $kmer (21,31,41,51,61,71,81,91,101,111) {
	my $soap = $soap63;
	   $soap = $soap127 if $kmer > 63;

	my $dir = "k$kmer";
	   $dir = "unmapped_k$kmer";

	executeCommand("mkdir -p $pwd/$dir");
	executeCommand("$soap all -s soapdenovo.config -K $kmer -p 25 -o $dir/graph_prefix 1>$dir/assembly.log 2>$dir/assembly.err");
	logData("");
}

## Two subroutines are used, one to run commands, the second to log all activities
sub executeCommand {
	open LOGF, ">>$pwd/$logfile";
	print LOGF "[".localtime()."] CMD: $_[0]\n";
	close LOGF;
	my $output = `$_[0]`;
	return($output);
}

sub logData {
	print "[".localtime()."] $_[0]\n" if $_[1] eq "print";
	open LOGF, ">>$pwd/$logfile";
	print LOGF "[".localtime()."] LOG: $_[0]\n";
	close LOGF;
	return 1;
}
## End Subroutines
