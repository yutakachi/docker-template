# syntax=docker/dockerfile:1.3-labs

FROM ubuntu:20.04

# 入力待ちを無視する　apt install 時に timezone の選択待ちで止まるので無視する設定
ENV DEBIAN_FRONTEND=noninteractive

# proxy が必要な場合は設定する
# docker コンテナに proxy を教える
# ENV https_proxy "http://proxy.com:80"
# ENV http_proxy "http://proxy.com:80"
# ENV ftp_proxy "http://proxy.com:80"
# no_proxy アスタリスク or サブネットマスク が効かない場合は、直接IPアドレスを指定する必要がある
# ENV no_proxy "127.0.0.1, localhost, 192.168.*, 192.168.1.0/24, 192.168.1.xx"

# docker コンテナの proxy 設定でもダメなら ubuntu で proxy 設定を行う
# RUN touch /etc/profile.d/proxy.sh
# RUN echo "\
# COPY <<EOF /etc/profile.d/proxy.sh
# export http_proxy=http://proxy.com:80
# export https_proxy=http://proxy.com:80
# export ftp_proxy=http://proxy.com:80
# export no_proxy='"127.0.0.1, localhost, 192.168.*, 192.168.1.0/24, 192.168.1.xx"'
# EOF

# apt proxy 設定
# ヒアドキュメントでは syntax errpr が出力されてしまうので echo で作成
# RUN touch /etc/apt/apt.conf
# RUN echo "\
# Acquire::http::Proxy \"http://proxy.com:80\";\n\
# Acquire::https::Proxy \"http://proxy.com:80\";\n\
# Acquire::http::Pipeline-Depth 0;" >> /etc/apt/apt.conf
# RUN cat /etc/apt/apt.conf

# wget proxy 設定
# vscode 接続する際に vscode は裏で wget を使用して vscoce-server をダウンロードするため proxy 設定が必要
# RUN touch /home/devUser/.wgetrc
# COPY <<EOF /home/devUser/.wgetrc
# http_proxy=http://proxy.com:80
# https_proxy=http://proxy.com:80
# EOF
# curl proxy 設定
# COPY <<EOF /home/devUser/.curlrc
# proxy=http://proxy.com:80
# EOF

# 必要なコマンドをインストール
RUN <<EOF
	apt update
	apt -y upgrade
	apt install -y build-essential
	apt install -y software-properties-common
	apt install -y curl wget unzip vim sudo
	apt install -y git
	apt install -y tzdata
	apt install -y bash-completion
	apt install -y iputils-ping net-tools
	apt install -y apache2 php libapache2-mod-php
	apt install -y php-cli php-mbstring
EOF

# ユーザを追加(-m devUserディレクトリ作成する)
RUN useradd -m devUser
# sudo を使えるようにする
RUN gpasswd -a devUser sudo
RUN echo 'devUser:devPass' | chpasswd

# ログイン後のシェルを bash に設定
RUN sed -i 's/devUser:x:1000:1000::\/home\/devUser:\/bin\/sh/devUser:x:1000:1000::\/home\/devUser:\/bin\/bash/g' /etc/passwd
# git log で文字化対応
RUN echo 'export LESSCHARSET=utf-8' >> /home/devUser/.bashrc

# ssh 設定
RUN apt install -y openssh-server
RUN mkdir /var/run/sshd
# root で入ることはしないのでコメントアウト
# RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 開発環境を作るための install.sh を作成する。ubuntu 構築後、ログインして install.sh を実行する
# nvm インストール
RUN echo '#!/bin/bash'"\n"'wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash'"\n"'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"'"\n"'[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'"\n" >> /home/devUser/install.sh
# node インストール(LTSバージョン)
RUN echo 'nvm install --lts --latest-npm'"\n" >> /home/devUser/install.sh
# yarn インストール
RUN echo 'curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -'"\n" >> /home/devUser/install.sh
RUN echo 'echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list'"\n" >> /home/devUser/install.sh
RUN echo 'sudo apt update'"\n" >> /home/devUser/install.sh
RUN echo 'sudo apt install yarn'"\n" >> /home/devUser/install.sh
# composer インストール
RUN echo '# php -r "copy('\''https://getcomposer.org/installer'\', \''composer-setup.php'\'');"'"\n" >> /home/devUser/install.sh
# php -r copy は proxy を超えられないので curl で代替えする
RUN echo '# php -r copy can not cross the proxy. Use curl as an alternative. ' >> /home/devUser/install.sh
RUN echo 'curl -sS https://getcomposer.org/installer -o composer-setup.php' >> /home/devUser/install.sh
RUN echo 'HASH=`curl -sS https://composer.github.io/installer.sig`' >> /home/devUser/install.sh
RUN echo 'php -r "if (hash_file('\''sha384'\', \''composer-setup.php'\'') === '\''$HASH'\'') { echo '\''Installer verified'\''; } else { echo '\''Installer corrupt'\''; unlink('\''composer-setup.php'\''); } echo PHP_EOL;"'"\n" >> /home/devUser/install.sh
RUN echo 'sudo -E php composer-setup.php --install-dir=/usr/local/bin --filename=composer'"\n" >> /home/devUser/install.sh
RUN echo 'php -r "unlink('\''composer-setup.php'\'');"'"\n" >> /home/devUser/install.sh

# シェルの再起動(source ~/.bashrcせずに済む）
RUN echo 'exec $SHELL -l'"\n" >> /home/devUser/install.sh

RUN chown devUser:devUser /home/devUser/install.sh
RUN chmod 755 /home/devUser/install.sh

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

