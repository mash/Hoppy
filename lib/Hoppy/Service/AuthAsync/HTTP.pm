package Hoppy::Service::AuthAsync::HTTP;
use strict;
use warnings;
use base qw( Hoppy::Service::Base );
use POE qw/Component::Client::HTTPDeferred/;
use HTTP::Request::Common;
use URI;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->config( $self->context->config->{auth} );

    return $self;
}

sub login {
    my ($self, $args, $poe) = @_;

    my $ua = POE::Component::Client::HTTPDeferred->new;

    my $req = $self->build_login_request( $args );

    my $d = $ua->request( $req );
    $d->addBoth(
        sub {
            my $res = shift;

            $ua->shutdown;

            $self->context->room->login_complete( $args, $poe, $self->is_login_success($res) );
        }
    );
}

sub build_login_request {
    my ($self, $args) = @_;

    my $auth_url = URI->new( $self->config->{login} );
    $auth_url->query_form({
        user_id    => $args->{user_id},
        password   => $args->{password},
        session_id => $args->{session_id},
        room_id    => $args->{room_id} || 'global',
    });
    return POST $auth_url;
}

sub is_login_success {
    my ($self, $args, $res) = @_;

    # override this

    return 1;
}

sub logout {
    my ($self, $args, $poe) = @_;

    my $ua = POE::Component::Client::HTTPDeferred->new;

    my $req = $self->build_logout_request( $args );

    my $d = $ua->request( $req );
    $d->addBoth(
        sub {
            my $res = shift;

            $ua->shutdown;

            $self->context->room->logout_complete( $args, $poe );
        }
    );

}

sub build_logout_request {
    my ($self, $args) = @_;

    my $auth_url = URI->new( $self->config->{logout} );
    $auth_url->query_form({
        user_id    => $args->{user_id},
        password   => $args->{password},
        session_id => $args->{session_id},
        room_id    => $args->{room_id} || 'global',
    });
    return POST $auth_url;
}

1;
