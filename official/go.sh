#!/bin/bash

importantName=learning_puppet_vm ;

execute() {
  "$@" || die "ERROR: Failed to executed this command: q{$@}." ;
}
die() {
  echo $1 ;
  exit ${2:-1} ;
}
mktmpd() {
  local tmpd=`mktemp -d "${TMPDIR:-/tmp}/tmp.d.XXXXXXXXXX"` ;
  echo "$tmpd" ;
}

cd $(dirname $0) || die "ERROR: Failed to cd \$(dirname $0) (\$0 = '$0')." ;
main() {
  import_ova ;
  add_box ;
  vagrant up ;
  echo "Vagrantfile is probably using private networking with 80 and 443 forwarded to localhost ports 20080 and 20443, respectively." ;
}



add_box() {
  local x='' ;
  [[ -e $importantName.box ]] || import_ova ;
  x=`vagrant box list | grep $importantName` ;
  [[ $x ]] || vagrant box add $importantName.box --name $importantName ;
}
import_ova() {
  export PATH="$PATH:/Applications/VirtualBox.app/Contents/MacOS" ;
  local x='' ;
  if [[ ! -e $importantName.box ]] ; then
    x=`VBoxManage list vms | egrep 'puppet' | grep 'learning' | awk '{print $NF}' | sed 's/[{}]//g' | tail -1` ;
    [[ $x ]] || _import_ova ;
    if [[ '' ]] ; then
      x=`VBoxManage list vms | egrep 'puppet' | grep 'learning' | awk '{print $NF}' | sed 's/[{}]//g'` ;
      [[ $x ]] || (
        VBoxManage list vms | egrep 'puppet' | grep 'learning' ;
        echo -e "\nSee anything puppet-y or learning-y"'?' ;
      ) ;
    fi ;
    echo "vmid=$x" ;
    vagrant package --base $x --output $importantName.box ;
  fi ;
}
_import_ova() {
  local importantDir=$importantName ;
  if [[ ! -d $importantDir ]] ; then
    local zip=~/dw/$importantDir.zip ;
    [[ -e $zip ]] || zip=~/dw/huge/$importantDir.zip ;
    [[ -e $zip ]] || die "ERROR: Failed to find $importantDir.zip ($zip).  Download it from https://puppet.com/download-learning-vm ." ;
    local pwd0=`pwd` ;
    local tmpd=`mktmpd` ;
    execute cd $tmpd ;
    pwd ;
    unzip $zip ;
    ls -lart ;
    local d=. ;
    [[ -d $importantDir ]] && d=$importantDir ;
    rsync -av $d/* $pwd0/$importantDir/ ;
    
    mkdir old ; 
    local x='' ;
    for x in `ls ..` ; do 
      mv ../$x old/ ;
    done ;
    mv ./* old/ ;
    rm -rf old ;
    
    execute cd $pwd0 ;
    pwd ;
    
  fi ;
  local x=`(cd $importantDir ; ls -d *.ova ) | tail -1 | sed -e 's/[.]ova$//'` ;
  local vmName="learning_puppet_$x" ;
  execute VBoxManage import $importantDir/$x.ova --vsys 0 \
    --vmname "$vmName" --memory 4096 --eula accept ;
  execute VBoxManage modifyvm "$vmName" --nic1 bridged --bridgeadapter1 eth0 ;
}



main "$@" ;

#
