BEGIN {delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV', 'PATH'};}

use strict;

use modules::init;
use modules::subs;
use LWP::UserAgent;

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
my $EXE_PATH = $config->EXE_PATH();
my $CSS_PATH = $config->CSS_PATH();
my $CSS_DEFAULT = $config->CSS_DEFAULT();
my $JS_PATH = $config->JS_PATH();
my $JS_DEFAULT = $config->JS_DEFAULT();
my $HTDOCS_PATH = $config->HTDOCS_PATH();
my $DALLIANCE_DATA_DIR_URI = $config->DALLIANCE_DATA_DIR_URI();

my $DATABASES_PATH = $config->DATABASES_PATH();

my @styles = ($CSS_PATH.'font-awesome.min.css', $CSS_PATH.'w3.css', $CSS_DEFAULT, $CSS_PATH.'fullsize/fullsize.css', $CSS_PATH.'jquery.alerts.css', $CSS_PATH.'datatables.min.css');

my $q = new CGI;

my $dbh = DBI->connect(    "DBI:Pg:database=$DB;host=$HOST;",
                        $DB_USER,
                        $DB_PASSWORD,
                        {'RaiseError' => 1}
                ) or die $DBI::errstr;


print $q->header(-type => 'text/html', -'cache-control' => 'no-cache'),
	$q->start_html(-title=>"LED variant page",
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
                                -src => $JS_PATH.'datatables.min.js', 'defer' => 'defer'},
				{-language => 'javascript',
				-src => $JS_PATH.'easy-comment/jquery.easy-comment.min.js', 'defer' => 'defer'},
				{-language => 'javascript',
				-src => $JS_PATH.'dalliance_v0.13/build/dalliance-compiled.js', 'defer' => 'defer'},
                                {-language => 'javascript',
                                -src => $JS_DEFAULT, 'defer' => 'defer'}],		
                        -encoding => 'ISO-8859-1');

#my $user = U2_modules::U2_users_1->new();


modules::subs::standard_begin_html($q);

##end of Basic init

