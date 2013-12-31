# See bottom of file for default license and copyright information

=begin TML

---+ package FortunePlugin

Fortune Plugin will run either the Unix fortune_mod program "fortune" to access
the traditional fortune database, or alternatively will use the CPAN Fortune
module to access fortunes.

=cut

package Foswiki::Plugins::FortunePlugin;

# Always use strict to enforce variable scoping
use strict;

require File::Spec;
require Foswiki::Func;       # The plugins API
require Foswiki::Plugins;    # For the API version

our $VERSION = '1.0';
our $RELEASE = '1.0';

# Short description of this plugin
# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
our $SHORTDESCRIPTION =
  'Fortune Plugin - Displays a random fortune from Unix/Linux fortune file';

our $NO_PREFS_IN_TOPIC = 1;

my $fortune_db;
my $fdb_vol;
my $fdb_path;
my $fortune_bin;

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin topic is in
     (usually the same as =$Foswiki::cfg{SystemWebName}=)

=cut

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeDebug( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    $fortune_bin = $Foswiki::cfg{Plugins}{FortunePlugin}{FortuneProgram}
      || "";    # If not set, use Perl Fortune from CPAN

    unless ($fortune_bin) {
        eval "require Fortune";
        if ($@) {
            Foswiki::Func::writeDebug(
'Perl CPAN module \"Fortune\" could not be found and FortuneProgram not set in LocalSite.cfg - assuming fortune in path'
            );
            $fortune_bin = 'fortune';
        }
    }

    my $fdb;
    if ( $Foswiki::cfg{Plugins}{FortunePlugin}{FortuneDBPath} ) {
        $fdb = $Foswiki::cfg{Plugins}{FortunePlugin}{FortuneDBPath};
    }
    else {
        $fdb =
            Foswiki::Func::getPubDir()
          . "/$Foswiki::cfg{SystemWebName}"
          . "/FortunePlugin/";
    }

    ( $fdb_vol, $fdb_path, ) = File::Spec->splitpath( $fdb, 1 );
    $fdb = File::Spec->catpath( $fdb_vol, $fdb_path, '' );

    Foswiki::Func::writeDebug("FortuneDBPath set to $fdb ");

    if ( $fdb && !( -d $fdb ) ) {
        Foswiki::Func::writeDebug("provided FortuneDBPath ($fdb) not found ");
        return 0;
    }

    Foswiki::Func::registerTagHandler( 'FORTUNE',         \&_FORTUNE );
    Foswiki::Func::registerTagHandler( 'FORTUNE_LIST',    \&_FORTUNE_LIST );
    Foswiki::Func::registerTagHandler( 'FORTUNE_DB_LIST', \&_FORTUNE_DB_LIST );

    # Plugin correctly initialized
    return 1;
}

=begin TML

---++ _FORTUNE
Primary macro for the FortunePlugin.  Returns a single random fortune
from a random database. 

  %<nop>FORTUNE{}%
  %<nop<FORTUNE{"foswiki"}%

=cut

sub _FORTUNE {
    my ( $session, $params, $theTopic, $theWeb ) = @_;

    my $db  = $params->{_DEFAULT} || "foswiki";
    my $len = $params->{LENGTH}   || "";

    if ($len) {
        if ( $len =~ m/^(SHORT|S)$/o ) {
            $len = "-s";
        }
        else {
            if ( $len =~ m/^(LONG|L)$/o ) {
                $len = "-l";
            }
            else {
                return
"<font color=\"red\"><nop>Fortune Error: Length paremater must be SHORT, LONG, S or L. (was: $len)</font>";
            }
        }
    }

    my $fdb = File::Spec->catpath( $fdb_vol, $fdb_path, $db );

    unless ( -f $fdb ) {
        return
          "<span class=\"foswikiAlert\">Fortune database $db not found</span>";
    }

    if ($fortune_bin) {
        my ( $output, $exit ) =
          Foswiki::Sandbox->sysCommand( "$fortune_bin %DATABASE|U% $len ",
            DATABASE => "$fdb" );
        Foswiki::Func::writeDebug("$fortune_bin Length $len Database ^$fdb^");
        return $output;
    }
    else {
        my $ffile = undef;
        eval { $ffile = new Fortune($fdb); };
        if ($@) {
            return " *Error - Problem handling processing $db* \n";
        }
        $ffile->read_header();
        return ( $ffile->get_random_fortune() );
    }

}

=begin TML

---++ _FORTUNE_LIST
Returns a formatted list of the fortunes from the specified database.
Requires a single parameter of the database to list.

 %<nop>FORTUNE_LIST{"scifi"}%

