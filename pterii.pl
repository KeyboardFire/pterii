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
        '+'  => 'ga; push @s, shift @args; $s[-1] +=  $_ foreach @args;',
        '-'  => 'ga; push @s, shift @args; $s[-1] -=  $_ foreach @args;',
        '*'  => 'ga; push @s, shift @args; $s[-1] *=  $_ foreach @args;',
        '/'  => 'ga; push @s, shift @args; $s[-1] /=  $_ foreach @args;',
        '%'  => 'ga; push @s, shift @args; $s[-1] %=  $_ foreach @args;',
        '^'  => 'ga; push @s, shift @args; $s[-1] **= $_ foreach @args;',
        '.'  => 'ga; push @s, shift @args; $s[-1] .=  $_ foreach @args;',
        '!'  => 'ga; push @s, 1;           $s[-1] &= !$_ foreach @args;',
        '&'  => 'ga; push @s, 1;           $s[-1] &=  $_ foreach @args;',
        '|'  => 'ga; push @s, 0;           $s[-1] |=  $_ foreach @args;',
        ' '  => '',
        'ab' => 'ga; push @s, map abs,      @args;',
        'co' => 'ga; push @s, map cos,      @args;',
        'ex' => 'ga; push @s, map exp,      @args;',
        'lc' => 'ga; push @s, map lc,       @args;',
        'pe' => 'ga; push @s, map eval,     @args;',
        'pr' => 'ga;          map print,    @args;',
        'sa' => 'ga;          map say,      @args;',
        'si' => 'ga; push @s, map sin,      @args;',
        'sl' => 'ga;          map sleep $_, @args;',
        'sq' => 'ga; push @s, map sqrt,     @args;',
        'uc' => 'ga; push @s, map uc,       @args;',
        'x'  => 'ga; push @s, $args[0] x $args[1];',
        '('  => '(', ')' => ')', '[' => '[', ']' => ']', '{' => '{', '}' => '}',
        #'\\e' => 'else', '\\E' => 'elsif', '\\f' => 'for', '\\i' => 'if',
        #'\\l' => 'last', '\\n' => 'next', '\\r' => 'return', '\\u' => 'until',
        #'\\U' => 'unless', '\\w' => 'while',
    }->{$_};
    return $constmap if $constmap;

    # ok so it's more complicated than that ;(
    if ($token =~ /^([0-9]+|".*"|\$.*|\@.*)$/) {
        return "push(\@s, $token);";
    }
};

my $compiled = join(' ', map $comptoken->($_), @tokens);
eval $compiled;
print @s;
