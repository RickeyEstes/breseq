#!/usr/bin/perl -w

###
# Pod Documentation
###

=head1 NAME

graph_coverage.pl

=head1 SYNOPSIS

Usage: graph_coverage.pl -i deletions.tab -c coverage.tab

Use R to create graphs of the read coverage at specified positions, or to 
show the boundaries of all predicted deletions in a genome.

=head1 DESCRIPTION

=over

=item B<-i> <file path> 

Input "deletions.tab" file produced by breseq.pl. These intervals will be graphed
in the output file "deletions.pdf".

=item B<-c> <file path> 

Path to "coverage.tab" file produced by breseq.pl.

=item B<--interval> <start>-<end>

Instead of using the -i option to input a file specifying positions to graph, you can
specify start-end coordinates (e.g. --interval=12345-12456). Multiple intervals can be 
specified, and the graphs will be made as separate pages in the output file "specific_coverage.pdf".

=back

=head1 AUTHOR

Jeffrey Barrick
<jbarrick@msu.edu>

=head1 COPYRIGHT

Copyright 2008.  All rights reserved.

=cut

###
# End Pod Documentation
###
use strict;

use File::Path;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;

#Get options
use Getopt::Long;
use Pod::Usage;

my ($help, $man);
my $verbose;
my $input_file;
my $output_file;
my $output2_file;
my $deletion_file;
my $coverage_file;
my $max_files = 99999;

GetOptions(
	'help|?' => \$help, 'man' => \$man,
	'input-path|p=s' => \$input_file,
	'output-path|o=s' => \$output_file,
	'deletion-file|d=s' => \$deletion_file,
	'coverage-file|c=s' => \$coverage_file,
	'verbose|v=s' => \$verbose,
);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $window_size;
open COV, "<$coverage_file" or die;
my $line = <COV>;
$line =~ m/#window_size=(\d+)/;
$window_size = $1;
print "Window Size = $window_size\n";
	
$input_file =~ m/(.+?)\./;
$deletion_file = "$1.deletions.tab" if (!defined $deletion_file);
$output_file = "$1.normalized.tab" if (!defined $output_file);
$output2_file = "$1.normalized.highlight.tab" if (!defined $output2_file);


open OUTPUT, ">$output_file" or die;
print OUTPUT "pos\tmean\tz_score\n";
open OUTPUT2, ">$output2_file" or die;
print OUTPUT2 "pos\tmean\tz_score\n";


#read complete length of all deletion files
	
open IN, "$deletion_file";
my @lines = <IN>;
shift @lines;
print "File $deletion_file\n";

my @deletion_list = ();
foreach my $l (@lines)
{
	my @sl = split /\t/, $l; 
	push @deletion_list, { start=> $sl[1], end=>$sl[2] };
	print "  Deletion $sl[1]-$sl[2]\n";
}

my $unique_average;
my $unique_positions = 0;
my $unique_total = 0;
	
open IN, "$input_file";
my $dontcare = <IN>;
while (my $_ = <IN>)
{
	last if ($unique_positions > 100000);
	
	chomp $_;
	my @sl = split "\t", $_;
	
	if ($sl[2] + $sl[3] == 0)
	{
		$unique_total+= $sl[0] + $sl[1];
		$unique_positions++;
	}
}
$unique_average = $unique_total/$unique_positions;
close IN;
	
print "Input $input_file, Unique Average $unique_average\n";

open IN, "$input_file";
$dontcare = <IN>;


#go through every position
#assumes every position exists in file
my $position = 0;
POS: while (1) {
	
	my $line = <COV>;
	last if (!$line);
	chomp $line;
	my ($ref_mean, $ref_stdev, $ref_obs) = split "\t", $line;
	
	my $top=0;
	my $bot=0;
	my $tot=0;
	my $count=0;

	W: for (my $w=0; $w < $window_size; $w++)
	{		
		$position++;		
		my $line = readline IN;
		
		last W if (!$line);
		#SHOULD check here to see if we are actually at the right position from the split line.
	
		#check the corresponding deletion we are on
		if (scalar @deletion_list > 0)
		{
			#remove first deletion if we are past it
			shift @deletion_list if ($position > $deletion_list[0]->{end});
			
			if (scalar @deletion_list > 0)
			{
				#ignore position if we are inside a deletion
				next W if ($position >= $deletion_list[0]->{start} && $position <= $deletion_list[0]->{end})
			}
		}
	
		#print "$line\n";
		chomp $line;
		my @sl = split "\t", $line;
		
		#note that we average out IS elements...
		
		if ($sl[2] + $sl[3] == 0)
		{
			$top += $sl[0] / $unique_average;
			$bot += $sl[1] / $unique_average;
			$tot += ($sl[0]+$sl[1]) / $unique_average;
			$count++;
		}
	}
	
	#calculate average and standard deviation	
	my $norm_mean = 'NA';
	my $norm_z = 'NA';
	if (($count > 0) && ($ref_mean ne 'NA'))
	{
		my $mean = $tot/$count;
		$norm_mean = $mean/$ref_mean;
		$norm_z = ($mean-$ref_mean) / $ref_stdev if ($ref_stdev != 0);
	}
	my $pos = $position;

	print OUTPUT2 "$pos\t$norm_mean\t$norm_z\n" if (($norm_mean ne 'NA') && ($norm_mean > 1.5));
	print OUTPUT "$pos\t$norm_mean\t$norm_z\n";
}