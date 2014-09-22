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

package main;
use Server::Engine;

my $worker = MyWorker->instance;
my $server = Server::Engine->new(
    max_workers               => 10,
    spawn_interval            => 1,
    graceful_shutdown_timeout => 30,
);

$server->run($worker);
