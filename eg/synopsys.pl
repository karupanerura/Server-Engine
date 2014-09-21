package MyWorker;
use Server::Engine::Worker::DSL;
use Server::Engine::Util qw/safe_sleep/;

my $living = 1;
worker {
    my $c = 0;
    while ($living) {
        warn "[$$] c: ", $c++;
    }
    continue {
        safe_sleep 1;
    }
};

on_shutdown { $living = 0 };

package main;
use Server::Engine;

Server::Engine->new(
    max_workers               => 10,
    spawn_interval            => 1,
    graceful_shutdown_timeout => 30,
    worker                    => MyWorker->instance,
)->run;
