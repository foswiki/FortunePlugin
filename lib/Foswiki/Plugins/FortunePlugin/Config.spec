# ---+ Extensions
# ---++ FortunePlugin
# Settings for the Fortune interface.  Generates fortunes using the Unix/Linux "fortune" program
# or the Perl "Fortune" CPAN module.
# **PATH O**
# Complete path to the Fortune database files.  (Must include trailing slash). 
# If not set, the plugin will use files attached to the System/FortunePlugin topic.
$Foswiki::cfg{Plugins}{FortunePlugin}{FortuneDBPath} = '';
# **PATH O**
# Fully specified Fortune executable. 
# If left blank, plugin will attempt to load the Perl "Fortune" module.  If the Perl "Fortune" module
# is not available, the plugin will attempt to use any fortune program found on the path.
$Foswiki::cfg{Plugins}{FortunePlugin}{FortuneProgram} = '';
