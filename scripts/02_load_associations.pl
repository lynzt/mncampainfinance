#!/usr/local/bin/perl
use strict;
use Config::Simple;
use File::Basename;
use HTML::TokeParser::Simple;

use WWW::Mechanize;
use JSON;
use Data::Dumper;


#
# get id for any channel that has ??% as number because it wasn't found during usual run
#

require '/Users/ltechel/scripts/mncampainfinance/modules/common.pm';

my $browser = WWW::Mechanize->new(autocheck=>0);

# channel_id json
# https://www.googleapis.com/youtube/v3/search?part=id%2Csnippet&maxResults=1&q=lynzteee&type=channel&key=AIzaSyAW7vPz_89NdtVK3jwioimGmsMPdwm5avg
my $lobbyist_index_url = 'http://www.cfboard.state.mn.us/lobby/lbatoz.html';

my $log_file = '/Library/WebServer/Documents/cdragon/scripts/helper script/load_categories.txt';

mainProgram();

sub mainProgram {
	
	processAssociations()
	
}

sub processAssociations {
	my $association_url;


	my $sql_stmt = "select association_number, name
		from mn_campaign_finance.associations
		where association_number < 6752
		-- where region is null
		-- where association_number = 5288
		-- limit 1
		;";

	# print ("sql_stmt: $sql_stmt \n");
	
	my $query_handle = prepareAndExecute($sql_stmt);

	$query_handle->bind_columns(\my ($association_nbr, $name));
	while($query_handle->fetch()) {

		getAssociationDetails($association_nbr, $name);
		# getAssociationDetails('61', $name);

		# 6007, 6009
		# getAssociationDetails('118', $name);
		# getAssociationDetails('518', $name);
		# exit;

	}

}

sub getAssociationDetails {
	my ($association_nbr, $name) = @_;

	# my $url = "http://www.cfboard.state.mn.us/lobby/lbdetail/lb$lobbyist_id.html";
	my $url = "http://www.cfboard.state.mn.us/lobby/adetail/a$association_nbr.html";
	
	print ("\t$url \n");
	my $stream2 = HTML::TokeParser::Simple->new(url => $url);
	my $temp;
	my (%association, %name, %address);

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
		$association{'address1'} = $association{'2'};
		$association{'city_state_zip'} = $association{'3'};
		$association{'website'} = $association{'4'};
	} elsif ($association{'5'} =~ m/^Website/i) {
		$association{'address1'} = $association{'2'};
		$association{'address2'} = $association{'3'};
		$association{'city_state_zip'} = $association{'4'};
		$association{'website'} = $association{'5'};
	} elsif ($association{'4'} =~ m/^Association Number/i) {
		$association{'address1'} = $association{'2'};
		$association{'city_state_zip'} = $association{'3'};
	} elsif ($association{'5'} =~ m/^Association Number/i) {
		$association{'address1'} = $association{'2'};
		$association{'address2'} = $association{'3'};
		$association{'city_state_zip'} = $association{'4'};
	}

	($association{'contact'}, $association{'titles'}) = splitAssociationNameTitle($association{'contact_title'});

	%name = splitName_FirstMiddleLast($association{'contact'});

	$association{'website'} =~ s/^Website:(\s)?//i;
	if ($association{'website'} eq 'No Website') {
		$association{'website'} = undef;
	}
	print ("\tassociation: ". $name ." \n");


	$address{'address1'} = $association{'address1'};
	$address{'address2'} = $association{'address2'};
	$address{'city_state_zip'} = $association{'city_state_zip'};
	splitCityStateZip(\%address);	
	formatFullAddress(\%address);

	
	
	# printHash(%association);
	# print (" \n");
	# printHash(%name);
	# print (" \n");
	# printHash(%address);
	# exit;1426

	my %return_association = touchAssociationsContacts(\%association, \%name);
	updateAssociation_hash_byPk(\%association);

	my %return_address = touchAddress(\%address); # l -> lobbist, not a -> association
	touchAssociationsAddresses('a', $return_association{'id'}, $return_address{'id'});
	

	# my %return_company = touchCompany(\%association, \%address);
	# $association{'company_id'} = $return_company{'id'};
	# touchassociations(\%association, \%name);
	# updateassociation_hash_byPk(\%association);

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

			# printHash(%lobbyist);
			# exit;
			# print ("\n \n");

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

 			
 			# printHash(%lobbyist);
 			# print (" \n");
 			# printHash(%name);
			
			
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

sub checkAddressFormat {
	my ($hash_ref, $name_hash, $ref) = @_;
	# printHashRef($hash_ref);
	
	if ($hash_ref->{'company'} =~ m/^(PO Box|Ste)/i) {
		$hash_ref->{'company_type'} = 'ind';
		$hash_ref->{'company'} = $name_hash->{'long_name'};
		$hash_ref->{'company_address1'} = $hash_ref->{'1'};
		$hash_ref->{'company_address2'} = $hash_ref->{'2'};
		
	} elsif ($ref =~ m/1385|954|1642|1649/) { #manual override  
		
		# exit;
		$hash_ref->{'company_type'} = 'ind';
		$hash_ref->{'company'} = $name_hash->{'long_name'};
		$hash_ref->{'company_address1'} = $hash_ref->{'1'};
		$hash_ref->{'company_address2'} = $hash_ref->{'2'};
	}
}