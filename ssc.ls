stream = require "./index"
{execSync} = require "child_process"
require! fs
args = process.argv.slice 2
setting =
   input: "index.stream"
   output: no
   target: "js"
   module: "yes"
   setting: no
for arg in args
   [key, val] = arg.split "="
   setting[key] = val
if typeof setting.setting is "string"
   setting = JSON.parse fs.readFileSync(setting.setting).toString!
output = ""
if not setting.output
   stream.runStream fs.readFileSync(setting.input).toString!
else
   console.log "Building Now"
   if setting.module is "yes"
      output = "(async function(){
        #{fs.readFileSync("#{__dirname}/index.js").toString!}
        retv = {}
        (await runStream(`#{fs.readFileSync(setting.input).toString!}`)).forEach( ( value, key ) => {
          retv[ key ] = value
        });
        return retv
      })()"
   else
      output = "
        #{fs.readFileSync("#{__dirname}/index.js").toString!}
        runStream(`#{fs.readFileSync(setting.input).toString!}`)
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
