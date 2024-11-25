#!/bin/bash

################################################################################
#
# This script automates some of the steps required after cloning or downloading
# in order to make Easymap ready for execution.
#
################################################################################

################################################################################
#
# REQUIREMENTS:
#   
#   - To use Easymap through the command line
#       - ...
#
#   - To use Easymap through the web interface
#       - Web server that runs Python 3
#
################################################################################

# Deal with argument provided by user
if ! [ $1 ]; then
    echo 'Please provide an argument specifying the type of installation: "cli" or "server". Example: "./install.sh server"'
    exit
fi

if ! [ $1 == server ] && ! [ $1 == cli ]; then
    echo 'Please choose between "cli" and "server". Example: "./install.sh server"'
    exit
fi

if [ $1 == server ]; then
    if ! [ $2 ]; then
        port=8100
    elif [ "$2" -ge 8100 ] && [ "$2" -le 8200 ]; then
        port=$2
    else
        echo 'Please choose a port number between 8100 and 8200. Example: "./install.sh server 8100"'
        exit
    fi
fi

################################################################################

# Create some folders not present in GitHub repo (e.g. 'user_data' and 'user_projects')

[ -d user_data ] || mkdir user_data
[ -d user_projects ] || mkdir user_projects

[ -d web_interface/tmp_upload_files ] || mkdir web_interface/tmp_upload_files

################################################################################

# Install necessary dependencies for Python 3 and virtualenv
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv build-essential wget -y

################################################################################

# Install Python 3 virtual environment
python3 -m venv easymap-env

# Install Pillow with pip3
[ -d cache ] || mkdir cache
easymap-env/bin/pip3 install Pillow --cache-dir cache

################################################################################

# Compile necessary tools like bcftools, bowtie, hisat, and samtools
cd ./htslib
make clean
make

cd ../bcftools-1.3.1
make clean
make

cd ../bowtie2
make clean
make

cd ../samtools1
make clean
make

cd ../hisat2
make clean
make

cd ..

################################################################################

# Create src directory 
if [ -d src ]; then rm -rf src; fi
mkdir src
cd src

# Get virtualenv for Python 3
wget https://pypi.python.org/packages/d4/0c/9840c08189e030873387a73b90ada981885010dd9aea134d6de30cd24cb8/virtualenv-15.1.0.tar.gz#md5=44e19f4134906fe2d75124427dc9b716
tar -zxvf virtualenv-15.1.0.tar.gz

# Install virtualenv for Python 3
cd virtualenv-15.1.0/
../Python3/.localpython/bin/python3 setup.py install

# Create virtual environment "easymap-env"
../Python3/.localpython/bin/python3 virtualenv.py easymap-env -p ../Python3/.localpython/bin/python3

cd ../..

################################################################################

# Change permissions to the Easymap folder and subfolders so Easymap can be used both from the
# web interface (server user -- e.g. www-data) and the command line of any user
sudo chmod -R 777 .

################################################################################

# Check if Easymap functions properly by running a small project: 
cp fonts/check.1.fa user_data/
cp fonts/check.gff user_data/
run_result=`./easymap -n setup -w snp -sim -r check -g check.gff -ed ref_bc_parmut`

# Cleanup
rm  user_data/check.gff
rm  user_data/check.1.fa 
rm -rf user_projects/*

if [ "$run_result" == "Easymap analysis properly completed." ]; then

    # Set easymap dedicated HTTP CGI server to run always in the background
    if [ $1 == server ]; then
        
        # Run server in the background using Python 3
        nohup ./src/Python3/.localpython/bin/python3 -m http.server $port &
        
        # Modify/create the etc/crontab file to always start easymap server at bootup
        echo "@reboot   root    cd $PWD; ./src/Python3/.localpython/bin/python3 -m http.server $port" >> /etc/crontab

        # Save port number to /config/port for future reference for the user
        echo $port > config/port

    fi

    echo " "
    echo " "
    echo "###################################################################################"
    echo "#                                                                                 #"
    echo "#                                                                                 #"
    echo "#                   Easymap installation successfully completed                   #"
    echo "#                                                                                 #"
    echo "#                                                                                 #"
    echo "###################################################################################"
    echo " "
    echo " "

else

    echo " "
    echo " "
    echo "###################################################################################"
    echo "#                                                                                 #"
    echo "#                                                                                 #"
    echo "#                          Easymap installation failed                            #"
    echo "#                                                                                 #"
    echo "#                                                                                 #"
    echo "###################################################################################"
    echo " "
    echo " "

fi