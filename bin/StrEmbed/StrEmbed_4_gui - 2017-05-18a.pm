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

# StrEmbed::StrEmbed_3_gui.pm
# StrEmbed-3 release A - HHC 2017-01-06
# HHC - 2017-01-16 - Version 3 Release A Update 1 -- StrEmbed-3 (A1)
# HHC - 2017-01-26 - Version 3 Release A Update 2 -- StrEmbed-3 (A2)
# HHC - 2017-01-30 - carry on
# HHC - 2017-03-07 - starting StrEmbed-4
# HHC - 2017-03-24 - use FileSelect
# HHC - 2017-04-04 - on GitHub
# HHC - 2017-03-12 - insert before and insert after work correctly
# HHC - 2017-05-12 - trying to populated @assy_tree (a HTree backwards)

require 5.002;
use warnings;
use strict;
use Tk;
use Tk::Balloon;
use Tk::Tree;
use Tk::PNG;
use StrEmbed::FileSelect;

our @assy_tree;

my $max;    # hypercube size
my ($x_normal, $y_normal) = (1440, 720);    # 1920 x 1080
my ($x_min, $y_min) = (640, 480);
my $element_radius = 8;
my $activewidth_is_covered_by = 5;
my $hightlighted_width_is_covered_by = 3;
my $mw;
my $c;
my @array_with_coords;
my %array_lookup_id_to_hash;
my %element;
my %element_id;
my %element_label;
my $active_element_id = 1;
my $active_element_label = 1;
my %is_covered_by;
my $tree;
my $box;
my $info;
my $status;
my $iterations;
my $zeros;
my $counter;
my $percentage;
my $quit_optimisation;
my %embedded;
my %parts_at_height_n;
my %lookup_label_to_id;
my %entity;
my $entity_focused;
my @available_atoms_n_subassemblies;
my $chosen_part;
my $chosen_index;
my @list_of_assembly_parts;
my $new_assy_name = "default";
my $assy_counter = 1;
my $ff_button_assy;
my $ff_button_parts;
my $menu_01;
my @atoms;
my $selected_entry;
my $entry_under_cursor = "";
my $entry_first_selected = "";
my $entry_second_selected = "";

return 1;

###
### Tk gui widgets
###

sub tk_initialise {
    @atoms = ();
    &delete_tree;
}

sub tk_mainloop {

    # Main Window

    $mw = new MainWindow;
    $mw -> geometry('+0+20');
    $mw -> minsize($x_min, $y_min);
    $mw -> optionAdd('*font', 'Helvetica 10');
    $mw -> title("Structure Embedding version 4 (StrEmbed-4)");
    my $icon = $mw -> Photo(-file => "./resources/icons/32x32/Actions-document-edit-icon-40.gif");
    $mw -> iconimage($icon);
    $mw -> idletasks;    # this line is crucial, or is it ???
    
    &tk_pulldown_menu;
    &tk_lower_frame;
    &tk_assembly_tree;
    &tk_canvas;
    # my $height = $mw -> screenheight;
    # my $width = $mw -> screenwidth;
    # print "width = $width, height = $height\b";
    MainLoop;
}

