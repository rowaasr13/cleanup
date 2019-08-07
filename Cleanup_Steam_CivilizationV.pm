package Cleanup::Steam::CivilizationV;
use strict;
use warnings;

my @loc_can_be_cleaned = qw(
	English
	French
	German
	Italian
	Polish
	Russian
	Spanish
);

my %loc_should_be_cleaned;
foreach my $loc (@loc_can_be_cleaned) { $loc_should_be_cleaned{$loc} = 1 }
delete $loc_should_be_cleaned{English};

sub directory_should_be_cleaned {
	my ($dir_name, $loc_should_be_cleaned) = @_;

	my @dirs = File::Spec->splitdir($File::Find::dir);
	# use JSON::XS; print "Changed dir: ", encode_json(\@dirs), "\n";

	foreach my $dir (@dirs) {
		if ($loc_should_be_cleaned->{$dir}) { return 1 }
	}

	return 0;
}

sub file_find_make_wanted_delete_unwanted_localization_sounds {
	require File::Find;
	require File::Spec;

	my $last_directory = '';
	my $last_directory_should_be_cleaned;
	my $env = {};

	my $delete_unwanted_localization_sounds = sub {
		if ($last_directory ne $File::Find::dir) {
			$last_directory = $File::Find::dir;
			$last_directory_should_be_cleaned = directory_should_be_cleaned($last_directory, \%loc_should_be_cleaned);
		}

		unless ($last_directory_should_be_cleaned) { return }

		unless (/\.(?:mp3|ogg)$/i) { return }

		$env->{size} += (-s $File::Find::name);
		if ($env->{unlink}) { unlink $File::Find::name }
		# print("$File::Find::dir !!! $File::Find::name ", (-s $File::Find::name), "\n");
	};

	return $delete_unwanted_localization_sounds, $env;
}

sub perform_cleanup {
	my $civ5_dir = "Sid Meier's Civilization V";
	unless(-d $civ5_dir) { return { error => 'required_curdir_steamapps_common_root' } }

	my ($delete_unwanted_localization_sounds, $env) = file_find_make_wanted_delete_unwanted_localization_sounds();

	$env->{unlink} = 1;
	File::Find::find({
		no_chdir => 1,
		wanted => $delete_unwanted_localization_sounds,
	}, $civ5_dir);

	return $env;
}

sub main {
	require Data::Dumper;
	print Data::Dumper::Dumper(perform_cleanup());
}

if (not caller()) { __PACKAGE__->main(\@ARGV) }