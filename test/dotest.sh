#!/bin/bash
# goto test folder
cd $(dirname $0)
# simulate env var from faspex
set -a
faspex_meta_type='Ads (M:fox/ads)'
faspex_meta_format='Hi Res (M:hires)'
faspex_pkg_directory='/File sent by script - 912d022c-7ba2-4b91-8374-909cbb8d19f1.aspera-package/PKG - File sent by script'
faspex_pkg_id='21'
faspex_pkg_is_forward='0'
faspex_pkg_name='File sent by script'
faspex_pkg_note='this file was sent by a script'
faspex_pkg_total_bytes='6'
faspex_pkg_total_files='1'
faspex_pkg_uuid='912d022c-7ba2-4b91-8374-909cbb8d19f1'
faspex_recipient_0='aspera.user1@gmail.com'
faspex_recipient_count='1'
faspex_recipient_list='aspera.user1@gmail.com'
faspex_sender_email='laurent@asperasoft.com'
faspex_sender_id='2'
faspex_sender_name='admin'
faspex_metadata_fields='_pkg_uuid, _pkg_name, _created_utc, Type, Format'
_created_utc='2016/12/15 08:03:14 +0000'
_dropbox_name='*TVI1'
_metadata_profile_name='TVIDelivery'
_metadata_profile_uuid='cb07d169-202b-4b1e-af46-1ee2efeeda42'
_metadata_profile_version='2016-12-12 15:04:08'
_pkg_name='File sent by script'
_pkg_uuid='912d022c-7ba2-4b91-8374-909cbb8d19f1'
set +a
workflow_folder=tmp/w
docroot=tmp/d
abs_pkg="$docroot$faspex_pkg_directory"
mkdir -p $workflow_folder "$abs_pkg"
touch "$abs_pkg"/file1.dat
../faspex_postprocessing.rb faspex_postprocessing.yaml.test
test -e "$abs_pkg"/_FILES_HAVE_BEEN_MOVED_.txt || exit 1
test -e "$workflow_folder"/fox/ads/hires/file1.dat || exit 1
