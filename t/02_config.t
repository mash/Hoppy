use strict;
use warnings;
use Hoppy;
use Test::More tests => 4;
use FindBin::libs;

my %config = (
    alias           => 'hoge',
    port            => 12345,
    io_format       => "JSON",
    regist_services => { auth => 'MyAuth' } 
);

my $server = Hoppy->new( config => \%config );

is_deeply(
    $server->config,
    {
        'alias'           => 'hoge',
        'port'            => 12345,
        'io_format'       => 'JSON',
        'regist_services' => { 'auth' => 'MyAuth' },

    },
    'config passed correctly'
);

isa_ok( $server->formatter,       'Hoppy::Formatter::JSON' );
isa_ok( $server->service->{auth}, 'MyAuth' );

POE::Session->create(
    inline_states => {
        _start => sub {
            $server->stop;
        },
    }
);

$server->start;


delete $config{regist_services};
my $server_by_regist_service = Hoppy->new( config => \%config );
$server_by_regist_service->regist_service(
    auth => 'MyAuth',
);
isa_ok( $server->service->{auth}, 'MyAuth' );
