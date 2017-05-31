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

# StrEmbed::StrEmbed_3_STEP.pm
# StrEmbed-3 Release A - HHC 2017-01-06
#            Release B - HHC 2017-01-31
# HHC - 2017-03-07 - starting StrEmbed-4
# HHC - 2017-03-24
# HHC - 2017-05-26 Version 4 Release C

require 5.002;
use warnings;
use strict;

my $n;
my $nauo_n;
my %line;
# my @shape_def_rep = ();
my %shape_def_rep;
my %to_be_deleted_shape_def_rep;
my @shape_rep_relationship = ();
# my @context_dependent_shape_rep = ();
my %context_dependent_shape_rep;
my $preamble;
my %part;
my @parent_child_pair;  # taken from STEP file via cdsr-pds-nano-pd-pdfwss-p

return 1;

###
### testing prints via Tk gui
###

sub step_initialise {
    $n = "";
    $nauo_n = "";
    %line = ();
    # @shape_def_rep = ();
    %shape_def_rep = ();
    %to_be_deleted_shape_def_rep = ();
    @shape_rep_relationship = ();
    # @context_dependent_shape_rep = ();
    %context_dependent_shape_rep = ();
    $preamble = ();
    %part = ();
    @parent_child_pair = ();  # taken from STEP file via cdsr-pds-nano-pd-pdfwss-p
}

sub step_parent_child_pair {
    # print "step_parent_child_pair\n";
    # &print_pairs(@parent_child_pair);
    return \@parent_child_pair;
}

sub step_print_part {
    print "step print part\n";
    foreach my $label (sort keys %part) {
        my $id_shape_rep         = $part{$label}[0];
        my $id_product_def       = $part{$label}[1];
        my $id_product_def_shape = $part{$label}[2];
        print "$label = [sr=$id_shape_rep, pd=$id_product_def, pds=$id_product_def_shape]\n";
    }
}

sub step_print_shape_def_rep {
    print "step print shape def rep\n";
    foreach my $id (keys %shape_def_rep) {
        my $id_pds = $shape_def_rep{$id}[0][0];
        my $id_pd  = $shape_def_rep{$id}[0][1];
        my $id_sr  = $shape_def_rep{$id}[1];
        print "sdr=$id = [[pds=$id_pds], [pd=$id_pd], sr=$id_sr]\n";
    }
}

sub step_produce_parent_child_pairs {
    ### i/p - cdsr-rr-sr
    ###     - cdsr-pds-nauo-pd-pdfwss-p
    ### o/p - @parent_child_pair
    @parent_child_pair = ();
    foreach my $id (keys %context_dependent_shape_rep) {
        my $id_three_rep_relationships = $context_dependent_shape_rep{$id}[0][0];
        my $id_rr_parent               = $context_dependent_shape_rep{$id}[0][1][0];
        my $id_rr_child                = $context_dependent_shape_rep{$id}[0][1][1];
        my $id_pds                     = $context_dependent_shape_rep{$id}[1][0];
        my $id_nauo                    = $context_dependent_shape_rep{$id}[1][1];
        my $id_nauo_parent             = $context_dependent_shape_rep{$id}[1][2][0];
        my $id_nauo_child              = $context_dependent_shape_rep{$id}[1][2][1];
        # my $label_parent = &get_product_label($id_nauo_parent);    # alternative rr-sr is nauo-pd-pdfwss-p
        # my $label_child  = &get_product_label($id_nauo_child);
        my $label_parent = &get_argument($id_rr_parent, 0);
        my $label_child  = &get_argument($id_rr_child, 0);
        $label_parent =~ s/^'//;    # strip single quote b/f and a/f labels
        $label_parent =~ s/'$//;
        $label_child =~ s/^'//;
        $label_child =~ s/'$//;
        # @parent_child_pair
        push @parent_child_pair, [$label_parent, $label_child];
    }
    return @parent_child_pair;
}

sub get_product_label {
    ### i/p - id_product_definition
    ### o/p - label_product
    my $id_pd     = shift;
    my $id_pdfwss = &get_argument($id_pd, 2);
    my $id_p      = &get_argument($id_pdfwss, 2);
    my $label     = &get_argument($id_p, 0);
    return $label;
}

###
### menu items
###

sub step_open {
    my $file = shift;
    &read_step_file($file);
    &find_product;
    &extract_shape_def_rep;
    &extract_context_dependent_shape_rep;
    &step_find_sdr_cdsr;
}

