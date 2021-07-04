#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

#use Test::More;
#use Test::Deep;

use Data::Dumper;

use Levenshtein::Simple;
#my $object = Levenshtein::Simple->new();

my $examples = [
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

if (1) {
#for my $example (@$examples) {
for my $example ($examples->[0]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my $x = $a;
  $x =~ s/_//g;
  my $y = $b;
  $y =~ s/_//g;

  #my @X = map { $_ =~ s/_//; $_ } split(//,$example->[0]);
  #my @Y = map { $_ =~ s/_//; $_ } split(//,$example->[1]);

  my @X = split(//,$x);
  my @Y = split(//,$y);

  print $a, "\n", $b, "\n";
  print join('',@X),' ',join('',@Y),"\n";

  my $object = Levenshtein::Simple->new();

  my $c = $object->_matrix(\@X,\@Y);


  #print '$c: ',Dumper($c);

  $object->_print_matrix(\@X, \@Y, $c);

  #exit;

  my $R = $object->all_ses(\@X,\@Y);

  my $paths = scalar @$R;

  print '$paths: ', $paths,"\n"; # $paths: 19

  #print '$R: ',Dumper($R);

  #exit;

  #for my $alignment (@$R) {
  #    print "\n";
  #    #print $a, ' > ', $b, "\n";
  #    $object->_print_alignment(\@X, \@Y, $alignment);
  #}

  print "\n",'ses ', $a, ' > ', $b, "\n";
  my $ses = $object->ses(\@X,\@Y);
  $object->_print_alignment(\@X, \@Y, $ses);
}
}


