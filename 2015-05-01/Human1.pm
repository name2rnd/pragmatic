package Human;
use strict; use warnings;

sub do {
    my $logger = shift;
    my $text = shift;
    my $key = shift;
    if ($key eq 'rree') {
        
        # ... some code
        
        # normalize
        $text =~ s/[!\-\+]/ ! /g;
        $text =~ s/\(\(/ ( /g;
        $text =~ s/\)\)/ ); /g;
        if ($text =~ /superpower/) {
            $logger->log('warn', 'superpower used');
            $text =~ s/superpower/secret weapon/g;
        }
        # ... more normalize rules

        # ... some code
        
        # prepare
        $text = sprintf '%s %s', $text, $key;
        unless ($text) {
            $logger->log('warning', 'no text');
        }
    }
    elsif ($key eq 'jjii') {
        # ...
    }

    return $text; 
}

sub _normalize {
    my ($logger, $text) = @_;
    return 1;
}
1;

