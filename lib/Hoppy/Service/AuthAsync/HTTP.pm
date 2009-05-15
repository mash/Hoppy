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
__END__

=head1 NAME

Hoppy::Service::AuthAsync::HTTP - Asynchronously login/logout using HTTP.

=head1 SYNOPSIS

  use Hoppy;

  my $config = {
      Room => 'Hoppy::Room::Memory::AuthAsync',
      regist_services => {
          auth => 'Hoppy::Service::AuthAsync::HTTP',
      },
      auth => {
          login  => 'http://example.com/login',
          logout => 'http://example.com/logout',
      },
  };

  my $server = Hoppy->new;

=head1 DESCRIPTION

Asynchronously login/logout using HTTP. POST to an url to login/logout.

=head1 METHODS

=head2 new

=head2 login

=head2 build_login_request

=head2 is_login_success

=head2 logout

=head2 build_logout_request

=head1 AUTHOR

Masakazu Ohtsuka (mash) E<lt>o.masakazu@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
