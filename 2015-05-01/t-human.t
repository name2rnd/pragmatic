#!/usr/bin/perl
use strict;
use Data::Dumper;
use Test::More;
use Test::MockModule;

use_ok('Human');
use_ok('Logger');

my $tests = {
    '!abc+' => ' ! abc ! ',
    '((bbb))' => ' ( bbb ); ',
    'i want to use superpower' => 'i want to use secret weapon',
    'gg' => '',
    '!ggabcrr))' => ' ! abc ); ',
};
# mock
my $module = Test::MockModule->new('Logger');
$module->mock('log', sub { shift; note explain ['IN MOCK', @_] });

my $logger = Logger->new(); 

for my $t (keys %$tests) {
    is Human::_normalize($logger, $t), $tests->{$t};
}
done_testing();
