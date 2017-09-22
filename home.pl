BEGIN {delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV', 'PATH'};}

use strict;

use modules::init;
use modules::subs;

#    This program is part of LED,
#    Copyright (C) 2016  David Baux
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


##Basic init of LED perl scripts:
#	env variables
#	get config infos
#	initialize DB connection
#	initialize HTML (change page title if needed, as well as CSS files and JS)
#	Load standard JS, CSS and fixed html
#	identify users
#	just copy at the beginning of each script

$CGI::POST_MAX = 1024; #* 100;  # max 1K posts
$CGI::DISABLE_UPLOADS = 1;



my $config_file = modules::init->getConfFile();
my $config = modules::init->initConfig();
$config->file($config_file);# or die $!;
my $DB = $config->DB();
my $HOST = $config->HOST();
my $DB_USER = $config->DB_USER();
my $DB_PASSWORD = $config->DB_PASSWORD();
my $CSS_PATH = $config->CSS_PATH();
my $CSS_DEFAULT = $config->CSS_DEFAULT();
my $JS_PATH = $config->JS_PATH();
my $JS_DEFAULT = $config->JS_DEFAULT();
my $HTDOCS_PATH = $config->HTDOCS_PATH();

my @styles = ($CSS_DEFAULT, $CSS_PATH.'fullsize/fullsize.css', $CSS_PATH.'jquery.alerts.css');

my $q = new CGI;

my $dbh = DBI->connect(    "DBI:Pg:database=$DB;host=$HOST;",
                        $DB_USER,
                        $DB_PASSWORD,
                        {'RaiseError' => 1}
                ) or die $DBI::errstr;


print $q->header(-type => 'text/html', -'cache-control' => 'no-cache'),
	$q->start_html(-title=>"LED: LmgExomeDb",
                        -lang => 'en',
                        -style => {-src => \@styles},
                        -head => [
				$q->Link({-rel => 'icon',
					-type => 'image/png',
					-href => $HTDOCS_PATH.'data/img/favicon.ico'}),
				$q->Link({-rel => 'search',
					-type => 'application/opensearchdescription+xml',
					-title => 'LED search engine',
					-href => $HTDOCS_PATH.'ledbrowserengine.xml'}),
				$q->meta({-http_equiv => 'Cache-control',
					-content => 'no-cache'}),
				$q->meta({-http_equiv => 'Pragma',
					-content => 'no-cache'}),
				$q->meta({-http_equiv => 'Expires',
					-content => '0'})],
                        -script => [{-language => 'javascript',
                                -src => $JS_PATH.'jquery-1.7.2.min.js', 'defer' => 'defer'},
				{-language => 'javascript',
                                -src => $JS_PATH.'jquery.fullsize.pack.js', 'defer' => 'defer'},
				{-language => 'javascript',
				-src => $JS_PATH.'jquery.validate.min.js', 'defer' => 'defer'},
				{-language => 'javascript',
				-src => $JS_PATH.'jquery.alerts.js', 'defer' => 'defer'},
                                {-language => 'javascript',
                                -src => $JS_DEFAULT, 'defer' => 'defer'}],		
                        -encoding => 'ISO-8859-1');

#my $user = U2_modules::U2_users_1->new();


modules::subs::standard_begin_html($q);

##end of Basic init


#1st query to the database - basic statistics

my $query = "SELECT COUNT(id) as a, COUNT(DISTINCT(dbsnp_rs)) as b FROM Variant;";
my $res = $dbh->selectrow_hashref($query);

$query = "SELECT COUNT(variant_id) as a FROM Variant2Patient;";
my $res_var = $dbh->selectrow_hashref($query);

#my $user = users->new();

print $q->br(), $q->start_div({'align' => 'center'}), $q->start_p(), $q->start_big(), $q->span('Welcome to LED, the Lmg Exome Database.'), $q->br(), $q->br(), $q->span("The system currently records $res->{'a'} different (unique) variants of which $res->{'b'} are linked to dbSNP (".sprintf('%.2f',($res->{'b'}/$res->{'a'})*100)."%) and corresponding to $res_var->{'a'} cumulated variants."), $q->end_big(), $q->end_p(), "\n";#,
#	$q->p("You ".$user->isAnalystToString()." and ".$user->isValidatorToString()." and ".$user->isRefereeToString()), "\n";

$query = "SELECT COUNT(id) as a FROM patient;";
$res = $dbh->selectrow_hashref($query);

print $q->start_p(), $q->start_big(), $q->span("These variants are related to $res->{'a'} patients with the pathologies and experiment types shown below:"), $q->end_big(), $q->end_p(),"\n";

#$query = "SELECT COUNT(id) as a, disease_name FROM Patient GROUP BY disease_name;";
print $q->start_table({'class' => 'zero_table'}), $q->start_Tr(), $q->start_td(),"\n";

&table('Diseases', 'SELECT COUNT(id) as a, disease_name FROM Patient GROUP BY disease_name;', 'disease_name');
print $q->end_td(), $q->start_td(),"\n";
#SELECT COUNT(DISTINCT patient_id) as a, experiment_type FROM Variant2patient GROUP BY experiment_type; old school
&table('Experiments', 'SELECT COUNT(DISTINCT patient_id) as a, experiment_type FROM Patient GROUP BY experiment_type;', 'experiment_type');
print $q->end_td(), $q->end_Tr(), $q->end_table(),$q->br(),"\n",
	$q->start_div(),"\n",
	$q->span('Example research for search engine:'), 
		$q->start_ul({'id' => 'example'}),
			$q->li('\'hg19:chr1:977330\' or'),
			$q->li('\'19:1:977330\' or'),
			$q->li('\'hg19:chr11:76,839,310-76,926,286\' (UCSC style, but do not forget hg19!), or'),
			$q->li('\'19:11:76839310-76926286\' or'),
			$q->li('\'MYO7A\' (HGNC gene name) or'),
			$q->li('\'MYO7A:A1060\' (HGNC gene name:sampleID, do not forget : between gene and sample!) '),
		$q->end_ul(),
	$q->end_div(),"\n",
	$q->end_div(), "\n",
	$q->start_div({'align' => 'center'}), "\n",
		$q->start_form({'action' => '/perl/led/engine.pl', 'id' => 'engine_form'}), "\n",
			$q->label({'for' => 'main_engine'}),
			$q->input({'type' => 'text', 'name' => 'research', 'id' => 'main_engine', 'size' => '50', 'maxlength' => '40', 'placeholder' => ' Ask LED:', 'autofocus' => 'autofocus', 'class' => 'big_cadre'}), "\n", $q->br(), $q->br(), $q->br(),
			$q->submit({'value' => 'Submit', 'class' => 'gras'}),
		$q->end_form(), "\n",
	$q->end_div(), "\n",
	#$q->br(), $q->br(), $q->start_div({'id' => 'farside', 'class' => 'appear center'}), $q->end_div(), "\n",
	$q->br(), $q->br(), $q->start_div({'align' => 'center'}),
		$q->img({'width' => '200', 'height' => '150', 'src' => $HTDOCS_PATH.'data/img/led_logo.png'}), "\n", $q->br(), $q->span("Logo by Kevin Yauy."),
	$q->end_div(),"\n",
	$q->br(), $q->br(),
	$q->start_div({'align' => 'center'}),
		$q->start_a({'href' => 'http://perl.apache.org/', 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/mod_perl.png', 'width' => '100', 'height' => '20'}), $q->end_a(),
		$q->span('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'),
		$q->start_a({'href' => 'http://www.postgresql.org/', 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/Postgresql.gif', 'width' => '75', 'height' => '50'}), $q->end_a(),
		$q->span('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'),
		$q->start_a({'href' => 'http://httpd.apache.org/docs/2.2/mod/mod_ssl.html', 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/mod_ssl.jpg', 'width' => '62', 'height' => '30'}), $q->end_a(),
	$q->end_div();


##Basic end of lmg_ex perl scripts:

modules::subs::standard_end_html($q);

print $q->end_html();

exit();

##End of Basic end

##specific subs

sub table {
	my ($caption, $query, $data) = @_;
	my $sth = $dbh->prepare($query);
	$res = $sth->execute();
	print $q->br(), $q->start_div({'class' => 'in_line'}), $q->start_table({'class' => 'technical great_table'}), $q->caption($caption),
			$q->start_Tr(), "\n",
				$q->th({'class' => 'left_general'}, $caption), "\n",
				$q->th({'class' => 'left_general'}, 'Number of samples'), "\n",
			$q->end_Tr(), "\n";
	
	while (my $result = $sth->fetchrow_hashref()) {
		print $q->start_Tr(), "\n",
			$q->td($result->{$data}), $q->td($result->{'a'}), "\n",
			$q->end_Tr(), "\n";
	}
	print $q->end_table(), $q->end_div(), "\n";
}

