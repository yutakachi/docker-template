# Docker 開発環境構築（プロキシ設定あり）
## Docker イメージ作成からローカルレジストリ構築し各PCにイメージを展開（pull）するまで

https://qiita.com/SZZZUJg97M/items/dbdc784b92bde56cde3b  

を参考に作成  

## Dockerfile 作成  
docker 内に ubuntu を構築する Dockerfile を作成する  

- ubuntu:20.04 イメージをベースにする FROM OS：タグ  
- プロキシに対応させる  
- 必要なコマンドをインストールする  
- 

#### 必要（あったら開発が楽になった）コマンド  
**aptでインストールするもの**  

|インストールするもの|用途|
|---|---|
|build-essential|ビルドツール|
|software-properties-common|apt関連(search,repositoryとか)を使えるようにする|
|openssh-server<br>curl<br>wget<br>iputils-ping<br>net-tools|ネットワーク関連|
|unzip<br>vim<br>sudo<br>git<br>|開発に便利なコマンドと思うやつ|
|tzdata|タイムゾーンを設定できるようになる|
|bash-completion|bashの自動保管できるようになる|
|apache2|webサーバ|
|php<br>libapache2-mod-php<br>php-cli<br>php-mbstring|php関連|

**install.shを作ってインストールするもの**  

|インストールするもの|用途|
|---|---|
|nvm<br>node<br>yarn|webアプリ開発で必要なもの|
|composer|phpのライブラリ管理でつかう|


## イメージの作成（Dockerfile を読み込んでイメージを作成）  
```
$ docker build . -t myubuntu:20.04  

Dockerfile でヒアドキュメントを使用する場合は、BuildKit を有効にするため  

$ docker buildx build . -t myubuntu:20.04  

とする  

```

## イメージの確認  
```
$ docker images
```

## コンテナの起動  

全ポートを開いて特定のポートをポートマッピングする  
-P    全ポート開放  
-p xxx:yyy    ホスト側ポート：コンテナ側ポート  

```
$ ./dockerStart.sh

# systemctl を使用するには systemd を PID 1 で起動する必要がある --privileged オプションを使い /sbin/init を指定する
# ホスト：10022->docker：22 へポートフォア―ドして ssh の穴あけします。  
# ホスト：8888->docker:8888 へポートフォアードして http 開発用の穴あけします。http://ホストのIP:8888 で接続するため  
docker run -d -P -p 10022:22 -p 8888:8888 --name mu1 --privileged myubuntu:20.04 /sbin/init
```

#### systemd を使用すると docker stop 後の docker start でエラーになるので対処が必要
以下、対処方法  
```
$ vim /etc/docker/daemon.json
{ "exec-opts": ["native.cgroupdriver=systemd"] }

```

## SSH の接続
docker 内に構築した ubuntu のアカウント devUser IPアドレス 192.168.1.xx  
```
$ ssh -p 10022 devUser@192.168.1.xx
```

## 作成したイメージをローカルレジストリに登録
https://qiita.com/Brutus/items/da63d23be32d505409c6  

#### プライベートレジストリの作成（必要なら）

Docker プライベートレジストリ用のイメージをダウンロード
```
docker pull registry
```

Docker プライベートレジストリ コンテナの起動  
```
docker run -d -p 5000:5000 registry
```

Docker プライベートレジストリを GUI で操作する  
※ konradkleine/docker-registry-frontend:v2 は docker pull しなくても勝手に落ちてくる

コンテナの起動  
```
$ docker run \
  -d \
  -e ENV_DOCKER_REGISTRY_HOST=192.168.1.xx \
  -e ENV_DOCKER_REGISTRY_PORT=5000 \
  -p 8080:80 \
  konradkleine/docker-registry-frontend:v2
```


Docker プライベートレジストリからイメージ情報を取得する方法  
```
http://my-registry:port/v2/_catalog

http://192.168.1.xx:5000/v2/_catalog
```
#### プライベートレジストリ用のイメージを作成
```
docker tag [OPTIONS] IMAGE[:TAG] [REGISTRYHOST/][USERNAME/]NAME[:TAG]

docker tag myubuntu:20.04 localhost:5000/myubuntu

```
#### プライベートレジストリへ登録
```
docker push localhost:5000/myubuntu
```

## windodws + wsl + vscode-remote-containers 
ローカルリポジトリに登録したイメージをダウンロード（PULL）   
時間切れ未実施  

