#  ########  ########  
#  ##     ## ##     ## 
#  ##     ## ##     ## 
#  ##     ## ########  
#  ##     ## ##     ## 
#  ##     ## ##     ## 
#  ########  ########             
use strict;
use DBI;
use DBD::mysqlPP;
use Text::CSV_XS;
use LWP::Simple;
use Try::Tiny;
use DateTime::Format::ISO8601;

use XML::LibXML;
use URI::Escape;

my $dsn = "dbi:mysql:database=channeldragon;host=localhost";
my $user = "simplr_admin";
my $pass = "asdf";
my $database = "channeldragon";
my ($query_handle, $result, $sql_stmt);

$dsn = "DBI:mysqlPP:database=$database;host=localhost";
my $dbh = DBI->connect($dsn, $user, $pass, {RaiseError => 1});
my $sql = qq{SET NAMES 'utf8';};
$dbh->do($sql);

my %datetime = getDateTime();
my $current_date = sprintf("%.4d-%.2d-%.2d", $datetime{year}, $datetime{month}, $datetime{day});
my $current_year = sprintf("%.4d", $datetime{year});

my $api_key = 'AIzaSyAW7vPz_89NdtVK3jwioimGmsMPdwm5avg';
my $youtube_base = 'https://www.googleapis.com/youtube/';
my $youtube_v = 'v3/';

my $youtube_base_2 = 'https://gdata.youtube.com/feeds/api/';


sub getIdAndTotal {
	my ($query_handle) = @_;

	$query_handle->bind_columns(\my ($id, $total));
	
	# LOOP THROUGH RESULTS
	while($query_handle->fetch()) {
		# print ("id: $id \t total: $total \n");
		if ($total == 1) {
			return $id;
		} else {
			return undef;
		}
	}
	return undef;
	# die;
}

sub prepare {
	my ($sql_stmt) = @_;
	# print ("sql_string: $sql_string \n");

	my $sth = $dbh->prepare( $sql_stmt ) or warn "Couldn't prepare statement: " . $query_handle->errstr . " \n $sql_stmt \n";
	return $sth;
}

sub prepareAndExecute {
	my ($sql_string) = @_;
	# print ("sql_string: $sql_string \n");
	$query_handle = $dbh->prepare($sql_string) or warn "Couldn't prepare statement: " . $query_handle->errstr . " \n $sql_string \n";
	
	# EXECUTE THE QUERY
	$query_handle->execute() or die "Couldn't execute statement: " . $query_handle->errstr . " \n $sql_string \n";
	return $query_handle;
}


#  ######## ##     ## ##    ##  ######  ######## ####  #######  ##    ##  ######  
#  ##       ##     ## ###   ## ##    ##    ##     ##  ##     ## ###   ## ##    ## 
#  ##       ##     ## ####  ## ##          ##     ##  ##     ## ####  ## ##       
#  ######   ##     ## ## ## ## ##          ##     ##  ##     ## ## ## ##  ######  
#  ##       ##     ## ##  #### ##          ##     ##  ##     ## ##  ####       ## 
#  ##       ##     ## ##   ### ##    ##    ##     ##  ##     ## ##   ### ##    ## 
#  ##        #######  ##    ##  ######     ##    ####  #######  ##    ##  ######                                                              
sub getDateTime {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = 1900 + $year;
	my %datetime;

	$datetime{year} = $year;
	$datetime{month} = $mon+1;
	$datetime{day} = $mday;
	$datetime{hour} = $hour;
	$datetime{minute} = $min;
	$datetime{second} = $sec;

	return %datetime;
}

