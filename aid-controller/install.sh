#!/bin/bash

if [ "$EUID" -ne 0 ]
then 
	echo "Please run as root"
	exit
fi

read -p "If AID-Controller is already installed, this will overwrite everything, including the config. ARE YOU SURE YOU WANT TO PROCEED? [y/n]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then

  echo "Checking version of python..."
  pv=`python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' | grep 2.7`
  if [ -z $pv ]; then
     echo "Python 2.7 not installed or not default... please install python2.7"
     exit
  else
     echo "Python 2.7 installed and default. Continuing."
  fi
  
  echo "Checking python libraries..."
  preq=`python -c 'import requests'`
  if [ -z $preq ]; then
     echo "Python \'requests\' library not installed. Please install using pip or offline package."
     exit
  else
     echo "Python requests library installed. Continuing."
  fi
  pyodbc=`python -c 'import pyodbc'`
  if [ -z $pyodbc ]; then
     echo "Python \'pyodbc\' library not installed. Please install using pip or offline package."
     exit
  else
     echo "Python pyodbc library installed. Continuing."
  fi
  
  echo "Setting up directories..."
  mkdir -p /opt/scripts/aid-controller/logs
  mkdir -p /opt/scripts/aid-controller/etc
  mkdir -p /opt/scripts/aid-controller/status
  mkdir -p /opt/scripts/aid-controller/sysinfo
  echo "Done."
  
  echo "Copying files..."
  cp ./install-files/aid-controller.py /opt/scripts/aid-controller/
  chmod 744 /opt/scripts/aid-controller/aid-controller.py
  cp ./install-files/etc/agents.conf /opt/scripts/aid-controller/etc/
  chmod 644 /opt/scripts/aid-controller/etc/agents.conf
  cp ./install-files/etc/logging.conf /opt/scripts/aid-controller/etc/
  chmod 644 /opt/scripts/aid-controller/etc/logging.conf
  cp ./install-files/helperController.py /opt/scripts/aid-controller/helperController.py
  chmod 644 /opt/scripts/aid-controller/helperController.py
  echo "Done."
  
  echo "Creating init script..."
  if [ -d "/etc/init.d/" ]; then
     cp ./install-files/startup/aid-init-script.sh /etc/init.d/aid-controller
     chmod 755 /etc/init.d/aid-controller
  fi
  if [ -d "/etc/systemd/system" ]; then
     cp ./install-files/startup/aid-controller.service /etc/systemd/system/aid-controller.service
     chmod 644 /etc/systemd/system/aid-controller.service
  fi
  echo "Done."
  
  echo "Creating aid user..."
  useradd -s /bin/false -M aid
  chown -R aid. /opt/scripts/aid-controller/
  usermod -d /opt/scripts/ aid
  
  echo "AID installed to /opt/scripts/aid-controller/"
  
  # Find which init system is running
  init=`stat /proc/1/exe | head -n1 | awk '{print $4}' | awk -F"/" '{print $3}' | awk -F"’" '{print $1}'`
  
  if [ "$init" == "systemd" ]; then
     echo "Run 'systemctl start aid-controller' to start the daemon."
  elif [ "$init" == "init" ]; then
     echo "Run 'service aid-controller start' to start the daemon"
  else
     echo "Could not determine init system."
  fi
else
  echo "Exiting."
fi
