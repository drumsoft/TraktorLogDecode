#!/opt/local/bin/perl

use strict;
use warnings;
use XML::Simple;

sub main() {
	# get xml string
	local $/;
	undef $/;
	my $xml;
	if ($ARGV[0]) {
		my $in;
		open $in, $ARGV[0] or die "cannot open $ARGV[0]";
		$xml = <>;
		close $in;
	}else{
		$xml = <>;
	}

	# parse
	my $xs = new XML::Simple();
	my $ref = $xs->XMLin($xml);
	my $playlist = $ref->{PLAYLISTS}->{NODE}->{SUBNODES}->{NODE}->{PLAYLIST}->{ENTRY};
	my $collection = $ref->{COLLECTION}->{ENTRY};

	# link metadata
	link_trackinfo($playlist, $collection);
	# make simple
	$playlist = simple_playlist($playlist);
	# print
	print_playlist($playlist);
}

sub link_trackinfo($$) {
	my ($playlist, $collection) = @_;

	my %trackindex = map {
		($_->{LOCATION}->{VOLUME} . $_->{LOCATION}->{DIR} . $_->{LOCATION}->{FILE}
		 => 
		$_)
	} @$collection;

	map {
		$_->{INFO} = $trackindex{$_->{PRIMARYKEY}->{KEY}};
	} @$playlist;
}

sub simple_playlist($) {
	my $playlist = shift;
	[
		map {
			simple_playlist_song($_);
		} @$playlist
	];
}
sub simple_playlist_song($) {
	my $song = shift;

	{
		BPM       => round($song->{INFO}->{TEMPO}->{BPM}),
		ARTIST    => $song->{INFO}->{ARTIST} || '',
		TITLE     => $song->{INFO}->{TITLE} || '',
		ALBUM     => $song->{INFO}->{ALBUM}->{TITLE} || '',
		DECK      => $song->{EXTENDEDDATA}->{DECK},
		STARTDATE => trday2date($song->{EXTENDEDDATA}->{STARTDATE}),
		STARTTIME => sec2time($song->{EXTENDEDDATA}->{STARTTIME}),
		DURATION  => sec2duration($song->{EXTENDEDDATA}->{DURATION}),
	};
}

sub print_playlist($) {
	my $playlist = shift;

	print join "\n", map {
		join "\t", @{$_}{qw(DECK STARTDATE STARTTIME DURATION BPM ARTIST TITLE ALBUM)};
#		join "\t", @{$_}{qw(ARTIST TITLE ALBUM)};
	} @$playlist;

	print "\n";
}

#-------------------------------------------
sub round {
	int((shift) + 0.5);
}

sub sec2duration {
	my $s = shift;
	sprintf "%d:%02d", int($s / 60), ($s % 60);
}

sub sec2time {
	my $s = shift;
	sprintf "%02d:%02d:%02d", int($s / 3600), int($s / 60) % 60, ($s % 60);
}

sub trday2date {
	my $trday = shift;
	sprintf "%04d-%02d-%02d", 
		$trday>>16, ($trday>>8 & 0xff), ($trday & 0xff);
}

#-------------------------------------------
main();

__END__

Sample of song data
{
'PRIMARYKEY' => {
                'KEY' => 'Macintosh HD/:Users/:hrk/:Music/:Traktor Library/:01 Wake Up.mp3',
                'TYPE' => 'TRACK'
              },
'EXTENDEDDATA' => {
                'DURATION' => '298.561981',
                'STARTTIME' => '84215',
                'EXTENDEDTYPE' => 'HistoryData',
                'DECK' => '1',
                'STARTDATE' => '131794189'
              }
'INFO' => {
          'TEMPO' => {
                     'BPM_TRANSIENTCOHERENCE' => '136',
                     'BPM' => '136',
                     'BPM_QUALITY' => '100'
                   },
          'LOCATION' => {
                          'FILE' => '01 Wake Up.mp3',
                          'VOLUMEID' => 'Beef',
                          'VOLUME' => 'Macintosh HD',
                          'DIR' => '/:Users/:hrk/:Music/:Traktor Library/:'
                        },
          'AUDIO_ID' => '.....',
          'MODIFIED_DATE' => '2011/4/10',
          'LOUDNESS' => {
                        'PEAK_DB' => '-0.655512929',
                        'PERCEIVED_DB' => '1.77946603'
                      },
          'ARTIST' => 'Various Artists',
          'MODIFIED_TIME' => '67046',
          'INFO' => {
                    'PLAYTIME' => '300',
                    'GENRE' => 'Holiday',
                    'LAST_PLAYED' => '2011/5/13',
                    'IMPORT_DATE' => '2011/4/11',
                    'BITRATE' => '192000',
                    'PLAYCOUNT' => '1',
                    'FILESIZE' => '7084',
                    'RELEASE_DATE' => '2002/1/1'
                  },
          'TITLE' => 'Wake Up',
          'ALBUM' => {
                     'OF_TRACKS' => '8',
                     'TITLE' => 'Shell Helix In Summer',
                     'TRACK' => '1'
                   },
          'CUE_V2' => {
                      'REPEATS' => '-1',
                      'HOTCUE' => '0',
                      'DISPL_ORDER' => '0',
                      'NAME' => 'AutoGrid',
                      'START' => '164.9263063876048',
                      'LEN' => '0',
                      'TYPE' => '4'
                    }
        },
};

