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
	
	processLobbyists()
	
}

sub processLobbyists {
	my $lobbyist_url;
	for ('a'..'z') {
		# $lobbyist_url = "http://www.cfboard.state.mn.us/lobby/lbdetail/lbindex$_.html";
		$lobbyist_url = "http://www.cfboard.state.mn.us/lobby/lbdetail/lbindexm.html";

		if (isValidUrl($lobbyist_url)) {
			print ("\nindexpg: $lobbyist_url\n\n");

			my $stream = HTML::TokeParser::Simple->new(url => $lobbyist_url);
			getLobbyistPage($stream);
			exit;
		}
	}
	exit;
}

sub getLobbyistPage {
	my ($stream) = @_;
	while (my $tag = $stream->get_token) {
		if ($tag->is_start_tag('a')) {
			my $lobbyist_id = $tag->get_attr('href');

			if ($lobbyist_id =~m /^\.\./) { # ..is a back index link - break here
				last;
			}
			$lobbyist_id =~ s/^lb//g;
			$lobbyist_id =~ s/\.html$//g;

			# getLobbyistDetails($lobbyist_id);
			getLobbyistDetails('1557');
			exit;
			# 1385|954|1642|1649
			# 2231, 954
			
		}
	}
}

sub getLobbyistDetails {
	my ($lobbyist_id) = @_;

	my $url = "http://www.cfboard.state.mn.us/lobby/lbdetail/lb$lobbyist_id.html";
	
	print ("\t$url \n");
	my $stream2 = HTML::TokeParser::Simple->new(url => $url);
	my $temp;
	my (%lobbyist, %name, %address);

	$lobbyist{'name'} = getLobbyistName($stream2);
 	%name = splitName_FirstMiddleLast($lobbyist{'name'});
 	print ("hi mom \n");

 	printHash(%name);
 	print ("hi bye \n");
 	exit;

 	my $line_count = 0;
 	for (1..5) {
 		$temp = getLobbyistData($stream2);
	 	if ($temp eq '') {
	 		next;
	 	} else {
	 		$line_count++;
	 		$lobbyist{$line_count} = $temp;
	 	}
 	}


 	$lobbyist{'reg_nbr'} = $lobbyist_id;
	if ($lobbyist{'3'} =~ m/^Telephone/) {
		$lobbyist{'company'} = $name{'long_name'};
		$lobbyist{'company_type'} = 'ind';
		$lobbyist{'company_address1'} = $lobbyist{'1'};
		$lobbyist{'company_city_state_zip'} = $lobbyist{'2'};
		$lobbyist{'phone'} = $lobbyist{'3'};
		$lobbyist{'email'} = $lobbyist{'4'};

	} elsif ($lobbyist{'4'} =~ m/^Telephone/) {
		$lobbyist{'company_type'} = 'bus';
		$lobbyist{'company'} = $lobbyist{'1'};
		$lobbyist{'company_address1'} = $lobbyist{'2'};
		$lobbyist{'company_city_state_zip'} = $lobbyist{'3'};
		$lobbyist{'phone'} = $lobbyist{'4'};
		$lobbyist{'email'} = $lobbyist{'5'};
		checkAddressFormat(\%lobbyist, \%name, $lobbyist_id);
	} elsif ($lobbyist{'3'} =~ m/^Email/) {
		$lobbyist{'company'} = $name{'long_name'};
		$lobbyist{'company_type'} = 'ind';
		$lobbyist{'company_address1'} = $lobbyist{'1'};
		$lobbyist{'company_city_state_zip'} = $lobbyist{'2'};
		$lobbyist{'phone'} = $lobbyist{'3'};
		$lobbyist{'email'} = $lobbyist{'4'};
	} elsif ($lobbyist{'4'} =~ m/^Email/) {
		$lobbyist{'company_type'} = 'bus';
		$lobbyist{'company'} = $lobbyist{'1'};
		$lobbyist{'company_address1'} = $lobbyist{'2'};
		$lobbyist{'company_city_state_zip'} = $lobbyist{'3'};
		$lobbyist{'phone'} = $lobbyist{'4'};
		$lobbyist{'email'} = $lobbyist{'5'};
		checkAddressFormat(\%lobbyist, \%name, $lobbyist_id);
	}



	# if ($lobbyist{'reg_nbr'} eq '1557') {
	# 	printHash(%lobbyist);
	# 	exit;
	# }
	$lobbyist{'email'} =~ s/Email:\s//g;
	if ($lobbyist{'email'} eq 'No Email') {
		$lobbyist{'email'} = undef;
	} else {
		$lobbyist{'email_lookup'} = scalar reverse($lobbyist{'email'});
	}
	
	$lobbyist{'phone'} =~ s/Telephone:\s//g;
	# %name = splitName_FirstMiddleLast($lobbyist{'name'});

	print ("\tlobbyist: ". $name{'long_name'} ." \n");

	%address = splitCityStateZip($lobbyist{'company_city_state_zip'});

	printHash(%name);
	exit;

	$address{'company_address1'} = $lobbyist{'company_address1'};
	$address{'company_address2'} = $lobbyist{'company_address2'};

	if ($address{'company_address2'} eq '') {
		$address{'full_address'} = $lobbyist{'company_address1'} . ' ' . $lobbyist{'company_city_state_zip'};
	} else {
		$address{'full_address'} = $lobbyist{'company_address1'} . ' ' . $lobbyist{'company_address2'} . ' ' . $lobbyist{'company_city_state_zip'};
	}
	

	

	my %return_company = touchCompany(\%lobbyist, \%address);
	$lobbyist{'company_id'} = $return_company{'id'};
	touchLobbyists(\%lobbyist, \%name);
	updateLobbyist_hash_byPk(\%lobbyist);

	getAssociations($stream2, \%lobbyist);

}

