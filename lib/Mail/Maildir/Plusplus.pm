#!/usr/bin/perl -w

#########################################################################################################
# Don't use me directly.  Use Mail::Maildir.  Seriously.  I'm not kidding.
#########################################################################################################

use strict;
package Mail::Maildir::Plusplus;

require Exporter;
use Sys::Hostname;
use File::Temp qw/tempfile/;
use File::Copy;
use File::Path;
use FileHandle;
use IO::Handle qw(flush);
use Mail::Maildir;

use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA $VERSION);
$VERSION = "1.00";

@ISA = ("Mail::Maildir");

@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ( all => [qw()]);

my $DEFAULT_QUOTA_BYTES = 10000000; # ~ 10 MB
my $DEFAULT_QUOTA_MESGS = 1000;

my $hostname = hostname();
$hostname =~ s|/|\\057|g;
$hostname =~ s|:|\\072|g;

sub __new 
{
    my ($class, $maildirobj) = @_;
    $class = ref($class) || $class;       # inheritable, callable as object method
    bless $maildirobj, $class;            # inheritable, bless into the right package
    #warn "*********** Plusplus: returning newly blessed object\n";
    return $maildirobj;
}

sub create
{
    my ($path, $quotabytes, $quotamessages) = @_;
    return &createPlusplus($path, $quotabytes, $quotamessages);
}

sub open
{
    my ($path) = @_;
    my $mailObj = Mail::Maildir->open($path);
    if ($mailObj->isPlusplusMaildir())
    {
	return $mailObj;
    }
    else
    {
	return undef;
    }
}

sub createFolder
{
    my ($self, $folder) = @_;
    my $retval = 0;
    if (($folder =~ m/^\./) || (!$self->{"isplusplus"}))
    {
	$self->warnLog("Maildir++ folder names must be specified without a leading dot (we take care of that) " . 
	    "and must be created in a maildir++; creation and context change failed");
    }
    else
    {
	my $nfolder = $self->{"folder"} . "." . $folder;
	if (-e $self->{"directory"} . "/" . $nfolder)
	{
	    $self->warnLog("createFolder called for folder $nfolder, but it already exists; neither creating nor " . 
		"switching contexts");
	}
	else
	{
	    my $success = $self->createMaildir($nfolder);
	    if ($success)
	    {
		$self->{"folder"} = $nfolder;	    
		$retval = 1;
	    }
	    else
	    {
		$self->warnLog("createMaildir failed, folder not created, context not changed");
	    }
	}
    }

    return $retval;
}

sub createPlusplus
{
    my ($path, $quotabytes, $quotamessages) = @_;
    my $success = 0;

    my $maildirObj = Mail::Maildir::create($path);
    if ($maildirObj && ($maildirObj->isValidMaildir()))
    {
	if ($maildirObj->{"isplusplus"})
	{
	    $maildirObj = Mail::Maildir::Plusplus->__new($maildirObj);
	}
	else
	{
	    $success = $maildirObj->upgradeToPlusplus($quotabytes, $quotamessages);
	    if ($success)
	    {
		$maildirObj = Mail::Maildir::Plusplus->__new($maildirObj);		
	    }
	    else
	    {
		undef($maildirObj);
	    }
	}
    }

    return $maildirObj;
}

sub setFolder
{
    my ($self, $folder) = @_;
    if (($folder =~ m/^\./) || (!$self->{"isplusplus"}))
    {
	$self->warnLog("Maildir++ folder names must be specified without a leading dot (we take care of that) " . 
	    "and must be set in a valid maildir++; context change failed");
    }
    else
    {
	my $nfolder = $self->{"folder"} . "." . $folder;
	if (!-e $self->{"directory"} . "/" . $nfolder)
	{
	    $self->warnLog("setFolder called for folder $nfolder, but it doesn't exist; not switching contexts");
	    return 0;
	}
	$self->{"folder"} = $nfolder;
	return 1;
    }
    return 0;
}

