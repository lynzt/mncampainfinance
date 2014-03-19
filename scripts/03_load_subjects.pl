#!/usr/local/bin/perl
use strict;
use Config::Simple;
use File::Basename;
use HTML::TokeParser::Simple;

use WWW::Mechanize;
use JSON;
use Data::Dumper;

#
# loop thru subject page: http://www.cfboard.state.mn.us/lobby/subjectlist.html
# 	for each subject - load page and loop thru details and add record
#		updates tables: subjects, associations$lobbyists$subjects
#
#		note: didn't use this page: http://www.cfboard.state.mn.us/lobby/lobbysub.html
# 		because the other page we have keys w/o lookups
#

require '/Users/ltechel/scripts/mncampainfinance/modules/common.pm';

my $browser = WWW::Mechanize->new(autocheck=>0);

# channel_id json
# https://www.googleapis.com/youtube/v3/search?part=id%2Csnippet&maxResults=1&q=lynzteee&type=channel&key=AIzaSyAW7vPz_89NdtVK3jwioimGmsMPdwm5avg
# my $lobbyist_index_url = 'http://www.cfboard.state.mn.us/lobby/lbatoz.html';

my $log_file = '/Library/WebServer/Documents/cdragon/scripts/helper script/03_load_subjects.txt';

# my $processed_thru = '2014-03-09 23:13:00';

mainProgram();

sub mainProgram {
	
	processSubjects()
	
}

sub processSubjects {
	my $subjects_url;
	
	$subjects_url = "http://www.cfboard.state.mn.us/lobby/subjectlist.html";

	if (isValidUrl($subjects_url)) {
		print ("\nindexpg: $subjects_url\n\n");

		my $stream = HTML::TokeParser::Simple->new(url => $subjects_url);
		getSubjects($stream);
	}
}

sub getSubjects {
	my ($stream) = @_;
	my $run_now = 'false';
	my $sid = '1608';
	while (my $tag = $stream->get_token) {
		if ($tag->is_start_tag('a')) {
			my $subject_id = $tag->get_attr('href');

			$subject_id =~ s/^subjlob\/subj//g;
			$subject_id =~ s/\.html$//g;
			print ("subject_id: $subject_id \n");

			# getSubjectDetails('1608');
			# exit;

			if ($sid eq $subject_id) {
				$run_now = 'true';
			}
			if ($run_now eq 'true') {
				getSubjectDetails($subject_id);
			} else {
				next;
			}
			
		}
	}
}

sub getSubjectDetails {
	my ($subject_id) = @_;

	my $url = "http://www.cfboard.state.mn.us/lobby/subjlob/subj$subject_id.html";
	
	print ("\t$url \n");
	my $stream2 = HTML::TokeParser::Simple->new(url => $url);
	my $loop = 'true';
	my (%subject);
	$subject{'subject_id'} = $subject_id;
	$subject{'name'} = getSubjectName($stream2);
	print ("subject: $subject{'name'} \n");
	stripNewlineCharsBegEnd($subject{'name'});
	touchSubjects(\%subject);

	while($loop) {
		my $lobbyist = getSubjectInfo($stream2, 'l');
		my $association = getSubjectInfo($stream2, 'a');
		print ("lobbyist: $lobbyist \t association: $association \n");
		
		if ($lobbyist && $association) {
			my $al_id = getAssociationLobbyists_wFallback($association, $lobbyist);
			
			if (!$al_id) {
				my $al_id = getAssociationLobbyists_wFallback($association, $lobbyist);
			}
			if (!$al_id) {
				print (" no id...:   \n");
				print ("subject{'association'}: $association \t subject{'lobbyist'}: $lobbyist \n");
				exit;
			} else {
				touchAssociationsLobbyistsSubjects($al_id, $subject{'subject_id'});
			}
		} else {
			$loop = undef;
		}
	}
}

sub getSubjectName {
	my ($stream) = @_;
	
	my $tag = $stream->get_tag("title");$tag = $stream->get_token;
	my $text = getTagText($tag);
	$text =~ s/^Subject\s\-\s//i;
	$text = substr($text, 2);

	return $text;
}

sub getSubjectInfo {
	my ($stream, $type) = @_;
	my $id;
	my $tag = $stream->get_tag("a");
	if (!$tag) {
		return;
	}

	my $href = $tag->get_attr('href');

	# my $text = getTagText($tag);
	if ($href) {
		# print ("href: $href \n");
		if ($type eq 'l') {
			$href =~ m/lb(\d+)\.html$/;
			$id = $1;
		} else {
			$href =~ m/\/a(\d+)\.html$/;
			$id = $1;
		}
		return $id;
	}
}