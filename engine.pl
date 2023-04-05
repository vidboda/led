BEGIN {delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV', 'PATH'};}

use strict;

use modules::init;
use modules::subs;
use List::Util qw[min max];
#use Data::Dumper;

#    This program is part of lgm_ex,
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


##Basic init of lgm_ex perl scripts:
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

my @styles = ($CSS_PATH.'font-awesome.min.css', $CSS_PATH.'w3.css', $CSS_DEFAULT, $CSS_PATH.'fullsize/fullsize.css', $CSS_PATH.'jquery.alerts.css', $CSS_PATH.'datatables.min.css');

my $q = new CGI;

my $dbh = DBI->connect(    "DBI:Pg:database=$DB;host=$HOST;",
                        $DB_USER,
                        $DB_PASSWORD,
                        {'RaiseError' => 1}
                ) or die $DBI::errstr;


print $q->header(-type => 'text/html', -'cache-control' => 'no-cache'),
	$q->start_html(-title=>"LED results page",
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
				-src => $JS_PATH.'jquery.alerts.js', 'defer' => 'defer'},
				{-language => 'javascript',
				-src => $JS_PATH.'datatables.min.js', 'defer' => 'defer'},
                                {-language => 'javascript',
                                -src => $JS_DEFAULT, 'defer' => 'defer'}],		
                        -encoding => 'ISO-8859-1');

#my $user = U2_modules::U2_users_1->new();


modules::subs::standard_begin_html($q);

##end of Basic init

