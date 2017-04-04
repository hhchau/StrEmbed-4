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

# test_popup.pl
# HHC - 2017-01-23

require 5.002;
# use warnings;
# use strict;
use Tk;
use Tk::Menu;
use Tk::Tree;
use Tk::PNG;

my $entity = 1000;

$main = MainWindow->new();
$main -> minsize(640, 480);
$main -> optionAdd('*font', 'Helvetica 10');

$frame = $main -> Frame(
) -> pack(
    -fill => 'both',
    -side => 'left',
    -expand => 1,
);

$tree = $frame -> Scrolled( "Tree",
    -scrollbars => 'se',
    -width => 40,
    -label => "Assembly Tree",
    -cursor => 'hand2',
) -> pack(
    -fill => 'both',
    #-side => 'left',
    -expand => 1,
);

$tree -> add("top", -text => "top");
$tree -> add("top.item1", -text => "item1");
$tree -> add("top.item2", -text => "item2");
$tree -> add("top.item1.feature_a", -text => "feature_a");
$tree -> add("top.item2.feature_b", -text => "feature_b");
$tree -> add("top.item2.feature_c", -text => "feature_c");
$tree -> autosetmode;
# $tree -> focus;

$box = $frame -> Frame(
) -> pack(
    -fill => 'x',
    -side => 'left',
    -expand => 1,
);

### buttons

$label = $box -> Entry(
    -text => \$entity,
    -state => 'readonly',
) -> pack(
    -fill => 'x',
);

$icon_scroll_up_up     = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-up-double-icon-small.png");
$icon_scroll_up        = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-up-icon-small.png");
$icon_scroll_down      = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-down-icon-small.png");
$icon_scroll_down_down = $box->Photo(-file => "./resources/icons/32x32/Actions-arrow-down-double-icon-small.png");
$icon_level_up         = $box->Photo(-file => "./resources/icons/32x32/Actions-go-previous-icon-small.png");
$icon_level_down       = $box->Photo(-file => "./resources/icons/32x32/Actions-go-next-icon-small.png");

$button1 = $box -> Button(
    -command => \&button_up_up,
    -image => $icon_scroll_up_up,
) -> pack (
    -side => 'top',
);

$button1a = $box -> Button(
    -command => \&button_up,
    -image => $icon_scroll_up,
) -> pack (
    -side => 'top',
);

$button4 = $box -> Button(
    -command => \&button_down_down,
    -image => $icon_scroll_down_down,
    # -text => "To the bottom",
) -> pack (
    -side => 'bottom',
);

$button1b = $box -> Button(
    -command => \&button_down,
    -image => $icon_scroll_down,
) -> pack (
    -side => 'bottom',
);

$button2 = $box -> Button(
    -command => \&button_left,
    -image => $icon_level_up,
) -> pack (
    -side => 'left',
    -expand => 1,
    # -fill => 'x',
);

$button3 = $box -> Button(
    -command => \&button_right,
    -image => $icon_level_down,
) -> pack (
    -side => 'right',
    -expand => 1,
    # -fill => 'x',
);

### canvas

$canvas = $main -> Scrolled( "Canvas",
    -scrollbars => 'se',
    -width => 40,
    -label => "Canvas",
) -> pack(
    -fill => 'both',
    -side => 'left',
    -expand => 1,
);

$menu = $tree->Menu(-tearoff => 0);
# $menu->add('separator');
# $menu->configure(-title => "move");
$menu->add('command', -label => 'One', -command => \&item1);
$menu->add('command', -label => 'Two', -command => \&item2);

# $tree->Label(-text => 'This Tree')->pack();

# $tree -> bind('<1>', [\&test_exit, 1]);
$tree -> bind('<2>', [\&test_exit, 2]);
$tree -> bind('<3>', [\&showmenu, Ev('X'), Ev('Y'), Ev('W')]);
# $tree->focus();
$tree -> configure(
    -browsecmd => \&tk_callback_entity_browse,
    # -command => \&tk_callback_entity,
);

MainLoop;

### subroutines

sub tk_callback_entity_browse {
    ### THIRD BUTTON MENU CALLBACK
    my @list = @_;
    $entity = @list[0];
    # print "tk_callback_entity (browse) - ";
    # print "browsed item = @list\n";    
}

sub tk_callback_entity {
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

sub button_up_up {
    print "button - scroll to top\n";
}

sub button_up {
    print "button - scroll up\n";
}

sub button_down {
    print "button - scroll down\n";
}

sub button_down_down {
    print "button - scroll to bottom\n";
}

sub button_left {
    print "button - level up\n";
}

sub button_right {
    print "button - level down\n";
}

sub test_exit {
    my @list = @_;
    print "test exit = @list\n";
    # exit;
}

sub showmenu {
    my ($self, $x, $y, $widget) = @_;
    my $label = $widget->cget('text');
    # print "show menu >$self<\n";
    $menu->insert(0, 'command',
        -label => $label,
        -command => sub { print "Clicked $label.\n" },
    );
    $menu->post($x, $y);
    $menu->delete(0,0);
}

sub item1 { print "Item 1!\n" }
sub item2 { print "Item 2!\n" }