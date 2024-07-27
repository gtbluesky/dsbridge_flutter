import 'dsbridge_extension.dart';

abstract class JavaScriptNamespaceInterface {
  var functionMap = <String, Function>{};

  JavaScriptNamespaceInterface() {
    register();
  }

  void register();

  bool registerFunction(Function function, {String? functionName}) {
    final name = functionName ?? function.name;
    if (name.isEmpty) {
      return false;
    }
    functionMap[name] = function;
    return true;
  }
}
