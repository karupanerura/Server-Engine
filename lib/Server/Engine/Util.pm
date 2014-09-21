package Server::Engine::Util;
use strict;
use warnings;
use utf8;
use subs qw/sleep/;

use parent qw/Exporter/;
our @EXPORT_OK = qw/safe_sleep/;

use Time::HiRes ();

our $SIGNAL_HANDLER;
sub safe_sleep (;$) {## no critic
    $SIGNAL_HANDLER ? $SIGNAL_HANDLER->sleep(@_) : Time::HiRes::sleep(@_);
}

{
    # alias sleep=safe_sleep
    no warnings qw/once/;
    *sleep = \&safe_sleep;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Server::Engine::Util - utility for Server::Engine

=head1 DESCRIPTION

This utility for Server::Engine.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