sub step_delete_old {
    &find_to_be_deleted_shape_def_rep;
    &find_old_pds;
    &delete_entities;
}

sub read_step_file {
    ### i/p - STEP AP214 file
    ### o/p - %line

    my $file = shift;
    $n = 0;
    $nauo_n = 0;
    %line = ();
    open(my $fh, "<", $file) or die "cannot open < $file: $!";
    LABEL: while (<$fh>) {
        # print "$_";
        $preamble .= $_;
        last if $_ =~ m/^DATA;/;
    }
    while (<$fh>) {
        chomp;
        s/\s*;\s*$//;
        if ( $_ =~ m/^\s*(\#\d+)\s*=\s*(.*)$/ ) {
            my $id = $1;
            my $content = $2;
            $line{$id} = $content;
            my @i = $id =~ m/\#(\d+)/;
            $n = $i[0] if $n < $i[0];
            
            if ( $content =~ m/NEXT_ASSEMBLY_USAGE_OCCURRENCE\s*\(\s*\'NAUO(\d+)\'/ ) {
                $nauo_n = $1 if $nauo_n < $1;
            }
        }
    }
    close $fh;
}

sub output_step_file {
    my $filename = shift;
    open( my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh $preamble;
    print $fh "$_ = $line{$_} ;\n" foreach &hash_sort( keys %line );
    print $fh "ENDSEC;\n";
    print $fh "END-ISO-10303-21;\n";
    close $fh;
}

sub create_new_shape_def_rep {
    ### o/p - %create_new_assy_relation
    my $parent = shift;
    my @children = @_;
    my %template;
    foreach my $id ('#sdr', '#pds', '#pd', '#pdfwss', '#p', '#pc', '#app', '#pdc', '#apc',
                    '#sr', '#axis', '#origin', '#dirz', '#dirx', '#geo',
                    '#uncertainy', '#mm', '#radian', '#steradian',
                    '#prpc', '#apdp', '#apdc') {
        $template{$id} = ++$n;
    }
    
    my $data_start = tell DATA;
    while (<DATA>) {
        my $line = $_;
        chomp $line;
        $line =~ s/\s*;\s*$//;
        while (my ($old, $new) = each %template) {
            $line =~ s/\Q$old\E([,\)\s])/#\Q$new\E$1/g;
        }

        if ( $line =~ m/^\s*(\#\d+)\s*=\s*(.*)$/ ) {
            my $id = $1;
            my $content = $2;
            $line{$id} = $content;
            if ($content =~ m/^PRODUCT\s*\(/) {
                $content =~ s/\#name\#/$parent/g;
                $line{$id} = $content;
            } elsif ($content =~ m/^SHAPE_REPRESENTATION\s*\(/) {
                $part{$parent}[0] = $id;
                $content =~ s/\#name\#/$parent/;
                $line{$id} = $content;
            } elsif ($content =~ m/^PRODUCT_DEFINITION\s*\(/) {
                $part{$parent}[1] = $id;
            } elsif ($content =~ m/^PRODUCT_DEFINITION_SHAPE\s*\(/) {
                $part{$parent}[2] = $id;
            }
        }
    }
    seek DATA, $data_start, 0;    # reset DATA pointer to the beginning
    
    foreach my $child (@children) {
        &create_new_assy_relation($parent, $child);
    }
}

sub XXX_create_one_new_shape_def_rep {
    ### o/p - %create_new_assy_relation
    my $parent = shift;
    my $child = shift;
    my %template;
    foreach my $id ('#sdr', '#pds', '#pd', '#pdfwss', '#p', '#pc', '#app', '#pdc', '#apc',
                    '#sr', '#axis', '#origin', '#dirz', '#dirx', '#geo',
                    '#uncertainy', '#mm', '#radian', '#steradian',
                    '#prpc', '#apdp', '#apdc') {
        $template{$id} = ++$n;
    }
    
    my $data_start = tell DATA;
    while (<DATA>) {
        my $line = $_;
        chomp $line;
        $line =~ s/\s*;\s*$//;
        while (my ($old, $new) = each %template) {
            $line =~ s/\Q$old\E([,\)\s])/#\Q$new\E$1/g;
        }

        if ( $line =~ m/^\s*(\#\d+)\s*=\s*(.*)$/ ) {
            my $id = $1;
            my $content = $2;
            $line{$id} = $content;
            if ($content =~ m/^PRODUCT\s*\(/) {
                $content =~ s/\#name\#/$parent/g;
                $line{$id} = $content;
            } elsif ($content =~ m/^SHAPE_REPRESENTATION\s*\(/) {
                $part{$parent}[0] = $id;
                $content =~ s/\#name\#/$parent/;
                $line{$id} = $content;
            } elsif ($content =~ m/^PRODUCT_DEFINITION\s*\(/) {
                $part{$parent}[1] = $id;
            } elsif ($content =~ m/^PRODUCT_DEFINITION_SHAPE\s*\(/) {
                $part{$parent}[2] = $id;
            }
        }
    }
    seek DATA, $data_start, 0;    # reset DATA pointer to the beginning
    &create_new_assy_relation($parent, $child);
}

sub create_new_assy_relation {
    ### o/p - %line
    my ($parent, $child) = @_;
    my $sr_p  = $part{$parent}[0];
    my $pd_p  = $part{$parent}[1];
    my $sr_c  = $part{$child} [0];
    my $pd_c  = $part{$child} [1];
    my $pds_c = $part{$child} [2];
    #print "$parent -> $child = SR=$sr_p PD=$pd_p\n";
    #print "$parent <- $child = SR=$sr_c PD=$pd_c\n";
    my $nauo     = "#" . ++$n; $nauo_n++;
    $line{$nauo} = "NEXT_ASSEMBLY_USAGE_OCCURRENCE ( 'NAUO$nauo_n', ' ', ' ', $pd_p, $pd_c, \$ )";  ###
    my $pds      = "#" . ++$n;
    $line{$pds}  = "PRODUCT_DEFINITION_SHAPE ( 'NONE', 'NONE',  $nauo )";
    my $idt      = "#" . ++$n;
    my $axis     = "#" . ++$n;
    my $origin   = "#" . ++$n;
    my $dirz     = "#" . ++$n;
    my $dirx     = "#" . ++$n;
    $line{$idt}    = "ITEM_DEFINED_TRANSFORMATION ( 'NONE', 'NONE', $axis, $axis )";
    $line{$axis}   = "AXIS2_PLACEMENT_3D ( 'NONE', $origin, $dirz, $dirx )";
    $line{$origin} = "CARTESIAN_POINT ( 'NONE',  ( 0.0000000000000000000, 0.0000000000000000000, 0.0000000000000000000 ) )";
    $line{$dirz}   = "DIRECTION ( 'NONE',  ( 0.0000000000000000000, 0.0000000000000000000, 1.000000000000000000 ) )";
    $line{$dirx}   = "DIRECTION ( 'NONE',  ( 1.000000000000000000, 0.0000000000000000000, 0.0000000000000000000 ) )";
    my $rep      = "#" . ++$n;
    $line{$rep}    = "( REPRESENTATION_RELATIONSHIP ('NONE','NONE', $sr_p, $sr_c ) REPRESENTATION_RELATIONSHIP_WITH_TRANSFORMATION ( $idt )SHAPE_REPRESENTATION_RELATIONSHIP( ) )";   ###
    my $cdsr     = "#" . ++$n;
    $line{$cdsr}   = "CONTEXT_DEPENDENT_SHAPE_REPRESENTATION ( $rep, $pds )";
}

###
### subroutines
###

sub find_product {
    ### reverse lookup for internal use only, not a part of AP214
    ### index by product label
    ### o/p - %part
    ### key = label (not description)
    ### field [0] = shape_rep
    ### field [1] = product_def
    ### field [2] = product_def_shape    # filled elsewhere
    ### !!! need to delete old ones after creating a new assy structure -- HHC 16th Dec
    foreach my $id (keys %line) {
        my $content = $line{$id};
        my $entity = 0;
        $entity = $1 if $content =~ m/^(\w+)\s*(.*)/;
        if ($entity eq 'SHAPE_DEFINITION_REPRESENTATION') {
            my $pds         = &get_argument($id, 0);
            my $pd          = &get_argument($pds, 2);
            my $pdfwss      = &get_argument($pd, 2);
            my $p           = &get_argument($pdfwss, 2);
            my $label       = &get_argument($p, 0);
            my $description = &get_argument($p, 1);
            $label =~ s/^'//;
            $label =~ s/'$//;
            $description =~ s/^'//;
            $description =~ s/'$//;
            # print "sdr ... id = $label (pd = $pd) description = $description\n";
            $part{$label}[1] = $pd;    # label description
        } elsif ($entity eq 'SHAPE_REPRESENTATION') {
            my $label = &get_argument($id, 0);
            $label =~ s/^'//;
            $label =~ s/'$//;
            # print "sr  >>> id = $label\n";
            $part{$label}[0] = $id;    #label id
        }
    }
}

sub extract_shape_def_rep {
    ### o/p - %shape_def_rep
    ### key = id_shape_def_rep
    ### field [0][0] = id_product_def_shape
    ### field [0][1] = id_product_dep
    ### field [1]    = id_shape_rep
    my $entity = 'SHAPE_DEFINITION_REPRESENTATION';
    #print "shape_def_rep\n";
    foreach my $id (sort keys %line) {
        if ($line{$id} =~ m/^\Q$entity\E\s*\(/) {
            my $id_product_def_shape = &get_argument($id, 0);                      # pds
            my $id_product_def       = &get_argument($id_product_def_shape, 2);    # pd
            my $id_shape_rep         = &get_argument($id, 1);                      # sr

            $shape_def_rep{$id} = [ [$id_product_def_shape, $id_product_def], $id_shape_rep ];
        }
    }
}

sub extract_context_dependent_shape_rep {
    ### o/p - %context_dependent_shape_rep
    ### key = id_cdsr
    ### field [0][0]    = id_three_rep_relationships
    ### field [0][1][0] = id_rr_parent
    ### field [0][1][1] = id_rr_child
    ### field [1][0]    = id_pds
    ### field [1][1]    = id_nauo
    ### field [1][2][0] = id_nauo_parent
    ### field [1][2][1] = id_nauo_child
    my $entity = 'CONTEXT_DEPENDENT_SHAPE_REPRESENTATION';
    foreach my $id (sort keys %line) {
        if ($line{$id} =~ m/^\Q$entity\E\s*\(/) {
            my $three_rep_relationships = &get_argument($id, 0);
            my $content = $line{$three_rep_relationships};
            $content =~ s/^\(\s*//;
            $content =~ s/\s*\)$//;
            my @rep_relationships = $content =~ m/#\d+/g;
            my $rep_relationship_parent  = $rep_relationships[0];
            my $rep_relationship_child   = $rep_relationships[1];
            my $rep_relationship_w_trans = $rep_relationships[2];
            # print "$id:$three_rep_relationships:($rep_relationship_parent $rep_relationship_child)\n";

            my $product_def_shape = &get_argument($id, 1);
            my $nauo              = &get_argument($product_def_shape, 2);
            my $nauo_parent       = &get_argument($nauo, 3);
            my $nauo_child        = &get_argument($nauo, 4);
            # print "$id:$product_def_shape:$nauo:($nauo_parent $nauo_child)\n";
            $context_dependent_shape_rep{$id} = [
                [$three_rep_relationships, [$rep_relationship_parent, $rep_relationship_child] ] ,
                [$product_def_shape, $nauo, [$nauo_parent, $nauo_child] ]
            ];
            # my $p = &get_product_label($nauo_parent);
            # my $c = &get_product_label($nauo_child);
            # print "*** parent = $nauo_parent, child = $nauo_child\n";
            # print "*** parent = $p, child = $c\n";
        }
    }
}

sub step_find_sdr_cdsr {
    ### find existing assemblies/parts via cdsr/sdr to be deleted
    ### o/p - @to_be_deleted_shape_def_rep
    ### id = cdsr
    ### id2 = sdr

    # assembly names (pd onwards via cdsr/sdr) to be deleted
    foreach my $id (sort keys %context_dependent_shape_rep) {
         my $parent = $context_dependent_shape_rep{$id}[1][2][0];                 # nauo_parent
         # print "$id:", $context_dependent_shape_rep{$id}[1][0], ":",            # product_def_shape
         #               $context_dependent_shape_rep{$id}[1][1], ":(",           # nauo
         #                  $context_dependent_shape_rep{$id}[1][2][0], " ",      # nauo_parent
         #                  $context_dependent_shape_rep{$id}[1][2][1], ")\n";    # nauo_child
        foreach my $id2 (sort keys %shape_def_rep) {
            my $match = $shape_def_rep{$id2}[0][1];                               # product_def = nauo_parent ? 
            @{ $to_be_deleted_shape_def_rep{$id2} } = () if $parent eq $match;
        }
    }

    # part names (sr onwards via cdsr/sdr) to be deleted
    foreach my $id (sort keys %context_dependent_shape_rep) {
        my $parent = $context_dependent_shape_rep{$id}[0][1][0];              # rep_relationship_parent
        # print "$id:", $context_dependent_shape_rep{$id}[0][0], ":(",        # three_rep_relationships
        #               $context_dependent_shape_rep{$id}[0][1][0], " ",      # rep_relationship_parent
        #               $context_dependent_shape_rep{$id}[0][1][1], ")\n";    # rep_relationship_child
        foreach my $id2 (sort keys %shape_def_rep) {
            my $match = $shape_def_rep{$id2}[1];                              # shape_representation = rep_relationship_parent ?
            @{ $to_be_deleted_shape_def_rep{$id2} } = () if $parent eq $match;
        }
    }
}

sub find_to_be_deleted_shape_def_rep {
    ### put pds/sr of sdr into @to_be_deleted_shape_def_rep [and their branches] recursively
    foreach my $sdr (keys %to_be_deleted_shape_def_rep) {
        my @references = $line{$sdr} =~ m/\#\d+/g;    # (field[0], field[1]) = (pds, sr) ### Use of uninitialized value within %line in pattern match (m//) at StrEmbed/StrEmbed_4_step.pm line 479, <DATA> line 21.
        foreach my $ref (@references) {
            &find_to_be_deleted_entities($sdr, $ref);
        }
    }
}

sub find_old_pds {
    ### pds connects to pd in two different ways
    ### 1/ for parts, pds - pd
    ### 2/ for assemblies, pds - nauo (parent, child) - pd
    while ( my ($id, $content) = each %line) {
        if ($content =~ m/^PRODUCT_DEFINITION_SHAPE\s*\(/) {
            my $id2 = &get_argument($id, 2);
            my $content2 = $line{$id2};
            if ($content2 =~ m/^PRODUCT_DEFINITION\s*\(/) {
                ### 1/ it is a part, keep it
                ###    $part{$name}[0] = $id_sr
                ###    $part{$name}[1] = $id_pd
                ###    $part{$name}[2] = $id_pds
                my $pdfwss  = &get_argument($id2, 2);
                my $product = &get_argument($pdfwss, 2);
                my $name    = &get_argument($product, 0);
                $name =~ s/^\'//;
                $name =~ s/\'$//;
                $part{$name}[2] = $id;  # $id = $pds
            } elsif ($content2 =~ m/^NEXT_ASSEMBLY_USAGE_OCCURRENCE\s*\(/) {
                ### 2/ it is an assembly relation
                ###    get rid of it
                delete $line{$id};
            }
        }
    }
}

sub delete_entities {
    ### delete 1/ entities in a predefined list and their children
    ###        2/ all of nauo, idt, prpc, rr, pds, cdsr
    foreach my $sdr (keys %to_be_deleted_shape_def_rep) {
        delete $line{$sdr};
        foreach my $ref( @{$to_be_deleted_shape_def_rep{$sdr}} ) {
            delete $line{$ref};
        }
    }

    while ( my ($id, $content) = each %line) {
        if ( $content =~ m/^NEXT_ASSEMBLY_USAGE_OCCURRENCE/ or
             $content =~ m/^ITEM_DEFINED_TRANSFORMATION/ or
             $content =~ m/^PRODUCT_RELATED_PRODUCT_CATEGORY/ or
             $content =~ m/^\(\s*REPRESENTATION_RELATIONSHIP/ or
             $content =~ m/^\(\s*PRODUCT_DEFINITION_SHAPE/ or
             $content =~ m/^CONTEXT_DEPENDENT_SHAPE_REPRESENTATION/ ) {
            delete $line{$id};
        }            
    }
}

### find to be deleted entities

sub find_to_be_deleted_entities {
    ### o/p - @{ $to_be_deleted_shape_def_rep{$sdr} }
    my ($sdr, $ref) = @_;
    my $content = $line{$ref};
    push @{ $to_be_deleted_shape_def_rep{$sdr} }, $ref;
    &find_to_be_deleted_entities_next_level_down($sdr, $ref);
}

sub find_to_be_deleted_entities_next_level_down {
    ### o/p - @{ $to_be_deleted_shape_def_rep{$sdr} }
    ### recursive
    my ($sdr, $next) = @_;
    my $content = $line{$next};
    my @references = ();
    @references = $content =~ m/\#\d+/g;
    push @{ $to_be_deleted_shape_def_rep{$sdr} }, $next;
    &find_to_be_deleted_entities_next_level_down($sdr, $_) foreach @references;   
}

###
### subroutines
###

sub hash_sort {
    my @input = @_;
    my @output = ();
    my %hash;
    foreach my $hash_digits (@input) {
        $hash_digits =~ m/#(\d+)/;
        my $digits = $1;
        $hash{$digits} = $hash_digits;
    }

    for my $key ( sort {$a<=>$b} keys %hash) {
           push @output, $hash{$key};
    }

    return @output;
}

sub get_argument {
    my $id = $_[0];
    my $item = $_[1];
    my $content = $line{$id};
    #print "$id > $content\n";
    my @list;
    if ($content =~ m/^(\w+)\s*(.*)/) {
        my $entity = $1;
        my $arguments = $2;
        $arguments =~ s/^\(\s*//;
        $arguments =~ s/\s*\)$//;
        @list = split m/,(?![^()]*\))/, $arguments;
        $_ =~  s/^\s*// foreach @list;
    }
    return $list[$item];
}

#prpc = PRODUCT_RELATED_PRODUCT_CATEGORY ( 'part', '', ( #p ) ) ;

__DATA__
#sdr = SHAPE_DEFINITION_REPRESENTATION ( #pds, #sr ) ;
#pds = PRODUCT_DEFINITION_SHAPE ( 'NONE', 'NONE',  #pd ) ;
#pd = PRODUCT_DEFINITION ( 'UNKNOWN', '', #pdfwss, #pdc ) ;
#pdfwss = PRODUCT_DEFINITION_FORMATION_WITH_SPECIFIED_SOURCE ( 'ANY', '', #p, .NOT_KNOWN. ) ;
#p = PRODUCT ( '#name#', '#name#', '', ( #pc ) ) ;
#pc = PRODUCT_CONTEXT ( 'NONE', #app, 'mechanical' ) ;
#app = APPLICATION_CONTEXT ( 'automotive_design' ) ;
#pdc = PRODUCT_DEFINITION_CONTEXT ( 'detailed design', #apc, 'design' ) ;
#apc = APPLICATION_CONTEXT ( 'automotive_design' ) ;
#sr = SHAPE_REPRESENTATION ( '#name#', ( #axis ), #geo ) ;
#axis = AXIS2_PLACEMENT_3D ( 'NONE', #origin, #dirz, #dirx ) ;
#origin = CARTESIAN_POINT ( 'NONE',  ( 0.0000000000000000000, 0.0000000000000000000, 0.0000000000000000000 ) ) ;
#dirz = DIRECTION ( 'NONE',  ( 0.0000000000000000000, 0.0000000000000000000, 1.000000000000000000 ) ) ;
#dirx = DIRECTION ( 'NONE',  ( 1.000000000000000000, 0.0000000000000000000, 0.0000000000000000000 ) ) ;
#geo = ( GEOMETRIC_REPRESENTATION_CONTEXT ( 3 ) GLOBAL_UNCERTAINTY_ASSIGNED_CONTEXT ( ( #uncertainy ) ) GLOBAL_UNIT_ASSIGNED_CONTEXT ( ( #mm, #radian, #steradian ) ) REPRESENTATION_CONTEXT ( 'NONE', 'WORKASPACE' ) ) ;
#uncertainy = UNCERTAINTY_MEASURE_WITH_UNIT (LENGTH_MEASURE( 1.000000000000000100E-005 ), #mm, 'distance_accuracy_value', 'NONE') ;
#mm = ( LENGTH_UNIT ( ) NAMED_UNIT ( * ) SI_UNIT ( .MILLI., .METRE. ) ) ;
#radian = ( NAMED_UNIT ( * ) PLANE_ANGLE_UNIT ( ) SI_UNIT ( $, .RADIAN. ) ) ;
#steradian = ( NAMED_UNIT ( * ) SI_UNIT ( $, .STERADIAN. ) SOLID_ANGLE_UNIT ( ) ) ;
#apdp = APPLICATION_PROTOCOL_DEFINITION ( 'draft international standard', 'automotive_design', 1998, #app ) ;
#apdc = APPLICATION_PROTOCOL_DEFINITION ( 'draft international standard', 'automotive_design', 1998, #apc ) ;