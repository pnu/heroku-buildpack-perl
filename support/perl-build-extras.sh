#!/usr/bin/env bash
set -e

CPANMURL='https://raw.github.com/miyagawa/cpanminus/master/cpanm'
VENDOR_DIR='/app/vendor/perl'

rm -rf $VENDOR_DIR
mkdir -p $VENDOR_DIR

cd $VENDOR_DIR
curl -sL "$S3_BUCKET_NAME.s3.amazonaws.com/perl-$PERL_VERSION.tgz" | tar xzf -
find . -exec touch {} \;
sleep 1
touch .
curl -sL $CPANMURL | bin/perl - --quiet --notest App::cpanminus
bin/cpanm --quiet --notest File::HomeDir ## can't find root's home directory on Heroku
bin/cpanm --quiet Task::Moose
bin/cpanm --quiet Dancer Mojolicious Task::Catalyst Plack
bin/cpanm --quiet Starman Twiggy Carton local::lib
bin/cpanm --quiet DBI DBIx::Class DBIx::Class::Schema::Loader SQL::Translator
bin/cpanm --quiet CHI Redis DBD::Pg
bin/cpanm --quiet XML::LibXML MIME::Types XML::Atom XML::RSS

find . -newercm . | tar czf ~/perl-$PERL_VERSION-extras.tgz --no-recursion --files-from=/dev/stdin
cd ~

git clone https://github.com/s3tools/s3cmd
cd s3cmd
git checkout v1.5.0-beta1
cat >~/.s3cfg <<EOF
[default]
access_key = $AWS_ACCESS_KEY_ID
secret_key = $AWS_SECRET_ACCESS_KEY
use_https = True
EOF

./s3cmd put --acl-public ~/perl-$PERL_VERSION-extras.tgz s3://$S3_BUCKET_NAME
