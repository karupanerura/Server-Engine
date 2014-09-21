package Server::Engine::Worker::DSL;
use strict;
use warnings;
use utf8;

use Server::Engine::Worker;

sub import {
    my $class  = shift;
    my $caller = caller;
    strict->import;
    warnings->import;
    utf8->import;

    my %stash;
    my $worker = sub (&) {# no critic
        $stash{code} = shift;
    };
    my $on_shutdown = sub (&) {# no critic
        $stash{on_shutdown} = shift;
    };
    my $on_force_shutdown = sub (&) {# no critic
        $stash{on_force_shutdown} = shift;
    };
    my $instance = sub {
        Server::Engine::Worker->new(%stash);
    };

    {
        no strict qw/refs/;
        *{"${caller}::worker"}            = $worker;
        *{"${caller}::on_shutdown"}       = $on_shutdown;
        *{"${caller}::on_force_shutdown"} = $on_force_shutdown;
        *{"${caller}::instance"}          = $instance;
    }
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Server::Engine::Worker::DSL - TODO

=head1 SYNOPSIS

    package MyServer::Worker;
    use Server::Engine::Worker::DSL;
    use Server::Engine::Util qw/safe_sleep/;

    my $living = 1;
    worker {
        my $c = 0;
        while ($living) {
            warn 'c: ', $c++;
        }
        continue {
            safe_sleep 1;
        }
    };

    on_shutdown { $living = 0 };

    1;

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
