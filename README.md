# NAME

Server::Engine - prefork server framework. (inspired by serverengine from rubygems)

# SYNOPSIS

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

# DESCRIPTION

Server::Engine is ...

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
