#!/usr/bin/env perl6
use lib 'lib';
use Test;
use Log::Async;
use Jupyter::Kernel::Magics;
use LLM::Prompts;

logger.add-tap( -> $msg { diag $msg<msg> } );

plan *;

my $m = Jupyter::Kernel::Magics.new;
class MockResult {
    has $.output;
    has $.output-mime-type;
    has $.stdout;
    has $.stdout-mime-type;
    has $.stderr;
    has $.exception;
    has $.incomplete;
}


{
    my $code = q:to/DONE/;
    %% chat, conf=ChatGPT
    @Yoda Hi! Who are you and where do you live? #HaikuStyled
    DONE

    ok my $magic = $m.find-magic($code), 'preprocess recognized %% chat';
    is $code.starts-with('@Yoda'), True, 'content of the chat cell';
    my $r = $magic.preprocess($code);
    note $r.output;

    is $r.output.contains('Yoda', :i) || $r.output.contains('Jedi', :i),
            True,
            'response contains "Yoda" or "Jedi"';

    is $r.output-mime-type, 'text/plain', 'chat magic set the mime type';
}

{
    my $code = q:to/DONE/;
    %% chat
    !Translate|German^
    DONE

    ok my $magic = $m.find-magic($code), 'preprocess recognized %% chat';
    is $code.contains('Translate'):i, True, 'content of the chat cell';
    my $r = $magic.preprocess($code);
    note $r.output;

    is $r.output.contains('meister', :i) || $r.output.contains('ich', :i),
            True,
            'response contains "meister" or "ich';

    is $r.output-mime-type, 'text/plain', 'chat magic set the mime type';
}

done-testing;