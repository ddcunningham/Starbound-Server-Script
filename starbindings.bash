#!/bin/bash
#V0.6
##Variables for menucreator and in all menus
declare -i MCOUNTER
declare -a MARRAY
declare MNAME
declare CURRMEN
##Variables for steamlogin
declare STEAMUSER=""
declare STEAMPW=""
##Variables for server variable/log menus
declare SVLOGDIR="/home/steam/Steam/SteamApps/common/Starbound/starbound_server.log"
declare REPV
declare REPVARRAY
declare CFGKEY
declare CFGDIR="/home/steam/Steam/SteamApps/common/Starbound/starbound.config"
declare VARCHANGE
##Variables for setup portion
declare SOURCEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare STEAMCMDDIR="/opt/steam/steamcmd.sh"
declare INITFILEDIR="/etc/init.d/starbound"
declare SERVERFILEDIR="/home/steam/Steam/SteamApps/common/Starbound/linux64/starbound_server"
#Subfunctions referenced in menu functions
fail(){
  echo -e "\n$1\n"; exit 1
}
exitscript(){
  sudo -k
  exit 0
}
inputreturn(){
  echo -e "\n"
  read -p "Press Enter to return to menu."
  echo -e "\n"
  $CURRMEN
}
inputproceed(){
  echo -e "\n"
  read -p "Press Enter to proceed."
  echo -e "\n"
}
steamlogin(){
  read -p 'Enter your Steam username: ' STEAMUSER
  [[ $1 = 'loginpw' || $1 = 'vloginpw' ]] && read -p 'Enter your Steam password: ' STEAMPW

  command="/opt/steam/steamcmd.sh +login $STEAMUSER $STEAMPW +app_update 211820"
  [[ $1 = 'vlogin' || $1 = 'vloginpwless' ]] && command="$command validate"

  sudo su - steam -c "$command +exit"
  read -p "Press ENTER to return to main menu."
  mmenu
}
menuprinter(){
  tput clear
  echo -e "\n$MNAME";
  MCOUNTER=0
  for MCYCLE in "${MARRAY[@]}"; do
    let "MCOUNTER++"
    printf "\n%d)%s\n" "$MCOUNTER" "$MCYCLE"
  done
  printf "\n"
}
## Server variable printing/changing snippet
varprint (){
  echo -e "\nThe value(s) for this variable:\n"
  awk -F ",$" -v k="$CFGKEY" '{
    for(JIT=1;JIT<=NF;JIT++){
    if( $JIT ~ k ){
    gsub(/\\s|\"/, "")
    sub(/[^:]+:/, "")
    print $JIT
    }
    }
    }' $CFGDIR
  echo -e "\n"
  varmodify
}
varmodify(){
  read -p "Do you want to modify this? Y/N: " VMOD
  case $VMOD in
    y|Y)varinput;;
    n|N)svcfvarmenu;;
    *)varmodify;;
  esac
}
varinput(){
read -p "Enter a replacement variable:" REPV
varconfirm
}
varconfirm(){
  tput clear
  echo -e "\nYou entered: $REPV\n"
  read -p "Is this correct? Y/N: " VARCONFIRM
  case $VARCONFIRM in
  	y|Y)$VARCHANGE;echo -e "\nChanges written to file\n";;
  	n|N)varinput;;
  	*)varconfirm;;
  esac
  if [[ $VARCHANGE = "multivarchange" ]]; then
    inputproceed; morevars
  else
    inputreturn
  fi
}
morevars(){
  tput clear
  read -p "Do you have any other entries you'd like to enter? Y/N: " MOREVARS
  case $MOREVARS in
    y|Y)varrayinput;;
    n|N)svcfvarmenu;;
    *)morevars;;
  esac
}
varrayinput(){
  tput clear
  echo -e "\nInput your variable entries.  ENTER submits an entry, CTRL+D ceases prompt.\n"
  while read -p "> " REPVLINE
    do
	    REPVARRAY=(${REPVARRAY[@]} "$REPVLINE")
    done
  varrayconfirm
}
varrayconfirm(){
  tput clear
  echo -e "\nYou entered: ${REPVARRAY[@]}\n"
  read -p "Is this correct? Y/N: " VARRAYCONFIRM
  case $VARRAYCONFIRM in
  	y|Y)$VARCHANGE; echo -e "\nChanges written to file.\n"; inputreturn;;
  	n|N)varrayinput;;
  	*)varrayconfirm;;
  esac
}

singlevarchange(){
  if [[ *$REPV =~ .*[[:alpha:]]+.* && $REPV != "true" && $REPV != "false" || $REPV =~ .*[[:punct:]]+.* ]]; then
    sudo sed -i "/$CFGKEY*/c\  \"$CFGKEY\" : \"$REPV\"," $CFGDIR
  else
    sudo sed -i "/  \"$CFGKEY\" :*/c\  \"$CFGKEY\" : $REPV," $CFGDIR
  fi
}

