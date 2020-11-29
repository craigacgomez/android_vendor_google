#!/bin/bash

source_location=/mnt/factory-image/redfin

copy () {
    local source_file_path="$source_location/$1"
    local target_file="${1#*/}"
    local target_file_path="$2/$target_file"
    local target_file_location=$2/$(dirname $target_file)
    if [ ! -f "$source_file_path" ]; then
        echo -e "\t\e[31mSource file $1 does not exist\e[0m"
    else
        echo -e "\t\e[32mExtracting file $1\e[0m"
        mkdir -p "$target_file_location"
        cp --no-preserve=mode,ownership,timestamps "$source_file_path" "$target_file_path"
    fi
}

fix_xml_version_header_location () {
    local xml_file="$1"
    local xml_version_header_line_number=$(grep -n -m 1 "xml version=" $xml_file | sed 's/\([0-9]*\).*/\1/')
    echo -e "\t\e[32mXML version header in $xml_file is on line '$xml_version_header_line_number', but should be on line '1'\e[0m"
    sed -i -n "1{h; :a; n; $xml_version_header_line_number{p;x;bb}; H; ba}; :b; p" $xml_file
}

fix_xml_invalid_version_number () {
    local xml_file="$1"
    local xml_version_number=$(grep -n -m 1 "xml version" "$xml_file" | sed 's/.*version="\([0-9.]*\).*/\1/')
    echo -e "\t\e[32mXML version number in $xml_file is '$xml_version_number', but should be '1.0'\e[0m"
    sed -i "s/version=\"$xml_version_number\"/version=\"1.0\"/" $xml_file
}

fix_json_comments () {
    local json_file="$1"
    echo -e "\t\e[32mComments are not permitted in JSON files, but $json_file has comments\e[0m"
    sed -ri ':a; s%(.*)/\*.*\*/%\1%; ta; /\/\*/ !b; N; ba' $json_file
    sed -i '/./,$!d' $json_file
}

echo -e "\e[1mExtracting 'system' proprietary files\e[0m"
cat "$PWD/redfin/proprietary-files-system.txt" | while read proprietary_file
do
    target_location="$PWD/redfin/proprietary"
    copy "$proprietary_file" "$target_location"
done

echo -e "\e[1mExtracting 'system_ext' proprietary files\e[0m"
cat "$PWD/redfin/proprietary-files-system_ext.txt" | while read proprietary_file
do
    target_location="$PWD/redfin/proprietary/system_ext"
    copy "$proprietary_file" "$target_location"
done

echo -e "\e[1mExtracting 'product' proprietary files\e[0m"
cat "$PWD/redfin/proprietary-files-product.txt" | while read proprietary_file
do
    target_location="$PWD/redfin/proprietary/product"
    copy "$proprietary_file" "$target_location"
done

echo -e "\e[1mExtracting 'vendor' proprietary files\e[0m"
cat "$PWD/redfin/proprietary-files-vendor.txt" | while read proprietary_file
do
    target_location="$PWD/redfin/proprietary/vendor"
    copy "$proprietary_file" "$target_location"
done

echo -e "\e[1mFixing invalid/malformed files from stock image\e[0m"
fix_xml_invalid_version_number "$PWD/redfin/proprietary/product/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml"
fix_xml_version_header_location "$PWD/redfin/proprietary/vendor/etc/data/dsi_config.xml"
fix_xml_version_header_location "$PWD/redfin/proprietary/vendor/etc/data/netmgr_config.xml"
fix_json_comments "$PWD//redfin/proprietary/vendor/etc/ssg/ta_config.json"
fix_json_comments "$PWD//redfin/proprietary/vendor/etc/ssg/tz_whitelist.json"
