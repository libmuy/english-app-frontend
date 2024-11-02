#!/bin/sh

. .env
flutter build web && \
ssh $LIBMUY_ENGLISH_SRV_HOST find $LIBMUY_ENGLISH_SRV_PATH/docs -type f ! -name 'CNAME' -delete && \
ssh $LIBMUY_ENGLISH_SRV_HOST find $LIBMUY_ENGLISH_SRV_PATH/docs -type d -empty -delete && \
scp -r build/web/* $LIBMUY_ENGLISH_SRV_HOST:$LIBMUY_ENGLISH_SRV_PATH/docs && \
ssh $LIBMUY_ENGLISH_SRV_HOST "cd $LIBMUY_ENGLISH_SRV_PATH && ./commit.sh 'Publishing to gh-pages'"

# flutter build web && \
# cd gh-pages && \
# git pull && \
# find . -type f ! -name 'CNAME' -delete && \
# find . -type d -empty -delete && \
# cp -r ../build/web/* docs/ && \
# git add --all && \
# git commit -m "Publishing to gh-pages" && \
# git push origin
