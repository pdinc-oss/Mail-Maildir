#!/usr/bin/perl -w
##!/usr/bin/perl -wT

#########################################################################################################
#
# This program implements many of the common features of creating, managing, removing, and so on of 
# Maildir and Maildir++ directories and files.  Reference:
#
#   http://cr.yp.to/proto/maildir.html
#   http://www.inter7.com/courierimap/README.maildirquota.html
#
# Usage:
#   my $maildirObj = new Mail::Maildir("/path/to/somewhere");          # path should *be* the maildir (i.e. 
#                                                                      # /path/Maildir, and not, /path, which HAS a 
#                                                                      # Maildir).  Runs open() if path is a maildir,
#                                                                      # will not automatically create; use create() 
#                                                                      # instead of new() if that's what you want
#   my $maildirObj = Mail::Maildir::Plusplus::open(PATH); 
#   my $maildirObj = Mail::Maildir::open(PATH); 
#   my $maildirObj = Mail::Maildir->open(PATH); 
#   my $maildirObj = open Mail::Maildir(PATH);                         # opens an existing Maildir, returns
#                                                                      # undef if it isn't a Maildir
#   my $maildirObj = Mail::Maildir::Plusplus::create(PATH, quotabytes, quotamessages); 
#   my $maildirObj = Mail::Maildir->create(PATH); 
#   my $maildirObj = Mail::Maildir::create(PATH); 
#   my $maildirObj = create Mail::Maildir(PATH);                       # creates a Maildir; returns maildirObj ref
#                                                                      # if one exists there; returns undef on failure
#                                                                      # NOTE: The Maildir will be created right in
#                                                                      # PATH, as PATH/new, PATH/cur etc.  Use this
#                                                                      # method to create Maildirs whose base paths
#                                                                      # are not .../Maildir/.  Note also that you 
#                                                                      # can shoot yourself in the foot here, by 
#                                                                      # creating a Maildir in a directory that has
#                                                                      # existing files disallowed in a Maildir/++
#   my $success = $maildirObj->warnLogAt(filestring);                  # say where you want the log to be, 0 or 1
#   my $success = $maildirObj->enableWarnLog();                        # 0 or 1, default log location /tmp/maildir.log
#   my $ret = $maildirObj->createMaildir($optfolder);                  # make one (i.e., ./Maildir/, etc), (not ++), 
#                                                                      # 0 (failed) or 1 (made); note: after create,
#                                                                      # the path is automatically adjusted to 
#                                                                      # path/Maildir (hopefully for convenience)
#                                                                      # if optfolder is specified, puts folder in 
#                                                                      # self->directory and does not make any changes
#                                                                      # FOLDER CONTEXT IS IGNORED (logic for this in
#                                                                      # createfolder, where it belongs; here is just
#                                                                      # a blind, deaf and dumb maildir maker)
#   my $ret = $maildirObj->delete();                                   # if maildirObj is a valid maildir, this
#                                                                      # entirely removes everything, including the
#                                                                      # base directory (Maildir); if used in a folder
#                                                                      # context, just the folder; 0 or 1
#   my $ret = $maildirObj->isValidMaildir();                           # is this already a maildir? 0 or 1
#   my $ret = $maildirObj->isPlusplusMaildir();                        # is this already a maildir++? 0 or 1
#   my $ret = $maildirObj->upgradeToPlusplus(quotabytes, quotamsg);    # if x is a maildir but not plusplus, this
#                                                                      # will create a properly formatted quota file
#                                                                      # with quota $quota, and a Trash folder, 
#                                                                      # properly ++ formatted; 0 or 1
#   my $ret = $maildirObj->setFolder(foldername);                      # note: the current folder context is used; so
#                                                                      # you can change to subfolders using this;  
#                                                                      # if isPlusplus, sets the current context
#                                                                      # to foldername, "" for return to root; 0 or 1
#   my $ret = $maildirObj->createFolder(foldername);                   # note: the current folder context is used; so
#                                                                      # if you are in dir D and folder F, a new folder
#                                                                      # N will be F.N, the dot convention for sub-
#                                                                      # folders; if isPlusplus, creates a 
#                                                                      # folder as a maildir; 0 or 1
#   my ($n, $fh) = $maildirObj->createNamedTmpMessage();
#   my ($n, $fh) = $maildirObj->createNamedTmpMessage(filenameString); # put a message in tmp with the contents of file
#                                                                      # (optional); returns an empty array (failed) 
#                                                                      # or $messagename (valid
#                                                                      # Maildir message name created) and an OPEN+w
#                                                                      # filehandle to the message file created
#   my $ret = $maildirObj->moveTmpToNew($messagename);                 # moves from tmp to new, 0 or 1
#   my $messagename = $maildirObj->moveNewToCur($messagename);         # moves from new to cur, returns new message 
#                                                                      # name, sets P flag
#   my $ret = $maildirObj->trashMessage($messagename, $actuallyremove);# trashes a message from cur; respects 
#                                                                      # Maildir++ trashing convention if isPlusplus,
#                                                                      # creating .Trash if necessary
#                                                                      # FOLDER context respected; messagename or 1
#   my $ret = $maildirObj->getQuotaBytes();                            # returns the quota for this account, -1 on err
#   my $ret = $maildirObj->getQuotaMessages();                         # returns the quota for this account in 
#                                                                      # messages, -1 on err
#   my $ret = $maildirObj->dirExists();                                # returns 0 or 1
#   my $ret = $maildirObj->isInsecure();                               # returns 0 or 1
#   my ($byte, $message) = $maildirObj->getMaildirUsage();             # returns the usage information (bytes, 
#                                                                      # messages) deduced from the Maildir++ quota 
#                                                                      # file, -1, -1 if not ++
#   my $ret = $maildir->setQuota(bytes, messages);                     # sets the quota -- if an argument is set to
#                                                                      # '', will use the existing value; 0 or 1
#   my ($bytes, $messages) = $self->calculateMaildirsize();            # follows maildir++ procedure for calculating
#                                                                      # usage, and rewriting maildirsize
#   my ($arrayref) = $self->listFolders();                             # an array reference listing all the Maildir++
#                                                                      # folders.  Note: is independent of context, so
#                                                                      # will return a list of names that start with
#                                                                      # '.' and may have more '.'s in them.
#   my ($arrayref) = $self->listMessages();                            # see the POD for details
#
# Internal API:
#   my $ret = $self->determineMaildirValidity($optdir);                # 0 for false, 1 for maildir, 2 for maildir++
#   my $ret = $self->loadMaildirsize();                                # parse and set usage values from maildirsize
#   my $ret = $self->writeDefaultMaildirsize();                        # writes a default maildirsize file
#
#########################################################################################################