Implementation:

Unix =fortune= - issue =fortune -m . database=  (List fortunes matching regular expression)

Perl Fortune - Get fortune count and loop through database listing fortunes

=cut

sub _FORTUNE_LIST {
    my ( $session, $params, $theTopic, $theWeb ) = @_;

    my $db = $params->{_DEFAULT} || "foswiki";
    my $fdb = File::Spec->catpath( $fdb_vol, $fdb_path, $db );

    unless ( -f $fdb ) {
        return
          "<span class=\"foswikiAlert\">Fortune database $db not found</span>";
    }

    if ($fortune_bin) {
        my ( $output, $exit ) =
          Foswiki::Sandbox->sysCommand( "$fortune_bin -m .*  %DATABASE|F% ",
            DATABASE => "$fdb" );
        Foswiki::Func::writeDebug("$fortune_bin -m '.*' Database ^$fdb^");
        $output =~ s/\n/<br \/>/g;                # Newlines become breaks
        $output =~ s/<br \/>%<br \/>/\n<li>/g;    # Percents become list entries
        $output =~ s/<li>$//g;                    # Remove trailing entry
        return "<ul><li>" . $output . "\n </ul>\n";
    }
    else {
        my $ffile = undef;
        eval { $ffile = new Fortune("$fdb"); };
        if ($@) {
            return " *Error - Problem handling $fdb* \n";
        }
        $ffile->read_header();
        my $num_fortunes = $ffile->num_fortunes();
        &Foswiki::Func::writeDebug(
            "FortunePlugin  - " . $num_fortunes . $fdb );
        my $output = "<ul>";
        for ( my $i = 0 ; $i < $num_fortunes ; $i++ ) {
            &Foswiki::Func::writeDebug(
                "FortunePlugin  - " . $i . " = " . $ffile->read_fortune($i) );
            $output .= "<li> " . $ffile->read_fortune($i);
        }
        $output .= "\n</ul>\n";
        return $output;
    }

}

=begin TML

---++ _FORTUNE_DB_LIST
Returns a formatted list of the fortune files found in the path specfied
in the configuration file. No parameters supported.

 %<nop>FORTUNE_DB_LIST{}%

Uses perl functions to list the =.dat= files in the fortune database directory.

For each file, either use fortune -m . , and count % delimiters,  or use Fortune module
to count the number of fortunes in the file.

=cut

sub _FORTUNE_DB_LIST {
    my ( $session, $params, $theTopic, $theWeb ) = @_;

  #SMELL:  "fortune -f" sends the results to stderr.  So Sandbox cannot be used.

    my $fdb = File::Spec->catpath( $fdb_vol, $fdb_path, '' );

    my $output = undef;
    if ($fortune_bin) {
        $output = `$fortune_bin -f $fdb 2>&1`;
        $output =~ s/^100.*+$//m
          ;   #Remove the file path statement.  Don't reveal system information.
        return "<pre>" . $output . "\n </pre>\n";
    }
    else {
        opendir( DIR, $fdb )
          || die "<ERR> Can't find directory --> $fdb !";
        my @fdbs = grep { /\.dat$/ } readdir(DIR);
        @fdbs   = sort (@fdbs);
        $output = "\n| *Fortune Count* | *Database Name* |\n";
        foreach my $f (@fdbs) {
            $f = substr( $f, 0, -4 );
            my $fn = File::Spec->catpath( $fdb_vol, $fdb_path, $f );
            my $ffile = undef;
            eval { $ffile = new Fortune("$fn"); };
            if ($@) {
                return " *Error - Problem handling $fn\n";
            }
            $ffile->read_header();
            $output .= "| " . $ffile->num_fortunes() . " | " . $f . " |\n";
        }
        $output .= "\n</ul>\n";
        return $output;
    }
}

1;
__END__
This copyright information applies to the FortunePlugin:

# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# FortunePlugin is Copyright (C) 2008, 2013 Foswiki Contributors.
#
# Foswiki Contributors
# are listed in the AUTHORS file in the root of this distribution.
# NOTE: Please extend that file, not this notice.
# Additional copyrights apply to some or all of the code as follows:
# Copyright (C) 2000-2003 Andrea Sterbini, a.sterbini@flashnet.it
# Copyright (C) 2001-2006 Peter Thoeny, peter@thoeny.org
# and TWiki Contributors. All Rights Reserved. Foswiki Contributors
# are listed in the AUTHORS file in the root of this distribution.
#
# This license applies to FortunePlugin *and also to any derivatives*
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# For licensing info read LICENSE file in the Foswiki root.