#basic research
if ($q->param('research') && $q->param('research') =~ /(h?g?[1938]{2}):c?h?r?([\dXY]{1,2}):g?\.?([\d,]+)$/o) {
	my ($g, $chr, $pos) = ($1, $2, $3);
	if ($g =~/^\d{2}$/o) {$g = "hg$g"}	
	my $query = "SELECT * FROM Variant WHERE chr = '$chr' AND pos_$g BETWEEN '".($pos-10)."' AND '".($pos+10)."';";
	my $sth = $dbh->prepare($query);
	my $res = $sth->execute();
	if ($res ne '0E0') {
		my $text = $q->start_div({'class' => 'w3-container w3-large'}).
			$q->span('Between positions ').$q->span({'class' => 'gras'}, $pos-10).$q->span(' and ').$q->span({'class' => 'gras'}, $pos+10).
			$q->span(' of ').$q->span({'class' => 'gras'}, "$g:chr$chr").
			$q->span(', the database contains the following ').$q->span({'class' => 'gras'}, "$res variant(s):").
			$q->end_div()."\n";
		print modules::subs::mini_info_panel($text,$q);
		#print $q->br(), $q->start_big(), $q->start_p(), $q->span('Between positions '), $q->span({'class' => 'gras'}, $pos-10),$q->span(' and '), $q->span({'class' => 'gras'}, $pos+10), $q->span(' of '), $q->span({'class' => 'gras'}, "$g:chr$chr"), $q->span(', the database contains the following '), $q->span({'class' => 'gras'}, "$res variant(s):"), $q->end_p(), "\n",
		print $q->br(), "\n",
			$q->start_div({'class' => 'w3-container', 'style' => 'width:50%'}), $q->start_ul({'class' => 'w3-ul w3-large w3-hoverable'}), "\n";
		while (my $result = $sth->fetchrow_hashref()) {#removed param lilit &amp;limit=20 11/2016 useless
			print $q->start_li(), $q->a({'href' => "variant.pl?var=$result->{'id'}", 'target' => '_blank'}, "$g:chr$result->{'chr'}:g.".$result->{'pos_'.$g}."$result->{'reference'}/$result->{'alternative'}");
			if ($result->{'pos_'.$g} eq $pos) {
				print $q->span('  <--  your query'), $q->end_li(), "\n";
			}
		}
		print $q->end_ul(), $q->end_div();"\n";
		print modules::subs::mini_info_panel('Click on a variant to display the full information.', $q);
		#	$q->p('Click on a variant to display the full information.');
	}
	else {
		my $text = $q->span({'class' => 'w3-large'},"The database does not contain any variant between positions ".($pos-10)." and ".($pos+10)." of $g:chr$chr");
		print modules::subs::danger_panel($text, $q);
		#print $q->br(), $q->start_big(), $q->p({'class' => 'gras'}, "The database does not contain any variant between positions ".($pos-10)." and ".($pos+10)." of $g:chr$chr"), "\n";
	}
	print $q->end_big(), $q->br(), $q->br(), $q->br(), $q->start_div({'id' => 'farside', 'class' => 'appear center'}), $q->end_div(), "\n";
}
elsif ($q->param('research') && $q->param('research') ne '') {#2 positions or a gene
	my ($g, $chr, $pos1, $pos2);
	my ($gene, $order, $param) = ('', 'ASC', '');
	my ($patient, $last_col, $main_text, $failed_patient)	= ('', '# found in LED', 'rare variants (gnomAD Exome/Genome AF < 0.01)', '');
	if ($q->param('research') =~ /(h?g?[1938]{2}):c?h?r?([\dXY]{1,2}):g?\.?([\d,]+)[-_:]([\d,]+)/o) {
		($g, $chr, $pos1, $pos2) = ($1, $2, $3, $4);
		$pos1 =~ s/,//og;
		$pos2 =~ s/,//og;
		if ($g =~/^\d{2}$/o) {$g = "hg$g"}
	}
	elsif ($q->param('research') =~ /^(\w+)$/o) {$gene = $1}#gene
	elsif ($q->param('research') =~ /^(\w+):(\w+)$/o) {$gene = $1;$patient = $2;$main_text = "variants for patient $patient";$failed_patient = " (for patient $patient)";}#gene:patient
	else {print $q->p('Unrecognized query format');exit;}
	#if ($param =~ /^(\w+):(\w*)$/o) {#gene:patient
	if ($gene ne '') {
		#so we need to build two kind of pages:
		#one with rare variants per gene (gnomad < 0.01)
		#the second with all variants per gene for a particular patient
		#$gene = $1;
		$gene = uc($gene);
		#if ($2) {$patient = $2;$main_text = "variants for patient $patient";$failed_patient = " (for patient $patient)";}
		#print "--$gene--";exit;
		$g = 'hg19';
		my $dbh_ucsc = DBI->connect(    "DBI:mysql:database=$g;host=genome-mysql.cse.ucsc.edu;",
                        "genome", 
                        "",
                        {'RaiseError' => 1}
                ) or die $!;
		my $query_ucsc = "SELECT chrom, MIN(txStart) as a, MAX(txStart) as b, MIN(txEnd) as c, MAX(txEnd) as d, strand FROM refGene WHERE name2 = '$gene';";
		my $res_pos = $dbh_ucsc->selectrow_hashref($query_ucsc);
		#print Dumper($res_pos);exit;
		if ($res_pos) {
			#print $res_pos->{'strand'};exit;
			if ($res_pos->{'strand'} eq '-') {$order = 'DESC'}#strand -
			($pos1, $pos2) = ($res_pos->{'a'}, $res_pos->{'d'});
			$chr = $res_pos->{'chrom'};
			$chr =~ s/chr//og;
		}
		if (!$res_pos->{'chrom'}) {print $q->p('Unkown gene. Please use HGNC cannonical name');exit;}	
	}
	
	
	my $DATABASES_PATH = $config->DATABASES_PATH();
	$ENV{PATH} = $DATABASES_PATH;
	my $DALLIANCE_DATA_DIR_RESTRICTED_PATH = $config->DALLIANCE_DATA_DIR_RESTRICTED_PATH();

	my $query = "SELECT * FROM Variant WHERE chr = '$chr' AND pos_$g BETWEEN '$pos1' AND '$pos2' ORDER BY pos_$g $order;";
	if ($patient ne '') {
		$query = "SELECT a.*, b.status_type FROM variant a, variant2patient b, patient c WHERE a.id = b.variant_id AND b.patient_id = c.id AND a.chr = '$chr' AND a.pos_$g BETWEEN '$pos1' AND '$pos2' AND c.patient_id = '$patient';";
		$last_col = 'Status';
	}	
	my $sth = $dbh->prepare($query);
	my $res = $sth->execute();
	if ($res ne '0E0') {
		my $text = $q->start_big().$q->start_p().
			$q->span('Between positions ').$q->span({'class' => 'gras'}, $pos1).$q->span(' and ').
			$q->span({'class' => 'gras'}, $pos2).$q->span(' of ').$q->span({'class' => 'gras'}, "$g:chr$chr $gene").
			$q->span(", the database contains the following $main_text"), $q->end_p().$q->end_big()."\n";
		print modules::subs::mini_info_panel($text, $q);
		#print $q->br(), $q->start_big(), $q->start_p(), $q->span('Between positions '), $q->span({'class' => 'gras'}, $pos1),$q->span(' and '), $q->span({'class' => 'gras'}, $pos2), $q->span(' of '), $q->span({'class' => 'gras'}, "$g:chr$chr $gene"), $q->span(", the database contains the following $main_text"), $q->end_p(), $q->end_big(), "\n",
		print $q->br(), "\n",
			$q->start_div({'class' => 'fitin decale', 'id' => 'pat_details'}), "\n", $q->br(), $q->br(),
			$q->start_table({'class' => 'technical great_table', 'id' => 'patient_variant_table', 'data-page-length' => '25'}), $q->caption("Variants recorded in LED:"),
				$q->start_thead(), "\n",
				$q->start_Tr(), "\n",
					$q->th({'class' => 'left_general'}, 'Variant hg19'), "\n",
					$q->th({'class' => 'left_general'}, 'Variant hg38'), "\n",
					$q->th({'class' => 'left_general'}, 'Protein consequence if NS'), "\n",
					$q->th({'class' => 'left_general'}, 'dbsnp rs'), "\n",
					$q->th({'class' => 'left_general'}, 'gnomAD Exome/Genome AF'), "\n",
					$q->th({'class' => 'left_general'}, "$last_col"), "\n",
				$q->end_Tr(), "\n",
				$q->end_thead(), "\n",
				$q->start_tbody(), "\n";
		my ($thg, $espea, $espaa, $exac, $clinvar, $filtered_out) = (0, 0, 0, '', 0);
		while (my $result = $sth->fetchrow_hashref()) {
			#Filter frequent variants max_max < 0,01 or LED < 20
			#my $query = "SELECT COUNT(DISTINCT(patient_id)) as a FROM Variant2Patient WHERE variant_id = '$result->{'id'}';";
			#my $res = $dbh->selectrow_hashref($query);
			#my $found = $res->{'a'};
			
			#my $nom_prot = '';
			#if (length($result->{'reference'}) == 1 && length($result->{'alternative'}) == 1) {
			#	#print "$DATABASES_PATH/htslib-1.2.1/tabix $DATABASES_PATH/dbNSFP/dbNSFP29.gz $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}";exit;
			#	my @dbnsfp = split(/\n/, `$DATABASES_PATH/htslib-1.2.1/tabix $DATABASES_PATH/dbNSFP/dbNSFP29.gz $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}`);
			#	##print "$DATABASES_PATH/htslib-1.2.1/tabix $DATABASES_PATH/dbNSFP/dbNSFP29.gz $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}";#exit;
			#	if ($dbnsfp[0]) {
			#		foreach (@dbnsfp) {
			#			if (/\t$result->{'reference'}\t$result->{'alternative'}\t/) {
			#				#print $dbnsfp[0];exit;
			#				my @res = split(/\t/, $_);
			#				my $aa = $res[13];
			#				if ($aa =~ /\d/o) {
			#					if ($aa =~ /^(\d+);/o) {$aa = $1}
			#					$nom_prot = $res[4].$aa.$res[5];
			#				}							
			#			}
			#		}
			#	}
			#}
			#		if ($res[83] ne '.') {$thg = $res[83]}
			#		if ($res[92] ne '.') {$espaa = $res[92]}
			#		if ($res[93] ne '.') {$espea = $res[93]}
			#		if ($res[99] ne '.') {$exac = $res[99]}
			#		if ($res[115] ne '.') {$clinvar = $clinvar_patho{$res[115]}}
			#		my $max_maf = 0;
			#		if ($thg > $max_maf) {$max_maf = $thg}
			#		if ($espaa > $max_maf) {$max_maf = $espaa}
			#		if ($espea > $max_maf) {$max_maf = $espea}
			#		if ($exac > $max_maf) {$max_maf = $exac}
			#		if ($max_maf < 0.01) {
			#			print $q->start_Tr(), "\n",
			#				$q->start_td(), $q->a({'href' => "engine.pl?research=$g:chr$chr:g.$result->{'pos_'.$g}", 'target' => '_blank'}, "$g:chr$chr:g.$result->{'pos_'.$g}$result->{'reference'}/$result->{'alternative'}"), $q->end_td(), "\n";
			#				if ($result->{'dbsnp_rs'} ne '') {
			#					print $q->start_td(), $q->a({'href' => "http://www.ncbi.nlm.nih.gov/SNP/snp_ref.cgi?rs=rs$result->{'dbsnp_rs'}", 'target' => '_blank'}, "rs$result->{'dbsnp_rs'}"), $q->end_td(), "\n";
			#				}
			#				else {print $q->td()}
			#				print $q->td($clinvar), "\n",
			#				$q->td($max_maf), "\n",
			#				#$q->td($found), "\n",
			#				$q->td($result->{'creation'}), "\n",
			#				$q->end_Tr(), "\n";
			#		}
			#		else {$filtered_out++}
			#		
			#	}
			#}
			#else {
			
			#exome or genome???
			my ($gnomad_file, $gnomad_alleles, $focus) = ('hg19_gnomad_genome.sorted.vcf.gz', '30992', 'genome');
			my $query = "SELECT a.focus FROM experiment a, patient b, variant2patient c WHERE a.type = b.experiment_type AND b.id = c.patient_id AND c.variant_id = '$result->{'id'}' AND a.focus = 'exome';";
			my $sth = $dbh->prepare($query);
			my $res = $sth->execute();
			if ($res ne '0E0') {($gnomad_file, $gnomad_alleles, $focus) = ('hg19_gnomad_exome.sorted.af.vcf.gz', '155504', 'exome')}
			
			#my ($maf, $count, $total) = (0, 0, 155504);
			my $maf = 0;
			#my ($maf_exome, $maf_genome) = (0, 0);
			#my @kaviar = split(/\n/, `$DATABASES_PATH/htslib-1.2.1/tabix $DALLIANCE_DATA_DIR_RESTRICTED_PATH/$g/kaviar/Kaviar-160204-Public-$g-trim.vcf.gz $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}`);
			#if ($kaviar[0]) {
			my $gnomad_file = $g."_gnomad_exome.sorted.af.vcf.gz";
			my @gnomad = split(/\n/, `$EXE_PATH/tabix $DALLIANCE_DATA_DIR_RESTRICTED_PATH/$g/gnomad/$gnomad_file $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}`);
			if ($gnomad[0]) {
				foreach (@gnomad) {
					my @current = split(/\t/, $_);
					if (/\t$result->{'reference'}\t$result->{'alternative'}\t/) {
						if ($focus eq 'genome') {$maf = $current[7]}
						else {
							$current[7] =~ /AF=([\d\.e-]+)/o;
							$maf = $1;
							#$maf_exome = $1;
						}
					}
					#print "$DATABASES_PATH/htslib-1.2.1/tabix $DALLIANCE_DATA_DIR_RESTRICTED_PATH/$g/gnomad/$gnomad_file $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}";
				}
			}
			
			#$gnomad_file = $g."_gnomad_genome.sorted.vcf.gz";
			#@gnomad = split(/\n/, `$DATABASES_PATH/htslib-1.2.1/tabix $DALLIANCE_DATA_DIR_RESTRICTED_PATH/$g/gnomad/$gnomad_file $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}`);
			#if ($gnomad[0]) {
			#	foreach (@gnomad) {
			#	my @current = split(/\t/, $_);
			#		if (/\t$result->{'reference'}\t$result->{'alternative'}\t/) {
			#			if ($focus eq 'genome') {$maf = $current[7]}
			#			else {
			#				#$current[7] =~/AF=([\d\.]+)/o;
			#				$maf = $1;
			#				#$maf_genome = $current[7];
			#			}
			#		}
			#		#print "$DATABASES_PATH/htslib-1.2.1/tabix $DALLIANCE_DATA_DIR_RESTRICTED_PATH/$g/gnomad/$gnomad_file $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}";
			#	}
			#}
			#$maf = max($maf_exome, $maf_genome);
			
			
			#if ($kaviar[0]) {
			#	foreach (@kaviar) {
			#		my @data = split(/\t/, $_);
			#		if ($result->{'reference'} eq $data[3]) {
			#			my @possible;
			#			my ($multiple, $present) = (0, 0);
			#			if ($data[4] =~ /,/o) {@possible = split(/,/, $data[4]);$multiple = 1}
			#			else {push @possible, $data[4]}
			#			my $i = 0;
			#			foreach(@possible) {
			#				if ($possible[$i] eq $result->{'alternative'}) {$present = 1;last;}
			#				$i++;
			#			}
			#			if ($present == 1 && $multiple == 0) {
			#				if ($data[7] =~ /AF=([\d\.]+);AC=(\d+);AN=(\d+);?/o) {($maf, $count, $total) = ($1, $2, $3)}					
			#			}
			#			elsif ($present == 1 && $multiple == 1) {
			#				if ($data[7] =~ /AF=([\d\.,]+);AC=([\d,]+);AN=(\d+);?/o) {
			#					my @mafs = split(/,/, $1);
			#					my @counts = split(/,/, $2);
			#					($maf, $count, $total) = ($mafs[$i], $counts[$i], $3);
			#				}
			#			}
			#		}
			#	}
			#}

			if (($patient eq '' && $maf < 0.01) || ($patient ne '')) {
				#Filter frequent variants max_max < 0,01 or LED < 20				
				my $nom_prot = '';
				if (length($result->{'reference'}) == 1 && length($result->{'alternative'}) == 1) {
					#print "$DATABASES_PATH/htslib-1.2.1/tabix $DATABASES_PATH/dbNSFP/dbNSFP29.gz $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}";exit;
					my @dbnsfp = split(/\n/, `$EXE_PATH/tabix $DATABASES_PATH/dbNSFP/dbNSFP29.gz $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}`);
					##print "$DATABASES_PATH/htslib-1.2.1/tabix $DATABASES_PATH/dbNSFP/dbNSFP29.gz $chr:$result->{'pos_'.$g}-$result->{'pos_'.$g}";#exit;
					if ($dbnsfp[0]) {
						foreach (@dbnsfp) {
							if (/\t$result->{'reference'}\t$result->{'alternative'}\t/) {
								#print $dbnsfp[0];exit;
								my @res = split(/\t/, $_);								
								my $aa = $res[13];
								if ($aa =~ /\d/o) {
									if ($aa =~ /^(\d+);/o) {$aa = $1}
									$nom_prot = $res[4].$aa.$res[5];
								}
								elsif ($res[13] eq '.') {if ($res[5] eq 'X') {$nom_prot = 'PTC*'}}
								
							}
						}
					}
				}
				my $found = '';
				#print "--$patient--";exit;
				if ($patient eq '') {
					my $query = "SELECT COUNT(DISTINCT(patient_id)) as a FROM Variant2Patient WHERE variant_id = '$result->{'id'}';";
					my $res_found = $dbh->selectrow_hashref($query);
					$found = $res_found->{'a'};
				}
				else {$found = $result->{'status_type'}}
				
				print $q->start_Tr(), "\n",
					$q->start_td(), $q->a({'href' => "variant.pl?var=$result->{'id'}", 'target' => '_blank'}, "chr$chr:g.$result->{'pos_hg19'}$result->{'reference'}/$result->{'alternative'}"), $q->end_td(), "\n",
					$q->td("chr$chr:g.$result->{'pos_hg38'}$result->{'reference'}/$result->{'alternative'}"), "\n",
					$q->td($nom_prot), "\n";
				if ($result->{'dbsnp_rs'} ne '') {
					print $q->start_td(), $q->a({'href' => "http://www.ncbi.nlm.nih.gov/SNP/snp_ref.cgi?rs=rs$result->{'dbsnp_rs'}", 'target' => '_blank'}, "rs$result->{'dbsnp_rs'}"), $q->end_td(), "\n";
				}
				else {print $q->td()}
				print $q->td("$maf (on $gnomad_alleles alleles)"), "\n",
				#print $q->td($maf), "\n",
					$q->td($found), "\n",
					$q->end_Tr(), "\n";
			}
			#else {$filtered_out++}
		}	
		print $q->end_tbody(), "\n", $q->end_table(), $q->end_div(), "\n", $q->br(), $q->br();
		$text = '* PTC: Premature Termination Codon but be careful! LED does not recognise frameshifts yet.';
		print modules::subs::info_panel($text, $q);
		
	}
	else {
		print $q->br(), $q->start_big(), $q->p({'class' => 'gras'}, "The database does not contain any variant between positions $pos1 and $pos2 of $g:chr$chr $failed_patient"), "\n";
	}
	print $q->end_big(), $q->br(), $q->br(), $q->br(), $q->start_div({'id' => 'farside', 'class' => 'appear center'}), $q->end_div(), "\n";
}


