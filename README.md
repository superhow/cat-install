# Catapult Install Scripts
Symbol Catapult install scripts by SUPER HOW? This is a set of bash scripts that aid in downloading, compiling, installing the Symbol Catapult server, dependancies and rest on Ubuntu systems. 

## Script Package Organization
cat-install scripts are organized as follows:

| Script name | Description |
| -------------|--------------|
| cat-install.sh | Symbol Catapult server with dependancies install script. |
| cat-install.sh | Symbol Catapult server with dependancies install script. |

## Scripts usage

[ ] Get the scripts:  

``wget https://github.com/superhow/cat-install/raw/master/src/install_base_deps.sh``

``wget https://github.com/superhow/cat-install/raw/master/src/install_cat_deps.sh``

``wget https://github.com/superhow/cat-install/raw/master/src/install_catapult.sh``

[ ] Run the scripts:  

``screen -S build_cat -L -Logfile cat-build-screen.log bash install_catapult.sh``

``bash install_catapult.sh``

The following scripts are included: 
Installs `apt` system dependencies that are required for Catapult. It also updates via `apt update` and `apt upgrade`, installs direct Catapult dependencies.  Dependencies will be installed in the specified directory.  

## Symbol server
Symbol-based networks rely on nodes to provide a trustless, high-performance, and secure blockchain platform.
These nodes are deployed using [symbol-server] software, a C++ rewrite of the previous Java-written [NEM] distributed ledger that has been running since 2015.

## License
Copyright (c) 2020 superhow, ministras, SUPER HOW UAB licensed under the [GNU Lesser General Public License v3](LICENSE)
This repository might include copyrighted material from Jaguar0625, gimre, BloodyRookie, Tech Bureau, Corp licensed under the [GNU Lesser General Public License v3](LICENSE)

[symbol-server]: https://github.com/nemtech/catapult-server
[symbol-rest]: https://github.com/nemtech/catapult-rest
[nem]: https://nem.io
