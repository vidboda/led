package modules::subs;

use URI::Encode qw(uri_encode uri_decode);
use strict;
use warnings;
use modules::init;


my $config_file = modules::init->getConfFile();
my $config = modules::init->initConfig();
$config->file($config_file);# or die $!;
my $HTDOCS_PATH = $config->HTDOCS_PATH();

# HTML subs

sub standard_begin_html { #prints top of the pages
	my ($q) = @_;
	#prints fix_top.html in one div and starts main div , 'src' => $HTDOCS_PATH.'fix_top.shtml'
	print $q->start_div({'id' => 'page'}), $q->start_div({'id' => 'fixtop'}), $q->end_div(), $q->br(), $q->br(), $q->br(),
	$q->start_div({'id' => 'internal'});#, $q->p({'id' => 'log'}, 'logged in as ');#, $q->start_a({'href' => '#bottom', 'class' => 'print_hidden'}), $q->img({'src' => $HTDOCS_PATH.'data/img/buttons/bottom_arrow.png', 'width' => '23', 'height' => '34', 'border' => '0'}), $q->strong('Go to bottom'), $q->end_a(), $q->br();
}

sub standard_end_html { #prints bottom of the pages
	my ($q) = shift;
	#ends main div and prints fix_bot.html , 'src' => $HTDOCS_PATH.'fix_bot.html'
	print $q->end_div(), $q->br(); #$q->start_div({'id' => 'bottom', 'align' => 'right', 'class' => 'print_hidden'}), $q->start_a({'href' => '#page'}), $q->img({'src' => $HTDOCS_PATH.'data/img/buttons/top_arrow.png', 'width' => '23', 'height' => '34', 'border' => '0'}), $q->strong('Go to top'), $q->end_a(), $q->end_div(), "\n",
	print $q->start_div({'id' => 'fixbot'}), $q->end_div(), $q->br(), $q->br(), $q->br(), $q->br(), $q->br(), $q->end_div();
}