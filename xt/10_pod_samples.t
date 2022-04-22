#!perl
use 5.008;

use strict;
use warnings;
use utf8;

binmode(STDOUT,":encoding(UTF-8)");
binmode(STDERR,":encoding(UTF-8)");

use lib qw(
../lib/
./lib/
);

use Test::More;
use Test::More::UTF8;
use Test::Deep;

use Levenshtein::Simple;

use Data::Dumper;

  my $lev = Levenshtein::Simple->new();

  # we need arrays of strings
  my @seq1 = split( //, 'sue' );
  my @seq2 = split( //, 'use' );

  my $distance = $lev->distance( [ @seq1 ], [ @seq2 ] );

  print "distance: $distance", "\n";

  my $ses = $lev->ses( [ @seq1 ], [ @seq2 ] );

  # $ses now contains an arrayref of the shortest edit script

  print $lev->_format_alignment_path($ses), "\n", "\n";
  # [ [-1,0,+],[0,1,=],[1,-1,-],[2,2,=], ]

  # generate all shortest edit scripts
  my $all_ses = $lev->all_ses( [ @seq1 ], [ @seq2 ] );

  for my $solution ( @{$all_ses} ) {
    print $lev->_format_alignment_path($solution), "\n";
  }
  print "\n";

  print $lev->format_matrix( [ @seq1 ], [ @seq2 ] );
  print "\n";

=pod
Levenshtein matrix of "sue" versus "use"

     u s e
   0 1 2 3
 s 1 1 1 2
 u 2 1 2 2
 e 3 2 2 2
=cut

  # print alignment
  print $lev->format_alignment( [ @seq1 ], [ @seq2 ] );
  print "\n";

  # print all alignments
  my $solutions  = $lev->all_ses( [ @seq1 ], [ @seq2 ] ) ;
  for my $solution (@$solutions) {
    print $lev->_format_alignment( [ @seq1 ], [ @seq2 ] , $solution ), "\n";
  }
  print "\n";


print Dumper($lev->all_ses( [qw(g o l d)], [qw(g l o w)]));


  $distance = $lev->distance( [qw(g o l d)], [qw(g l o w)]);
  print '$distance: ', $distance,"\n";

my $alignment_path = $lev->format_alignment_path( [qw(g o l d)], [qw(g l o w)]);
print 'format_alignment_path: ',"\n", $alignment_path,"\n";
# [ [0,0,=],[0,1,+],[1,2,=],[2,3,~],[3,3,-], ]

print $lev->format_matrix( [qw(g o l d)], [qw(g l o w)] );

print $lev->format_alignment( [qw(g o l d)], [qw(g l o w)] );

# _format_alignment($self, $X, $Y, $ses, $gap)
{
  my $ses = $lev->ses( [qw(g o l d)], [qw(g l o w)]);
  my $alignment
    = $lev->_format_alignment( [qw(g o l d)], [qw(g l o w)], $ses );
  print $alignment,"\n";
}

my $metrics = $lev->metrics( [qw(g o l d)], [qw(g l o w)] );

print 'metrics: ', Dumper($metrics);

$metrics = $lev->_metrics( [qw(g o l d)], [qw(g l o w)], $ses );

print "\n", 'format_metrics: ',$lev->format_metrics($metrics), "\n";

# align2strings($self, $ses, $gap)

my $aligned_strings = $lev->align2strings($ses);

print 'aligned_strings: ', Dumper($aligned_strings);

# ses2align($self, $X, $Y, $ses)

my $ses2align = $lev->ses2align( [qw(g o l d)], [qw(g l o w)], $ses );

print 'ses2align: ', Dumper($ses2align);

# ses2none($self, $ses)

my $ses2none = $lev->ses2align( $ses );

print 'ses2none: ', Dumper($ses2none);

# ses2compact($self, $ses)

my $ses2compact = $lev->ses2compact( $ses ), "\n";

print 'ses2compact: ', Dumper($ses2compact);

exit;

=pod
sub matrix {
    my ($self, $X, $Y) = @_;

sub format_matrix {
    my ($self, $X, $Y ) = @_;

  # print the match matrix
  print $lev->print_matrix( [ @seq1 ], [ @seq2 ] );

  Levenshtein matrix of "sue" versus "use"

      u s e
    0 1 2 3
  s 1 1 1 2
  u 2 1 2 2
  e 3 2 2 2

sub _format_matrix {
    my ($self, $X, $Y, $c)

sub format_alignment_path {
    my ($self, $X, $Y ) = @_;



sub _format_alignment_path {
    my ($self, $hunks) = @_;

sub format_alignment {
    my ($self, $X, $Y, $gap) = @_;

  # print alignment
  print $lev->print_alignment( [ @seq1 ], [ @seq2 ] );

  _sue
  +=-=  distance:2 M:2 S:0 D:1 I:1 ERR:0.67 Acc:0.50 nCER:0.50
  us_e

sub _format_alignment {
    my ($self, $X, $Y, $hunks, $gap) = @_;

sub format_metrics {
    my ($self, $metrics ) = @_;

sub metrics {
    my ($self, $X, $Y ) = @_;

sub _metrics {
    my ($self, $X, $Y, $hunks) = @_;

sub align2strings {
  	my ($self, $hunks, $gap) = @_;

sub ses2align {
    my ($self, $X, $Y, $hunks) = @_;

sub ses2none {
    my ($self, $hunks) = @_;

sub ses2compact {
    my ($self, $ses) = @_;

=cut


done_testing;
