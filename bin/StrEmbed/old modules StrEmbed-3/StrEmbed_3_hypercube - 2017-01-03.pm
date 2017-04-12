#!/usr/bin/perl

# StrEmbed::StrEmbed_3_hypercube.pm
# HHC - 2016-11-03 - cleaned up and changed as a perl module
# HHC - 2016-11-14
# HHC - 2016-11-18 - double_up_double_up.pl - hypercube_double.pm
# HHC - 2016-11-22 - double_up_double_up.pl - hypercube_binary_encording.pm
# HHC - 2016-11-23 - hypercube_bin_encoding_only
# HHC - 2016-11-29 - hypercube_sorted.pl - StrEmbed/hypercube_sorted_binary_encoded.pm
# HHC - 2016-11-29 - StrEmbed3.pl <- StrEmbed3_lattice.pm + StrEmbed3_gui.pm + StrEmbed3_STEP.pm
# HHC - 2016-12-06 - filename is now StrEmbed/StrEmbed_3_hypercube.pm
# HHC - 2016-12-10 - changed directory tree structure, ready to be uploaded to GitHub
# HHC - 2016-12-19 - no more double/triple number of elements
# HHC - 2017-01-03 - back in Leeds

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

# print "hypercube module\n\n";

return 1;

###
### subroutines
###

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

sub testing_meet_n_join {
    my $a = int rand() * (1 << $max);
    my $b = int rand() * (1 << $max);
    my $c = int rand() * (1 << $max);
    my $d = int rand() * (1 << $max);
    my $meet;
    my $join;
    $meet = &meet($a, $b, $c, $d);
    $join = &join($a, $b, $c, $d);
    print "$a - $b - $c - $d [meet = $meet] [join = $join]\n";
    $meet = &meet($a, $b, $c);
    $join = &join($a, $b, $c);
    print "$a - $b - $c [meet = $meet] [join = $join]\n";
    $meet = &meet($a, $b);
    $join = &join($a, $b);
    print "$a - $b [meet = $meet] [join = $join]\n";
    print "\n";
}

sub meet {
    my @list = @_;
    my $e = pop @list;
    $e |= $_ foreach @list;
    return $e;
}

sub join {
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

###
### to be deleted
###

sub print_cube_XXX {
    my $filename = "cube" . $max . ".lat";
    open(my $FH, ">$filename") or die "Can't open file: $!";
    print $FH "(", &name($max), "\n";
    foreach (keys %hypercube) {
        print $FH "($_ (@{$hypercube{$_}}))\n";
    }
    print $FH ")\n";
    close $FH;
}