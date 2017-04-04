#!/usr/bin/perl

# StrEmbed::StrEmbed_3_gui.pm
# HHC - 2016-11-28 - hypercube_sorted.pl - StrEmbed/hypercube_gui.pm
# HHC - 2016-11-29 - StrEmbed3.pl <- StrEmbed3_lattice.pm + StrEmbed3_gui.pm + StrEmbed3_STEP.pm
# HHC - 2016-12-02 - StrEmbed3_gui.pm - using %array_lookup_id_to_hash instead of %array_lookup_id_to_hj
#                  - done swapping n and m if distance(n) > distance(m)
# HHC - 2016-12-05 - good optimisation
#                  - menu/subroutines ordered well with clear canvas
#                  - in three sections - Tk gui widgets, subroutines, functions
# HHC - 2016-12-05 - add STEP module
# HHC - 2016-12-06 - filename is now StrEmbed/StrEmbed_3_gui.pm
# HHC - 2016-12-19 - changed directory tree structure, ready to be uploaded to GitHub
# HHC - 2017-01-03 - back in Leeds

require 5.002;
use warnings;
use strict;
use Tk;
use Tk::Font;
use Tk::Balloon;
use Tk::Tree;
#use Tk::FileDialog;
#use Tk::DirTree;
#use Cwd;
#use Tk::FileSelect;

our $max;
our %elements_available;

