#!/usr/bin/perl

#    StrEmbed-3 - Embedding assembly structure on to a corresponding hypercube lattice
#    Copyright (C) 2016  University of Leeds
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

# StrEmbed::StrEmbed_3_tree_editor.pm
# StrEmbed-3 release A - HHC 2017-01-06
# HHC - 2017-01-09 - post Release A
# HHC - 2017-03-07 - starting StrEmbed-4
# HHC - 2017-03-12 - insert before and insert after work correctly
# HHC - 2017-05-26 Version 4 Release C

require 5.002;
use warnings;
use strict;

our @assy_tree;
my $n = 0;

return 1;

sub biggest_current_n {
    my @assy_tree = @_;
    my %hash = ();
    foreach my $ref (@assy_tree) {
        my $this = $$ref[-1];
        $this =~ m/(ASSY_)(\d+)/;
        $n = $2 if defined $1 and defined $2 and $1 eq "ASSY_" and $n < $2;
    }
    return $n;
}

sub change_tree {
    ### i/p - \@assy_tree, $command, $from, $to
    ### o/p - @assy_tree
    my $ref_assy_tree = shift;
    my @assy_tree = @{$ref_assy_tree};
    my $command = shift;
    my $from = shift;
    my $to = shift;
    my @rest = @_;

    my $assy_tree_changed = 0;
    my @temp_tree = ();

    my @first = my @pre_from = split '\.', $from;
    my @second = my @pre_to = split '\.', $to;
    my $first_name = my $name_from = pop @pre_from;
    my $second_name = my $name_to = pop @pre_to;
    my @first_path = @pre_from;
    my @second_path = @pre_to;

    if ($command eq "insert_before" and &compare_array(\@first_path, \@second_path) ) {
        foreach my $ref_this (@assy_tree) {
            my @this = @{$ref_this};
            if ( &compare_array(\@this, \@first) ) {
                push @temp_tree, \@this if &compare_array(\@first, \@second);
            } elsif ( &compare_array(\@this, \@second) ) {
                push @temp_tree, \@first, \@second;
            } else {
                push @temp_tree, \@this;
            }
        }
        @temp_tree = &reorder_tree(\@first, \@temp_tree);
        @temp_tree = &reorder_tree(\@second, \@temp_tree);
        $assy_tree_changed = 1;
    } elsif ($command eq "insert_after" and &compare_array(\@first_path, \@second_path) ) {
        foreach my $ref_this (@assy_tree) {
            my @this = @{$ref_this};
            if ( &compare_array(\@this, \@first) ) {
                push @temp_tree, \@this if &compare_array(\@first, \@second);
            } elsif ( &compare_array(\@this, \@second) ) {
                push @temp_tree, \@second, \@first;
            } else {
                push @temp_tree, \@this;
            }
        }
        @temp_tree = &reorder_tree(\@first, \@temp_tree);
        @temp_tree = &reorder_tree(\@second, \@temp_tree);
        $assy_tree_changed = 1;
    } elsif ($command eq "adopt") {
        # need to exclude bare atoms
        foreach my $ref (@assy_tree) {
            my @this = my @pre_this = @{$ref};
            my $name_this = pop @pre_this;
            if ( &compare_array(\@this, \@first) ) {
                # skip [original] from
                # unless the same
                push @temp_tree, $ref if $name_from eq $name_to;
            } elsif ( &compare_array(\@this, \@second) ) {
                # put to and adopt from
                my @temp = (@pre_this, $name_this, $name_from);
                push @temp_tree, $ref;
                push @temp_tree, \@temp;
            } else {
                push @temp_tree, $ref;
            }
            $assy_tree_changed = 1;
        }
    } elsif ($command eq "assy" and &compare_array(\@first_path, \@second_path) ) {
        my @first_tree = ();
        my @second_tree = ();
        my @rest = ();
        $n = &biggest_current_n(@assy_tree);
        my $new = "ASSY_" . ++$n;
        ### first pass
        foreach my $ref (@assy_tree) {
            if (  &compare_array_first_few(\@first, $ref) and not &compare_array(\@first, $ref)  ) {
                my (undef, $ref_tail) = &compare_array_first_few(\@first, $ref);
                my @tail = @{$ref_tail};
                push @first_tree, [(@first_path, $new, $first_name, @tail)];
            } elsif (  &compare_array_first_few(\@second, $ref) and not &compare_array(\@second, $ref)  ) {
                my (undef, $ref_tail) = &compare_array_first_few(\@second, $ref);
                my @tail = @{$ref_tail};
                push @second_tree, [(@second_path, $new, $second_name, @tail)];
            } else {
                push @rest, $ref;
            }
        }
        ### second pass
        foreach my $ref (@rest) {
            my @this = my @this_path = @{$ref};
            my $this_name = pop @this_path;
            if ( &compare_array(\@this, \@first) ) {
                # first: do something
                push @temp_tree, [(@this_path, $new)];
                push @temp_tree, [(@this_path, $new, $first_name)], @first_tree;
                push @temp_tree, [(@this_path, $new, $second_name)], @second_tree;
            } elsif ( &compare_array(\@this, \@second) ) {
                # second: skip
            } else {
                # rest: copy verbatim
                push @temp_tree, $ref;
            }
            $assy_tree_changed = 1;
        }
    } elsif ($command eq "collapse") {
        foreach my $ref (@assy_tree) {
            my @this = my @this_path = @{$ref};
            my $name_this = pop @this_path;
            if ( &compare_array(\@this, \@first) ) {
                # skip whole line
            } else {
                # remove a name
                my @temp;
                foreach my $entity (@{$ref}) {
                    push @temp, $entity unless $entity eq $first_name;
                }
                push @temp_tree, \@temp;
            }
            $assy_tree_changed = 1;
        }
    } else {
        # do nothing
    }

    @temp_tree = @assy_tree unless $assy_tree_changed;
    return @temp_tree;
}

sub reorder_tree {
    my @second = @{$_[0]};
    my @array = @{$_[1]};
    my @before = ();
    my @middle = ();
    my @children = ();
    my @after = ();
    my @rest = ();
    my $found = 0;
    ### first pass
    foreach my $ref (@array) {
        if ( &compare_array_first_few(\@second, $ref) and not &compare_array(\@second, $ref) ) {
            push @children, $ref;
        } else {
            push @rest, $ref;
        }
    }
    ### second pass
    foreach my $ref (@rest) {
        my $match = &compare_array_first_few(\@second, $ref);
        if ($match) {
            push @middle, $ref;
            $found = 1;
        } else {
            if ($found) {
                push @after, $ref;
            } else {
                push @before, $ref;
            }
        }
    }
    return @before, @middle, @children, @after;
}

sub compare_array_first_few {
    ### i/p - \@first, \@second
    ### o/p - 
    my @first = @{$_[0]};
    my @second = @{$_[1]};
    my @rest = @second;
    return 0 if $#first > $#second;
    foreach my $i (0..$#first) {
        return 0 if $first[$i] ne $second[$i];
        shift @rest;
    }
    return (1, \@rest);
}

sub compare_array {
    ### i/p - \@first, \@second
    ### o/p - 
    my @first = @{$_[0]};
    my @second = @{$_[1]};
    return 0 if $#first != $#second;
    foreach my $i (0..$#first) {
        return 0 if $first[$i] ne $second[$i];
    }
    return 1;
}