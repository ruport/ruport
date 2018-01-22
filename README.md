[![Build Status][BS img]](https://travis-ci.org/ruport/ruport)

## What Ruport Is

Ruby Reports (Ruport) is an extensible reporting system.

It aims to be as lightweight as possible while still providing core support
for data aggregation and manipulation as well as multi-format rendering
of reports.

Ruport provides tools for using a number of data sources, including CSV files,
ActiveRecord models, and raw SQL connections via RubyDBI (through ruport-util).

Data manipulation is easy as there are standard structures that support
record, table, and grouping operations.  These all can be extended to
implement custom behavior as needed.

For common tasks, Ruport provides formatters for CSV, HTML, PDF, and text-
based reports.  However, the real power lies in building custom report
controllers and formatters.  The base formatting libraries provide a number
of helper functions that will let you build complex reports while maintaining
a DRY and consistent interface.

To get a quick feel for what you can accomplish with Ruport, take a look at
a few simple examples provided on our web site:

https://ruport.github.io/examples.html

Since Ruport's core support is intentionally minimalistic, you may be looking
for some higher level support for specific needs such as graphing, invoices,
report mailing support, etc.  For this, you may wish to take a look at the
ruport-util package, which contains some generally useful tools and libraries
to extend Ruport's capabilities.

## Installation

To install ruport via rubygems:

```sh
$ sudo gem install ruport
```

Check to see if it installed properly:

```sh
$ ruby -e "require 'ruport'; puts Ruport::VERSION"
```

If you get an error, please let us know on our mailing list.

### Dependencies

#### Formatting

Ruport relies on PDF::Writer for its formatting support.
If you want to make use of textile helpers, you'll also need RedCloth.

#### Database interaction

If you wish to use Ruport to report against a Rails project, you'll need
ActiveRecord and the `acts_as_reportable` gem.

If you want to use Ruport::Query for raw SQL support, you'll need to
install `ruport-util`, `RubyDBI` and whatever database drivers you might
need.

## Resources

Our developers have published a free-content book about all things
Ruport, including complete coverage of acts_as_reportable and some of
ruport-util's features.  This book serves as the definitive guide to
Ruport, so all users should become acquainted with it:

https://ruport.github.io

If you are looking to dig a little deeper, there are a couple more resources
that may be helpful to you.

- The latest stable API documentation is available at: http://rubydoc.info/gems/ruport/frames
- The code repository is on GitHub: https://github.com/ruport/ruport
- Our issues tracker is at https://github.com/ruport/ruport/issues

## Hacking

If you'd like to contribute code to Ruport, fork the repository and open a PR!

We are very responsive to contributors, and review every patch we receive
fairly quickly.  Most contributors who successfully get a patch or two applied
are given write access to the repositories and invited to join Ruport's
development team.  Since we view every user as potential contributor, this
approach works well for us.

So if you want to help out with Ruport, we'll happy accept your efforts!

[BS img]: https://travis-ci.org/ruport/ruport.svg?branch=master
