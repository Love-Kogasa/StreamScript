stream = require "./index"
{execSync} = require "child_process"
require! fs
args = process.argv.slice 2
setting =
   input: "index.stream"
   output: no
   target: "js"
   module: "yes"
   libs: []
   setting: no
libs = []
toJs = ->
   outstrings = ""
   if typeof it is "object" and not Array.isArray it
      outstrings += "{#{
         (for key, value of it
            "#key: #{toJs value}").join ","
      }}"
   else if typeof it is \function
      outstrings += it.toString!
   else
      outstrings += JSON.stringify it
   outstrings
for arg in args
   [key, val] = arg.split "="
   if key is libs and not Array.isArray libs
      val = val.split "&"
   setting[key] = val
if typeof setting.setting is "string"
   setting = setting with JSON.parse fs.readFileSync(setting.setting).toString!
output = ""
for lib in setting.libs
   libs.push require lib
valueMap = stream.concatMap.apply @, libs
if not setting.output
   stream.runStream fs.readFileSync(setting.input).toString!, stream.concatMap( valueMap, stream.valueMap )
else
   console.log "Building Now"
   reqlib = ""
   valueMap.forEach ( value, key) ->
      reqlib += "valueMap.set( #key, #{toJs value} );"
   if setting.module is "yes"
      output = "(async function(){
        #{fs.readFileSync("#{__dirname}/index.js").toString!}
        retv = {};\n
        #reqlib
        (await runStream(`#{fs.readFileSync(setting.input).toString!}`, valueMap)).forEach( ( value, key ) => {
          retv[ key ] = value
        });
        return retv
      })()"
   else
      output = "
        #{fs.readFileSync("#{__dirname}/index.js").toString!}
        #reqlib
        runStream(`#{fs.readFileSync(setting.input).toString!}`, valueMap)
      "
   fs.writeFileSync setting.output, output
   console.log "Build Succeed"
   if setting.target is "bin"
      console.log "Compiling Now"
      fs.renameSync setting.output, "_" + setting.output
      execSync "qjsc _#{setting.output}"
      fs.renameSync "a.out", setting.output
      fs.unlinkSync "_" + setting.output
      console.log "Compile Succeed"
