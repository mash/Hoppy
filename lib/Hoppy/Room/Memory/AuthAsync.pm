package Hoppy::Room::Memory::AuthAsync;
use strict;
use warnings;
use Hoppy::User;
use base qw(Hoppy::Base);
use Carp;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->create_room('global');
    $self->{where_in}                = {};
    $self->context->{not_authorized} = {};
    $self->context->{authorizing}    = {};
    croak 'why use this module without auth?' unless $self->context->service->{auth};
    return $self;
}

sub create_room {
    my $self    = shift;
    my $room_id = shift;
    unless ( $self->{rooms}->{$room_id} ) {
        $self->{rooms}->{$room_id} = {};
    }
}

sub delete_room {
    my $self    = shift;
    my $room_id = shift;
    if ( $room_id ne 'global' ) {
        my $room = $self->{rooms}->{$room_id};
        for my $user_id ( keys %$room ) {
            $self->delete_user($user_id);
        }
        delete $self->{rooms}->{$room_id};
    }
}

sub login {
    my $self = shift;
    my $args = shift;
    my $poe  = shift;

    my $user_id    = $args->{user_id};
    my $password   = $args->{password};
    my $session_id = $args->{session_id};
    my $room_id    = $args->{room_id} || 'global';

    my $c = $self->context;

    # is authorizing async, but still 'not_authorized'
    $c->{authorizing}->{$session_id} = $user_id;

    $c->service->{auth}->login( $args, $poe );
    return 'authorizing';
}

sub login_complete {
    my ($self, $args, $poe, $success) = @_;

    my $user_id    = $args->{user_id};
    my $session_id = $args->{session_id};
    my $room_id    = $args->{room_id} || 'global';
    my $c = $self->context;

    delete $c->{authorizing}->{$session_id};

    if ( $success ) {
        my $user = Hoppy::User->new(
            user_id    => $user_id,
            session_id => $session_id,
        );

        delete $c->{not_authorized}->{$session_id};
        $self->{rooms}->{$room_id}->{$user_id} = $user;
        $self->{where_in}->{$user_id}          = $room_id;
        $self->{sessions}->{$session_id}       = $user_id;
        return 1;
    }
    return 0;
}

sub logout {
    my $self = shift;
    my $args = shift;
    my $poe  = shift;

    my $user_id = $args->{user_id};
    my $user    = $self->fetch_user_from_user_id($user_id);

    delete $self->{sessions}->{ $user->session_id };
    my $room_id = delete $self->{where_in}->{$user_id};
    delete $self->{rooms}->{$room_id}->{$user_id};
    $self->context->{not_authorized}->{ $user->session_id } = 1;

    $self->context->service->{auth}->logout( $args, $poe );

    return 1;
}

sub logout_complete {
}

sub fetch_user_from_user_id {
    my $self    = shift;
    my $user_id = shift;
    return unless ($user_id);
    my $room_id = $self->{where_in}->{$user_id};
    return $self->{rooms}->{$room_id}->{$user_id};
}

sub fetch_user_from_session_id {
    my $self       = shift;
    my $session_id = shift;
    return unless ($session_id);
    my $user_id = $self->{sessions}->{$session_id};
    return $self->fetch_user_from_user_id($user_id);
}

sub fetch_users_from_room_id {
    my $self    = shift;
    my $room_id = shift;
    my @users   = values %{ $self->{rooms}->{$room_id} };
    return \@users;
}

1;
__END__

=head1 NAME

Hoppy::Room::Memory::AuthAsync - Room on memory, and also somewhere else where you access asynchronously. It manages users and their sessions.

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
  my $room = $server->room; # get room object from the Hoppy.

  # login and logout are handled automatically, asynchronously.
  $room->login(...);
  $room->logout(...);

  # create or delete a new room.
  $room->create_room('hoge');
  $room->delete_room('hoge');

  # you can fetch user(s) object from any ID.
  # Because of the asynchronousity, calling $room->fetch_user* just after $room->login will fail
  # wait for login_complete to fetch_user.
  # On the other hand, logout will make users unfetch-able immediately, while doing the actual logout asynchronously.
  my $user  = $room->fetch_user_from_user_id($user_id);
  my $user  = $room->fetch_user_from_session_id($session_id);
  my $users = $room->fetch_users_from_room_id($room_id);

=head1 DESCRIPTION

Room on memory, and also somewhere else where you access asynchronously. It manages users and their sessions.

=head1 METHODS

=head2 new

=head2 create_room($room_id); 

=head2 delete_room($room_id);

=head2 login(\%args,$poe_object);

  Do login asynchronously.
  Calls back login_complete when completed.
  $c->regist_service your Hoppy::Service::AuthAsync::Something class to implement the asynchronousity,
  for example Hoppy::Service::AuthAsync::HTTP which posts async to any url to do authentication.

  %args = (
    user_id    => $user_id,
    session_id => $session_id,
    password   => $password,  #optional
    room_id    => $room_id,   #optional
  );

=head2 login_complete( \%args, $poe_object, $login_success );

=head2 logout(\%args, $poe_object);

  will logout immediately, and do the actual logout asynchronously
  
  %args = ( user_id => $user_id );

  Do logout asynchronously.

=head2 logout_complete( \%args, $poe_object );

=head2 fetch_user_from_user_id($user_id) 

=head2 fetch_user_from_session_id($session_id) 

=head2 fetch_users_from_room_id($room_id) 

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

Masakazu Ohtsuka (mash) E<lt>o.masakazu@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
