#!/usr/bin/env bash
set -e

CPANMURL='https://raw.github.com/miyagawa/cpanminus/master/cpanm'
VENDOR_DIR='/app/vendor/perl'
HEROKU_STACK=${HEROKU_STACK-'cedar-14'}

export AUTOMATED_TESTING=1      ## VM::EC2 to skip network tests
export NONINTERACTIVE_TESTING=1 ## http://www.dagolden.com/index.php/2098/the-annotated-lancaster-consensus/

rm -rf $VENDOR_DIR
mkdir -p $VENDOR_DIR

cd $VENDOR_DIR
curl -sL "$S3_BUCKET_NAME.s3.amazonaws.com/$HEROKU_STACK/perl-$PERL_VERSION.tgz" | tar xzf -
find . -exec touch {} \;
sleep 1
touch .
curl -sL $CPANMURL | bin/perl - --quiet --notest App::cpanminus
bin/cpanm --quiet --installdeps File::HomeDir
bin/cpanm --quiet --notest File::HomeDir ## can't find root's home directory on Heroku
bin/cpanm --quiet --installdeps Term::ReadKey
bin/cpanm --quiet --notest Term::ReadKey
bin/cpanm --quiet --installdeps Data::Dump::Streamer
bin/cpanm --quiet --notest Data::Dump::Streamer ## 2.38 fails on 5.22.0
bin/cpanm --quiet --installdeps LWP::Protocol::https
bin/cpanm --quiet --notest LWP::Protocol::https ## https://rt.cpan.org/Public/Bug/Display.html?id=104150
bin/cpanm --quiet --installdeps HTTP::Server::Simple
bin/cpanm --quiet --notest HTTP::Server::Simple ## 0.50 getaddrinfo / localhost fails on cedar stack
bin/cpanm --quiet Task::Moose MooseX::Daemonize Mouse
bin/cpanm --quiet Dancer Dancer2 Mojolicious Catalyst Catalyst::Devel
bin/cpanm --quiet Plack Starman Twiggy Carton local::lib
bin/cpanm --quiet DBI DBIx::Class DBIx::Class::Schema::Loader DBIx::Class::Migration SQL::Translator
bin/cpanm --quiet CHI Redis DBD::Pg Net::Amazon::S3
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

./s3cmd put --acl-public ~/perl-$PERL_VERSION-extras.tgz s3://$S3_BUCKET_NAME/$HEROKU_STACK/
