package App::ypath;
use utf8;
use 5.026;
use strict;
use warnings;

use feature qw(signatures);
no warnings qw(experimental::signatures);

our $VERSION = '0.013';

=encoding utf8

=head1 NAME

App::ypath - Extract information from YAML

=head1 SYNOPSIS


=head1 DESCRIPTION

This is a simple script to extract values from a list of YAML files. It's
meant for simple and quick inspections rather than full-on queries and
collations.

=head2 Methods

=over 4

=item * run( YPATH, FILE, CALLBACK )

=back

=head1 TO DO

=over 4

=item * Support @ in any position as a wildcard to process all thingys at that level

=back

=head1 SOURCE AVAILABILITY

This code is in GitHub:

	https://github.com/briandfoy/app-ypath

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2020, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

use Scalar::Util qw( reftype );
use YAML qw( LoadFile );

sub run ( $self, $path, $file, $callback, $options = {} ) {
	my @paths = map
		{ [ split m|/| ] }
		split /,/, $path;

	my $count;

	my $yaml = eval { LoadFile( $file ) };
	unless( defined $yaml ) {
		warn "$file did not parse correctly\n";
		return;
		}

	PATH: foreach my $path ( @paths ) {
		my $ref = $yaml;

		KEY: foreach my $key ( @$path ) {
			if( reftype $ref eq reftype [] ) {
				if( $key !~ m/-?\d+/ ) {
					warn "Bad array value at $key!\n";
					next PATH;
					}
				elsif( $key > $#$ref ) {
					warn "Array out of bounds at $key!\n";
					next PATH;
					}

				$ref = $ref->[$key];
				}
			elsif( reftype $ref eq reftype {} ) {
				unless( exists $ref->{$key} ) {
					warn "\tPath to ",
						join( '->', @$path ),
						" does not exist (misses at $key)\n";
					next PATH;
					}

				$ref = $ref->{$key};
				}
			else {
				warn "End of the road before $key!";
				next PATH;
				}
			}

		$callback->( {
			file => $file,
			path => $path,
			result => $ref,
			} );

		}

	}

1;
