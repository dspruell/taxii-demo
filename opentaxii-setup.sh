#!/bin/sh
# shellcheck disable=SC3043
#
# TAXII server prototype setup using Python virtual environment and TAXII
# server and client implementations:
# 
# - OpenTAXII (EclecticIQ): https://www.opentaxii.org/
# - Cabby (EclecticIQ): https://cabby.readthedocs.io/
# 
# Relevant TAXII standards documentation:
# 
# - http://taxii.mitre.org/
# - http://docs.oasis-open.org/cti/taxii/v1.1.1/taxii-v1.1.1-part1-overview.html
# - http://docs.oasis-open.org/cti/taxii/v2.0/taxii-v2.0.html
# - http://docs.oasis-open.org/cti/taxii/v2.1/taxii-v2.1.html
#
# Sample STIX bundles from Cybersecurity and Infrastructure Security Agency
# (CISA):
#
# - https://www.cisa.gov/

set -e

VENV_DIR="env.d"
WORK_DIR="$PWD"
DATA_DIR="opentaxii-var"

# TAXII server
PKG_OPENTAXII="opentaxii"
CONF_FILE_OPENTAXII_SERVER_DEFAULTS=".opentaxii-server-defaults.yml"
CONF_FILE_OPENTAXII_SERVER="opentaxii-server-configuration.yml"
CONF_FILE_OPENTAXII_DATA="opentaxii-data-configuration.yml"
export OPENTAXII_CONFIG="$CONF_FILE_OPENTAXII_SERVER"

# TAXII client
PKG_CABBY="cabby"
PKG_EXTRAS="ipython wheel"
STIX_FILES_DIR="stix-docs"

# STIX documents; these are downloaded as test datasets to load into the server
STIX_DOCUMENTS="
https://www.cisa.gov/sites/default/files/publications/MAR-10296782-3.v1.stix.xml
https://www.cisa.gov/sites/default/files/publications/MAR-10310246-1.v1.WHITE.stix.xml
https://www.cisa.gov/sites/default/files/publications/MAR-10319053-1.v1.WHITE_stix.xml
https://www.cisa.gov/sites/default/files/publications/MAR-10369127-1.v1.WHITE_stix.xml
https://www.cisa.gov/sites/default/files/AA22-257A.stix.xml
https://www.cisa.gov/sites/default/files/publications/AA22-320A.stix.xml
"

create_venv()
{
	python3 -m venv "$VENV_DIR"
}

install_packages()
{
	./"$VENV_DIR"/bin/pip install \
		"$PKG_OPENTAXII" "$PKG_CABBY" "$PKG_EXTRAS"
}

check_venv()
{
	local _venv="$1"
	[ -e "${_venv}/bin/python" ] && return 0
	return 1
}

configure_opentaxii()
{
	local _conf_file_server="$1"
	local _secret
	_secret="$(openssl rand -hex 16)"
	sed \
		-e "s!/tmp!${WORK_DIR}/${DATA_DIR}!" \
		-e "s!SECRET-STRING-NEEDS-TO-BE-CHANGED!${_secret}!" \
		"$CONF_FILE_OPENTAXII_SERVER_DEFAULTS" \
		> "$_conf_file_server"
}

# Download specified STIX files to a directory
fetch_stix_documents()
{
	local _dir="$1"
	local _documents="$2"
	local _downloaded=0
	(
		cd "$_dir"
		for _doc in $_documents
		do
			local _bname="${_doc##*/}"
			if [ ! -e "$_bname" ]
			then
				echo "  Downloading $_bname"
				curl -s -O "$_doc"
				_downloaded="$((_downloaded + 1))"
			fi
		done
		if [ $_downloaded -eq 0 ]
		then
			echo "  All files were previously fetched."
		else
			echo "Fetched $_downloaded documents"
		fi
	)
}

# Load TAXII server data into server databases
load_opentaxii_data()
{
	local _conf_file_data="$1"
	mkdir -p "$DATA_DIR"
	"$VENV_DIR/bin/opentaxii-sync-data" "$_conf_file_data"
}

# Set up virtual environment and install packages
if ! check_venv "$VENV_DIR"
then
	echo "Creating virtual environment..."
	create_venv
	echo "Installing TAXII software..."
	install_packages
else
	echo "Virtual environment already present at ${VENV_DIR}."
fi

echo "Configuring TAXII server..."
configure_opentaxii "$CONF_FILE_OPENTAXII_SERVER"
echo "Downloading STIX documents..."
mkdir -p "$STIX_FILES_DIR"
fetch_stix_documents "$STIX_FILES_DIR" "$STIX_DOCUMENTS"
echo "Loading data into configuration..."
load_opentaxii_data "$CONF_FILE_OPENTAXII_DATA"

echo "Starting development server..."
"$VENV_DIR/bin/opentaxii-run-dev"
