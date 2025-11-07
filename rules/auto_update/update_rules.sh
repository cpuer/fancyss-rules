#!/bin/bash
CurrentDate=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
OBJECT_1='{}'

get_gfwlist(){
	# gfwlist.conf

	# 1. download
	python3 fwlist.py gfwlist_download.conf >/dev/null 2>&1
	if [ ! -f "gfwlist_download.conf" ]; then
		echo "gfwlist download faild!"
		exit 1
	fi

	# 2. merge
	cat gfwlist_download.conf gfwlist_fancyss.conf | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >../gfwlist_merge.conf
	cat gfwlist_download.conf gfwlist_fancyss.conf | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed "s/^/ipset=&\/./g" | sed "s/$/\/gfwlist/g" >>../gfwlist_merge.conf

	# 3. sort
	sort -k 2 -t. -u ../gfwlist_merge.conf >../gfwlist_tmp.conf
	
	# 4. post filter: delete site below
	sed -i '/m-team/d' ../gfwlist_tmp.conf
	sed -i '/windowsupdate/d' ../gfwlist_tmp.conf
	sed -i '/v2ex/d' ../gfwlist_tmp.conf
	sed -i '/apple\.com/d' ../gfwlist_tmp.conf

	# 5. compare
	local md5sum1=$(md5sum ../gfwlist_tmp.conf | awk '{print $1}')
	local md5sum2=$(md5sum ../gfwlist.conf | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "gfwlist same md5!"
		return
	fi

	# 6. update file
	echo "update gfwlist!"
	mv -f ../gfwlist_tmp.conf ../gfwlist.conf

	# 7. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ../gfwlist.conf|grep -E "^server="|wc -l)
	jq --arg variable "${CURR_DATE}" '.gfwlist.date = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${MD5_VALUE}" '.gfwlist.md5 = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${LINE_COUN}" '.gfwlist.count = $variable' ../rules.json.js | sponge ../rules.json.js
}

get_chnroute(){
	# chnroute.txt

	# 1. download
	# source-1：ipip, 20220604: total 6182 subnets, 13240665434 unique IPs
	# wget https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset -qO ../chnroute_tmp.txt

	# source-2：misakaio, 20220604: total 3403 subnets, 298382954 unique IPs
	# wget https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt -qO ../chnroute_tmp.txt

	# source-3: mayaxcn, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget https://raw.githubusercontent.com/mayaxcn/china-ip-list/master/chnroute.txt -qO ../chnroute_tmp.txt

	# source-4: clang, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget https://ispip.clang.cn/all_cn.txt -qO ../chnroute_tmp.txt
	
	# source-5：apnic, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget -4 -O- http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -qO ../apnic.txt
	# cat apnic.txt| awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > ../chnroute_tmp.txt
	# rm -rf ../apnic.txt

 	# source-6：china-operator-ip, 20250105: total 4277 subnets, 64838768 unique IPs
	wget https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china.txt -qO ../chnroute_tmp.txt
	
	if [ ! -f "../chnroute_tmp.txt" ]; then
		echo "chnroute download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' ../chnroute_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ../chnroute_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ../chnroute.txt | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "chnroute same md5!"
		return
	fi
	
	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ../chnroute_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' ../chnroute_tmp.txt)
	jq --arg variable "${CURR_DATE}" '.chnroute.date = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${MD5_VALUE}" '.chnroute.md5 = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${LINE_COUN}" '.chnroute.count = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${IP_COUNT}" '.chnroute.count_ip = $variable' ../rules.json.js | sponge ../rules.json.js

	# 5. update file
	echo "update chnroute, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ../chnroute_tmp.txt ../chnroute.txt
}

get_cdn(){
	# cdn.txt

	# 1.download
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf -qO ../accelerated-domains.china.conf
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf -qO ../apple.china.conf
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf -qO ../google.china.conf
	if [ ! -f "../accelerated-domains.china.conf" -o ! -f "../apple.china.conf" -o ! -f "../google.china.conf" ]; then
		echo "cdn download faild!"
		exit 1
	fi
	
	# 2.merge
	cat ../accelerated-domains.china.conf ../apple.china.conf ../google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" > ../cdn_download.txt
	cat cdn_koolcenter.txt ../cdn_download.txt | sort -u > ../cdn_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ../cdn_tmp.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ../cdn.txt | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn list same md5!"
		return
	fi
	
	# 4. update file
	echo "update cdn!"
	mv -f ../cdn_tmp.txt ../cdn.txt

	# 5. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ../cdn.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.cdn_china.date = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${MD5_VALUE}" '.cdn_china.md5 = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${LINE_COUN}" '.cdn_china.count = $variable' ../rules.json.js | sponge ../rules.json.js
}

get_apple(){
	# 1. get domain
	cat ../apple.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u >../apple_download.txt

	# 2. compare
	local md5sum1=$(md5sum ../apple_download.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ../apple_china.txt | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "apple china list same md5!"
		return
	fi
	
	# 3. update file
	echo "update apple china list!"
	mv -f ../apple_download.txt ../apple_china.txt

	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ../apple_china.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.apple_china.date = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${MD5_VALUE}" '.apple_china.md5 = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${LINE_COUN}" '.apple_china.count = $variable' ../rules.json.js | sponge ../rules.json.js	
}

get_google(){
	# 1. get domain
	cat ../google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u > ../google_download.txt

	# 2. compare
	local md5sum1=$(md5sum ../google_download.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ../google_china.txt | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "google china list same md5!"
		return
	fi
	
	# 3. update file
	echo "update google china list!"
	mv -f ../google_download.txt ../google_china.txt

	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ../google_china.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.google_china.date = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${MD5_VALUE}" '.google_china.md5 = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${LINE_COUN}" '.google_china.count = $variable' ../rules.json.js | sponge ../rules.json.js
}

get_cdntest(){
	# 1. get domain
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/cdn-testlist.txt -qO ../cdn_test_tmp.txt

	# 2. compare
	local md5sum1=$(md5sum ../cdn_test_tmp.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ../cdn_test.txt | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn test list same md5!"
		return
	fi
	
	# 3. update file
	echo "update cdn test list!"
	mv -f ../cdn_test_tmp.txt ../cdn_test.txt

	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ../cdn_test.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.cdn_test.date = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${MD5_VALUE}" '.cdn_test.md5 = $variable' ../rules.json.js | sponge ../rules.json.js
	jq --arg variable "${LINE_COUN}" '.cdn_test.count = $variable' ../rules.json.js | sponge ../rules.json.js
}


finish(){
	rm -f ../gfwlist_tmp.conf
	rm -f ../gfwlist_merge.conf
	rm -f ../gfwlist_download.conf
	rm -f ../chnroute_tmp.txt
	rm -f ../cdn_tmp.txt
	rm -f ../cdn_test_tmp.txt
	rm -f ../accelerated-domains.china.conf
	rm -f ../cdn_download.txt
	rm -f ../apple.china.conf
	rm -f ../apple_download.txt
	rm -f ../google.china.conf
	rm -f ../google_download.txt
	echo "---------------------------------"
}

get_rules(){
	get_gfwlist
	get_chnroute
	get_cdn
	get_apple
	get_google
	get_cdntest
	finish
}

get_rules
