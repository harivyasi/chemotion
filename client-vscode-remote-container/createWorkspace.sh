#!/bin/bash

function confirm() {	
	while : ; do
		read -p "$1 (y/n)? " choice
		case "$choice" in
			[yY][eE][sS]|[yY] ) return 0;;
			[nN][oO]|[nN] ) return 1;;
			* ) echo "Invalid choice.";;
		esac
	done
}

dest=$1

[[ -z "${dest}" ]] && {
	echo "No target directory specified."
	exit 1
}

dest=$(realpath ${dest})

echo "Chosen target directory is: ${dest}"
echo "Please make sure the folder ist empty!"
confirm "Confirm" || {
	echo "See you around then..."
	exit 0
}

procs=$(nproc 2>/dev/null || echo "4")
echo "Info: ${procs} cores detected."

echo "Creating workspace in ${dest}..."

# clone the repo
mkdir -p ${dest}/
git clone https://github.com/ptrxyz/chemotion_ELN.git ${dest}/ || exit 1

# copy over config files for VSCode
cp -r .devcontainer ${dest}/
cp Dockerfile.vscode ${dest}/
cp dbinit.sh ${dest}/
cp postCreate.sh ${dest}/
cp docker-compose.vscode ${dest}/

# adjust number of CPUs used
sed -i 's/BUNDLE_JOBS=.*/BUNDLE_JOBS='${procs}'/g' ${dest}/docker-compose.vscode

# adjust config files for chemotion
cp ${dest}/public/welcome-message-sample.md ${dest}/public/welcome-message.md
cp ${dest}/config/datacollectors.yml.example ${dest}/config/datacollectors.yml
cp ${dest}/config/storage.yml.example ${dest}/config/storage.yml
cp ${dest}/config/database.yml.example ${dest}/config/database.yml
sed -i 's/host: .*/host: db/g' ${dest}/config/database.yml

# Install VSCode extension
command -v code &>/dev/null && {
	code --install-extension ms-vscode-remote.vscode-remote-extensionpack
} || {
	echo "VSCode not detected. Please make sure the Remote Development Extension Pack is installed."
	echo "Get it here: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack"
}

echo "Some gems take ages to compile (even on potent machines). Some "
echo "native libraries are precompiled for x64 systems and can be "
echo "embedded into the workspace to speed up container creation by "
echo "a lot."

# todo: explain why this is not default...

confirm "Embed precompiled libraries?" && {
	echo "Native extensions will be embedded."
	cp rdkit_chem.tar.gz ${dest}/rdkit_chem.tar.gz
	sed -i "s#^gem 'rdkit_chem'.*#gem 'rdkit_chem', git: 'https://github.com/ptrxyz/rdkit_chem', ref: 'b7532a4bbbb154ed2bb7d49d15a79c26eb2c8086'#g" ${dest}/Gemfile
} || {
	echo "Native extensions will NOT be embedded."
}

echo "done."
echo ""
command -v code &>/dev/null && {
	echo "Opening folder [${dest}] in VSCode for you. Please confirm"
	echo "to change to the container environment when prompted."
	echo ""
	code ${dest}
} || {
	echo "Please open the folder [${dest}] in VSCode and confirm"
	echo "to change to the container environment when prompted."
	echo ""
	echo "Please Note: this requires the non-OSS build of VSCode "
	echo "             with the Remote Development Extension Pack"
	echo "             installed and working."
	echo ""
}