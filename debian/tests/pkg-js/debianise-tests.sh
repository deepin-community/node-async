#! /bin/bash

# The provided tests test the uncompiled sources rather than the
# compiled (and possibly minified) dist/* files.  They also fail
# because they use an older version of mocha (or something like that).
# We modify the test files to address both of these problems.  The fix
# is slightly different during build and for autopkgtest; for the latter,
# the node-async package is already installed so we can use that.

set -e

mode=$1

cp -a test localtest

# Most tests require async.js via "require('../lib')".  But some have
# other approaches; we address those first.

case "$mode" in
    build)
	async=../dist/async.js
	async2=../../dist/async.js
        ;;
    autopkgtest)
        async=async
	async2=async
	;;
    *)
	echo "$0 needs to be called with argument 'build' or 'autopkgtest'" >&2
	exit 1
	;;
esac

perl -i -pe "s%\Qvar Heap = require('../lib/internal/Heap').default;\E%var {Heap} = require('$async');%" localtest/heap.js
perl -i -pe "s%\Qvar async = require('../lib/index.js');\E%var async = require('$async');%" localtest/auto.js
perl -i -pe "s%\Qvar DLL = require('../lib/internal/DoublyLinkedList').default;\E%var {DLL} = require('$async');%" localtest/linked_list.js
perl -i -pe "s%\Qvar {isAsync} = require('../lib/internal/wrapAsync');\E%var {isAsync} = require('$async');%" localtest/asyncFunctions.js
perl -i -pe "s%\Qconst {default: wrapAsync} = require('../../lib/internal/wrapAsync')\E%const {default: wrapAsync} = require('$async2');%" localtest/es2017/awaitableFunctions.js
perl -i -pe "s%\Qvar async = require('../../lib');\E%var async = require('$async2');%" localtest/es2017/*.js
perl -i -pe "s%\Qvar async = require('../lib');\E%var async = require('$async');%" localtest/*.js

# And one module has been renamed
perl -i -pe 's%babel-register%\@babel/register%' localtest/mocha.opts
