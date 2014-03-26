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

my $log_file = $root_path . '/scripts/load_all_associations.txt';
my $processed_at = $cfg->param("common_vars.processed_at");

mainProgram();

sub mainProgram {
	my $url = 'http://www.cfboard.state.mn.us/lobby/principl.html';

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
	my (%association);

	for (1..3) {
		$association{$_} = getAssociationDetails($stream);
 	}
	
 	if ($association{'1'} =~ m/^Principal Name/i) {
 		# print ("header row \n");
 		return;
 	}

 	$association{'name'} = $association{'1'};
 	$association{'association_nbr'} = $association{'2'};
 	$association{'term_date'} = $association{'3'};

 	if ($association{'term_date'} eq '') {
 		undef;
 	} else {
 		$association{'term_date'} = convertDate($association{'term_date'}, 'mm/dd/yyyy', 'yyyy/mm/dd');
 	}

 	print ("$association{'association_nbr'}: $association{'name'} \n");
 	printHash(%association);
 	exit;
 	# updateTables(\%association);
 	
}

sub updateTables {
	my ($hash_ref) = @_;

	my %return_assoc = touchAssociation($hash_ref);
	# updateAssociation_name_byPK($hash_ref);
	updateAssociation_nameTerm_byPK($hash_ref);
	if ($return_assoc{'updated'} eq 'true') {
		printLogDateTime($log_file, "new record: $hash_ref->{'association_nbr'}: $hash_ref->{'name'} ");
		# updateAssociation_nameTerm_byPK($hash_ref);
		# exit;
	}
}

sub getAssociationDetails {
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
	}
	$text =~ s/,\s$//g;

	return $text;
}