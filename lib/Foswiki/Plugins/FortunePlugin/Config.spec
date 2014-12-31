# ---+ Extensions
# ---++ FortunePlugin
# Settings for the Fortune interface.  Generates fortunes using the Unix/Linux "fortune" program
# or the Perl "Fortune" CPAN module.
# **PATH**
# Complete path to the Fortune database files.
# If not set, the plugin will use files attached to the System/FortunePlugin topic.
# The default location for the system fortune database files is <tt>/usr/share/fortune/</tt>
$Foswiki::cfg{Plugins}{FortunePlugin}{FortuneDBPath} = '';
# **PATH**
# Fully specified Fortune executable. 
# If left blank, plugin will attempt to load the Perl "Fortune" module.  If the Perl "Fortune" module
# is not available, the plugin will attempt to use any fortune program found on the path.   Typically
# the system fortune program installed by the <tt>fortune-mod</tt> package is <tt>/usr/bin/fortune</tt>.
$Foswiki::cfg{Plugins}{FortunePlugin}{FortuneProgram} = '';
1;
