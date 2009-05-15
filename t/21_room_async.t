use Test::Base qw/no_plan/;
use Hoppy;
use Hoppy::Room::Memory::AuthAsync;
use POE::Sugar::Args;

{
    my $config = {
        Room => 'Hoppy::Room::Memory::AuthAsync',
        regist_services => {
            auth => 'Hoppy::Service::AuthAsync::HTTP',
        },
        auth => {
            url => 'http://www.google.com/',
        },
    };
    my $server = Hoppy->new( config => $config );

    my $room   = $server->room;
    $room->create_room('room1');

    isa_ok( $room, "Hoppy::Room::Memory::AuthAsync", "isa AuthAsync room" );
    isa_ok( $server->service->{auth}, "Hoppy::Service::AuthAsync::HTTP", "auth isa AuthAsync::HTTP service" );

    POE::Session->create(
        inline_states => {
            _start => sub {
                my $poe = sweet_args;
                
                $room->login( { user_id => 'hoge', session_id => 1, room_id => 'room1' }, $poe );

                is_deeply( $room->{where_in}, {}, 'empty room just after login()' );
                is_deeply( $server->{authorizing}, { 1 => 'hoge' }, 'hoge is authorizing' );

                $poe->kernel->delay( 'after_login' => 1 );
            },
            after_login => sub {

                is_deeply( $room->{where_in}, { hoge => 'room1' }, 'has joined room 1sec after login' );

                $server->stop;
            },
        }
    );
    $server->start;
}

