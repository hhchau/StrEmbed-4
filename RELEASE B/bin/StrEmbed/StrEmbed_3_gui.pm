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

# StrEmbed::StrEmbed_3_gui.pm
# StrEmbed-3 release A - HHC 2017-01-06
# HHC - 2017-01-16 - Version 3 Release A Update 1 -- StrEmbed-3 (A1)
# HHC - 2017-01-26 - Version 3 Release A Update 2 -- StrEmbed-3 (A2)
# HHC - 2017-01-30 - carry on

require 5.002;
use warnings;
use strict;
use Tk;
use Tk::Font;
use Tk::Balloon;
use Tk::Tree;
use Tk::DirTree;
use Tk::PNG;
use Time::HiRes qw/usleep/;

our $max;
our %elements_available;

my ($x_normal, $y_normal) = (1440, 720);
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
my $menu_00;
my %entity;
my $entity_focused;
my $tree_cache;
my @available_atoms_n_subassemblies;
my $chosen_part;
my $chosen_index;
my @list_of_assembly_parts;
my $new_assy_name;
my @assy_list_of_list;
my $assy_counter = 1;
my $ff_button_assy;
my $ff_button_parts;
my $menu_01;

return 1;

###
### Tk gui widgets
###

sub tk_mainloop {

    # Main Window

    $mw = new MainWindow;
    $mw -> geometry('+0+20');
    $mw -> minsize($x_min, $y_min);
    $mw -> optionAdd('*font', 'Helvetica 10');
    my $label = $mw -> Label(-text => "StrEmbed-3")->pack;
    my $icon = $mw -> Photo(-file => "./resources/icons/32x32/Actions-document-edit-icon-40.gif");
    # $mw->idletasks;        # this line is crucial
    $mw->iconimage($icon);
    
    &tk_pulldown_menu;
    &tk_lower_frame;
    &tk_assembly_tree;
    &tk_canvas;
    # &tk_create_new_assy_from_atoms;

    MainLoop;
}

sub XXX_tk_create_new_assy_from_atoms {
    my @atoms = &step_count_atomic_part;
    print "xxx @atoms\n";
}