multivarchange(){
  if [[ $CFGKEY = "serverPasswords" || $REPV =~ .*[[:alpha:]]+.* || $REPV =~ .*[[:punct:]]+.* ]]; then
    sudo sed -i "/$CFGKEY*/c\  \"$CFGKEY\" : \[ \"$REPV\"\ ]," $CFGDIR
    for i in "${REPVARRAY[@]}"; do
      sudo sed -i "s|  \"$CFGKEY\" : \[ \"$REPV\"|&, \"$i\"|"  $CFGDIR
      done
  else
    sudo sed -i "/$CFGKEY*/c\  \"$CFGKEY\" : \[ $REPV \]," $CFGDIR
    for i in "${REPVARRAY[@]}"; do
      sudo sed -i "s|  \"$CFGKEY\" : \[ $REPV|&, $i|"  $CFGDIR
      done
  fi
  unset REPVARRAY
}

#Menu functions
mmenu(){
  CURRMEN="mmenu"
  MNAME="Main Menu"
  MARRAY=("Steam management" "Server management" "Exit script")
  menuprinter
  read -p "Make your selection: " MMENU
  case $MMENU in
    1) smenu ;;
    2) svmenu ;;
    3) exitscript;;
    *) mmenu
  esac
}
#Steam
smenu(){
  CURRMEN="smenu"
  read -p "Are you logged into steam elsewhere? Y\\N: " SMENU
  case $SMENU in
    y|Y) ssmenu1;;
    n|N) ssmenu2;;
    *) smenu;;
  esac
}
ssmenu1(){
  CURRMEN="ssmenu1"
  MNAME="Steam Management"
  MARRAY=("Update Starbound" "Verify Starbound" "Back to Main Menu" "Exit")
  menuprinter
  read -p "Make your selection: " SSMENU1
  case $SSMENU1 in
    1)steamlogin loginpw;;
    2)steamlogin vloginpw;;
    3) mmenu;;
    4) exitscript;;
    *) ssmenu1;;
  esac
}
ssmenu2(){
  CURRMEN="ssmenu2"
  MNAME="Steam Management"
  MARRAY=("Update Starbound" "Verify Starbound" "Back to Main Menu" "Exit")
  menuprinter
  read -p "Make your selection: " SSMENU2
  case $SSMENU2 in
    1)steamlogin loginpwless;;
    2)steamlogin vloginpwless;;
    3) mmenu;;
    4) exitscript;;
    *) ssmenu2;;
  esac
}
#Server
svmenu(){
  CURRMEN="svmenu"
  MNAME="Server Management"
  MARRAY=("Server Daemon Management" "Server Log Options" "Server Configuration" "Back to Main Menu" "Exit")
  menuprinter
  read -p "Make your selection: " SVMENU
  case $SVMENU in
    1) svprmenu;;
    2) svlgmenu;;
    3) svcfmenu;;
    4) mmenu;;
    5) exitscript;;
    *) svmenu;;
  esac
}
svprmenu(){
  CURRMEN="svprmenu"
  MNAME="Server Daemon Management"
  MARRAY=("Start Server Daemon" "Stop Server Daemon" "Restart Server Daemon" "Server Daemon Status" "Back to Server Management" "Exit")
  menuprinter
  read -p "Make your selection: " SVPRMENU
  case $SVPRMENU in
    1) service starbound start;inputreturn;;
    2) service starbound stop;inputreturn;;
    3) service starbound restart;inputreturn;;
    4) service starbound status;inputreturn;;
    5) svmenu;;
    6) exitscript;;
    *) svprmenu;;
  esac
}
svlgmenu(){
  CURRMEN="svlgmenu"
  MNAME="Server Log Options"
  MARRAY=("Open Log" "Review Recent Events" "Review Errors" "Monitor Live Changes" "Wipe Server Logs" "Back to Server Management" "Exit")
  menuprinter
  read -p "Make your selection: " SVLGMENU
  case $SVLGMENU in
    1) less $SVLOGDIR; svlgmenu;;
    2) tail -15 $SVLOGDIR; inputreturn;;
    3) grep -iE -A 5 "Error" $SVLOGDIR || echo "No errors found."; inputreturn;;
    4) echo "Press Ctrl+C to stop monitoring the log"; inputproceed; trap : sigint; tail -f $SVLOGDIR; trap sigint; svlgmenu;;
    5) cat /dev/null | sudo tee $SVLOGDIR; echo "Server log wiped"; inputreturn;;
    6) svmenu;;
    7) exitscript;;
    *) svlgmenu;;
  esac
}
svcfmenu(){
  CURRMEN="svcfmenu"
  MNAME="Server Configuration"
  MARRAY=("Variable/Password Management" "Universe Management" "User Management" "Back to Server Management" "Exit" )
  menuprinter
  read -p "Make your selection: " SVCFMENU
  case $SVCFMENU in
    1)svcfvarmenu;;
    2)svcfunimenu;;
    4)svmenu;;
    5)exitscript;;
    *)svcfmenu;;
  esac
}
svcfvarmenu(){
  CURRMEN="svcfvarmenu"
  MNAME="Variable/Password Management"
  MARRAY=("Display Server Config File" "Server Password" "Server Name" "Server Port" "Max Players" "Edit Server Config File Directly" "Back to Server Management" "Exit")
  menuprinter
  read -p "Make your selection: " SVCFVARMENU
  case $SVCFVARMENU in
  	1)less $CFGDIR;svcfvarmenu;;
  	2)CFGKEY="serverPassword"; VARCHANGE="multivarchange"; varprint;;
  	3)CFGKEY="serverName"; VARCHANGE="singlevarchange"; varprint;;
  	4)CFGKEY="gamePort"; VARCHANGE="singlevarchange"; varprint;;
  	5)CFGKEY="maxPlayers"; VARCHANGE="singlevarchange"; varprint;;
  	6)sudo vim $CFGDIR;svcfmenu;;
  	7)svmenu;;
  	8)exitscript;;
    *)svcfvarmenu;;
  esac
}
svcfunimenu(){
  CURRMEN="svcfunimenu"
  MNAME="Universe Management"
  MARRAY=("Back Up Universe" "Delete Universe" "Restore Universe" "Purge Backups")
  menuprinter
  read -p "Make your selection: " SVCFUNIMENU
  case $SVCFUNIMENU in
    1)find /home/steam/Steam/SteamApps/common/Starbound/universe/ -regex ".*\.world"|\
      sudo -u steam xargs mv {} -v -t /home/steam/Steam/SteamApps/common/Starbound/universebackup/
       ;;
    2)find /home/steam/Steam/SteamApps/common/Starbound/universe/ -regex ".*\.world"|\
      sudo xargs rm {}
      ;;
    3)find /home/steam/Steam/SteamApps/common/Starbound/universebackup/ -regex ".*\.world"|\
      sudo -u steam xargs mv {} -v -t /home/steam/Steam/SteamApps/common/Starbound/universe/
      ;;
    4)find /home/steam/Steam/SteamApps/common/Starbound/universebackup/ -regex ".*\.world"|\
      sudo xargs rm {}
      ;;
    *)svcfunimenu;;
  esac
}
#THE FRAYED ENDS OF SANITY CHECKING
#THE SETUP SECTION
usertest(){
  echo "Checking for user 'steam'."
  if getent passwd steam > /dev/null; then
    echo -e "User 'steam' exists. Continuing...\n" ; else
    echo -e "User 'steam' does not exist. Creating...\n"
    sudo adduser --disabled-login steam
  fi
}
steamtest(){
  echo "Checking for steamcmd directory."
  if [ -s $STEAMCMDDIR ]; then
    echo -e "Steamcmd directory exists. Continuing...\n";else
    echo "Steamcmd directory does not exist. Creating..."
    cd /opt/ || fail "/opt/ directory does not exist, aborting script."
    sudo mkdir steam
    cd steam
    echo "Downloading steamcmd"
    sudo wget -v http://media.steampowered.com/client/steamcmd_linux.tar.gz
    echo "Unpacking steamcmd"
    sudo tar xzfv steamcmd_linux.tar.gz
    echo "Tidying up"
    sudo rm -v steamcmd_linux.tar.gz
    sudo chown -R steam:steam /opt/steam
    echo "Updating steamcmd\n"
    sudo su - steam -c "/opt/steam/steamcmd.sh +exit"
    sudo -u steam mkdir /home/steam/Steam/SteamApps/common/Starbound/universebackup
    fi
}
inittest(){
  echo "Checking for init.d script"
  if [ -s $INITFILEDIR ]; then
    echo -e "Init.d script exists. Continuing...\n";else
    echo "Init.d script does not exist. Copying..."
    echo "Cloning initfile"
    sudo chown steam:steam $SOURCEDIR/starbound || fail "Starbound initfile is not in script's parent folder, aborting script."
    sudo cp -vp $SOURCEDIR/starbound $INITFILEDIR
    echo "Updating runlevels\n"
    sudo update-rc.d -v starbound defaults
  fi
}
servertest(){
  echo "Checking for Starbound Server"
  if [ -s $SERVERFILEDIR ]; then
    echo "Starbound server exists. Your files appear to be in order.";inputproceed; else
    echo "Starbound server does not exist. Launching steamcmd and downloading..."; steamsetup
  fi
}
steamsetup(){
  read -p "Are you logged into steam elsewhere? Y\\N: " SETUPSMENU
  case $SETUPSMENU in
  	y|Y)steamlogin loginpw;;
  	n|N)steamlogin loginpwless;;
    *) steamsetup;;
  esac
}
sudo -vS || fail "Must run this script with sudo permissions."
tput clear
usertest
steamtest
inittest
servertest
mmenu