if ($q->param('var') && $q->param('var') =~ /(\d+)/o) {
	my $id = $1;
	
	#variant info
	my $query = "SELECT * FROM Variant WHERE id = '$id';";
	my $variant = $dbh->selectrow_hashref($query);
	my ($chr, $pos19, $pos38, $ref, $alt, $rs, $creation) = ($variant->{'chr'}, $variant->{'pos_hg19'}, $variant->{'pos_hg38'}, $variant->{'reference'}, $variant->{'alternative'}, $variant->{'dbsnp_rs'}, $variant->{'creation'});
	my ($assembly, $pos, $ncbi_assembly) = ('hg19', $pos19, '37');
	if ($rs) {$rs = "rs$rs"}	
	if ($pos38 ne '') {($assembly, $pos, $ncbi_assembly) = ('hg38', $pos38, '38')}
	
	print $q->start_div({'class' => 'w3-light-grey'}), $q->span({'id' => 'openNav', 'class' =>'w3-button w3-blue w3-xlarge', 'onclick' => 'w3_open()', 'title' => 'Click here to open the menu of useful external links', 'style' => 'visibility:visible'}, '&#9776;'), $q->end_div(), "\n";
	
	#my $pos_end = $pos;
	my $size = 1;
	my $highlight_start = $pos; #to highlight dalliance later and ucsc
	if ($ref =~ /[ATCG]{2,}/o) {$size = length($ref)-1;$highlight_start = $pos+1}
	my $highlight_end = $highlight_start+$size;
	my ($dal_start, $dal_stop, ) = ($highlight_start-50, $highlight_start+50);
	
	#print $q->start_p({'class' => 'title'}), $q->big("Variant $assembly:chr$chr:$pos$ref/$alt, first seen on $creation:"), $q->end_p();
	# number of samples
	my $query = "SELECT COUNT(DISTINCT(patient_id)) as a FROM Variant2Patient WHERE variant_id = '$id';";
	my $res = $dbh->selectrow_hashref($query);
	my $samples = $res->{'a'};
	#limit - deprecated 11/2016; use of datatables instead
	#my ($limit, $limit_text) = ('', '');
	#if ($q->param('limit') && $q->param('limit') =~ /(\d+)/o) {
	#	$limit = "LIMIT $1";
	#	if ($samples > 19) {$limit_text = $q->span('Click ').$q->a({'href' => "variant.pl?var=$id"}, 'here').$q->span(' to reload the page with full table.')}
	#}
	#number of families
	my $query = "SELECT COUNT(DISTINCT(family_id)) as a FROM Patient a, Variant2Patient b WHERE a.id=b.patient_id AND b.variant_id = '$id';";
	my $res = $dbh->selectrow_hashref($query);
	my $family = $res->{'a'};
	
	#my $query = "SELECT * FROM Variant2Patient a, Patient b WHERE a.patient_id=b.id AND a.variant_id = '$id' $limit;";#removed limit param 11/2016
	my $query = "SELECT * FROM Variant2Patient a, Patient b WHERE a.patient_id=b.id AND a.variant_id = '$id';";
	my $sth = $dbh->prepare($query);
	my $res = $sth->execute();
	if ($res ne '0E0') {
		print				$q->start_div({'class' => 'w3-sidebar w3-bar-block w3-card w3-animate-left w3-light-grey', 'id' => 'smart_menu', 'style' => 'display:none;z-index:1111;width:15%;'}),
				$q->span({'class' => 'w3-bar-item w3-button w3-large w3-border-bottom w3-xlarge', 'onclick' => 'w3_close()'}, 'Close &times;');
		#print $q->br(),
			#$q->start_ul({'class' => 'menu_left ombre appear', 'id' => 'smart_menu'}), "\n";
			my $ucsc_end = $highlight_end;
			if ($highlight_end-$highlight_start == 1) {$ucsc_end = $highlight_start}#ucsc end differs from dalliance
			
			my $ucsc_link = "http://genome-euro.ucsc.edu/cgi-bin/hgTracks?db=$assembly&position=chr$chr%3A".($highlight_start-10)."-".($ucsc_end+10)."&hgS_doOtherUser=submit&hgS_otherUserName=david.baux&hgS_otherUserSessionName=U2&ruler=full&knownGene=full&refGene=full&pubs=pack&lovd=pack&hgmd=pack&cons100way=full&snp144=dense&ucscGenePfam=full&omimGene2=full&tgpPhase1=dense&tgpPhase3=dense&evsEsp6500=dense&exac=dense&dgvPlus=dense&allHg19RS_BW=full&highlight=hg19.chr$chr%3A$highlight_start-$ucsc_end";
			print $q->a({'href' => $ucsc_link, 'target' => '_blank', 'class' => 'w3-bar-item w3-button w3-large w3-hover-blue w3-border-bottom w3-xlarge'}, 'UCSC'), "\n";
			#print $q->start_li(), $q->start_a({'href' => $ucsc_link, 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/buttons/ucsc_button.png'}), $q->end_a(),
			#$q->end_li(), "\n";
		if ($rs) {
			#print $q->start_li(), $q->start_a({'href' => "http://www.ncbi.nlm.nih.gov/SNP/snp_ref.cgi?rs=$rs", 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/buttons/dbsnp_button.png'}), $q->end_a(),
			#$q->end_li(), "\n",
			print $q->a({'href' => "http://www.ncbi.nlm.nih.gov/clinvar?term=".$rs."[varid]", 'target' => '_blank', 'class' => 'w3-bar-item w3-button w3-large w3-hover-blue w3-border-bottom w3-xlarge'}, 'dbSNP'), "\n";
			#$q->start_li(), $q->start_a({'href' => "http://www.ncbi.nlm.nih.gov/clinvar?term=".$rs."[varid]", 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/buttons/clinvar_button.png'}), $q->end_a(),
			#$q->end_li(), "\n";
		}
		print $q->a({'href' => "http://evs.gs.washington.edu/EVS/PopStatsServlet?searchBy=chromosome&chromosome=$chr&chromoStart=".($pos-5)."&chromoEnd=".($pos+5)."&x=0&y=0", 'target' => '_blank', 'class' => 'w3-bar-item w3-button w3-large w3-hover-blue w3-border-bottom w3-xlarge'}, 'EVS'), "\n";
		#print $q->start_li(),
			#$q->start_a({'href' => "http://evs.gs.washington.edu/EVS/PopStatsServlet?searchBy=chromosome&chromosome=$chr&chromoStart=".($pos-5)."&chromoEnd=".($pos+5)."&x=0&y=0", 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/buttons/EVS_button.png'}), $q->end_a(),
			#$q->end_li(), "\n",
			#$q->start_li(),
			#	$q->start_a({'href' => "http://gnomad.broadinstitute.org/variant/$chr-$pos-$ref-$alt", 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/buttons/gnomad_button.png'}), $q->end_a(),
			#$q->end_li(), "\n",
		print $q->a({'href' => "http://gnomad.broadinstitute.org/variant/$chr-$pos-$ref-$alt", 'target' => '_blank', 'class' => 'w3-bar-item w3-button w3-large w3-hover-blue w3-border-bottom w3-xlarge'}, 'gnomAD'), "\n";
		my $grc_assembly = 'GRCh37';
		if ($assembly eq 'hg38') {$grc_assembly = 'GRCh38'}
		print $q->a({'href' => "https://variantvalidator.org/variantvalidation/?variant=$chr-$pos-$ref-$alt&alignment=splign&primary_assembly=$grc_assembly", 'target' => '_blank', 'class' => 'w3-bar-item w3-button w3-large w3-hover-blue w3-border-bottom w3-xlarge'}, 'VariantValidator'), "\n";	
			#$q->start_li(),
			#	$q->start_a({'href' => "http://www.mutationtaster.org/cgi-bin/MutationTaster/MT_ChrPos.cgi?chromosome=$chr&position=$pos&ref=$ref&alt=$alt", 'target' => '_blank'}), $q->img({'src' => $HTDOCS_PATH.'data/img/buttons/mut_taster_button.png'}), $q->end_a(),
			#$q->end_li(), "\n",
			#$q->end_ul(), "\n";
		print $q->a({'href' => "http://www.mutationtaster.org/cgi-bin/MutationTaster/MT_ChrPos.cgi?chromosome=$chr&position=$pos&ref=$ref&alt=$alt", 'target' => '_blank', 'class' => 'w3-bar-item w3-button w3-large w3-hover-blue w3-border-bottom w3-xlarge'}, 'Mutation Taster'), "\n",
		$q->end_div();
		print $q->start_p({'class' => 'title'}), $q->big("Variant hg19:chr$chr:$pos19$ref/$alt, hg38:chr$chr:$pos38$ref/$alt, first seen on $creation:"), $q->end_p();
		my $text = $q->span({'class' => 'w3-large'}, "We have currently $samples distinct samples carrying this variant coming from $family families.");
		print $q->start_div({'class' => 'decale fitin'}).modules::subs::mini_info_panel($text, $q).$q->end_div()."\n";
			#print modules::subs::mini_info_panel($text, $q);
		#print	$q->end_ul(), "\n";
		#	$q->big({'class' => 'gras decale'}, "We have currently $samples distinct samples carrying this variant coming from $family families."),$q->br(),$q->br(),"\n",
		print $q->big({'class' => 'pointer title decale', 'onclick' => '$("#var_details").toggle(500)'}, 'Click to show/hide the patients table.'),"\n", #removed $limit_text line above after families 11/2016
			$q->start_div({'class' => 'decale fitin', 'id' => 'var_details'}), "\n", $q->br(), $q->br(),
				$q->start_table({'class' => 'technical great_table', 'id' => 'var_in_patients'}), $q->caption("$samples distinct samples carrying the variant from $family families:"), $q->start_thead(),
				$q->start_Tr(), "\n",
					$q->th({'class' => 'left_general'}, 'Patient info (sample/familiy/disease/creation date)'), "\n",
					$q->th({'class' => 'left_general'}, 'Experiment'), "\n",
					$q->th({'class' => 'left_general'}, 'Team'), "\n",
					$q->th({'class' => 'left_general'}, 'Status'), "\n",
					$q->th({'class' => 'left_general'}, 'Variant filter'), "\n",
					$q->th({'class' => 'left_general'}, 'QUAL score'), "\n",
					$q->th({'class' => 'left_general'}, 'Depth Of Coverage'), "\n",
				$q->end_Tr(), $q->end_thead(), $q->start_tbody(), "\n";			
		while (my $result = $sth->fetchrow_hashref()) {
			print $q->start_Tr(), "\n";
			if ($result->{'visibility'} == 1) {
				if ($result->{'team_name'} eq 'SENSORINEURAL') {
					print $q->start_td(), $q->a({'href' => "/perl/U2/patient_file.pl?sample=$result->{'patient_id'}", 'target' => '_blank'}, "$result->{'patient_id'} | $result->{'family_id'} | $result->{'disease_name'} | $result->{'creation'}"), $q->end_td(), "\n"
				}
				else {
					print $q->td("$result->{'patient_id'} | $result->{'family_id'} | $result->{'disease_name'} | $result->{'creation'}"), "\n"
				}
			}
			else {
				print $q->td('Not shown'), "\n";
			}
			print $q->td($result->{'experiment_type'}), "\n",
				$q->td($result->{'team_name'}), "\n",
				$q->td($result->{'status_type'}), "\n",
				$q->td($result->{'filter'}), "\n",
				$q->td($result->{'qual'}), "\n",
				$q->td($result->{'doc'}), "\n",
				$q->end_Tr(), "\n";
		}
		print $q->end_tbody(), $q->end_table(), $q->end_div(), "\n", $q->br(), $q->br();
		
		##genome browser
		#http://www.biodalliance.org/
		#my $DALLIANCE_DATA_DIR_URI = '/dalliance_data/hg19/';
					#	{name: 'ExAC',
					#desc: 'ExAC r0.3',
					#tier_type: 'tabix',
					#payload: 'vcf',
					#noSourceFeatureInfo: true,
					#uri: '".$DALLIANCE_DATA_DIR_URI."exac/ExAC.r0.3.sites.vep.vcf.gz'},
					#{name: 'UK10K',
					#desc: 'UK10K dataset',
					#tier_type: 'tabix',
					#payload: 'vcf',
					#uri: '".$DALLIANCE_DATA_DIR_URI."uk10k/UK10K_COHORT.20160215.sites.vcf.gz'},
					#{name: 'dbSNP',
					#desc: 'dbSNP142',
					#tier_type: 'tabix',
					#payload: 'vcf',
					#uri: '".$DALLIANCE_DATA_DIR_URI."dbSNP142/All_20150415.vcf.gz'},
		my ($padding, $sources) = (50, '');
		$sources = "{name: 'ClinVar',
					desc: 'ClinVar 02/2017',
					tier_type: 'tabix',
					payload: 'vcf',
					uri: '".$DALLIANCE_DATA_DIR_URI."clinvar/clinvar_20170228.vcf.gz'},
				{name: 'ESP',
					desc: 'ESP 6500',
					tier_type: 'tabix',
					payload: 'vcf',
					uri: '".$DALLIANCE_DATA_DIR_URI."esp/combined_esp6500.vcf.gz'},
				{name: 'gnomAD Ex',
					desc: 'gnomAD exome dataset',
					tier_type: 'tabix',
					payload: 'vcf',
					uri: '".$DALLIANCE_DATA_DIR_URI."gnomad/hg19_gnomad_exome.sorted.af.vcf.gz'},				
				{name: 'gnomAD Ge',
					desc: 'gnomAD genome dataset',
					tier_type: 'tabix',
					payload: 'vcf',
					uri: '".$DALLIANCE_DATA_DIR_URI."gnomad/hg19_gnomad_genome.sorted.vcf.gz'},				
				";
		
		my $browser = "
			console.log(\"creating browser with coords: chr$chr:$dal_start-$dal_stop\" );
			var sources = [
				{name: 'Genome',
					desc: '$assembly/Grch$ncbi_assembly',
					twoBitURI: '".$DALLIANCE_DATA_DIR_URI."genome/$assembly.2bit',
					tier_type: 'sequence',
					provides_entrypoints: true,
					pinned: true},
				{name: 'Genes',
					desc: 'GENCODE v19',
					bwgURI: '".$DALLIANCE_DATA_DIR_URI."gencode/gencode.v19.annotation.bb',
					stylesheet_uri: '".$DALLIANCE_DATA_DIR_URI."gencode/gencode-expanded.xml',
					collapseSuperGroups: true,
					trixURI: '".$DALLIANCE_DATA_DIR_URI."gencode/gencode.v19.annotation.ix'},
				$sources			
			];
			var browser = new Browser({
				chr:		'$chr',
				viewStart:	$dal_start,
				viewEnd:	$dal_stop,
				cookieKey:	'human-grc_h$ncbi_assembly',
				prefix:		'".$JS_PATH."dalliance_v0.13/',
				fullScreen:	false,
				noPersist:	true,
				noPersistView:	true,
				maxHeight:	500,
		
				coordSystem:	{
					speciesName: 'Human',
					taxon: 9606,
					auth: 'GRCh',
					version: '$ncbi_assembly',
					ucscName: '$assembly'
				},
				sources:	sources,
				hubs:	['http://ftp.ebi.ac.uk/pub/databases/ensembl/encode/integration_data_jan2011/hub.txt']
			});
			
			function highlightRegion(){
				console.log(\" xx highlight region chr$chr,$dal_start,$dal_stop\");
				browser.highlightRegion('chr$chr',$highlight_start,$highlight_end);
				browser.setLocation(\"$chr\",$dal_start,$dal_stop);
			}
		
			browser.addInitListener( function(){
				console.log(\"dalliance initiated\");
				//setTimeout(highlightRegion(),5000);
				highlightRegion();
			});
		";
		
		print $q->br(), $q->start_div({'class' => 'decale'}), $q->script({'type' => 'text/javascript', 'defer' => 'defer'}, $browser), $q->div({'id' => 'svgHolder', 'class' => 'fitin'}, 'Dalliance Browser here'), $q->end_div(), $q->br(), $q->br();
		#end genome browser
		print $q->start_div({'class' => 'decale fitin', 'id' => 'pred_details'}), "\n", $q->br(), $q->br(),
			$q->start_table({'class' => 'technical great_table'}), $q->caption("Predictions from various datasets:"),
				$q->start_Tr(), "\n",
					$q->th({'class' => 'left_general'}, 'Dataset'), "\n",
					$q->th({'class' => 'left_general'}, 'Score'), "\n",
				$q->end_Tr(), "\n";			
		my $cadd_data = 'whole_genome_SNVs';
		if (length($ref) != length($alt)) {$cadd_data = 'InDels'}
		#if ($alt =~ /^([ATCG]+),/o) {$alt = $1}
		my @alt = split(/,/, $alt);#if multiple alts
		
		$ENV{PATH} = $DATABASES_PATH;
		
		#dbscsnv
		if ((length($ref) == length($alt)) && (length($ref) == 1) && (length($alt) == 1)) {#substitution only
			my @dbnsfp = split(/\n/, `$EXE_PATH/tabix $DATABASES_PATH/dbNSFP/dbNSFP29.gz $chr:$pos-$pos`);
			if ($dbnsfp[0]) {
				foreach (@dbnsfp) {
					if (/\t$ref\t$alt\t/) {
						my @res = split(/\t/, $_);
						#pre display treatment
						my $aa = $res[13];
						if ($res[13] =~ /^(\d+);/o) {$aa = $1}
						my ($sift_score, $sift_pred) = ($res[26], $res[28]);
						if ($res[26] =~ /;/o) {($sift_score, $sift_pred) = &select_scores($res[26], $res[28], 'low')}
						my ($pph_score, $pph_pred) = ($res[29], $res[31]);
						if ($res[26] =~ /;/o) {($pph_score, $pph_pred) = &select_scores($res[29], $res[31], 'high')}
						my ($fat_score, $fat_pred) = ($res[44], $res[46]);
						if ($res[26] =~ /;/o) {($fat_score, $fat_pred) = &select_scores($res[44], $res[46], 'low')}
						if ($res[5] ne 'X') {
							print $q->start_Tr(), "\n",
								$q->start_td(), $q->a({'href' => "https://sites.google.com/site/jpopgen/dbNSFP", 'target' => '_blank'}, 'dbNSFP'), $q->end_td(),
								$q->td("Gene: $res[10] p.$res[4]$aa$res[5]"), $q->end_Tr(), "\n",
								$q->start_Tr(),
									$q->start_td(), $q->a({'href' => 'http://sift.bii.a-star.edu.sg/', 'target' => '_blank'}, 'SIFT*'), $q->end_td(),
									$q->td("Score: $sift_score | Interpretation: $sift_pred"),
								$q->end_Tr(), "\n",
								$q->start_Tr(),
									$q->start_td(), $q->a({'href' => 'http://genetics.bwh.harvard.edu/pph2/dokuwiki/about', 'target' => '_blank'}, 'Polyphen 2 humDiv*'), $q->end_td(),
									$q->td("Score: $pph_score | Interpretation: $pph_pred"),
								$q->end_Tr(), "\n",
								$q->start_Tr(),
									$q->start_td(), $q->a({'href' => 'http://fathmm.biocompute.org.uk/', 'target' => '_blank'}, 'FATHMM*'), $q->end_td(),
									$q->td("Score: $fat_score | Interpretation: $fat_pred"),
								$q->end_Tr(), "\n",
								$q->start_Tr(),
									$q->start_td(), $q->a({'href' => 'http://karchinlab.org/apps/appVest.html', 'target' => '_blank'}, 'VEST3*'), $q->end_td(),
									$q->td("Score: $res[54]"),
								$q->end_Tr(), "\n",
								$q->start_Tr(),
									$q->start_td(), $q->a({'href' => 'http://annovar.openbioinformatics.org/en/latest/user-guide/filter/#-metasvm-annotation', 'target' => '_blank'}, 'Meta SVM*'), $q->end_td(),
									$q->td("Score: $res[47] | Interpretation: $res[49]"),
								$q->end_Tr(), "\n";
						}
						else {
							print $q->start_Tr(), "\n",
								$q->start_td(), $q->a({'href' => "https://sites.google.com/site/jpopgen/dbNSFP", 'target' => '_blank'}, 'dbNSFP'), $q->end_td(),
								$q->td("Gene: $res[10] Premature Termination Codon"), $q->end_Tr(), "\n",
						}
					}
				}
			}
			else {print $q->td('no dbNSFP*'), $q->td()}
			print $q->end_Tr(), "\n";
			
			
			
			my @dbscsnv = split(/\n/, `$EXE_PATH/tabix $DATABASES_PATH/dbscSNV/dbscSNV.txt.gz $chr:$pos-$pos`);			
			print $q->start_Tr(), "\n",
							$q->start_td(), $q->a({'href' => "https://sites.google.com/site/jpopgen/dbNSFP", 'target' => '_blank'}, 'dbscSNV**'), $q->end_td();
			if ($dbscsnv[0]) {
				foreach (@dbscsnv) {
					if (/\t$ref\t$alt\t/) {
						my @res = split(/\t/, $_);
						print $q->td("refSeq Gene: $res[7] - $res[6] | ADA score ".(sprintf('%.2f', $res[14]))." | RF score: ".(sprintf('%.2f', $res[15])));
					}
				}
			}
			else {print $q->td('no dbscSNV**')}
			print $q->end_Tr(), "\n";
			
			my @spliceai = split(/\n/, `$EXE_PATH/tabix $DATABASES_PATH/spliceAI/exome_spliceai_scores.vcf.gz $chr:$pos-$pos`);		
			print $q->start_Tr(), "\n",
							$q->start_td(), $q->a({'href' => "https://www.cell.com/cell/fulltext/S0092-8674(18)31629-5", 'target' => '_blank'}, 'spliceAI***'), $q->end_td();
			if ($spliceai[0]) {
				foreach (@spliceai) {
					if (/\t$ref\t$alt\t/) {
						my @res = split(/\t/, $_);
						$res[7] =~ s/;/ | /go;
						print $q->td($res[7]);
					}
				}
			}
			else {print $q->td('no spliceAI***')}
			print $q->end_Tr(), "\n";
			
			
			my @spidex = split(/\n/, `$EXE_PATH/tabix $DATABASES_PATH/spidex_public_noncommercial_v1.0/spidex_public_noncommercial_v1_0.tab.gz chr$chr:$pos-$pos`);
			print $q->start_Tr(), "\n",
							$q->start_td(), $q->a({'href' => "http://www.deepgenomics.com/spidex", 'target' => '_blank'}, 'Spidex****'), $q->end_td();
			if ($spidex[0]) {
				foreach (@spidex) {
					#print $_;
					if (/\t$ref\t$alt\t/) {
						my @res = split(/\t/, $_);
						print $q->td('SPANR dPSI: '.(sprintf('%.2f', $res[4])).'% | dPSI Z-score: '.(sprintf('%.2f', $res[5])));
					}
				}
			}
			else {print $q->td('no Spidex***')}
			print $q->end_Tr(), "\n";
		}
		#cadd
		my @cadd = split(/\n/, `$EXE_PATH/tabix $DATABASES_PATH/CADD/$cadd_data.tsv.gz $chr:$pos-$pos`);
		
		print $q->start_Tr(), "\n",
						$q->start_td(), $q->a({'href' => "http://cadd.gs.washington.edu/", 'target' => '_blank'}, 'CADD'), $q->end_td(), $q->start_td();
		if ($cadd[0]) {
			foreach (@cadd) {
				my @res = split(/\t/, $_);
				if (/\t$ref\t$alt\t/) {					
					print $q->span('raw: '.(sprintf('%.2f', $res[4])).' | phred: '.(sprintf('%.2f', $res[5])));				
				}
				else {
					if (grep(/^$res[3]$/, @alt) && /\t$ref\t/) {
						print $q->span("for $res[3] variant | raw: ".(sprintf('%.2f', $res[4])).' | phred: '.(sprintf('%.2f', $res[5])).'  /');
					}					
				}
			}
		}
		else {print $q->span('no CADD')}
		print $q->end_td(), $q->end_Tr(), "\n";
		
		#LOVD
		my $url = "http://www.lovd.nl/search.php?build=hg19&position=chr$chr:".$highlight_start."_".$ucsc_end;
		#print $url;
		my $ua = new LWP::UserAgent();
		$ua->timeout(10);
		my $response = $ua->get($url);		
		#"hg_build"	"g_position"	"gene_id"	"nm_accession"	"DNA"	"variant_id"	"url"
		#"hg19"	"chr1:215847440"	"USH2A"	"NM_206933.2"	"c.13811+2T>G"	"USH2A_00751"	"https://grenada.lumc.nl/LOVD2/Usher_montpellier/variants.php?select_db=USH2A&action=search_all&search_Variant%2FDBID=USH2A_00751"
		print $q->start_Tr(), "\n";
		if($response->is_success()) {
			if ($response->decoded_content() =~ /.+"(http[^"]+)"/g) {
				my @matches = $response->decoded_content() =~ /.+"(http[^"]+)"/g;
				#print $q->start_li().$q->strong('LOVD matches: ').$q->start_ul();
				my $i = 1;
				print $q->td('LOVD matches:'), $q->start_td();
				foreach (@matches) {
					print $q->a({'href' => $_, 'target' => '_blank'}, "Link $i"), $q->span(' | ');
					$i++;
				}
				
			}
			else {print $q->td('No LOVD matches'), $q->start_td()}
		}
		else {print $q->td('No LOVD matches'), $q->start_td()}
		print $q->end_td(), $q->end_Tr();
		print $q->end_table(), $q->end_div(), "\n", $q->br(), $q->br();
		
		if (length($ref) == length($alt)) {#substitution only
			my $text = $q->span('*Predictions extracted from ').
				$q->a({'href' => 'https://sites.google.com/site/jpopgen/dbNSFP', 'target' => '_blank'}, 'dbNSFP').
				$q->span('. Please note that some predictors like SIFT may report multiple results coming from multiple transcripts. In this case, only the most deleterious is displayed here. For VEST3, the closer to 1, the likely to alter protein function. Interpretation: B benign, T tolerated, D deleterious.')."\n";
			print $q->start_div({'class' => 'decale fitin'}).modules::subs::info_panel($text, $q).$q->end_div();
			#print $q->start_p({'class' => 'decale fitin'}), $q->span('*Predictions extracted from '), $q->a({'href' => 'https://sites.google.com/site/jpopgen/dbNSFP', 'target' => '_blank'}, 'dbNSFP'), $q->span('. Please note that some predictors like SIFT may report multiple results coming from multiple transcripts. In this case, only the most deleterious is displayed here. For VEST3, the closer to 1, the likely to alter protein function. Interpretation: B benign, T tolerated, D deleterious.'), $q->end_p(), "\n",
			$text = $q->span('**').
				$q->a({'href' => 'http://nar.oxfordjournals.org/content/42/22/13534.full', 'target' => '_blank'}, 'dbscSNV').
				$q->span(' is a dataset which provides access, for all variants located into identified intron/exon junctions ').
				$q->span({'class' => 'gras'}, '(-3 to +8 at the 5\' splice site and -12 to +2 at the 3\' splice site)').
				$q->span(' to precomputed splicing alterations likelyhood scores. These scores called Random Forest (RF) or ADA depending on the learning machine used rely on both MaxEntScan and Position Weight Matrix (Shapiro) prediction scores.').
				$q->br().$q->span({'class' => 'gras'}, 'The closer to 1, the likely to disrupt splicing.')."\n";
			print $q->start_div({'class' => 'decale fitin'}).modules::subs::info_panel($text, $q).$q->end_div();
			#print $q->start_p({'class' => 'decale fitin'}), $q->span('**'), $q->a({'href' => 'http://nar.oxfordjournals.org/content/42/22/13534.full', 'target' => '_blank'}, 'dbscSNV'), $q->span(' is a dataset which provides access, for all variants located into identified intron/exon junctions '), $q->span({'class' => 'gras'}, '(-3 to +8 at the 5\' splice site and -12 to +2 at the 3\' splice site)'), $q->span(' to precomputed splicing alterations likelyhood scores. These scores called Random Forest (RF) or ADA depending on the learning machine used rely on both MaxEntScan and Position Weight Matrix (Shapiro) prediction scores.'), $q->br(), $q->span({'class' => 'gras'}, 'The closer to 1, the likely to disrupt splicing.'), $q->end_p(), "\n",			
			$text = $q->span('***').
				$q->a({'href' => 'https://www.cell.com/cell/fulltext/S0092-8674(18)31629-5', 'target' => '_blank'}, 'spliceAI').
				$q->span(' is a dataset which provides access, for all SNVs located into an exon or near splice junctions to precomputed splice sites alterations likelyhood scores.').$q->br().
				$q->span({'class' => 'gras'}, 'The closer to 1, the likely to disrupt splicing. ').$q->br().
				$q->span('The second number represents the distance to the variant of the affected splice site (positive values upstream to the variant, negative downstream). A quick explanation ').
				$q->a({'href' => 'https://github.com/Illumina/SpliceAI', 'target' => '_blank'}, 'here').
				$q->span('. Thresholds: 0.2 (possibly alter splicing), 0.5 (likely), 0.8 (very likely).').$q->end_p()."\n";
			print $q->start_div({'class' => 'decale fitin'}).modules::subs::info_panel($text, $q).$q->end_div();
			$text = $q->span('****').
				$q->a({'href' => 'http://www.deepgenomics.com/spidex', 'target' => '_blank'}, 'Spidex').
				$q->span(' is a dataset which provide access, for all variants in and around 300bp of exons, to ').
				$q->a({'href' => 'http://tools.genes.toronto.edu/', 'target' => '_blank'}, 'SPANR').
				$q->span(' predictions (percent inclusion ratio (PSI) of the affected exon given the wildtype and the mutant sequence).')."\n".
				$q->start_ul().
				$q->li({'class' => 'decale fitin'}, 'dPSI: The delta PSI. This is the predicted change in percent-inclusion due to the variant, reported as the maximum across tissues (in percent).').
				$q->li({'class' => 'decale fitin'}, 'dPSI z-score: This is the z-score of dpsi_max_tissue relative to the distribution of dPSI that are due to common SNP. 0 means dPSI equals to mean common SNP. A negative score means dPSI is less than mean common SNP dataset, positive greater.').
			$q->end_ul();
			print $q->start_div({'class' => 'decale fitin'}).modules::subs::info_panel($text, $q).$q->end_div();
			#$q->start_p({'class' => 'decale fitin'}), $q->span('***'), $q->a({'href' => 'http://www.deepgenomics.com/spidex', 'target' => '_blank'}, 'Spidex'), $q->span(' is a dataset which provide access, for all variants in and around 300bp of exons, to '), $q->a({'href' => 'http://tools.genes.toronto.edu/', 'target' => '_blank'}, 'SPANR'), $q->span(' predictions (percent inclusion ratio (PSI) of the affected exon given the wildtype and the mutant sequence).'), $q->end_p(), "\n",
			#$q->start_ul(),
			#	$q->li({'class' => 'decale fitin'}, 'dPSI: The delta PSI. This is the predicted change in percent-inclusion due to the variant, reported as the maximum across tissues (in percent).'),
			#	$q->li({'class' => 'decale fitin'}, 'dPSI z-score: This is the z-score of dpsi_max_tissue relative to the distribution of dPSI that are due to common SNP. 0 means dPSI equals to mean common SNP. A negative score means dPSI is less than mean common SNP dataset, positive greater.'),
			#$q->end_ul(), "\n";
			
		}
		
		##easy-comment
		my $valid_id = $assembly.'_'.$chr.'_'.$pos.'_'.$alt;
		#$valid_id =~ s/>//og;
		#$valid_id =~ s/\.//og;
		#$valid_id =~ s/\+//og;
		#$valid_id =~ s/\?//og;
		#$valid_id =~ s/\*//og;
		my $js = "jQuery(document).ready(function(){
		   \$(\"#$valid_id\").EasyComment({
		      path:\"/javascript/u2/easy-comment/\"
		   });
		});";
		
		print $q->end_div(), $q->br(), $q->br(), $q->script({'type' => 'text/javascript', 'defer' => 'defer'}, $js), $q->start_div({'id' => $valid_id, 'class' => 'comments decale'});

	}
	else {
		print $q->br(), $q->start_big(), $q->p({'class' => 'gras'}, "Sorry, Cannot find variant with ID:$id."), "\n";
	}
}


##Basic end of LED perl scripts:

modules::subs::standard_end_html($q);

print $q->end_html();

exit();

##End of Basic end

##specific subs

sub select_scores {
	my ($score, $pred, $direction) = @_;
	my @scores = split(/;/, $score);
	my @preds = split(/;/, $pred);
	my ($elected, $i, $elected_index) = (-10, 0, 0);
	if ($direction eq 'low') {$elected = 10}	
	foreach(@scores) {
		if ($direction eq 'low' && $_ < $elected) {$elected = $_;$elected_index = $i}
		elsif ($direction ne 'low' && $_ > $elected) {$elected = $_;$elected_index = $i}
		$i++;
	}
	return ($elected, $preds[$elected_index]);
}
