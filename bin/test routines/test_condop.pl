use strict;
use warnings;

print "trinary conditional operator\n";
my $m = 1;
my $n = 10;
my ($pp, $qq, @qq);
$pp = 0 ? 0 ? 0 ? 102
                : 103
            : 104
        : 105 ;
print "pp = $pp\n";

      is_array();
$qq = &is_array;
@qq = &is_array;

sub is_array {
    my $test = defined wantarray ? (wantarray) ? "want array"
                                               : "want scalar"
                                 : "not wanted any" ;
    print "test = $test\n";
}