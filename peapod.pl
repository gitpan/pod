#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

use Tk;

use Tk::PeaPod;

my $top = MainWindow->new();

#alpha
 #bravp
#charlie
	#delta
#echo


my $text_frame = $top->Frame->pack
	(-anchor=>'nw', expand=>'yes', -fill => 'both'); # autosizing
my $counter_frame = $top->Frame->pack(-anchor=>'nw');

##############################################
##############################################
## now set up text window with contents.
##############################################
##############################################

## autosizing is set up such that when the outside window is 
## resized, the text box adjusts to fill everything else in.
## the text frame and the text window in the frame are both 
## set up for autosizing.

my $textwindow = $text_frame->Scrolled(
	'PeaPod',
	exportselection => 'true',  # 'sel' tag is associated with selections
	# initial height, if it isnt 1, then autosizing fails 
	# once window shrinks below height
	# and the line counters go off the screen.
	# seems to be a problem with the Tk::pack command;
	height => 1, 	 
	-background => 'white',
	-wrap=> 'word', 
	-setgrid => 'true', # use this for autosizing
	-scrollbars =>'se')
	-> pack(-expand => 'yes' , -fill => 'both');	# autosizing



##############################################
# set the window to a normal size and set the minimum size
$top->minsize(30,1);
$top->geometry("80x24");



##############################################

{
	local $/;
	my $string = <>;
	$textwindow->podview($string);
}


MainLoop();






