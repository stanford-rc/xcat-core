package xCAT_plugin::packimage;
use xCAT::Table;
use Getopt::Long;
use File::Path;
use File::Copy;
use Cwd;
use File::Temp;
use xCAT::Utils qw(genpassword);
Getopt::Long::Configure("bundling");
Getopt::Long::Configure("pass_through");

sub handled_commands {
     return {
            packimage => "packimage",
   }
}

sub process_request {
   my $sitetab = xCAT::Table->new('site');
   my $request = shift;
   my $callback = shift;
   my $doreq = shift;
   my $ent = $sitetab->getAttribs({key=>'installdir'},['value']);
   my $installroot = "/install";

   if ($ent and $ent->{value}) {
      $installroot = $ent->{value};
   }
   @ARGV = @{$request->{arg}};
    my $osver;
    my $arch;
    my $profile;
    my $method='cpio';
   GetOptions(
      "profile|p=s" => \$profile,
      "arch|a=s" => \$arch,
      "osver|o=s" => \$osver,
      "method|m=s" => \$method,
      "help|h" => \$help,
      "version|v" => \$version
      );
   if ($version) {
      $callback->({info=>["Version 2.0"]});
      return;
   }
   if ($help) {
      $callback->({info=>["packimage -h \npackimage -v \npackimage [-p profile] [-a architecture] [-o OS] [-m method]\n"]});
      return;
   }
   my $distname = $osver;
   until (-r  "$::XCATROOT/share/xcat/netboot/$distname/" or not $distname) {
      chop($distname);
   }
   unless ($distname) {
      $callback->({error=>["Unable to find $::XCATROOT/share/xcat/netboot directory for $osver"],errorcode=>[1]});
      return;
   }
    unless ($installroot) {
        $callback->({error=>["No installdir defined in site table"],errorcode=>[1]});
        return;
    }
    my $oldpath=cwd();
    my $exlistloc;
    if (-r "$::XCATROOT/share/xcat/netboot/$distname/$profile.$osver.$arch.exlist") {
       $exlistloc = "$::XCATROOT/share/xcat/netboot/$distname/$profile.$osver.$arch.exlist";
    } elsif (-r "$::XCATROOT/share/xcat/netboot/$distname/$profile.$arch.exlist") {
       $exlistloc = "$::XCATROOT/share/xcat/netboot/$distname/$profile.$arch.exlist";
    } elsif (-r "$::XCATROOT/share/xcat/netboot/$distname/$profile.$osver.exlist") {
       $exlistloc = "$::XCATROOT/share/xcat/netboot/$distname/$profile.$osver.exlist";
    } elsif (-r "$::XCATROOT/share/xcat/netboot/$distname/$profile.exlist") {
       $exlistloc = "$::XCATROOT/share/xcat/netboot/$distname/$profile.exlist";
    } else {
       $callback->({error=>["Unable to finde file exclusion list under $::XCATROOT/share/xcat/netboot/$distname/ for $profile/$arch/$osver"],errorcode=>[1]});
       next;
    }
    my $exlist;
    open($exlist,"<",$exlistloc);
    my $excludestr = "find . ";
    while (<$exlist>) {
       chomp $_;
       $excludestr .= "'!' -wholename '".$_."' -a ";
    }
    close($exlist);

	# add the xCAT post scripts to the image
	copybootscript($installroot, $osver, $arch, $profile, $callback);
   my $passtab = xCAT::Table->new('passwd');
   if ($passtab) {
      (my $pent) = $passtab->getAttribs({key=>'system',username=>'root'},'password');
      if ($pent and defined ($pent->{password})) {
         my $pass = $pent->{password};
         my $shadow;
         open($shadow,">","$installroot/netboot/$osver/$arch/$profile/rootimg/etc/shadow");
         unless ($pass =~ /^\$1\$/) {
            $pass = crypt($pass,'$1$'.genpassword(8));
         }
         print $shadow "root:$pass:13880:0:99999:7:::\n";
         close($shadow);
      }
   }


    my $verb = "Packing";
    if ($method =~ /nfs/) {
      $verb = "Prepping";
    }
    $callback->({data=>["$verb contents of $installroot/netboot/$osver/$arch/$profile/rootimg"]});
    if ($method =~ /nfs/) {
      $callback->({data=>["\nNOTE: Contents of $installroot/netboot/$osver/$arch/$profile/rootimg\nMUST be available on all service and management nodes and NFS exported."]});
    }
    my $temppath;
    my $oldumask;
    if (! -d "$installroot/netboot/$osver/$arch/$profile/rootimg") {
       $callback->({error=>["$installroot/netboot/$osver/$arch/$profile/rootimg does not exist, run genimage -o $osver -p $profile on a server with matching architecture"]});
       return;
    }
    if ($method =~ /cpio/) {
       $excludestr =~ s!-a \z!|cpio -H newc -o | gzip -c - > ../rootimg.gz!;
       unlink("$installroot/netboot/$osver/$arch/$profile/rootimg.gz");
       $oldmask = umask 0077;
    } elsif ($method =~ /squashfs/) {
      $temppath = mkdtemp("/tmp/packimage.$$.XXXXXXXX");
      $excludestr =~ s!-a \z!|cpio -dump $temppath!; 
      unlink("$installroot/netboot/$osver/$arch/$profile/rootimg.sfs");
    } elsif ($method =~ /nfs/) {
       $excludestr = "touch ../rootimg.nfs";
    } else {
       $callback->({error=>["Invalid method '$method' requested"],errorcode=>[1]});
    }
    chdir("$installroot/netboot/$osver/$arch/$profile/rootimg");
    system($excludestr);
    if ($method =~ /cpio/) {
        chmod 0644,"$installroot/netboot/$osver/$arch/$profile/rootimg.gz";
        umask $oldmask;
    } elsif ($method =~ /squashfs/) {
       my $flags;
       if ($arch =~ /x86/) {
          $flags="-le";
       } elsif ($arch =~ /ppc/) {
          $flags="-be";
       }
       if (! -x "/sbin/mksquashfs") {
          $callback->({error=>["mksquashfs not found, squashfs-tools rpm should be installed on the management node"],errorcode=>[1]});
          return;
       }
       my $rc = system("mksquashfs $temppath ../rootimg.sfs $flags");
       if ($rc) {
          $callback->({error=>["mksquashfs could not be run successfully"],errorcode=>[1]});
          return;
       }
       $rc = system("rm -rf $temppath");
       if ($rc) {
          $callback->({error=>["Failed to clean up temp space"],errorcode=>[1]});
          return;
       }
       chmod(0644,"../rootimg.sfs");
    }
    chdir($oldpath);
}

