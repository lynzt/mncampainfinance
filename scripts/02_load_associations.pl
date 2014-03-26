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

my $log_file = $root_path . '/scripts/load_associations.txt';
my $processed_at = $cfg->param("common_vars.processed_at");

mainProgram();

sub mainProgram {
	processAssociations()
	
}

sub processAssociations {
	my $association_url;

	$processed_at = '2014-03-13 00:00:00';
	my $sql_stmt = "select association_number, name
		from mn_campaign_finance.associations
		where created_at >= '$processed_at'
		-- where association_number in (6146, 5783)
		-- limit 1
		;";

	# print ("sql_stmt: $sql_stmt \n");
	# exit;
	
	my $query_handle = prepareAndExecute($sql_stmt);

	$query_handle->bind_columns(\my ($association_nbr, $name));
	while($query_handle->fetch()) {

		getAssociationDetails($association_nbr, $name);
		# exit;
		# getAssociationDetails('518', $name);
		# exit;

	}

}

sub getAssociationDetails {
	my ($association_nbr, $name) = @_;


	# my $url = "http://www.cfboard.state.mn.us/lobby/lbdetail/lb$lobbyist_id.html";
	my $url = "http://www.cfboard.state.mn.us/lobby/adetail/a$association_nbr.html";
	
	# print ("\t$url \n");
	if (!isValidUrl($url)) {
		print ("\t\tinvalid url: $url \n");
		return;
	} 

	print ("fetching: $url \n");

	my $stream2 = HTML::TokeParser::Simple->new(url => $url);
	my $temp;
	my (%association, %name, %address);

	if (!getManualData(\%association, \%name, \%address, $association_nbr)) {
		$association{'name'} = getAssociationName($stream2);

	 	my $line_count = 0;
	 	for (1..5) {
	 		$temp = getAssociationData($stream2);
		 	if ($temp eq '') {
		 		next;
		 	} else {
		 		$line_count++;
		 		$association{$line_count} = $temp;
		 	}
	 	}

	 	$association{'association_nbr'} = $association_nbr;
	 	$association{'contact_title'} = $association{'1'};
		if ($association{'4'} =~ m/^Website/i) {
			$association{'street1'} = $association{'2'};
			$association{'city_state_zip'} = $association{'3'};
			$association{'website'} = $association{'4'};
		} elsif ($association{'5'} =~ m/^Website/i) {
			$association{'street1'} = $association{'2'};
			$association{'street2'} = $association{'3'};
			$association{'city_state_zip'} = $association{'4'};
			$association{'website'} = $association{'5'};
		} elsif ($association{'4'} =~ m/^Association Number/i) {
			$association{'street1'} = $association{'2'};
			$association{'city_state_zip'} = $association{'3'};
		} elsif ($association{'5'} =~ m/^Association Number/i) {
			$association{'street1'} = $association{'2'};
			$association{'street2'} = $association{'3'};
			$association{'city_state_zip'} = $association{'4'};
		}


		($association{'contact'}, $association{'titles'}) = splitAssociationNameTitle($association{'contact_title'});

		%name = splitName_FirstMiddleLast($association{'contact'});

		$association{'website'} =~ s/^Website:(\s)?//i;
		if ($association{'website'} eq 'No Website') {
			$association{'website'} = undef;
		}
		print ("\tassociation: ". $name ." \n");


		$address{'street1'} = $association{'street1'};
		$address{'street2'} = $association{'street2'};
		$address{'city_state_zip'} = $association{'city_state_zip'};
		splitCityStateZip(\%address);	
		formatFullAddress(\%address);
	}

	# http://www.cfbreport.state.mn.us/rptViewer/Main.php?do=viewPDF

	# l_6801_1733_A1.pdf

	# http://www.cfbreport.state.mn.us/rptViewer/viewPDF.php?file=pdfStorage/2006/Campfin/YE/40889


	# printHash(%association);
	# print (" \n");
	# printHash(%name);
	# print (" \n");
	# printHash(%address);
	# exit;

	my %return_assoc = touchAssociation(\%association);

	if ($name{'long_name'} ne '') {
		my %return_association = touchAssociationsContacts(\%association, \%name);
		updateAssociation_hash_byPk(\%association);
	}
	

	my %return_address = touchAddress(\%address); # l -> lobbist, not a -> association
	touchAssociationsAddresses('a', $return_assoc{'id'}, $return_address{'id'});

	getLobbyists($stream2, \%association);
}

