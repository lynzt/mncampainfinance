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

my $log_file = $root_path . '/scripts/load_expenditures.txt';
my $processed_at = $cfg->param("common_vars.processed_at");

mainProgram();

sub mainProgram {
	my $url = 'http://www.cfboard.state.mn.us/lobby/lobbyist.html';

	my $stream = HTML::TokeParser::Simple->new(url => $url);
	my $temp;
	
	$stream->get_tag("table");
	my $count = 0;
	while ($stream->get_tag("tr")) {
		$count++;
		getLobbyistData($stream);
		# if ($count > 320) {
		# 	exit;
		# }
		
	}
}

sub getLobbyistData {
	my ($stream) = @_;
	my (%lobbyist, %name, %address);

	for (1..6) {
		# $stream->get_tag("td");
		$lobbyist{$_} = getLobbyistDetails($stream);
 	}
	
 	if ($lobbyist{'1'} =~ m/^Lobbyist/i) {
 		print ("header row \n");
 		return;
 	}
 	

 	%name = splitName($lobbyist{'1'});
	if (!%name) {
		%name = splitName_FirstMiddleLast($lobbyist{'1'}, 'ln_fn');
	}
 	# printHash(%name);

 	$lobbyist{'address'} = $lobbyist{'2'};
 	$lobbyist{'phone'} = $lobbyist{'3'};
 	$lobbyist{'reg_nbr'} = $lobbyist{'4'};
 	$lobbyist{'from_date'} = convertDate($lobbyist{'5'}, 'mm/dd/yyyy', 'yyyy/mm/dd');
 	$lobbyist{'termination_date'} = convertDate($lobbyist{'6'}, 'mm/dd/yyyy', 'yyyy/mm/dd');

	print ("\n");
 	print ("$name{'long_name'}: $lobbyist{'reg_nbr'} \n");
 	%address = splitAddress($lobbyist{'address'});
 	
 	# printHash(%lobbyist);

 	# printHash(%address);
 	# exit;

 	
 	my %return_people = touchPeople(\%lobbyist, \%name);
 	updatePeople_Phone_byId(\%lobbyist, $return_people{'id'});
 	my %return_lobbyist = touchLobbyist(\%lobbyist, $return_people{'id'});
 	updateLobbyist_Dates_byPk(\%lobbyist, $return_lobbyist{'id'});
 	
 	my %return_address = touchAddress(\%address); 
 # 	if ($address{'zip_4_code'}) {
	# 	updateAddress_zip_byPk(\%address, $return_address{'id'});
	# }
 	touchAssociationsAddresses('l', $return_people{'id'}, $return_address{'id'}); # l -> lobbist, not a -> association

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
	}
	$text =~ s/,\s$//g;

	return $text;
}

sub splitName {
	my ($name_str) = @_;
	my %name;
	my ($fn, $mn, $ln);

	$name_str =~ s/\b(jr|jr\.|sr|sr\.|II|III|IV)$//i;  # remove suffix
	if ($1) {
		$name{'suffix'} = $1;
	}

	my @parts = split (/\,\s/,$name_str, 3);
	my $parts_length = @parts;
	if ($parts_length == 2) {
		if ($parts[1] =~ m/\s/) {
			return;
		} else {
			$name{'last_name'} = $parts[0];
			$name{'first_name'} = $parts[1];
			$name{'long_name'} = $name{'first_name'} . ' ' . $name{'last_name'};
		}
		
	} elsif ($parts_length == 3) {
		$name{'last_name'} = $parts[0];
		$name{'last_name'} =~ s/\b(jr|jr\.|sr|sr\.|II|III|IV)$//i;  # remove suffix
		if ($1) {
			$name{'suffix'} = $1;
		}
		$name{'first_name'} = $parts[1];
		$name{'middle_name'} = $parts[2];
		$name{'long_name'} = $name{'first_name'} . ' ' . $name{'middle_name'} . ' ' . $name{'last_name'};
	}

	return %name;
}

sub splitAddress {
	my ($address) = @_;
	my @arr;
	my %address;

	@arr = split(/\,\s/, $address);

	my $processed_street1 = undef;

	foreach (@arr) {
		my $line = stripWhitespaceBegEnd($_);
		$line =~ s/\.//g;
		$line =~ s/\,$//i;
		$address{'street1'} =~ s/,(\s)+$//g;
		$line = addressAbbrs($line);
		
		# print ("line: $line \n");
		
		if ($line =~ m/^(c\/o\sAnn\sTinker)/i) {
			next;
		}
		elsif ($line =~ m/^(\d+|PO\sBox|c\/o\s)/i) {
			$address{'street1'} = $line;
			$processed_street1 = 'true';

		} elsif ($line =~ m/^(Two Gateway Center|One General Mills|One W Lake St|One W Water St|One Tower Square)/i) {
			$address{'street1'} = $line;
			$processed_street1 = 'true';
		} elsif ($line =~ m/^(Ste|Rm)(\s|\.)/i) {
			$address{'street1'} .= ' ' . $line;
		# } elsif ($line =~ m/^(Ste|Rm)\./i) {
		# 	$address{'street1'} .= ' ' . $line;
		} elsif ($line =~ m/^#(\d)+/i) {
			$address{'street1'} .= ' ' . $line;
		} elsif ($line =~ m//i) {
			$address{'street1'} .= ' ' . $line;
		} elsif ($processed_street1) {
			$address{'city_state_zip'} .= $line . ', ';
		} else {
			$address{'principal_business'} = $line;
		}
	}

	
	$address{'city_state_zip'} =~ s/,\s$//g;

	if ($address{'street1'} =~ m/(.*)\s(PO\sBox.*)$/i) {
		$address{'principal_business'} = $1;
		$address{'street1'} = $2;
	}
	splitStreets(\%address);
	splitCityStateZip(\%address);

	
 	formatFullAddress(\%address);

	return %address;
}