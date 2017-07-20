#!/bin/bash
set -x
#
# Create XIOS file_defs for each context described in file in arg2 ,
# for the simulation described by file in arg3
# and accounting for a few other args
#
# Output files are named after pattern dr2xml_<context>.xml
#
EXPID=$1 ; shift # The value for an attribute 'EXPID' in datafiles
ln -sf $1 lab_and_model_settings.tmp.py ; shift
ln -sf $1 simulation_settings.tmp.py ; shift
year=$1 ; shift # year that will be simulated
enddate=$1 ; shift  # simulation end date - YYYYMMDD - must be at 00h next day
ncdir=${1:-@IOXDIR@/} ; shift  # Directory for outpu files
print=${1:-1} ; shift # Want some reporting ?
dummies=${1:-skip} ; shift # See dr2xml doc : forbid/skip/include
dummies=include
#
# Set paths for all software components
#
root=$(cd $(dirname $0) ; pwd)
cvspath=$root/CMIP6_CVs # Path for CMIP6_CV
dr2xmlpath=$root/dr2pub
DRpath=$root/01.00.13/dreqPy
#
#CVtag=$(cd $cvspath ; git log --oneline | head -n 1 | cut -d\  -f 1)
export PYTHONPATH=$dr2xmlpath:$DRpath:$PYTHONPATH
#
# Create Python script for using dr2xml's generate_file_defs()
#
cat >create_file_defs.tmp.py  <<-EOF
	#!/usr/bin/python
	from lab_and_model_settings.tmp import lab_and_model_settings
	from simulation_settings.tmp import simulation_settings
	from dr2xml import generate_file_defs
	import sys, os, traceback
	#print "* CMIP6_CV commit : "
	#os.system("cd $cvspath ; git log --oneline | head -n 1 | cut -d\  -f 1")
	#print
	#
	if $print=="1" : printout=True
	else : printout=False
	#
	for context in lab_and_model_settings['realms_per_context']:
	    ok=generate_file_defs(lab_and_model_settings,
	                       simulation_settings,
	                       year       =$year,
	                       enddate    ="$enddate",
	                       context    =context,
	                       pingfile   ="./ping_%s.xml"%context,
	                       printout   =$print, 
	                       cvs_path   ="${cvspath}/",
	                       dummies    ="$dummies",
	                       dirname    ="./",
	                       prefix     ="$ncdir",
                               attributes= [ ("EXPID","$EXPID") ]   
                               )
	#if not ok : sys.exit(1)
	EOF


[[ $(uname -n) == beaufix* ]] && module load python/2.7.5-2
python create_file_defs.tmp.py
ret=$?
rm create_file_defs.tmp.py simulation_setting.tmp.py lab_and_model_settings.tmp.py
exit $ret