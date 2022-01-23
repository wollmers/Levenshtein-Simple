package Levenshtein::Simple;

use strict;
use warnings;

use 5.006;
our $VERSION = '0.01';

binmode(STDOUT,":encoding(UTF-8)");
binmode(STDERR,":encoding(UTF-8)");

sub new {
    my $class = shift;
    my $self = bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;

    unless ( $self->{'gapchar'} ) { $self->{'gapchar'} = '_'; }

    unless ( defined $self->{'editchars'} && ( length($self->{'editchars'}) == 4) ) {
        $self->{'editchars'} = '=~-+';
    }
    my @editchars  = split( //, $self->{'editchars'} );
    $self->{'eq'}  = $editchars[0];
    $self->{'sub'} = $editchars[1];
    $self->{'del'} = $editchars[2];
    $self->{'ins'} = $editchars[3];

    return $self;
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
    # uncoverable condition false
    if ( !$m || !$n ) { return ( $m ? $m : $n ) }

    my @c = ();

    # init first row of matrix @c
    for my $j ( 0 .. $n ) { $c[0][$j] = $j; }

    my ($i, $j);

    # NOTE: comparison in @c uses index-origin 1
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

sub matrix {
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

    my $c = $self->matrix( $X, $Y );

    my $ses = [];

    my $i = $m;
    my $j = $n;

    while ($i > 0 && $j > 0) {
        my $min = $self->min3(
        	$c->[$i-1][$j-1],
        	$c->[$i-1][$j  ],
        	$c->[$i  ][$j-1]
        );

        if ( $c->[$i-1][$j-1] == $min && (($c->[$i-1][$j-1] + 0 ) == $c->[$i][$j]) ) {
            unshift @$ses, [$i-1, $j-1, $self->{'eq'}];
            $i--; $j--;
        }
        elsif ($i > 0 && ($c->[$i-1][$j] + 1 == $c->[$i][$j]) ) {
            unshift @$ses, [$i-1, -1, $self->{'del'}];
            $i--;
        }
        elsif ($j > 0 && ($c->[$i][$j-1] + 1 == $c->[$i][$j]) ) {
            unshift @$ses, [-1, $j-1, $self->{'ins'}];
            $j--;
        }
        elsif ($i > 0 && $j > 0 && ($c->[$i-1][$j-1] + 1  == $c->[$i][$j]) ) {
            unshift @$ses, [$i-1, $j-1, $self->{'sub'}];
            $i--; $j--;
        }
    }
    while ($i > 0) {
        unshift @$ses, [$i-1, -1, $self->{'del'}];
        $i--;
    }
    while ($j > 0) {
        unshift @$ses, [-1, $j-1, $self->{'ins'}];
        $j--;
    }
    return $ses;
}

sub all_ses {
    my ($self, $X, $Y) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    if ( !$m && !$n ) { return [[]] }

    my $c = $self->matrix($X, $Y);

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
                if    ($path->[0][2] eq $self->{'del'}) { $i--; }
                elsif ($path->[0][2] eq $self->{'ins'}) { $j--; }
                else  { $i--; $j--; }
            }

            # deletion
            if ($i > 0 && $c->[$i-1][$j] + 1 == $c->[$i][$j]) {
                if ($i == 1 && $j <= 1) {
                    push @$result, [ [0, 0, $self->{'del'}], @$path ];
                }
                else {
                    push @temp, [ [$i-1, $j-1, $self->{'del'}], @$path ];
                }
            }
            # insertion
            if ($j > 0 && $c->[$i][$j-1] + 1 == $c->[$i][$j]) {
                if ($i <= 1 && $j == 1) {
                    push @$result, [ [0, 0, $self->{'ins'}], @$path ];
                }
                else {
                    push @temp, [[$i-1, $j-1, $self->{'ins'}], @$path];
                }
            }
            # equal = match
            if ($i > 0 && $j > 0 && $c->[$i-1][$j-1] == $c->[$i][$j]) {
                if ($i == 1 && $j == 1) {
                    push @$result, [ [0, 0, $self->{'eq'}], @$path ];
                }
                else {
                    push @temp, [ [$i-1, $j-1, $self->{'eq'}], @$path ];
                }
            }
            # substitution
            if ($i > 0 && $j > 0 && $c->[$i-1][$j-1] + 1  == $c->[$i][$j]) {
                if ($i == 1 && $j == 1) {
                    push @$result, [ [0, 0, $self->{'sub'}], @$path ];
                }
                else {
                    push @temp, [[$i-1, $j-1, $self->{'sub'}], @$path];
                }
            }
        }
        @$paths = @temp;
    }

    return [ map { $self->ses2none($_) } @$result ];
}

sub format_matrix {
    my ($self, $X, $Y ) = @_;

    return $self->_format_matrix( $X, $Y, $self->matrix( $X, $Y ) );
}

sub _format_matrix {
    my ($self, $X, $Y, $c) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    my $max_length = ($m >= $n) ? $m : $n;
    my $l = length($max_length) + 1; # length in chars plus space

    my $out = '';

    $out .= "\n". 'Levenshtein matrix of "'
        . join('',@$X).'" versus "' . join('',@$Y) . '"' . "\n";
    $out .=  "\n";
    $out .=  sprintf("%${l}s",' ') . sprintf("%${l}s",' ');
    for my $j (0..$n-1) {
        $out .=  sprintf("%${l}s",$Y->[$j]);
    }
    $out .=  "\n" . sprintf("%${l}s",' ');
    for my $j (0..$n) {
        $out .=  sprintf("%${l}s",$c->[0][$j]);
    }
    $out .=  "\n";
    for my $i (1..$m) {
        $out .=  sprintf("%${l}s",$X->[$i-1]);
        for my $j (0..$n) {
            $out .=  sprintf("%${l}s", $c->[$i][$j]);
        }
        $out .= "\n";
    }
    return $out;
}

sub format_alignment_path {
    my ($self, $X, $Y ) = @_;

    return $self->_format_alignment_path( $X, $Y, $self->ses( $X, $Y ) );
}

sub _format_alignment_path {
    my ($self, $X, $Y, $hunks) = @_;

    my $line = '[ ';
    for my $hunk (@$hunks) {
        $line .= '[' . join(',', @$hunk) . '],';
    }
    $line .=  ' ]';
    return $line;
}

sub format_alignment {
    my ($self, $X, $Y, $gap) = @_;

    return $self->_format_alignment( $X, $Y, $self->ses( $X, $Y ), $gap );
}

sub _format_alignment {
    my ($self, $X, $Y, $hunks, $gap) = @_;

    $gap = (defined $gap) ? $gap : $self->{'gapchar'};

    my $line1 = '';
    my $line2 = '';
    my $line3 = '';

    for my $hunk (@$hunks) {
        $line2 .= $hunk->[2];
        if ($hunk->[2] eq $self->{'del'}) {
            $line1 .= $X->[$hunk->[0]];
            $line3 .= $gap;
        }
        elsif ($hunk->[2] eq $self->{'ins'}) {
            $line1 .= $gap;
            $line3 .= $Y->[$hunk->[1]];
        }
        elsif ($hunk->[2] eq $self->{'sub'}) {
            $line1 .= $X->[$hunk->[0]];
            $line3 .= $Y->[$hunk->[1]];
        }
        else {
            $line1 .= $X->[$hunk->[0]];
            $line3 .= $Y->[$hunk->[1]];
        }
    }

    my $metrics = $self->_metrics( $X, $Y, $hunks );

    $line2 .= $self->format_metrics($metrics);

    return join("\n", ($line1, $line2, $line3)) . "\n";
}

sub format_metrics {
    my ($self, $metrics ) = @_;

    my $string =
    	' distance: ' . $metrics->{'distance'} .
    	' M: ' . $metrics->{'matches'} .
    	' S: ' . $metrics->{'substitutions'} .
    	' D: '. $metrics->{'deletes'} .
    	' I: ' . $metrics->{'inserts'} .
    	' Err: '  . sprintf('%.2f', $metrics->{'error-rate'}) .
    	' Acc: '  . sprintf('%.2f', $metrics->{'accuracy'}) .
    	' nErr: ' . sprintf('%.2f', $metrics->{'normalised error-rate'}) .
    	' Sim: ' . sprintf('%.2f', $metrics->{'similarity'})
    	;
}

