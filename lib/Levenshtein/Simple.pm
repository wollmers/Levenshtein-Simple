package Levenshtein::Simple;

use strict;
use warnings;

use 5.006;
our $VERSION = '0.01';

binmode(STDOUT,":encoding(UTF-8)");
binmode(STDERR,":encoding(UTF-8)");

sub new {
    my $class = shift;
    bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub distance {
    my ($self, $X, $Y) = @_;

    # X equal Y needs no extra logic, as it is
    # catched by prefix/suffix optimisation

    # prefix/suffix optimisation
    my ($amin, $amax, $bmin, $bmax) = (0, $#$X, 0, $#$Y);

    while ($amin <= $amax and $bmin <= $bmax and $X->[$amin] eq $Y->[$bmin]) {
        $amin++;
        $bmin++;
    }
    while ($amin <= $amax and $bmin <= $bmax and $X->[$amax] eq $Y->[$bmax]) {
        $amax--;
        $bmax--;
    }

    # lengths for matrix
    my $m = ($amax - $amin) + 1;
    my $n = ($bmax - $bmin) + 1;

    # shortcut if length of one or both sides is zero
    if ( !$m || !$n ) { return ( $m ? $m : $n ) }

    my @c = ();

    # init first row of matrix @c
    for my $j ( 0 .. $n ) { $c[0][$j] = $j; }

    my ($i, $j);

    for $i ( 1 .. $m ) {

        # init first column of matrix
        $c[$i][0] = $i;

        for $j ( 1 .. $n ) {
            if ( $X->[$amin + $i - 1] eq $Y->[$bmin + $j - 1] ) {
                $c[$i][$j] = $c[$i-1][$j-1];
            }
            else {
                my $delete     = $c[$i-1][$j  ] + 1;
                my $insert     = $c[$i  ][$j-1] + 1;
                my $substitute = $c[$i-1][$j-1] + 1;
                my $minimum    = $delete;

                if ( $insert     < $minimum ) { $minimum = $insert; }
                if ( $substitute < $minimum ) { $minimum = $substitute; }
                $c[$i][$j] = $minimum;
            }
        }
    }

    # last cell contains distance
    return ( $c[$m][$n] );
}

sub _matrix {
    my ($self, $X, $Y) = @_;

    my $m = scalar @{$X};
    my $n = scalar @{$Y};

    my @c = ();

    for my $j (0..$n) { $c[0][$j] = $j; }

    my ($i,$j);

    for $i ( 1 .. $m ) {
        $c[$i][0] = $i;
        for $j ( 1 .. $n ) {
            if ( $X->[$i-1] eq $Y->[$j-1] ) {
                $c[$i][$j] = $c[$i-1][$j-1];
            }
            else {
                my $delete     = $c[$i-1][$j  ] + 1;
                my $insert     = $c[$i  ][$j-1] + 1;
                my $substitute = $c[$i-1][$j-1] + 1;
                my $minimum    = $delete;

                if ( $insert     < $minimum ) { $minimum = $insert; }
                if ( $substitute < $minimum ) { $minimum = $substitute; }
                $c[$i][$j] = $minimum;
            }
        }
    }
    return [ @c ];
}

sub ses {
    my ( $self, $X, $Y) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    if ( !$m && !$n ) { return [] }

    my $c = $self->_matrix( $X, $Y );

    ##$self->_print_matrix($X, $Y, $c);

    my $ses = [];

    my $i = $m;
    my $j = $n;

    while ($i > 0 && $j > 0) {
        my $min = $self->min3(
        	$c->[$i-1][$j-1],
        	$c->[$i-1][$j  ],
        	$c->[$i  ][$j-1]
        );
        ##print STDERR '$i: ', $i, '$j: ', $j, "\n";
        ##print STDERR '$c->[$i-1][$j-1]: ', $c->[$i-1][$j-1], '$c->[$i-1][$j  ]: ', $c->[$i-1][$j  ], '$c->[$i  ][$j-1]: ', $c->[$i  ][$j-1], "\n";
        ##print STDERR '$min: ', $min, "\n" unless $min;
        # equal = match
        if ( $c->[$i-1][$j-1] == $min && (($c->[$i-1][$j-1] + 0 ) == $c->[$i][$j]) ) {
            unshift @$ses, [$i-1, $j-1, '='];
            $i--; $j--;
        }
        # deletion
        elsif ($i > 0 && ($c->[$i-1][$j] + 1 == $c->[$i][$j]) ) {
            unshift @$ses, [$i-1, $j-1, '-'];
            $i--;
        }
        # insertion
        elsif ($j > 0 && ($c->[$i][$j-1] + 1 == $c->[$i][$j]) ) {
            unshift @$ses, [$i-1, $j-1, '+'];
            $j--;
        }

        # substitution
        elsif ($i > 0 && $j > 0 && ($c->[$i-1][$j-1] + 1  == $c->[$i][$j]) ) {
            unshift @$ses, [$i-1, $j-1, '~'];
            $i--; $j--;
        }
    }
    while ($i > 0) {
            unshift @$ses, [$i-1, $j, '-'];
            $i--;
    }
    while ($j > 0) {
            unshift @$ses, [$i, $j-1, '+'];
            $j--;
    }
    return $ses;
}

sub all_ses {
    my ($self, $X, $Y) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    if ( !$m && !$n ) { return [[]] }

    my $c = $self->_matrix($X, $Y);

    ##$self->_print_matrix($X, $Y, $c);

    my $paths  = [[]];
    my $result = [];

    my $i = $m;
    my $j = $n;

    while ( scalar(@$paths) > 0 ) {
        my @temp;
        PATH: for my $path (@$paths) {
            $i = $m;
            $j = $n;

            if (scalar @$path) {
                $i = $path->[0][0] + 1;
                $j = $path->[0][1] + 1;
                if    ($path->[0][2] eq '-') { $i--; }
                elsif ($path->[0][2] eq '+') { $j--; }
                else  { $i--; $j--; }
            }
            #print STDERR ' $i: ', $i, ' $j: ', $j, "\n";
            # deletion
            if ($i > 0 && $c->[$i-1][$j] + 1 == $c->[$i][$j]) {
                if ($i == 1 && $j <= 1) {
                    push @$result, [ [0, 0, '-'], @$path ];
                }
                else {
                    #print STDERR join(' ', ($i-1, $j-1, '-')), "\n";
                    push @temp, [ [$i-1, $j-1, '-'], @$path ];
                }
            }
            # insertion
            if ($j > 0 && $c->[$i][$j-1] + 1 == $c->[$i][$j]) {
                if ($i <= 1 && $j == 1) {
                    push @$result, [ [0, 0, '+'], @$path ];
                }
                else {
                    #print STDERR join(' ', ($i-1, $j-1, '+')), "\n";
                    push @temp, [[$i-1, $j-1, '+'], @$path];
                }
            }
            # equal = match
            if ($i > 0 && $j > 0 && $c->[$i-1][$j-1] == $c->[$i][$j]) {
                if ($i == 1 && $j == 1) {
                    push @$result, [ [0, 0, '='], @$path ];
                }
                else {
                    #print STDERR join(' ', ($i-1, $j-1, '=')), "\n";
                    push @temp, [ [$i-1, $j-1, '='], @$path ];
                }
            }
            # substitution
            if ($i > 0 && $j > 0 && $c->[$i-1][$j-1] + 1  == $c->[$i][$j]) {
                if ($i == 1 && $j == 1) {
                    push @$result, [ [0, 0, '~'], @$path ];
                }
                else {
                    #print STDERR join(' ', ($i-1, $j-1, '~')), "\n";
                    push @temp, [[$i-1, $j-1, '~'], @$path];
                }
            }
        }
        @$paths = @temp;
    }
    return $result;
}

sub _print_matrix {
    my ($self, $X, $Y, $c) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    print "\n", 'Levenshtein matrix of "',join('',@$X),'" versus "',join('',@$Y),'"',"\n";
    print "\n";
    print '  ',sprintf('%3s',' ');
    for my $j (0..$n-1) { print sprintf('%3s',$Y->[$j]); }
    print "\n",'  ';
    for my $j (0..$n) { print sprintf('%3s',$c->[0][$j]); }
    print "\n";
    for my $i (1..$m) {
        print ' ', sprintf('%1s',$X->[$i-1]);
        for my $j (0..$n) { print sprintf('%3s', $c->[$i][$j]); }
        print "\n";
    }
}

sub _print_alignment_path {
    my ($self, $X, $Y, $hunks) = @_;

    my $line = 'Path: [ ';
    for my $hunk (@$hunks) {
        $line .= '[' . join(',', @$hunk) . '],';
    }
    print $line, ' ]', "\n";
}

sub _print_alignment {
    my ($self, $X, $Y, $hunks) = @_;

    my $line1 = '';
    my $line2 = '';
    my $line3 = '';

    my $match      = 0;
    my $substitute = 0;
    my $delete     = 0;
    my $insert     = 0;

    for my $hunk (@$hunks) {
        $line2 .= $hunk->[2];
        if ($hunk->[2] eq '-') {
        	$delete++;
            $line1 .= $X->[$hunk->[0]];
            $line3 .= '_';
        }
        elsif ($hunk->[2] eq '+') {
            $insert++;
            $line1 .= '_';
            $line3 .= $Y->[$hunk->[1]];
        }
        elsif ($hunk->[2] eq '~') {
            $substitute++;
            $line1 .= $X->[$hunk->[0]];
            $line3 .= $Y->[$hunk->[1]];
        }
        else {
        	$match++;
            $line1 .= $X->[$hunk->[0]];
            $line3 .= $Y->[$hunk->[1]];
        }
    }

    my $distance = $substitute + $delete + $insert;
    # CER = ( S + D + I ) / ( M + S + D )
    my $CER  = $distance / ($match + $substitute + $delete);
    # Accuracy = M       / ( M    + S + D + I )
    my $Acc  = $match / ($match + $distance);
    my $nCER = 1 - $Acc;

    print "\n";
    print $line1,"\n";
    print $line2,
    	'  distance:', $distance,
    	' M:', $match,
    	' S:', $substitute,
    	' D:', $delete,
    	' I:', $insert,
    	' CER:',  sprintf('%.2f', $CER),
    	' Acc:',  sprintf('%.2f', $Acc),
    	' nCER:', sprintf('%.2f', $nCER),
    	"\n";
    print $line3,"\n";
}

sub align2strings {
  	my ($self, $hunks, $gap) = @_;
  	$gap = (defined $gap) ? $gap : '_';

  	my $a = '';
  	my $b = '';

    for my $hunk (@$hunks) {
        if ($hunk->[0] eq $hunk->[1]) {
    	    $a .=  $hunk->[0];
    	    $b .=  $hunk->[1];
        }
        elsif (!$hunk->[0] && $hunk->[1])  {
    	    $a .=  $gap;
    	    $b .=  $hunk->[1];
        }
        elsif ($hunk->[0]  && !$hunk->[1]) {
    	    $a .=  $hunk->[0];
    	    $b .=  $gap;
        }
        else {
    	    $a .=  $hunk->[0];
    	    $b .=  $hunk->[1];
        }
    }

  	return ($a,$b);
}

sub ses2align {
    my ($self, $X, $Y, $hunks) = @_;

    my $align = [];

    for my $hunk (@$hunks) {
        if ($hunk->[2] eq '-') {
            push @$align,[ $X->[$hunk->[0]], '' ];
        }
        elsif ($hunk->[2] eq '+') {
            push @$align,[ '', $Y->[$hunk->[1]] ];
        }
        else {
            push @$align,[ $X->[$hunk->[0]], $Y->[$hunk->[1]] ];
        }
    }
    return $align;
}

sub min3 {
  ($_[1] <= $_[2])
    ? ($_[1] <= $_[3]
      ? $_[1] : $_[3]
    )
    : ($_[2] <= $_[3]
      ? $_[2] : $_[3]
  );
}

1;

__END__

=encoding utf-8

=head1 NAME

Levenshtein::Simple - Levenshtein algorithm in the simple variant

=begin html

<a href="https://travis-ci.org/wollmers/Levenshtein-Simple"><img src="https://travis-ci.org/wollmers/Levenshtein-Simple.png" alt="Levenshtein-Simple"></a>
<a href='https://coveralls.io/r/wollmers/Levenshtein-Simple?branch=master'><img src='https://coveralls.io/repos/wollmers/Levenshtein-Simple/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Levenshtein-Simple'><img src='http://cpants.cpanauthors.org/dist/Levenshtein-Simple.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Levenshtein-Simple"><img src="https://badge.fury.io/pl/Levenshtein-Simple.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use LCS;
  my $lcs = LCS->LCS( [qw(a b)], [qw(a b b)] );

  # $lcs now contains an arrayref of matching positions
  # same as
  $lcs = [
    [ 0, 0 ],
    [ 1, 2 ]
  ];

  my $all_lcs = LCS->allLCS( [qw(a b)], [qw(a b b)] );

  # same as
  $all_lcs = [
    [
      [ 0, 0 ],
      [ 1, 1 ]
    ],
    [
      [ 0, 0 ],
      [ 1, 2 ]
    ]
  ];

=head1 DESCRIPTION

LCS is an implementation based on the traditional Longest Common Subsequence algorithm.

It contains reference implementations working slow but correct.

Also some utility methods are added to reformat the result.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the LCS computation.  Use one of these per concurrent
LCS() call.

=back

=head2 METHODS

=over 4


=item LCS(\@a, \@b)

Finds a Longest Common Subsequence, taking two arrayrefs as method
arguments. It returns an array reference of corresponding
indices, which are represented by 2-element array refs.

  # position  0 1 2
  my $a = [qw(a b  )];
  my $b = [qw(a b b)];

  my $lcs = LCS->LCS($a,$b);

  # same like
  $lcs = [
      [ 0, 0 ],
      [ 1, 1 ]
  ];

=item LLCS(\@a, \@b)

Calculates the length of the Longest Common Subsequence.

  my $llcs = LCS->LLCS( [qw(a b)], [qw(a b b)] );
  print $llcs,"\n";   # prints 2

  # is the same as
  $llcs = scalar @{LCS->LCS( [qw(a b)], [qw(a b b)] )};

=item allLCS(\@a, \@b)

Finds all Longest Common Subsequences. It returns an array reference of all
LCS.

  # This example has 2 possible alignments:

  # 1st alignment
  # position  0 1 2
  #        qw(a b  )
  #        qw(a b b)

  # 2nd alignment
  # position  0 1 2
  #          (a   b)
  #          (a b b)

  my $all_lcs = LCS->allLCS( [qw(a b)], [qw(a b b)] );

  # same as
  $all_lcs = [
    [             # 1st alignment
      [ 0, 0 ],
      [ 1, 1 ]
    ],
    [             # 2nd alignment
      [ 0, 0 ],
      [ 1, 2 ]
    ]
  ];

The purpose is mainly for testing LCS algorithms, as they only return one of the possible
optimal solutions. If we want to know, that the result is one of the optimal solutions, we need
to test, if the solution is part of all optimal LCS:

  use Test::More;
  use Test::Deep;
  use LCS;
  use LCS::Tiny;

  cmp_deeply(
    LCS::Tiny->LCS(\@a,\@b),
    any( @{LCS->allLCS(\@a,\@b)} ),
    "Tiny::LCS $a, $b"
  );

=item lcs2align(\@a, \@b, $LCS)

Returns the two sequences aligned, missing positions are represented as empty strings.

  use Data::Dumper;
  use LCS;
  print Dumper(
    LCS->lcs2align(
      [qw(a   b)],
      [qw(a b b)],
      LCS->LCS([qw(a b)],[qw(a b b)])
    )
  );
  # prints

  $VAR1 = [
            [
              'a',
              'a'
            ],
            [
              '',
              'b'
            ],
            [
              'b',
              'b'
            ]
  ];

=item align(\@a,\@b)

Returns the same as lcs2align() via calling LCS() itself.

=item sequences2hunks($a, $b)

Transforms two array references of scalars to an array of hunks (two element arrays).

=item hunks2sequences($hunks)

Transforms an array of hunks to two arrays of scalars.

  use Data::Dumper;
  use LCS;
  print Dumper(
    LCS->hunks2sequences(
      LCS->LCS([qw(a b)],[qw(a b b)])
    )
  );
  # prints (reformatted)
  $VAR1 = [ 0, 1 ];
  $VAR2 = [ 0, 2 ];


=item align2strings($hunks, $gap_character)

Returns two strings aligned with a gap character. The default gap character is '_'.

  use Data::Dumper;
  use LCS;
  print Dumper(
    LCS->align2strings(
      LCS->lcs2align([qw(a b)],[qw(a b b)],LCS->LCS([qw(a b)],[qw(a b b)]))
    )
  );
  $VAR1 = 'a_b';
  $VAR2 = 'abb';


=item fill_strings($string1, $string2, $fill_character)

Returns both strings filling up the shorter with $fill_character to the same length.

The default $fill_character is '_'.

=item clcs2lcs($compact_lcs)

Convert compact LCS to LCS.

=item lcs2clcs($compact_lcs)

Convert LCS to compact LCS.

=item max($i, $j)

Returns the maximum of two numbers.

=back

=head2 EXPORT

None by design.

=head1 STABILITY

Until release of version 1.00 the included methods, names of methods and their
interfaces are subject to change.

Beginning with version 1.00 the specification will be stable, i.e. not changed between
major versions.

=head1 REFERENCES

Ronald I. Greenberg. Fast and Simple Computation of All Longest Common Subsequences,
http://arxiv.org/pdf/cs/0211001.pdf

Robert A. Wagner and Michael J. Fischer. The string-to-string correction problem.
Journal of the ACM, 21(1):168-173, 1974.


=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/LCS>

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT

Copyright 2022 Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

