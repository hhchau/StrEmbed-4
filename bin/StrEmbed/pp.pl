use Tk; 
use subs qw/build_menubar fini/; 

$mw = MainWindow->new(); 

my $menubar = $mw->Menu; 
my $file = $menubar -> cascade(
    -label => 'File',
    -underline => 0,
); 
$file -> separator;
$file -> separator;
$mw->configure(-menu => $menubar); 
$file->command(-label => "~Print Text");
$file->command(-label => "~Quit"); 
$file -> separator;

MainLoop; 
