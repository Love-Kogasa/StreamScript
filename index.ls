# 语法正则
export syntax =
   keyword : new RegExp "@.+"
   value : new RegExp "$[\\w\\_]+", "ig"
   # path : /\&.+/g
   # url : /\&\&.+/g
   #what : /[^\[\]]+(?=\])/g
   argsc : /[^\(\)]+(?=\))/g

# 标准库
std =
   node : yes
   read : ( fname )->
      if not fname
         new Promise (res)->
            process.stdin.once "data", ->
               process.stdin.end!
               res it.toString!.slice( 0, -1 )
      else
         require("fs").readFileSync fname
   write : ( string, fname ) ->
      if not fname
         process.stdout.write string.toString!
      else
         require("fs").writeFileSync fname, string

con =
   _history : ""
   node : yes
   read : -> @_history
   write : ( ...string ) ->
      console.log.apply @, string
      @_history += string.join(" ").toString!

fet =
   _body : ""
   node : yes
   read : -> @_body
   write : ( url, json = no ) ->>
      if Array.isArray url
         for link in url
            @write link
      else
         if json
            @_body = await (await fetch url).json!
         else
            @_body = await (await fetch url).text!

# 这个节点完全是因为我写完解释器就一点都不想动了()
cstr =
   _ret : void
   node : yes
   read : -> @_ret
   write : ( text, string, re = no ) ->
      if typeof text is "string"
         if re
            @_ret = (string or "") + text
         else
            @_ret = text + (string or "")
      else
         @_ret = text with (string or {})

tou =
   _ret : ""
   node : yes
   read : -> @_ret
   write : ( string ) ->
      @_ret = encodeURI string

pau =
   _ret : ""
   node : yes
   read : -> @_ret
   write : ( string ) ->
      @_ret = decodeURI string

json =
   _ret : void
   node : yes
   read : -> @_ret
   write : ( string, sj ) ->
      @_ret = if typeof string is "string" then JSON.parse string
      else JSON.stringify string, 0, sj

pobj =
   _value : void
   node : yes
   read : -> @_value
   write : ( obj, ...keys ) ->
      nobj = obj
      nvalue = void
      for key in keys
         nvalue = nobj[key]
         nobj = nvalue
      @_value = nvalue

jsn =
   _ret : void
   node : yes
   read : -> @_ret
   write : ( ...arg ) ->
      @_ret = eval( arg.0 ).apply global, arg.slice 1

tostr =
   _string : ""
   node : yes
   read : -> @_string
   write : ( ns )-> @_string = ns.toString!

tobuf =
   _buf : void
   node : yes
   read : -> @_buf
   write : ( string ) -> @_buf = Buffer.from string

clear =
   read : -> it
   write : -> void

export valueMap = new Map!
valueMap.set "Std", std
valueMap.set "Fetch", fet
valueMap.set "Console", con
valueMap.set "JsFunc", jsn
valueMap.set "Json", json
valueMap.set "ToUrl", tou
valueMap.set "ParseObject", pobj
valueMap.set "ParseUrl", pau
valueMap.set "Concat", cstr
valueMap.set "ToString", tostr
valueMap.set "ToBuffer", tobuf
valueMap.set "ClearTo", clear

export keywordMap = new Map!
keywordMap.set "@log", ( strings, values ) ->
   console.log strings.join " "
   do
      _value : strings.join " "
      node : yes
      read : -> @_value
      write : ( value ) -> @_value += value
keywordMap.set "@val", ( args, values ) ->
   values.set do
      args.0
      do
         _value : do ->
            try
               JSON.parse args.slice(1).join " "
            catch err
               args.slice(1).join " "
         node : yes
         read : -> @_value
         write : ( value ) ->
            try
               @_value += value
            catch err
               @_value = value with @_value
   values.get args.0
#keywordMap.set "@require", ( args, values ) ->
#   streamModule = { values: {}, keywords: {} }
#   if typeof module is "object"
#      eval (require "fs").readFileSync args.join " "
#   else
#      eval await (await fetch args.join " ").text!
#   for key, val of streamModule
#      values.set key, val
#   do
#      _vallist : Object.keys streamModule
#      node : yes
#      read : -> @_vallist
#      write : -> void
#keywordMap.set "@include", ( args, values ) ->
#   vm = void
#   if typeof module is "object"
#      vm = run (require "fs").readFileSync args.join " "
#   else
#      vm = run (await (await fetch args.join " ").text!)
#   vm.forEach (value, key) ->
#      values.set key, value
#   do
#      _vallist : vm
#      node : yes
#      read : -> @_vallist
#      write : -> void

# 工具函数
export concatMap = (...m)->
   md = new Map
   for map in m
      map.forEach ( val, key)->
         md.set key, val
   md

# 解释器
export runStream = ( code, values = valueMap, keywords = keywordMap ) ->>
   codeBlocks = code.split( ";;;" )
   for block in codeBlocks
      allnode = block.split "\n"
      localValues = []
      for node in allnode
         node = node.trim!
         if syntax.keyword.test node
            valuekeys = (node.match( syntax.value ) or [])
            for vk in valuekeys
               node = node.replace "$#vk", await values.get(vk).read().toString!
            addVal =
               node : keywords.get( node.split(" ").0 ) node.split(" ").slice(1), values
               #what : []
               args : []
            localValues.push( addVal )
         else
            #what = node.match syntax.what
            fargs = node.match syntax.argsc
            #node = node.replace new RegExp "\\[[^\\[\\]]+\\]", ""
            node = node.replace  new RegExp("\\([^\\(\\)]+\\)", "g"), ""
            if node.indexOf("$") is 0
               addVal =
                  node : values.get node.slice 1
                  #what : what or []
                  args : fargs or []
               localValues.push addVal
            else if node isnt ""
               try
                  addVal =
                     node :
                        node : yes
                        _value : JSON.parse node
                        read : -> @_value
                        write : ( value ) -> @_value = value
                     #what : what or []
                     args : fargs or []
                  localValues.push addVal
               catch err
                  void
      do await ->>
         nodereturn = []
         for index, nodeclass of localValues
            #console.log nodeclass
            args = for arg in nodeclass.args
               if arg.trim!.indexOf("$") is 0
                  await (values.get arg.trim!.slice 1).read!
               else
                  JSON.parse arg.trim!
            await nodeclass.node.write.apply nodeclass.node, (
               if index > 0 then [nodereturn[ index - 1 ]] else ([await nodeclass.node.read!] or [])
            ) ++ args
            if (Number(index)+1) isnt localValues.length then nodereturn.push await nodeclass.node.read.apply nodeclass.node, args
         void
   values