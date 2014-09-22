package Server::Engine::Worker;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use Server::Engine::SignalHandler;
use Server::Engine::Util;

use Class::Accessor::Lite new => 1, ro => [qw/code on_shutdown on_force_shutdown/];

sub run {
    my $self = shift;
    local $Server::Engine::Util::SIGNAL_HANDLER = $self->set_signal_handler();
    $self->_run();
}

sub _run {
    my $self = shift;
    eval {
        $self->code->();
        1;
    } || die $@;
}

sub set_signal_handler {
    my $self = shift;

    # to ignore signal propagation
    $SIG{$_} = 'IGNORE' for qw/INT/;

    my $handler = Server::Engine::SignalHandler->new;
    for my $sig (qw/TERM HUP/) {
        $handler->register($sig => sub { $self->shutdown($sig) });
    }
    for my $sig (qw/ABRT/) {
        $handler->register($sig => sub { $self->force_shutdown($sig) });
    }

    return $handler;
}

sub shutdown :method {
    my ($self, $sig) = @_;
    if ($self->on_shutdown) {
        $self->on_shutdown->($sig);
    }
    else {
        die "signal recieved: SIG$sig";
    }
}

sub force_shutdown {
    my ($self, $sig) = @_;
    if ($self->on_force_shutdown) {
        $self->on_force_shutdown->($sig);
    }
    else {
        $self->shutdown($sig);
    }
}

1;
__END__