sub metrics {
    my ($self, $X, $Y ) = @_;

    return $self->_metrics( $X, $Y, $self->ses( $X, $Y ) );
}

sub _metrics {
    my ($self, $X, $Y, $hunks) = @_;

    my $match      = 0;
    my $substitute = 0;
    my $delete     = 0;
    my $insert     = 0;

    my $metrics = {
        'len1'          => scalar(@$X),
        'len2'          => scalar(@$Y),
        'matches'       => 0,
        'substitutions' => 0,
        'deletes'       => 0,
        'inserts'       => 0,
        'distance'      => 0,
        'len-align'     => 0,
        'error-rate'    => 2.0, # default for len1 == 0
        'accuracy'      => 0,
        'normalised error-rate' => 0,
        'normalised similarity' => 1, # default for both empty
        'similarity'    => 1, # default for both empty
    };

    for my $hunk (@$hunks) {
        if ($hunk->[2] eq $self->{'del'}) {
        	$metrics->{'deletes'}++;
        }
        elsif ($hunk->[2] eq $self->{'ins'}) {
            $metrics->{'inserts'}++;
            $insert++;
        }
        elsif ($hunk->[2] eq $self->{'sub'}) {
            $metrics->{'substitutions'}++;
        }
        else {
        	$metrics->{'matches'}++;
        }
    }

    $metrics->{'distance'}
        = $metrics->{'substitutions'} + $metrics->{'deletes'} + $metrics->{'inserts'};

    # CER = ( S + D + I ) / ( M + S + D )
    $metrics->{'error-rate'}
        = $metrics->{'distance'} / $metrics->{'len1'} if ( $metrics->{'len1'} );

    $metrics->{'len-align'} = $metrics->{'matches'} + $metrics->{'distance'};

    # Accuracy = M       / ( M    + S + D + I )
    $metrics->{'accuracy'} = $metrics->{'matches'} / $metrics->{'len-align'};

    $metrics->{'normalised error-rate'} = 1 - $metrics->{'accuracy'};

    my $max_len = ($metrics->{'len1'} >= $metrics->{'len2'})
        ? $metrics->{'len1'} : $metrics->{'len2'};

    $metrics->{'normalised similarity'}
        = 1 - ( $metrics->{'distance'} / $max_len )  if ( $max_len );

    # similarity = matches * 2 / (length1 + length2)
    $metrics->{'similarity'}
        = $metrics->{'matches'} * 2 / ($metrics->{'len1'} + $metrics->{'len2'})
            if ( $metrics->{'len1'} ||  $metrics->{'len2'} );

    return $metrics;
}

sub align2strings {
  	my ($self, $hunks, $gap) = @_;

  	$gap = (defined $gap) ? $gap : $self->{'gapchar'};

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

  	return [$a, $b];
}

sub ses2align {
    my ($self, $X, $Y, $hunks) = @_;

    my $align = [];

    for my $hunk (@$hunks) {
        if ($hunk->[2] eq $self->{'del'}) {
            push @$align,[ $X->[$hunk->[0]], '' ];
        }
        elsif ($hunk->[2] eq $self->{'ins'}) {
            push @$align,[ '', $Y->[$hunk->[1]] ];
        }
        else {
            push @$align,[ $X->[$hunk->[0]], $Y->[$hunk->[1]] ];
        }
    }
    return $align;
}

sub ses2none {
    my ($self, $hunks) = @_;

    my $none  = -1;
    my $align = [];

    for my $hunk (@$hunks) {
        if ($hunk->[2] eq $self->{'del'}) {
            push @$align,[ $hunk->[0], $none, $hunk->[2] ];
        }
        elsif ($hunk->[2] eq $self->{'ins'}) {
            push @$align,[ $none, $hunk->[1], $hunk->[2] ];
        }
        else {
            push @$align,[ $hunk->[0], $hunk->[1], $hunk->[2] ];
        }
    }
    return $align;
}

