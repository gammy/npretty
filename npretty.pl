#!/usr/bin/perl -w
#
# Next Generation Pretty
#
# Copyright (C) 2006-2012 Kristian Gunstone
#
# A simple thumbnail and page generator which
# uses common software to do the job.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# REQUIRED dependencies:
# - Anything but Windows (fork won't work)
# - kernel threading support
# - perl > 5.8.x (untested on anything lower)
# - fork perl module (use 'force install forks' in cpan)
# - Image::ExifTool perl module (use 'force install Image::ExifTool' in cpan)
# - Image::Magic (use 'force install Image::Magick' in cpan)
# - Getopt::Long
# 
# SUGGESTED dependencies:
# mplayer (with as many codecs as possible)
# (use 1.0pre7try2, 1.0pre9 has broken gif89a output)
# display (comes with imagemagick)
# jhead   (for pre-processing)
#
# Pre-git Changelog:
# n3.0/0.9
# 	remove duplicate slashed in path
# 	thread bug fix when calling jhead
# 	template parser minor bugfixes
# 	Fixed bug in recursive move
# 	Fixed problem in listcalc
# 	Incredibly, more bugfixes
# 	MORE bugfixes
# 	More bugfixes
# 	Added --skip-pages
# 	Replaced old thumb link code with code similar to prevs
# 	Added side padding for thumb/preview link lists
# 	Additional argument checks and minor bugfixes
# n3.0/0.8
# 	Modified progress output a little
# 	Added config override support
# 	Added overwrite support
# 	Added template selection argument
# 	Comment code bugfixes and cleanups
# 	Switched to bsd_glob
# 	Fixed bug in directory glob code
# 	New tag NPRETTY_TITLE_NOEXIST and code
# 	New tag NPRETTY_TITLE_EXIST and code
# 	Fixed some problems with tag reading without images present
# 	Fixed yet an other comment bug
# 	Strip odd chars from filenames (see stripChars)
# 	Fixed comment file location problem
# 	Added -title argument
# 	Fixed bug in thumbs/page calculation from a4
# 	Added --destination argument
# 	Added (almost) all new arguments to argument parser
# 	Argument parser rewrite
# 	Fixed bug in comment handler (would apply comment even if it was empty)
# 	Fixed a bug in the delimiter + padding code (thanks uchman)
# n3.0/0.7
# 	Skip copying images if --skip-images is set
# 	Modified preview list index tag code (Ree filed a complaint)
# 	Modified comment tags and code as requested (thanks Ree)
# 	Added delimiter padding tag and code (thanks Ree)
# 	Fixed a problem with sloppy page creation on very small archives
# 	Added preview list index tag and code (thanks Ree)
# 	Got rid of zero-indexing on all output (pagenum, thumbnum, etc)
# 	Added filesize tag
# 	Resampling algorithm selection
# 	Quality setting on JPEG/MIFF/PNG
# 	Use EXIF-w/h if image is jpeg (speeds up thumb/preview creation)
# 	Optimised use of magick object in thumb dimension read
# 	Added a 'no video preview available' image and code
# 	Using 'cp' for copy instead of builtin routines
# 	Now using Image::Magick directly (not the convert binary)
# 	width/height check fix
# n3.0/0.6
# 	Rewrote template parser
# 	Added video support for previewing
# 	--skip-images support (includes video)
# n3.0/0.5
# 	Change dimensions of preview image if larger than original
# 	Preliminary video conversion support
# 	preview aspect change (no arghandler yet)
# 	Thumbnail delimiter code
# 	Preprocessor (jhead) code
# 	Template code
# 	Sloppy page info correction (output was broken)
# 	Preliminary thumb+preview generation
# 	Proper output filename generation
# n3.0/0.4
# 	Page generation modes
# 	Sloppy pages
# n3.0/0.3
# 	File permission read+write checks
# 	Basic comment store/load
# 	Configuration file support
# 	FIX: recursive mode broke if dir did not contain subdirs
# n3.0/0.2
# 	Threading job support
# 	Save/Load comment support
# 	Preview image support
# n3.0/0.1
# 	Extensive permission checks before job starts
# 	No session file
# 	Recursive directory parsing
# 	Argument parser
# 	Simultaneous job handling
# 	Comment support
#
#Notes:
#files shouldn't have the same name as a directory
#

use strict;
use Image::Magick;
use Image::ExifTool 'ImageInfo';
use Getopt::Long;
use File::Find;
use forks;
use Fcntl ':mode';
$SIG{CHLD} = 'DEFAULT'; # Needs to be set to IGNORE during forks

### Arguments

## Defaults
my $templatefile		=	"npretty_template.tpl";
my $vid_converter_path		=	"";
my $img_path			=	".";
my $dest			=	".";
my $img_dest			=	"img";
my $thumb_dest			=	"thumbs";
my $prevpage_dest		=	"previews"; #NEW 0.5
my $preview_dest		=	"$prevpage_dest/preview";
my $thumbpage_prefix		=	"index"; #Will have number and .html appended
my $thumb_prefix		=	"_thumb_"; # Will be prepended with index id
my $preview_prefix		=	"_preview_"; # Will be prepended with index id

my $thumb_dimensions		=	"100x100";
my $preview_dimensions		=	"800x600";
my $video_preview_dimensions	=	"320x240";
my $image_quality		=	"85"; # JPEG/MIFF/PNG only
my $resize_algorithm		=	"Box";
					# Point, Box, Triangle,Hermite, Hanning, 
					# Hamming, Blackman, Gaussian, Quadratic, 
					# Cubic, Catrom, Mitchell, Lanczos,Bessel, Sinc
my $sidepad			=	"..&nbsp;";
my $thumb_keep_aspect		=	1;
my $preview_keep_aspect		=	1;
my $recursive			=	0;
my $maxdepth			=	-1;
my $comments			=	0;
my $overwrite			=	0;
my $overwrite_images		=	0;
my $overwrite_thumbs		=	0;
my $overwrite_previews		=	0;
my $jobs			=	2;
my $max_thumbs_per_page		=	20;
my $max_pages			=	0;
my $thumbnail_links		=	9;
my $preview_links		=	9;
my $pagebuild_type		=	0; # 0 = number of thumbs, 1 = number of pages
my $sloppy_mode			=	0;
my $sloppy_files		=	3;
my $generation_mode		=	0; # 0 = all, 1 = images only, 2 = pages only
my $show_preview		=	0; # 0 = yes, 1 = no
                                         # ^ for viewing images before commenting them
my $use_vidconverter		=	0;
my $use_preprocessor		=	0;
my $pre_remove_cthumbs		=	0; # Remove thumbnails in images
my $pre_auto_rotate		=	0; # Autorotate images

my $delete_originals		=	0;

my $commentfile			=	".npretty_comments";
my $no_video_image		=	"novideo.gif";

my $image_view			=	"display -resize 640x480+0+0 ";
my $video_view			=	"mplayer ";
my @configuration		=	(".npretty_config", "/home/$ENV{'USER'}/.npretty_config", "/etc/npretty/npretty.conf");

