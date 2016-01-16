#!/usr/bin/env bash
set -e

DIST_NAME="rakudo"
RAKUDO_CONFIGURE_OPTS=${RAKUDO_CONFIGURE_OPTS:-'--gen-moar --gen-nqp --backends=moar'}
RAKUDO_REPO=${RAKUDO_REPO:-'https://github.com/rakudo/rakudo.git'}
PANDA_REPO=${PANDA_REPO:-'https://github.com/pnu/panda.git'}
RAKUDO_VERSION=${RAKUDO_VERSION:-'nom'}
PANDA_VERSION=${PANDA_VERSION:-'master'}
HEROKU_STACK=${HEROKU_STACK:-'cedar-14'}
BUILD_PATH="/tmp/build-rakudo-$$"
VENDOR_PATH="/app/vendor/perl6"

mkdir -p $BUILD_PATH
exec  > >(tee -a $BUILD_PATH/log.txt)
exec 2> >(tee -a $BUILD_PATH/log.txt >&2)

rm -rf $VENDOR_PATH; mkdir -p $VENDOR_PATH

cd $BUILD_PATH
git clone -b $RAKUDO_VERSION $RAKUDO_REPO rakudo
git clone --recursive -b $PANDA_VERSION $PANDA_REPO panda
git clone -b v1.5.0-beta1 https://github.com/s3tools/s3cmd.git s3cmd

cd $BUILD_PATH/rakudo
perl Configure.pl $RAKUDO_CONFIGURE_OPTS --prefix=$VENDOR_PATH
make test
make install
export PATH=$VENDOR_PATH/bin:$PATH
export PATH=$VENDOR_PATH/share/perl6/site/bin:$PATH
CURRENT_PERL6_VERSION=`perl6 -e'print $*PERL.compiler.version' 2> /dev/null`
CURRENT_PERL6_VM=`perl6 -e'print $*VM.name' 2> /dev/null`
echo "Current perl6 version is '$CURRENT_PERL6_VERSION' on '$CURRENT_PERL6_VM'"

cd $BUILD_PATH/panda
perl6 bootstrap.pl

cd $BUILD_PATH
tar cvzf dist.tgz -C $VENDOR_PATH .

cd $BUILD_PATH/s3cmd
cat >~/.s3cfg <<EOF
[default]
access_key = $AWS_ACCESS_KEY_ID
secret_key = $AWS_SECRET_ACCESS_KEY
use_https = True
EOF

UPLOAD_NAME="$HEROKU_STACK/perl6/$DIST_NAME-$CURRENT_PERL6_VM-$RAKUDO_VERSION"
echo "### UPLOAD $UPLOAD_NAME ###"
./s3cmd put --acl-public $BUILD_PATH/dist.tgz s3://$S3_BUCKET_NAME/$UPLOAD_NAME.tgz
./s3cmd put --acl-public $BUILD_PATH/log.txt  s3://$S3_BUCKET_NAME/$UPLOAD_NAME.log

UPLOAD_NAME="$HEROKU_STACK/perl6/$DIST_NAME-$CURRENT_PERL6_VM-$CURRENT_PERL6_VERSION"
echo "### UPLOAD $UPLOAD_NAME ###"
./s3cmd put --acl-public $BUILD_PATH/dist.tgz s3://$S3_BUCKET_NAME/$UPLOAD_NAME.tgz
./s3cmd put --acl-public $BUILD_PATH/log.txt  s3://$S3_BUCKET_NAME/$UPLOAD_NAME.log
