package Human;
use strict; use warnings;

sub do {
    my $logger = shift;
    my $text = shift;
    my $key = shift;
    if ($key ne 'rree') {
        
        # ... some code    
        # normalize
        my $text = _normalize($logger, $text);

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
    $text =~ s/[!\-\+]/ ! /g;
    $text =~ s/\(\(/ ( /g;
    $text =~ s/\)\)/ ); /g;
    if ($text =~ /superpower/) {
        $logger->log('warn', 'superpower used');
        $text =~ s/superpower/secret weapon/g;
    }
    else {
        $text =~ s/gg|rr|e|t|q//g;
    }
    # ... more normalize rules
    return $text;
}
1;

