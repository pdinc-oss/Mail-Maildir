#!/usr/bin/perl -w

use strict;
use lib './lib';
use Test::More tests => 36;
use Mail::Maildir;
use Mail::Maildir::Plusplus;
use File::Path;

########################################################### MAILDIR

ok (1, "MAILDIR TESTS");

my $INVALID_MAILDIR_PATH = "/tmp/ridiculous/path/for/a/maildir";
ok (&enable_warn_log, "enabling warn log");
ok (&warn_log_at, "put warn log at /tmp/log.warn");

ok (&create_then_instance_nodir(), 
    "attempt to create a maildir obj on a directory tree that doesn't exist, createMaildir -- ok means didn't work");

my $MAILDIR_PATH = "/tmp";
my $MAILDIR_PATH_P = "/tmp/Maildir";
ok (&create_then_instance_success(),
    "attempt to create a maildir obj on a directory tree that does exist and run createMaildir");

ok (&create_maildir_where_one_exists(),
    "attempt to create a maildir where one exists already -- ok means didn't work");

ok (&open_real, "open a maildir that exists");
ok (&open_unreal, "open a maildir that does not exist");
ok (&create_new, "create a new one");
ok (&create_exists, "create a new one over an existing one");

ok (&upgrade_our_maildir_to_plusplus(),
    "attempt to upgrade our maildir to plusplus");

ok (&upgrade_already_upgraded_maildir(),
    "attempt to upgrade an already upgraded maildir");

ok (&create_plusplus_maildir, "create a new plusplus maildir");

########################################################### STATE DATA

ok (&getdirectory(), "get the maildir directory");
ok (&isvalid(), "is a valid maildir");
ok (&isplusplus(), "is a plusplus maildir");
ok (&direxists(), "directory exists?");
ok (&insecure(), "is an insecure pathname?");
ok (&getquotabytes(), "get quota in bytes");
ok (&getquotamessages(), "get quota in messages");

########################################################### MESSAGE

ok (1, "MESSAGE TESTS");

my $messagename;
ok (&create_temp_message(),
    "create a temporary message in maildir/tmp");

ok (&move_message_to_new(),
    "move the temporary message to maildir/new");

ok (&move_message_to_cur(),
    "move the temporary message to maildir/cur");

ok (&messagename_is_valid(),
    "simple messagename validity test suite");

ok (&getmaildirusage(), "get maildir usage info");

########################################################### FOLDER

ok (1, "FOLDER TESTS");

my $FOLDER = "subfolder";
ok (&create_a_mailfolder(),
    "attempt to make a folder");

ok (&create_a_subfolder(),
    "attempt to make a subfolder of the folder we made");

ok (&list_folders(),
    "list existing folders in the home directory");

ok (&list_messages(),
    "list existing messages");

########################################################### QUOTA

ok (1, "QUOTA TESTS");

ok (&set_new_quota(), "attempt to set a new quota for the user");

########################################################### DELETE

ok (1, "DELETE TESTS");

ok (&trash_the_message(),
    "remove the message we made");

ok (&delete(),
    "delete the maildir we made");

#print "\n\nSuspend to check file system, hit ENTER to finish\n\n";
#my $throw = <STDIN>;

# ! cleanup !
rmtree(["/tmp/Maildir", "/tmp/Maildir2", "/tmp/Maildir3", "/tmp/testfile.maildir", "/tmp/maildir.log"]);

exit 0;

######################################################################################

sub enable_warn_log
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($INVALID_MAILDIR_PATH);
    my $success = $mailObj->enableWarnLog();
    if ($success)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "enable_warn_log");
    }
    
    return $returnval;
}

sub warn_log_at
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($INVALID_MAILDIR_PATH);
    my $success = $mailObj->warnLogAt("/tmp/log.warn");
    if ($success)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "warn_log_at");
    }
    
    return $returnval;
}

sub create_then_instance_nodir
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($INVALID_MAILDIR_PATH);
    $mailObj->enableWarnLog();  
    my $success = $mailObj->createMaildir();    
    if ($success == 0)
    {
	$success = $mailObj->createMaildir(".foo");
	if ($success == 0)
	{
	    $success = $mailObj->createMaildir("foo");
	    if ($success == 0)
	    {
		&buzzsuccess($mailObj);
		$returnval = 1;
	    }
	}
    }
    else
    {
	&buzzerror($mailObj, "create_then_instance_nodir");
    }

    return $returnval;
}

sub create_then_instance_success
{
    # put it in /tmp, to /tmp/Maildir
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH);
    $mailObj->enableWarnLog();  
    my $success = $mailObj->createMaildir();
    if ($success == 1)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "create_then_instance_success");
    }

    return $returnval;
}

