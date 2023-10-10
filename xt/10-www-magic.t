#!/usr/bin/env perl6
use lib 'lib';
use Test;
use Log::Async;
use Jupyter::Chatbook::Magics;
use Text::SubParsers;
use JSON::Tiny;

logger.add-tap( -> $msg { diag $msg<msg> } );

plan *;

my $m = Jupyter::Chatbook::Magics.new;
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
    %% openai
    What is the population of Brazil?
    DONE

    ok my $magic = $m.find-magic($code), 'preprocess recognized %% openai';
    is $code, "What is the population of Brazil?\n", 'find-magic removed magic line';
    my $r = $magic.preprocess($code);
    #note $r.output;
    my $spres = sub-parser('GenericNumeric').subparse($r.output.subst(/(\d) ',' (\d**3)/, {"$0_$1"}):g);
    #note $spres;
    is $spres ~~ Numeric || $spres ~~ Array, True, 'Numeric or Array answer from OpenAI cell';
    is $r.output-mime-type, 'text/plain', 'openai magic set the mime type';
}

{
    my $code = q:to/DONE/;
    %% palm
    What is the population of Brazil?
    DONE

    ok my $magic = $m.find-magic($code), 'preprocess recognized %% palm';
    is $code, "What is the population of Brazil?\n", 'find-magic removed magic line';
    my $r = $magic.preprocess($code);
    #note $r.output;
    isa-ok sub-parser('GenericNumeric').subparse($r.output.subst(/(\d) ',' (\d**3)/, {"$0_$1"}):g), Numeric, 'Numeric answer from PalM cell';
    is $r.output-mime-type, 'text/plain', 'palm magic set the mime type';
}

{
    my $code = q:to/DONE/;
    %% palm, max-tokens=30, format=json
    What is the population of Brazil?
    DONE

    ok my $magic = $m.find-magic($code), 'preprocess recognized %% palm, *%args';
    is $code, "What is the population of Brazil?\n", 'find-magic removed magic line';
    my $r = $magic.preprocess($code);
    #note $r.output;
    ok from-json($r.output), 'got JSON string for PalM with format=json';
    is $r.output-mime-type, 'text/plain', 'palm magic set the mime type';
}

{
    my $code = q:to/DONE/;
    %% mermaid
    graph LR
    A --> B --> C
    C --> D --> B
    DONE

    ok my $magic = $m.find-magic($code), 'preprocess recognized %% mermaid';
    is $code.starts-with('graph LR'), True, 'find-magic removed magic line';

    my $r = $magic.preprocess($code);

    #note $r.output;
    is $r.output.starts-with('<img src="data:image/png;base64'),
            True,
            'got HTML base64 string from mermaid-ink';

    is $r.output-mime-type, 'text/html', 'mermaid magic set the mime type';
}

{
    my $code = q:to/DONE/;
    %% dalle

    @resources/logo-64x64.png

    DONE

    ok my $magic = $m.find-magic($code), 'preprocess recognized %% dalle';
    is $code.trim.starts-with('@'), True, 'find-magic removed magic line';

    my $r = $magic.preprocess($code);

    #note $r.output;
    is $r.output.starts-with('<img src="data:image/png;base64'),
            True,
            'got HTML base64 string from dalle';

    is $r.output-mime-type, 'text/html', 'dalle magic set the mime type';
}

{
    my $code = q:to/DONE/;
    %% dalle, prompt='Better butterfly.'

    @resources/logo-64x64.png

    DONE

    ok my $magic = $m.find-magic($code), 'preprocess recognized %% dalle with prompt';
    is $code.trim.starts-with('@'), True, 'find-magic removed magic line';

    my $r = $magic.preprocess($code);

    #note $r.output;
    is $r.output.starts-with('<img src="data:image/png;base64'),
            True,
            'got HTML base64 string from dalle with prompt';

    is $r.output-mime-type, 'text/html', 'dalle with prompt magic set the mime type';
}

done-testing;