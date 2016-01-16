#!/usr/bin/env bash
set -e

DIST_NAME="rakudo"
REPO_NAME="star"
PERL6_VM=${PERL6_VM:-'moar'}
PERL6_VERSION=${PERL6_VERSION:-'nom'}
HEROKU_STACK=${HEROKU_STACK:-'cedar-14'}
PERL_URL=${PERL_URL:-"https://heroku-buildpack-perl.s3.amazonaws.com/$HEROKU_STACK/perl6"}
PERL6_PACKAGE="${PERL_URL%/}/$DIST_NAME-$PERL6_VM-$PERL6_VERSION.tgz"
BUILD_PATH="/tmp/build-rakudo-$$"
VENDOR_PATH="/app/vendor/perl6"
REPO_PATH="/app/vendor/perl6-$REPO_NAME"

function join { local IFS="$1"; shift; echo "$*"; }

rm -rf $VENDOR_PATH; mkdir -p $VENDOR_PATH

mkdir -p $BUILD_PATH
exec  > >(tee -a $BUILD_PATH/log.txt)
exec 2> >(tee -a $BUILD_PATH/log.txt >&2)

cd $BUILD_PATH
curl -sL $PERL6_PACKAGE | tar xzf - -C "$VENDOR_PATH" &> /dev/null
export PATH=$VENDOR_PATH/bin:$PATH
export PATH=$VENDOR_PATH/share/perl6/site/bin:$PATH
CURRENT_PERL6_VERSION=`perl6 -e'print $*PERL.compiler.version' 2> /dev/null`
CURRENT_PERL6_VM=`perl6 -e'print $*VM.name' 2> /dev/null`
echo "Current perl6 version is '$CURRENT_PERL6_VERSION' on '$CURRENT_PERL6_VM'"

cd $BUILD_PATH
rm -rf $REPO_PATH; mkdir -p $REPO_PATH
export PERL6LIB="inst#$REPO_PATH"
panda --prefix="inst#$REPO_PATH" --force install Bailador
panda --prefix="inst#$REPO_PATH" --force install Task::Star || { TASK_STAR_FAIL=1; }

tar cvzf dist.tgz -C $REPO_PATH .

git clone -b v1.5.0-beta1 https://github.com/s3tools/s3cmd.git s3cmd
cd s3cmd
cat >~/.s3cfg <<EOF
[default]
access_key = $AWS_ACCESS_KEY_ID
secret_key = $AWS_SECRET_ACCESS_KEY
use_https = True
EOF

UPLOAD_NAME="$HEROKU_STACK/perl6/$DIST_NAME-$CURRENT_PERL6_VM-$CURRENT_PERL6_VERSION-$REPO_NAME"
echo "### UPLOAD $UPLOAD_NAME ###"
./s3cmd put     --acl-public $BUILD_PATH/log.txt  s3://$S3_BUCKET_NAME/$UPLOAD_NAME.log
if [ -z "$TASK_STAR_FAIL" ]; then
    ./s3cmd put --acl-public $BUILD_PATH/dist.tgz s3://$S3_BUCKET_NAME/$UPLOAD_NAME.tgz
fi

#echo "### SMOKE ###"
#cd $BUILD_PATH
#PANDA_SUBMIT_TESTREPORTS=1 panda --exclude="XML::Query,v5" smoke || true
#cp $BUILD_PATH/log $BUILD_PATH/$DIST_NAME-$CURRENT_PERL6_VERSION-smoke.log
#cd $BUILD_PATH/s3cmd
#./s3cmd put --acl-public $BUILD_PATH/$DIST_NAME-$CURRENT_PERL6_VERSION-smoke.log s3://$S3_BUCKET_NAME/$HEROKU_STACK/
