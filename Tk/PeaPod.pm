

require 5;

#######################################################################
#######################################################################
package Tk::PeaPod::Parser;
#######################################################################
#######################################################################

use strict;
use warnings;
use Data::Dumper;

use base Pod::Simple;

#######################################################################

my %start_new_line_for_element =
	(
	head => 1,
	for => 1,
	Document => 1,
	Para => 1,
	Verbatim => 1,

	'over_bullet' => 0,
	'item_bullet' => 1,

	'over_text' => 0,
	'item_text' => 1,

	'I' => 0,
	'B' => 0,
	'C' => 0,

	);

#######################################################################
sub new
{
 my ($class) = @_;
 my $parser = $class->SUPER::new();
 $parser->{_marker_counts}={};
 return $parser;
}

#######################################################################
sub next_marker
{
	my ($parser, $key)= @_ ;

	my $cnt = $parser->{_marker_counts}->{$key}++;
	my $marker = $key .'_'. $cnt;
	return $marker;
}



#######################################################################

sub _handle_text 
{
	my $parser = shift(@_);
	my $text = shift( @_ );
	my $tag = $parser->CurrentTag;
	my $font = $parser->CurrentFont;

	$parser->{_widget}->insert('insert', $text, $font);
	$parser->{_widget}->tagAdd($tag, 'insert linestart', 'insert lineend');

}

#######################################################################
sub CurrentTag
{
	my $parser = shift(@_);
	$parser->{_current_tag}=shift if(scalar(@_));
	return $parser->{_current_tag};
	
}

#######################################################################
sub CurrentFont
{
	my $parser=shift(@_);
	my $href =  $parser->{_current_font}->[-1];

	my $family = $href->{family};
	my $size   = $href->{size};
	my $weight = $href->{weight};
	my $slant  = $href->{slant};

	my $font = $family.$size.$weight.$slant;
	return $font;
}

#######################################################################
sub ColumnTracking
{
	my $parser=shift(@_);
	my ($startend , $element, $attrs)=@_;

	$parser->{_column_indent}=0 unless(exists($parser->{_column_indent}));

	if($startend eq 'start')
		{
		if(exists($attrs->{indent}))
			{
			$parser->{_column_indent} += $attrs->{indent};
			}
		push(@{$parser->{_indentable_attributes}}, $attrs);
		}

	elsif( ($startend eq 'end') )
		{
		my $popattrs = pop(@{$parser->{_indentable_attributes}});
		if(exists($popattrs->{indent}))
			{
			$parser->{_column_indent} -= $popattrs->{indent};
			}

		}

	my $col = $parser->{_column_indent};

	$parser->CurrentTag('Column'.$col);

}


#######################################################################
sub FontTracking
{
	my $parser=shift(@_);
	my ($startend , $element, $attrs)=@_;

	unless(exists($parser->{_current_font}))
		{
			$parser->{_current_font}=
			[
				{
				family => 'lucida',	# lucida, courier
				size => 10,		# 10, 12, 18, 24
				weight => 'normal',	# normal, bold
				slant => 'roman', 	# roman, italic
				}
			];
		}
	

	if($startend eq 'start')
		{
		my $href = $parser->{_current_font}->[-1];

		my %newhash = map { ( $_, $href->{$_} ) } keys(%$href);

		if(0) {}
		elsif($element eq 'C')
			{ 
			$newhash{family}='courier';
			}
		elsif($element eq 'head')
			{ 
			my $hindex = $attrs->{_head_index};
			if(0) {}
			if($hindex eq '1')
				{
				$newhash{size}='18';
				$newhash{weight}='bold';
				}
			if($hindex eq '2')
				{
				$newhash{size}='12';
				$newhash{weight}='bold';
				}

			}
		elsif($element eq 'I')
			{ 
			$newhash{slant}='italic';
			}
		elsif($element eq 'B')
			{ 
			$newhash{weight}='bold';
			}

		push(@{$parser->{_current_font}}, \%newhash);
		}
	elsif($startend eq 'end')
		{
		pop(@{$parser->{_current_font}});
		}
	
}


#######################################################################
sub _handle_element_start_and_end
{
	my $parser = shift(@_);

	my $startend = shift(@_);
	my $element= shift(@_);
	$element =~ s{\W}{_}g;
	my $attrs = shift(@_);

	my $mark = $parser->next_marker($startend .'_'.$element);

	if(0) {}
	elsif($element =~ s{head(\d+)}{head})
		{
		$attrs->{'_head_index'}=$1;
		}

	my $method = $startend .'_'.$element;

	unless(exists($start_new_line_for_element{$element}))
		{
		die "Error: unknown element type '$element'";
		}

	if($start_new_line_for_element{$element})
		{
		$parser->{_widget}->insert('insert',"\n");
		}

	$parser->{_widget}->markSet($mark, 'insert');
	$parser->{_widget}->markGravity($mark, 'left');

 	$parser->ColumnTracking($startend , $element, $attrs);
 	$parser->FontTracking  ($startend , $element, $attrs);

	if($parser->can($method))
		{
		$parser->$method($attrs);
		}
}


