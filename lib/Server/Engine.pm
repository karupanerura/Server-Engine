package Server::Engine;
use 5.008001;
use strict;
use warnings;
use utf8;

our $VERSION = "0.01";

use Parallel::Prefork 0.17;
use Module::Load ();

use Class::Accessor::Lite
    new => 1,
    ro  => [
        # config
        qw/
          max_workers
          spawn_interval
          graceful_shutdown_timeout
        /,
        # callback
        qw/on_start on_reload on_force_reload on_shutdown on_force_shutdown on_fork on_leap/,
        # stat
        qw/worker_pids worker_generation/,
    ];

sub run {
    my ($self, $worker) = @_;

    $self->on_start->() if $self->on_start;
    $self->_run($worker);
    $self->on_shutdown->() if $self->on_shutdown;
}

sub _run {
    my ($self, $worker) = @_;
    my $pm = $self->_create_parallel_prefork();
    $self->start_workers($pm => $worker);
    $self->wait_workers($pm);
}

sub _create_parallel_prefork {
    my $self = shift;
    my $on_leap = $self->on_leap;
    $self->{job_worker_generation} = 0;
    $self->{job_worker_pids}       = {};
    return Parallel::Prefork->new({
        max_workers    => $self->max_workers,
        spawn_interval => $self->spawn_interval,
        after_fork     => sub {
            my (undef, $pid) = @_;
            $self->{job_worker_pids}->{$pid} = $self->{job_worker_generation};
        },
        on_child_reap => sub {
            my (undef, $pid) = @_;
            $self->{_reapd_job_worker_pids}->{$$} = delete $self->{job_worker_pids}->{$pid};
            $on_leap->($pid) if $on_leap;
        },
        trap_signals => {
            INT  => 'TERM', # graceful shutdown
            TERM => 'TERM', # graceful shutdown
            HUP  => 'HUP',  # graceful reload
        },
    });
}

sub start_workers {
    my ($self, $pm, $worker) = @_;

    my $on_fork = $self->on_fork;
    local $SIG{ALRM} = $SIG{ALRM};
    until ($self->_check_signal($pm)) {
        $pm->start(sub {
            $on_fork->($$) if $on_fork;
            $worker->run();
        });
    }
}

sub wait_workers {
    my ($self, $pm) = @_;
    my $is_timeout = $pm->wait_all_children($self->graceful_shutdown_timeout);
    if ($is_timeout) {
        $self->on_force_shutdown->(keys %{ $self->{job_worker_pids} }) if $self->on_force_shutdown;
        $pm->signal_all_children('ABRT'); # force kill children.
    }
    $pm->wait_all_children();
}

sub _check_signal {
    my ($self, $pm) = @_;
    return 1 if $pm->signal_received eq 'INT';
    return 1 if $pm->signal_received eq 'TERM';

    if ($pm->signal_received eq 'HUP') {
        my $old_generation = $self->{job_worker_generation}++;

        my $super = $SIG{ALRM};
        $SIG{ALRM} = sub {
            my @target_pids = grep { $self->{job_worker_pids}->{$_} <= $old_generation } keys %{ $self->{job_worker_pids} };
            if (@target_pids) {
                $self->on_force_reload->(@target_pids) if $self->on_force_reload;
                kill ABRT => @target_pids; # force kill children.
            }
            $SIG{ALRM} = $super;
        };
        alarm $self->graceful_shutdown_timeout;
    }

    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Server::Engine - prefork server framework. (inspired by serverengine from rubygems)

=head1 SYNOPSIS

    use Server::Engine;
    use MyWorker;

    my $worker = MyWorker->instance;
    my $server = Server::Engine->new(
        max_workers               => 10,
        spawn_interval            => 1,
        graceful_shutdown_timeout => 30,
    );

    $server->run($worker);
    use Server::Engine;
    use MyWorker;

    Server::Engine->new(
        max_workers               => 10,
        spawn_interval            => 1,
        graceful_shutdown_timeout => 30,
        worker                    => MyWorker->instance,
    )->run;

MyWorker:

    package MyWorker;
    use Server::Engine::Worker::DSL;
    use Server::Engine::Util qw/safe_sleep/;

    my $living = 1;
    worker {
        my $c = 0;
        warn "[$$] START WORKER";
        while ($living) {
            warn "[$$] c: ", $c++;
        }
        continue {
            safe_sleep $c;
        }
        warn "[$$] SHUTDOWN WORKER";
    };

    on_shutdown {
        my $sig = shift;
        warn "[$$] SIG$sig recived.";
        $living = 0;
    };

    1;


=head1 DESCRIPTION

Server::Engine is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
