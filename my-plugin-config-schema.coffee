# #my-plugin configuration options

# Declare your config option for your plugin here. 

# Defines a `node-convict` config-schema and exports it.
module.exports =
  option1:
    doc: "Some option"
    format: String
    default: "foo"