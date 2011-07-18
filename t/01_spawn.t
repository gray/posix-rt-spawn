use strict;
use warnings;
use Test::More;
use POSIX::RT::Spawn;

my $pid = spawn(qw(true that));
cmp_ok($pid, '>', 1, 'valid looking pid');
isnt($pid, $$, 'pid is different from our pid');
is($!+0, 0, 'no errno');

{
    diag "non-existant program";
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    $pid = spawn('some_random_nonexisting_program_name');
    like($warning, qr/^Can't spawn/, 'warning');
    ok(!$pid, 'no pid');
    isnt($!+0, 0, 'errno');
}

diag "single scalar with shell metacharacters";
$pid = spawn('false || true 2>&1');
cmp_ok($pid, '>', 1, 'valid looking pid');
isnt($pid, $$, 'pid is different from our pid');
is($!+0, 0, 'no errno');

done_testing;