sub create_maildir_where_one_exists
{
    # put it in /tmp, to /tmp/Maildir
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH);
    my $success = $mailObj->createMaildir();
    if ($success == 0)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "create_maildir_where_one_exists");
    }

    return $returnval;
}

sub open_real
{
    my $returnval = 0;

    my $mailObj = Mail::Maildir::open($MAILDIR_PATH_P);
    if ($mailObj)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "open_real");
    }

    return $returnval;
}

sub open_unreal
{
    my $returnval = 0;

    my $mailObj = Mail::Maildir::open($INVALID_MAILDIR_PATH);
    if (!$mailObj)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "open_unreal");
    }

    return $returnval;
}

sub create_new
{
    my $returnval = 0;

    my $mailObj = Mail::Maildir::create("/tmp/Maildir2");
    if ($mailObj)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "create_new");
    }

    return $returnval;
}

sub create_exists
{
    my $returnval = 0;

    my $mailObj = Mail::Maildir::create("/tmp/Maildir2");
    if ($mailObj)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "create_exists");
    }

    return $returnval;
}

sub upgrade_our_maildir_to_plusplus
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $success = $mailObj->upgradeToPlusplus(500000, 500);
    if ($success == 1)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "upgrade_our_maildir_to_plusplus");
    }

    return $returnval;
}

sub upgrade_already_upgraded_maildir
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $success = $mailObj->upgradeToPlusplus(5000010, 5010);
    if ($success == 0)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "upgrade_already_upgraded_maildir");
    }

    return $returnval;
}

sub create_plusplus_maildir
{
    my $returnval = 0;

    my $mailObj = Mail::Maildir::Plusplus::create("/tmp/Maildir3", 1000000, 1000);
    if ($mailObj)
    {
	&buzzsuccess($mailObj);
	$returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "create_plusplus_maildir");
    }

    return $returnval;
}

sub getdirectory
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $dir = $mailObj->getDirectory();
    if ($dir eq $MAILDIR_PATH_P)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;	
    }
    else
    {
	&buzzerror($mailObj, "getdirectory");
    }

    return $returnval;
}

sub isvalid
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $s = $mailObj->isValidMaildir();
    if ($s == 1)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "isvalid");
    }

    return $returnval;
}

sub isplusplus
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $s = $mailObj->isPlusplusMaildir();
    if ($s == 1)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "isplusplus");
    }

    return $returnval;
}

sub direxists
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $s = $mailObj->dirExists();
    if ($s == 1)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "direxists");
    }

    return $returnval;
}

sub insecure
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $s = $mailObj->isInsecure();
    if ($s == 0)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "insecure");
    }

    return $returnval;
}

sub getquotabytes
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $s = $mailObj->getQuotaBytes();
    if ($s == 500000)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "getquotabytes");
    }

    return $returnval;
}

sub getquotamessages
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $s = $mailObj->getQuotaMessages();
    if ($s == 500)
    {
	&buzzsuccess($mailObj);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "getquotamessages");
    }

    return $returnval;
}

sub create_temp_message
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    open (OUTFILE, ">/tmp/testfile.maildir");
    print OUTFILE "hihihi";
    close OUTFILE;
    
    my $fh;
    ($messagename, $fh) = $mailObj->createNamedTmpMessage("/tmp/testfile.maildir");
    $fh->close();
    if (-e "/tmp/Maildir/tmp/$messagename")
    {
	&buzzsuccess($mailObj, "messagename: " . $messagename);
        $returnval = 1;
    }    
    else
    {
	&buzzerror($mailObj, "create_temp_message");
    }

    return $returnval;
}

sub move_message_to_new
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $success = $mailObj->moveTmpToNew($messagename);
    if ($success == 1)
    {
	&buzzsuccess($mailObj, "messagename: " . $messagename);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "move_message_to_new");
    }

    return $returnval;
}

sub move_message_to_cur
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    $messagename = $mailObj->moveNewToCur($messagename);
    if ($messagename)
    {
	&buzzsuccess($mailObj, "messagename: " . $messagename);
        $returnval = 1;
    }
    else
    {
	&buzzerror($mailObj, "move_message_to_cur");
    }

    return $returnval;
}

sub messagename_is_valid
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $success = $mailObj->messageNameIsValid("asdf.asdf.asdf");
    if ($success == 1)
    {
	$success = $mailObj->messageNameIsValid("asdf.asdf.asdf:2,P");
	if ($success == 1)
	{
	    $success = $mailObj->messageNameIsValid("asdf.asdf.asdf.asdf:2,P");
	    if ($success == 1)
	    {
		&buzzsuccess($mailObj);
		$returnval = 1;
	    }
	    else
	    {
		warn "asdf.asdf.asdf.asdf is not valid?  Wrong.\n";			
	    }
	}
	else
	{
	    warn "asdf.asdf.asdf:2,P is not valid?  Wrong.\n";
	}
    }
    else
    {
	warn "asdf.asdf.asdf is not valid?  Wrong.\n";
	&buzzerror($mailObj, "message_name_is_valid");
    }

    return $returnval;
}

