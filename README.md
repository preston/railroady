# RailRoady

[![Build Status](https://travis-ci.org/preston/railroady.svg?branch=master)](https://travis-ci.org/preston/railroady)

RailRoady generates Rails 3/4/5 model (ActiveRecord, Mongoid, Datamapper) and controller UML diagrams as cross-platform .svg files, as well as in the DOT language.

Code is based on the original "railroad" gem, patched and maintained over the years. Lineage can be traced via GitHub.

I (Preston Lee) am not trying to hijack Peter Hoeg or Javier's project, but rather create a dedicated, lean gem that can be used without major issue on Rails projects. Rails v2 is not supported.

# System Requirements

You MUST have the the following utilities available at the command line.
  * `dot` and `neato`.

  * `sed`, which should already be available on all sane UNIX systems.

## Mac users

Brew users can install via:

    brew install graphviz

MacPorts users can install in via

    sudo port install graphviz


## Ubuntu users

Ubuntu users can install in via

    sudo apt-get install graphviz

# Usage

The easiest (and recommend) usage is to include railroady as a development dependency with your Rails 3 Gemfile, like so...

    group :development, :test do
        gem 'railroady'
    end

...and then run the master rake task...

    rake diagram:all

This should generate four doc/\*.svg files that can be opened in (most) web browsers as well as dedicated document viewers supporting the Scalable Vector Graphics format.

## Support for Engines

Generate diagram for models and controllers including those in the engines.

    rake diagram:all_with_engines

## Alternate Usage

Alternatively, you may run the 'railroady' command-line program at the Rails application's root directory. You can redirect its output to a .dot file or pipe it to the dot or neato utilities to produce a graphic. Model diagrams are intended to be processed using dot and controller diagrams are best processed using neato.

    railroady [options] command

## Options

  	Common options:
      	-b, --brief                      Generate compact diagram
                                         (no attributes nor methods)
      	-s, --specify file1[,fileN]      Specify only given files
      	-e, --exclude file1[,fileN]      Exclude given files
      	-i, --inheritance                Include inheritance relations
      	-l, --label                      Add a label with diagram information
                                         (type, date, migration, version)
      	-o, --output FILE                Write diagram to file FILE
      	-r, --root PATH                  Set PATH as the application root
      	-v, --verbose                    Enable verbose output
                                         (produce messages to STDOUT)
      	-x, --xmi                        Produce XMI instead of DOT
                                         (for UML tools)
        --alphabetize                Sort methods alphabetically

  	Models diagram options:
      	-a, --all                        Include all models
                                         (not only ActiveRecord::Base derived)
          	--show-belongs_to            Show belongs_to associations
          	--hide-through               Hide through associations
          	--all-columns                Show all columns (not just content columns)
          	--hide-magic                 Hide magic field names
          	--hide-types                 Hide attributes type
        --excluded_classes class1[,classN] Exclude given classes (helpful when you can't reference a file, for example with PaperTrail::Version or other gems)
      	-j, --join                       Concentrate edges
      	-m, --modules                    Include modules
      	-p, --plugins-models             Include plugins models
      	-z, --engine-models              Include engine models
          	--include-concerns           Include models in concerns subdirectory
      	-t, --transitive                 Include transitive associations
                                       	(through inheritance)                                

  	Controllers diagram options:
          	--hide-public                Hide public methods
          	--hide-protected             Hide protected methods
          	--hide-private               Hide private methods
          	--engine-controllers         Include engine controllers

  	Other options:
      	-h, --help                       Show this message
          	--version                    Show version and copyright

      	-c, --config FILE                File to load environment (defaults to config/environment)

## Commands

You must supply one of these:

    -M, --models                     Generate models diagram
    -C, --controllers                Generate controllers diagram
    -A, --aasm                       Generate "acts as state machine" diagram

## Examples

    railroady -o models.dot -M
      Produces a models diagram to the file 'models.dot'
    railroady -a -i -o full_models.dot -M
      Models diagram with all classes showing inheritance relations
    railroady -M | dot -Tsvg > models.svg
      Model diagram in SVG format
    railroady -C | neato -Tpng > controllers.png
      Controller diagram in PNG format
    railroady -h
      Shows usage help


# Processing DOT files

To produce a PNG image from model diagram generated by RailRoady you can
issue the following command:

    dot -Tpng models.dot > models.png

If you want to do the same with a controller diagram, use neato instead of
dot:

    neato -Tpng controllers.dot > controllers.png

If you want to produce SVG (vectorial, scalable, editable) files, you can do
the following:

    dot -Tsvg models.dot > models.svg
    neato -Tsvg controllers.dot > controllers.svg

Important: There is a bug in Graphviz tools when generating SVG files that
cause a text overflow. You can solve this problem editing (with a text
editor, not a graphical SVG editor) the file and replacing around line 12
"font-size:14.00;" by "font-size:11.00;", or by issuing the following command
(see "man sed"):

    sed -i 's/font-size:14.00/font-size:11.00/g' file.svg

Note: For viewing and editing SVG there is an excellent opensource tool
called Inkscape (similar to Adobe Illustrator. For DOT processing you can
also use Omnigraffle (on Mac OS X).

= Rake Tasks

As of Preston Lee's Rails 3/4/5 modifications, including RailRoady as a project development dependency will automatically add a set of rake tasks to your project. Sweet! (Run `rake -T` to check them out.)


# Requirements

RailRoady has been tested with the following Ruby and Rails versions

## Ruby
* 1.9.2+
* 2.0.0+

## Rails
* 3.0.3+
* 4.0.0+
* 5.0.0+

There are no additional requirements (nevertheless, all your Rails application
requirements must be installed).

In order to view/export the DOT diagrams, you'll need the processing tools
from Graphviz.

= Website and Project Home

http://railroady.prestonlee.com

# License

RailRoady is distributed under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

See LICENSE for details.

## Copyright

Copyright (c) 2007-2008 Javier Smaldone
Copyright (c) 2009 Peter Hoeg
Copyright (c) 2010-2016 Preston Lee

See LICENSE for details.

## Authors

Authors/Contributors (in approximate order of appearance):

* Javier Smaldone (javier |at| smaldone |dot| com |dot| ar)
* Elliot Smith
* Juan Ignacio Pumarino
* Hajime Baba
* Ana Nelson
* Peter Hoeg
* John McCaffrey
* David Jones
* Mike Dalessio
* [Preston Lee](https://www.prestonlee.com) and [Lee Does](https://www.leedoes.com), the vendor providing maintenance.
* Tim Harvey
* Atli Christiansen
* John Bintz (http://www.coswellproductions.com/)

And of course, many thanks to the many patch submitters and testers that make this possible!
