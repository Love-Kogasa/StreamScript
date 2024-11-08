# 关于 StreamScript
StreamScript ( 译名: 流脚本 )  
GH地址:https://github.com/Love-Kogasa/StreamScript  
是我花了仅仅6个小时就基本完成的一门非传统编程语言  
没办法，作为一个河北初中生实在太累了，6个小时还是我一周熬夜拼凑出来的还不到  
streamScript ~~就是个垃圾~~ 是一门相对简单，便捷的非传统脚本语言  
可以用于api脚本，简单的网络，文件操作，嵌入式等  
为什么叫他流脚本或流语言后面你会知道的w
# 如何安装
StreamScript的安装较为繁琐  
我没有上传npm市场  
```bash
# 安装nodejs和git以及qjs( 否则你无法使用ssc
apt install node quickjs git -y
# 拉取仓库到本地
git clone https://github.com/Love-Kogasa/StreamScript
mkdir nodecmds
mv StreamScript nodecmds/ssc
# 设置项目入口文件和环境变量
echo '{"main": "ssc.js"}' > "nodecmds/ssc/package.json"
export PATH=$PATH:$PWD/nodecmds/ssc
echo "export PATH=$PATH" >> ~/.bashrc
# 安装完成
```
# Ssc测试 StreamScript
注: log关键字仅用于测试，实际应用中请不要使用log关键字
```bash
echo "@log Hello" > hello.stream
# 不要空格
ssc input=hello.stream
# Hello
```
### Ssc参数
* input 输入的stream文件
* output 构建出的文件名
* target 构建目标( js(默认)或bin )
* module 模块化打包，即打包成js带有一个立即执行的异步函数，返回带有所有虚拟Stream节点(即stream的虚拟流，变量或者节点)对象的对象
* libs 模块引用
* setting 从json结合提供的命令行参数获取构建选项

通用从index.js编译到任意运行时和引擎的JSON.  
请将如下代码保存到build.json
```json
{
  "input": "index.js",
  "output": "dist.js",
  "libs": [],
  "module": "yes"
}
```
编译和测试用命令
```bash
ssc setting=build.json
# 用qjs模拟非node运行时
qjs dist.js
# Hello
```
# 基础语法
更 StreamScript のHelloWorld
```bash
"HelloWorld"
将HelloWorld传递给Console虚拟流
$Console( " ← DATA" )
```
本段代码是StreamScript的HelloWorld，是不是很有流操作的感觉，把HelloWorld字符串(在stream里实际上就是一个json字符串虚拟流)流Pipe到Console虚拟流里  
*Console*后面的括号代表其他的传递给虚拟流的东西，附带一句，stream里传递参数不是(a,b)而是(a)(b)，~~这样解释器会好写不少~~  
事实上也确实是这样，StreamScript里数据类型写法与标准json相同，因此，你可以再Stream的任何地方打注释  
恭喜你，学完StreamScript了，这是一门很简单的，适合嵌入式的语言，对吧
# 所有内置虚拟流和关键字(具体以源码为准)
## 关键字
* log 测试用输出关键字
* val 将合并来的数据虚拟流储存在变量里并原样合并到下一个虚拟流
## 虚拟流
### 通用
* Console ( 等同于js的*console.log*函数 )  
read获取的是输出历史
* Json 如果将字符串与其合并则解析json并将json字符串合并到下一个虚拟流，如果是对象则编码对象到json
* JsFunc Js函数虚拟流，使用合并来的字符串流获取js函数，参数为传递给js函数的参数
* Fetch 将url合并给Fetch以url请求，接受一个参数，如果为true则解析json
* ParseObject 将对象虚拟流合并到它解析对象，参数决定读取的对象
```bash
{ "key": { "key": "value" } }
$ParseObject( "key" )( "key" )
$Console
打印Value
```
* ToString 将任意类型虚拟流转换为字符串虚拟流
* ClearTo 将目前流合并过来的内容清空，并将指定数据合并到下一流，示例
```bash
"HELLO"
$ClearTo( "World" )
$Console
输出World
```
* ToUrl URL字符串编码
* ParseUrl URL字符串解码
* Concat 拼接数据，第一个参数是要与合并来的数据流拼接的数据，第二个是是否翻转数组或字符串
### NodeJs
* Std write是sdtout read是stdin 如果有参数则从参数指定的文件读写
* ToBuffer 缓冲区编码
# Custom Runtime in js
你一定发现了这门语言作为嵌入式一定很合适，事实上我也是这么想的，jsAPI轻小且适配任何js环境，运行时，引擎，是简单js嵌入工程的不二选择
## JSApi
有别于下面的SscModule形式，JSApi更加方便直接，更直接的定义StreamScript的运行时  
运行Stream
```js
// 这里示例用的nodejs
var stream = require( "本目录index.js的线路" )

// 自定义一个内置虚拟流
stream.valueMap.set( "Myvalue", {
  // 当读取虚拟流的时候执行的
  read: ( ...args ) => void args,
  // 当写入虚拟流时执行的
  write: ( value, ...args ) => void value
  // 允许使用this
})

// 自定义一个关键字
stream.keywordMap.set( "@xxx", ( args, values ) => {
  // args 传递给关键字的参数数组，以" "分割
  // values 节点表
  return 必须返回一个虚拟流对象
})

stream.runStream( 
  "streamScript代码",
  stream.valueMap
  /** 内置节点表，默认为valueMap */,
  stream.keywordMap
  /** 内置关键词表，默认为keywordMap */
)
```
## SscModule
SscModule则更加简单，依赖ssc编译器，在编译选项libs数组中添加库js线路
```js
var myLib = new Map()
// ...
// 导出模块↓
module.exports = mylib
```
这样就可以啦
# 其他