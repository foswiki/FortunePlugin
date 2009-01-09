# See bottom of file for default license and copyright information

=begin TML

---+ package EmptyPlugin

Foswiki plugins 'listen' to events happening in the core by registering an
interest in those events. They do this by declaring 'plugin handlers'. These
are simply functions with a particular name that, if they exist in your
plugin, will be called by the core.

This is an empty Foswiki plugin. It is a fully defined plugin, but is
disabled by default in a Foswiki installation. Use it as a template
for your own plugins.

To interact with Foswiki use ONLY the official APIs
documented in %SYSTEMWEB%.DevelopingPlugins. <strong>Do not reference any
packages, functions or variables elsewhere in Foswiki</strong>, as these are
subject to change without prior warning, and your plugin may suddenly stop
working.

Error messages can be output using the =Foswiki::Func= =writeWarning= and
=writeDebug= functions. You can also =print STDERR=; the output will appear
in the webserver error log. Most handlers can also throw exceptions (e.g.
[[%SCRIPTURL{view}%/%SYSTEMWEB%/PerlDoc?module=Foswiki::OopsException][Foswiki::OopsException]])

For increased performance, all handler functions except =initPlugin= are
commented out below. *To enable a handler* remove the leading =#= from
each line of the function. For efficiency and clarity, you should
only uncomment handlers you actually use.

__NOTE:__ When developing a plugin it is important to remember that

Foswiki is tolerant of plugins that do not compile. In this case,
the failure will be silent but the plugin will not be available.
See %SYSTEMWEB%.InstalledPlugins for error messages.

__NOTE:__ Foswiki:Development.StepByStepRenderingOrder helps you decide which
rendering handler to use. When writing handlers, keep in mind that these may
be invoked

on included topics. For example, if a plugin generates links to the current
topic, these need to be generated before the =afterCommonTagsHandler= is run.
After that point in the rendering loop we have lost the information that
the text had been included from another topic.

=cut

# change the package name!!!
package Foswiki::Plugins::FortunePlugin;

# Always use strict to enforce variable scoping
use strict;

require Foswiki::Func;       # The plugins API
require Foswiki::Plugins;    # For the API version

# $VERSION is referred to by Foswiki, and is the only global variable that
# *must* exist in this package.
# This should always be $Rev$ so that Foswiki can determine the checked-in
# status of the plugin. It is used by the build automation tools, so
# you should leave it alone.
our $VERSION = '$Rev$';

# This is a free-form string you can use to "name" your own plugin version.
# It is *not* used by the build automation tools, but is reported as part
# of the version number in PLUGINDESCRIPTIONS.
our $RELEASE = '$Date$';

# Short description of this plugin
# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
our $SHORTDESCRIPTION =
  'Fortune Plugin - Displays a random fortune from Unix/Linux fortune file';

# You must set $NO_PREFS_IN_TOPIC to 0 if you want your plugin to use
# preferences set in the plugin topic. This is required for compatibility
# with older plugins, but imposes a significant performance penalty, and
# is not recommended. Instead, leave $NO_PREFS_IN_TOPIC at 1 and use
# =$Foswiki::cfg= entries set in =LocalSite.cfg=, or if you want the users
# to be able to change settings, then use standard Foswiki preferences that
# can be defined in your %USERSWEB%.SitePreferences and overridden at the web
# and topic level.
our $NO_PREFS_IN_TOPIC = 1;

use vars qw($fortune_db $fortune_bin);

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin topic is in
     (usually the same as =$Foswiki::cfg{SystemWebName}=)

*REQUIRED*

Called to initialise the plugin. If everything is OK, should return
a non-zero value. On non-fatal failure, should write a message
using =Foswiki::Func::writeWarning= and return 0. In this case
%<nop>FAILEDPLUGINS% will indicate which plugins failed.

In the case of a catastrophic failure that will prevent the whole
installation from working safely, this handler may use 'die', which
will be trapped and reported in the browser.

__Note:__ Please align macro names with the Plugin name, e.g. if
your Plugin is called !FooBarPlugin, name macros FOOBAR and/or
FOOBARSOMETHING. This avoids namespace issues.

