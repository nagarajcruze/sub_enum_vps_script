#!/bin/bash

initDefaults(){
  domain=$1
  if [ -z "$1" ]; then
    echo -e "\e[91mNo argument supplied\e[0m"
    echo -e "\e[91mDomain Name requried! \e[0m Ex: ./cruze.sh example.com"
    exit 1
  fi
  echo -e "\e[96mThe Target is \e[0m \e[96m$1\e[0m"
  dir=$1-$(date '+%Y-%m-%d')
  dir=$(echo "$dir" | sed -r s/[^a-zA-Z0-9]+/_/g | tr A-Z a-z)
  mkdir -p $dir
}
initDefaults "$1"

if [[ -z $(find ./$dir/ -type f -name hosts-ignore.txt) ]]
then
    read -p 'continue without Out of Scope Domains?? y/n' -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        touch  $dir/hosts-ignore.txt
    else
        echo $(clear)
        touch $dir/hosts-ignore.txt
        echo "Add in this format here $dir/hosts-ignore.txt if you want and Start again!!!"
        echo 'eg: foo\.example\.com$' && exit 1
    fi
fi

echo -e "\e[91m-------------------Amass Started  -------------------------------------------\e[0m"
amass enum -src -ip -active -d $domain -o $dir/amass-out.txt

cat $dir/amass-out.txt | cut -d']' -f 2 | awk '{print $1}' | sort -u > $dir/hosts-amass.txt

cat $dir/amass-out.txt | cut -d']' -f2 | awk '{print $2}' | tr ',' '\n' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > $dir/ips-amass.txt


echo -e "\e[91m-------------------Generating Wordlists  -------------------------------------------\e[0m"
sed s/$/.$domain/ ~/tools/custom-sub-wordlist.txt > $dir/hosts-wordlist.txt

#making amass hosts and wordlist into one
cat $dir/hosts-amass.txt $dir/hosts-wordlist.txt | sort -u > $dir/hosts-all.txt
rm $dir/hosts-wordlist.txt && rm $dir/hosts-amass.txt 

grep -vf $dir/hosts-ignore.txt $dir/hosts-all.txt > $dir/hosts-inscope.txt
#rm $dir/hosts-ignore.txt

echo -e "\e[91m-------------------MassDNS Started  -------------------------------------------\e[0m"
massdns -r ~/tools/massdns/lists/resolvers.txt -t A -o S -w $dir/massdns.out $dir/hosts-inscope.txt
rm $dir/hosts-inscope.txt
cat $dir/massdns.out | awk '{print $1}' | sed 's/.$//' | sort -u > $dir/hosts-massdns.txt
cat $dir/hosts-massdns.txt | httprobe | sed -e 's!http\?://\S*!!g' | sort -u | tee $dir/clean-live-hosts.txt
#as massdns output will have more chunks let's delete it. after probing with httprobe
rm $dir/hosts-massdns.txt
cat $dir/massdns.out | awk '{print $3}' | sort -u | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > $dir/ips-online.txt

echo -e "\e[91m-------------------Naabu Started  -------------------------------------------\e[0m"

naabu -hL $dir/ips-online.txt -silent | ~/tools/naabu2nmap.sh
