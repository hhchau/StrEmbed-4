use Tk;
use Tk::Menu;

$mw = new MainWindow;
$mw -> configure(-menu => $menubar = $mw -> Menu);

#$mw -> geometry('+0+20');
#$mw -> minsize($x_min, $y_min);
#$mw -> optionAdd('*font', 'Helvetica 10');
#$mw -> title("Structure Embedding version 4 (StrEmbed-4)");

$file = $menubar -> cascade(-label => '~File');
$file = $menubar -> cascade(-label => '~File');


sleep(100);
Mainloop;