#######################################################################
# these are methods called by the parser, intercept them here
# and send text to widget.
#######################################################################
sub _handle_element_start
{
	my $parser = shift(@_);

	$parser->_handle_element_start_and_end('start', @_);
}

#######################################################################
# these are methods called by the parser, intercept them here
# and send text to widget.
#######################################################################
sub _handle_element_end
{
	my $parser = shift(@_);
	push(@_, {} );
	$parser->_handle_element_start_and_end('end', @_);
}



#######################################################################
sub start_item_bullet
{
	my $parser=shift(@_);
	my $attrs=shift(@_);
	my $bullet_string = $attrs->{'~orig_content'};
	$bullet_string .= ' ';
	$parser->{_widget}->insert('insert', $bullet_string );

}

#######################################################################
#######################################################################
package Tk::PeaPod;
#######################################################################
#######################################################################

use strict;
use warnings;
use Data::Dumper;

use vars qw($VERSION);
$VERSION = '0.001'; 

use Tk qw (Ev);

use  Pod::Simple::Methody;
use base qw(Tk::TextUndo);

Construct Tk::Widget 'PeaPod';

#######################################################################
#######################################################################
sub ClassInit
{
 my ($class,$mw) = @_;
 $class->SUPER::ClassInit($mw);

 $mw->bind($class,'<F1>', 'DumpMarks'); 
 $mw->bind($class,'<F2>', 'DumpTags'); 
 $mw->bind($class,'<F3>', 'DumpCursor'); 

}

#######################################################################
#######################################################################
sub InitObject
{
 my ($w) = @_;
 $w->SUPER::InitObject;

 my $parser = Tk::PeaPod::Parser->new();
 $w->{_parser}= $parser;
 $parser->{_widget}=$w;

 for(my $i=0; $i<100; $i++)
	{
	 $w->tagConfigure
		(
			'Column'.$i,
 			-lmargin1 => $i*8,
			-lmargin2 => $i*8,
		);
	}

# family=>  garamond, courier
# size 	=>  10, 12, 16, 18, 24
# weight=>  normal, bold
# slant =>  roman, italic
	
for my $family qw(lucida courier)
	{
	for my $size qw (6 8 10 12 14 16 18 20 22 24)
		{
		for my $weight qw(normal bold)
			{
			for my $slant qw(roman italic)
				{
				$w->tagConfigure 
					(
					$family.$size.$weight.$slant,
					-font =>
						[
						-family=>$family,
						-size  =>$size,
						-weight=>$weight,
						-slant =>$slant,
						]
					);
				}
			}
		}
	}

}

#######################################################################
#######################################################################

sub podview
{
	my ($widget, $string)=@_;

	$widget->{_parser}->parse_string_document($string);
}


sub DumpMarks
{
	my ($widget)=@_;

	my @marknames = $widget->markNames;

	foreach my $markname (sort(@marknames))
		{
		my $index = $widget->index($markname);
		my ($ln, $col)=split(/[.]/, $index);

		my $string = sprintf("% 10u\.% 6u", $ln, $col) . "  $markname\n";
		print $string;
		}

}


sub DumpTags
{
	my ($widget)=@_;

	my @tagname = $widget->tagNames;

	foreach my $tag (@tagname)
		{
		my @indexes = $widget->tagRanges($tag);
		next unless(scalar(@indexes));
		print "\n\n";
		print "tag name '$tag'\n";
		for(my $i=0; $i<scalar(@indexes); $i=$i+2)
			{
			my $start = $indexes[$i];
			my $end   = $indexes[$i+1];
			print "\t $start $end \n";
			}
		}
}


sub DumpCursor
{
	my ($widget)=@_;

	my @tagname = $widget->tagNames('insert');
	print "\n\n";

	foreach my $tag (@tagname)
		{
		my @indexes = $widget->tagRanges($tag);
		next unless(scalar(@indexes));
		#print "\n\n";
		print "tag name '$tag'\n";
		for(my $i=0; $i<scalar(@indexes); $i=$i+2)
			{
			my $start = $indexes[$i];
			my $end   = $indexes[$i+1];
		#	print "\t $start $end \n";
			}
		}
}




1;











