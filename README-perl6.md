Heroku buildpack: Rakudo Perl 6
===============================

Usage
-----

    $ git init
    $ cat >META.info
    {
       "name": "WebApp",
        "depends": [ "Bailador" ]
    }
    ^D
    $ cat >app.pl
    use Bailador;
    get '/' => sub {
        "hello world"
    }
    baile( Int(%*ENV<PORT> || 5000) );
    ^D
    $ git add -A; git commit -m 'implement the app'
    $ heroku create --buildpack 'https://github.com/pnu/heroku-buildpack-perl#christmas'
    $ git push heroku master
    $ curl https://myapp-name-1234.herokuapp.com/
    hello world
    $ heroku run perl6 -e\'.print for ^5\'
    Running `perl6 -e'.say for ^5'` attached to terminal... up, run.7985
    01234

By default this buildpack uses the version "moar-nom" found in AWS S3 bucket
https://heroku-buildpack-perl.s3.amazonaws.com/ (path prefix cedar-14/perl6/).
You can specify the version with heroku configuration, or by adding file
`.perl6-version` to the root directory of the project. Eg.

    $ echo "moar-2016.04.15.gb.3.d.8169" >.perl6-version
    $ git add .perl6-version; git commit -m 'set perl6 version'

    or..

    $ heroku config:set BUILDPACK_PERL6_VERSION=moar-2016.03

Next build will use the specified version. See bucket URL above for the
list of currently available versions.

Compiling rakudo
----------------

Script `support/rakudo-build.sh` can be used to build your own rakudo versions.
The build script runs on Heroku, and uploads the compiled package to a S3 bucket.
S3 credentials and bucket name are specified in the environment.

    $ heroku create     # create a build server, eg. your-app-1234
    $ heroku config:set AWS_ACCESS_KEY_ID="xxx" AWS_SECRET_ACCESS_KEY="yyy" S3_BUCKET_NAME="heroku-buildpack-rakudo" HEROKU_STACK="cedar-14" --app your-app-1234
    $ heroku run 'curl -sL https://raw.github.com/pnu/heroku-buildpack-rakudo/christmas/support/rakudo-build.sh | RAKUDO_VERSION="nnn" bash' --app your-app-1234
    [...]
    $ heroku destroy --app your-app-1234 --confirm your-app-1234

You can use the same build server to build multiple versions concurrently.
Environment variable `RAKUDO_VERSION` specifies the rakudo version to build.
It can be anything that works for `git checkout`. If not specified, default
is HEAD of the default branch.

Compiled package is saved as rakudo-VM-VERSION.tgz, where VERSION is the version
string given by `$*PERL.compiler.version` and VM is `$*VM.name`.
