# #my-device configuration options

# Declare your config option for MyDevice here. 

# Defines a `node-convict` config-schema and exports it.
module.exports =
  option1:
    doc: "Some int option"
    format: "int"
    default: 32
  option2: 
    doc: "Some string option"
    format: String
    default: "bar"