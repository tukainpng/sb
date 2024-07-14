PKGREPO=local
MANREPO=man
BSDIR=base
BKDIR=backup
DTDIR=dotfiles
USER=$$(whoami)
HOST=$$(hostname)
HOME=/home/${USER}
DOTFILES=/home/${USER}/git/${DTDIR}

all:
	@printf "\033[41mSTOP RIGHT THERE, CRIMINAL SCUM!\033[0m\n"
	@echo "You need to provide one of these options:"
	@echo ""
	@echo "setup          - installs packages, manuals, and configures the user's environment"
	@echo "restore        - install the packages, configures the current user, and copies the files to the correct locactions (needs a backup made previously)"
	@echo "update         - updates the local repositories and make a backup of the user's files"
	@echo "backup         - makes a backup of the user files"
	@echo "dotfiles       - creates a directory containing dotfiles"
	@echo "tar            - creates a tarball containing a backup of files from the user and packages"
	@echo ""

setup: package-update man-update admin motd config
	@git clone --depth=1 https://github.com/tukainpng/dotfiles
	@git clone --depth=1 https://github.com/tukainpng/nvim ${HOME}/.config/nvim
	@cp -r ${DTDIR}/.config ${HOME}
	@cp -r ${DTDIR}/.local ${HOME}
	@cp -r ${DTDIR}/.bash* ${HOME}
	@rm -rf ${DTDIR}

restore: ${PKGREPO} ${MANREPO} ${BKDIR} admin motd config copy remove-trash

update: backup package-update man-update

admin:
	@printf "\033[44mCriando:\033[0m doas.conf\n"
	@echo "permit persist :wheel" > doas.conf
	@echo "permit nopass :wheel as root cmd /sbin/poweroff" >> doas.conf
	@echo "permit nopass :wheel as root cmd /sbin/reboot" >> doas.conf
	@echo "permit nopass :wheel as root cmd /bin/mount" >> doas.conf
	@echo "permit nopass :wheel as root cmd /bin/umount" >> doas.conf
	@echo "permit nopass :wheel as root cmd /sbin/cryptsetup" >> doas.conf

motd:
	@printf "\033[44mCriando:\033[0m motd\n"
	@echo "    /\ /\       ${USER}@${HOST} " > motd
	@echo "   // \  \      ----------- " >> motd
	@echo "  //   \  \     Alpine Linux " >> motd
	@echo " ///    \  \    " >> motd
	@echo " //      \  \   " >> motd
	@echo "          \     " >> motd

