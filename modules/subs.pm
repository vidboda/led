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
	#print $q->start_div({'id' => 'page'}), $q->start_div({'id' => 'fixtop'}), $q->end_div(), $q->br(), $q->br(), $q->br(),
	#$q->start_div({'id' => 'internal'});
	print $q->start_div({'id' => 'page', 'class' => 'w3-large'}), $q->start_div({'class' => 'w3-top', 'style' => 'z-index:1002'}),
		$q->start_div({'id' => 'scroll', 'class' => 'w3-white w3-opacity-min'}),
			$q->start_div({'id' => 'scroll-bar', 'class' => 'w3-blue', 'style' => 'height:4px;width:0%'}), $q->end_div(),
		$q->end_div(),
		$q->start_div({'id' => 'myNavbar', 'class' => 'w3-bar w3-card-2 w3-black w3-opacity-min'}),
			$q->start_a({'class' => 'w3-button w3-black', 'href' => '/led/'}), $q->start_i({'class' => 'fa fa-home w3-xxlarge'}), $q->end_i(), $q->end_a(),
			$q->start_a({'class' => 'w3-button w3-black', 'href' => '/perl/led/engine.pl?patients=1'}), $q->start_i({'class' => 'fa fa-stethoscope w3-xxlarge'}), $q->end_i(), $q->end_a(),
		$q->end_div(),
		#$q->a({'class' => 'w3-bar-item w3-button w3-xlarge', 'href' => '/led/'}, 'Home'),
		#$q->a({'class' => 'w3-bar-item w3-button w3-xlarge', 'href' => '/perl/led/engine.pl?patients=1'}, 'Patients'),
		$q->end_div(), $q->br(), $q->br(),
		$q->start_div({'id' => 'internal'}), $q->br();
}

sub standard_end_html { #prints bottom of the pages
	my ($q) = shift;
	#ends main div and prints fix_bot.html , 'src' => $HTDOCS_PATH.'fix_bot.html'
	#print $q->start_div({'id' => 'fixbot'}), $q->end_div(), $q->br(), $q->br(), $q->br(), $q->br(), $q->br(), $q->end_div();
	#<form action = "/perl/led/engine.pl" id = "search_form"><div class="w3-row"><div class="w3-half w3-right-align"><input type = "text" class="w3-input w3-border w3-large" name = "research" id = "engine" size = "30" style="width:200px;display:inline;" maxlength = "40" placeholder = " Ask LED:" autofocus = "autofocus" /></div><div class="w3-quarter"><input type = "submit" id = "submit_a" value = "Submit" class="w3-button w3-white w3-large w3-border"/></div></div></form> 
	#print $q->end_div(), $q->br(), $q->start_div({'class' => 'w3-container w3-center'}),
	#	$q->start_form({'id' => ''}),
	#	$q->end_div(), $q->br(), $q->br(), $q->br(), $q->br(), $q->br(), $q->end_div();
	print $q->end_div(), $q->br(), $q->start_div({'id' => 'fixbot', 'class' => 'w3-container w3-center'}), $q->end_div(), $q->br(), $q->br(), $q->br(), $q->br(), $q->br(), $q->end_div();
}

#sub to display info panel

sub info_panel {
	my ($text, $q) = @_;
	return $q->start_div({'class' => 'w3-margin w3-panel w3-sand w3-leftbar w3-display-container'}).$q->span({'onclick' => 'this.parentElement.style.display=\'none\'', 'class' => 'w3-button w3-display-topright w3-large'}, 'X').$q->p($text).$q->end_div()."\n";
}

sub mini_info_panel {
	my ($text, $q) = @_;
	return $q->start_div({'class' => 'w3-margin w3-panel w3-sand w3-leftbar'}).$q->p($text).$q->end_div()."\n";
}

sub danger_panel {
	my ($text, $q) = @_;
	return $q->start_div({'class' => 'w3-margin w3-panel w3-pale-red w3-leftbar w3-display-container'}).$q->span({'onclick' => 'this.parentElement.style.display=\'none\'', 'class' => 'w3-button w3-display-topright w3-large'}, 'X').$q->start_p().$q->strong($text).$q->end_p().$q->end_div()."\n";
}