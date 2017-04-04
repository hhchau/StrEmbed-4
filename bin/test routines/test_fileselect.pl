#!/usr/bin/perl -w

use strict;
use Tk;

use Tk::FileSelect;

main();
MainLoop;

sub main {
    my $top = MainWindow->new;

    my $fs = $top->FileSelect( -verify => ["-d"] );

    my $b = $top->Button( -text => "List a dir",
                          -command => sub { list_dir( $top, $fs ) } );
    $b->pack;
}

sub list_dir {
    my( $top, $fs ) = @_;
    my $dir = $fs->Show( -popover => $top );
    print "dir = $dir\n";
    system( "ls $dir" );
}