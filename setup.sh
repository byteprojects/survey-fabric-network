#!/bin/bash

function updateLibraries() {
	echo $'\n'"Updating the machine libraries"$'\n'
	if ! sudo apt-get update; then
		echo $'\n'"Failure: Error updating the machine libraries"$'\n'
		exit 1
	fi

}	

function sourceProfile() {
	echo $'\n'"Applying changes..."$'\n'
	if ! source ~/.bashrc; then
		echo $'\n'"Failure: Error while applying changes"$'\n'
		exit 1
	fi
	source ~/.profile
}

function allowPackageOverHttps() {
	echo $'\n'"Getting packages to allow over HTTPS..."$'\n'
	if ! sudo apt-get install \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg-agent \
		software-properties-common -y ; then
		
		echo $'\n'"Failure: Error while getting packages"$'\n'
		exit 1
	fi
}

function addDockerGCPKey() {
	echo $'\n'"Adding docker GCP key..."$'\n'
	if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ;then
		echo $'\n'"Failure: Error while adding docker GCP key"$'\n'
		exit 1
	fi

}

function setupStableRepository() {
	echo $'\n'"Setting up stable repository..."$'\n'
	if ! sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" ; then
		echo $'\n'"Failure: Error while Setting up stable repository"$'\n'
		exit 1
	fi
}

function installDocker() {
	allowPackageOverHttps
	addDockerGCPKey
	setupStableRepository
	updateLibraries

	echo $'\n'"Getting docker using apt..."$'\n'
	if ! sudo apt-get install docker-ce -y; then
		echo $'\n'"Failure: Error while getting docker"$'\n'
		exit 1
	fi
	

}

function installDockerCompose() {
	echo $'\n'"Info: Getting docker compose binaries..."$'\n'
	if ! sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose;  then
		echo $'\n'"Failure: Error while getting docker compose binaries"$'\n'
		exit 1
	fi

	echo $'\n'"Info: Making binaries executable"$'\n'
	if ! sudo chmod +x /usr/local/bin/docker-compose; then
		echo $'\n'"Failure: Error while makeing binaries executable"$'\n'
		exit 1
	fi
	
}

function startDockerService() {
	# sudo usermod -a -G docker $USER
	sudo usermod -aG docker $USER & su - $USER
	sourceProfile

	echo $'\n'"Info: Starting docker service"$'\n'
	if ! sudo service docker start ;then
		echo $'\n'"Failure: Error while starting docker service"$'\n'
		exit 1
	fi
}

function installNode() {
	echo $'\n'"Failure: Downloading build essentials for nvm"$'\n'
	if ! sudo apt-get install build-essential libssl-dev -y ; then 
		echo $'\n'"Failure: Error while downloading build essentials for nvm"$'\n'
		exit 1
	fi

	echo $'\n'"INfo: Downloading NVM"$'\n'
	if ! curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh -o install_nvm.sh; then 
		echo $'\n'"Failure: Error while downloading NVM"$'\n'
		exit 1
	fi

	echo $'\n'"Info: Installing NVM"$'\n'
	if ! bash install_nvm.sh; then 
		echo $'\n'"Failure: Error while installing NVM"$'\n'
		exit 1
	fi
	
	echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.profile

}

function downloadExtrasBinaries() {
	installNode
	sourceProfile

	# echo $'\n'"Info: Installing python"$'\n'
	if ! sudo apt-get install python; then 
		echo $'\n'"Failure: Error while installing python"$'\n'
		exit 1
	fi

	echo $'\n'"Info: Installing GoLang"$'\n'
	sudo apt-get update
	sudo apt-get -y upgrade
	cd /tmp 
	wget https://dl.google.com/go/go1.11.linux-amd64.tar.gz
	sudo tar -xvf go1.11.linux-amd64.tar.gz
	sudo mv go /usr/local

	echo 'export GOROOT=/usr/local/go' >> ~/.profile
	echo 'export GOPATH=$HOME/go' >> ~/.profile
	echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> ~/.profile
	
	sourceProfile

}

updateLibraries
installDocker
installDockerCompose
startDockerService
downloadExtrasBinaries