#!/bin/sh

. .env
# build 
flutter build web && \
ssh $LIBMUY_ENGLISH_SRV_HOST rm -rf $LIBMUY_ENGLISH_SRV_PATH/* && \
scp -r build/web/* $LIBMUY_ENGLISH_SRV_HOST:$LIBMUY_ENGLISH_SRV_PATH
