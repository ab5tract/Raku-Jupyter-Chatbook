#!/usr/bin/env perl6
use lib 'lib';
use Test;
use Log::Async;
use Jupyter::Chatbook::History;

plan 7;

logger.add-tap( -> $msg { diag $msg<msg> } );

my $history-file will leave {.unlink} = $*TMPDIR.child('history-test.json');
my $history = Jupyter::Chatbook::History.new(:$history-file);
ok $history, 'made a history object';
ok $history.init, 'init';
is-deeply $history.read, [], 'nothing there yet';
ok (await $history.append("2.say", :1execution_count)), 'append';
is-deeply $history.read, [ [ 1, 1, '2.say'], ], 'read the history';
ok (await $history.append("2.is-prime", :2execution_count)), 'append';
is-deeply $history.read, [ [ 1, 1, '2.say'], [ 1, 2, '2.is-prime'], ], 'read the history';
