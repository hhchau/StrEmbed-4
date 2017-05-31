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

# StrEmbed::StrEmbed_4_hypercube.pm
# StrEmbed-3 release A - HHC 2017-01-06
# HHC - 2017-01-09 - post Release A
# HHC - 2017-03-07 - starting StrEmbed-4
# HHC - 2017-03-24
# HHC - 2017-05-26 Version 4 Release C

require 5.002;
# use warnings qw(FATAL);
use strict;
use Set::Partition;

my $max;  # hypercube size
my $i;    # current n
my %hypercube;
my %elements_at_height;
my @array;

return 1;

###
### subroutines
###

sub hypercube_initialise {
    # $max = "";
    # $i = "";
    # %hypercube = ();
    # %elements_at_height = ();
    # @array = ();
}

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
    my $max = shift;   # setting $max for the first and only time in this hypercube module
    &calcualte_elements_for_each_height($max);
    my $ref_array = &hypercube_height_n_position;
    return $ref_array;
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

sub join {    # clash with CORE::join ???
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

sub calcualte_elements_for_each_height {
    ### i/p - $max is assumed as a global variable for the size of n-hypercube lattice
    ### o/p - %elements_at_height via enumerate
    $max = shift;
    my $k = int $max / 2;
    &enumerate($max, $_) foreach 0..$k;    # 0..k is the lower half, its dual is the upper half
}

sub enumerate {
    ### partition of a set
    ### o/p = %elements_at_height
    my ($n, $h) = @_;

    if ($h == 0) {
        @{$elements_at_height{$h}} = 0;              # height = 0
        @{$elements_at_height{$n}} = (1 << $n) - 1;  # height = n, dual; 1 << $n == 2**$n - 1
    } else {
        my @list = ();
        push @list, $_ foreach 0..$n-1;  # a list of all digit positions

        my $set = Set::Partition->new(
            list      => [@list],
            partition => [$h, $n-$h],  # specify only the first partition/block, the second is $n-$h implicitly
        );

        while (my $ref_first_block = $set->next) {
            my $element;
            $element += 1 << $_ foreach @{@$ref_first_block[0]};                                 # worry about the first block only and put 1 in each digit
            push @{$elements_at_height{$h}}, $element;                                           # height = r
            push @{$elements_at_height{$n-$h}}, ((1 << $n) - 1 - $element) unless $h == $n / 2;  # height = n-r, dual unless the middle odd one
        }
        @{$elements_at_height{$h}} = reverse @{$elements_at_height{$h}};                         # make visualisation less messy
    }  # end if..then..else
}

sub hypercube_height_n_position {
    ### i/p - %elements_at_height
    ### o/p - \@array

    @array = ();
    while (my ($height, $ref_elements) = each %elements_at_height) {
        my $j = 0;
        my @list = @$ref_elements;
        foreach my $e (@$ref_elements) {
            # print "[$height][$j] = $e\n";
            $array[$height][$j] = $e;
            $j++;
        }
    }
    return \@array;
}

sub hypercube_get_array {
    return \@array;
}