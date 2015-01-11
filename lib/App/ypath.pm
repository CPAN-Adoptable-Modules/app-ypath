#!perl
use utf8;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.011';

=head1 NAME

extract_yaml_value - Find distributions to index

=head1 SYNOPSIS

	# separate keys by /
	% extract_yaml_info dist_info/dist_file directory_of_yaml_files
	
	# separate multiple values with commas
	% extract_yaml_info dist_info/dist_file,run_info/alarm_error directory_of_yaml_files

	# print the filename with each output line
	% extract_yaml_info -f dist_info/dist_file directory_of_yaml_files

	# print the path to each value
	% extract_yaml_info -f -k dist_info/dist_file directory_of_yaml_files

	# suppress warnings
	% extract_yaml_info -w dist_info/dist_file directory_of_yaml_files

=head1 DESCRIPTION

This is a simple script to extract values from a list of YAML files. It's
meant for simple and quick inspections rather than full-on queries and 
collations.

=head1 TO DO

=over 4

=item * Support @ in any position as a wildcard to process all thingys at that level

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2015, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the same terms as Perl itself.

=cut

use Data::Dumper;
use File::Spec::Functions qw( catfile );
use Scalar::Util qw( reftype );
use YAML qw( LoadFile );

use Getopt::Std;
getopt('dk', \my %opts);
$SIG{__WARN__} = sub { 1 } unless $opts{w};

my ($value, @dirs ) = @ARGV;
my @paths = map 
	{ [ split m|/| ] } 
	split /,/, $value;

my $count;

foreach my $dir ( @dirs )
	{
	opendir my $dh, $dir or warn "Could not open $dir: $!\n";
	
	FILE: while( my $file = readdir( $dh ) )
		{
		next if $file =~ /^\./;
		
		my $yaml = eval { LoadFile( catfile( $dir, $file ) ) };
		unless( defined $yaml )
			{
			warn "$file did not parse correctly\n";
			next FILE;
			}

		PATH: foreach my $path ( @paths ) {
			my $ref = $yaml;

			KEY: foreach my $key ( @$path )
				{
				if( reftype $ref eq reftype [] )
					{
					if( $key !~ m/-?\d+/ )
						{
						warn "Bad array value at $key!\n";
						next PATH;
						}
					elsif( $key > $#$ref )
						{
						warn "Array out of bounds at $key!\n";
						next PATH;						
						}
					
					$ref = $ref->[$key];
					}
				elsif( reftype $ref eq reftype {} )
					{
					unless( exists $ref->{$key} )
						{
						warn "\tPath to ", 
							join( '->', @$path ),
							" does not exist (misses at $key)\n";
						next PATH;
						}
						
					$ref = $ref->{$key};
					}
				else
					{
					warn "End of the road before $key!";
					next PATH;
					}
				}
			
			if( ref $ref )
				{
				$ref = Dumper( $ref );
				$ref =~ s/\A\$VAR.*=\s*//;
				}

			printf "%s%s%s\n",
				( $opts{f} ? "$file: " : '' ),
				( $opts{k} ? join( "/", @$path) . " => " : '' ),
				$ref
				;
			}
		}
	}


1;
