# Webgrind

Xdebug Profiling Web Frontend in PHP

[https://github.com/jokkedk/webgrind](https://github.com/jokkedk/webgrind)

## Summary

Webgrind is a [Xdebug](http://www.xdebug.org) profiling web frontend in PHP. It implements a subset of the features of [kcachegrind](http://kcachegrind.sourceforge.net/html/Home.html) and installs in seconds and works on all platforms. For quick'n'dirty optimizations it does the job. Here's a screenshot showing the output from profiling:

[![](http://jokke.dk/media/2008-webgrind/webgrind_small.png)](http://jokke.dk/media/2008-webgrind/webgrind_large.png)

## Features

* Super simple, cross platform installation - obviously :)
* Track time spent in functions by self cost or inclusive cost. Inclusive cost is time inside function + calls to other functions.
* See if time is spent in internal or user functions.
* See where any function was called from and which functions it calls.
* Generate a call graph using [gprof2dot.py](https://github.com/jrfonseca/gprof2dot)
