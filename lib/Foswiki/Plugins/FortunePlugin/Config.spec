# ---+ Extensions
# ---++ FortunePlugin
# Settings for the Fortune interface.  Generates fortunes using the Unix/Linux "fortune" program
# if supplied.   If left empty, the CPAN "Fortune" module will be required.
# **PATH O**
# Complete path to the Fortune database files.  (Must include trailing slash). 
# If left blank, plugin will use files attached to the System/FortunePlugin topic.
$Foswiki::cfg{Plugins}{FortunePlugin}{FortuneDBPath} = '';
# **PATH O**
# Fully specified Fortune executable. 
# If left blank, plugin will attempt to load the Perl "Fortune" module.
$Foswiki::cfg{Plugins}{FortunePlugin}{FortuneProgram} = '';

