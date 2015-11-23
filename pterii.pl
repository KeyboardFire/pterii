#!/usr/bin/env perl

use 5.10.0;
use strict;
use warnings;

my $code = join('', <>);

my @tokens;
while ($code =~ m/
                 ([-+*\/%><!.^=|&~:?A-LN-RT-XZ,;()\[\]{} ]      # single char
                 | [fhjkmnqtvwxyz]|[a-z].                       # function
                 | (["']) (?:\\.|(?!\2).)*\2                    # quote
                 | [0-9]+                                       # number
                 | M(.)   (?:\\.|(?!\3).)*\3                    # m regex
                 | [SY](.)(?:\\.|(?!\4).)*\4(?:(?!\4).|\\.)*\4  # s, y regex
                 | [\$@#](?:[A-Za-z]+|.)                        # variable
                 | \\s.|\\.                                     # backslash seq
                 )/gx) {
    push @tokens, $1;
}

# the stack (1-letter variable name in case someone wants to use it in the
# Pterii code
my @s = ();
# args used by almost every single operator/function
my @args = ();
# "grab args" -- update the @args variable
sub ga {
    # TODO cut off at last stack div
    @args = @s;
    @s = ();
}

my $comptoken = sub {
    my $token = shift;

    # let's handle easy constants first
    my $constmap = {
        '+' => 'ga; push(@s, 0); $s[-1] += $_ foreach @args;',
        '-' => 'ga; push(@s, shift @args); $s[-1] -= $_ foreach @args;',
        '*' => 'ga; push(@s, 0); $s[-1] *= $_ foreach @args;',
        '/' => 'ga; push(@s, shift @args); $s[-1] /= $_ foreach @args;',
        ' ' => '',
        'sa' => 'ga; say @args;',
    }->{$_};
    return $constmap if $constmap;

    # ok so it's more complicated than that ;(
    if ($token =~ /^[0-9]+$/) {
        return "push(\@s, $token);";
    }
};

my $compiled = join(' ', map $comptoken->($_), @tokens);
eval $compiled;
print @s;
