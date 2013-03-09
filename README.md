Heroku buildpack: Perl
======================

This is a Heroku buildpack that runs any PSGI based web applications using Starman.

Usage
-----

Example usage:

    $ ls
    cpanfile
    app.psgi
    lib/

    $ cat cpanfile
    requires 'Plack', '1.0000';
    requires 'DBI', '1.6';

    $ heroku create --buildpack http://github.com/pnu/heroku-buildpack-perl.git

    $ git push heroku master
    ...
    -----> Heroku receiving push
    -----> Fetching custom buildpack
    -----> Perl/PSGI app detected
    -----> Installing dependencies

The buildpack will detect that your app has an `app.psgi` in the root.

Libraries
---------

Dependencies can be declared using `cpanfile` or traditional `Makefile.PL` and `Build.PL`, and the buildpack will install these dependencies using [cpanm](http://cpanmin.us) into `./local` directory.

Prebuilt libraries
------------------

Building all dependecies of a typical Catalyst application for the first time may timeout the slug compilation. However, this is not an issue for incremental builds, as the `./local` directory is cached between builds.

To avoid the timeout, you can prebuild the libraries, and specify an environment variable `LOCALURL` that points to a tar package. The `./local` directory is replaced with the content of this tar before building rest of the dependecies.

As an example, here are the steps I've used to bootstrap the libraries for such projects. First upload the `cpanfile` to some url. Github gist works fine for this purpose. You'll also need a S3 bucket for hosting the tar package. After creating the heroku application, but before doing the git push (that would timeout while installing the dependencies), install the dependencies in a one-off process:

    $ heroku config:set AWS_ACCESS_KEY_ID=xxx
    $ heroku config:set AWS_SECRET_ACCESS_KEY=yyy
    $ heroku config:set S3_BUCKET_NAME=zzz

    $ heroku run 'curl -sL https://raw.github.com/pnu/heroku-vendor-cpanfile/master/build | CPANFILE=https://raw.github.com/gist/3713534/7430a2eab5ac6f959d69aa3042052b417e5d27ac/cpanfile bash'

    $ heroku config:set LOCALURL=http://zzz.s3.amazonaws.com/local-nnn.tar.gz
    $ heroku labs:enable user-env-compile

After doing the initial push, you can unset the LOCALURL and disable user-env-compile.