sub tk_pulldown_menu {

    # menu bar

    my $pm = $mw -> Frame(
#        -height => 15,
    )-> pack(
        -side => 'top',
        -anchor => 'w',
        -fill => 'x',
    );

    $menu_00 = $pm -> Menubutton( -text => "Open",
        -menuitems => [
            # [ 'command' => "Open",                 -command => sub { &open_file} ],
            [ 'command' => "puzzle 1b",            -command => sub { &step_open("../step_data/input/puzzle_1b.STEP"); &big_bundle; } ],
            [ 'command' => "puzzle 1c",            -command => sub { &step_open("../step_data/input/puzzle_1c.STEP"); &big_bundle; } ],
            [ 'command' => "puzzle 1d",            -command => sub { &step_open("../step_data/input/puzzle_1d.STEP"); &big_bundle; } ],
            [ 'command' => "Robot-Arm-5-parts",    -command => sub { &step_open("../step_data/input/Robot-Arm-5-parts.STEP"); &big_bundle; } ],

            # [ 'command' => "lock assembly eg",     -command => sub { &step_open("../step_data/input/lock_assembly_eg.STEP"); &big_bundle; } ],
            # [ 'command' => "lock assy (flat)",     -command => sub { &step_open("../step_data/input/lock_assy_5_parts_flat.STEP"); &big_bundle; } ],
            # [ 'command' => "lock assy (15 parts)", -command => sub { &step_open("../step_data/input/lock_6-pin_assembly_eg_less_one.STEP"); &big_bundle; } ],
            "-",
            [ 'command' => "~Exit",                -command => sub { exit } ],                      
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    $menu_01 = $pm -> Menubutton( -text => "Save",
        -menuitems => [
            [ 'command' => "~Save STEP file", -command => sub { &tk_save_step_file } ],
            [ 'command' => "~Exit", -command => sub { exit } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_02 = $pm -> Menubutton( -text => "Background 2^n lattice",
        -menuitems => [
            [ 'command' => "O~ff", -command => sub { &tk_turn_off_is_covered_by } ],
            [ 'command' => "O~n", -command => sub { &tk_turn_on_is_covered_by } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );
=ccc
    my $menu_03 = $pm -> Menubutton( -text => "Exit",
        -menuitems => [
            [ 'command' => "~Exit", -command => sub { exit } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_1 = $pm -> Menubutton( -text => "File",
        -state => 'disabled',
        -menuitems => [
            [ 'command' => "~New",                -command => sub { &tk_new_file } ],
            [ 'command' => "~Open",               -command => sub { &step_open } ],
            [ 'command' => "~Delete old",         -command => sub { &step_delete_old } ],
            [ 'command' => "New S~TEP structure", -command => sub { &step_main_loop } ],
            [ 'command' => "~Save",               -command => sub { &step_save } ],
            "-",
            [ 'command' => "~Exit",               -command => sub { exit } ],                      
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_2 = $pm -> Menubutton( -text => "STEP",
        -state => 'disabled',
        -menuitems => [
            [ 'command' => "print part",          -command => sub { &step_print_part } ],
            [ 'command' => "print shape_def_rep", -command => sub { &step_print_shape_def_rep } ],
            "-",
            [ 'command' => "produce parent child pairs",  -command => sub { &step_produce_parent_child_pairs } ],
            [ 'command' => "produce assembly has parent", -command => sub { &step_produce_assembly_has_parent } ],
            "-",
            [ 'command' => "insert tree items",     -command => sub { &tk_insert_tree_items } ],
            "-",
            [ 'command' => "count atomic part",     -command => sub { &tk_count_atomic_part } ],
            "-",
            "-",
            [ 'command' => "Open file + 4-in-1 ++", -command => sub {
                # &step_open;
                &step_produce_parent_child_pairs;
                &step_produce_assembly_has_parent;
                &tk_insert_tree_items;
                &tk_count_atomic_part;
                &hypercube_corresponding_to_step_file;
                &tk_optimise;
                &tk_clear_canvas;
                &tk_setup_initial_colour_for_covered_by;
                &tk_plot_is_covered_by;
                &tk_setup_initial_colour_for_elements;
                &tk_plot_elements;
                &tk_embed_height_0;
                &tk_embed_height_n;
                &tk_highlight_relations;
                &tk_highlight_is_covered_by;
                &tk_clear_canvas;

                ### 3-in-1
                &tk_optimise;
                &tk_clear_canvas;
                &tk_plot_is_covered_by;
                &tk_plot_elements;                
            } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_3 = $pm -> Menubutton( -text => "Hypercube",
        -state => 'disabled',
        -menuitems => [
            # [ 'command' => "~Generate", -command => sub { &hypercube_corresponding_to_step_file } ],
            # [ 'command' => "~Embed",    -command => sub { &tk_embed } ],
            [ 'command' => "Embed ~0",  -command => sub { &tk_embed_height_0 } ],
            [ 'command' => "Embed ~1",  -command => sub { &tk_embed_height_n } ],
            [ 'command' => "~Highlight relations", -command => sub { &tk_highlight_relations } ],
            [ 'command' => "Highlight is ~covered by", -command => sub { &tk_highlight_is_covered_by } ],            
            # [ 'command' => "Embed ~Test",  -command => sub { &tk_embed_test } ],
            ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_4 = $pm -> Menubutton( -text => "Plot",
        # -state => 'disabled',
        -menuitems => [
            [ 'command' => "clear\n~3-in-1", -command => sub {
                &tk_clear_canvas;
                &tk_optimise;
                &tk_clear_canvas;
                &tk_plot_is_covered_by;
                &tk_plot_elements;
                &tk_turn_off_is_covered_by;
            } ],
            "-",
            [ 'command' => "~Optimise",      -command => sub { &tk_optimise } ],
            [ 'command' => "~Is covered by", -command => sub { &tk_plot_is_covered_by } ],
            [ 'command' => "~Elements",      -command => sub { &tk_plot_elements } ],
            "-",
            [ 'command' => "ID",             -command => sub { &tk_plot_ids } ],
            [ 'command' => "Label",          -command => sub { &tk_plot_labels } ],
            "-",
            [ 'command' => "~Clear canvas",  -command => sub { &tk_clear_canvas } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_5 = $pm -> Menubutton( -text => "Assemby tree",
        -state => 'disabled',
        -menuitems => [
            [ 'command' => "~Tree", -command => sub { &tk_insert_tree_items } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );
=cut

    my $menu_96 = $pm -> Menubutton( -text => "Plot",
        -state => 'normal',
        -menuitems => [
            [ 'command' => "~Resume optimisation", -command => sub {
                &tk_clear_canvas;
                &tk_optimise;
                &tk_clear_canvas;
                &tk_plot_is_covered_by;
                &tk_plot_elements;
                &tk_turn_off_is_covered_by;
            } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_99 = $pm -> Menubutton( -text => "Help",
        -state => 'normal',
        -menuitems => [
            # [ 'command' => "Users' ~manual", -command => sub { &tk_users_manual } ],
            [ 'command' => "~About",         -command => sub { &tk_about } ],
            [ 'command' => "~Copyright",     -command => sub { &tk_copyright } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'right',
    );

    my $menu_98 = $pm -> Menubutton( -text => "Exit",
        -state => 'normal',
        -menuitems => [
            [ 'command' => "~Exit",         -command => sub { exit } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'right',
    );
}

sub tk_users_manual {
}

sub tk_about {
    my $message = "University of Leeds
The Open University

StrEmbed-3
Embedding design structures in engineering information

Structure Embedding version 3 (StrEmbed-3) is a deliverable from the
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
    my $about_text = $popup_about -> Text(
        -background => 'gray95',
        -relief => 'flat',
    ) -> pack;
    $about_text -> insert('end', $message);

}

sub tk_copyright {
    my $message = "StrEmbed-3 - Embedding assembly structure on to a corresponding hypercube lattice
Copyright (C) 2016  University of Leeds

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
    my $about_text = $popup_copyright -> Text(
        -background => 'gray95',
        -relief => 'flat',
    ) -> pack;
    $about_text -> insert('end', $message);

}


### lower tree, toggle, optimisation

sub tk_lower_frame {
    my $f = $mw -> Frame -> pack(
        -side => 'bottom',
        -fill => 'x',
    );

    ### display toggles

    $info = $f -> Scrolled("Text",
        -height => 5,
        -scrollbars => 'e',
        # -yscrollcommand => 1,
        -width => 20,
        -background => 'gray95',
        -relief => 'flat',
    ) -> pack(
        -fill => 'both',
        -side => 'left',
        -expand => 1,
    );

    $info -> insert( 'end', "This space is reserved for user messages.\n",);
    # $info -> configure(-state => 'disabled');

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

sub big_bundle {
    $menu_00 -> configure(-state => 'disabled');
    &step_produce_parent_child_pairs;
    &step_produce_assembly_has_parent;
    &tk_insert_tree_items;
    &tk_count_atomic_part;
    &hypercube_corresponding_to_step_file;
    &tk_optimise;
    &tk_clear_canvas;
    &tk_setup_initial_colour_for_covered_by;
    &tk_plot_is_covered_by;
    &tk_setup_initial_colour_for_elements;
    &tk_plot_elements;
    &tk_embed_height_0;
    &tk_embed_height_n;
    &tk_highlight_relations;
    &tk_highlight_is_covered_by;
    &tk_clear_canvas;

    ### 3-in-1
    &tk_optimise;
    &tk_clear_canvas;
    &tk_plot_is_covered_by;
    &tk_plot_elements;
    &tk_display_order;    
}

sub tk_display_order {
    $c -> raise("element", "is_covered_by");
    $c -> raise("is_covered_by_highlighted", "element");
    $c -> raise("element_highlighted", "is_covered_by_highlighted");
}

### open file

sub open_file {
    print "open file\n";
    my $popup = new MainWindow;
    $popup -> geometry('+50+50');
    $popup -> minsize(640, 480);
    $popup -> optionAdd('*font', 'Helvetica 10');
    $popup -> Label(-text => "Open file")->pack;
    # my $icon2 = $popup -> Photo(-file => "./resources/icons/32x32/Actions-document-edit-icon-40.gif");
    # $popup->idletasks;        # this line is crucial
    # $popup->iconimage($icon2);


    my $directory = $popup -> Scrolled( "DirTree",
        -directory => "../step_data/input",
        -scrollbars => 'e',
    ) -> pack(
        -fill => 'both',
        -expand => 1,
    );
    
    my $files = $popup -> Scrolled( "Listbox",
        -scrollbars => 'e',
    ) -> pack(
        -fill => 'both',
        -expand => 1,
    );
}

### assembly tree

sub tk_insert_tree_items {
    ### can't handle duplicate part name at the moment, need to add suffix when reading step file
    # print "tk insert tree\n";
    my @items = &step_produce_tree;
    foreach my $ref_list (@items) {
        my ($name, $item) = @{$ref_list};
        # print "TREE: $item\n";
        # print "name = $name, item = $item\n";
        $entity{$name} = $tree -> add($item,
            -text => $name,
            # -browsecmd => \&tk_callback_entity,
        );
        # print "eee $name\n";
    }
    $tree -> autosetmode;
    $tree -> focusFollowsMouse;
    # $tree -> bind('<Button-3>' => \&tk_callback_tree);   # B3
    # $tree -> bind('<Button-2>' => \&tk_callback_B2);     # B2

    $tree -> configure(
        # -browsecmd => \&tk_callback_entity_browse,
        # -command => \&tk_callback_entity,                # double-click-B1
    );

    while (my ($name, $value) = each %entity) {
        # print "$name = $value\n";    # switched off 2017-01-16
    }
}

sub tk_callback_B2 {
    my @list = @_;
    print "B2 - @list\n";
}

sub tk_callback_tree{
    my @list = @_;
    # print "B3 tk_callback_tree - @list\n";
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

### PROCESS TREE ENTITY(IES)
sub tk_callback_entity_browse {
    ### First button Tree entity callback
    my @list = @_;
    my $this_entity_name = shift @list;
    if (@list) {
        # print "B1 -- $entity_focused @list\n";
        ($entity_focused, my @parents) = &tk_entity_strip($this_entity_name);
        print "$entity_focused\n";
        print "    $_\n" for @parents;
        my @siblings = &tk_siblings($entity_focused);
        my $parent = &tk_parent($entity_focused);
        my @children = &covers($entity_focused);
        print "    who is my parent? >$parent<\n" if $parent;
        print "    who are my siblings? >@siblings<\n";
        print "    who are my children? >@children<\n";
    };    
}

sub tk_entity_strip {
    my $input = shift;
    my @list = split /\./, $input;
    my $entity = pop @list;
    return $entity, reverse @list;
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

    $tree = $f_tree -> Scrolled( "Tree",
        -scrollbars => 'se',
        -width => 40,
    ) -> pack(
        -side => 'top',
        -fill => 'both',
        -expand => 1,
    );

    my $f_assy = $f_tree -> Frame(
        -width => 60,
        -label => "Create new assembly structure",
    ) -> pack(
        -fill => 'both',
        -side => 'top',
        -expand => 1,

    );

    ###
=ccc
    my $label = $f_tree -> Entry(
        -text => "Current entity",
        -state => 'readonly',
        -relief => 'flat',
        -font => ['*font', '10', 'bold'],
    ) -> pack(
        -side => 'top',
        -fill => 'x',
        # -expand => 1,
    );

    my $current_entry = $f_tree -> Scrolled('Entry',
        -text => \$entity_focused,
        -state => 'readonly',
        -scrollbars => 's',
    ) -> pack(
        -side => 'top',
        -fill => 'x',
        # -expand => 1,
    );
=cut
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
    $box -> packForget;

    my $icon_scroll_up_up     = $box->Photo(-file => "./resources/icons/visualpharm/stark_icons/PNG/1998_low_cost_clock/1998_low_cost_clock_32x32.png");
    my $icon_scroll_up        = $box->Photo(-file => "./resources/icons/visualpharm/hardware_icons/PNG/png32/web_camera.png");
    # my $icon_scroll_up_up     = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-up-double-icon-small.png");
    # my $icon_scroll_up        = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-up-icon-small.png");
    my $icon_scroll_down      = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-down-icon-small.png");
    my $icon_scroll_down_down = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-down-double-icon-small.png");
    # my $icon_level_up         = $box->Photo(-file => "./resources/icons/32x32/arrow-left-icon-key.png");
    # my $icon_level_down       = $box->Photo(-file => "./resources/icons/32x32/Actions-go-next-icon-small.png");
    my $icon_level_up         = $box->Photo(-file => "./resources/icons/32x32/arrow-left-icon-key-small.png");
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

    ### Frame for new assembly structure
    my $ff_part_assy_names = $f_assy -> Frame (
    ) -> pack(
        -fill => 'both',
        -side => 'left',
        -expand => 1,
    );

    ###

    my $ff_parts_array = $ff_part_assy_names -> Scrolled('Listbox',
        -scrollbars => 'se',
        -height => 6,
        # -width => 20,
    ) -> pack(
        -side => 'top',
        -fill => 'x',
    );

    $ff_parts_array -> bind('<<ListboxSelect>>' => [
        \&tk_ff_parts_array_select_part,
        "dadsds",
    ]);

    sub tk_ff_parts_array_select_part{
        my @part = @_;
        my @index = $part[0] -> curselection;
        $chosen_index = $index[0];
        $chosen_part = $available_atoms_n_subassemblies[$index[0]];
        # print "adsadfafsa - @part - $chosen_index - $chosen_part\n";
        $ff_button_parts -> configure(-state => 'normal');
    }

    $ff_parts_array -> insert('end', @available_atoms_n_subassemblies );
    tie @available_atoms_n_subassemblies, "Tk::Listbox", $ff_parts_array;

    $ff_button_parts = $ff_part_assy_names -> Button(
        -text => "SELECT parts and/or sub-assemblies",
        -command => [\&tk_button_parts, "tk button parts"],
        -state => 'disabled',
    ) -> pack (
        -side => 'top',
        -expand => 1,
        -fill => 'x',
    );

    ###

    my $ff_assy_name = $ff_part_assy_names -> Scrolled('Entry',
        -textvariable => \$new_assy_name,
        -scrollbars => 's',
    ) -> pack(
        -side => 'top',
        -fill => 'x',
    );

    $ff_button_assy = $ff_part_assy_names -> Button(
        -text => "CREATE a new sub- (or top level) assembly",
        -command => [\&tk_button_assy, "tk button assy"],
        -state => 'disabled',
    ) -> pack (
        -side => 'top',
        -expand => 1,
        -fill => 'x',
    );

    ###
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

sub tk_button_assy {
    # print "@list_of_assembly_parts ($new_assy_name)\n";
    if ($new_assy_name =~ /^(?:[A-Za-z0-9_-]+,?)+(?<!,)$/) {
        # print "good\n";
        $info -> insert( 'end', qq(Sub-assembly "$new_assy_name" is created with part(s)/subassembly(ies) "@list_of_assembly_parts"\n), );
        push @available_atoms_n_subassemblies, $new_assy_name if @available_atoms_n_subassemblies;
        push @assy_list_of_list, [$new_assy_name, @list_of_assembly_parts];
        @list_of_assembly_parts = ();
        $assy_counter++;
        $ff_button_assy -> configure (-state => 'disabled');
        $info -> insert( 'end', qq(All done. Click "Save -> Save STEP file" to output an AP214 file.) ) if not @available_atoms_n_subassemblies;
        $info -> see('end');
    } else {
        # print "bad\n";
        $info -> insert( 'end', "ERROR: Valid chars are A-Z a-z 0-9 _ -.  Please re-enter new assembly name\n");
        $info -> insert( 'end', qq(Current selected part(s)/subassembly(ies) are "@list_of_assembly_parts"\n), );
        $info -> see('end');
    }
}

sub tk_save_step_file {
    &step_delete_old;
    # print "$new_assy_name\n";
    foreach my $set (@assy_list_of_list) {
        my @list = @$set;
        # print "xxx @list\n";
        &create_new_shape_def_rep(@list);
    }
    &output_step_file("../step_data/output/" . $new_assy_name . ".step");
    $menu_01 -> configure(-state => 'disabled');
}

sub XXX_tk_callback_entity_browse {
    ### THIRD BUTTON MENU CALLBACK
    my @list = @_;
    $entity_focused = $list[0];
    print "tk_callback_entity (browse) - ";
    print "browsed item = @list\n";    
}

sub XX_tk_callback_entity {
    my $entity = shift;
    print "clicked entity > $entity\n";
    our $option_menu -> Menu(
        -tearoff => 0,
    );
    $option_menu = $mw->Menu(-tearoff => 0);
    $option_menu -> add('separator');
    $option_menu -> add('command', -label => 'One', -command => \&item1);
    $option_menu -> add('command', -label => 'Two', -command => \&item2);
    $tree -> bind('<3>', [\&showmenu, Ev('X'), Ev('Y'), Ev('W')]);
    $tree -> focus();
}

sub tk_button_callback {
    my $arrow = shift;
    print "button - scroll to top <$arrow>\n";
}

### middle canvas

sub tk_canvas {
    $c = $mw -> Canvas(
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

sub tk_callback_hlist {
}

###
### subroutines
###

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

sub tk_highlight_relations {
    #  print "tk_highlight_relations\n";

    ### highlight most
    my $ref_parent_child_pair = &step_parent_child_pair;
    my @parent_child_pair = @{$ref_parent_child_pair};
    foreach my $ref_one_pair (@parent_child_pair) {
        my ($parent, $child) = @{$ref_one_pair};
        my $p_id = $lookup_label_to_id{$parent};
        my $c_id = $lookup_label_to_id{$child};
        my @chain = &hypercube_return_chain($p_id, $c_id);
        # print "$parent($p_id) - $child($c_id) -- @chain\n";
        for (my $i=0; $i<$#chain; $i++) {
            # print "$chain[$i] - $chain[$i+1]\n";
            $is_covered_by{$chain[$i+1]}{$chain[$i]}{colour} = 'black';
            $is_covered_by{$chain[$i+1]}{$chain[$i]}{width} = $hightlighted_width_is_covered_by;
            $is_covered_by{$chain[$i+1]}{$chain[$i]}{active} = 1;
        }
    }

    ### highlight inf=zero to atom[s]
    my @atoms = &step_count_atomic_part;
    # print "xxxxxx @atoms.\n";
    @available_atoms_n_subassemblies = @atoms;
    foreach my $atom (@atoms) {
        my $id = $lookup_label_to_id{$atom};
        $is_covered_by{0}{$id}{colour} = 'black';
        $is_covered_by{0}{$id}{width} = $hightlighted_width_is_covered_by;
        $is_covered_by{0}{$id}{active} = 1;
    }

}

sub tk_embed_height_0 {
   my ($e) = &hypercube_elements_at_height(0);
   # print "height 0 = $e\n";
   $array_lookup_id_to_hash{$e}{label} = "0";
   $array_lookup_id_to_hash{$e}{active} = 1;
   $embedded{0} = 0;
   # $elements_available{0} = 0;  ??? inf zero - set to unavailable ???
}

sub fisher_yates_shuffle {
    # Perl Cookbook 4.17. Randomizing an Array
    # fisher_yates_shuffle( \@array ) : generate a random permutation of @array in place
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub tk_embed_height_n {
    my @height_n = &hypercube_elements_at_height(1);
    my @atoms = &step_count_atomic_part;
    # print "height n = @height_n\n";
    my $top_level_assembly = &step_top_level_assembly;

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
    FIRST_ATTEMPT:  my @list = &tk_to_be_embedded_list;
                    # &fisher_yates_shuffle( \@list );  # seems okay-ish
    SECOND_ATTEMPT: my ($first) = @list;
    # print "there are @list\n";
    goto EXIT unless $first;
    goto EXIT if $first eq $top_level_assembly;
    my @siblings = &tk_siblings($first);
    # &fisher_yates_shuffle( \@siblings );  # not here
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
        # print "... @siblings are ready\n";
        foreach my $s (@siblings) {
            my $avail = $embedded{$s};
            # print ". $s [$avail]\n";
        }

        if (defined $embedded{$parent}) {
            my $parent_avail = $embedded{$parent};
            # print "oo $parent [$parent_avail]\n";
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
            # print "xxxxxx bundle @siblings (@bundle_of_ids) -> $parent ($join)\n";
        }
    } else {
        my $swap = shift @list;
        push @list, $swap;
        goto SECOND_ATTEMPT;
    }  # end if all siblings exists and are ready

    $embedded{ &tk_parent($first) } = 1 if &tk_parent($first);
    goto EXIT if $first eq $top_level_assembly;
    goto FIRST_ATTEMPT;
    EXIT:;
}

sub next_available_height_n {
    my $sibling = shift;
    my @list = @_;
    # &fisher_yates_shuffle( \@list );   # sounds good but actually not a good idea
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
    my @list;
    while (my ($part, $available) = each %embedded) {
        push @list, $part if $available;
    }
    return @list;
}

sub tk_count_atomic_part {
    ### i/p - %elements_available
    ### o/p - ??? what is the o/p?  Can I get rid of it in the main loop? ???
    #print "tk/step count atomic part\n";
    my @atoms = &step_count_atomic_part;
    $max = $#atoms + 1;
    # print "n = $max\n";

    foreach my $atom (@atoms) {
        my $available = &tk_is_atom_available($atom);
        # print "$atom ($available) is an atom\n";
    }

    # print "tk/step count atomic part ... 2nd set\n";
    foreach my $element (keys %elements_available) {
        my $available = &tk_is_atom_available($element);
        my @siblings = &tk_siblings($element);
        # print "... $element ($available) has siblings @siblings.\n";
        # print "    $element ($available) is a top level assembly\n" unless @siblings;
    }
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

sub tk_is_atom_available {
    ### i/p - $atom
    ###     - @elements_available
    ### o/p - $available (true or false)
    my $sibling = shift;
    # my @elements_available = @_;
    # while (my ($atom, $available) = each %elements_available) {
    #     return $available if $sibling eq $atom;
    # }
    return $elements_available{$sibling};
}

sub tk_clear_canvas {
    $c -> delete("is_covered_by", "element", "element_id", "element_label", "is_covered_by_highlighted", "element_highlighted");
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

sub tk_turn_off_is_covered_by {
    $c -> itemconfigure("is_covered_by", -state => 'hidden');
    $c -> itemconfigure("element", -state => 'hidden');
}

sub tk_turn_on_is_covered_by {
    $c -> itemconfigure("is_covered_by", -state => 'normal');
    $c -> itemconfigure("element", -state => 'normal');
    &tk_display_order;
}

sub tk_return_tag_is_covered_by {
    my $switch = shift;
    if ($switch) {
        return "is_covered_by_highlighted";
    } else {
        return "is_covered_by";
    }
}

sub tk_return_tag_element {
    my $switch = shift;
    if ($switch) {
        return "element_highlighted";
    } else {
        return "element";
    }
}

sub tk_return_element_colour {
    my $switch = shift;
    if ($switch) {
        return "black";
    } else {
        return "gray75";
    }
}

sub tk_plot_is_covered_by {
    while (my ($child, $ref_hash) = each %array_lookup_id_to_hash) {
        my $ref_parents = &get_parents($child);
        foreach my $parent (@$ref_parents) {
            my ($x1, $y1, $z1) = @{$array_lookup_id_to_hash{$child} {canvas}};
            my ($x2, $y2, $z2) = @{$array_lookup_id_to_hash{$parent}{canvas}};
            $is_covered_by{$child}{$parent}{entity} = $c->createLine($x1, $y1, $x2, $y2,
                -tags => &tk_return_tag_is_covered_by( $is_covered_by{$child}{$parent}{active} ),
                -fill => $is_covered_by{$child}{$parent}{colour},
                -width => $is_covered_by{$child}{$parent}{width},
                -activefill => 'red',
                -activewidth => $activewidth_is_covered_by,
            );
        }
    }
}

sub tk_setup_initial_colour_for_elements {
    foreach my $h (0..$#array_with_coords) {
        my @elements = @{$array_with_coords[$h]};
        foreach my $j (0..$#elements) {
            $array_with_coords[$h][$j]{colour} = 'gray95';
            $array_with_coords[$h][$j]{active} = 0;
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
                -tags => &tk_return_tag_element( $array_with_coords[$h][$j]{active} ),
                -outline => tk_return_element_colour( $array_with_coords[$h][$j]{active} ),
                -fill => $array_with_coords[$h][$j]{colour},
                -activeoutline => 'red',
                -activefill => "red",
            );                                 # lower-left, upper-right

            $element_id{$id} = $c -> createText($x2 + $element_radius , $y2 - $element_radius,
                -text => $array_with_coords[$h][$j]{id},
                # -tags => "element_id",
                -tags => &tk_return_tag_element( $array_with_coords[$h][$j]{active} ),
                -fill => 'gray75',
            );

            if ($array_with_coords[$h][$j]{label}) {
                $element_label{$id} = $c -> createText($x2 + $element_radius , $y1 + $element_radius,
                    -text => $array_with_coords[$h][$j]{label},
                    -tags => "element_label",
                    -fill => 'black',
                    -justify => 'left',   # ??? not working ???
                );
                # $c -> Tk::RotCanvas::rotate($element_label{$id}, 15, $x2, $y1);
            }
        }
    }
}

###

sub tk_optimise {
    $zeros = 0;
    $iterations = 0;
    my $number_of_times = 9999;

    $quit_optimisation = 0;    # need to sort out needing to multiple "Quit" button clicks
    LABEL: while ($zeros <= 2) {    # consider optimised when three sets of 10,000 zeros
    usleep 1;    # need to sort out needing to multiple "Quit" button clicks
        $counter = 0;
        foreach (0..$number_of_times) {
            my $element_count = 1 << $max;
            my $n = int rand() * $element_count;
            my $height = &tk_hamming_weight($n);
            my @list = &hypercube_those_at_height($height);
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
        last LABEL if $quit_optimisation;
    }
    &tk_turn_off_is_covered_by;  # see what happens

}

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
    ### o/p - @array_with_coords
    ###     - %array_lookup_id_to_hash

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

    foreach my $h (0..$#array_with_coords) {    # at height h
        my @ee = @{$array_with_coords[$h]};
            foreach my $j (0..$#ee) {
                my $id = $array_with_coords[$h][$j]{id};
                my $ref_coords = $array_with_coords[$h][$j]{coords};
                my $ref_canvas = $array_with_coords[$h][$j]{canvas};
            }
        }
    }
}

sub tk_scale_settings {
    ### i/p - \@array
    ### o/p - origin on cancvas
    ###     - interval between widths
    ###     - intevval between heights

    my $ref_array = shift;
    my @array = @$ref_array;                     my $max_height = $#array;
    my @ee    = @{$array[int $max_height/2]};    my $max_width  = $#ee;
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