###########################################################
#
#  copybootscript - copy the xCAT diskless init scripts to the image
#
#############################################################
sub copybootscript {

    my $installroot  = shift;
    my $osver  = shift;
    my $arch = shift;
    my $profile = shift;
    my $callback = shift;


    if ( -f "$installroot/postscripts/xcatdsklspost") {

        # copy the xCAT diskless post script to the image
        mkpath("$installroot/netboot/$osver/$arch/$profile/rootimg/opt/xcat");  

        copy ("$installroot/postscripts/xcatdsklspost", "$installroot/netboot/$osver/$arch/$profile/rootimg/opt/xcat/xcatdsklspost");

        chmod(0755,"$installroot/netboot/$osver/$arch/$profile/rootimg/opt/xcat/xcatdsklspost");

    } else {

	my $rsp;
        push @{$rsp->{data}}, "Could not find the script $installroot/postscripts/xcatdsklspost.\n";
        xCAT::MsgUtils->message("E", $rsp, $callback);
        return 1;
    }
    if ( -f "$installroot/postscripts/xcatdsklspost.aix") {
       copy ("$installroot/postscripts/xcatdsklspost.aix", "$installroot/netboot/$osver/$arch/$profile/rootimg/opt/xcat/xcatdsklspost.aix");
       chmod(0755,"$installroot/netboot/$osver/$arch/$profile/rootimg/opt/xcat/xcatdsklspost.aix");
    }

	if ( -f "$installroot/postscripts/xcatpostinit") {

        # copy the linux diskless init script to the image
        #   - & set the permissions
        copy ("$installroot/postscripts/xcatpostinit","$installroot/netboot/$osver/$arch/$profile/rootimg/etc/init.d/xcatpostinit");

        chmod(0755,"$installroot/netboot/$osver/$arch/$profile/rootimg/etc/init.d/xcatpostinit");

        # run chkconfig
        #my $chkcmd = "chroot $installroot/netboot/$osver/$arch/$profile/rootimg chkconfig --add xcatpostinit";
        symlink "/etc/init.d/xcatpostinit","$installroot/netboot/$osver/$arch/$profile/rootimg/etc/rc3.d/S84xcatpostinit";
        symlink "/etc/init.d/xcatpostinit","$installroot/netboot/$osver/$arch/$profile/rootimg/etc/rc4.d/S84xcatpostinit";
        symlink "/etc/init.d/xcatpostinit","$installroot/netboot/$osver/$arch/$profile/rootimg/etc/rc5.d/S84xcatpostinit";
        #my $rc = system($chkcmd);
        #if ($rc) {
		#my $rsp;
      #  	push @{$rsp->{data}}, "Could not run the chkconfig command.\n";
      #  	xCAT::MsgUtils->message("E", $rsp, $callback);
      #      	return 1;
      #  }
    } else {
	my $rsp;
        push @{$rsp->{data}}, "Could not find the script $installroot/postscripts/xcatpostinit.\n";
        xCAT::MsgUtils->message("E", $rsp, $callback);
        return 1;
    }
	return 0;
}

