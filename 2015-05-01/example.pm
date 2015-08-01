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
1;

