#!/bin/bash
# 全ポート開放 -P オプション ランダムにホスト側のポートが割り振られる
# 個別にポートフォア―ド -p オプション ホスト側とゲスト側のポートを固定して紐づける
# systemctl を使用するには systemd を PID 1 で起動する必要がある --privileged オプションを使い /sbin/init を指定する
docker run -d -P -p 10022:22 -p 8888:8888  --name mu1 --privileged myubuntu:20.04 /sbin/init

