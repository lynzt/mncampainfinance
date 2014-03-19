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
	processExpenditures();
}

sub processExpenditures {
	my $url = 'http://www.cfboard.state.mn.us/lobby/LobPrincipalExpendbyexpend_Current_L.html';
	my $type = 'principal';
	# print ("\t$url \n");

	my $stream = HTML::TokeParser::Simple->new(url => $url);
	my $temp;
	# my (%association, %name, %address);
	my (%years);


	$stream->get_tag("tr");

 	for (1..8) {
 		$years{$_} = getExpenditureYears($stream);
 	}

 	# my $count = 0;
 	my $run_me = 'false';
 	while ($stream->get_tag("tr")) {
		getExpenditureData($stream, \%years, $type, $run_me);
 	}
}

sub getExpenditureData {
	my ($stream, $year_hash, $type, $run_me) = @_;
	my (%expenditures);

	for (1..8) {
 		$expenditures{$_} = getExpenditureDetails($stream, $_);
 	}
 	
 	if (skipAssociation($expenditures{'1'})) {
 		return;
 	}
 	my $association_nbr = getAssociation_byName($expenditures{'1'});
 	print ("association_nbr: $association_nbr \n");

 	if ($association_nbr eq '') {
 		printLogDateTime($log_file, "skipping this: $expenditures{'1'} ");
 		# printHash(%expenditures);
 		# exit;
 	}

 	my $a_nbr = '6007';
 	if ($a_nbr eq $association_nbr) {
 		$run_me = 'true';
 	}
 	
 	if ($run_me eq 'true') {
		for (2..8) {
	 		print ("\tyears: $year_hash->{$_}: $expenditures{$_} \n");
	 		touchExpenditures($association_nbr, $year_hash->{$_}, $type);
	 		updateExpenditures_byPk($association_nbr, $year_hash->{$_}, $type, $expenditures{$_});
	 	}
 	}
 	

}

sub getExpenditureYears {
	my ($stream) = @_;

	my ($tag, $text);
	$tag = $stream->get_tag("td");$tag = $stream->get_token;$tag = $stream->get_token;
	# $tag = $stream->get_token;
	$text = getTagText($tag);
	$text =~ s/\*$//g;

	return $text;
}

sub getExpenditureDetails {
	my ($stream, $count) = @_;
	my ($tag, $text);

	$tag = $stream->get_tag("td");$tag = $stream->get_token;$tag = $stream->get_token;
	$text = stripWhitespaceBegEnd(getTagText($tag));

	if ($count > 1) {
		$text =~ s/^\$//g;
		$text =~ s/\,//g;
		$text =~ s/\.00$//g;
		if ($text eq '') {
			$text = undef;
		}
	} else {
		$text = escapeWideChar($text);
	}

	return $text;
}

sub skipAssociation {
	my ($str) = @_;
	my $return = 'true';

	if ($str =~ m/^(21st Services|Accenture LLP|Ackerberg Group)/i) {
		$return = 'false';
	}

}