## General
my $VERSION = "n0.9.3";
my $vid_converter = "mplayer";
my $pre_processor = "jhead";

## Other
my $title = "";
my $config = "";

my %filetypes = (
    "jpg" => "img",
    "jpeg"=> "img",
    "png" => "img",
    "bmp" => "img",
    "gif" => "img",
    "tif" => "img",
    "mpg" => "vid",
    "mpeg"=> "vid",
    "avi" => "vid");
    		
my %overwritemodes = ("y" => 0, "n" => 1, "A" => 2, "N" => 3); # yes no All None

my @arglist =(
    "video-preview-dimensions=  video preview dimensions XxY",
    "image-quality=             image quality in percent (JPEG/MIFF/PNG only)",
    "resize-algorithm=          resizing algorithm, set to 'help' for list",
    "keep-thumb-ratio           keep aspect ratio of thumbnails", 
    "keep-preview-ratio         keep aspect ratio of previews",
    "use-video                  use video converter",
    "use-preprocessor           use pre-processor",
    "pre-remove-cthumbs         remove cam thumbs with pre-processor",
    "pre-auto-rotate            auto-rotate images with pre-processor",
    "jobs=                      jobs to run simultaneously",
    "mplayer-path=              path to 'mplayer' binary",
    "image-path=                path to images",
    "image-dest=                destination path for images",
    "thumb-dest=                destination path for thumbs",
    "destination=               destination prefix for archive",
    "preview-dest=              destination path for previews",
    "thumb-dimensions=          thumbnail dimensions, XxY",
    "preview-dimensions=        preview dimensions XxY",
    "thumbs-per-page=           max thumbs per page",
    "pages=                     max number of pages",
    "sloppy-files=              be sloppy on page calculation",
    "title=                     text to prepend to title tag",
    "config=                    use config instead of config hierarchy",
    "sidepad=                   string to pad thumb/preview lists with",
    "delete-originals           delete original images",
    "overwrite-images           overwrite images",
    "overwrite-previews         overwrite previews",
    "overwrite-thumbs           overwrite thumbnails",
    "overwrite-all              overwrite everything",
    "overwrite-nothing          overwrite nothing",
    "template                   template file to use",
    "skip-images                skip image creation",
    "skip-pages                 skip page creation",
    "recursive                  recursively look for images",
    "maxdepth                   traversal depth if recursive",
    "comments                   ask for comment on each image",
    "preview                    show preview before comment",
    "sloppy                     enable sloppiness",
    "help                       this text",
    "version                    version");

# Do not fuck with these
my $i; #Cough
my @progmap		= ();
my @preview_dimension	= (); # index-specific dimensions
my $useoldcomments	= 0;


my @threadlist		= ();
my $finishedthreads	= 0;

my @badfiles		= ();
my @badfileperms	= ();

my @CARGV		= ();
my @page_index		= ();
my $internal_pages	= (); # Need to be fixed?
my $internal_thumbs	= ();
my $NTAG='<!-- Generated by npretty v'.$VERSION.' by gamkiller. http://www.pulia.nu -->'."\n";

my @filelist		= (); # Original file paths
my @imglist		= (); # New path and new names
my @thumblist		= (); # Thumbnail filenames
my @prevpagelist	= (); # Preview pages
my @prevlist		= (); # Preview filenames
my %work;		      # <file> Contains bools, 1 to work, 0 to not.
my @tmpargs		= ();
my @ov_list		= ();
my $mode;

### Subroutines
sub usage{
    my $padding;
    print "Usage: npretty <arguments>\n";
    print "Example: npretty --image-path=.\n\n";
    print "Options:\n";
    foreach (@arglist){
	print "\t--$_\n";
    }
    print "
This is free software; see the source for copying conditions. There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n";

    exit 0;
}

sub init_thread{
    $threadlist[threads->list()] = threads->create("start_thread", @_);
}

sub start_thread{
    my ($message, $in, $arguments, $out) = @_;
    print "$message";
    my $image = Image::Magick->new;
    my $ret = $image->Read($in);
    warn "$ret" if "$ret";
    #$ret = $image->Thumbnail(geometry=>"$arguments");
    $ret = $image->Resize(geometry=>"$arguments", filter=>"$resize_algorithm");
    warn "$ret" if "$ret";

    ## TEST
    #$ret = $image->Annotate(font=>'kai.ttf', gravity=>"NorthWest", pointsize=>10, fill=>'white', text=>"zomg (C)");
    #warn "$ret" if "$ret";

    $ret = $image->Set(quality=>$image_quality);
    warn "$ret" if "$ret";
    $ret = $image->Write($out);
    warn "$ret" if "$ret";
    undef $image;
    threads->self->detach();
    return;
}

sub init_sys_thread{
    $threadlist[threads->list()] = threads->create(
	"start_sys_thread", 
	"$_[0]", 
	"$_[1]"
    );
}

sub start_sys_thread{
    print "$_[1]";
    system("$_[0]");
    threads->self->detach();
    return;
}

sub filesize{
    my $file = $_[0];
    open(FILE, "<$_[0]") or die "ERROR: Failed to open \"$_[0]\" for read (filesize check)";
    seek(FILE, 0, 2);
    my $filesize = tell(FILE);
    close(FILE);
    return $filesize;
}

sub load{
    my ($buf, $filesize, $bytesread) = ("", 0, 0);
    open(LOADDESC, "<$_[0]") or die "ERROR: Failed to open \"$_[0]\" for read";
    seek(LOADDESC, 0, 2);
    $filesize = tell(LOADDESC);
    seek(LOADDESC, 0, 0);
    $bytesread = read(LOADDESC, $buf, $filesize, 0);
    close(LOADDESC);
    return "$buf";
}

sub save{
    open(FILE, ">$_[0]") or die "ERROR: Failed to open \"$_[0]\" for write";
    print FILE $_[1];
    close(FILE);
}

sub replaceExifTags{
    my ($buf, $info) = @_;
    
    if($buf=~m/\[NPRETTY_EXIF_.+?\]/){
	# Collect
	my @exiflist;
	while($buf=~m/\[NPRETTY_EXIF_(.+?)\]/g){
	    push(@exiflist, $1);
	}
	foreach my $exif (@exiflist){
	    my $found = 0;
	    my $replacement = "Missing";
	    foreach my $cmp (sort keys %$info){
		if("$cmp" eq "$exif"){
		    $found = 1;
		    last;
		}
	    }
	    $replacement = $$info{$exif} if $found;
	    $buf =~s/\[NPRETTY_EXIF_$exif\]/$replacement/g;
	}
    }else{
	#print "DEBUG: No EXIF tags in block\n";
    }

    return $buf;

}

sub replaceTags{
    my ($buf, %tag) = @_;
    foreach my $r (sort keys %tag){
	my $repl = $tag{"$r"};
	$buf =~s/\Q$r\E/$repl/g;
    }
    return $buf;
}

