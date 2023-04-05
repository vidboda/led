package modules::init;

#use AppConfig qw(:expand :argcount); #in startup.pl
use File::Basename;

#    This program is part of ushvam2, USHer VAriant Manager version 2
#    Copyright (C) 2012-2014  David Baux
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
#
#
#		initiates config


##Replace ushvam2.config with the name of your config file
## ushvam2.config MUST BE IN THE SAME DIRECTORY THAN THE CALLING FILE

sub getConfFile {
	return dirname($ENV{SCRIPT_FILENAME}).'/led.config';
}

##Loads each variable

sub initConfig {	
	return AppConfig->new(
		'HOME' => {ARGCOUNT => 1},
		'HOME_IP' => {ARGCOUNT => 1},
		'PERL_SCRIPTS_HOME' => {ARGCOUNT => 1},
		'HTDOCS_PATH' => {ARGCOUNT => 1},
		'ABSOLUTE_HTDOCS_PATH' => {ARGCOUNT => 1},
		'DALLIANCE_DATA_DIR_URI' => {ARGCOUNT => 1},
		'DALLIANCE_DATA_DIR_PATH' => {ARGCOUNT => 1},
		'DALLIANCE_DATA_DIR_RESTRICTED_PATH' => {ARGCOUNT => 1},
		'DATABASES_PATH' => {ARGCOUNT => 1},
		'EXE_PATH' => {ARGCOUNT => 1},
		'JS_PATH' => {ARGCOUNT => 1},
		'JS_DEFAULT' => {ARGCOUNT => 1},
		'CSS_PATH' => {ARGCOUNT => 1},
		'CSS_DEFAULT' => {ARGCOUNT => 1},
		'DB' => {ARGCOUNT => 1},
		'HOST' => {ARGCOUNT => 1},
		'ADMIN_EMAIL' => {ARGCOUNT => 1},
		'DB_USER' => {ARGCOUNT => 1},
		'DB_PASSWORD' => {ARGCOUNT => 1},
		'PERL_ACCENTS' => {ARGCOUNT => 1},
		#'SSH_RACKSTATION_LOGIN' => {ARGCOUNT => 1},
		#'SSH_RACKSTATION_PASSWORD' => {ARGCOUNT => 1},
		#'SSH_RACKSTATION_IP' => {ARGCOUNT => 1},
		#'SSH_RACKSTATION_BASE_DIR' => {ARGCOUNT => 1},
		#'SSH_RACKSTATION_FTP_BASE_DIR' => {ARGCOUNT => 1},
	);
}



1;