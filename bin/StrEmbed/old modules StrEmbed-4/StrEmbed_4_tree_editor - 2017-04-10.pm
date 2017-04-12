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

return 1;

sub tree_modify {
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

sub change_tree {
    ### i/p - \assy_tree, $from, $to, @assy_tree, $command
    ### o/p - \@assy_tree
    my $ref_assy_tree = shift;
    my @assy_tree = @{$ref_assy_tree};
    my @temp_tree = ();
    my $from = shift;
    my $to = shift;
    my $command = shift;
    my $assy_tree_changed = 0;
    # print "From ($from) to [$to] with command '$command'\n";

    my @pre_from = split '\.', $from;
    my @pre_to   = split '\.', $to;
    my $name_to = pop @pre_to;
    my $name_from = pop @pre_from;

    return @assy_tree unless @pre_from eq @pre_to and $name_from ne $name_to;

    if ($command eq "up") {
        foreach my $ref (@assy_tree) {
            my @pre_this = @{$ref};
            my $name_this = pop @pre_this;
            if      (@pre_this eq @pre_from and $name_this eq $name_from) {
                # skip [original] from
            } elsif (@pre_this eq @pre_to   and $name_this eq $name_to) {
                # put from, then put to
                my @temp = (@pre_from, $name_from);
                push @temp_tree, \@temp;
                push @temp_tree, $ref;
            } else {
                # copy whatever it was (not from, not to)
                push @temp_tree, $ref;
            }
            $assy_tree_changed = 1;
        }
    } elsif ($command eq "down") {
    } elsif ($command eq "adopt") {
        # need to exclude bare atoms
        foreach my $ref (@assy_tree) {
            my @pre_this = @{$ref};
            my $name_this = pop @pre_this;
            print "* @pre_this, $name_this\n";
            if (@pre_this eq @pre_from and $name_this eq $name_from) {
                # skip [original] from
                # print "- @pre_this, $name_this\n";
            } elsif (@pre_this eq @pre_to and $name_this eq $name_to) {
                # put to and adopt from
                my @temp = (@pre_this, $name_this, $name_from);
                push @temp_tree, $ref;
                push @temp_tree, \@temp;
            } else {
                # copy whatever it was (not from, not to)
                push @temp_tree, $ref;
                # print "  @pre_this, $name_this\n";
            }
            $assy_tree_changed = 1;
        }
    } elsif ($command eq "assy") {
    } elsif ($command eq "collapse") {
    } else {
        # do nothing
        @temp_tree = @assy_tree;
    }

    @temp_tree = @assy_tree unless $assy_tree_changed;
    return @temp_tree;
}

sub pre_name_from_to {
    my $input = shift;
    my @list = split '\.', $input;
    my $name = pop @list;
    return \@list, $name;
}