sub setPreviewDimensions{
    my ($info, $offset, $image) = @_;

    if("$progmap[$offset]" eq "vid"){
	$preview_dimension[$offset] = $video_preview_dimensions;
    }else{
	my ($imgwidth, $imgheight) = (0, 0);
	if(lc(substr($image, -4)) eq ".jpg" || lc(substr($image, -5)) eq ".jpeg"){
	    ($imgwidth, $imgheight) = ($$info{'ImageWidth'}, $$info{'ImageHeight'});
	}else{
	    my $magick = Image::Magick->new;
	    $magick->Read("$image");
	    ($imgwidth, $imgheight) = $magick->Get('width', 'height');
	    undef $magick;
	}
	    
	my ($curwidth, $curheight) = (split("x", $preview_dimensions));
	#my ($imgwidth, $imgheight) = ($$info{"ImageWidth"}, $$info{"ImageHeight"});
	if($imgwidth < $curwidth && $imgheight < $curheight){
	    $preview_dimension[$offset] = $imgwidth."x".$imgheight;
	}else{
	    $preview_dimension[$offset] = $preview_dimensions;
	}
    }
}

sub getPageName{
    my $thumbpage = $thumbpage_prefix;
    $thumbpage .= sprintf("_%03d", $_[0]) if $_[0] != 1;
    $thumbpage .= ".html";
    return $thumbpage;
}

sub stripChars{
    my $in = $_[0];
    my $out;

    # Translation map for swedish iso-8859-1 letters
    $in =~tr/åäöAÄÖ/aaoAAO/;
    
    # Replace everything else except .
    for(my $i = 0;$i < length($in); $i++){
	my $c = substr($in, $i, 1);
	if("$c" ne "." && $c=~/[[^\W]|[^\D]]/){
	    $c = "_";
	}
	$out .= $c;
    }
    $out =~s/_+/_/g;
    return $out;
}

sub askOverwrite{
    print "Overwrite? [y/n/A/N]";
    my $checkcomment = "";
    while("$checkcomment" ne 'y' && 
	"$checkcomment" ne 'n' &&
	"$checkcomment" ne 'A' &&
	"$checkcomment" ne 'N'){
	$checkcomment = <STDIN>;
	chomp($checkcomment);
    }
    return $overwritemodes{$checkcomment};
}

sub checkOverwrite{
    my $path = shift;
    foreach(@_){
	my $filename = "$path$_";
	if(-f "$filename"){;
	    print "\"$filename\" already exists. ";
	    my $ret = askOverwrite();
	    if($ret == 0){ # yes
		push(@ov_list, $_); # With no path
	    }elsif($ret == 1){ #no
	    }elsif($ret == 2){ #All
		foreach my $img (@_){
		    my $ignore = 0;
		    foreach my $ignoreimg (@ov_list){
			if("$img" eq "$ignoreimg"){
			    $ignore = 1;
			    last;
			}
		    }
		    $work{$img} = 1 unless $ignore;
		}
		last;
	    }elsif($ret == 3){ #None
		foreach my $img (@_){
		    my $ignore = 0;
		    foreach my $ignoreimg (@ov_list){
			if("$img" eq "$ignoreimg"){
			    $ignore = 1;
			    last;
			}
		    }
		    if(-f "$path$img" && $ignore == 0){
			$work{$img} = 0;
		    }else{
			$work{$img} = 1;
		    }
		}
		last;
	    }
	}
    }

    foreach(@ov_list){
	$work{$_} = $overwrite;
    }
}

### Internal variable checks and setup

### Main
print "npretty v$VERSION by gamkiller.\n\n";

usage() if @ARGV == 0;

## Extended argument parser (NEW)

foreach my $arg (@ARGV){
    if("$arg" =~m/--config=(.+)/s){
	$config = $1;
	@configuration = ("$1");
    }else{
	push(@tmpargs, $arg);
    }
}
@ARGV = @tmpargs;
@tmpargs = ();

# Check for configfiles and prepend to arglist
foreach (@configuration){
    if(-f "$_"){
	$mode = (stat("$_"))[2];
	die "Configuration file \"$_\" is unreadble" if ($mode & S_IRUSR) == 0;
	open(FILE, "<$_");
	@tmpargs = <FILE>;
	close(FILE);
	chomp(@tmpargs);
	s/\s+$// foreach @tmpargs;
	@ARGV = (@tmpargs, @ARGV);
	print "Prepended \"$_\" to argument list.\n";
    }else{
	die "Couldn't find config file \"$_\"\n" if "$config" ne "";
    }
}

# Note that --config is not in @ARGV since we pre-parsed it
my $result = GetOptions(
    "destination=s"	=> \$dest,
    "jobs=i"		=> \$jobs,
    "use-video"		=> \$use_vidconverter,
    "use-preprocessor"	=> \$use_preprocessor,
    "pre-remove-cthumbs"=> \$pre_remove_cthumbs,
    "pre-auto-rotate"	=> \$pre_auto_rotate,
    "image-quality=i"	=> \$image_quality,
    "resize-algorithm=s"=> \$resize_algorithm,
    "mplayer-path=s"	=> \$vid_converter_path,
    "image-path=s"	=> \$img_path,
    "image-dest=s"	=> \$img_dest,
    "thumb-dest=s"	=> \$thumb_dest,
    "preview-dest=s"	=> \$preview_dest,
    "video-preview-dimensions=s"=> \$video_preview_dimensions,
    "thumb-dimensions=s"=> \$thumb_dimensions,
    "preview-dimensions=s"=> \$preview_dimensions,
    "thumbs-per-page=i"	=> sub{$pagebuild_type = 0; $max_thumbs_per_page=$_[1];},
    "pages=i"		=> sub{$pagebuild_type = 1; $max_pages=$_[1];},
    "sloppy-files=i"	=> \$sloppy_files,
    "title=s"		=> \$title,
    "template=s"	=> \$templatefile,
    "sidepad=s"		=> \$sidepad,
    "delete-originals"	=> \$delete_originals,
    "overwrite-images"	=> \$overwrite_images,
    "overwrite-previews"=> \$overwrite_previews,
    "overwrite-thumbs"	=> \$overwrite_thumbs,
    "overwrite-all"	=> sub{$overwrite = 1;},
    "overwrite-nothing"	=> sub{$overwrite = 2;},
    "skip-images"	=> sub{$generation_mode = 2;},
    "skip-pages"	=> sub{$generation_mode = 1;},
    "recursive"		=> \$recursive,
    "maxdepth=i"	=> \$maxdepth,
    "keep-thumb-ratio"	=> \$thumb_keep_aspect,
    "keep-preview-ratio"=> \$preview_keep_aspect,
    "comments"		=> \$comments,
    "preview"		=> \$show_preview,
    "sloppy"		=> \$sloppy_mode,
    "help"		=> sub{usage(); exit 0;},
    "version"		=> sub{exit 0;}
);

## Set commentfile
$commentfile = "$dest/$commentfile";
	    
## Check that args are within range
die "Maximum number of jobs is 8 for your own safety" if $jobs < 1 or $jobs > 8;
die "Incorrect thumbnail dimension format" unless $thumb_dimensions =~m/^[0-9]+?x[0-9]+?$/;
die "Incorrect preview dimension format" unless $preview_dimensions =~m/^[0-9]+?x[0-9]+?$/;
die "Incorrect video preview dimension format" unless $video_preview_dimensions =~m/^[0-9]+?x[0-9]+?$/;
die "Incorrect image quality range" if $image_quality < 0||$image_quality > 100;