use strict;
package Mail::Maildir;

require Exporter;
use Sys::Hostname;
use File::Temp qw/tempfile/;
use File::Copy;
use File::Path;
use FileHandle;
use IO::Handle qw(flush);
use Mail::Maildir::Plusplus;

use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA $VERSION);
$VERSION = "1.00";

@ISA = ();

@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ( all => [qw()]);

my $MAILDIRNAME = "Maildir";
my @FILES_ALLOWED_IN_MAILDIR = qw(new cur tmp .qmail bulletintime bulletinlock seriallock maildirsize maildirfolder);
my %INFO_CODES = (
		  1 => "Experimental semantics",
		  2 => "Uses INFO_FLAGS",
		  );
my %INFO_FLAGS = (
		  P => "passed",
		  R => "replied",
		  S => "seen",
		  T => "trashed",
		  D => "draft",
		  F => "flagged",
		  );
# for creating, not verifying: (verifying is =~ m|^([^\.:/]+)(\.)([^\.:/]+)(\.)([^:/]+)(:[12]\,[PRSTDF]+)?$|)
my $MESSAGENAME_FORMAT = "time(seconds_since_epoch).pid_time(millisecs_since_epoch)_inode.[hostname()],S=[bytesize]";
my $DEFAULT_QUOTA_BYTES = 10000000; # ~ 10 MB
my $DEFAULT_QUOTA_MESGS = 1000;
my $ABS_PATH = "///"; # a signal to createMaildir that the path of the underlying maildirObj can be treated as absolute
                      # i.e. create Maildir on $self->{"directory"} directly, not as dir/Maildir
my $hostname = hostname();
$hostname =~ s|/|\\057|g;
$hostname =~ s|:|\\072|g;