sub ses2compact {
    my ($self, $ses) = @_;

    my $compact = '';

    for my $hunk (@$ses) { $compact .= $hunk->[2]; }

    return $compact;
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

<a href='http://cpants.cpanauthors.org/dist/Levenshtein-Simple'><img src='http://cpants.cpanauthors.org/dist/Levenshtein-Simple.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Levenshtein-Simple"><img src="https://badge.fury.io/pl/Levenshtein-Simple.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use Levenshtein::Simple;

  my $lev = Levenshtein::Simple->new();

  # we need arrays of strings
  my @seq1 = split( //, 'sue' );
  my @seq2 = split( //, 'use' );

  my $distance = $lev->distance( [ @seq1 ], [ @seq2 ] );

  print "distance: $distance", "\n";
  distance: 2

  my $ses = $lev->distance( [ @seq1 ], [ @seq2 ] );

  # $ses now contains an arrayref of the shortest edit script

  # same as
  $ses = [
    [0,0,+],
    [0,1,=],
    [1,1,-],
    [2,2,=],
  ];

  # generate all shortest edit scripts
  my $all_ses = $lev->all_ses( [ @seq1 ], [ @seq2 ] );

  # same as (reformatted)
  $all_ses = [
    [ [0,0,~],          [1,1,~], [2,2,=] ],
    [ [0,0,+], [0,1,=], [1,1,-], [2,2,=] ],
    [ [0,0,-], [1,0,=], [1,1,+], [2,2,=] ],
  ];

  # print the match matrix
  print $lev->format_matrix( [ @seq1 ], [ @seq2 ] );

  Levenshtein matrix of "sue" versus "use"

      u s e
    0 1 2 3
  s 1 1 1 2
  u 2 1 2 2
  e 3 2 2 2

  # print alignment
  print $lev->format_alignment( [ @seq1 ], [ @seq2 ] );

  _sue
  +=-=  distance:2 M:2 S:0 D:1 I:1 ERR:0.67 Acc:0.50 nCER:0.50
  us_e

  # print all alignments
  my $solutions  = $lev->all_ses( [ @seq1 ], [ @seq2 ] ) ;
  for my $solution (@$solutions) {
    print $lev->_format_alignment( [ @seq1 ], [ @seq2 ] , $solution ), "\n";
  }

  sue
  ~~=  distance:2 M:1 S:2 D:0 I:0 ERR:0.67 Acc:0.33 nCER:0.67
  use

  _sue
  +=-=  distance:2 M:2 S:0 D:1 I:1 ERR:0.67 Acc:0.50 nCER:0.50
  us_e

  su_e
  -=+=  distance:2 M:2 S:0 D:1 I:1 ERR:0.67 Acc:0.50 nCER:0.50
  _use


=head1 DESCRIPTION

Levenshtein::Simple is an implementation based on the traditional Levenshtein algorithm.

It allows to compare two sequences and calculate the differences and where they are located.
Main applications are spelling correction or DNA analysis.

Sequences can consist of characters, graphemes, words, lines or anything that is comparable
as string. Therefore we use array references (arrays of strings) as input and do not limit
to strings as most implementations do.

It contains reference implementations working moderately fast for the slow algorithm but
correct. Internally it uses a match matrix and has exponential run time complexity O(m*n).
This means, that the comparison of two sequences of length 10 need 10 * 10 = 100 iterations,
and of length 100 need 100 * 100 = 10,000 iterations.

Also some utility methods are added to format the results for diagnosis or exploration.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the Levenshtein computation. The methods need object mode.

  my $lev = Levenshtein::Simple->new(
    {
        'gapchar'   => '_',    # default
        'editchars' => '=~-+', # default
    }
  );

Parameters are optional.

- 'gapchar' must be a character. Choose another one if more convenient.

- 'editchars' must be a string of 4 unique characters meaning in this order

  '=' match (equal)
  '~' substitution
  '-' deletion
  '+' insertion

=back

=head2 METHODS

=over 4

=item ses(\@a, \@b)

Finds a Shortest Edit Script (SES), taking two arrayrefs as method
arguments. It returns an array reference of corresponding
indices, which are represented by 3-element array refs.

  # position  0 1 2 3
  my $a = [qw(g o l d)];
  my $b = [qw(g l o w)];

  my $ses = $lev->ses($a,$b);

  # same as
  $ses = [
    [ 0, 0, '=' ], # match equal
    [ 0, 1, '+' ], # insertion
    [ 1, 2, '=' ], # match equal
    [ 2, 3, '~' ], # substitution
    [ 3, 3, '-' ]  # deletion
  ];

NOTE: In case of deletion or insertion one of the indices is not undef or -1.

=item distance(\@a, \@b)

Calculates the length of the edit distance.

  my $distance = $lev->distance( [ qw(g o l d) ], [ qw(g l o w) ] );
  print $distance,"\n";   # prints 3

Distance = substitutions + insertions + deletions.

=item all_ses(\@a, \@b)

Finds all Shortest Edit Scripts. It returns an array reference of all
SES.

  # This example has 3 possible alignments:

  my $all_ses = $lev->all_ses( [ qw(s u e) ], [ qw(u s e) ] );

  # same as
  $all_ses = [
    [ [0,0,'~'],            [1,1,'~'], [2,2,'='] ],
    [ [0,0,'+'], [0,1,'='], [1,1,'-'], [2,2,'='] ],
    [ [0,0,'-'], [1,0,'='], [1,1,'+'], [2,2,'='] ],
  ];

Note that all SES are optimal in the sense of minimal distance. Levenshtein minimises distance.
In contrast LCS maximises matches.

CAUTION: Use this method only with short sequences as it can have extreme runtimes with longer ones.

The purpose is mainly for testing Levenshtein algorithms, as they only return one of the possible
optimal solutions. If we want to know, that the result is one of the optimal solutions, we need
to test, if the solution is part of all optimal SES:

  use Test::More;
  use Test::Deep;
  use Levenshtein::Simple;

  my $lev = Levenshtein::Simple->new();

  cmp_deeply(
    $lev->ses( $X ,$Y ),
    any( @{ $lev->all_ses($X, $Y) } )
  );

=item matrix(\@a, \@b)

Calculates the match matrix as 2-dimensional array length1+1 (rows) x length2+1 (columns).
Note that the first element of a sequence has index 1 in the matrix, but index 0 in the
original sequence array.

  my $matrix = $lev->matrix( [qw(g o l d)], [qw(g l o w)] );

Returns the matrix as array reference.

=item format_matrix(\@a, \@b)

Formats the matrix human readable. Returns a string of concatenated lines.

  print $lev->format_matrix( [qw(g o l d)], [qw(g l o w)] );

  Levenshtein matrix of "gold" versus "glow"

       g l o w
     0 1 2 3 4
   g 1 0 1 2 3
   o 2 1 1 1 2
   l 3 2 1 2 2
   d 4 3 2 2 3

=item _format_matrix(\@a, \@b, $matrix)

  my $matrix = $lev->matrix( [qw(g o l d)], [qw(g l o w)] );
  print $lev->_format_matrix( [qw(g o l d)], [qw(g l o w)], $matrix );

=item format_alignment_path(\@a, \@b)

Formats an SES human readable in pseudo array notation.

  my $alignment_path = $lev->format_alignment_path( [qw(g o l d)], [qw(g l o w)]);
  print $alignment_path,"\n";

  [ [0,0,=],[0,1,+],[1,2,=],[2,3,~],[3,3,-], ]

=item _format_alignment_path(\@a, \@b, $ses)

  my $ses = $lev->ses( [qw(g o l d)], [qw(g l o w)]);
  my $alignment_path
    = $lev->_format_alignment_path( [qw(g o l d)], [qw(g l o w)], $ses );
  print $alignment_path,"\n";

=item format_alignment(\@a, \@b, $gap_character)

Formats an SES into printable lines. Default for $gap_character is '_'.

Returns a string of concatenated lines.

  print $lev->format_alignment( [qw(g o l d)], [qw(g l o w)] );

  g_old
  =+=~-  distance: 3 M: 2 S: 1 D: 1 I: 1 Err: 0.75 Acc: 0.40 nErr: 0.60
  glow_

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

Vladimir I. Levenshtein. Binary codes capable of correcting deletions, insertions, and reversals.
Soviet Physics Doklady, 10(8):707–710, 1966.
Original in Russian in Doklady Akademii Nauk SSSR, 163(4):845–848, 1965.

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Levenshtein-Simple>

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

L<Text::Levenshtein> Accepts only strings
L<Text::Levenshtein::BV> Fast implementation in pure Perl

=cut

