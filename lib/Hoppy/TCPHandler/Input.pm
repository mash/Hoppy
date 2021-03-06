package Hoppy::TCPHandler::Input;
use strict;
use warnings;
use base qw( Hoppy::Base );

sub do_handle {
    my $self  = shift;
    my $poe   = shift;
    my $c     = $self->context;
    my $input = $poe->args->[0];
    if ( $input =~ /policy-file-request/ ) {
        my $xml = $self->cross_domain_policy_xml;
        $c->handler->{Send}->do_handle( $poe, $xml );
    }
    elsif ( $input eq 'exit' ) {
        my $session_id = $poe->session->ID;
        my $user       = $c->room->fetch_user_from_session_id($session_id);
        if ($user) {
            $c->room->logout( { user_id => $user->user_id }, $poe );
        }
        delete $c->{sessions}->{$session_id};
        delete $c->{not_authorized}->{$session_id};
        $poe->kernel->yield("shutdown");
    }
    else {
        my $data = '';
        eval { $data = $c->formatter->deserialize($input); };
        if ($@) {
            warn "IO Format Error: $@";
        }
        else {
            my $method = $data->{method};
            my $params = $data->{params};
            $c->dispatch( $method, $params, $poe );
        }
    }
}

sub cross_domain_policy_xml {
    my $self = shift;
    my $xml  = <<"    END";
        <?xml version="1.0"?>
        <!DOCTYPE cross-domain-policy SYSTEM "http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd">
        <cross-domain-policy>
        <allow-access-from domain="*" to-ports="*" />
        </cross-domain-policy>
    END
    return $xml;
}

1;
__END__

=head1 NAME

Hoppy::TCPHandler::Input - TCP handler class that will be used when client input any data. 

=head1 SYNOPSIS

=head1 DESCRIPTION

TCP handler class that will be used when client input any data. 
And then, it dispatches input data to registered classes. 

=head1 METHODS

=head2 do_handle($poe)

=head2 cross_domain_policy_xml

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut