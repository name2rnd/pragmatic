package Utils;
use strict; use warnings; use feature qw/say/;
use Common;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(a);

sub a {
    say 'a';
}

1;