if($recursive == 1) {
	# No traversal limit unless the user explicitly set one using --maxdepth 
	$maxdepth = 0 if $maxdepth == -1; 
} else {
	$maxdepth = 1;
}

my @resize_algorithms = qw(Point Box Triangle Hermite Hanning Hamming Blackman Gaussian Quadratic Cubic Catrom Mitchell Lanczos Bessel Sinc);
if(lc($resize_algorithm) eq "help"){
    print "\nAvailable resizing algorithms: @resize_algorithms\n";
    exit 0;
}
my $exists = 0;
foreach (@resize_algorithms){
    $exists = 1 if "$resize_algorithm" eq "$_";
}
die "Incorrect resize algorithm. Algorithms: @resize_algorithms" unless $exists;
undef $exists;
undef @resize_algorithms;

# Expand paths
$img_path=~s/~/$ENV{'HOME'}/g;
$dest=~s/~/$ENV{'HOME'}/g;
$commentfile=~s/~/$ENV{'HOME'}/g;

## Check existence
die "\"$img_path\" is not a directory.\n" unless -d "$img_path";
$useoldcomments = 1 if -f "$commentfile";

my $found = 0;
foreach("$templatefile", "$ENV{'HOME'}/$templatefile", "/etc/npretty/$templatefile"){
    if(-f "$_"){
	$templatefile = $_;
	$found = 1;
	last;
    }
}
die "Couldn't find template \"$templatefile\"" if $found == 0;
print "Using \"$templatefile\" as template.\n\n";

$found = 0;
foreach("$no_video_image", "$ENV{'HOME'}/$no_video_image", "/etc/npretty/$no_video_image"){
    if(-f "$_"){
	$no_video_image = $_;
	$found = 1;
	last;
    }
}
die "Couldn't find novideo image \"$no_video_image\"" if $found == 0;
    
## Check external programs
if($use_vidconverter){
    if(system("$vid_converter > /dev/null 2>&1") != 0){
	print "WARN: Failed to testrun video converter \"$vid_converter\", disabling video conversion.\n";
	$use_vidconverter = 0;
    }
}

if($use_preprocessor){
    if(system("$pre_processor -V > /dev/null 2>&1") != 0){
	print "WARN: Failed to testrun pre-processor \"$pre_processor\", disabling pre-processing.\n";
	$use_preprocessor = 0;
    }
}

## Check permissions

# We have to create destination here to satisfy tests
unless(-d "$dest"){
    print "Creating \"$dest\"...";
    die "Could not create \"$dest\"" if mkdir("$dest") != 1;
    print "ok.\n";
}elsif(-e "$dest"){
    print "NOTE: \"$dest\" already exists.\n";
}
# Prepend destination to destination variables
my ($abs_img_dest, $abs_prevpage_dest, $abs_preview_dest, $abs_thumb_dest) = 
($img_dest, $prevpage_dest, $preview_dest, $thumb_dest);

$thumb_dest = "$dest/$thumb_dest";
$img_dest = "$dest/$img_dest";
$prevpage_dest = "$dest/$prevpage_dest";
$preview_dest = "$dest/$preview_dest";

# Remove duplicate slashes in paths
$thumb_dest =~s/\/+/\//g;
$img_dest =~s/\/+/\//g;
$prevpage_dest =~s/\/+/\//g;
$preview_dest =~s/\/+/\//g;

# image, thumb, preview and preview page destination check
foreach ("$thumb_dest", "$img_dest", "$prevpage_dest", "$preview_dest", "$img_path"){
    unless(-d "$_"){
	die "\"$_\" exists but is not a directory" if(-e "$_");
    }else{
	$mode = (stat("$_"))[2];
	die "\"$_\" is not readable" if ($mode & S_IRUSR) == 0;
	unless("$_" eq "$img_path"){
	    die "\"$_\" is not writeable" if ($mode & S_IWUSR) == 0;
	}
    }
}
#FIXME: More checks here?
#NOTE: File read+write checks are done after file list collection

## Collection with recursive directory support (NEW)
$| = 1; # Set canonical output
#Get file list
print "Compiling file list...";
$img_path = substr($img_path, 0, -1) if substr($img_path, (length($img_path) - 1), 1) eq "/";
File::Find::find({wanted => sub {
			my $depth = $File::Find::name =~ tr#/##; # Count slashes
			return if $maxdepth > 0 && $depth > $maxdepth;
			if(-f) {
				my $name = $File::Find::name;
				for my $type (keys %filetypes) {
					push @filelist, $name if 
						$name =~ m/\.\Q$type\E$/i;
				}

			}
		},
	}, $img_path);
print "ok.\n";
print @filelist . " files.\n";

#Check permissions on newly added files
print "\n";
foreach (@filelist){
    $mode = (stat("$_"))[2];
    if( (($mode & S_IRUSR) == 0) || (($mode & S_IWUSR) == 0)){
	push(@badfiles, "$_");
	push(@badfileperms, $mode);
    }
}

if(@badfiles > 0){
    print @badfiles . " did not have read+write permissions.\n";
    print "Correct these files:\n";
    print "   #  mode\tfile\n";
    for(my $i = 0; $i < @badfiles; $i++){
	printf("%4d: %04o\t%s\n", $i, ($badfileperms[$i] & 07777), $badfiles[$i]);
    }
    print "Cannot continue. Exit.\n";
    exit 1;
}
    
die "No files means nothing to do" if @filelist == 0;

## Directory creation (except destination which was previously created)
foreach ("$thumb_dest", "$prevpage_dest", "$preview_dest", "$img_dest"){
    unless(-d "$_"){
	print "Creating \"$_\"...";
	die "Could not create \"$_\"" if mkdir("$_") != 1;
	print "ok.\n";
    }elsif(-e "$_"){
	print "NOTE: \"$_\" already exists.\n";
    }
}

## Generate new filenames for images, thumbnails, previews and preview pages
#  and map filetypes to decoders
for(my $i = 0; $i < @filelist; $i++){
    my $s = rindex($filelist[$i], "/") + 1;
    my ($directory, $filename) = (substr($filelist[$i], 0, $s), substr($filelist[$i], $s));
    my $prefix = sprintf("%03d", $i + 1);

    $filename = stripChars($filename);
    push(@progmap, $filetypes{lc(substr($filename, (rindex($filename, ".") + 1)))});

    push(@imglist,	$prefix."_".$filename);
    
    substr($filename, rindex($filename, "."), length($filename), ".gif") if "$progmap[$i]" eq "vid";
    push(@thumblist,	"$prefix$thumb_prefix$filename");
    push(@prevlist,	"$prefix$preview_prefix$filename");
    push(@prevpagelist,	"$prefix$preview_prefix" . substr($filename, 0, rindex($filename, ".")) . ".html");
    
}