sub getLobbyists {
	my ($stream, $association_hash) = @_;

	my $is_first = 'true';
	
	$stream->get_tag("table");

	while (my $tag = $stream->get_token) {
		if ($tag->is_end_tag('tbody')) {
			last;
		}

		if ($tag->is_start_tag('tr')) {
			if ($is_first eq 'true') {
				$is_first = 'false';
				next;
			}

			my (%lobbyist, %name, %types);

			$lobbyist{'name'} = getLobbyistName($stream);
			$lobbyist{'reg_nbr'} = getLobbyistData($stream);
			$lobbyist{'reg_date_orig'} = getLobbyistData($stream);
			$lobbyist{'term_date_orig'} = getLobbyistData($stream);
			$lobbyist{'lobbyist'} = stripWhitespaceBegEnd(getLobbyistData($stream));

			if ($lobbyist{'reg_date_orig'} =~ m/Pre\-1996/i) {
				$lobbyist{'reg_date_orig'} = '1/1/1995';
			}
			# printHash(%lobbyist);

			$lobbyist{'reg_date'} = convertDate($lobbyist{'reg_date_orig'}, 'mm/dd/yyyy', 'yyyy/mm/dd');
			$lobbyist{'term_date'} = convertDate($lobbyist{'term_date_orig'}, 'mm/dd/yyyy', 'yyyy/mm/dd');

			
			if ($lobbyist{'lobbyist'} eq '' or $lobbyist{'lobbyist'} eq '&nbsp') { # &nbsp... idk. stupid
				$lobbyist{'designated'} = 0;
			} else {
				$lobbyist{'designated'} = 1;
			}

 			%name = splitName_FirstMiddleLast($lobbyist{'name'});
			
			
			touchLobbyists(\%lobbyist, \%name);
			touchAssociationsLobbyists($association_hash->{'association_nbr'}, $lobbyist{'reg_nbr'}, $lobbyist{'reg_date'});
			updateAssociationsLobbyists_hashPartial1_byPk(\%lobbyist, $association_hash->{'association_nbr'});
		}
	}

}

sub getAssociationName {
	my ($stream) = @_;
	my ($tag, $text);

	$tag = $stream->get_tag("strong");$tag = $stream->get_token;
	$text = getTagText($tag);
	return $text;
}

sub getAssociationData {
	my ($stream) = @_;

	my ($tag, $text);
	$tag = $stream->get_tag("br");
	$tag = $stream->get_token;
	$text = getTagText($tag);
	# $text =~ s/^Email:\s//g;

	return $text;
}

sub getLobbyistName {
	my ($stream) = @_;
	my ($tag, $text);

	$tag = $stream->get_tag("a");$tag = $stream->get_token;
	$text = getTagText($tag);
	return $text;
}

sub getLobbyistData {
	my ($stream) = @_;
	my ($tag, $text);

	$tag = $stream->get_tag("td");$tag = $stream->get_token;
	$text = getTagText($tag);
	return $text;
}

sub getManualData {
	my ($assoc_hash, $name_hash, $add_hash, $association_nbr) = @_;
	
	if ($association_nbr eq '6146') {
		$assoc_hash->{'association_nbr'} = $association_nbr;
		$add_hash->{'street1'} = '200 S Sixth St, Ste 350';
		$add_hash->{'city'} = 'Minneapolis';
		$add_hash->{'state'} = 'MN';
		$add_hash->{'zip'} = '55402';
		$add_hash->{'country'} = 'US';
		$add_hash->{'full_address'} = $add_hash->{'street1'} . ' ' 
																. $add_hash->{'city'} . ' '
																. $add_hash->{'state'} . ' ' 
																. $add_hash->{'zip'};
		return 'true';
	} elsif ($association_nbr eq '5783') {
		$assoc_hash->{'association_nbr'} = $association_nbr;
		$add_hash->{'street1'} = '1 North Jefferson Avenue';
		$add_hash->{'city'} = 'St Louis';
		$add_hash->{'state'} = 'MO';
		$add_hash->{'zip'} = '63103';
		$add_hash->{'country'} = 'US';
		$add_hash->{'full_address'} = $add_hash->{'street1'} . ' ' 
																. $add_hash->{'city'} . ' '
																. $add_hash->{'state'} . ' ' 
																. $add_hash->{'zip'};
	}

}