sub new 
{
    my %SELF_STRUCT = (
		       directory => '',
		       folder => '',
		       exists => 0,
		       insecure => 0,
		       isvalid => 0,
		       isplusplus => 0,
		       usedbytes => 0,    # calculated from maildirsize
		       usedmessages => 0, # calculated from maildirsize
		       quotabytes => 0,
		       quotamessages => 0,
		       warnlog => '/tmp/maildir.log',
		       warnlogenabled => 0,
		       );
    my ($class, $directory) = @_;
    $class = ref($class) || $class; # inheritable, callable as object method
    my $self = { %SELF_STRUCT };
    bless $self, $class;            # inheritable, bless into the right package

    if ($directory =~ m/[\`\|\:\\]+/)
    {
	$directory =~ s/[\`\|\:\\]+//g;
	$self->{"insecure"} = 1;
    }

    $self->{"directory"} = $directory;

    if (-e $directory)
    {
	$self->{"exists"} = 1;
	my $ret = $self->determineMaildirValidity();
	#warn "************** determineMaildirValidity: $ret\n";
	if ($ret)
	{
	    $self->{"isvalid"} = 1;
	    if ($ret == 2) 
	    { 
		$self->{"isplusplus"} = 1; 
		$self = Mail::Maildir::Plusplus->__new($self);
		my $success = $self->loadMaildirsize();
	    }
	}
	#else
	#{
	#    # make one
	#    $self->createMaildir();
	#}
    }

    return $self;
}

sub open
{
    my ($self, $path) = @_;
    if (!ref($self))
    {
	$path = $self; # self is the path, here  
    }

    my $mailObj = new Mail::Maildir($path);
    
    if ($mailObj->isValidMaildir())
    {
	#warn "*** returning $path and $self\n";
	return $mailObj;
    }
    else
    {
	return undef;
    }
}

sub create
{
    my ($self, $path) = @_;
    my $success = 0;

    if (!ref($self))
    {
	$path = $self; # self is the path, here
    }

    my $mailObj = new Mail::Maildir($path); 

    if ($mailObj->isValidMaildir())
    {
	$success = 1;
    }
    else
    {
	# instantiated on an existing directory; permit creation.  NOTE: if there were other files in this
	# directory, the result might be a non-valid Maildir/++	
	$mailObj->{"exists"} = 1;
	$success = $mailObj->createMaildir($ABS_PATH);	    
    }
    
    $success ? (return $mailObj) : (return undef);
}

sub determineMaildirValidity
{
    # if a $dir argument, this is a test; if not, this is an initialize condition (from new())
    my ($self, $dir) = @_;
    my $returnval = 1;
    my $newtmpcur = 0;
    my $isplusplus = 0;

    # x is a valid maildir iff:
    #   1) x has a new, tmp and cur directory
    #   2) the files and directories in x are either in the allowed file list, or start with the character '.'

    # x is a valid maildir++ iff:
    #   1) x is a valid maildir, except that x may and must also have a file maildirsize
    #   2) any directory in x that starts with '.' may be a valid maildir, with the exception that maildirfolder file
    #      is allowed and required for it to be recognized as a maildir

    my $odir = ($dir ? $dir : $self->{"directory"});
    my $tmp1 = $odir . "/*";
    my $tmp2 = $odir . "/.*";
    my @fileshere = glob("$tmp1 $tmp2");
    foreach my $filehere (@fileshere)
    {
	my ($sfilehere) = ($filehere =~ m|.*/([^/]+)$|);
	next if ($sfilehere eq '.');
	next if ($sfilehere eq '..');

	if (0) { $self->warnLog("checking $sfilehere"); }

	if (($sfilehere eq "cur") || ($sfilehere eq "new") || ($sfilehere eq "tmp"))
	{
	    $newtmpcur++;
	}
	elsif ($sfilehere =~ m/^\./)
	{
	    if (-d $filehere)
	    {
		# maildir++ possibly
		if ((-e ($odir . "/maildirsize")) && ((-e ($filehere . "/maildirfolder")) || 
						      ($filehere =~ m/.Trash$/)))
		{
		    if (($self->determineMaildirValidity($filehere)) || ($filehere =~ m/.Trash$/))
		    {
			$isplusplus = 1;
		    }
		}
	    }
	}
	else
	{
	    # has to be in valid file list, or else, we fail this out
	    my $tmpmatch = 0;
	    foreach my $validfile (@FILES_ALLOWED_IN_MAILDIR)
	    {
		if ($sfilehere eq $validfile) { $tmpmatch = 1; }
	    }
	    if ($tmpmatch == 0)
	    {
		$returnval = 0;
	    }
	}
    }

    # if we didn't fail out due to a bad file, and we found all that was required...
    if (($returnval == 1) && ($newtmpcur == 3))
    {
	# and if it's a ++...
	if ($isplusplus == 1) { $returnval = 2; }
    }
    else
    {
	# otherwise, we failed
	$returnval = 0;
    }

    return $returnval;
}

sub messageNameIsValid
{
    my ($self, $messagename) = @_;

    # we permit message name to be a full path:
    my ($messagenamepathstripped) = ($messagename =~ m|.*/([^/]+)$|);
    if (!$messagenamepathstripped) { $messagenamepathstripped = $messagename; };
    return (($messagenamepathstripped =~ m|^([^\.:/]+)(\.)([^\.:/]+)(\.)([^:/]+)(:[12]\,[PRSTDF]+)?$|) ? 1 : 0);
}

sub createNamedTmpMessage
{
    # properly named mail message with filepath contents, or no contents
    my ($self, $filepath) = @_;
    my $success = 0;
    my $newname; my $fh; my $filename;

    my $path = $self->{"directory"};
    if ($self->{"folder"}) { $path .= "/" . $self->{"folder"}; }
    my $tmppath = $path . "/tmp/";

    if (!-e $tmppath)
    {
	$self->warnLog("Failed to find a temp directory at $tmppath");
    }
    else
    {
	# step 1: create a temp file
	($fh, $filename) = tempfile( DIR => "$tmppath");
	
	$filepath =~ s/[\`\|\:\\]+//g;
	if ((-e $filepath) && (-f $filepath))
	{
	    my $lfh = new FileHandle;
	    $lfh->open ("<" . $filepath) or 
		$self->warnLog("Failed to open $filepath for reading!  ($!)  Creating empty message.");
	    while (<$lfh>)
	    {
		print $fh $_;
	    }
	    $lfh->close();
	    $fh->flush();
	}
	## returns open file handle? 
	## close $fh;
	
	# step 2: find out its stuff
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
	
	# step 3: rename the file
	my $timestr = &getTimeSecsString();
	my $millis = &getTimeMillisString();
	my $pid = $$;
	my ($filenamepathstripped) = ($filename =~ m|.*/([^/]+)$|);
	if (!$filenamepathstripped) { $filenamepathstripped = $filename; };
	$newname = $timestr . "." . $pid . "_" . $millis . "_" . $ino . "." . $hostname . ",S=" . $size;
	my $newfile = $tmppath . $newname;
	$success = move($filename, $newfile);
	$self->warnLog("Error moving tmp message from temp dir ($filename) to ($newfile) tmp maildir: $!\n") 
	    if !$success;
    }

    # step 4: return the name of the file we created
    return ($success ? ($newname, $fh) : ());
}

sub moveTmpToNew
{
    my ($self, $messagename) = @_;
    # we permit meesage name to be a full path:
    my ($messagenamepathstripped) = ($messagename =~ m|.*/([^/]+)$|);
    if (!$messagenamepathstripped) { $messagenamepathstripped = $messagename; };

    my $path = $self->{"directory"};
    if ($self->{"folder"}) { $path .= "/" . $self->{"folder"}; }
    my $newpath = $path . "/new/";    
    my $tmppath = $path . "/tmp/";    

    my $success = move ($tmppath . $messagenamepathstripped, $newpath . $messagenamepathstripped);
    $self->warnLog("Error moving tmp message to ($messagename) new: $!") if !$success;

    if (($success) && ($self->{"isplusplus"}))
    {
	# recalculate maildirsize
	my ($bytes, $messages) = $self->calculateMaildirsize();
	if ($bytes == -1)
	{
	    $self->warnLog("moveTmpToNew: failed to recalculate maildirsize");
	    $success = 0;
	}
    }

    return $success;
}

sub moveNewToCur
{
    my ($self, $message) = @_;
    # we permit meesage name to be a full path:
    my ($messagenamepathstripped) = ($message =~ m|.*/([^/]+)$|);
    if (!$messagenamepathstripped) { $messagenamepathstripped = $message; };

    my $newname = $messagenamepathstripped . ":2,P";

    my $path = $self->{"directory"};
    if ($self->{"folder"}) { $path .= "/" . $self->{"folder"}; }
    my $newpath = $path . "/new/";    
    my $curpath = $path . "/cur/";    

    my $success = move ($newpath . $messagenamepathstripped, $curpath . $newname);

    $self->warnLog("Error moving new message to ($message) cur: $!") if !$success;

    if (($success) && ($self->{"isplusplus"}))
    {
	# recalculate maildirsize
	my ($bytes, $messages) = $self->calculateMaildirsize();
	if ($bytes == -1)
	{
	    $self->warnLog("moveNewToCur: failed to recalculate maildirsize");
	    $success = 0;
	}
    }

    return ($success ? $newname : $success);
}

sub createMaildir
{
    my ($self, $optfolder) = @_;
    my $retval = 0;
    if (!$self->{"exists"})
    {
	$self->warnLog("Failing to createMaildir in non-existant directory " . $self->{"directory"} . 
	    ".  Sorry, that is not allowed.");
	return 0;
    }
    else
    {	
	my $base = ($optfolder || $MAILDIRNAME);
	if ($base eq $ABS_PATH) { $base = ''; $optfolder = ''; }

	$retval = mkdir($self->{"directory"} . "/" . $base, 0700);
	
	if (!$retval) 
	{ 
	    $self->warnLog("Error in Mail::Maildir trying to make " . $self->{"directory"} . "/" . $base . 
		" -- caught error: $!"); 
	    return $retval; 
	}	
	$retval = mkdir($self->{"directory"} . "/" . $base . "/new", 0700);
	if (!$retval) 
	{ 
	    $self->warnLog("Error in Mail::Maildir trying to make " . $self->{"directory"} . "/" . $base . 
		"/new -- caught error: $!"); 
	    return $retval; 
	}
	$retval = mkdir($self->{"directory"} . "/" . $base . "/tmp", 0700);
	if (!$retval) 
	{ 
	    $self->warnLog("Error in Mail::Maildir trying to make " . $self->{"directory"} . "/" . $base . 
		"/tmp -- caught error: $!"); 
	    return $retval; 
	}
	$retval = mkdir($self->{"directory"} . "/" . $base . "/cur", 0700);	
	if (!$retval) 
	{ 
	    $self->warnLog("Error in Mail::Maildir trying to make " . $self->{"directory"} . "/" . $base . 
		"/cur -- caught error: $!"); 
	    return $retval; 
	}

	if ($optfolder)
	{
	    my $maildirfolder = $self->{"directory"} . "/" . $base . "/maildirfolder"; 
	    `touch $maildirfolder`;
	    $retval = chmod 0700, $maildirfolder;
	    if (!$retval) 
	    { 
		$self->warnLog("Error in Mail::Maildir trying to make " . $self->{"directory"} . "/" . $base . 
		    "/cur -- caught error: $!"); 
		return $retval; 
	    }	
	}
	else
	{
	    $self->{"directory"} = $self->{"directory"} . "/" . $base;
	    $self->{"isvalid"} = 1;
	}
	# don't change context for folder creation
    }

    return 1;
}

sub getTimeSecsString
{
    return time;
}

sub getTimeMillisString
{
    my $returnval = 0;
    eval("use Time::HiRes qw(gettimeofday);");

    if ($!)
    {
	$returnval = int(rand(1000000));
    }
    else
    {
	my ($seconds, $microseconds) = &gettimeofday;
	$returnval = $microseconds;
    }

    return $returnval;
}

sub getDirectory
{
    my ($self) = @_;
    return $self->{"directory"};
}

sub isValidMaildir
{
    my ($self) = @_;
    return $self->{"isvalid"};
}

sub isPlusplusMaildir
{
    my ($self) = @_;
    return $self->{"isplusplus"};
}

sub dirExists
{
    my ($self) = @_;
    return $self->{"exists"};
}

sub isInsecure
{
    my ($self) = @_;
    return $self->{"insecure"};
}

sub getQuotaBytes
{
    my ($self) = @_;
    ($self->{"isplusplus"}) ? (return $self->{"quotabytes"}) : (return -1);
}

sub getQuotaMessages
{
    my ($self) = @_;
    ($self->{"isplusplus"}) ? (return $self->{"quotamessages"}) : (return -1);
}

sub getMaildirUsage
{
    my ($self) = @_;
    if ($self->{"isplusplus"})
    {
	return ($self->{"usedbytes"}, $self->{"usedmessages"}); 
    }
    else 
    {
	# -1, -1 if not a ++
	return (-1, -1);
    }
}

sub listMessages
{
    my ($self) = @_;
    my $home = $self->{"directory"};
    my $folder = $self->{"folder"};
    
    if ($folder) { $home = $home . "/" . $folder; }
    my $cur = $home . "/cur/*";
    my $new = $home . "/new/*";

    my @searchmsgs = glob("$cur $new");

    my @messages = ();
    foreach my $xmessage (@searchmsgs)
    {
	next if !$xmessage;

        my ($messagestripped) = ($xmessage =~ m|.*/([^/]+)$|);
	if (!$messagestripped) { $messagestripped = $xmessage; };
	
        next if (!-f $xmessage);
	next if (!$self->messageNameIsValid($messagestripped));

	my $size = &determineSize($xmessage, $messagestripped);
	my $status = &determineStatus($xmessage, $messagestripped);
	my $folder = $self->{"folder"};
	my %messagehash = (
			   NAME => $messagestripped,
			   SIZE => $size,
			   STATUS => $status,
			   FOLDER => $folder,
			   FULLPATH => $xmessage,
			   );

	push @messages, \%messagehash;
    }
    
    return \@messages;
}

sub determineSize
{
    my ($m, $ms) = @_;
    if ($m =~ m/\,S=(\d+)\D?.*$/)
    {
	#warn "RETURN positional ($m) , $1\n";
	return $1;
    }
    else
    {
	#warn "RETURN STAT ($m) , " . (stat($ms))[7] . "\n";
	return (stat($m))[7];
    }
}

sub determineStatus
{
    my ($m, $ms) = @_;
    if ($m =~ m/\:2,(\w+)/)
    {
	return $1;
    }
    else
    {
	return "N";
    }
}

sub trashMessage
{
    # folder context specific
    my ($self, $message, $actuallyremove) = @_;
    my $success = 0;

    # we permit message name to be a full path:
    my ($messagenamepathstripped) = ($message =~ m|.*/([^/]+)$|);
    if (!$messagenamepathstripped) { $messagenamepathstripped = $message; }

    my $path = $self->{"directory"};
    my $fpath = "$path";
    if ($self->{"folder"})
    {
	$fpath .= "/" . $self->{"folder"};
    }
    my $cpath = "$fpath";
    $cpath .= "/cur/" . $messagenamepathstripped;

    if ($actuallyremove)
    {
	$success = unlink($cpath);
	if (!$success)
	{
	    $self->warnLog("trashMessage, actually remove, failed to unlink $cpath ($message)");
	}
    } # if actuallyremove
    else
    {
	if ($self->{"isplusplus"})
	{
	    if (!-e ($path . "/.Trash"))
	    {
		mkdir($path . "/.Trash", 0700);
	    }
	    $messagenamepathstripped =~ s|\:2\,\w|\:2\,T|;
	    $success = move($cpath, $path . "/.Trash/" . $messagenamepathstripped);
	    if (!$success)
	    {
		$self->warnLog("trashMessage, move to .Trash failed ($messagenamepathstripped)");
	    }
	    else
	    {
		$success = $messagenamepathstripped;
	    }
	} # if is plusplus
	else
	{	
	    $messagenamepathstripped =~ s|\:2\,\w|\:2\,T|;
	    $success = move($cpath, $fpath . "/cur/" . $messagenamepathstripped);    
	    if (!$success)
	    {
		$self->warnLog("trashMessage, move to cur with new flag failed ($messagenamepathstripped)");
	    }
	    else
	    {
		$success = $messagenamepathstripped;
	    }
	} # else is not plusplus
    } # else do not actually remove

    return $success;
}

sub delete
{
    my ($self) = @_;
    my $dir = $self->{"directory"};
    my $retval = 0;
    if ($self->{"folder"})
    {
	$dir .= "/" . $self->{"folder"};
    }

    if ((-e $dir) && (-d $dir) && (!-l $dir) && ($self->determineMaildirValidity($dir)))
    {
	# i'm paranoid, so i can't bring myself to completely remove:
	rmtree(["$dir/cur", "$dir/new", "$dir/tmp", "$dir/mailfolder", "$dir/maildirsize", "$dir/.Trash"]);
	$retval = 1;
    }
    else
    {
	$self->warnLog("Could not delete $dir: didn't exist or wasn't a maildir");
	$retval = 0;
    }

    return $retval;
}

sub upgradeToPlusplus
{
    my ($self, $quotabytes, $quotamessages) = @_;    
    my $retval = 0;

    if ($self->{"exists"})
    {   
	if ($self->{"isplusplus"})
	{
	    $self->warnLog("Cannot upgrade " . $self->{"directory"} . " because it is already a maildir++.");
	}
	elsif (!$self->{"isvalid"})
	{
	    $self->warnLog("Cannot upgrade " . $self->{"directory"} . " because it is not a maildir.  Failing.");
	}
	else
	{
	    # make .Trash
	    my $trashfolder = $self->{"directory"} . "/.Trash";
	    $retval = mkdir $trashfolder, 0700;

	    $self->{"quotabytes"} = $quotabytes || $DEFAULT_QUOTA_BYTES;
	    $self->{"quotamessages"} = $quotamessages || $DEFAULT_QUOTA_MESGS;

	    $self = Mail::Maildir::Plusplus->__new($self);

	    # calculate maildirsize
	    my $tmp;

	    if ($retval) 
	    { 
		($retval, $tmp) = $self->calculateMaildirsize(); 

		# update our local info
		if ($retval != -1) 
		{ 
		    $retval = 1; 
		    $self->{"isplusplus"} = 1; 
		}
		else         
		{
		    $self->warnLog("failure to return a valid result from calculateMaildirsize()($retval)-dump was: " .
				   $self->statedump()); 
		}
	    }
	    else         
	    { 
		$self->warnLog("Unable to make maildir++ Trash folder $trashfolder; will not flag the creation as a success");
	    }
	}
    }
    else
    {
	$self->warnLog("Cannot upgrade " . $self->{"directory"} . " because it doesn't exist.  Failing.");
    }

    return $retval;
}

##############################################################################
#
# Utility
#
##############################################################################

sub statedump
{
    my ($self) = @_;
    $self->warnLog("\n__DATA DUMP__:\n");
    foreach my $key (keys %$self)
    {
	next if !$key;
	$self->warnLog("\tKEY: $key, VAL: " . $self->{$key});
    }
    $self->warnLog("\n__END_DUMP__\n");
    return 1;
}

sub enableWarnLog
{
    my ($self) = @_;
    my $log = $self->{"warnlog"};
    my $retval = 1;
    my $lfh = new FileHandle;
    $lfh->open(">>" . $log) or (
			       ($retval = 0) 
			       );				 
    $lfh->close();
    if ($retval)
    {
	$self->{"warnlogenabled"} = 1;
    }
    return $retval; 
}

sub warnLogAt
{
    my ($self, $log) = @_;
    my $retval = 1;
    $self->{"warnlog"} = $log;
    my $lfh = new FileHandle;
    $lfh->open (">>" . $log) or ($retval = 0);
    $lfh->close();
    return $retval;
}

sub warnLog
{
    my ($self, $message) = @_;
    if ($self->{"warnlogenabled"})
    {
	my $log = $self->{"warnlog"};
	my $lfh = new FileHandle;
	$lfh->open(">>" . $log);
	print $lfh "(pid: $$, time: " . time . ": $message\n";
	$lfh->close();
    }
}

1;

__END__

# to view pod: pod2man ./Mail/Maildir.pm | nroff -man | more

=head1 NAME

Mail::Maildir -- Maildir/Maildir++ filesystem implementation

=head1 SYNOPSIS

See the README for copyright information and prerequisites.  See INSTALL_SOURCE/t/Maildir.t for 
useful use cases.

This program implements many of the common features of creating, managing, removing, and so on of 
Maildir and Maildir++ directories and files.  Reference:

=over 2

=item 1.
Z<>  B<http://cr.yp.to/proto/maildir.html>

=item 2.
Z<>  B<http://www.inter7.com/courierimap/README.maildirquota.html>

=back

=head1 USAGE

Z<>    B<< my $maildirObj = new Mail::Maildir("/path/to/somewhere"); >>

Path should *be* the Maildir (i.e. /path/Maildir, and not, /path, which HAS a Maildir).  Initializes a new Maildir
object, sets internal values for isvalid, isplusplus (that is, runs several validation functions on initialization).
This never returns undef.  It won't create a new Maildir if the path isn't a Maildir, (use create() for this) and it 
will open() it if it is a Maildir.

~~~~~

Z<>    B<< my $maildirObj = Mail::Maildir::Plusplus::open(PATH); >>

Z<>    B<< my $maildirObj = Mail::Maildir::open(PATH); >>

Z<>    B<< my $maildirObj = Mail::Maildir->open(PATH); >>

Z<>    B<< my $maildirObj = open Mail::Maildir(PATH); >>

Opens an existing Maildir, returns undef if it isn't a Maildir.

~~~~~

Z<>    B<< my $maildirObj = Mail::Maildir::Plusplus::create(PATH); >>

Z<>    B<< my $maildirObj = Mail::Maildir->create(PATH); >>

Z<>    B<< my $maildirObj = Mail::Maildir::create(PATH); >>

Z<>    B<< my $maildirObj = create Mail::Maildir(PATH); >>

Creates a Maildir, returns a Mail::Maildir on success or on already exists, returns undef if it failed.  NOTE: The 
Maildir will be created right in PATH, as PATH/new, PATH/cur etc.  Use this method to create Maildirs whose base paths
are not .../Maildir/.  Note also that you can shoot yourself in the foot here, by creating a Maildir in a directory 
that has existing files disallowed in a Maildir/++

~~~~~

Z<>    B<< my $success = $maildirObj->warnLogAt(filestring); >>

Say where you want the log to be.  Returns 0 or 1, where 0 means that the log could not be written there, and 1 means
that it can.  Specify a full path.  The default log location is /tmp/maildir.log

~~~~~

Z<>    B<< my $success = $maildirObj->enableWarnLog(); >>
                        
Returns 0 (log not successfully writable, warn logging not enabled) or 1 (log successfully writable, warn logging
enabled); the default log location is /tmp/maildir.log.

~~~~~

Z<>    B<< my $ret = $maildirObj->createMaildir($optfolder); >>

Make a non-++ Maildir as ./Maildir at the directory you specified in new(), or as a subfolder named $optfolder if
$optfolder is specified.  Note: we use the .Folder convention for Maildir++ folders, but you do I<not> specify
the dot yourself, i.e. if you want a folder called 'Stuff', then say 'Stuff', not '.Stuff' in $optfolder.   This 
method will not create subfolders automatically -- even if you are in a folder context after having used setFolder(),
the Maildir that would be created with $optfolder will be in $optfolder, not $folder.$optfolder.  A 0 return means 
failed to create the Maildir and 1 indicates success.  Note: after creating a Maildir without the $optfolder, so
making ./Maildir, the internal path is automatically adjusted to path/Maildir (hopefully for convenience), where
path is whatever you said in new().

~~~~~

Z<>    B<< my $ret = $maildirObj->delete(); >>

If maildirObj refers to a valid Maildir, this removes everything under dir/cur, dir/new, dir/tmp and dir/.Trash, as
well as maildirsize and maildirfolder.  If called in a folder context (after setFolder()), then 'dir' will be the
folder directory.  Returns 0 for any failures, and 1 for success.

~~~~~

Z<>  B<< my $ret = $maildirObj->isValidMaildir(); >>

Is this a Maildir?  Returns 0 or 1.

~~~~~

Z<>  B<< my $ret = $maildirObj->isPlusplusMaildir(); >>

Is this a Maildir++?  Returns 0 or 1.  Note: the algorithm here is: it is a Maildir if, and only if, (1) at the time
the object was instantiated, the instantiation folder had maildirsize, and either a .Trash or a subfolder with a
maildirfolder file, OR (2) upgradeToPlusplus() was called on the object, and was successful.

~~~~~

Z<>  B<< my $ret = $maildirObj->upgradeToPlusplus(quotabytes, quotamsg); >>

If maildirObj is a Maildir but not a Maildir++, this will create a properly formatted quota file (maildirsize) with 
quota $quotabytes and $quotamsg, and a Trash folder, properly formatted.  Returns 0 on any failure, and 1 on success.

~~~~~

Z<>  B<< my $ret = $maildirObj->setFolder(foldername); >>

If maildirObj is a Maildir++, sets the current folder context to 'foldername'.  Note: the current folder context is 
used; so you can change to subfolders using this method by calling setFolder() into deeper folders.  Returns 0 for
any failure, 1 on success.  Note: you can set subfolders directly, e.g. foldername = folder.subfolder.

~~~~~

Z<>  B<< my $ret = $maildirObj->createFolder(foldername); >>

If maildirObj is a Maildir++,  creates a folder and sets context to 'foldername'.  Note: the current folder context is 
used; so you can create subfolders using this method.  The subfolder convention used is the 'dot' notation one; i.e. if
you are in folder F and create a new folder D, D will be a subfolder of F, and the filesystem structure, under
your root Maildir++, will have a directory called .F.D.  Returns 0 for any failure, 1 on success.

~~~~~

Z<>  B<< my ($n, $fh) = $maildirObj->createNamedTmpMessage(); >>

Z<>  B<< my ($n, $fh) = $maildirObj->createNamedTmpMessage(filenameString); >>

Put a message in tmp, optionally with the contents of the file specified as a full path with filenameString.  Returns
an empty array on failure, or $messagename (valid Maildir message name that was created, not a full path) and an OPEN, 
writable filehandle to the message file.  Note: if you are in a folder context, the tmp directory used will be the one
corresponding to that folder.

~~~~~

Z<>  B<< my $ret = $maildirObj->moveTmpToNew($messagename); >>

Moves messagename from tmp to new, respecting folder context.  Returns 0 (failure) or 1 (success).

~~~~~

Z<>  B<< my $messagename = $maildirObj->moveNewToCur($messagename); >>

Moves messagename from new to cur, respecting folder context.  Returns new message name (sets P flag) on success,
0 on failure.

~~~~~

Z<>    B<< my $ret = $maildirObj->trashMessage($messagename, $actuallyremove); >>

Trashes a message from cur; respects Maildir++ trashing convention if isPlusplus, creating .Trash if necessary.  Folder
context is respected (i.e. will trash folder/cur to base/.Trash).  Returns 0 (failure) or messagename (with replaced
2,T info string, on success).  If actuallyremove is specified, the messagename will be the true value returned from
unlink().

~~~~~

Z<>  B<< my $ret = $maildirObj->getQuotaBytes(); >>

Returns the quota in bytes for this account, -1 on error.

~~~~~

Z<>  B<< my $ret = $maildirObj->getQuotaMessages(); >>

Returns the quota in messages for this account, -1 on error.

~~~~~

Z<>  B<< my $ret = $maildirObj->dirExists(); >>
                               
Returns 0 if the directory specified in new() does not exist, otherwise 1.

~~~~~

Z<>  B<< my $ret = $maildirObj->isInsecure(); >>

Not terribly useful, but, if the directory specified in new() contains :, `, | or \, then those characters got
stripped from the name, and this flag got set to 1.  0 otherwise.

~~~~~

Z<>  B<< my ($byte, $message) = $maildirObj->getMaildirUsage(); >>

Returns the usage information (bytes, messages) deduced from the Maildir++ quota file (maildirsize).  Returns -1, -1 
if maildirObj is not a Maildir++.

~~~~~

Z<>  B<< my $ret = $maildir->setQuota(bytes, messages); >>

Sets the quota -- if an argument is set to '', the existing value will be used.  Causes maildirsize to be rewritten.
Returns 0 or 1.

~~~~~

Z<>  B<< my ($bytes, $messages) = $self->calculateMaildirsize(); >>

Follows maildir++ procedure for calculating usage, and rewriting maildirsize, and returns the usage information
calculated.  Will return -1, -1 on any failure.  Note that not much counts as a failure: basically file writes for
maildirsize do count as failures, and nothing else does.  These is probably a bug here somewhere.

~~~~~

Z<>  B<< my ($arrayref) = $self->listFolders(); >>

Returns an array reference listing all the Maildir++ folders.  Note: is independent of context, so will return a list 
of names that start with '.' and may have more '.'s in them.

~~~~~

Z<>  B<< my ($arrayref) = $self->listMessages(); >>

Returns an array reference listing all the mail messages in the folder context set for $self (can be none, for base
Maildir).  The array structure is as follows: each item is a hash reference, whose dereferencers are SIZE (the
size of the mail message), STATUS (new, read, passed, etc), FOLDER (the folder this message was found in), FULLPATH
(the full path to the message) and NAME (the name of the message).  STATUS can be anything in INFO_FLAGS, or N for new.

~~~~~

=head2 Internal API:

Z<>  B<< my $ret = $self->determineMaildirValidity($optdir); >>

0 for false, 1 for maildir, 2 for Maildir++.

~~~~~

Z<>  B<< my $ret = $self->loadMaildirsize(); >> 

Parse and set internal ($self) usage values from maildirsize.

~~~~~

Z<>  B<< my $ret = $self->writeDefaultMaildirsize(); >>

Writes a default maildirsize file with $DEFAULT_QUOTA_BYTES and $DEFAULT_QUOTA_MESGS.


=head1 BUGS

I think the unique filename creator could be made better.  The test suite could be fleshed out much more.  The failure
return values could be fleshed out in more detail with better codes for failures.  Complex operations that have many 
steps should be able to rollback all changes on a failure.  There is probably a bug somewhere in 
calculateMaildirsize().

I am sure there are other bugs; the fact that I cannot find them lends even more credence to this hypothesis.

=head1 FUTURE DEVELOPMENT

Plug this module into Mail::Box and create a nifty mail reader for Maildir/Maildir++ all in Perl.  Create a web
interface to the same.

=head1 AUTHOR

Edward L. Abrams <edward.abrams@corp.terralycos.com>.

Copyright (c) 2004 Edward Abrams, Lycos.  All rights reserved.  This program is free software: you can redistribute 
it and/or modify it under the same terms as Perl itself.

=head1 FIN

Fin.

=cut