## Check overwrite stuff, ugly :(.
foreach(@imglist, @thumblist, @prevlist){
    if($overwrite == 2){
	$work{$_} = 0;	
    }else{	
	$work{$_} = 1;
    }
}

if($overwrite == 0 && $generation_mode != 2){
    checkOverwrite("$img_dest/", @imglist) unless $overwrite_images;
    checkOverwrite("$preview_dest/", @prevlist) unless $overwrite_previews;
    checkOverwrite("$thumb_dest/", @thumblist) unless $overwrite_thumbs;

    if($overwrite_images){
	$work{$_} = 1 foreach (@imglist);
    }
    if($overwrite_previews){
	$work{$_} = 1 foreach (@prevlist);
    }
    if($overwrite_thumbs){
	$work{$_} = 1 foreach (@thumblist);
    }
}

undef @ov_list;

## Copy files to dest
if($generation_mode != 2){
    for(my $i = 0; $i < @filelist; $i++){
	next unless $work{$imglist[$i]};
	print "$filelist[$i] -> $img_dest/$imglist[$i]\n";
	system("cp \"$filelist[$i]\" \"$img_dest/$imglist[$i]\"");
    }
}

goto GENERATION if $generation_mode == 1;

## Save/Load comments
my %commenthash;

if($comments == 0 and $useoldcomments == 1){
    print "\nA comment file was located but comments have been disabled.\n";
    print "Would you like to enable comments now? [y/n]";
    my $checkcomment = "";
    while(lc($checkcomment) ne 'y' && lc($checkcomment) ne 'n'){
	$checkcomment = <STDIN>;
	chomp($checkcomment);
    }
    $comments = 1 if "$checkcomment" eq "y";
}
if($comments == 1 and $useoldcomments == 1){
    print "\nFound commentfile, loading...";
    open(FILE, "<$commentfile");
    foreach (<FILE>){
	my $offset = index($_, "\t", 0);
	if($offset == -1){
	    print "\nWARN: A line in the commentfile is broken! Skipped.";
	}else{
	    $commenthash{substr($_, 0, $offset)} = substr($_, ($offset + 1));
	    chomp($commenthash{substr($_, 0, $offset)});
	}
    }
    close(FILE);
    print "ok.\n";
    print "Looking up files.\n";
    my $found;
    for(my $j = 0; $j < @filelist; $j++){
	$found = 0;
	foreach(keys %commenthash){
	    if("$_" eq "$filelist[$j]"){
		$found = 1;
		last;
	    }
	}
	if($found == 0){
	    #FIXME: Replicated code
	    my $previewer = $image_view;
	    $previewer = $video_view if "$progmap[$j]" eq "vid";
	    system("echo -n \"Previewing \\\"$filelist[$j]\\\"...\"; $previewer \"$filelist[$j]\" > /dev/null 2>&1 && echo \"ok\" || echo \"failed\"") if $show_preview == 1;
	    print "Comment " . ($j+1) . " ($filelist[$j]): ";
	    my $tmp = <STDIN>; 
	    chomp($tmp);
	    $commenthash{$filelist[$j]} = $tmp;
	    # Save directly in case user interrupts
	    open(FILE, ">>$commentfile");
	    print FILE "$filelist[$j]\t$tmp\n";
	    close(FILE);
	}
    }
}elsif($comments == 1 and $useoldcomments == 0){
    print "\n";
    for($i = 0; $i < @filelist; $i++){
	my $previewer = $image_view;
	$previewer = $video_view if "$progmap[$i]" eq "vid";
	system("echo -n \"Previewing \\\"$filelist[$i]\\\"...\"; $previewer \"$filelist[$i]\" > /dev/null 2>&1 && echo \"ok\" || echo \"failed\"") if $show_preview == 1;
	print "Comment " . ($i+1) . " ($filelist[$i]): ";
	my $tmp = <STDIN>; 
	chomp($tmp);
	$commenthash{$filelist[$i]} = $tmp;
	# Save directly in case user interrupts
	open(FILE, ">>$commentfile") or die "couldn't open \"$commentfile\"!";
	print FILE "$filelist[$i]\t$tmp\n";
	close(FILE);
    }
}

if($comments){
    open(FILE, ">$commentfile");
    foreach (sort keys %commenthash){
	my $found = 0;
	for(my $i = 0; $i < @filelist; $i++){
	    $found = 1 if "$_" eq "$filelist[$i]";
	}
	if($found){
	    print FILE "$_\t$commenthash{$_}\n";
	}else{
	    print "Removed $_ from commentfile.\n";
	}
    }
    close(FILE);
}