=cut

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    # Example code of how to get a preference value, register a macro
    # handler and register a RESTHandler (remove code you do not need)

    # Set your per-installation plugin configuration in LocalSite.cfg,
    # like this:
    # $Foswiki::cfg{Plugins}{EmptyPlugin}{ExampleSetting} = 1;
    # Optional: See %SYSTEMWEB%.DevelopingPlugins#ConfigSpec for information
    # on integrating your plugin configuration with =configure=.

    $fortune_bin = $Foswiki::cfg{Plugins}{FortunePlugin}{FortuneProgram}
      || "";    # If not set, use Perl Fortune from CPAN

    unless ($fortune_bin) {
        eval "require Fortune";
        if ($@) {
            Foswiki::Func::writeWarning(
'Perl CPAN module \"Fortune\" could not be found and FortuneProgram not set in LocalSite.cfg'
            );
            return 0;
        }
    }

    $fortune_db = $Foswiki::cfg{Plugins}{FortunePlugin}{FortuneDBPath}
      || Foswiki::Func::getPubDir()
      . "/$Foswiki::cfg{SystemWebName}"
      . "/FortunePlugin";

    unless ( $fortune_db && ( -d $fortune_db ) ) {
        Foswiki::Func::writeWarning('FortuneDBPath not provided or not found ');
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

Optional parameters is a list of one or more databases to be used 
for the fortune.

  %<nop>FORTUNE{}%
  %<nop<FORTUNE{"foswiki,scifi"}%

=cut

sub _FORTUNE {
    my ( $session, $params, $theTopic, $theWeb ) = @_;

    my $db = $params->{_DEFAULT} || "foswiki";

    if ($fortune_bin) {
        my ( $output, $exit ) =
          Foswiki::Sandbox->sysCommand( "$fortune_bin %DATABASE|F% ",
            DATABASE => "$db" );
        return $output;
    }
    else {
        my $ffile = new Fortune( "$fortune_db" . "$db" );
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

    if ($fortune_bin) {
        my ( $output, $exit ) =
          Foswiki::Sandbox->sysCommand( "$fortune_bin -m .*  %DATABASE|F% ",
            DATABASE => "$db" );
       $output =~ s/\n/<br \/>/g;                                # Newlines become breaks
       $output =~ s/<br \/>%<br \/>/\n<li>/g;                    # Percents become list entries
       $output =~ s/<li>$//g;                         # Remove trailing entry
       return "<ul><li>" . $output . "\n </ul>\n";
    }
    else {
        my $ffile = new Fortune( "$fortune_db" . "$db" );
        $ffile->read_header();
        my $num_fortunes = $ffile->num_fortunes ();
        &Foswiki::Func::writeDebug( "FortunePlugin  - " . $num_fortunes  .  $fortune_db  .  $db );
        my $output = "<ul>";
        for (my $i = 0; $i < $num_fortunes; $i++) {
            &Foswiki::Func::writeDebug( "FortunePlugin  - " . $i . " = " . $ffile->read_fortune($i) );
            $output .= "<li>" . $ffile->read_fortune ($i) ; 
            }
        $output .= "\n</ul>\n";    
        return  $output ;
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

    if ($fortune_bin) {
       my $output = `$fortune_bin -f 2>&1`;
       return "<pre>" . $output . "\n </pre>\n";
    }

}

1;
__END__
This copyright information applies to the EmptyPlugin:

# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# EmptyPlugin is Copyright (C) 2008 Foswiki Contributors. Foswiki Contributors
# are listed in the AUTHORS file in the root of this distribution.
# NOTE: Please extend that file, not this notice.
# Additional copyrights apply to some or all of the code as follows:
# Copyright (C) 2000-2003 Andrea Sterbini, a.sterbini@flashnet.it
# Copyright (C) 2001-2006 Peter Thoeny, peter@thoeny.org
# and TWiki Contributors. All Rights Reserved. Foswiki Contributors
# are listed in the AUTHORS file in the root of this distribution.
#
# This license applies to EmptyPlugin *and also to any derivatives*
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