sub listFolders
{
    my ($self) = @_;
    my $home = $self->{"directory"};
    my @newdirs = glob($home . "/.*");
    my @dirs = ();
    foreach my $path (@newdirs)
    {
        my ($pathstripped) = ($path =~ m|.*/([^/]+)$|);
	if (!$pathstripped) { $pathstripped = $path; };
	##$self->warnLog("PATHSTRIPPED $pathstripped PATH $path");
        next if ($pathstripped eq '..');
        next if ($pathstripped eq '.');
        next if (!-d $path);
        next if ($pathstripped eq '.Trash');
        next if (!-e ($path . "/maildirfolder"));
        next if (!-e ($path . "/new"));
        next if (!-e ($path . "/cur"));
	push @dirs, "$pathstripped";
    }
    return \@dirs;
}

sub setQuota
{
    my ($self, $quotabytes, $quotamessages) = @_;
    $self->{"quotabytes"} = $quotabytes;
    $self->{"quotamessages"} = $quotamessages;
    
    # commit new maildirsize file
    $self->calculateMaildirsize();
}

#######################################################################
#
# Maildirsize stuff
#
#######################################################################

sub loadMaildirsize
{
    my ($self) = @_;
    if (!$self->{"isvalid"} || !$self->{"isplusplus"})
    {
	$self->warnLog("Attempted to call loadMaildirsize from a non Maildir++ object");
    }
    else
    {
	my $mdsFile = $self->{"directory"} . "/maildirsize";
	my $lfh = new FileHandle;
	$lfh->open("<" . $mdsFile) or 
	    $self->warnLog("Failed to open maildirsize for reading in " . $self->{"directory"} .
			   ".  ($!)");
	
	my $firstline = 1;
	my $parsefail = 0;
	my $bytesfail = 0;
	my $countfail = 0;
	my $nummessages = 0;
	my $numbytes = 0;
	while (<$lfh>)
	{
	    chomp $_;
	    if ($firstline)
	    {
		$firstline = 0;
		my ($bytes, $messages) = split(/\,/, $_);
		#*$self->warnLog("B: $bytes/M: $messages");
		if ($bytes =~ m/S/i)
		{
		    $bytes =~ s/S//;
		    if (!$bytes)
		    {
			$self->warnLog($self->{"directory"} . "/maildirsize had nothing for bytes, malformed");
			$bytesfail = 1;
			if ($countfail) { $parsefail = 1; }
		    }
		    else
		    {
			$self->{"quotabytes"} = $bytes;
		    }
		}
		else
		{
		    $self->warnLog($self->{"directory"} . "/maildirsize was malformed (bytes: $bytes (messages: $messages))");
		    $countfail = 1;
		    if ($bytesfail) { $parsefail = 1; }
		}
		if ($messages =~ m/C/i)
		{
		    $messages =~ s/C//;
		    if (!$messages)
		    {
			$self->warnLog($self->{"directory"} . "/maildirsize had nothing for messages, malformed");
			$parsefail = 1;
		    }
		    else
		    {
			$self->{"quotamessages"} = $messages;
		    }
		}
		else
		{
		    $self->warnLog($self->{"directory"} . "/maildirsize was malformed (messages: $messages (bytes: $bytes))");
		    $parsefail = 1;
		}
	    } # if firstline
	    elsif (!$parsefail)
	    {
		my ($lbyt, $lmes) = ($_ =~ m/^\s*(\d+)\s+(\d+)\s*$/);
		if (($lbyt !~ m/\d+/) || ($lmes !~ m/\d+/))
		{
		    $self->warnLog($self->{"directory"} . "/maildirsize had an invalid bytes line ($_).  Processing stopped.");
		    $parsefail = 1;
		}
		else
		{
		    $self->{"usedbytes"} += $lbyt;
		    $self->{"usedmessages"} += $lmes;
		}
	    } # else not firstline, and not parsefail
	} # while <$lfh>
	$lfh->close();
    } # else is valid and is plusplus
}

