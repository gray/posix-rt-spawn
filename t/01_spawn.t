use strict;
use warnings;
use Test::More;

use Config;
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use POSIX::RT::Spawn;

my $Perl = $Config{perlpath};
plan skip_all => "$Perl is not a usable Perl interpreter"
    unless -x $Perl;

my @cmd = (
    $Perl,  '-e',
    q(open my $out, ">&=$ARGV[0]"; printf $out "%s\n%s", $$, $^X;),
);
my $fake_cmd_name = 'lskdjfalksdjfdjfkls';

sub spawn_cmd {
    my ($real, @cmd) = @_;

    pipe my($in, $out) or die "pipe: $!";

    # Disable close-on-exec.
    my $flags = fcntl $out, F_GETFD, 0;
    fcntl $out, F_SETFD, $flags & ~FD_CLOEXEC;

    my $fd = fileno $out;
    if (1 == @cmd) { $cmd[0] .= " $fd"; }
    else           { push @cmd, $fd; }

    my $pid;
    if ($real) {
        $pid = eval qq(spawn $real ) . join ',',  map { qq('$_') }@cmd;
        die $@ if $@;
    }
    else {
        $pid = spawn @cmd;
    }

    close $out;
    waitpid $pid, 0;

    chomp(my @out = <$in>);
    close $in;

    return $pid, @out;
}

subtest 'non-existant program' => sub {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    my $pid = spawn($fake_cmd_name);
    ok ! $pid, 'no pid';
    isnt $!+0, 0, 'errno';
    like $warning, qr/^Can't spawn/, 'warning';
};

subtest 'single scalar with no shell metacharacters' => sub {
    my $cmd = join ' ', @cmd[0 .. 1], qq('$cmd[2]');
    my ($pid, $xpid) = spawn_cmd '', $cmd;
    is $xpid, $pid, 'returned pid is correct';
    is $!+0, 0, 'no errno';
};

subtest 'single scalar with shell metacharacters' => sub {
    my $cmd = join ' ', @cmd[0 .. 1], qq('$cmd[2]');
    my ($pid, $xpid) = spawn_cmd '', 'true && ' . $cmd;
    isnt $xpid, $pid, 'perl opened in subshell';
    is !! $pid, 1, 'valid looking pid';
    is $!+0, 0, 'no errno';
};

subtest 'multivalued list' => sub {
    my ($pid, $xpid) = spawn_cmd '', @cmd;
    is $xpid, $pid, 'returned pid is correct';
    is $!+0, 0, 'no errno';
};

subtest 'modify process name with indirect object syntax' => sub {
    local $TODO = 'unimplemented';

    # plan skip_all => "Modifying process name requires Perl >= 5.13.08"
    #     if $^V lt '5.13.8';

    eval {
        my @cmd = @cmd;
        unshift @cmd,  qq({ '$cmd[0]' });
        $cmd[1] = $fake_cmd_name;
        my ($pid, $xpid, $cmd_name) = spawn_cmd @cmd;

        is !! $pid, 1, 'valid looking pid';
        is $xpid, $pid, 'returned pid is correct';
        is $!+0, 0, 'no errno';
        is $cmd_name, $fake_cmd_name, 'modified process name'
    };
    is $@, '', 'indirect object syntax using block';

    eval {
        my @cmd = @cmd;
        unshift @cmd, q($real);
        $cmd[1] = $fake_cmd_name;
        my ($pid, $xpid, $cmd_name) = spawn_cmd @cmd;

        is !! $pid, 1, 'valid looking pid';
        is $xpid, $pid, 'returned pid is correct';
        is $!+0, 0, 'no errno';
        is $cmd_name, $fake_cmd_name, 'modified process name'
    };
    is $@, '', 'indirect object syntax using scalar variable';
};

done_testing;