print "\nCalculating page layout.\n";
## Page pre-calculation
if($pagebuild_type == 0){ # --thumbs-per-page
    my $tmpimgcount = 0;
    for(my $tmpcalc = 0; $tmpcalc < @imglist; $tmpcalc++){
        $tmpimgcount++;
        if(($tmpcalc + 1) % $max_thumbs_per_page == 0){
            $internal_pages++;
            push(@page_index, $tmpimgcount);
            $tmpimgcount = 0;
        }
    }
    if(@page_index * $max_thumbs_per_page != @imglist){
        push(@page_index, (@imglist - (@page_index * $max_thumbs_per_page)));
        $internal_pages++;
    }
    if($page_index[$#page_index] <= $sloppy_files && $sloppy_mode == 1 && $#imglist > $max_thumbs_per_page){
	print "Being sloppy, moved $page_index[$#page_index] images to page " . ($internal_pages - 1) . ".\n";
        $page_index[($#page_index - 1)] += $page_index[$#page_index];
        pop(@page_index);
        $internal_pages--;
    }
}elsif($pagebuild_type == 1){ # --max_pages
    my $tmpimgcount = 0;
    $internal_thumbs = int(@imglist / $max_pages);
    die "ERROR: Fewer thumbs than requested number of pages! Bluntly assuming you made a mistake " if $internal_thumbs < 1;
    for(my $tmpcalc = 0; $tmpcalc < $max_pages; $tmpcalc++){
        push(@page_index, $internal_thumbs);
        $tmpimgcount += $internal_thumbs;
    }
    $page_index[$#page_index] += (@imglist - $tmpimgcount);
}else{ # Fuckup
    die "Internal error: Incorrect value in \$pagebuild_type ($pagebuild_type)";
}

print "Generating preview and thumbnail pages.\n";

## Generate thumbnail and preview pages

my $template_buf = load("$templatefile");

# Read in seperate template blocks
my %template;
foreach("THUMB", "BODY", "PREVIEW"){
    if($template_buf=~m/\[NPRETTY_BLOCK_$_\](.+?)\[\/NPRETTY_BLOCK_$_\]/s){
	$template{$_} = $1;
    }else{
	die "ERROR: Required block $_ was not found in template";
    }
}

die "ERROR: Required block BODY not found in THUMB block" unless $template{"THUMB"} =~m/\[NPRETTY_BODY\]/;

# Replace title tag
$template{"THUMB"} =~s/\[NPRETTY_TITLE\]/$title/gs;
$template{"BODY"} =~s/\[NPRETTY_TITLE\]/$title/gs;
$template{"PREVIEW"} =~s/\[NPRETTY_TITLE\]/$title/gs;

# Get image delimiter 
my ($delimiter, $img_delimiter_rep, $img_delimiter) = (0, 0, "");
if($template{"BODY"} =~s/\[NPRETTY_DEL_([0-9]+)\](.*?)\[\/NPRETTY_DEL\]//s){
    ($img_delimiter_rep, $img_delimiter) = ($1, $2);
    last if $img_delimiter_rep == 0;
    $delimiter = 1;
    print "Delimiting every $img_delimiter_rep thumbnails.\n";
}

# Get all extra buffers needed
my %sub_template;
foreach(
    "PREV_EXIST", "PREV_NOEXIST", "LIST", "LIST_IFSEL", "NEXT_EXIST", "NEXT_NOEXIST", 
    "PREV_IMG_EXIST", "PREV_IMG_NOEXIST", "NEXT_IMG_EXIST", "NEXT_IMG_NOEXIST",
    "COMMENT_EXIST", "PREV_LIST", "PREV_LIST_IFSEL", "PAD_DEL"){ #NPRETTY_TITLE_EXIST
    foreach my $tplname ("THUMB", "BODY", "PREVIEW"){
	$sub_template{"$tplname$_"} = ""; # To prevent warnings
	if($template{$tplname} =~m/\[(NPRETTY_$_\])(.*?)\[\/\1/s){
	    $sub_template{"$tplname$_"} = $2;
	}
    }
}

# Grab delimiter padding
my $delimiter_padding = $sub_template{"BODYPAD_DEL"};

# Prepare the thumbnail linkindex lists
my $offset = 0;
my @linkindex = ();
my @prevlinkindex = ();
$offset = 0;

my ($tsidepad, $psidepad) = ($sidepad, $sidepad);
$tsidepad = "" if $thumbnail_links > $#page_index;
$psidepad = "" if $preview_links > $#imglist;

$preview_links = @imglist if $preview_links > @imglist;
$thumbnail_links = @page_index if $thumbnail_links > @page_index;

my ($mincount, $maxcount) = (($preview_links - 1) / 2, ($preview_links + 1) / 2);
my ($lmincount, $lmaxcount) = (($thumbnail_links - 1) / 2, ($thumbnail_links + 1) / 2);

for(my $pIndex = 1; $pIndex < (@page_index + 1); $pIndex++){
    ## Thumbs
    my $thumblist = "";
    my $linkindexbuf = "";
    my $pIndexEx = $pIndex - 1;
    my ($lsidepad_left, $lsidepad_right) = ("", "");
    my ($lbeg, $lend) = ($pIndexEx - $lmincount, $pIndexEx + $lmaxcount);
    if($lbeg < 1){
	$lbeg = 0;
	$lend = $thumbnail_links;
    }else{
	$lsidepad_left = $tsidepad;
    }
    if($lend > @page_index){
	$lbeg = @page_index - $thumbnail_links;
	$lend = @page_index;
    }else{
	$lsidepad_right = $tsidepad if $lend < @page_index;
    }

    for(my $i = $lbeg; $i < $lend; $i++){
	my $i_human = $i + 1;
	my $thumbpageEx = getPageName($i_human);
	my $current;
	if($i == $pIndexEx){
	    $current = $sub_template{"THUMBLIST_IFSEL"};
	}else{
	    $current = $sub_template{"THUMBLIST"};
	}
	$current =~s/\[NPRETTY_LIST_PAGE\]/$thumbpageEx/gs;
	$current =~s/\[NPRETTY_LIST_NUM\]/$i_human/gs;
	$linkindexbuf .= $current;
    }

    $linkindexbuf = "$lsidepad_left$linkindexbuf$lsidepad_right";
    push(@linkindex, $linkindexbuf);
	
    ## Previews
    for(my $iIndex = 0; $iIndex < $page_index[$pIndex-1]; $iIndex++){
	my ($sidepad_left, $sidepad_right) = ("", "");
	my $prevlistbuf = "";
	my ($beg, $end) = ($offset - $mincount, $offset + $maxcount);
	if($beg < 1){
	    $beg = 0;
	    $end = $preview_links;
	}else{
	    $sidepad_left = $psidepad;
	}
	if($end > @imglist){
	    $beg = @imglist - $preview_links;
	    $end = @imglist;
	}else{
	    $sidepad_right = $psidepad if $end < @imglist;
	}
	for(my $i = $beg; $i < $end; $i++){
	    my $i_human = $i + 1;
	    my $current;
	    if($i == $offset){
		$current = $sub_template{"PREVIEWPREV_LIST_IFSEL"};
	    }else{
		$current= $sub_template{"PREVIEWPREV_LIST"};
	    }
	    $current =~s/\[NPRETTY_PREV_LIST_PAGE\]/$prevpagelist[$i]/gs;
	    $current =~s/\[NPRETTY_PREV_LIST_NUM\]/$i_human/gs;
	    $prevlistbuf .= $current;
	}
	$prevlistbuf = "$sidepad_left$prevlistbuf$sidepad_right";
	push(@prevlinkindex, $prevlistbuf);
	$offset++;
    }
}
undef $offset;
$template{"THUMB"} =~s/\[(NPRETTY_LIST_IFSEL\]).*?\[\/\1//s;
$template{"THUMB"} =~s/\[(NPRETTY_PREV_NOEXIST\]).*?\[\/\1//s;
$template{"THUMB"} =~s/\[(NPRETTY_NEXT_NOEXIST\]).*?\[\/\1//s;
$template{"PREVIEW"} =~s/\[(NPRETTY_LIST_IFSEL\]).*?\[\/\1//s;
$template{"PREVIEW"} =~s/\[(NPRETTY_PREV_IMG_NOEXIST\]).*?\[\/\1//s;
$template{"PREVIEW"} =~s/\[(NPRETTY_NEXT_IMG_NOEXIST\]).*?\[\/\1//s;
$template{"PREVIEW"} =~s/\[(NPRETTY_PREV_LIST_IFSEL\]).*?\[\/\1//s;
$template{"BODY"} =~s/\[(NPRETTY_PAD_DEL\]).*?\[\/\1//s;

print "\n";

my ($body_write_buf, $thumb_write_buf, $preview_write_buf);

$offset = 0;
my $offset_human = $offset + 1;
for(my $pIndex = 0; $pIndex < @page_index; $pIndex++){
    my $pIndex_human = $pIndex + 1;
    printf("Page %3d, %3d files:\n", $pIndex_human, $page_index[$pIndex]);

    my $thumbpage = getPageName($pIndex_human);
    
    $body_write_buf = "";
    $thumb_write_buf	= $template{"THUMB"};
    # Add list index
    $thumb_write_buf =~s/\[(NPRETTY_LIST\]).*?\[\/\1/$linkindex[$pIndex]/s;

    # Add previous/next page
    my %subtemplate_tag = (
	'[NPRETTY_PREV_PAGE]'		=> getPageName($pIndex_human - 1),
	'[NPRETTY_NEXT_PAGE]'		=> getPageName($pIndex_human + 1),
	'[NPRETTY_PREV_PAGE_NUM]'	=> ($pIndex_human - 1),
	'[NPRETTY_NEXT_PAGE_NUM]'	=> ($pIndex_human + 1));
    my ($ppagebuf, $npagebuf);
    if($pIndex == 0){
	$ppagebuf = $sub_template{"THUMBPREV_NOEXIST"};
    }else{
	$ppagebuf = $sub_template{"THUMBPREV_EXIST"};
    }
    if($pIndex == $#page_index){
	$npagebuf = $sub_template{"THUMBNEXT_NOEXIST"};
    }else{
	$npagebuf = $sub_template{"THUMBNEXT_EXIST"};
    }
    $ppagebuf = replaceTags($ppagebuf, %subtemplate_tag);
    $npagebuf = replaceTags($npagebuf, %subtemplate_tag);

    $thumb_write_buf =~s/\[NPRETTY_PREV_EXIST\].*?\[\/NPRETTY_PREV_EXIST\]/$ppagebuf/s;
    $thumb_write_buf =~s/\[NPRETTY_NEXT_EXIST\].*?\[\/NPRETTY_NEXT_EXIST\]/$npagebuf/s;
    
    #Title if it exists
    if("$title" ne ""){
	$thumb_write_buf =~s/\[(NPRETTY_TITLE_EXIST\])(.*?)\[\/\1/$2/gs;
	$thumb_write_buf =~s/\[(NPRETTY_TITLE_NOEXIST\]).*?\[\/\1//gs;
    }else{
	$thumb_write_buf =~s/\[(NPRETTY_TITLE_NOEXIST\])(.*?)\[\/\1/$2/gs;
	$thumb_write_buf =~s/\[(NPRETTY_TITLE_EXIST\])(.*?)\[\/\1//gs;
    }

    for(my $iIndex = 0; $iIndex < $page_index[$pIndex]; $iIndex++){
	my $iIndex_human = $iIndex + 1;
	my $image = $imglist[$offset];
	
        printf("%3d \"%s\"\n", $offset + 1, $image);
	# Get EXIF
	my $EXIF_info = ImageInfo("$filelist[$offset]");
	setPreviewDimensions($EXIF_info, $offset, "$filelist[$offset]"); # FIXME might be moved later
	#print " (preview $preview_dimension[$offset])\n";

	my $line_buffer		= $template{"BODY"};
	$preview_write_buf	= $template{"PREVIEW"}; 
    
	#Title if it exists
	if("$title" ne ""){
	    $preview_write_buf =~s/\[(NPRETTY_TITLE_EXIST\])(.*?)\[\/\1/$2/gs;
	    $preview_write_buf =~s/\[(NPRETTY_TITLE_NOEXIST\]).*?\[\/\1//gs;
	}else{
	    $preview_write_buf =~s/\[(NPRETTY_TITLE_NOEXIST\])(.*?)\[\/\1/$2/gs;
	    $preview_write_buf =~s/\[(NPRETTY_TITLE_EXIST\]).*?\[\/\1//gs;
	}

	# Add preview ist index
	$preview_write_buf =~s/\[NPRETTY_PREV_LIST\].*?\[\/NPRETTY_PREV_LIST\]/$prevlinkindex[$offset]/s;
    
	# Add previous/next preview page
	my %preview_tag;
	my ($pprevbuf, $nprevbuf);
	if($offset == 0){
	    $pprevbuf = $sub_template{"PREVIEWPREV_IMG_NOEXIST"};
	    $preview_tag{'[NPRETTY_PREV_IMG]'} 		= "";
	    $preview_tag{'[NPRETTY_PREV_IMG_NAME]'} 	= "";
	}else{
	    $pprevbuf = $sub_template{"PREVIEWPREV_IMG_EXIST"};
	    $preview_tag{'[NPRETTY_PREV_IMG]'} 		= $prevpagelist[$offset - 1];
	    $preview_tag{'[NPRETTY_PREV_IMG_NAME]'} 	= $imglist[$offset - 1];
	}
	if($offset == $#imglist){
	    $nprevbuf = $sub_template{"PREVIEWNEXT_IMG_NOEXIST"};
	    $preview_tag{'[NPRETTY_NEXT_IMG]'}		= "";
	    $preview_tag{'[NPRETTY_NEXT_IMG_NAME]'}	= "";
	}else{
	    $nprevbuf = $sub_template{"PREVIEWNEXT_IMG_EXIST"};
	    $preview_tag{'[NPRETTY_NEXT_IMG]'}		= $prevpagelist[$offset + 1];
	    $preview_tag{'[NPRETTY_NEXT_IMG_NAME]'} 	= $imglist[$offset + 1];
	}
	$pprevbuf = replaceTags($pprevbuf, %preview_tag);
	$nprevbuf = replaceTags($nprevbuf, %preview_tag);

	$preview_write_buf =~s/\[(NPRETTY_PREV_IMG_EXIST\]).*?\[\/\1/$pprevbuf/s;
	$preview_write_buf =~s/\[(NPRETTY_NEXT_IMG_EXIST\]).*?\[\/\1/$nprevbuf/s;

	my $comment = "";
	$comment = $commenthash{$filelist[$offset]} if $comments;
	
	# Insert EXIF data
	$line_buffer = replaceExifTags($line_buffer, $EXIF_info);
	$preview_write_buf = replaceExifTags($preview_write_buf, $EXIF_info);

	my %template_tag =(	    
	    '[NPRETTY_SIZE]'		=> sprintf("%1.1fKiB", filesize("$filelist[$offset]") / 1024),
	    '[NPRETTY_FILENAME]'	=> $image,
	    '[NPRETTY_INDEX_NUM]'	=> $offset_human,
	    '[NPRETTY_PAGE]'		=> $thumbpage,
	    '[NPRETTY_THUMB]'		=> "$abs_thumb_dest/$thumblist[$offset]",
	    '[NPRETTY_PREVIEW]'		=> "$abs_prevpage_dest/$abs_preview_dest/$prevlist[$offset]",
	    '[NPRETTY_PREVIEW_PAGE]'	=> "$abs_prevpage_dest/$prevpagelist[$offset]",
	    '[NPRETTY_IMAGE]'		=> "$abs_img_dest/$image",
	    '[NPRETTY_COMMENT]'		=> $comment);

	if($comments && "$comment" ne ""){
	    $preview_write_buf =~s/\[(NPRETTY_COMMENT_EXIST\]).*?\[\/\1/$sub_template{"PREVIEWCOMMENT_EXIST"}/s;
	}else{
	    $preview_write_buf =~s/\[(NPRETTY_COMMENT_EXIST\]).*?\[\/\1//s;
	}

    	$line_buffer = replaceTags($line_buffer, %template_tag);
	$template_tag{"[NPRETTY_PAGE]"}		= "../$thumbpage";
	$template_tag{"[NPRETTY_THUMB]"}	= "../$thumblist[$offset]";
	$template_tag{"[NPRETTY_PREVIEW]"}	= "../$abs_preview_dest/$prevlist[$offset]";
	$template_tag{"[NPRETTY_IMAGE]"}	= "../$abs_img_dest/$image";
	$preview_write_buf = replaceTags($preview_write_buf, %template_tag);

	# Write preview page
	save("$prevpage_dest/$prevpagelist[$offset]", "$NTAG$preview_write_buf");
	$body_write_buf .= $line_buffer;
	$body_write_buf .= $img_delimiter if $delimiter && ($iIndex + 1) != $page_index[$pIndex] && (($iIndex + 1) % $img_delimiter_rep) == 0;
        
	$offset++;
	$offset_human = $offset + 1;

	# Pad remaining blocks if endcount of thumbs is uneven
	if($delimiter && $iIndex == $page_index[$pIndex]-1){
	    my $remaining = $img_delimiter_rep - ($iIndex + 1) % $img_delimiter_rep;
	    unless($remaining == $img_delimiter_rep){
		for($i = 0; $i < $remaining; $i++){
		    $body_write_buf .= $delimiter_padding;
		}
	    }
	}

    }
    $thumb_write_buf=~s/\[NPRETTY_BODY\]/$body_write_buf/g;

   # Write thumbnail page
    print "-> $thumbpage\n";
    save("$dest/$thumbpage", "$NTAG$thumb_write_buf");
    print "\n";
}

undef $body_write_buf;
undef $thumb_write_buf;
undef $preview_write_buf;

## --skip-images? If so, we're all done.
if($generation_mode == 2){
    print "Images skipped.\nDone.\n";
    exit 0;
}

GENERATION:
if($generation_mode == 1){
    # We missed dimension info when we skipped pages
    for($offset = 0; $offset < @filelist; $offset++){
	my $EXIF_info = ImageInfo("$filelist[$offset]");
	setPreviewDimensions($EXIF_info, $offset, "$filelist[$offset]");
    }
}

# We don't need images any more, delete them if requested.
if($delete_originals){
    print "Deleting original images.\n\n";
    foreach(@filelist){
	system("rm \"$_\"");
    }
}

## Main loop should begin somewhere around here.

## Argument setup for external programs
my ($thumb_conv_args, $pre_conv_args, $video_conv_args);

$thumb_conv_args = "$thumb_dimensions";
$thumb_conv_args .= "!" unless $thumb_keep_aspect;
    
$pre_conv_args = "-exonly -se ";
$pre_conv_args .= "-dt " if $pre_remove_cthumbs;
$pre_conv_args .= "-autorot " if $pre_auto_rotate;

#$video_conv_args = "-really-quiet -nosound -vo jpeg -frames 1";
$video_conv_args = "-really-quiet -nosound -vo gif89a:5.0:$img_dest/tmpvid.gif -frames 50";

## Initialisation and running of threads

my $PROGRESS = 1;
my $PROGRESS_MAX = @imglist;

# Video conversion

if($use_vidconverter){
    print "Converting video frames to images.\n\n";
    my $videos = 0;
    for(my $i = 0; $i < @imglist; $i++){
	next unless("$progmap[$i]" eq "vid");
	next unless $work{$imglist[$i]};
	printf("%03d vid->img $img_dest/$imglist[$i]\n", $i);
	if(system("$vid_converter $video_conv_args \"$img_dest/$imglist[$i]\" > /dev/null 2>&1") == 0){
	    substr($imglist[$i], rindex($imglist[$i], "."), length($imglist[$i]), ".gif");
	    rename("$img_dest/tmpvid.gif", "$img_dest/$imglist[$i]");
	}else{
	    substr($imglist[$i], rindex($imglist[$i], "."), length($imglist[$i]), ".gif");
	    print "WARN: conversion failed!\n";
	    system("cp \"$no_video_image\" \"$img_dest/$imglist[$i]\"");
	}
	unless(-e "$img_dest/$imglist[$i]"){
	    print "WARN: conversion failed!\n";
	    system("cp \"$no_video_image\" \"$img_dest/$imglist[$i]\"");
	}
	$videos++;
    }
    print "No videos to convert!\n" if $videos == 0;
}else{
    my $videos = 0;
    for(my $i = 0; $i < @imglist; $i++){
	next unless("$progmap[$i]" eq "vid");
	printf("%03d missing video image ..\n", $i);
	substr($imglist[$i], rindex($imglist[$i], "."), length($imglist[$i]), ".gif");
	system("cp \"$no_video_image\" \"$img_dest/$imglist[$i]\"");
	$videos++;
    }
    print "No videos to convert!\n" if $videos == 0;
		    
}

#Set max number of threads to run
$jobs = @imglist if $jobs > @imglist;

$finishedthreads = 0;
if($use_preprocessor){
    print "\nPreprocessing.\n\n";
    while($finishedthreads < @imglist){
	if(threads->list() < $jobs){
	    my $cjob = "$pre_processor $pre_conv_args \"$img_dest/$imglist[$finishedthreads]\"";
	    if($work{$imglist[$finishedthreads]}){
		init_sys_thread("$cjob", "") if $work{$imglist[$finishedthreads]};
	    }else{
		print  "\"$img_dest/$imglist[$finishedthreads]\", skipped\n";
	    }
	    $finishedthreads++;
	}
    }
    while(threads->list() != 0){};
}

$SIG{CHLD} = 'IGNORE';

my $workfile;
# Previews
print "\nGenerating previews.\n\n";
$finishedthreads = 0;
while($finishedthreads < @imglist){
    if(threads->list() < $jobs){
	my $workfile = "$preview_dest/$prevlist[$finishedthreads]"; # . shift(@prevlist);
	my $prev_conv_args = "$preview_dimension[$finishedthreads]";
	$prev_conv_args .= "!" unless $preview_keep_aspect;
	my @cjob = ("$img_dest/$imglist[$finishedthreads]", "$prev_conv_args", "$workfile");
	my $output = sprintf("[%03d/%03d] %s", $PROGRESS, $PROGRESS_MAX, $workfile);
	if($work{$prevlist[$finishedthreads]}){
	    init_thread("$output\n", @cjob);
	}else{
	    print "$output, skipped (already exists)\n";
	}

        $finishedthreads++;
	$PROGRESS++;
    }
}
while(threads->list() != 0){};


# Thumbnails
print "\nGenerating thumbnails.\n\n";
$finishedthreads = 0;
$PROGRESS = 1;
while($finishedthreads < @imglist){
    if(threads->list() < $jobs){
	$workfile = "$thumb_dest/$thumblist[$finishedthreads]"; #. shift(@thumblist);
	my @cjob = ("$preview_dest/$prevlist[$finishedthreads]", "$thumb_conv_args", "$workfile");
	my $output = sprintf("[%03d/%03d] %s", $PROGRESS, $PROGRESS_MAX, $workfile);
	if($work{$thumblist[$finishedthreads]}){
	    init_thread("$output\n", @cjob);
	}else{
	    print "$output, skipped (already exists)\n";
	}
        $finishedthreads++;
	$PROGRESS++;
    }
}
while(threads->list() != 0){};


$SIG{CHLD} = 'DEFAULT'; 
print "\nDone.\n";