sub tk_pulldown_menu {

    # menu bar

    my $pm = $mw -> Frame -> pack(
        -side => 'top',
        -anchor => 'w',
        -fill => 'x',
    );

    my $menu_01 = $pm -> Menubutton( -text => "File",
        -menuitems => [
            [ 'command' => "Open",  -command => sub { &file_open } ],
            [ 'command' => "Save",  -command => sub { &file_save } ],
            "-",
            [ 'command' => "~Exit", -command => sub { exit } ],                      
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_51 = $pm -> Menubutton( -text => "Background 2^n lattice",
        -menuitems => [
            [ 'command' => "O~ff", -command => sub { &tk_turn_off_is_covered_by } ],
            [ 'command' => "O~n",  -command => sub { &tk_turn_on_is_covered_by } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_52 = $pm -> Menubutton( -text => "Plot",
        -state => 'normal',
        -menuitems => [
            [ 'command' => "~Resume optimisation", -command => sub {
                &tk_clear_canvas;
                &tk_optimise;
                &tk_plot_is_covered_by;
                &tk_plot_elements;
                &tk_display_order("element_highlighted",
                                  "is_covered_by_highlighted",
                                  "element",
                                  "is_covered_by");    
            } ],
            '-',
            # [ 'command' => "tk_embed and tk_plot", -command => sub { &tk_embed;&tk_plot; } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_53 = $pm -> Menubutton( -text => "Hasse diagram",
        -menuitems => [
            [ 'command' => "print info", -command => sub { &tk_print_all_relations } ],
            [ 'command' => "delete_tree", -command => sub { &delete_tree } ],
            [ 'command' => "create_tree", -command => sub { &insert_tree_items(@assy_tree) } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_54 = $pm -> Menubutton( -text => "Test",
        -menuitems => [
            [ 'command' => "print_tree", -command => sub { &print_tree } ],
            [ 'command' => "print_array", -command => sub { &print_array } ],
            [ 'command' => "assy_list_of_lists", -command => sub { &create_new_assy(\@assy_tree) } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_71 = $pm -> Menubutton( -text => "New sequence",
        -menuitems => [
            [ 'command' => "hypercube intialise", -command => sub { &hypercube_initialise } ],
            [ 'command' => "Tk GUI intialise", -command => sub { &tk_initialise } ],
            [ 'command' => "tk clear canvas", -command => sub { &tk_clear_canvas } ],
            [ 'command' => "print \@assy_tree", -command => sub { &print_htree } ],
            [ 'command' => "HTree to pairs and plot", -command => sub { &replot_hasse } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_90 = $pm -> Menubutton( -text => "Help",
        -state => 'normal',
        -menuitems => [
            [ 'command' => "~About",         -command => sub { &tk_about } ],
            [ 'command' => "~Copyright",     -command => sub { &tk_copyright } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'right',
    );
}

sub replot_hasse {
    &hypercube_initialise;
    # @array_with_coords = ();
    # %array_lookup_id_to_hash = undef;
    my @parent_child_pair = &htree_to_pairs(@assy_tree);  # @parent_child_pair
    my $ref_array = &hypercube_get_array;
    my ($ref_1, $ref_2) = &tk_hasse($ref_array);
    # my %hush_lookup = %{$ref_1};
    # my @array_coords = @{$ref_2};
    # &print_hash_lookup_array_coords($ref_1, $ref_2);

    # &tk_plotting_overall;
    &tk_setup_initial_colour_for_covered_by;
    &tk_setup_initial_colour_for_elements;
    # &tk_optimise;
    &tk_embed_height_0;
    # return;
    &tk_embed_height_n(\@parent_child_pair);
    &tk_highlight_relations;
    &tk_highlight_is_covered_by;
    &tk_clear_canvas;
    &tk_plot_is_covered_by;
    &tk_plot_elements;
    &tk_display_order("element_highlighted",
                      "is_covered_by_highlighted",
                      "element",
                      "is_covered_by");    
}

sub print_hash_lookup_array_coords {
    my ($ref_1, $ref_2) = @_;
    my %array_lookup_id_to_hash = %{$ref_1};
    my @array_with_coords = @{$ref_2};
    print "print_hush_lookup_array_coords\n";
    foreach my $h (0..$#array_with_coords) {    # at height h
        my @ee = @{$array_with_coords[$h]};
        foreach my $j (0..$#ee) {
            my $id = $array_with_coords[$h][$j]{id};
            my $ref_coords = $array_with_coords[$h][$j]{coords};
            my $ref_canvas = $array_with_coords[$h][$j]{canvas};
            print "[$h][$j] $id, @$ref_coords, @$ref_canvas\n";
        }
    }

    print "\n";
    while ( my ($x, $ref_hash) = each %array_lookup_id_to_hash ) {
        my %hash = %$ref_hash;
        my $id = $hash{id};
        my $label = $hash{label};
        my $coords = $hash{coords};
        my $canvas = $hash{canvas};
        
        print "[$x] $id, $label, @$coords, @$canvas\n";
    }
}

sub print_tree {
    print "print_tree\n";
    my @list = $tree -> child_entries( '', 3);
    print "$_\n" foreach @list;
}

sub print_array {
    print "print_array\n";
    foreach my $ref (@assy_tree) {
        print "@{$ref}\n";
    }
}

sub print_htree {
    ### i/p - @assy_tree
    print "print assy tree\n";
    foreach my $ref (@assy_tree) {
        my @entities = @{$ref};
        my $list = CORE::join ' -- ', @entities;
        print "$list\n";
    }
}

sub htree_to_pairs {
    ### i/p - @assy_tree
    ### o/p - 
    # print "htree to pairs\n";
    my @assy_tree = @_;
    my @parent_child_pair = ();
    foreach my $ref (@assy_tree) {
        my @entities = @{$ref};
        if ($#entities > 0) {
            my $child = pop @entities;
            my $parent = pop @entities;
            # print "$parent -- $child\n";
            push @parent_child_pair, [$parent, $child];
        }
    }
    return @parent_child_pair;
}

sub delete_tree {
    $tree -> delete('all');
}

sub tk_about {
    my $heading = "University of Leeds
The Open University
";
    my $message = "
StrEmbed-4
Embedding design structures in engineering information

Structure Embedding version 4 (StrEmbed-4) is a deliverable from the
Embedding Design Structures in Engineering Information project,
a Design The Future project funded by Engineering and Physical Sciences
Research Council (grant reference EP/N005694/1).

People

The Design Structures in Engineering Information (Embedding) project is
jointly hosted by the University of Leeds and The Open University.
Members of the Embedding project are Amar Behera, Hau Hing Chau, Chris
Earl, David Hogg, Alison McKay, Alan de Pennington and Mark Robinson.

Getting help and reporting bugs

Send help request and bug report to Hau Hing Chau <H.H.Chau\@leeds.ac.uk>
School of Mechanical Engineering, University of Leeds, Leeds, LS2 9JT, UK.
";

    my $popup_about = new MainWindow;
    $popup_about -> optionAdd('*font', 'Helvetica 10');
    my $text = $popup_about -> Text(
        -background => 'gray95',
        -relief => 'flat',
    ) -> pack;
    $text->tagConfigure('bold', -font => "bold");
    $text -> insert('end', $heading, 'bold');
    $text -> insert('end', $message);
    $text -> configure(-state => 'disabled');

    my $icon = $popup_about -> Photo(-file => "./resources/icons/32x32/Actions-document-edit-icon-40.gif");
    $popup_about -> iconimage($icon);
    $popup_about -> title("StrEmbed-4 About");
}

sub tk_copyright {
    my $heading = "Structure Embedding version 4 (StrEmbed-4)
";
    my $message = "
Embedding an assembly structure onto a corresponding hypercube lattice
Copyright (C) 2017  University of Leeds

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Copyright acknowledgements

Additional icons are obtatined from:
1/ Icon Archive <http://www.iconarchive.com/>
2/ Visual Phram <http://www.visualpharm.com/articles/icon_sizes.html>
";

    my $popup_copyright = new MainWindow;
    $popup_copyright -> optionAdd('*font', 'Helvetica 10');
    my $text = $popup_copyright -> Text(
        -background => 'gray95',
        -relief => 'flat',
    ) -> pack;
    $text -> tagConfigure('bold', -font => "bold");
    $text -> insert('end', $heading, 'bold');
    $text -> insert('end', $message);
    $text -> configure(-state => 'disabled');

    my $icon = $popup_copyright -> Photo(-file => "./resources/icons/32x32/Actions-document-edit-icon-40.gif");
    $popup_copyright -> iconimage($icon);
    $popup_copyright -> title("StrEmbed-4 Copyright");
}

###
### lower tree, toggle, optimisation
###

sub tk_lower_frame {
    my $f = $mw -> Frame -> pack(
        -side => 'bottom',
        -fill => 'x',
    );

    ### display toggles

    $info = $f -> Scrolled("Text",
        -height => 5,
        -scrollbars => 'e',
        -width => 20,
        -background => 'gray95',
        -relief => 'flat',
    ) -> pack(
        -fill => 'both',
        -side => 'left',
        -expand => 1,
    );
    $info -> insert( 'end', "This space is reserved for user messages.\n",);

    ### status

    $status = $f -> Frame -> pack;
    $status -> Label(
        -text => "Optimising\nHasse diagram",
        -font => ['*font', '10', 'bold'],
    ) -> grid(
        -row => 0,
        -column => 0,
        -columnspan => 3,
        -sticky => 'we',
    );

    # iterations

    $status -> Label(
        -text => "iteration no.",
        -relief => 'flat',
        -state => 'disable',
    ) -> grid(
        -row => 1,
        -column => 0,
        -sticky => 'we',
    );

    $status -> Entry(
        -textvariable => \$iterations,
        -relief => 'flat',
        -state => 'disable',
        -width => 4,
        -justify => 'center',
    ) -> grid(
        -row => 1,
        -column => 1,
        -sticky => 'we',
    );

    $status -> Label(
        -text => "th",
        -relief => 'flat',
        -state => 'disable',
    ) -> grid(
        -row => 1,
        -column => 2,
        -sticky => 'we',
    );

    # in a row

    $status -> Label(
        -text => "with all zeros",
        -relief => 'flat',
        -state => 'disable',
    ) -> grid(
        -row => 2,
        -column => 0,
        -sticky => 'we',
    );

    $status -> Entry(
        -textvariable => \$zeros,
        -relief => 'flat',
        -state => 'disable',
        -width => 4,
        -justify => 'center',
    ) -> grid(
        -row => 2,
        -column => 1,
        -sticky => 'we',
    );

    $status -> Label(
        -text => "in a row",
        -relief => 'flat',
        -state => 'disable',
    ) -> grid(
        -row => 2,
        -column => 2,
        -sticky => 'we',
    );

    # swapped

    $status -> Label(
        -text => "and swapped",
        -relief => 'flat',
        -state => 'disable',
    ) -> grid(
        -row => 3,
        -column => 0,
        -sticky => 'we',
    );

    $status -> Entry(
        -textvariable => \$counter,
        -relief => 'flat',
        -state => 'disable',
        -width => 4,
        -justify => 'center',
    ) -> grid(
        -row => 3,
        -column => 1,
        -sticky => 'we',
    );

    $status -> Label(
        -text => "times",
        -relief => 'flat',
        -state => 'disable',
    ) -> grid(
        -row => 3,
        -column => 2,
        -sticky => 'we',
    );

    # percentage

    $status -> Label(
        -text => "percentage",
        -relief => 'flat',
        -state => 'disable',
    ) -> grid(
        -row => 4,
        -column => 0,
        -sticky => 'we',
    );

    $status -> Entry(
        -textvariable => \$percentage,
        -relief => 'flat',
        -state => 'disable',
        -width => 4,
        -justify => 'center',
    ) -> grid(
        -row => 4,
        -column => 1,
        -sticky => 'we',
    );

    $status -> Label(
        -text => "% left",
        -relief => 'flat',
        -state => 'disable',
    ) -> grid(
        -row => 4,
        -column => 2,
        -sticky => 'we',
    );

    # quit

    my $quit = $status -> Button(
        -text => "Quit optimisation",
        -command => sub {
            $quit_optimisation = 1;
        }
    ) -> grid(
        -row => 5,
        -column => 0,
        -columnspan => 3,
        -sticky => 'we',
    );

}

### big bundle

sub print_pairs {
    foreach my $ref_parent_child (@_) {
        my ($parent, $child) = @{$ref_parent_child};
        print "$parent, $child\n";
    }
}

sub assembly_has_parent_to_Htree {
    ### i/p - %assembly, %has_parent
    ### o/p - assembly tree without dots
    our %assembly   = %{$_[0]};
    our %has_parent = %{$_[1]};
    our @Htree = ();
    my $top_level_assembly;
    while ( my ($child, $parent) = each %has_parent ) {
        $top_level_assembly = $child unless $parent;
    }
    &assembly_tree_element($top_level_assembly);
    return @Htree;

    sub assembly_tree_element {
        my @list = @_;
        my $last = $list[$#list];
        push @Htree, \@list;
        foreach my $child ( @{$assembly{$last}} ) {
            &assembly_tree_element(@list, $child);
        }
    }
}

### file open and save

sub file_open {
    my $fs = $mw -> FileSelect(
        -initialdir => "../step_data/input",
        -filter => "*.STEP",
        -acceptlabel => 'Open',
        -width => 30,
    );
    my $icon = $fs -> Photo(-file => "./resources/icons/32x32/Actions-document-edit-icon-40.gif");
    $fs -> iconimage($icon);
    $fs -> title("StrEmbed-4 File Open");

    $mw -> withdraw;
    my $file = $fs -> Show( -popover => $mw );
    $mw -> deiconify;

    if ($file) {
        &step_open($file);
        my @parent_child_pair = &step_produce_parent_child_pairs;  # @parent_child_pair
        $max = &big_bundle(@parent_child_pair);
        # &print_pairs(@parent_child_pair);
        &tk_plotting_overall;
    }
}

sub print_assy_tree {
    my @assy_tree = @_;
    print "assy_tree\n";
    print "@$_\n" foreach @assy_tree;
}

sub big_bundle {
    my @parent_child_pair = @_;
    # &print_pairs(@parent_child_pair);

    my ($ref_assembly, $ref_has_parent) = &step_produce_assembly_has_parent(@parent_child_pair);

    @assy_tree = &assembly_has_parent_to_Htree($ref_assembly, $ref_has_parent);
    #&print_assy_tree(@assy_tree);

    &delete_tree;
    &insert_tree_items(@assy_tree);
    @atoms = &step_count_atomic_part;
    my $max = $#atoms + 1;
    my $ref_array = &hypercube_corresponding_to_step_file($max);
    # &gui_print_array($ref_array);
    &tk_hasse($ref_array);
    return $max;
}

sub gui_print_array {
    print "print_array\n";
    my $ref = shift;
    my @array = @{$ref};
    foreach my $i (0..$#array) {
        my @list = @{$array[$i]};
        foreach my $j (0..$#list) {
            print "\@array[$i][$j] - $array[$i][$j]\n";
        }
    }
}

sub tk_plotting_overall {
    &tk_setup_initial_colour_for_covered_by;
    &tk_setup_initial_colour_for_elements;
    &tk_optimise;
    &tk_embed_height_0;

    my $ref = &step_parent_child_pair;
    my @parent_child_pair = @$ref;
    # print "first round\n";
    # &print_pairs(@parent_child_pair);

    &tk_embed_height_n(@parent_child_pair);
    &tk_highlight_relations;
    &tk_highlight_is_covered_by;
    &tk_clear_canvas;
    &tk_plot_is_covered_by;
    &tk_plot_elements;
    &tk_display_order("element_highlighted",
                      "is_covered_by_highlighted",
                      "element",
                      "is_covered_by");    
}

sub tk_setup_initial_colour_for_covered_by {
    while (my ($child, $ref_hash) = each %array_lookup_id_to_hash) {
        my $ref_parents = &get_parents($child);
        foreach my $parent (@$ref_parents) {
            my ($x1, $y1, $z1) = @{$array_lookup_id_to_hash{$child} {canvas}};
            my ($x2, $y2, $z2) = @{$array_lookup_id_to_hash{$parent}{canvas}};
            $is_covered_by{$child}{$parent}{colour} = 'gray75';
            $is_covered_by{$child}{$parent}{width} = 1;
            $is_covered_by{$child}{$parent}{active} = 0;
        }
    }
}

sub tk_setup_initial_colour_for_elements {
    foreach my $h (0..$#array_with_coords) {
        my @elements = @{$array_with_coords[$h]};
        foreach my $j (0..$#elements) {
            $array_with_coords[$h][$j]{colour} = 'gray95';    # fill circles, same as background
            $array_with_coords[$h][$j]{active} = 0;
        }
    }
}

sub tk_optimise {
    $zeros = 0;
    $iterations = 0;
    my $number_of_times = 9999;
    my $start_time = time;

    $quit_optimisation = 0;    # need to sort out needing to multiple "Quit" button clicks
    LABEL: while ($zeros <= 2) {    # consider optimised when three sets of 10,000 zeros
        $counter = 0;
        foreach (0..$number_of_times) {
            my $element_count = 1 << $max;    # equivalent to 2**max
            my $n = int rand() * $element_count;
            my $height = &tk_hamming_weight($n);
            my @list = &hypercube_elements_at_height($height);
            my $m = $list[int rand() * ($#list + 1)];
            unless ($n == 0 or
                    $n == $element_count - 1 or
                    $n == $m) {
                if ( &tk_if_n_bigger_than_m($n, $m) ) {
                    $counter++;
                    &tk_swap($n, $m);
                }
            };
        }
        $percentage = sprintf "%.2f", (int $counter/$number_of_times * 10000) / 100;
        $status -> update;
        $iterations++;
        $zeros++;
        $zeros = 0 if $counter;
        last LABEL if $quit_optimisation or time - $start_time > 10;    # Quit button pressed or elapsed time more than 10 seconds
    }
    &tk_turn_off_is_covered_by;  # see what happens
}

sub tk_embed_height_0 {
   ### consider 2^n hypercube when height = 0
   my ($e) = &hypercube_elements_at_height(0);
   $array_lookup_id_to_hash{$e}{label} = "0";
   $array_lookup_id_to_hash{$e}{active} = 1;
   %embedded = ();
   $embedded{0} = 0;
}

sub tk_embed_height_n {
    my @parent_child_pair = @_;
    # &print_pairs(@parent_child_pair);
    ### consider 2^n hypercube when height = 1 to supremum
    my @height_n = &hypercube_elements_at_height(1);
    %parts_at_height_n = ();

    ### consider 2^n hypercube when height = n
    my $top_level_assembly = &find_top_level_assembly(@parent_child_pair);
    # &print_pairs(\@parent_child_pair);
    # print "... top level = $top_level_assembly\n";

    # $top_level_assembly = &step_top_level_assembly;
    # print "ooo top level = $top_level_assembly\n";

    ### consider 2^n hypercube when height = 2 .. n-1
    ### set up atoms as available for embedding $embedded{$e}=1
    for (my $i=0; $i<=$#atoms; $i++) {
        my $atom = $atoms[$i];
        my $element = $height_n[$i];
        # print "$atom - $element\n";
        # $array_lookup_id_to_hash{$element}{label} = $atom;    # need to do dynamically
        $embedded{$atom} = 1;
        $parts_at_height_n{$atom} = 1;
    }

    ### embed thingies
    ### need tidying up - HHC 2017-01-05
    FIRST_ATTEMPT:  my @list = &tk_to_be_embedded_list(\%embedded);

    SECOND_ATTEMPT: my ($first) = @list;
    return if $first eq $top_level_assembly;  # EXIT subroutine if supremum is the only element left in @list
    my @siblings = &tk_siblings($first);
    my $parent = &tk_parent($first);

    if ( &tk_check_if_all_exists(@siblings) ) {
        foreach my $sibling (@siblings) {
            # print "sibling $sibling\n";
            $embedded{$sibling} = 0;
            if (defined $parts_at_height_n{$sibling}) {
                my $id = &next_available_height_n($sibling, @height_n);
                $lookup_label_to_id{$sibling} = $id;
            }
            $embedded{$parent} = 1;
        }

        my @bundle_of_ids;
        foreach my $part (@siblings) {
            my $id = $lookup_label_to_id{$part};
            push @bundle_of_ids, $id;
        }

        unless ($first eq $top_level_assembly) {
            my $join = &join(@bundle_of_ids);
            $array_lookup_id_to_hash{$join}{label} = $parent;
            $lookup_label_to_id{$parent} = $join;
        }

    } else {
        my $swap = shift @list;
        push @list, $swap;
        goto SECOND_ATTEMPT;
    }  # end if all siblings exists and are ready

    $embedded{ &tk_parent($first) } = 1 if &tk_parent($first);
    goto FIRST_ATTEMPT;
}

sub tk_highlight_relations {
    ### highlight most
    my $ref_parent_child_pair = &step_parent_child_pair;
    my @parent_child_pair = @{$ref_parent_child_pair};
    foreach my $ref_one_pair (@parent_child_pair) {
        my ($parent, $child) = @{$ref_one_pair};
        my $p_id = $lookup_label_to_id{$parent};
        my $c_id = $lookup_label_to_id{$child};
        my @chain = &hypercube_return_chain($p_id, $c_id);

        for (my $i=0; $i<$#chain; $i++) {
            # print "$chain[$i] - $chain[$i+1]\n";
            $is_covered_by{$chain[$i+1]}{$chain[$i]}{colour} = 'black';
            $is_covered_by{$chain[$i+1]}{$chain[$i]}{width} = $hightlighted_width_is_covered_by;
            $is_covered_by{$chain[$i+1]}{$chain[$i]}{active} = 1;
        }
    }

    ### highlight inf=zero to atom[s]
    @available_atoms_n_subassemblies = @atoms;
    foreach my $atom (@atoms) {
        my $id = $lookup_label_to_id{$atom};
        $is_covered_by{0}{$id}{colour} = 'black';
        $is_covered_by{0}{$id}{width} = $hightlighted_width_is_covered_by;
        $is_covered_by{0}{$id}{active} = 1;
    }
}

sub tk_highlight_is_covered_by {
    foreach my $h (0..$#array_with_coords) {
        my @elements = @{$array_with_coords[$h]};
        foreach my $j (0..$#elements) {
            if ($array_with_coords[$h][$j]{label}) {
                $array_with_coords[$h][$j]{colour} = 'black';
                $array_with_coords[$h][$j]{active} = 1;
            }
        }
    }
    ### zero as well
    $array_with_coords[0][0]{colour} = 'black';
    $array_with_coords[0][0]{width} = $hightlighted_width_is_covered_by;
}

sub tk_clear_canvas {
    $c -> delete("is_covered_by", "element", "element_id", "element_label", "is_covered_by_highlighted", "element_highlighted");
}

sub tk_plot_is_covered_by {
    while (my ($child, $ref_hash) = each %array_lookup_id_to_hash) {
        my $ref_parents = &get_parents($child);
        foreach my $parent (@$ref_parents) {
            my ($x1, $y1, $z1) = @{$array_lookup_id_to_hash{$child} {canvas}};
            my ($x2, $y2, $z2) = @{$array_lookup_id_to_hash{$parent}{canvas}};
            $is_covered_by{$child}{$parent}{entity} = $c->createLine($x1, $y1, $x2, $y2,
                -tags =>  $is_covered_by{$child}{$parent}{active} ? "is_covered_by_highlighted" : "is_covered_by",
                -fill =>  $is_covered_by{$child}{$parent}{colour},
                -width => $is_covered_by{$child}{$parent}{width},
                -activefill => 'red',
                -activewidth => $activewidth_is_covered_by,
            );
        }
    }
}

sub tk_plot_elements {
    foreach my $h (0..$#array_with_coords) {
        my @elements = @{$array_with_coords[$h]};
        foreach my $j (0..$#elements) {
            my $id = $array_with_coords[$h][$j]{id};
            my $ref_coords = $array_with_coords[$h][$j]{coords};
            my $ref_canvas = $array_with_coords[$h][$j]{canvas};
            my ($x, $y, $z) = @$ref_canvas;    # centre
            my $x1 = $x - $element_radius;     # left
            my $x2 = $x + $element_radius;     # right
            my $y1 = $y + $element_radius;     # lower
            my $y2 = $y - $element_radius;     # upper

            $element{$id} = $c -> createOval($x1, $y1, $x2, $y2,
                -tags =>    $array_with_coords[$h][$j]{active} ? "element_highlighted" : "element",
                -outline => $array_with_coords[$h][$j]{active} ? 'black' : 'gray75',    # outline of circles
                -fill =>    $array_with_coords[$h][$j]{colour},
                -activeoutline => 'red',
                -activefill =>    'red',
            );                                 # lower-left, upper-right

            $element_id{$id} = $c -> createText($x2 + $element_radius , $y2 - $element_radius,
                -text => $array_with_coords[$h][$j]{id},
                -tags => $array_with_coords[$h][$j]{active} ? "element_highlighted" : "element",
                -fill => 'gray75',    # text colour of inactive labels
            );

            if ($array_with_coords[$h][$j]{label}) {
                $element_label{$id} = $c -> createText($x2 + $element_radius , $y1 + $element_radius,
                    -text => $array_with_coords[$h][$j]{label},
                    -tags => "element_label",
                    -fill => 'black',
                );
            }
        }
    }
}

sub tk_display_order {
    my @labels = reverse @_;  # from front to back
    $c -> raise($labels[$_], $labels[$_-1]) for 1..$#labels;
}

### end open file
### begin save file

sub create_new_assy {
    # print "... create_new_assy\n";
    my @list = ();
    ### first pass
    foreach my $entry ( $tree -> child_entries( '', 20) ) {
        push @list, [split '\.', $entry];
    }
    ### second pass
    my $current = "";
    my @new;
    foreach my $ref (reverse @list) {
        my @entities = @{$ref};
        # print "@entities\n";
        if ($#entities > 0) {
            my $child = pop @entities;
            my $parent = pop @entities;
            if ($parent eq $current) {
                unshift @{$new[$#new]}, $child;
                # print ", $child\n";
            } else {
                $current = $parent;
                $new[$#new + 1] = [($child, $parent )];
                # print "$parent - $child\n";
            }
        }
    }
    ### third pass
    foreach my $ref (@new) {
        unshift @{$ref}, pop @{$ref};
    }
    ### fourth (non-functional) pass
    # foreach my $ref (@new) {
    #     print "@{$ref}\n";
    # }
    return \@new;
}

sub file_save {
    &step_delete_old;
    my $ref_new = &create_new_assy($tree);
    foreach my $set (@$ref_new) {
        my @list = @$set;
        # print "file_save ... @list\n";
        &create_new_shape_def_rep(@list);
    }
    my $file = $new_assy_name . ".STEP" if $new_assy_name;

    my $fs = $mw -> FileSelect(
        -initialdir => "../step_data/output",
        -filter => "*.STEP",
        -initialfile => $file,
        -create => 1,
        -acceptlabel => 'Save',
        -width => 30,
    );
    my $icon = $fs -> Photo(-file => "./resources/icons/32x32/Actions-document-edit-icon-40.gif");
    $fs -> iconimage($icon);
    $fs -> title("StrEmbed-4 File Save");

    $mw -> withdraw;
    $file = $fs -> Show( -popover => $mw );
    $mw -> deiconify;

    &output_step_file($file) if $file;
}

### assembly tree

sub print_tree_items {
    my @items = @_;
    foreach my $ref_list (@items) {
        my ($name, $item) = @{$ref_list};
        print "$name $item\n";
    }
}

sub insert_tree_items {
    ### i/p - @Htree
    ### o/p - $tree Tk gui
    foreach my $ref (@_) {
        my @list = @{$ref};
        my $end = $list[$#list];
        $tree -> add(
            CORE::join( '.', @list),    # clash hypercube &core()
            -text => $end,
        );
    }
    $tree -> autosetmode;
    $tree -> focusFollowsMouse;
    $tree -> configure(
        -selectmode => 'extended',
        -selectbackground => 'LightBlue2',
        -browsecmd => [\&browse_entry],
        # -closecmd => [\&browse, "close"], 
        # -opencmd => [\&browse, "open"], 
    );
}

sub print_B3 {
    print "print_B3\n";
    print "@_\n";
    my ($widget) = @_;
    my $e = $widget -> XEvent;
    print "$e\n";
}

sub print_B2 {
    print "print_B2\n";
}

sub print_mousewheel {
    print "print_mousewheel\n";
}

sub select_entry {
    # enter - item 0 imagetext body
    # leave - item
    $selected_entry = $_[0];
}

sub click_entry {
    my @list = @_;
    our $entry = $_[$#_];
    our $target;
    our $current;
    our $popup = new MainWindow;
    $popup -> optionAdd('*font', 'Helvetica 10');
    $popup -> title("Move tree to");
    my $icon = $popup -> Photo(-file => "./resources/icons/32x32/Actions-document-edit-icon-40.gif");
    $popup -> iconimage($icon);
    $popup -> bind('<Leave>' => [ sub {$popup -> destroy if $popup eq $Tk::widget} ]);

    my $name1 = $popup -> Entry(-textvariable => \$entry) -> pack;
    my $name2 = $popup -> Entry(-textvariable => \$target) -> pack;
    my $button1 = $popup -> Button(
        -text => "insert before",
        -command => [\&capture, "insert_before"],
    ) -> pack;
    my $button2 = $popup -> Button(
        -text => "insert after",
        -command => [\&capture, "insert_after"],
    ) -> pack;
    my $button3 = $popup -> Button(
        -text => "adopt",
        -command => [\&capture, "adopt" ],
    ) -> pack;
    my $button4 = $popup -> Button(
        -text => "assy",
        -command => [\&capture, "assy" ],
    ) -> pack;
    my $button5 = $popup -> Button(
        -text => "collapse",
        -command => [\&capture, "collapse" ],
    ) -> pack;
    my $button6 = $popup -> Button(
        -text => "Cancel",
        -command => [ sub {$popup -> destroy } ],
    ) -> pack;
    
    my $Ptree = $popup -> ScrlTree(
        -scrollbars => 'se',
        -width => 40,
        -height => 20,
        -browsecmd => [ sub {$current = shift} ],
    ) -> pack;

    foreach my $ref (@assy_tree) {
        my @list = @{$ref};
        my $end = $list[$#list];
        $Ptree -> add(
            CORE::join( '.', @list),    # clash hypercube &core()
            -text => $end,
        );
    }

    $Ptree -> bind('<ButtonPress>', [ sub {$entry = $current} ]);
    $Ptree -> bind('<ButtonRelease>', [ sub {$target = $current} ]);

    $Ptree -> autosetmode;
    $Ptree -> focusFollowsMouse;

    sub capture {
        my $action = shift;
        @assy_tree = &change_tree(\@assy_tree, $action, $entry, $target);
        $popup -> destroy;
        &delete_tree;
        &insert_tree_items(@assy_tree);
    }
}

### call backs

sub browse_entry {
    my @list = split '\.', shift;
    $entry_under_cursor = pop @list;
    # print "$entry_under_cursor\n";
}

sub tk_callback_B1 {
    my ($widget, $event, $motion, @list) = @_;
    # my $entry = $widget -> rooty;
    if ($motion eq "Press") {
        # print "> $entry_under_cursor\n";
        $entry_first_selected = $entry_under_cursor;
        $entry_second_selected = "";
    } elsif ($motion eq "Release") {
        # print ". $entry_under_cursor\n";
        $entry_second_selected = $entry_under_cursor;
    } else {
        # print "error...\n";
    }
}

sub tk_callback_B2 {
    my @list = @_;
    print "B2 - @list\n";
}

sub tk_callback_tree{
    my @list = @_;
    # print "B3 tk_callback_tree - @list\n";
    my @selection = $tree -> info("selection");
    print "*** selection ***\n";
    print "$_\n" foreach @selection;
    print "\n";
}

sub tk_callback_entity {
    my $entity = shift;
    print "clicked entity > $entity\n";
    our $option_menu = $mw -> Menu(
        -label => "Re-arrange tree",
        -options => ["move up", "move down", "level up", "create sub-assy"],
        -command => \&tk_callback_entity_options,
    ) -> pack(
        -x => $tree -> rootx + 300,
        -y => $tree -> rooty,
    );
}

### POPUP

sub showmenu {
  my ($self, $x, $y, $widget) = @_;
  my $label = $widget -> cget('text');
  our $option_menu -> insert(0, 'command',
    -label => $label,
    -command => sub { print "Clicked $label.\n" },
  );
  $option_menu -> post($x, $y);
  $option_menu -> delete(0,0);
}

sub item1 { print "Item 1!\n" }
sub item2 { print "Item 2!\n" }

### END POPUP

sub tk_callback_entity_options {
    our $option_menu;
    my $option = shift;
    print "got: $option\n";
    # $option_menu -> destroy ;
}

sub tk_assembly_tree {

    ### Frame for tree editing

    my $f_tree = $mw -> Frame(
        -width => 60,
        -label => "Assembly tree",
    ) -> pack(
        -fill => 'both',
        -side => 'left',
        -expand => 1,

    );

    $tree = $f_tree -> ScrlTree(
        -scrollbars => 'se',
        -width => 40,
        -browsecmd => \&select_entry,
        -command => [\&click_entry, "abc", "xyz", "123", "789"],
    ) -> pack(
        -side => 'top',
        -fill => 'both',
        -expand => 1,
    );

    $tree -> bind('<ButtonPress-1>'           => [\&tk_callback_B1, "Button",         "Press"]);
    $tree -> bind('<ButtonRelease-1>'         => [\&tk_callback_B1, "Button",         "Release"]);
    $tree -> bind('<Control-ButtonPress-1>'   => [\&tk_callback_B1, "Control-Button", "Press"]);
    $tree -> bind('<Control-ButtonRelease-1>' => [\&tk_callback_B1, "Control-Button", "Release"]);
    $tree -> bind('<Shift-ButtonPress-1>'     => [\&tk_callback_B1, "Shift-Button",   "Press"]);
    $tree -> bind('<Shift-ButtonRelease-1>'   => [\&tk_callback_B1, "Shift-Button",   "Release"]);
    $tree -> bind('<Button-2>' => [\&tk_callback_B2, 'qwerty' ]);
    $tree -> bind('<Button-3>' => [\&tk_callback_tree, "xyz"]);
    # $tree -> bind('<MouseWheel>' => [\&print_mousewheel]);

    $f_tree -> Entry(
        -text => "Entry under cursor",
        -state => 'disable',
        -relief => 'flat',
    ) -> pack;
    $f_tree -> Entry(
        -textvariable => \$entry_under_cursor,
    ) -> pack;
    $f_tree -> Entry(
        -text => "First entry selected",
        -state => 'disable',
        -relief => 'flat',
    ) -> pack;
    $f_tree -> Entry(
        -textvariable => \$entry_first_selected,
    ) -> pack;
    $f_tree -> Entry(
        -text => "Second entry selected",
        -state => 'disable',
        -relief => 'flat',
    ) -> pack;
    $f_tree -> Entry(
        -textvariable => \$entry_second_selected,
    ) -> pack;

    ###

    my $box = $f_tree -> Frame(
        # -scrollbars => 'se',
        -width => 40,
    ) -> pack(
        -side => 'bottom',
        # -fill => 'both',
        # -expand => 1,
    );
    $box -> focusFollowsMouse;
    # $box -> packForget;

    my $icon_scroll_up_up     = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-up-double-icon-small.png");
    my $icon_scroll_up        = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-up-icon-small.png");
    my $icon_scroll_down      = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-down-icon-small.png");
    my $icon_scroll_down_down = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-down-double-icon-small.png");
    my $icon_level_up         = $box->Photo(-file => "./resources/icons/visualpharm/must_have_icon_set/Undo/Undo_32x32.png");
    my $icon_level_down       = $box->Photo(-file => "./resources/icons/visualpharm/must_have_icon_set/Redo/Redo_32x32.png");

    my $button1 = $box -> Button(
        -command => [\&tk_button_callback, "up up"],
        -image => $icon_scroll_up_up,
    ) -> pack (
        -side => 'top',
    );

    my $button1a = $box -> Button(
        -command => [\&tk_button_callback, "up"],
        -image => $icon_scroll_up,
    ) -> pack (
        -side => 'top',
    );

    my $button4 = $box -> Button(
        -command => [\&tk_button_callback, "down down"],
        -image => $icon_scroll_down_down,
        # -text => "To the bottom",
    ) -> pack (
        -side => 'bottom',
    );

    my $button1b = $box -> Button(
        -command => [\&tk_button_callback, "down"],
        -image => $icon_scroll_down,
    ) -> pack (
        -side => 'bottom',
    );

    my $button2 = $box -> Button(
        -command => [\&tk_button_callback, "level up"],
        -image => $icon_level_up,
    ) -> pack (
        -side => 'left',
        -expand => 1,
        # -fill => 'x',
    );

    my $button3 = $box -> Button(
        -command => [\&tk_button_callback, "level down"],
        -image => $icon_level_down,
    ) -> pack (
        -side => 'right',
        -expand => 1,
        # -fill => 'x',
    );

    my $balloons = $box -> Balloon(
        -background => 'gray95',
    );
    my $b1  = $balloons -> attach($button1,  -balloonmsg => "Scroll to Top", -statusmsg => "Status bar message");
    my $b1a = $balloons -> attach($button1a, -balloonmsg => "Scroll Up", -statusmsg => "Status bar message");
    my $b1b = $balloons -> attach($button1b, -balloonmsg => "Scroll Down", -statusmsg => "Status bar message");
    my $b4  = $balloons -> attach($button4,  -balloonmsg => "Scroll to Bottom", -statusmsg => "Status bar message");
    my $b2  = $balloons -> attach($button2,  -balloonmsg => "Move Level Up", -statusmsg => "Status bar message");
    my $b3  = $balloons -> attach($button3,  -balloonmsg => "Move Level Down", -statusmsg => "Status bar message");
}

### button callbacks

sub tk_button_parts {
    my $entry = shift;
    # print "do sthg $chosen_part\n";
    $info -> insert( 'end', qq(Part or sub-assembly "$chosen_part" is chosen\n),);
    push @list_of_assembly_parts, $chosen_part;
    # print "list of assembly parts @list_of_assembly_parts\n";
    splice @available_atoms_n_subassemblies, $chosen_index, 1;
    $new_assy_name = "assy_" . $assy_counter;
    $ff_button_assy -> configure (-state => 'normal') if $#list_of_assembly_parts > 0;
    $ff_button_parts -> configure(-state => 'disabled');
}

### middle canvas

sub tk_canvas {
    my $frame = $mw -> Frame(
        -label => "Hasse diagram",
    ) -> pack;
    $c = $frame -> Canvas(
        -width => $x_normal,
        -height => $y_normal,
        -background => 'gray95',
    ) -> pack(
        -anchor => 'nw',
    );
}

###
### callbacks
###

sub tk_button_callback {
    my $arrow = shift;
    print "<$selected_entry> - button <$arrow>\n";
}

###
### subroutines
###

sub fisher_yates_shuffle {
    # Perl Cookbook 4.17. Randomizing an Array
    # generate a random permutation of @array in place
    # Usage: fisher_yates_shuffle( \@array )
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub next_available_height_n {
    my $sibling = shift;
    my @list = @_;
    # &fisher_yates_shuffle( \@list );   # sounds good but actually not a good idea (more options)
    foreach my $element (@list) {
        my $label = $array_lookup_id_to_hash{$element}{label};        
        unless ($label) {
            $array_lookup_id_to_hash{$element}{label} = $sibling;
            return $element;
        }
    }
}

sub tk_check_if_all_exists {
    my @siblings = @_;
    my $all_exists = 1;
    foreach my $siblings (@siblings) {
        $all_exists = $all_exists && defined $embedded{$siblings};
    }
    return $all_exists;
}

sub tk_to_be_embedded_list {
    my $ref = shift;
    my %embedded = %$ref;
    my @list = ();
    while (my ($part, $available) = each %embedded) {
        push @list, $part if $available;
    }
    return @list;
}

sub tk_siblings {
    my $element = shift;
    my @siblings;
    if (&is_covered_by($element)) {
        @siblings = &covers( &is_covered_by($element) );
    } else {
        @siblings = ();
    }
    return @siblings;
}

sub tk_parent {
    my $element = shift;
    return &is_covered_by($element);
}

sub tk_turn_off_is_covered_by {
    $c -> itemconfigure("is_covered_by", -state => 'hidden');
    $c -> itemconfigure("element", -state => 'hidden');
}

sub tk_turn_on_is_covered_by {
    $c -> itemconfigure("is_covered_by", -state => 'normal');
    $c -> itemconfigure("element", -state => 'normal');
}

###

sub tk_hamming_weight {
    my $integer = shift;
    my $count = 0;
    foreach (0..$max) {
        $count++ if $integer % 2 == 1;
        $integer = $integer >> 1;
    }
    return $count;
}

sub tk_if_n_bigger_than_m {
    my ($n, $m) = @_;
    my ($ref_n_p, $ref_n_c) = &get_parents_children($n);
    my ($ref_m_p, $ref_m_c) = &get_parents_children($m);
    my @n_list = (@{$ref_n_p}, @{$ref_n_c});
    my @m_list = (@{$ref_m_p}, @{$ref_m_c});
    my $original_distance = &tk_distance_sum_of_parents_n_children($n, \@n_list) +
                            &tk_distance_sum_of_parents_n_children($m, \@m_list);
    my $swapped_distance  = &tk_distance_sum_of_parents_n_children($n, \@m_list) +
                            &tk_distance_sum_of_parents_n_children($m, \@n_list);

    return $original_distance > $swapped_distance;
}

sub tk_distance_sum_of_parents_n_children {
    my ($e, $ref_f_list) = @_;
    my @f_list = @$ref_f_list;
    my $distance = 0;
    foreach my $f (@f_list) {
        my $ref_e_coords = $array_lookup_id_to_hash{$e}{canvas};
        my $ref_f_coords = $array_lookup_id_to_hash{$f}{canvas};
        $distance += &tk_distance($ref_e_coords, $ref_f_coords);
    }
    return $distance;
}

sub tk_distance {
    my ($ref_P, $ref_Q) = @_;
    my ($xP, $yP, $zP) = @$ref_P;
    my ($xQ, $yQ, $zQ) = @$ref_Q;
    return sqrt (($xP-$xQ)**2 + ($yP-$yQ)**2 + ($zP-$zQ)**2);
}

sub tk_swap {
    my ($n, $m) = @_;
    ($array_lookup_id_to_hash{$m}{canvas},
     $array_lookup_id_to_hash{$n}{canvas}) =
    ($array_lookup_id_to_hash{$n}{canvas},
     $array_lookup_id_to_hash{$m}{canvas});  
}

###
### functions
###

sub tk_hasse {
    ### i/p - \@array
    ### o/p - %array_lookup_id_to_hash
    ###     - @array_with_coords

    my $ref_array = shift;
    my @array = @$ref_array;
    my ($x_origin, $y_origin, $x_interval, $y_interval) = &tk_scale_settings($ref_array);

    foreach my $h (0..$#array) {    # at height h
        my @elements = @{$array[$h]};
        my $width = $#elements + 1;
        foreach my $j (0..$#elements) {
            my $id = $array[$h][$j];
            my $xc = (- $#elements / 2) + $j;
            my $yc = $h;
            my $zc = 0;
            my $x_screen = $x_origin + $xc * $x_interval;
            my $y_screen = $y_origin - $yc * $y_interval;
            my $z_screen = 0;
            $array_with_coords[$h][$j] = {
                id => $id,
                label => 0,
                coords => [$xc, $yc, $zc],
                canvas => [$x_screen, $y_screen, $z_screen],
            };
            $array_lookup_id_to_hash{$id} = $array_with_coords[$h][$j];
        }

        #foreach my $h (0..$#array_with_coords) {    # at height h
        #my @ee = @{$array_with_coords[$h]};
        #    foreach my $j (0..$#ee) {
        #        my $id = $array_with_coords[$h][$j]{id};
        #        my $ref_coords = $array_with_coords[$h][$j]{coords};
        #        my $ref_canvas = $array_with_coords[$h][$j]{canvas};
        #    }
        #}
    }
    return \%array_lookup_id_to_hash, \@array_with_coords;
}

sub tk_scale_settings {
    ### i/p - \@array
    ### o/p - origin on cancvas
    ###     - interval between widths
    ###     - interval between heights

    my $ref_array = shift;
    my @array = @$ref_array;                     my $max_height = $#array;
    my @elem  = @{$array[int $max_height/2]};    my $max_width  = $#elem;
    my $x_middle = $x_normal / 2;
    my $y_middle = $y_normal / 2;
    my $x_usable_width  = $x_normal * 0.9;
    my $y_usable_height = $y_normal * 0.9;
    my $x_interval = my $y_interval = 0;
       $x_interval = $x_usable_width  / $max_width  unless $max_width  == 0;
       $y_interval = $y_usable_height / $max_height unless $max_height == 0;
       $x_interval = $y_interval if $x_interval > $y_interval;
    my $x_origin = $x_middle;
    my $y_origin = $y_middle + $y_interval * $max_height / 2;

    return ($x_origin, $y_origin, $x_interval, $y_interval);
}
