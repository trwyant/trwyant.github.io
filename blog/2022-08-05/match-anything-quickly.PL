#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

use Benchmark qw{ cmpthese timethese };
use Getopt::Long 2.33 qw{ :config auto_version };
use Pod::Usage;

our $VERSION = '0.000_001';

my %opt = (
    count	=> 100_000_000,
    match	=> 'fubar',
);

GetOptions( \%opt,
    qw{ count=i html! match=s style=s },
    help => sub { pod2usage( { -verbose => 2 } ) },
) or pod2usage( { -verbose => 0 } );

$opt{style} //= $opt{html} ? 'none' : 'auto';

our $MATCH = $opt{match};

my @cases = (
    'sub { 1 }', sub { 1 },
);

foreach my $re ( qw{ (*ACCEPT) (?) (?:) .? .{0} \A ^ } ) {
    my $code = eval "sub { \$MATCH =~ m/ $re / }";
    push @cases,
	"sub { m/ $re /smx }", $code,
	"qr/ $re /smx", "use 5.010; state \$regex = qr/ $re /smx; \$MATCH =~ \$regex",
	;
}

my $rslt = timethese $opt{count}, { @cases }, $opt{style};

$opt{html}
    and print <<'EOD';
<table>
<thead>
<tr><th>Implementation</th><th>Rate</th></tr>
</thead>
<tbody>
EOD

my $tplt = $opt{html} ?
    '<tr><td>%s</td><td style="text-align: right;">%.2f/sec</td></tr>' :
    '%-26s  %12.2f/sec';

foreach my $item (
    sort { $a->[2] <=> $b->[2] }
    map { [ $_, $rslt->{$_}, $rslt->{$_}->cpu_a() ] }
    keys %{ $rslt }
) {
    my ( $name, $bmk ) = @{ $item };
    say sprintf $tplt, $name, $bmk->iters() / $bmk->cpu_a();
}

$opt{html}
    and print <<'EOD';
</tbody>
</table>
EOD

__END__

=head1 TITLE

match-anything-quickly.PL - Benchmark techniques for matching anything.

=head1 SYNOPSIS

 match-anything-quickly.PL
 match-anything-quickly.PL --help
 match-anything-quickly.PL --version

=head1 OPTIONS

=head2 --help

This option displays the documentation for this script. The script then
exits.

=head2 --html

If this Boolean option is asserted, the output is an HTML table.
Othewise it is text.

The default is C<--no-html>.

=head2 --match

 --match 'To be, or not to be.'

This option specifies the string to be matched.

The default is C<--match fubar>.

=head2 --style

 --style none

This option sets the C<STYLE> argument to C<timethese()>.

The default is C<--style none> if L<--html|--html> is asserted.
Otherwise it is C<--style auto>.

=head2 --version

This option displays the version of this script. The script then exits.

=head1 DETAILS

This Perl script benchmarks several plausable ways of matching any
string, and reports the restults on standard out. The actual benchmark
is done by the L<Benchmark|Benchmark> module.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the Artistic
License 1.0 at
L<https://www.perlfoundation.org/artistic-license-10.html>, and/or the
Gnu GPL at L<http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt>.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
