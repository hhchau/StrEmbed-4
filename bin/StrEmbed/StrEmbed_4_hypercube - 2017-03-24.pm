#!/usr/bin/perl

#    StrEmbed-4 - Embedding assembly structure on to a corresponding hypercube lattice
#    Copyright (C) 2017  University of Leeds
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# StrEmbed::StrEmbed_3_hypercube.pm
# StrEmbed-3 release A - HHC 2017-01-06
# HHC - 2017-01-09 - post Release A
# HHC - 2017-03-07 - starting StrEmbed-4

require 5.002;
use warnings;
use strict;
use Set::Partition;

our $max;  # $max is assumed as a global variable for the size of n-hypercube lattice

my $n;    # current n
my %hypercube;
my $name;
my %level;
my %elements_at_height;

return 1;

###
### subroutines
###

sub hypercube_return_chain {
    our @list = ();
    my ($sup, $inf) = @_;
    push @list, $inf;
    my $current = $inf;    # first one
    &hypercube_loop_chain($sup, $current);
    return @list;
}

sub hypercube_loop_chain {
    our @list;
    my ($sup, $current) = @_;
    my $ref_parents = &get_parents($current);
    my @parents = @{$ref_parents};
    SKIP: foreach my $parent (@parents) {
        my $covers = &hypercube_test_if_covers($sup, $parent);
        if ($covers) {
            $current = $parent;
            unshift @list, $parent;
            last SKIP;
        }
    }
    &hypercube_loop_chain($sup, $current) unless $sup eq $current;
}

sub hypercube_test_if_covers {
    my ($upper, $lower) = @_;
    my $odd_bit = ($upper & $lower) ^ $lower;
    return not $odd_bit;
}

sub hypercube_elements_at_height {
    my $h = shift;
    return @{$elements_at_height{$h}};
}

sub hypercube_corresponding_to_step_file {
    delete $hypercube{$_} for keys %hypercube;
    my $ref_all_elements_by_height = &calcualte_elements_for_each_height;
    my $ref_array = &hypercube_height_n_position;
    &tk_hasse($ref_array);
}

sub hypercube_those_at_height {
    my $n = shift;
    return @{$elements_at_height{$n}};
}

sub get_parents_children {
    my $e = shift;
    my @parents = ();
    my @children = ();
    foreach my $index (0..$max-1) {
        my $twos_power = 1 << $index;     # bitwise operation
        my $and    = $e & $twos_power;    # bitwise operation
        my $parent = $e | $twos_power;    # bitwise operation
        my $child  = $e - $twos_power;
        if ($and eq 0) {
            push @parents, $parent;
        } else {
            push @children, $child;
        }
    }
    return \@parents, \@children;
}

sub get_parents {
    my $e = shift;
    my @parents = ();
    foreach my $index (0..$max-1) {
        my $twos_power = 1 << $index;     # bitwise operation
        my $and    = $e & $twos_power;    # bitwise operation
        my $parent = $e | $twos_power;    # bitwise operation
        push @parents, $parent unless $and;
    }
    return \@parents;
}

sub join {
    my @list = @_;
    my $e = pop @list;
    $e |= $_ foreach @list;
    return $e;
}

sub meet {
    my @list = @_;
    my $e = pop @list;
    $e &= $_ foreach @list;
    return $e;
}

sub enquiry {
    my @list = ();
    push @list, int rand() * 2**$max foreach (1..5);
    foreach my $e (@list) {
        my ($ref_parents, $ref_children) = &get_parents_children($e);
        my @parents  = @$ref_parents;
        my @children = @$ref_children;
        print "($e (@parents))\n";
        print "\t\t((@children) $e)\n";    
    }
}

sub print_hypercube_out_of_order {
    print "(", &name($max), "\n";
    for my $e (0..2**$max-1) {
        my $ref_parents = &get_parents($e);
        print "($e (@$ref_parents))\n";
    }
    print "\)\n";
}

sub print_hypercube_by_level {
    print "(", &name($max), "\n";
    foreach my $r (0..$max) {
        foreach my $e (@{$elements_at_height{$r}}) {
        my $ref_parents = &get_parents($e);
        my @parents  = @$ref_parents;
            print "($e (@parents))\n";
        }
    }
    print "\)\n";
}

sub name {
    my $n = shift || $max;
    if    ($n == 0) {return "point_" . $n;}
    elsif ($n == 1) {return "line_" . $n;}
    elsif ($n == 2) {return "square_" . $n;}
    elsif ($n == 3) {return "cube_" . $n;}
    elsif ($n == 4) {return "tessaract_" . $n;}
    else            {return "hypercube_" . $n;}
}

sub calcualte_elements_for_each_height {
    ### i/p - $max is assumed as a global variable for the size of n-hypercube lattice
    ### o/p - \%elements_at_height
    delete $elements_at_height{$_} for keys %elements_at_height;
    my $k = int $max / 2;
    foreach my $r (0..$k) {
        # print ">>> $r <<<\n";
        my $zeros = $max-$r;
        my $ones = $n;
        &enumerate($max, $r);
        # print "==> height $r has - (@{$elements_at_height{$r}})\n";
    }
    return \%elements_at_height;
}


sub enumerate {
    ### partition of a set
    ### o/p = %elements_at_height
    my ($n, $r) = @_;

    if ($r == 0) {
        @{$elements_at_height{$r}} = 0;              # height = 0
        @{$elements_at_height{$n}} = (1 << $n) - 1;  # height = n, dual
    } else {
        my @list = ();
        push @list, $_ foreach 0..$n-1;  # a list of all digit positions

        my $set = Set::Partition->new(
            list      => [@list],
            partition => [$r, $n-$r],  # specify only the first partition/block, the second is $n-$r implicitly
        );

        while (my $ref_first_block = $set->next) {
            my $element;
            $element += 1 << $_ foreach @{@$ref_first_block[0]};                                 # worry about the first block only and put 1 in each digit
            push @{$elements_at_height{$r}}, $element;                                           # height = r
            push @{$elements_at_height{$n-$r}}, ((1 << $n) - 1 - $element) unless $r == $n / 2;  # height = n-r, dual unless the middle odd one
        }
        @{$elements_at_height{$r}} = reverse @{$elements_at_height{$r}};  # make visualisation less messy
    }  # end if..else
}

sub hypercube_height_n_position {
    ### i/p - %elements_at_height
    ### o/p - \@array

    my @array;
    while (my ($height, $ref_elements) = each %elements_at_height) {
        my $j = 0;
        my @list = @$ref_elements;
        foreach my $e (@$ref_elements) {
            $array[$height][$j] = $e;
            $j++;
        }
    }
    return \@array;
}