#patient list
if ($q->param('patients') && $q->param('patients') == 1) {
	
	my $query_pat = "SELECT COUNT(id) as a FROM Patient;";
	my $nb_pat = $dbh->selectrow_hashref($query_pat);
	my $query_fam = "SELECT COUNT(DISTINCT(family_id)) as a FROM Patient;";
	my $nb_fam = $dbh->selectrow_hashref($query_fam);
	
	my $query = "SELECT * FROM Patient ORDER BY experiment_type, team_name, family_id, patient_id;";
	my $sth = $dbh->prepare($query);
	my $res = $sth->execute();
	my $text = $q->strong("We have currently $nb_pat->{'a'} distinct samples coming from $nb_fam->{'a'} families.");
	print modules::subs::mini_info_panel($text, $q);
	#print	$q->br(), $q->big({'class' => 'gras decale'}, "We have currently $nb_pat->{'a'} distinct samples coming from $nb_fam->{'a'} families."),$q->br(),$q->br(),"\n",
	print 	$q->start_div({'class' => 'fitin decale', 'id' => 'pat_details'}), "\n", $q->br(), $q->br(),
			$q->start_table({'class' => 'technical great_table', 'id' => 'patient_table', 'data-page-length' => '25'}), $q->caption("Samples recorded in LED:"),
			$q->start_thead(), "\n",
				$q->start_Tr(), "\n",
					$q->th({'class' => 'left_general'}, 'Patient ID'), "\n",
					$q->th({'class' => 'left_general'}, 'Family ID'), "\n",
					$q->th({'class' => 'left_general'}, 'Gender'), "\n",
					$q->th({'class' => 'left_general'}, 'Disease'), "\n",
					$q->th({'class' => 'left_general'}, 'Team'), "\n",
					$q->th({'class' => 'left_general'}, 'Creation Date'), "\n",
					$q->th({'class' => 'left_general'}, 'Experiment'), "\n",
					#$q->th({'class' => 'left_general'}, '# variants'), "\n",
				$q->end_Tr(), "\n",
			$q->end_thead(), "\n",
			$q->start_tbody(), "\n";	
	while (my $result = $sth->fetchrow_hashref()) {
		#my $query_vars = "SELECT COUNT(variant_id) as a FROM Variant2Patient WHERE patient_id = '$result->{'id'}';";
		#my $nb_vars = $dbh->selectrow_hashref($query_vars);
		print $q->start_Tr(), "\n",
			$q->td($result->{'patient_id'}), "\n",
			$q->td($result->{'family_id'}), "\n",
			$q->td($result->{'gender'}), "\n",
			$q->td($result->{'disease_name'}), "\n",
			$q->td($result->{'team_name'}), "\n",
			$q->td($result->{'creation'}), "\n",
			$q->td($result->{'experiment_type'}), "\n",
			#$q->td($nb_vars->{'a'}), "\n",
			$q->end_Tr(), "\n";
	}
	print $q->end_tbody(), "\n", $q->end_table(), $q->end_div(), "\n", $q->br(), $q->br();
}


##Basic end of LED perl scripts:

modules::subs::standard_end_html($q);

print $q->end_html();

exit();

##End of Basic end

##specific subs


