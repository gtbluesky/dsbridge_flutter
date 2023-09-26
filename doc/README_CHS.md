# DSBridge for Flutter

![dsBridge](https://github.com/gtbluesky/dsbridge_flutter/raw/main/doc/dsbridge.png)
[![pub package](https://img.shields.io/pub/v/dsbridge.svg)](https://pub.dev/packages/dsbridge)
> 三端易用的现代跨平台 JavaScript bridge， 通过它，你可以在 JavaScript 和 Dart 之间同步或异步的调用彼此的函数.

DSBridge-Android：https://github.com/wendux/DSBridge-Android

DSBridge-IOS：https://github.com/wendux/DSBridge-IOS

### 概述

DSBridge for Flutter 完全兼容 Android 和 iOS DSBridge 的 dsbridge.js。

在现有使用了 dsbridge.js 的 Web 项目中无须修改任何代码即可使用 DSBridge for Flutter。

DSBridge for Flutter 基于 Flutter官方的 [webview_flutter](https://pub.dev/packages/webview_flutter)。

## 特性

1. Android、iOS、JavaScript 三端易用，轻量且强大、安全且健壮。

2. 同时支持同步调用和异步调用

3. 支持以类的方式集中统一管理API

4. 支持API命名空间

5. 支持调试模式

6. 支持 API 存在性检测

7. 支持进度回调：一次调用，多次返回

8. 支持 JavaScript 关闭页面事件回调

9. 支持 JavaScript 模态对话框

## 安装

1. 添加依赖

   ```yml
   dependencies:
     ...
     dsbridge: x.y.z
   ```

## 示例

请参考工程目录下的 `example` 包。运行 `example` 工程并查看示例交互。

如果要在你自己的项目中使用 dsBridge :

## 使用

1. 新建一个Dart类，实现API

   ```dart
   import 'package:dsbridge/dsbridge.dart';

   class JsApi extends JavaScriptNamespaceInterface {
      @override
      void register() {
         registerFunction(testSyn);
         registerFunction(testAsyn);
      }
   
      /// for synchronous invocation
      String testSyn(dynamic msg) {
         return "$msg［syn call］";
      }
   
      /// for asynchronous invocation
      void testAsyn(dynamic msg, CompletionHandler handler) {
         handler.complete("$msg [ asyn call]");
      }
   }
   ```

   所有Dart APIs必须在register函数中使用registerFunction来注册。

2. 添加API类实例到DWebViewController

   ```dart
   import 'package:dsbridge/dsbridge.dart';
   ...
   late final DWebViewController _controller;
   ...
   _controller.addJavaScriptObject(JsApi(), null);
   ```

3. 在 JavaScript 中调用 Dart API ,并注册一个 JavaScript API 供原生调用.

    - 初始化 dsBridge

      ```javascript
      //cdn
      //<script src="https://unpkg.com/dsbridge@3.1.3/dist/dsbridge.js"> </script>
      //npm
      //npm install dsbridge@3.1.3
      var dsBridge=require("dsbridge")
      ```

    - 调用 Dart API；以及注册一个 JavaScript API 供 Dart 调用.

      ```javascript
 
      //同步调用
      var str=dsBridge.call("testSyn","testSyn");
 
      //异步调用
      dsBridge.call("testAsyn","testAsyn", function (v) {
        alert(v);
      })
 
      //注册 JavaScript API 
       dsBridge.register('addValue',function(l,r){
           return l+r;
       })
      ```

4. 在 Dart 中调用 JavaScript API

   ```dart
   import 'package:dsbridge/dsbridge.dart';
   ...
   late final DWebViewController _controller;
   ...
   _controller.callHandler('addValue', args: [3, 4],
       handler: (retValue) {
     print(retValue.toString());
   });
   ```

## Dart API 签名

为了兼容Android&iOS，我们约定Dart API 签名，**注意，如果API签名不合法，则不会被调用**！签名如下：

1. 同步API.

   **`any handler(dynamic msg)`**

   参数必须是 `dynamic` 类型，**并且必须申明**（如果不需要参数，申明后不适用即可）。返回值类型没有限制，可以是任意类型。

2. 异步 API.

   **`void handler(dynamic arg, CompletionHandler handler)`**

## 命名空间

命名空间可以帮助你更好的管理API，这在API数量多的时候非常实用，比如在混合应用中。DSBridge支持你通过命名空间将API分类管理，并且命名空间支持多级的，不同级之间只需用'.' 分隔即可。


## 调试模式

在调试模式时，发生一些错误时，将会以弹窗形式提示，并且Dart API如果触发异常将不会被自动捕获，因为在调试阶段应该将问题暴露出来。

## 进度回调

通常情况下，调用一个方法结束后会返回一个结果，是一一对应的。但是有时会遇到一次调用需要多次返回的场景，比如在 JavaScript 中调用端上的一个下载文件功能，端上在下载过程中会多次通知 JavaScript 进度, 然后 JavaScript 将进度信息展示在h5页面上，这是一个典型的一次调用，多次返回的场景，如果使用其它 JavaScript bridge, 你将会发现要实现这个功能会比较麻烦，而 DSBridge 本身支持进度回调，你可以非常简单方便的实现一次调用需要多次返回的场景，下面我们实现一个倒计时的例子：

In Dart

```dart
void callProgress(dynamic args, CompletionHandler handler) {
   var i = 10;
   final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (i == 0) {
         timer.cancel();
         handler.complete(0);
      } else {
         handler.setProgressData(i--);
      }
   });
}
```

In JavaScript

```javascript
dsBridge.call("callProgress", function (value) {
    document.getElementById("progress").innerText = value
})
```

完整的示例代码请参考example工程。

## Javascript 对话框

DSBridge 已经实现了 JavaScript 的对话框函数(alert/confirm/prompt)，如果你想自定义它们，通过`DWebViewController`设置相关回调函数即可。DSBridge实现的对话框默认设置是模态的，这会挂起UI线程。

## API 列表

### Dart API

在 Dart 中我们把实现了供 JavaScript 调用的 API 类的实例称为 **Dart API object**.

##### `DWebViewController.addJavaScriptObject(JavaScriptNamespaceInterface? object, String? namespace)`

Dart API object到DWebViewController，并为它指定一个命名空间。然后，在 JavaScript 中就可以通过`bridge.call("namespace.api",...)`来调用Dart API object中的原生API了。

如果命名空间是空(null或空字符串）, 那么这个添加的Dart API object就没有命名空间。在 JavaScript 通过 `bridge.call("api",...)`调用。

**示例**:

In Dart

```dart
class JsEchoApi extends JavaScriptNamespaceInterface {
   @override
   void register() {
      registerFunction(syn);
      registerFunction(asyn);
   }

   dynamic syn(dynamic args) {
      return args;
   }

   void asyn(dynamic args, CompletionHandler handler) {
      handler.complete(args);
   }
}
//namespace is "echo"
controller.addJavaScriptObject(JsEchoApi(), 'echo');
```

In JavaScript

```javascript
// call echo.syn
var ret=dsBridge.call("echo.syn",{msg:" I am echoSyn call", tag:1})
alert(JSON.stringify(ret))  
// call echo.asyn
dsBridge.call("echo.asyn",{msg:" I am echoAsyn call",tag:2},function (ret) {
      alert(JSON.stringify(ret));
})
```

##### `DWebViewController.removeJavaScriptObject(String namespace)`

通过命名空间名称移除相应的Dart API object。

##### `DWebViewController.callHandler(String method, {List? args, OnReturnValue? handler})`

调用 JavaScript API。`handlerName` 为 JavaScript API 的名称，可以包含命名空间；参数以数组传递，`args`数组中的元素依次对应 JavaScript API的形参； `handler` 用于接收 JavaScript API 的返回值，**注意：handler将在Dart主isolate中被执行**。

示例:

```dart
_controller.callHandler('append', args: ["I", "love", "you"],
handler: (retValue) {
  print(retValue.toString());
});
/// call with namespace 'syn', More details to see the Demo project                    
_controller.callHandler('syn.getInfo', handler: (retValue) {
  print(retValue.toString());
});
```

##### `DWebViewController.javaScriptCloseWindowListener`

当 JavaScript 中调用`window.close`时，DWebViewController 会触发此监听器，你可以自定义回调进行处理。

Example:

```dart
controller.javaScriptCloseWindowListener = () {
  print('window.close called');
};
```

##### `DWebViewController.hasJavaScriptMethod(String handlerName, OnReturnValue existCallback)`

检测是否存在指定的 JavaScript API，`handlerName`可以包含命名空间.

示例:

```dart
_controller.hasJavaScriptMethod('addValue', (retValue) {
  print(retValue.toString());
});
```

##### `DWebViewController.dispose()`

释放资源。在当前页面处于dispose状态时，你应该显式调用它。

### JavaScript API

##### dsBridge

"dsBridge" 在初始化之后可用 .

##### `dsBridge.call(method,[arg,callback])`

同步或异步的调用Dart API。

`method`: Dart API 名称， 可以包含命名空间。

`arg`:传递给Dart API 的参数。只能传一个，如果需要多个参数时，可以合并成一个json对象参数。

`callback(String returnValue)`: 处理Dart API的返回结果. 可选参数，**只有异步调用时才需要提供**.

##### `dsBridge.register(methodName|namespace,function|synApiObject)`

##### `dsBridge.registerAsyn(methodName|namespace,function|asynApiObject)`

注册同步/异步的 JavaScript API. 这两个方法都有两种调用形式：

1. 注册一个普通的方法，如:

   In JavaScript

   ```javascript
   dsBridge.register('addValue',function(l,r){
        return l+r;
   })
   dsBridge.registerAsyn('append',function(arg1,arg2,arg3,responseCallback){
        responseCallback(arg1+" "+arg2+" "+arg3);
   })
   ```
   
   In Dart

   ```dart
   _controller.callHandler('addValue', args: [3, 4],
       handler: (retValue) {
     print(retValue.toString());
   });

   _controller.callHandler('append', args: ["I", "love", "you"],
       handler: (retValue) {
     print(retValue.toString());
   });
   ```

2. 注册一个对象，指定一个命名空间:

   **In JavaScript**

   ```javascript
   //namespace test for synchronous calls
   dsBridge.register("test",{
     tag:"test",
     test1:function(){
   	return this.tag+"1"
     },
     test2:function(){
   	return this.tag+"2"
     }
   })
     
   //namespace test1 for asynchronous calls  
   dsBridge.registerAsyn("test1",{
     tag:"test1",
     test1:function(responseCallback){
   	return responseCallback(this.tag+"1")
     },
     test2:function(responseCallback){
   	return responseCallback(this.tag+"2")
     }
   })
   ```

   > 因为 JavaScript 并不支持函数重载，所以不能在同一个 JavaScript 对象中定义同名的同步函数和异步函数

   **In Dart**

   ```dart
   _controller.callHandler('test.test1',
       handler: (retValue) {
     print(retValue.toString());
   });
   
   _controller.callHandler('test1.test1',
       handler: (retValue) {
     print(retValue.toString());
   });
   ```

##### `dsBridge.hasNativeMethod(handlerName,[type])`

检测Dart中是否存在名为`handlerName`的API, `handlerName` 可以包含命名空间.

`type`: 可选参数，`["all"|"syn"|"asyn" ]`, 默认是 "all".

```javascript
//检测是否存在一个名为'testAsyn'的API(无论同步还是异步)
dsBridge.hasNativeMethod('testAsyn') 
//检测test命名空间下是否存在一个’testAsyn’的API
dsBridge.hasNativeMethod('test.testAsyn')
// 检测是否存在一个名为"testSyn"的异步API
dsBridge.hasNativeMethod('testSyn','asyn') //false
```

## 最后

如果你喜欢DSBridge for Flutter, 欢迎点点star和like，以便更多的人知道它, 谢谢 !
