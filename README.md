# DSBridge for Flutter

![dsBridge](https://github.com/gtbluesky/dsbridge_flutter/raw/main/doc/dsbridge.png)
[![pub package](https://img.shields.io/pub/v/dsbridge.svg)](https://pub.dev/packages/dsbridge)
>Modern cross-platform JavaScript bridge, through which you can invoke each other's functions synchronously or asynchronously between JavaScript and Flutter applications.

Chinese documentation [中文文档](https://github.com/gtbluesky/dsbridge_flutter/blob/main/doc/README_CHS.md)

DSBridge-Android：https://github.com/wendux/DSBridge-Android

DSBridge-IOS：https://github.com/wendux/DSBridge-IOS    

## Overview

DSBridge for Flutter is fully **compatible** with Android and iOS DSBridge's dsbridge.js.

No need to modify any code in your existing web projects which using dsbridge.js.

DSBridge for Flutter is based on Flutter official [webview_flutter](https://pub.dev/packages/webview_flutter).

## Features

1. The three ends of Android, IOS and JavaScript are easy to use, light and powerful, secure and strong
2. Both synchronous and asynchronous calls are supported
3. Support **API Object**, which centrally implements APIs in a Dart Class or a JavaScript object
4. Support API namespace
5. Support debug mode
6. Support the test of whether API exists
7. Support **Progress Callback**: one call, multiple returns
8. Support event listener for JavaScript to close the page
9. Support Modal popup box for JavaScript

## Installation

1. Add the dependency

   ```yml
   dependencies:
     ...
     dsbridge_flutter: x.y.z
   ```

## Examples

See the `example` package. run the `example` project and to see it in action.

To use dsBridge in your own project:

## Usage

1. Implement APIs in a Dart class

   ```dart
   import 'package:dsbridge_flutter/dsbridge_flutter.dart';

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

   Dart APIs must be registered with registerFunction in register function.

2. Add API object to DWebViewController

   ```dart
   import 'package:dsbridge_flutter/dsbridge_flutter.dart';
   ...
   late final DWebViewController _controller;
   ...
   _controller.addJavaScriptObject(JsApi(), null);
   ```

3. Call Dart API in JavaScript, and register JavaScript API.

    - Init dsBridge

      ```javascript
      //cdn
      //<script src="https://unpkg.com/dsbridge@3.1.3/dist/dsbridge.js"> </script>
      //npm
      //npm install dsbridge@3.1.3
      var dsBridge=require("dsbridge")
      ```

    - Call Dart API and register a JavaScript API for Dart invocation.

      ```javascript
   
      //Call synchronously 
      var str=dsBridge.call("testSyn","testSyn");
   
      //Call asynchronously
      dsBridge.call("testAsyn","testAsyn", function (v) {
        alert(v);
      })
   
      //Register JavaScript API for Dart
       dsBridge.register('addValue',function(l,r){
           return l+r;
       })
      ```

4. Call JavaScript API in Dart

   ```dart
   import 'package:dsbridge_flutter/dsbridge_flutter.dart';
   ...
   late final DWebViewController _controller;
   ...
   _controller.callHandler('addValue', args: [3, 4],
       handler: (retValue) {
     print(retValue.toString());
   });
   ```

## Dart API signature

In order to be compatible with Android&iOS, we make the following convention on Dart API signature:

1. For synchronous API.

   **`any handler(dynamic msg)`**

   The argument type must be dynamic and must be declared even if not need，and the type of return value is not limited.

2. For asynchronous API.

   **`void handler(dynamic arg, CompletionHandler handler)`**

## Namespace

Namespaces can help you better manage your APIs, which is very useful in hybrid applications, because these applications have a large number of APIs. DSBridge allows you to classify API with namespace. The namespace can be multilevel, between different levels with '.' division.

## Debug mode

In debug mode, some errors will be prompted by a popup dialog , and the exception caused by the dart APIs will not be captured to expose problems.

## Progress Callback

Normally, when a API is called to end, it returns a result, which corresponds one by one. But sometimes a call need to repeatedly return multiple times,  Suppose that on the Flutter side, there is a API to download the file, in the process of downloading, it will send the progress information to JavaScript many times, then JavaScript will display the progress information on the H5 page. Oh...You will find it is difficult to achieve this function. Fortunately, DSBridge supports **Progress Callback**. You can be very simple and convenient to implement a call that needs to be returned many times. Here's an example of a countdown：

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

For the complete sample code, please refer to the example project.

## JavaScript popup box

For JavaScript popup box functions (alert/confirm/prompt), DSBridge has implemented them all by default, if you want to custom them, set the corresponding callback in DWebViewController. The default dialog box implemented by DSBridge is modal. This will block the UI thread.

## API Reference

### Dart API

In Dart, the object that implements the JavaScript interfaces is called **Dart API object**.

##### `DWebViewController.addJavaScriptObject(JavaScriptNamespaceInterface? object, String? namespace)`

Add the Dart API object with supplied namespace into DWebViewController. The JavaScript can then call Dart APIs with `bridge.call("namespace.api",...)`.

If the namespace is null or empty, the Dart API object have no namespace. The JavaScript can call Dart APIs with `bridge.call("api",...)`.

Example:

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

Remove the  Dart API object with supplied namespace.

##### `DWebViewController.callHandler(String method, {List? args, OnReturnValue? handler})`

Call the JavaScript API. If a `handler` is given, the JavaScript handler can respond. the `handlerName` can contain the namespace.  **The handler will be called in Dart main isolate**.

Example:

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

DWebViewController calls `callback` when JavaScript calls `window.close`you can provide a callback to add your handler.

Example:

```dart
controller.javaScriptCloseWindowListener = () {
  print('window.close called');
};
```

##### `DWebViewController.hasJavaScriptMethod(String handlerName, OnReturnValue existCallback)`

Test whether the handler exist in JavaScript.

Example:

```dart
_controller.hasJavaScriptMethod('addValue', (retValue) {
  print(retValue.toString());
});
```

##### `DWebViewController.dispose()`

Release resources. You should call it explicitly when page state is dispose.

### JavaScript API

##### dsBridge

"dsBridge" is accessed after dsBridge Initialization .

##### `dsBridge.call(method,[arg,callback])`

Call Dart api synchronously and asynchronously。

`method`: Dart API name， can contain the namespace。

`arg`: argument, Only one  allowed,  if you expect multiple  parameters,  you can pass them with a json object.

`callback(String returnValue)`: callback to handle the result. **only asynchronous invocation required**.

##### `dsBridge.register(methodName|namespace,function|synApiObject)`

##### `dsBridge.registerAsyn(methodName|namespace,function|asyApiObject)`

Register JavaScript synchronous and asynchronous  API for Dart invocation. There are two types of invocation

1. Just register a method. For example:

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

   

2. Register a JavaScript API object with supplied namespace. For example:

   In JavaScript

   ```javascript
   //namespace test for synchronous
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

   > Because JavaScript does not support function overloading, it is not possible to define asynchronous function and sync function of the same name。
   >

   In Dart

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

Test whether the handler exist in Dart, the `handlerName` can contain the namespace.

`type`: optional`["all"|"syn"|"asyn" ]`, default is "all".

```javascript
dsBridge.hasNativeMethod('testAsyn') 
//test namespace method
dsBridge.hasNativeMethod('test.testAsyn')
// test if exist a asynchronous function that named "testSyn"
dsBridge.hasNativeMethod('testSyn','asyn') //false
```

## Finally

If you like DSBridge for Flutter, please click star/like to let more people know it, Thanks!