# StreamScript
初中生独立开发的"流式"编程语言  
## AnyExample
StreamScript有着与众不同且轻松易学的语法.  
下面事一些Example
### HelloWorld
```bash
@log HelloWorld;;;
"HelloWorld"
$Console
```
### Request And Print As Sync
```bash
"https://example.com"
$Fetch
$Console
请求网站并打印到控制台
```
### Download File
```bash
"https://example.com"
$Fetch
$Std( "example.com.html" )
$ToString
$Console
```
### Get Minecraft Server Name
```bash
"Server Ip: "
$Std
$ToUrl
$Concat( "http://mcapi.org/server/status?ip=" )( true )
$Concat( "&port=25565" )
$Fetch( true )
$ParseObject( "server" )( "name" )
$Concat( "服务器名称: " )( true )
$Console
$ClearTo( "-----\n获取完毕，使用Ctrl-C退出程序" )
$Console
```
## Compiler
使用ssc编译或执行脚本
```bash
# Just Run
ssc input=test.stream
# 构建成Js(用于在前端运行)
ssc input=test.stream output=test.stream.js
# 构建成可执行文件
# 不支持Fetch和Std
ssc input=test.stream output=test.bin target=bin
```
## Custom Runtime
使用js自定义脚本的关键词，全局变量
```js
runStream( 脚本, 变量表, 关键字表 )
```
建议使用Ls开发