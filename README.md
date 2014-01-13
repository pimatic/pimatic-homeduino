pimatic-plugin-template
=======================

A template for creating plugins. Clone this folder from: 

[https://github.com/sweetpi/pimatic-plugin-template](https://github.com/sweetpi/pimatic-plugin-template)


Required Skills
----------------

 * You should know JavaScript and know how to write JavaScript code.
 * You should know CoffeeScript. If not learn it! It is beatiful and makes things easyer for you. 
   Just read the [CoffeeScript introduction page](http://coffeescript.org/)
 * You should know [node.js](http://nodejs.org/) and have some basic knowledge about asynchronous 
   programming. If not read [this](http://book.mixu.net/node/ch7.html)
 * pimatic heavy used promises for aync operations. So check out the 
   [docs about Q promises](https://github.com/kriskowal/q).

If you like videos more:

 * [Coffeescript](http://www.youtube.com/watch?v=qR5p5s8CMBQ)
 * [About Q promises: Redemption from Callback Hell](http://www.youtube.com/watch?v=hf1T_AONQJU)

Files
-----

* [my-plugin.coffee](http://sweetpi.de/pimatic/docs/pimatic-plugin-template/my-plugin.html): 
  This should become the main source file of your Plugin. It provides a short source walkthrough.
* [my-plugin-config-shema.coffee](http://sweetpi.de/pimatic/docs/pimatic-plugin-template/my-plugin-config-shema.html): 
  Template for config definitions for your
  plugin.
* [my-device-config-shema.coffee](http://sweetpi.de/pimatic/docs/pimatic-plugin-template/my-device-config-shema): 
  Template for config definitions for a device the plugin could provide.
* package.json: The [npm package specification](https://npmjs.org/doc/json.html).


Setup the development envirement
-----------------------

Develop on a Linux box. It makes things easyer. You can develop on the Raspberry Pi but its too 
slow. If you don't have a Linux running (how can you?) then I suggest to use VirtualBox and 
install a Ubuntu.

###Instal node.js and CoffeeScript
* Install Node.js with the package manager of you distro `sudo apt-get install node` 
* Install CoffeeScript gloabaly with: `sudo npm install -g coffee-script`

###Download pimatic for development
* Create a folder where your development files should be in: `mkdir pimatic-dev`
* Change into this folder and `cd pimatic-dev`.
* Run `npm install pimatic` to install the pimatic framework. The framework get installed in
 `pimatic-dev/node_modules/pimatic`.
* Copy the default config: `cp node_modules/pimatic/congig_default.json config.json`
* Make the changes you wish and add your plugin name without the `pimatic-` prefix to the plugins section.

###Setup  your plugin
* Clone this plugin template on github.
* Chnage to the `pimatic/dev/node_modules` folder where pimatic was installed: `cd node_modules`
* Clone your repository: `git clone ...`. Your repository should now be in 
  `pimatic-dev/node_modules/pimatic-your-plugin`.
* Change into your plugin folder `cd pimatic-your-plugin` and edit the `package.json`. Take a look
  at the [npm package.json documentation](https://npmjs.org/doc/json.html) for infos.

###Adding package dependencies
* You can add other package dependencies by running `npm install something --save`. With the `--save`
  option npm will auto add the installed dependency in your `package.json`
* You can allways install all dependencies in the package.json with `npm install`

###Commit your changes to git
* Add all edited files like `git add package.json` then commit you changes with `git commit`.
* After that you can push you commited work to github: `git push`

###Running pimatic with your plugin
* Change into the `pimatic-dev` direcotry and run `coffee node_modules/pimatic/pimatic.js`.
* Install grunt `sudo npm install -g grunt-cli` [see also getting started](http://gruntjs.com/getting-started) 
* For Testing run `grunt test` to execute all test files under `test` and all test files of installed
  plugins under `pimatic-dev/node_modules/pimatic-your-plugin/test`. Additional [CoffeeLint](http://www.coffeelint.org/) 
  will check you source files.

Editor / IDE Setup
------------------
Coffescript is whitespcae sensitiv so be sure to use the following editor settings:

* tab size: 2
* translate tabs to spaces: true
* max line length: 100

I'm using [sublime text](http://www.sublimetext.com/) with [BetterCoffee package](https://github.com/aponxi/sublime-better-coffeescript) as a editor. 
A example config would be:

    {
      "folders":
      [
        {
          "path": "."
        }
      ],
      "settings":
      {
        "tab_size": 2,
        "translate_tabs_to_spaces": true,
        "rulers": [100]
      }
    }


Feel free to ask questions on github: 
[https://github.com/sweetpi/pimatic-plugin-template/issues](https://github.com/sweetpi/pimatic-plugin-template/issues)