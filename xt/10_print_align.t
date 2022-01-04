#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

binmode(STDOUT,":encoding(UTF-8)");
binmode(STDERR,":encoding(UTF-8)");

#use Test::More;
#use Test::Deep;

use Data::Dumper;

use LCS;
use Levenshtein::Simple;
#my $object = Levenshtein::Simple->new();

my $examples1 = [
  ['ttatc__cg',
   '__agcaact'],
  ['abcabba_',
   'cb_ab_ac'],
   ['yqabc_',
    'zq__cb'],
  [ 'rrp',
    'rep'],
  [ 'a',
    'b' ],
  [ 'aa',
    'a_' ],
  [ 'abb',
    '_b_' ],
  [ 'a_',
    'aa' ],
  [ '_b_',
    'abb' ],
  [ 'ab',
    'cd' ],
  [ 'ab',
    '_b' ],
  [ 'ab_',
    '_bc' ],
  [ 'abcdef',
    '_bc___' ],
  [ 'abcdef',
    '_bcg__' ],
  [ 'xabcdef',
    'y_bc___' ],
  [ 'öabcdef',
    'ü§bc___' ],
  [ 'o__horens',
    'ontho__no'],
  [ 'Jo__horensis',
    'Jontho__nota'],
  [ 'horen',
    'ho__n'],
  [ 'Chrerrplzon',
    'Choereph_on'],
  [ 'Chrerr',
    'Choere'],
  [ 'rr',
    're'],
  [ 'abcdefg_',
    '_bcdefgh'],
  [ 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVY_',
    '_bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVYZ'],
];

my $examples2 = [
  [ 'gehe oder nachfolge; und gerade hiedurch iſt die Möglichkeit geboten, den',
    'gehe oder nachſolge; und gerade hiedur_h iſt die Wöglicht_it geboten, den'],
  [ 'Indem ich nun auch für dieſe zweite Auflage eine wohlwollende Auf⸗',
    'Inden ich nun auch für wuſlge ene wohlvolende Auſ⸗'],
  [ ' wohlwollende Auf⸗',
    ' wohlvo_lende Auſ⸗'],
];

my $examples3 = [
  ['isnt',
   'hint'],
  ['sue',
   'use'],
  ['gold',
   'glow'],
  ['eonnnnnicaio',
   'communicato'],
  ['Choerephon',
   'Chrerrplzon'],
  ['Algorithm',
   'Altruistic'],
  ['ABCABBA',
   'CBABAC'],
];

if (1) {
#for my $example (@$examples1) {
for my $example ($examples1->[0]) {
#for my $example (@$examples2) {
#for my $example (@$examples3) {
#for my $example ($examples3->[5]) {
  my $s1 = $example->[0];
  my $s2 = $example->[1];
  my $x = $s1;
  $x =~ s/_//g;
  my $y = $s2;
  $y =~ s/_//g;

  my @X = split(//,$x);
  my @Y = split(//,$y);

  my $object = Levenshtein::Simple->new();

  #my $c = $object->_matrix(\@X,\@Y);

  #my $L = $object->_matrix_LCS(\@X,\@Y);

  #my $ranks = $object->_ranks(\@X,\@Y);
    #print '$ranks: ',Dumper($ranks);
=pod
if (0) {
  for my $rank (sort {$b <=> $a} keys %{$ranks}) {
      for my $x (sort {$b <=> $a} keys %{$ranks->{$rank}}) {
          for my $y (sort {$b <=> $a} keys %{$ranks->{$rank}{$x}}) {
			print 'rank:',$rank,' x: ',$x,' y: ',$y,"\n";
      	  }
      }
  }
}

  if (0) {
    print '$c: ',Dumper($c);
    print '$L: ',Dumper($L);
    #exit;
  }

  if (0) {
  	$object->_print_matrix(\@X, \@Y, $c);
  	$object->_print_matrix(\@X, \@Y, $L);
  }
=cut
  if (1) {
  	my $R = $object->all_ses(\@X,\@Y);

  	my $paths = scalar @$R;

    print "\n";
  	print 'all possible SES alignments: ', $paths,"\n";


    my $alignment_count = 0;
    for my $alignment (@$R) {
      $alignment_count++;
      print "\n";
      print '*** ', $alignment_count, '. SES Alignment ***', "\n";
      #print $a, ' > ', $b, "\n";
      $object->_print_alignment_path(\@X, \@Y, $alignment);
      $object->_print_alignment(\@X, \@Y, $alignment);
    }

  }

  #print "\n",'ses ', $a, ' > ', $b, "\n";
  #my $ses = $object->ses(\@X,\@Y);
  my $ses = $object->align(\@X,\@Y);
  my $LLCS = LCS->LLCS(\@X, \@Y);
  my $distance = $object->distance(\@X,\@Y);

  #print "\n";
  #print '*** Default SES Alignment ***', "\n";

  #$object->_print_alignment_path(\@X, \@Y, $ses);
  my $OK = 'XX';
  if (($distance+$LLCS) == scalar @$ses) { $OK = 'OK'; }
  print $OK,  "\n";
  $object->_print_alignment(\@X, \@Y, $ses);


  #print 'LLCS: ', $LLCS, "\n";
}
}


