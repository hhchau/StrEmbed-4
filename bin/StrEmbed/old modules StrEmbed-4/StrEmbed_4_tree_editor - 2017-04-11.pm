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

require 5.002;
use warnings;
use strict;

our @assy_tree;
my $n = 0;

return 1;

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

    # print "@{$_}\n" foreach @assy_tree;

    if ($command eq "up") {
        foreach my $ref_this (@assy_tree) {
            my @this = @{$ref_this};
            if ( &compare_array(\@this, \@first) ) {
                push @temp_tree, $ref_this if &compare_array(\@first, \@second);
            } elsif ( &compare_array(\@this, \@second) ) {
                push @temp_tree, \@first, \@second;
            } else {
                push @temp_tree, \@this;
            }
            $assy_tree_changed = 1;
        }
    } elsif ($command eq "down") {
    } elsif ($command eq "adopt") {
        # need to exclude bare atoms
        # print "\n";
        foreach my $ref (@assy_tree) {
            my @this = my @pre_this = @{$ref};
            my $name_this = pop @pre_this;
            # print "* @pre_this, $name_this\n";
            if ( &compare_array(\@this, \@first) ) {
                # skip [original] from
                # unless the same
                push @temp_tree, $ref if $name_from eq $name_to;
                # print "- @pre_this, $name_this\n";
            } elsif ( &compare_array(\@this, \@second) ) {
                # put to and adopt from
                my @temp = (@pre_this, $name_this, $name_from);
                push @temp_tree, $ref;
                push @temp_tree, \@temp;
                # print ". @{$ref}\n";
                # print "+ @temp\n";
            } else {
                # copy whatever it was (not from, not to)
                push @temp_tree, $ref;
                # print "  @pre_this, $name_this\n";
            }
            $assy_tree_changed = 1;
        }
    } elsif ($command eq "assy") {
        foreach my $ref (@assy_tree) {
            my @this = my @pre_this = @{$ref};
            my $name_this = pop @pre_this;
            if ( &compare_array(\@this, \@first) and @pre_this eq @pre_to) {
                my $new_name = "ASSY_" . ++$n;
                my @new_pre = (@pre_this, $new_name);
                my @new_from = (@new_pre, $name_from);
                my @new_to = (@new_pre, $name_to);
                # print "+ @new_pre\n";
                # print "+ @new_from\n";
                # print "+ @new_to\n";
                push @temp_tree, \@new_pre;
                push @temp_tree, \@new_from;
                push @temp_tree, \@new_to;
            } elsif (@pre_this eq @pre_from and $name_this eq $name_to) {
                # skip
            } else {
                # copy whatever it was (not from, not to)
                push @temp_tree, $ref;
                # print "  @{$ref}\n";
            }
            $assy_tree_changed = 1;
        }
    } elsif ($command eq "collapse") {
        foreach my $ref (@assy_tree) {
            my @pre_this = @{$ref};
            my $name_this = pop @pre_this;
            if (@pre_this eq @pre_from and $name_this eq $name_from) {
                # skip
                # print "- @pre_this, $name_this\n";
            } else {
                # print ". @pre_this, $name_this\n";
                my @temp;
                foreach my $entity (@{$ref}) {
                    push @temp, $entity unless $entity eq $name_from;
                }
                # print "o @temp\n";
                push @temp_tree, \@temp;
            }
            $assy_tree_changed = 1;
        }
    } else {
        # do nothing
    }

    # print "@{$_}\n" foreach @temp_tree;
    @temp_tree = @assy_tree unless $assy_tree_changed;
    return @temp_tree;
}

sub compare_array {
    my @first = @{$_[0]};
    my @second = @{$_[1]};
    return 0 if $#first ne $#second;
    foreach my $i (0..$#first) {
        return 0 if $first[$i] ne $second[$i];
    }
    return 1;
}

sub XXX_pre_name_from_to {
    my $input = shift;
    my @list = split '\.', $input;
    my $name = pop @list;
    return \@list, $name;
}

sub XXX_tree_modify {
    ### i/p - $from, $to, @Htree
    ### o/p - @Htree modified
    print ">>> tree_modify\n";
    my @new;
    # my $from = shift;
    # my $to = shift;

    foreach my $ref (@_) {
        my @list = @{$ref};
        print "@list\n";
        my $end = $list[$#list];
        # print "$#list $end\n";
        my @xxx = ($#list, $end);
        push @new, \@xxx;
    }

    foreach my $ref (@new) {
        my ($i, $part) = @{$ref};
        # print "$i $part\n";
    }

    my @name = ();
    foreach my $ref (@new) {
        my ($i, $part) = @{$ref};
        $name[$i] = $part;
        my @list = ();
        for (0..$i) {
            push @list, $name[$_];
        }
        # print "$i @list [$name[$i]]\n";
    }
    return @_;
}