my ($x_normal, $y_normal) = (1440, 720);
my ($x_min, $y_min) = (640, 480);
my $element_radius = 6;
my $activewidth_is_covered_by = 3;
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
my $info;
my $status;
my $iterations;
my $zeros;
my $counter;
my $percentage;
my $quit_optimisation;
my %embedded;

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
    
    &tk_pulldown_menu;
    &tk_lower_frame;
    &tk_assembly_tree;
    &tk_canvas;

    MainLoop;
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

    my $menu_1 = $pm -> Menubutton( -text => "File",
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
            [ 'command' => "Open file + 4-in-1", -command => sub {
                &step_open;
                &step_produce_parent_child_pairs;
                &step_produce_assembly_has_parent;
                &tk_insert_tree_items;
                &tk_count_atomic_part;
                &hypercube_corresponding_to_step_file;
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
        -menuitems => [
            [ 'command' => "~Generate", -command => sub { &hypercube_corresponding_to_step_file } ],
            [ 'command' => "~Embed",    -command => sub { &tk_embed } ],
            [ 'command' => "Embed ~0",  -command => sub { &tk_embed_height_0 } ],
            [ 'command' => "Embed ~1",  -command => sub { &tk_embed_height_1 } ],
            [ 'command' => "Embed ~Test",  -command => sub { &tk_embed_test } ],
            ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_4 = $pm -> Menubutton( -text => "Plot",
        -menuitems => [
            [ 'command' => "~3-in-1", -command => sub {
                &tk_optimise;
                &tk_clear_canvas;
                &tk_plot_is_covered_by;
                &tk_plot_elements;
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
        -menuitems => [
            [ 'command' => "~Tree", -command => sub { &tk_insert_tree_items } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'left',
    );

    my $menu_99 = $pm -> Menubutton( -text => "Help",
        -menuitems => [
            [ 'command' => "Users' ~manual", -command => sub { &tk_users_manual } ],
            [ 'command' => "~Copyright",     -command => sub { &tk_copyright } ],
            [ 'command' => "~About",         -command => sub { &tk_about } ],
        ]
    ) -> pack(
        -anchor => 'nw',
        -side => 'right',
    );
}

sub tk_new_file {
    print "tk_new_file\n";
}


=ss

    my $LoadDialog = $mw -> FileDialog (
        -Title => "Open file",
        -Create => 1,
    )
}
my $top = new MainWindow;
$top->withdraw;

my $t = $top->Toplevel;
$t->title("Choose directory:");
my $ok = 0;

my $f = $t->Frame->pack(-fill => "x", -side => "bottom");

my $curr_dir = 'd:';
#my $curr_dir = Cwd::cwd();

my $d;
$d = $t->Scrolled('DirTree',
                  -scrollbars => 'osoe',
                  -width => 35,
                  -height => 20,
                  -selectmode => 'browse',
                  -exportselection =>1,
                  -browsecmd => sub { $curr_dir = shift },
                  -command => sub { $ok = 1; },
                 )->pack(-fill => "both", -expand => 1);

$d->chdir($curr_dir);

$f->Button(-text => 'Ok',
           -command => sub { $ok = 1 })->pack(-side => 'left');
$f->Button(-text => 'Cancel',
           -command => sub { $ok = 1 })->pack(-side => 'left');

$f->waitVariable(\$ok);

if ($ok == 1) { warn "The resulting directory is '$curr_dir'\n"; }

}  # end tk_new_file
=cut

sub tk_pass_tree {
    my @list = &step_pass_tree;
    print "$_\n" foreach @list;
}

sub tk_users_manual {
}

sub tk_about {
    # need a pop up box
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
        -width => 20,
        -background => 'gray95',
        -relief => 'flat',
    ) -> pack(
        -fill => 'both',
        -side => 'left',
        -expand => 1,
    );

    $info -> insert( 'end', "This spaced is reserved for changing assembly structure.",);
    $info -> configure(-state => 'disabled');

    ### status

    $status = $f -> Frame -> pack;
    $status -> Label(
        -text => "Optimisation on\nHasse diagram",
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

### assembly tree

sub tk_insert_tree_items {
    ### can't handle duplicate part name at the moment, need to add suffix when reading step file
    # print "tk insert tree\n";
    my @items = &step_produce_tree;
    foreach my $ref_list (@items) {
        my ($name, $item) = @{$ref_list};
        $tree -> add($item, -text => $name);
    }
    $tree -> autosetmode;
}

sub tk_assembly_tree {
    $tree = $mw -> Scrolled( "Tree",
        -scrollbars => 'se',
        -width => 40,
        -label => "Assembly tree",
    ) -> pack(
        -fill => 'both',
        -side => 'left',
        -expand => 1,
    );
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

sub tk_tree {
    print "tk tree\n";
    &step_tree;
}

###
### subroutines
###

sub tk_embed_height_0 {
   my ($e) = &hypercube_elements_at_height(0);
   print "height 0 = $e\n";
   $array_lookup_id_to_hash{$e}{label} = "0";
   $embedded{0} = 0;
   # $elements_available{0} = 0;  ??? inf zero - set to unavailable ???
}

sub tk_embed_height_1 {
    my @height_1 = &hypercube_elements_at_height(1);
    my @atoms = &step_count_atomic_part;
    print "height 1 = @height_1\n";
    my $top_level_assembly = "puzzle_1c";  ### need to get this value live

    ### set up atoms as available for embedding $embedded{$e}=1
    for (my $i=0; $i<=$#atoms; $i++) {
        my $atom = $atoms[$i];
        my $element = $height_1[$i];
        # print "$atom - $element\n";
        $array_lookup_id_to_hash{$element}{label} = $atom;
        $embedded{$atom} = 1;
    }

    ### embed thingies
    LABEL: my @list = &tk_to_be_embedded_list;
    my ($first) = @list;
    print "there are @list\n";
    goto EXIT unless $first;
    my @siblings = &tk_siblings($first);
    my $parent = &tk_parent($first);
    if (&tk_check_if_all_exists(@siblings)) {
        foreach my $sibling (@siblings) {
            print "sibling $sibling\n";
            $embedded{$sibling} = 0;
        }
    }
    $embedded{ &tk_parent($first) } = 1 if &tk_parent($first);
    goto EXIT if $first eq $top_level_assembly;
    goto LABEL;
    EXIT:;
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

sub tk_embed_test {
    print "tk_embed_test\n";
    while (my ($element, $avail) = each %embedded) {
        my @siblings = &tk_siblings($element);
        my $parent = &tk_parent($element);
        print "element $element is $avail. (@siblings) [$parent]\n" if $parent;
    }
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

sub tk_yet_embedded {
}

sub tk_embed {
    # print "hypercube_embed\n";
    ### copy from tk_count_atomic_part
    ### i/p - %elements_available
    ### o/p - ???
    # print "tk/step count atomic part\n";
    my @atoms = &step_count_atomic_part;
    $max = $#atoms + 1;
    # print "n = $max\n";

    foreach my $atom (@atoms) {
        my $available = &tk_is_atom_available($atom);
        my @siblings = &tk_siblings($atom);
        # print "$atom ($available) is an atom [@siblings]\n";
    }

    # print "tk/step count atomic part ... 2nd set\n";
    foreach my $element (keys %elements_available) {
        my $available = &tk_is_atom_available($element);
        my @siblings;
        if (&is_covered_by($element)) {
            @siblings = &covers( &is_covered_by($element) );
        } else {
            @siblings = ();
        }
        # print "... $element ($available) has siblings @siblings.\n";
        # print "    $element ($available) is a top level assembly\n" unless @siblings;
    }
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
    $c -> delete("is_covered_by", "element", "element_id", "element_label");
}

sub tk_plot_is_covered_by {
    while (my ($child, $ref_hash) = each %array_lookup_id_to_hash) {
        my $ref_parents = &get_parents($child);
        foreach my $parent (@$ref_parents) {
            my ($x1, $y1, $z1) = @{$array_lookup_id_to_hash{$child} {canvas}};
            my ($x2, $y2, $z2) = @{$array_lookup_id_to_hash{$parent}{canvas}};
            $is_covered_by{$child}{$parent} = $c->createLine($x1, $y1, $x2, $y2,
                -tags => "is_covered_by",
                -fill => 'gray75',
                -activefill => 'black',
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
                -tags => "element",
                -outline => 'gray75',
                -fill => 'gray95',
                -activeoutline => 'black',
                -activefill => "black",
            );                                 # lower-left, upper-right
            $element_id{$id} = $c -> createText($x2 + $element_radius , $y2 - $element_radius,
                 -text => $array_with_coords[$h][$j]{id},
                 -tags => "element_id",
                 -fill => 'gray75',
            );
            $element_label{$id} = $c -> createText($x2 + $element_radius , $y1 + $element_radius,
                 -text => $array_with_coords[$h][$j]{label},
                 -tags => "element_label",
                 -fill => 'gray50',
                 -justify => 'left',   # ??? not working ???
            ) if $array_with_coords[$h][$j]{label} or 1;    # show label only when it is not a "0"
        }
    }
}

sub tk_plot_ids {
    print "tk plot ids\n";
}

sub tk_plot_labels {
    print "tk plot labels\n";
}

###

sub tk_optimise {
    $zeros = 0;
    $iterations = 0;
    my $number_of_times = 9999;

    LABEL: while ($zeros <= 2) {    # consider optimised when three sets of 10,000 zeros
        $quit_optimisation = 0;
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

__DATA__

Tk_FreeCursor received unknown cursor argument

This application has requested the Runtime to terminate it in an unusual way.
Please contact the application's support team for more information.

sub tk_copyright {
    print "StrEmbed_3  Copyright (C) 2016  University of Leeds
This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
This is free software, and you are welcome to redistribute it
under certain conditions; type `show c' for details.


    my $popup = $mw->messageBox(
        -title   => 'Open file',
        -message => "We are displaying a silly message, do you wish to continue?",
        -type    => 'YesNo',
        -icon    => 'question',
    );

    if ( $popup eq 'No' ) {
        exit;
    } else {
        my $popup2 = $mw->messageBox(
            -title   => 'Really?',
            -message => "We displayed silly message and you wish to continue?",
            -type    => 'OK',
            -icon    => 'question',
        )
    };