config: ${PKGREPO} ${MANREPO}
	@printf "\033[45mConfigurando ambiente do usuário:\033[0m ${USER}\n"
	@doas apk add --no-network ./${PKGREPO}/*
	@doas apk add --no-network ./${MANREPO}/*
	@doas rc-update add seatd
	@doas rc-update add elogind
	@doas rc-update add udev sysinit
	@doas rc-update add udev-trigger sysinit
	@doas rc-update add udev-settle sysinit
	@doas rc-update add udev-postmount default
	@doas rc-service --ifstopped udev start
	@doas rc-service --ifstopped udev-trigger start
	@doas rc-service --ifstopped udev-settle start
	@doas rc-service --ifstopped udev-postmount start
	@doas adduser ${USER} seat
	@doas chsh ${USER} -s /bin/bash

backup: critical-files
	@printf "\033[44mAtualizando o backup\033[0m\n"
	@mkdir -p ${BKDIR}/.config
	@mkdir -p ${BKDIR}/.local/share
	@mkdir -p ${BKDIR}/.local/bin
	@cp -r ${HOME}/.local/share/nvim ${BKDIR}/.local/share
	@cp -r ${HOME}/.local/share/emoji ${BKDIR}/.local/share
	@cp -r ${HOME}/.local/share/bookmarks ${BKDIR}/.local/share
	@cp -r ${HOME}/.local/share/todo ${BKDIR}/.local/share
	@cp -r ${HOME}/.local/bin/* ${BKDIR}/.local/bin
	@cp -r ${HOME}/.config/foot ${BKDIR}/.config
	@cp -r ${HOME}/.config/lf ${BKDIR}/.config
	@cp -r ${HOME}/.config/htop ${BKDIR}/.config
	@cp -r ${HOME}/.config/mako ${BKDIR}/.config
	@cp -r ${HOME}/.config/mpv ${BKDIR}/.config
	@cp -r ${HOME}/.config/nvim ${BKDIR}/.config
	@cp -r ${HOME}/.config/qutebrowser ${BKDIR}/.config
	@cp -r ${HOME}/.config/rofi ${BKDIR}/.config
	@cp -r ${HOME}/.config/sway ${BKDIR}/.config
	@cp -r ${HOME}/.config/vis ${BKDIR}/.config
	@cp -r ${HOME}/.config/user-dirs.dirs ${BKDIR}/.config
	@cp -r ${HOME}/.bash* ${BKDIR}/

critical-files:
	@printf "\033[44mFazendo backup de arquivos críticos\033[0m\n"
	@rm -rf ${BKDIR}
	@mkdir -p ${BKDIR}/.config
	@mkdir -p ${BKDIR}/.local/share
	@cp -r ${HOME}/.ssh ${BKDIR}
	@cp -r ${HOME}/.local/share/gnupg ${BKDIR}/.local/share
	@cp -r ${HOME}/.local/share/pass ${BKDIR}/.local/share
	@cp -r ${HOME}/.config/git ${BKDIR}/.config
	@cp -r ${HOME}/.config/gh ${BKDIR}/.config

man-update: man_list
	@printf "\033[44mAtualizando manuais\033[0m\n"
	@rm -rf ${MANREPO}
	@mkdir ${MANREPO}
	@apk fetch $$(cat man_list | tr "\n" " ")
	@mv *.apk ${MANREPO}

package-update: package_list
	@printf "\033[44mAtualizando pacotes\033[0m\n"
	@rm -rf ${PKGREPO}
	@mkdir ${PKGREPO}
	@apk fetch -R $$(cat package_list | tr "\n" " ")
	@mv *.apk ${PKGREPO}

copy: backup doas.conf motd
	@rm -rf ${BSDIR}
	@printf "\033[43mMovendo arquivos para:\033[0m ${BSDIR}\n"
	@cp -r backup ${BSDIR}
	@cp -r ${BSDIR}/* ${HOME}
	@cp -r ${BSDIR}/.config ${HOME}
	@cp -r ${BSDIR}/.local ${HOME}
	@cp -r ${BSDIR}/.ssh ${HOME}
	@cp -r ${BSDIR}/.bash* ${HOME}
	@chmod 0700 -R ${HOME}/.ssh
	@chmod +x ${HOME}/.bash*
	@doas cp doas.conf /etc/doas.d/
	@doas cp motd /etc/

dotfiles: backup
	@printf "\033[44mAtualizando ${DTDIR}\033[0m\n"
	@mkdir -p ${DOTFILES}/.local/bin
	@mkdir -p ${DOTFILES}/.local/share
	@cp -r ${BKDIR}/.config ${DOTFILES}
	@cp -r ${BKDIR}/.local/bin/* ${DOTFILES}/.local/bin
	@cp -r ${BKDIR}/.local/share/emoji ${DOTFILES}/.local/share
	@cp -r ${BKDIR}/.bash* ${DOTFILES}
	@rm -rf ${DOTFILES}/.local/bin/xdg*
	@rm -rf ${DOTFILES}/.config/nvim

remove-trash: ${BSDIR}
	@printf "\033[41mRemovendo lixo\033[0m\n"
	@rm doas.conf
	@rm motd
	@rm -rf ${BSDIR}

tar: update
	@printf "\033[46mCriando tarball...\033[0m\n"
	@tar -caf "$$(date +%d-%m-%Y_%T)".tar.xz ${BKDIR} ${PKGREPO} ${MANREPO} package_list man_list Makefile README.md
	@mkdir -p tarballs
	@mv *.xz tarballs

