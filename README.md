pimatic-plugin-template
=======================

See the [development guide](http://pimatic.org/guide/development/required-skills-readings/) for
usage.

Some Tips:

###Adding package dependencies
* You can add other package dependencies by running `npm install something --save`. With the `--save`
  option npm will auto add the installed dependency in your `package.json`
* You can always install all dependencies in the package.json with `npm install`

###Commit your changes to git
* Add all edited files with `git add file`. For example: `git add package.json` then commit you changes 
  with `git commit`.
* After that you can push you commited work to github: `git push`