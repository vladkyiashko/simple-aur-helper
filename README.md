# simple-aur-helper
simple-aur-helper is a CLI application made to simplify the the usage of [Arch User Repository (AUR)](https://aur.archlinux.org/).
It can install/remove/upgrade AUR packages, get dependecies from Arch repository and fetch the necessary PGP keys. It has minimum dependencies.

## Installation
Get the script
```sh
wget https://github.com/vladkyiashko/simple-aur-helper/blob/main/simple-aur-helper.sh
```
or
```sh
curl https://github.com/vladkyiashko/simple-aur-helper/blob/main/simple-aur-helper.sh
```
Set executing permission
```sh
chmod +x simple-aur-helper.sh
```

Install git and rsync
```sh
sudo pacman -S --needed git rsync
```

## Usage
`./simple-aur-helper --install Foo` -- install the package.

`./simple-aur-helper --install Foo Foo2` -- install several packages.

`./simple-aur-helper --remove Foo` -- remove the package.

`./simple-aur-helper --remove Foo Foo2` -- remove several packages.

`./simple-aur-helper --upgrade` -- check for updates and upgrade packages.

~/.aur path is used to store PKGBUILDS and temporary files. Feel free to change it in the script
```sh
AUR_PATH=~/.aur
```

It can work with your existing AUR folder in you were downloading PKGBUILDS manually previously.
