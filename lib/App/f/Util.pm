package App::f::Util;
# ABSTRACT: random utils we need elsewhere
use strict;
use warnings;
use version;

use Sub::Exporter -setup => {
    exports => [qw/is_newer_than/],
};

# return true if A is newer than B
sub is_newer_than($$) {
    my ($a, $b) = @_;

    return 1 if !defined $a;
    return if !defined $b;

    return version->parse($a) > version->parse($b);
}

1;