sub getAssociations {
	my ($stream, $lobbyist_ref) = @_;

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

			my (%association, %types);

			$association{'name'} = getAssociationName($stream);
			$association{'number'} = getAssociationData($stream);
			$association{'reg_date_orig'} = getAssociationData($stream);
			$association{'term_date_orig'} = getAssociationData($stream);
			$association{'type'} = getAssociationData($stream);
			$association{'lobbyist'} = stripWhitespaceBegEnd(getAssociationData($stream));

			$association{'reg_date'} = convertDate($association{'reg_date_orig'}, 'mm/dd/yyyy', 'yyyy/mm/dd');
			$association{'term_date'} = convertDate($association{'term_date_orig'}, 'mm/dd/yyyy', 'yyyy/mm/dd');

			
			if ($association{'lobbyist'} eq '') {
				$association{'designated'} = 0;
			} else {
				$association{'designated'} = 1;
			}
			

			%types = splitLobbyType($association{'type'});;
			
			touchAssociation(\%association);
			touchAssociationsLobbyists($association{'number'}, $lobbyist_ref->{'reg_nbr'});
			updateAssociationsLobbyists_hash_byPk(\%association, \%types, $lobbyist_ref->{'reg_nbr'});
		}
	}

}

sub getAssociationDetails {
	my ($stream, $lobbyist_ref) = @_;

	while (my $tag = $stream->get_tag("td")) {

		if ($tag->is_end_tag('tr')) {
			last;
		}


	}

}
sub getLobbyistName {
	my ($stream) = @_;
	my ($tag, $text);
	$tag = $stream->get_tag("strong");
	$tag = $stream->get_token;
	$text = getTagText($tag);
	$tag = $stream->get_token;
	return $text;
}

sub getLobbyistData {
	my ($stream) = @_;

	my ($tag, $text);
	$tag = $stream->get_tag("br");
	$tag = $stream->get_token;
	$text = getTagText($tag);
	# $text =~ s/^Email:\s//g;

	return $text;
}

sub getAssociationName {
	my ($stream) = @_;
	my ($tag, $text);

	$tag = $stream->get_tag("a");$tag = $stream->get_token;
	$text = getTagText($tag);
	return $text;
}

sub getAssociationData {
	my ($stream) = @_;
	my ($tag, $text);

	$tag = $stream->get_tag("td");$tag = $stream->get_token;
	$text = getTagText($tag);
	return $text;
	# $association{'number'} = getTagText($tag);
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
		# printHashRef($hash_ref);
	}
	# print ("234 \n");
	# exit;
	# 1605

	# $lobbyist{'company_type'} = 'bus';
}
# 1605 - ^ste
# 2210 - st$



# $lobbyist{'company_type'} = 'bus';
# 		$lobbyist{'company'} = $lobbyist{'1'};
# 		$lobbyist{'company_address1'} = $lobbyist{'2'};
# 		$lobbyist{'company_city_state_zip'} = $lobbyist{'3'};
# 		$lobbyist{'phone'} = $lobbyist{'4'};
# 		$lobbyist{'email'} = $lobbyist{'5'};