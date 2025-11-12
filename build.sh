#!/bin/bash
set -ex
docker build . -f Dockerfile -t savimisha/marzban
docker push savimisha/marzban