sub getmaildirusage
{
    my $returnval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my ($b, $m) = $mailObj->getMaildirUsage();
    if (($b == 6) && ($m == 1)) { $returnval = 1; }

    if (0)
    {
	print "****** bytes $b, messages $m ******\n";
        print "\n###################\nOutput data:\n";
        $mailObj->statedump();
        print "\n###################\n";
    }
 
    if (0)
    {
	&buzzerror($mailObj, "getmaildirusage");
    }

    return $returnval;
}

sub create_a_mailfolder
{
    my $retval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $success = $mailObj->createFolder("hello");
    if ($success)
    {
	if ((-e "/tmp/Maildir/.hello") && (-d "/tmp/Maildir/.hello"))
	{
	    if ($mailObj->determineMaildirValidity("/tmp/Maildir/.hello"))
	    {
		&buzzsuccess($mailObj);
		$retval = 1;
	    }
	}
    }
    else
    {
	&buzzerror($mailObj, "create_a_mailfolder");
    }

    return $retval;
}

sub create_a_subfolder
{
    my $retval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $success = $mailObj->setFolder("hello");
    if ($success)
    {
	$success = $mailObj->createFolder("goodbye");
	if ($success)
	{
	    if ((-e "/tmp/Maildir/.hello.goodbye") && (-d "/tmp/Maildir/.hello.goodbye"))
	    {
		if ($mailObj->determineMaildirValidity("/tmp/Maildir/.hello.goodbye"))
		{
		    &buzzsuccess($mailObj);
		    $retval = 1;
		}
	    }
	}
    }
    else
    {
	&buzzerror($mailObj, "create_a_mailfolder");
    }

    return $retval;    
}

sub list_folders
{
    my $retval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $folders = $mailObj->listFolders();
    foreach (@{$folders})
    {
	$retval++;
    }
    #print "Folders, found $retval (want 2)\n";

    return (($retval == 2) ? 1 : 0);
}

sub list_messages
{
    my $retval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    my $msgs = $mailObj->listMessages();

    my $messagecount = @{$msgs};
    if ($messagecount == 1)
    {
	my $messagehash = $msgs->[0];
	if (($messagehash->{"SIZE"} == 6) &&
	    ($messagehash->{"STATUS"} eq "P") &&
	    ($messagehash->{"NAME"} eq $messagename))
	{
	    $retval = 1;
	}
	else
	{
	    warn "Odd, got wrong message data; dump follows; failing (global messagename: $messagename)\n";
	    foreach (keys %{$messagehash})
	    {
		warn "DUMP: key $_, value " . $messagehash->{$_} . "\n";
	    }
	    warn "__END DUMP__\n";
	}
    }
    else
    {
	warn "Odd, got message count of $messagecount; failing\n";       
    }

    return $retval;
}

sub set_new_quota
{
    my $retval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    $retval = $mailObj->setQuota(8000000, 800);

    return $retval;
}

sub trash_the_message
{
    my $retval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    #$retval = $mailObj->trashMessage($messagename, 1);
    $retval = $mailObj->trashMessage($messagename);

    if ($retval)
    {
	if (!-e "$MAILDIR_PATH_P/.Trash/$retval")
	{
	    print "$MAILDIR_PATH_P/.Trash/$retval\n";
	    my $t = <STDIN>;
	    $retval = 0;
	}
    }

    #warn "returnval $retval\n";
    #my $t = <STDIN>;

    return $retval;
}

sub delete
{
    my $retval = 0;

    my $mailObj = new Mail::Maildir($MAILDIR_PATH_P);
    $retval = $mailObj->setFolder("hello");
    if ($retval)
    {
	$retval = $mailObj->delete();
    }

    return $retval;
}

sub buzzerror
{
    my ($obj, $function) = @_;
    print "\n\n>>>>>>>>>>>>> ERROR REPORT for $function >>>>>>>>>\n";
    if ($obj) { $obj->statedump(); }
    print "\n<<<<<<<<<<<<<< END ERROR REPORT for $function <<<<<<<<<<<\n\n";
}

sub buzzsuccess
{
    my ($obj, $message) = @_;
    if (0)
    {
	print "\n###################\nOutput data ($message):\n";
	$obj->statedump();
	print "\n###################\n";
    }
}
 
__END__
