#!/usr/bin/env bash
set -e

HEROKU_STACK=${HEROKU_STACK-'cedar-14'}

git clone git://github.com/tokuhirom/Perl-Build.git perl-build
perl-build/perl-build -Duserelocatableinc -j 4 $PERL_VERSION /app/vendor/perl
tar czf perl-$PERL_VERSION.tgz -C /app/vendor/perl .

git clone https://github.com/s3tools/s3cmd
cd s3cmd
git checkout v1.5.0-beta1

cat >~/.s3cfg <<EOF
[default]
access_key = $AWS_ACCESS_KEY_ID
secret_key = $AWS_SECRET_ACCESS_KEY
use_https = True
EOF

./s3cmd put --acl-public ~/perl-$PERL_VERSION.tgz s3://$S3_BUCKET_NAME/$HEROKU_STACK/
