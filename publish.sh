#!/bin/sh

# . .env
# flutter build web && \
# ssh $LIBMUY_ENGLISH_SRV_HOST rm -rf $LIBMUY_ENGLISH_SRV_PATH/* && \
# scp -r build/web/* $LIBMUY_ENGLISH_SRV_HOST:$LIBMUY_ENGLISH_SRV_PATH

flutter build web && \
cd gh-pages && \
git pull && \
rm -rf app/* && \
cp -r ../build/web/* app/ && \
git add --all && \
git commit -m "Publishing to gh-pages" && \
git push origin