sub writeDefaultMaildirsize
{
    my ($self) = @_;  
    my $filewrite = $self->{"directory"} . "/maildirsize";
    my $retval = 0;

    # won't clobber; use setQuota for clobber
    if (-e $filewrite)
    {
	$self->warnLog("writeDefaultMaildirsize will not clobber existing maildirsize files; use setQuota in this case");
    }
    else
    {
	my $lfh = new FileHandle;
	$lfh->open(">" . $filewrite) or $self->warnLog("writeDefaultMaildirsize failed to write $filewrite ($!)");
	print $lfh "${DEFAULT_QUOTA_BYTES}S,${DEFAULT_QUOTA_MESGS}C\n0 0\n";
	$lfh->close;
	chmod 0700, $filewrite;
	if (-e $filewrite) { $retval = 1; }
    }

    return $retval;
}

sub calculateMaildirsize
{
    # this calculate function is rigid in the following way: it completely ignores invalid maildirs
    # the function is rather loose in the following way: it does not enforce the mail file name standard of maildir,
    # and includes even oddly named files in the usage calculation
    my ($self) = @_; 

    my $quotabytes = $self->{"quotabytes"};
    my $quotamessages = $self->{"quotamessages"};

    # build directory checklist:
    my @dirs = ("new", "cur");

    my $home = $self->{"directory"};
    my @newdirs = glob($home . "/.*");
    foreach my $path (@newdirs)
    {
	my ($pathstripped) = ($path =~ m|.*/([^/]+)$|);
	if (!$pathstripped) { $pathstripped = $path; }
	next if ($pathstripped eq '..');
	next if ($pathstripped eq '.');
	next if (!-d $path);
	next if ($pathstripped eq '.Trash');
	next if (!-e ($path . "/maildirfolder"));
	next if (!-e ($path . "/new"));
	next if (!-e ($path . "/cur"));
	push @dirs, "$pathstripped/new";	
	push @dirs, "$pathstripped/cur";
    }

    my $lasttime = 0;
    my $bytes = 0;
    my $messages = 0;
    foreach my $search (@dirs)
    {
	my $fullsearch = $self->{"directory"} . "/" . $search;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($fullsearch);
	if ($ctime > $lasttime) { $lasttime = $ctime; }
	my @tmplist = glob($fullsearch . "/*");
	foreach my $tmpfile (@tmplist)
	{
	    if (($tmpfile =~ m/S=(\d+)$/) || ($tmpfile =~ m/S=(\d+):/))
	    {
		$bytes += $1;
	    }
	    else
	    {
		my ($tdev,$tino,$tmode,$tnlink,$tuid,$tgid,$trdev,$tsize,$tatime,$tmtime,$tctime,$tblksize,$tblocks) 
		    = stat($tmpfile);
		$bytes += $tsize;
	    }
	    $messages++;
	}
    }

    # write the tmp maildirsize file:
    my $lfh = new FileHandle;
    $lfh->open(">" . $home . "/tmp/maildirsize") or 
	((($bytes = -1) == -1) || 
	 (($messages = -1) == -1) && 
	 $self->warnLog("caluculateMaildirsize failed opening $home/tmp/maildirsize for write ($!); failing"));
    print $lfh "${quotabytes}S,${quotamessages}C\n${bytes} ${messages}\n";
    $lfh->close;
    chmod 0700, $home . "/tmp/maildirsize";
    
    # move to home/maildir
    unlink($home . "/maildirsize");
    my $success = move($home . "/tmp/maildirsize", $home . "/maildirsize");

    if (!$success)
    {
	$self->warnLog("calculateMaildirsize failed to move maildirsize to its proper home ($!); failing");
	$bytes = -1;
	$messages = -1;
    }

    # spec requires us to now stat the subdirs again, and if stamp changed, remove maildirsize:
    foreach my $newsearch (@dirs)
    {
	my $fullsearch = $self->{"directory"} . "/" . $newsearch;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($fullsearch);
	if ($ctime > $lasttime) 
	{ 
	    unlink($home . "/maildirsize");
	    $self->warnLog("calculateMaildirsize hit condition where timestamps changed after calc; removing maildirsize");
	    last;
	}
    }

    # spec asks us to return the info we gathered even if it's a little out of date
    $self->{"usedbytes"} = $bytes;
    $self->{"usedmessages"} = $messages;
    return ($bytes, $messages);
}

1;

__END__

