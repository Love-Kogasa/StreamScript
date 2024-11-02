{runStream} = require "./index"
require! fs
runStream fs.readFileSync( "test.stream" ).toString!