sub convertDate {
	my ($str, $format_orig, $format_new) = @_;
	my ($m, $d, $y, $result);
	# print ("str: $str \n");
	# print ("format_orig: $format_orig \t format_new: $format_new \n");

	if ($str !~ m/^(\s)*$/) {
		if ($format_orig eq 'mm/dd/yyyy') {# month and day can be 1 or 2 digits... 04 and 4
			if ($format_new eq 'yyyy/mm/dd') {
				($m, $d, $y) = split (/\//, $str, 3);
				$result = sprintf("%.4d-%.2d-%.2d", $y, $m, $d);
			}
		}
	}

	return $result;
}

sub generateRandomNumber {
	my ($min, $max) = @_;
	my $range = $max - $min;
	# print ("min: $min \t max: $max \n");
	# print ("range: $range \n");

  my $random_number = int(rand($range)) + $min;
  return $random_number;
}

sub printHash {
	my %hash = @_;
	
	while ( my ($key, $value) = each(%hash) ) {
		print "$key => $value\n";
	}
}

sub printHashRef {
	my $hash_ref = shift;
	
	while( my ($key, $value) = each(%$hash_ref) ){
		print "$key => $value\n";
	}
}

sub stripWhitespaceBegEnd {
	my ($string) = @_;
	
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	
	return $string;
}

sub stripWhitespace {
	my ($string) = @_;
	
	$string =~ s/\s{2,}/ /g;
	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;
	
	return $string;
}

sub printLogDateTime {
	my ($log_file, $msg) = @_;
	# my $log_file = shift;
	# my $msg = shift;
	open(LOGFILE, ">>$log_file");
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = 1900 + $year;
	
	$result = sprintf("%.2d/%.2d/%.4d - %.2d:%.2d:%.2d", $mon, $mday, $year, $hour, $min, $sec);
	print LOGFILE "$result: $msg\n";
	close LOGFILE;
}

sub isValidUrl {
	my ($url) = @_;

	if (head($url)) {
		return 'true';
	} else {
		return undef;
	}
}

sub formatDatetimeFromISO {
	my ($dt) = @_;
	return DateTime::Format::ISO8601->parse_datetime($dt);
}

sub formatForeignChars {
	my $string = shift;
	$string = encode('UTF-8', $string);
	
	return $string;
}

sub formatGoogleCharsSearch {
	my ($string) = @_;

	$string =~ s/\s/\+/g;

	$string =~ s/&/%26/g;
	$string =~ s/\//%2F/g;
	return $string;
}

sub matchChannelTitle {
	my ($str) = @_;

	$str =~ m/^https:\/\/gdata\.youtube\.com\/feeds\/api\/users\/(.*)/;

	return ($1);
}

sub getUrlJson {
	my ($json_url) = @_;

	my $browser = WWW::Mechanize->new(autocheck=>0);
	my $perl_scalar;

	if (isValidUrl($json_url)) {
		$browser->get( $json_url );
		my $content = $browser->content();

		my $json = new JSON;
		$perl_scalar = $json->decode( $content );
	}

	return $perl_scalar;
}

sub formatTagText {
	my $string = shift;
	
	$string =~ s/(&amp;|&#038;)/&/g;
	
	$string =~ s/(&#39;)/\'/g;

	$string =~ s/(&nbsp;|&#160;)/ /g;
	$string =~ s/(&#150;|&#151;)/-/g;
	$string =~ s/(&#146;|&#8217;)/'/g;
	$string =~ s/(&#147;|&#148;)/"/g;
	$string =~ s/(&Ouml;|&#214;)/Ö/g;
	
	$string =~ s/(&agrave;|&#224;)/à/g;
	$string =~ s/(&aacute;|&#225;)/á/g;
	$string =~ s/(&acirc;|&#226;)/â/g;
	$string =~ s/(&atilde;|&#227;)/ã/g;
	$string =~ s/(&auml;|&#228;)/ä/g;
	$string =~ s/(&aring;|&#229;)/å/g;
	$string =~ s/(&aelig;|&#230;)/æ/g;
	$string =~ s/(&ccedil;|&#231;)/ç/g;
	$string =~ s/(&egrave;|&#232;)/è/g;
	$string =~ s/(&eacute;|&#233;)/é/g;
	$string =~ s/(&ecirc;|&#234;)/ê/g;
	$string =~ s/(&euml;|&#235;)/ë/g;
	$string =~ s/(&igrave;|&#236;)/ì/g;
	$string =~ s/(&iacute;|&#237;)/í/g;
	$string =~ s/(&icirc;|&#238;)/î/g;
	$string =~ s/(&iuml;|&#239;)/ï/g;
	$string =~ s/(&eth;|&#240;)/ð/g;
	$string =~ s/(&ntilde;|&#241;)/ñ/g;
	$string =~ s/(&ograve;|&#242;)/ò/g;
	$string =~ s/(&oacute;|&#243;)/ó/g;
	$string =~ s/(&ocirc;|&#244;)/ô/g;
	$string =~ s/(&otilde;|&#245;)/õ/g;
	$string =~ s/(&ouml;|&#246;)/ö/g;
	$string =~ s/(&oslash;|&#248;)/ø/g;
	$string =~ s/(&ugrave;|&#249;)/ù/g;
	$string =~ s/(&uacute;|&#250;)/ú/g;
	$string =~ s/(&ucirc;|&#251;)/û/g;
	$string =~ s/(&uuml;|&#252;)/ü/g;
	$string =~ s/(&yacute;|&#253;)/ý/g;
	$string =~ s/(&thorn;|&#254;)/þ/g;
	$string =~ s/(&yuml;|&#255;)/ÿ/g;
	$string =~ s/&#369;/ű/g;
	$string =~ s/&#337;/ő/g;
	
	return $string;
}

sub getTagText {
	my ($text) = @_;

	$text = formatTagText(stripWhitespaceBegEnd($text->as_is));
	return $text;
}


sub printHexChars {
	my $string = @_;
	
	my @array = split(//, $string);
	foreach (@array) {
		#my $temp = oct($_);
		my $temp2 = sprintf "%x", ord($_);
		
		print ("char: $_ \t temp: $temp2 \n");
	}
}

sub escapeWideChar {
	my ($var) = @_;
	
	$var =~ s/[^[:ascii:]]+//g;  # get rid of non-ASCII characters
	
	return $var;
}

sub removeWideChar {
	my ($str) = @_;

	$str =~ s/\\ufeff//g;
	return $str;
}

sub splitAssociationNameTitle {
	my ($str) = @_;
	my ($contact, $titles) = split (/\,/,$str, 2);

	return ($contact, stripWhitespaceBegEnd($titles));
}

sub splitCityStateZip {
	my ($location_hash) = @_;
	# my %location;

	if ($location_hash->{'city_state_zip'} =~ m/Canada$/i) {
		$location_hash->{'country'} = 'CA';
		$location_hash->{'city_state_zip'} =~ s/\,(\s)+Canada//i;

		_splitCityStateZipCountry($location_hash, 'canada');

		# ($location_hash->{'city'}, $location_hash->{'state'}, $location_hash->{'zip'}) = split (/\s/,$location_hash->{'city_state_zip'}, 3);
		# $location_hash->{'zip'} =~ s/\,(\s)+Canada$//i;
	} elsif ($location_hash->{'city_state_zip'} =~ m/^Canada/i) {
		# print ("\n \n");
		# printHashRef($location_hash);
		$location_hash->{'country'} = 'CA';
		$location_hash->{'city_state_zip'} = $location_hash->{'address2'};
		$location_hash->{'address2'} = undef;
		
		_splitCityStateZipCountry($location_hash, 'canada');
		# printHashRef($location_hash);
		# exit;
	} else {
		$location_hash->{'country'} = 'US';
		_splitCityStateZipCountry($location_hash);
		# ($location_hash->{'city'}, $location_hash->{'state_zip'}) = split (/\,\s/,$location_hash->{'city_state_zip'}, 2);
		# ($location_hash->{'state'}, $location_hash->{'postal_code'}) = split (/\s/,$location_hash->{'state_zip'}, 2);
		# ($location_hash->{'zip'}, $location_hash->{'zip_4_code'}) = split (/\-/,$location_hash->{'postal_code'}, 2);
		# if ($location_hash->{'zip'} =~ m/\,/i) {
		# 	printHashRef($location_hash);
		# 	exit;
		# }
	}
}

sub _splitCityStateZipCountry {
	my ($location_hash, $format) = @_;

	$location_hash->{'city_state_zip'} = stripWhitespace($location_hash->{'city_state_zip'});

	if ($format eq 'canada') {
		$location_hash->{'zip'} = substr($location_hash->{'city_state_zip'}, -7);
		$location_hash->{'city_state'} = substr($location_hash->{'city_state_zip'}, 0, -8);
		($location_hash->{'city'}, $location_hash->{'state'}) = split(/\s([^\s]+)$/, $location_hash->{'city_state'});
	} else {
		($location_hash->{'city'}, $location_hash->{'state_zip'}) = split (/\,\s/,$location_hash->{'city_state_zip'}, 2);
		($location_hash->{'state'}, $location_hash->{'postal_code'}) = split (/\s/,$location_hash->{'state_zip'}, 2);
		($location_hash->{'zip'}, $location_hash->{'zip_4_code'}) = split (/\-/,$location_hash->{'postal_code'}, 2);
	}

}

sub splitLobbyType {
	my ($str) = @_;
	my ($leg, $adm, $metro) = 0;
	my %types = ('leg', 0, 'adm', 0, 'metro', 0);
	# print ("str: $str \n");

	my @arr = split(/\//, $str);
	foreach (@arr) {
		if ($_ =~ m/^Leg$/g) {
			$types{'leg'} = 1;
		}
		if ($_ =~ m/^Adm$/g) {
			$types{'adm'} = 1;
		}
		if ($_ =~ m/^Metro$/g) {
			$types{'metro'} = 1;
		}
	}
	return (%types);
}

sub splitName_FirstMiddleLast {
	my ($long_name) = @_;

	$long_name =~ s/\b(jr|jr\.|sr|sr\.|II|III|IV|V|VI|VII|VIII)$//i;  # remove suffix
	my ($ln, $fn) = split (/\,/,$long_name, 2);
	$long_name = $fn . ' ' . $ln;

	$long_name = stripWhitespaceBegEnd($long_name);
	# $long_name =~ s/&nbsp;/ /g;
	my @full = split (/ /,$long_name, 4);

	my $length = @full;
	my %name;
	
	# $name{'long_name'} = $long_name;
	
	$name{'first_name'} = $full[0];
	if ($length == 2) {
		$name{'middle_name'} = undef;
		$name{'last_name'} = $full[1];
	} elsif ($length == 3) {
		my $mname_first_char = substr($full[1], 0, 1);
		if ($full[1] =~ m/^(den)$|^(del)$|^(de)$|^(la)$|^(van)$|^(von)$|^(di)$|^(st\.)$/i) {
		#if($mname_first_char =~ m/[de]/i) { # de la van st. o'
			$name{'middle_name'} = undef;
			$name{'last_name'} = $full[1] .' '. $full[2];
		} elsif ($full[1] =~ m/^(o')$|^(d')$/i) {
			$name{'middle_name'} = undef;
			$name{'last_name'} = $full[1] . ' ' . $full[2];
		} elsif ($full[1] =~ m/van't/i) {
			$name{'middle_name'} = undef;
			$name{'last_name'} = $full[1] .' '. $full[2];
		} elsif (($full[1] =~ m/Boero/i) && ($full[2] =~ m/Hughes/i)) {
			$name{'middle_name'} = undef;
			$name{'last_name'} = $full[1] .' '. $full[2];
		} else {
			$name{'middle_name'} = $full[1];
			$name{'last_name'} = $full[2];
		}
	} elsif ($length == 4) {
		if ($full[1] =~ m/Rossi/i && $full[2] =~ m/di/i && $full[3] =~ m/Montelera/i ||
				$full[1] =~ m/de/i && $full[2] =~ m/Saint/i && $full[3] =~ m/Victor/i ||
				$full[1] =~ m/Paz/i && $full[2] =~ m/Yanez/i && $full[3] =~ m/Macias/i ||
				$full[1] =~ m/del/i && $full[2] =~ m/Pino/i && $full[3] =~ m/Duran/i ||
				$full[1] =~ m/del/i && $full[2] =~ m/Pino/i && $full[3] =~ m/Duran/i ||
				$full[1] =~ m/van/i && $full[2] =~ m/der/i) {
					
			$name{'middle_name'} = undef;
			$name{'last_name'} = $full[1].' '.$full[2].' '.$full[3];
		} elsif ($full[2] =~ m/^(den)$|^(de)$|^(la)$|^(van)$|^(von)$|^(di)$|^(st\.)$/i) {
			$name{'middle_name'} = $full[1];
			$name{'last_name'} = $full[2].' '.$full[3];
		} elsif ($full[0] =~ m/^[a-z]$/i && $full[1] =~ m/^[a-z]$/i) { 
			$name{'first_name'} = $full[0] . ' ' . $full[1];
			$name{'middle_name'} = $full[2];
			$name{'last_name'} = $full[3];
		} elsif ($full[2] =~ m/Deputy/i && $full[3] =~ m/Ott/i) {
			$name{'middle_name'} = '';
			$name{'last_name'} = $full[2].' '.$full[3];
		} elsif ($full[1] =~ m/Jean/i && $full[2] =~ m/Marie/i && $full[3] =~ m/Turrini/i) {
			$name{'middle_name'} = $full[1].' '.$full[2];
			$name{'last_name'} = $full[3];
		} elsif ($full[2] =~ m/^[a-z]$/i) {
			$name{'middle_name'} = $full[1] . ' ' . $full[2];
			$name{'last_name'} = $full[3];
		} else {
			$name{'middle_name'} = $full[1];
			$name{'last_name'} = $full[2].' '.$full[3];
		}
	}

	if ($name{'first_name'} =~ m/\((.*)\)/g) {
		$name{'nick_name'} = $1;
		$name{'first_name'} =~ s/\((.*)\)//g;
	} elsif ($name{'middle_name'} =~ m/\((.*)\)/g) {
		$name{'nick_name'} = $1;
		$name{'middle_name'} =~ s/\((.*)\)//g;
	} elsif ($name{'last_name'} =~ m/\((.*)\)/g) {
		$name{'nick_name'} = $1;
		$name{'last_name'} =~ s/\((.*)\)//g;
	}

	$name{short_name} = $name{first_name} . ' ' . $name{last_name};

	$long_name = $name{first_name} . ' ' . $name{middle_name} . ' ' . $name{last_name};
	$long_name =~ s/\s{2}/ /;
	$name{long_name} = $long_name;
	# $name{name_websafe} = formatWebsafe($name{long_name});

	return %name;
}

sub formatFullAddress {
	my ($address_hash) = @_;


	if ($address_hash->{'address2'} eq '') {
		$address_hash->{'full_address'} = $address_hash->{'address1'} . ' ' . $address_hash->{'city_state_zip'};
	} else {
		$address_hash->{'full_address'} = $address_hash->{'address1'} . ' ' . $address_hash->{'address2'} . ' ' . $address_hash->{'city_state_zip'};
	}

	if ($address_hash->{'country'} =~ m/ca/i) {
		$address_hash->{'full_address'} = $address_hash->{'full_address'} . ' Canada';
	}

	$address_hash->{'full_address'} = stripWhitespace($address_hash->{'full_address'});
	if ($address_hash->{'full_address'} eq '') {
		$address_hash->{'full_address'} = undef;
	}
}


#   ######   #######  ##          ########  #######  ##     ##  ######  ##     ## 
#  ##    ## ##     ## ##             ##    ##     ## ##     ## ##    ## ##     ## 
#  ##       ##     ## ##             ##    ##     ## ##     ## ##       ##     ## 
#   ######  ##     ## ##             ##    ##     ## ##     ## ##       ######### 
#        ## ##  ## ## ##             ##    ##     ## ##     ## ##       ##     ## 
#  ##    ## ##    ##  ##             ##    ##     ## ##     ## ##    ## ##     ## 
#   ######   ##### ## ########       ##     #######   #######   ######  ##     ## 

{
	my $sth;
	sub touchLobbyists {
		my ($lobbyist_hash, $name_hash) = @_;
		my %return = ('updated', 'false', 'id', undef);
		# print ("touchChannels - id: $channel_id \t $channel_title\n");
		# printHashRef($lobbyist_hash);
		
		$return{'id'} = getLobbyistReg_byReg($lobbyist_hash->{'reg_nbr'});
		
		if (!$return{'id'}) {
			# print ("touch lobbyist new: ". $lobbyist_hash->{'reg_nbr'}." \n");
			# exit;
			if (!$sth) {
				$sql_stmt = "INSERT INTO mn_campaign_finance.lobbyists (registration_number, first_name, middle_name, last_name, nick_name, long_name, principal_business)
						SELECT ?, ?, ?, ?, ?, ?;";
				$sth = prepare($sql_stmt);
			}
			$sth->execute($lobbyist_hash->{'reg_nbr'}
								, $name_hash->{'first_name'}
								, $name_hash->{'middle_name'}
								, $name_hash->{'last_name'}
								, $name_hash->{'nick_name'}
								, $name_hash->{'long_name'});
			
			$return{'updated'} = 'true';
			$return{'id'} = getLobbyistReg_byReg($lobbyist_hash->{'reg_nbr'});
		}
		return %return;
	}
}

# {
# 	my $sth;
# 	sub touchCompany {
# 		my ($lobbyist_hash, $address_hash) = @_;
# 		my %return = ('updated', 'false', 'id', undef);
		
# 		$return{'id'} = getCompanyId_byName($lobbyist_hash->{'company'});
		
# 		if (!$return{'id'}) {
# 			# print ("touchCompany new \n");
# 			# exit;
# 			if (!$sth) {
# 				$sql_stmt = "INSERT INTO mn_campaign_finance.companies (name, alternate_name, type, street1, street2, city, region, zip, zip_4_code, country, full_address)
# 						SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?;";
# 				$sth = prepare($sql_stmt);
# 			}
# 			$sth->execute($lobbyist_hash->{'company'}
# 									, $lobbyist_hash->{'alternate_name'}
# 									, $lobbyist_hash->{'company_type'}
# 									, $address_hash->{'company_address1'}
# 									, $address_hash->{'company_address2'}
# 									, $address_hash->{'city'}
# 									, $address_hash->{'state'}
# 									, $address_hash->{'zip'}
# 									, $address_hash->{'zip_4_code'}
# 									, $address_hash->{'country'}
# 									, $address_hash->{'full_address'});
			
# 			$return{'updated'} = 'true';
# 			$return{'id'} = getCompanyId_byName($lobbyist_hash->{'company'});
# 		}
# 		return %return;
# 	}
# }

{
	my $sth;
	sub touchAddress {
		my ($address_hash) = @_;
		my %return = ('updated', 'false', 'id', undef);
		
		$return{'id'} = getAddressId_byFull($address_hash->{'full_address'});
		
		if (!$return{'id'}) {
			# print ("touchCompany new \n");
			# exit;
			if (!$sth) {
				$sql_stmt = "INSERT INTO mn_campaign_finance.addresses (street1, street2, city, region, zip, zip_4_code, country, full_address)
						SELECT ?, ?, ?, ?, ?, ?, ?, ?;";
				$sth = prepare($sql_stmt);
			}
			$sth->execute($address_hash->{'address1'}
									, $address_hash->{'address2'}
									, $address_hash->{'city'}
									, $address_hash->{'state'}
									, $address_hash->{'zip'}
									, $address_hash->{'zip_4_code'}
									, $address_hash->{'country'}
									, $address_hash->{'full_address'});
			
			$return{'updated'} = 'true';
			$return{'id'} = getAddressId_byFull($address_hash->{'full_address'});
		}
		return %return;
	}
}

{
	my $sth;
	sub touchAssociation {
		my ($association_hash) = @_;
		my %return = ('updated', 'false', 'id', undef);
		
		$return{'id'} = getAssociation_byNbr($association_hash->{'association_nbr'});
		
		if (!$return{'id'}) {
			# print ("touchAssociation new  \n");
			# exit;
			if (!$sth) {
				$sql_stmt = "INSERT INTO mn_campaign_finance.associations (association_number, name)
						SELECT ?, ?;";
				$sth = prepare($sql_stmt);
			}
			$sth->execute($association_hash->{'association_nbr'}
									, $association_hash->{'name'});
			
			$return{'updated'} = 'true';
			$return{'id'} = getAssociation_byNbr($association_hash->{'association_nbr'});
		}
		return %return;
	}
}

{
	my $sth;
	sub touchAssociationsAddresses {
		my ($type, $type_id, $address_id) = @_;
		my %return = ('updated', 'false', 'id', undef);
		# print ("type: $type \t type_id: $type_id \n");
		# print ("address_id: $address_id \n");
		
		$return{'id'} = getAssociationsAddresses_byPk($type, $type_id, $address_id);
		
		if (!$return{'id'}) {
			# print ("touch touchAssociationsLobbyists new:  association_nbr: $association_nbr \t registration_nbr: $registration_nbr \t reg_date: $registration_date\n");
			# exit;
			if (!$sth) {
				$sql_stmt = 'INSERT INTO mn_campaign_finance.associations$addresses (type, type_id, address_id)
						SELECT ?, ?, ?;';
				$sth = prepare($sql_stmt);
			}
			$sth->execute($type
									, $type_id
									, $address_id);
			
			$return{'updated'} = 'true';
			$return{'id'} = getAssociationsAddresses_byPk($type, $type_id, $address_id);
		}
		return %return;
	}
}

{
	my $sth;
	sub touchAssociationsLobbyists {
		my ($association_nbr, $registration_nbr, $registration_date) = @_;
		my %return = ('updated', 'false', 'id', undef);
		
		$return{'id'} = getAssociationLobbyists_byPk($association_nbr, $registration_nbr, $registration_date);
		
		if (!$return{'id'}) {
			# print ("touch touchAssociationsLobbyists new:  association_nbr: $association_nbr \t registration_nbr: $registration_nbr \t reg_date: $registration_date\n");
			# exit;
			if (!$sth) {
				$sql_stmt = 'INSERT INTO mn_campaign_finance.associations$lobbyists (association_number, registration_number, registration_date)
						SELECT ?, ?, ?;';
				$sth = prepare($sql_stmt);
			}
			$sth->execute($association_nbr
									, $registration_nbr
									, $registration_date);
			
			$return{'updated'} = 'true';
			$return{'id'} = getAssociationLobbyists_byPk($association_nbr, $registration_nbr, $registration_date);
		}
		return %return;
	}
}

{
	my $sth;
	sub touchAssociationsContacts {
		my ($association_hash, $name_hash) = @_;
		my %return = ('updated', 'false', 'id', undef);
		
		$return{'id'} = getAssociationsContacts_byPk($association_hash->{'association_nbr'}, $current_year);
		
		if (!$return{'id'}) {
			if (!$sth) {
				$sql_stmt = 'INSERT INTO mn_campaign_finance.associations$contacts (association_number, title, year, first_name, middle_name, last_name, nick_name, long_name)
						SELECT ?, ?, ?, ?, ?, ?, ?, ?;';
				$sth = prepare($sql_stmt);
			}
			$sth->execute($association_hash->{'association_nbr'}
									, $association_hash->{'titles'}
									, $current_year
									, $name_hash->{'first_name'}
									, $name_hash->{'middle_name'}
									, $name_hash->{'last_name'}
									, $name_hash->{'nick_name'}
									, $name_hash->{'long_name'});
			
			$return{'updated'} = 'true';
			$return{'id'} = getAssociationsContacts_byPk($association_hash->{'association_nbr'}, $current_year);
		}
		return %return;
	}
}


#   ######   #######  ##           ######   ######## ########    #### ########  
#  ##    ## ##     ## ##          ##    ##  ##          ##        ##  ##     ## 
#  ##       ##     ## ##          ##        ##          ##        ##  ##     ## 
#   ######  ##     ## ##          ##   #### ######      ##        ##  ##     ## 
#        ## ##  ## ## ##          ##    ##  ##          ##        ##  ##     ## 
#  ##    ## ##    ##  ##          ##    ##  ##          ##        ##  ##     ## 
#   ######   ##### ## ########     ######   ########    ##       #### ########  
{
	my $sth;
	sub getLobbyistReg_byReg {
		my ($reg_nbr) = @_;
		# print ("getChannelId_byChannelTitle: $channel_title \n");
		if ($reg_nbr) {
			if (!$sth) {
				$sql_stmt = "SELECT registration_number, count(*)
					from mn_campaign_finance.lobbyists
					where registration_number = ?;";
				$sth = prepare($sql_stmt);
			}
			$sth->execute($reg_nbr);
			return getIdAndTotal($sth);
		}
	}
}

{
	my $sth;
	sub getAddressId_byFull {
		my ($full_address) = @_;
		# print ("getChannelId_byChannelTitle: $channel_title \n");
		if ($full_address) {
			if (!$sth) {
				$sql_stmt = "SELECT id, count(*)
					from mn_campaign_finance.addresses
					where full_address = ?;";
				$sth = prepare($sql_stmt);
			}
			$sth->execute($full_address);
			return getIdAndTotal($sth);
		}
	}
}

{
	my $sth;
	sub getAssociation_byNbr {
		my ($association_nbr) = @_;
		
		if ($association_nbr) {
			if (!$sth) {
				$sql_stmt = "SELECT association_number, count(*)
					from mn_campaign_finance.associations
					where association_number = ?;";
				$sth = prepare($sql_stmt);
			}
			$sth->execute($association_nbr);
			return getIdAndTotal($sth);
		}
	}
}

{
	my $sth;
	sub getAssociationLobbyists_byPk {
		my ($association_nbr, $registration_nbr, $registration_date) = @_;
		
		if ($association_nbr) {
			if (!$sth) {
				$sql_stmt = 'SELECT association_number, count(*)
									from mn_campaign_finance.associations$lobbyists
									where association_number = ? and registration_number = ? and registration_date = ?;';
				$sth = prepare($sql_stmt);
			}
			$sth->execute($association_nbr, $registration_nbr, $registration_date);
			return getIdAndTotal($sth);
		}
	}
}

{
	my $sth;
	sub getAssociationsAddresses_byPk {
		my ($type, $type_id, $address_id) = @_;
		
		if ($type) {
			if (!$sth) {
				$sql_stmt = 'SELECT type_id, count(*)
									from mn_campaign_finance.associations$addresses
									where type = ? and type_id = ? and address_id = ?;';
				$sth = prepare($sql_stmt);
			}
			$sth->execute($type, $type_id, $address_id);
			return getIdAndTotal($sth);
		}
	}
}

{
	my $sth;
	sub getAssociationsContacts_byPk {
		my ($association_nbr, $year) = @_;
		
		if ($association_nbr) {
			if (!$sth) {
				$sql_stmt = 'SELECT association_number, count(*)
									from mn_campaign_finance.associations$contacts
									where association_number = ? and year = ?;';
				$sth = prepare($sql_stmt);
			}
			$sth->execute($association_nbr, $year);
			return getIdAndTotal($sth);
		}
	}
}

#   ######   #######  ##          ##     ## ########  ########     ###    ######## ########  ######  
#  ##    ## ##     ## ##          ##     ## ##     ## ##     ##   ## ##      ##    ##       ##    ## 
#  ##       ##     ## ##          ##     ## ##     ## ##     ##  ##   ##     ##    ##       ##       
#   ######  ##     ## ##          ##     ## ########  ##     ## ##     ##    ##    ######    ######  
#        ## ##  ## ## ##          ##     ## ##        ##     ## #########    ##    ##             ## 
#  ##    ## ##    ##  ##          ##     ## ##        ##     ## ##     ##    ##    ##       ##    ## 
#   ######   ##### ## ########     #######  ##        ########  ##     ##    ##    ########  ######  
{
	my $sth;
	sub updateLobbyist_hash_byPk {
		my ($lobbyist_hash) = @_;

		if (!$sth) {
			$sql_stmt = 'UPDATE mn_campaign_finance.lobbyists 
									SET `company_id` = ?
									, `phone` = ?
									, `email` = ?
									, `email_lookup` = ?
									, principal_business = ?
			WHERE registration_number = ?;';
			$sth = prepare($sql_stmt);
		}
		$sth->execute($lobbyist_hash->{'company_id'}
								, $lobbyist_hash->{'phone'}
								, $lobbyist_hash->{'email'}
								, $lobbyist_hash->{'email_lookup'}
								, $lobbyist_hash->{'company'}
								, $lobbyist_hash->{'reg_nbr'});
	}
}

{
	my $sth;
	sub updateAssociation_hash_byPk {
		my ($association_hash) = @_;

		if (!$sth) {
			$sql_stmt = 'UPDATE mn_campaign_finance.associations 
									SET `url` = ?
			WHERE association_number = ?;';
			$sth = prepare($sql_stmt);
		}
		$sth->execute($association_hash->{'website'}
								
								, $association_hash->{'association_nbr'});
	}
}

{
	my $sth;
	sub updateAssociationsLobbyists_hash_byPk {
		my ($association_hash, $types_hash, $registration_nbr) = @_;

		if (!$sth) {
			$sql_stmt = 'UPDATE mn_campaign_finance.associations$lobbyists 
									SET `termination_date` = ?
									, `is_legislative` = ?
									, `is_administrative` = ?
									, `is_metropolitan` = ?
									, `is_designated_lobbyist` = ?
			WHERE association_number = ? and registration_number = ? and registration_date = ?;';
			$sth = prepare($sql_stmt);
		}
		$sth->execute($association_hash->{'term_date'}
								, $types_hash->{'leg'}
								, $types_hash->{'adm'}
								, $types_hash->{'metro'}
								, $association_hash->{'designated'}
								, $association_hash->{'association_nbr'}
								, $registration_nbr
								, $association_hash->{'reg_date'});
	}
}

{
	my $sth;
	sub updateAssociationsLobbyists_hashPartial1_byPk {
		my ($association_hash, $registration_nbr) = @_;

		if (!$sth) {
			$sql_stmt = 'UPDATE mn_campaign_finance.associations$lobbyists 
									set `termination_date` = ?
									, `is_designated_lobbyist` = ?
			WHERE association_number = ? and registration_number = ? and registration_date = ?;';
			$sth = prepare($sql_stmt);
		}
		$sth->execute($association_hash->{'term_date'}
								, $association_hash->{'designated'}
								, $association_hash->{'association_nbr'}
								, $registration_nbr
								, $association_hash->{'reg_date'});
	}
}

1;