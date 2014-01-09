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

Where to put the files?
-----------------------

Rename the pimatic-plugin-template folder to pimatic-your-plugin and put it in the node_modules 
parent directory of pimatic.

Feel free to ask questions on github: 
[https://github.com/sweetpi/pimatic-plugin-template/issues](https://github.com/sweetpi/pimatic-plugin-template/issues)