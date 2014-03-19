#!/usr/local/bin/perl
use strict;
use Config::Simple;
use File::Basename;
use HTML::TokeParser::Simple;

use WWW::Mechanize;
use JSON;
use Data::Dumper;


#
# loop thru associations table and get records to process (default those records w/ dates >= config.pl processed_at date)
# 	foreach record - goto association page - example: http://www.cfboard.state.mn.us/lobby/adetail/a6063.html
#			get contact info and address of association
# 	updates: addresses, associations$addresses, associations$contacts, lobbyist, associations$lobbyists
#
my $root_path = '/Users/ltechel/scripts/mncampainfinance';
my $cfg = new Config::Simple($root_path . '/modules/config.pl');

require $root_path . '/modules/common.pm';

# my $browser = WWW::Mechanize->new(autocheck=>0);

my $log_file = $root_path . '/scripts/load_expenditures.txt';
my $processed_at = $cfg->param("common_vars.processed_at");

mainProgram();

sub mainProgram {
	my $url = 'http://www.cfboard.state.mn.us/lobby/lobbyist.html';

	my $stream = HTML::TokeParser::Simple->new(url => $url);
	my $temp;
	
	$stream->get_tag("table");
	while ($stream->get_tag("tr")) {
		# print (" row ... \n");
		getLobbyistData($stream);
		
	}
}

sub getLobbyistData {
	my ($stream) = @_;
	my (%lobbyist, %name);

	for (1..6) {
		# $stream->get_tag("td");
		$lobbyist{$_} = getLobbyistDetails($stream);

 	}
	
 	if ($lobbyist{'1'} =~ m/^Lobbyist/i) {
 		print ("header row \n");
 		return;
 	}
 	# printHash(%lobbyist);

 	%name = splitName_FirstMiddleLast($lobbyist{'1'});
 	# printHash(%name);
 	$lobbyist{'address'} = $lobbyist{'2'};
 	$lobbyist{'phone'} = $lobbyist{'3'};
 	$lobbyist{'reg_nbr'} = $lobbyist{'4'};
 	$lobbyist{'from_date'} = $lobbyist{'5'};
 	$lobbyist{'termination_date'} = $lobbyist{'6'};

 	# printHash(%lobbyist);
 	print ("$name{'long_name'}: $lobbyist{'reg_nbr'} \n");
 	my %return_lobbyist = touchLobbyists(\%lobbyist, \%name);
 	if ($return_lobbyist{'updated'}) {
 		print ("\t\t added... \n");
 	}
 	# # splitAddress($lobbyist{'address'});
 	# exit;

}

sub getLobbyistDetails {
	my ($stream) = @_;

	my ($tag, $text);
	$tag = $stream->get_tag("td");
	while (my $tag = $stream->get_token) {
		if ( $tag->is_start_tag() ) {
			next;
		} elsif ($tag->is_end_tag() ) {
			last;
		}

		$text .= getTagText($tag) . ', ';
		
		
		# $tag = $stream->get_token;$tag = $stream->get_token;
	# $tag = $stream->get_token;
	# $text = getTagText($tag);
	# $text =~ s/\*$//g;
	}
	$text =~ s/,\s$//g;
	# print ("text: $text \n");

	return $text;
}


# # sub splitAddress {
# 	my ($address) = @_;


# 	my @lines = split (/\, /,$address);
# 	my $arr_length = scalar @lines;

# 	print ("line: @lines \n");

# 	foreach (@lines) {
# 		print ("$_ \n");
# 	}
# }