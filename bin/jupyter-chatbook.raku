#!/usr/bin/env perl6

use Log::Async;
use Jupyter::Chatbook;
use Jupyter::Chatbook::Paths;

multi MAIN($spec-file, :$logfile = './jupyter.log') {
    logger.send-to($logfile);
    Jupyter::Chatbook.new.run($spec-file);
}


multi MAIN(Bool :$generate-config!,
        Str :$location = ~raku-dir;
        Bool :$force) {

    # Retrieve color code
    # nb: Colored output can be disabled with RAKUDO_ERROR_COLOR environment variable
    my ($red, $clear, $green, $yellow, $eject) = Rakudo::Internals.error-rcgye;

    # Check if need to work
    my $dest-spec = $location.IO.child('kernel.json');
    $dest-spec.f and !$force and do {
        say "File $dest-spec already exists => exiting the configuration.";
        say "You can force the configuration with '" ~ $red~"--force"~$clear ~ "'";
        exit;
    }

    # Declare kernel.json content
    my $spec = q:to/DONE/;
        {
            "display_name": "RakuChatbook",
            "language": "raku",
            "argv": [
                "jupyter-chatbook.raku",
                "{connection_file}"
            ]
        }
        DONE

    # Create kernel file system
    note "Creating directory $location";
    mkdir $location;
    note "Writing kernel.json to $dest-spec";
    $dest-spec.spurt($spec);
    for <32 64> {
        my $file = "logo-{ $_ }x{ $_ }.png";
        my $resources = Jupyter::Chatbook.resources;
        my $resource = $resources{ $file } // $?FILE.IO.parent.parent.child('resources').child($file);
        $resource.IO.e or do {
            say "Can't find resource $file";
            next;
        }
        note "Copying $file to $location";
        copy $resource.IO, $location.IO.child($file) or die "Failed to copy $file to $location.";
    }

    # Say Success
    say "Congratulations, configuration files have been "
        ~ $green~"successfully"~$clear ~ " written!";
    say $green~"Happy Chatting!"~$clear
        ~ " <- " ~ $yellow~"jupyter console --kernel=raku"~$clear;
    say '';
}
