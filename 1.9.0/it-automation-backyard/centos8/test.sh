#!/bin/bash -e

if [ -e /tmp ]; then
    # 存在する場合
  echo ari
else
    # 存在しない場合
  echo nashi
fi

echo $?
