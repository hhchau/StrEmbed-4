#!/usr/local/bin/perl -w

 use Tk;
 use Tk::FileDialog;
 use strict;

 my($main) = MainWindow->new;
 my($Horiz) = 1;
 my($fname);

 my($LoadDialog) = $main->FileDialog(-Title =>'This is my title',
                                    -Create => 0);

 print "Using FileDialog Version ",$LoadDialog->Version,"\n";

 $LoadDialog->configure(-FPat => '*pl',
                       -ShowAll => 'NO');

 $main->Entry(-textvariable => \$fname)
        ->pack(-expand => 1,
               -fill => 'x');

 $main->Button(-text => 'Kick me!',
              -command => sub {
                  $fname = $LoadDialog->Show(-Horiz => $Horiz);
                  if (!defined($fname)) {
                      $fname = "Fine,Cancel, but no Chdir anymore!!!";
                      $LoadDialog->configure(-Chdir =>'NO');
                  }
              })
        ->pack(-expand => 1,
               -fill => 'x');

 $main->Checkbutton(-text => 'Horizontal',
                   -variable => \$Horiz)
        ->pack(-expand => 1,
               -fill => 'x');

 $main->Button(-text => 'Exit',
              -command => sub {
                  $main->destroy;
              })
        ->pack(-expand => 1,
               -fill => 'x');

 MainLoop;

 print "Exit Stage right!\n";

 exit;