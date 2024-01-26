import 'dsbridge_extension.dart';

abstract class JavaScriptNamespaceInterface {
  var functionMap = <String, Function>{};

  JavaScriptNamespaceInterface() {
    register();
  }

  void register();

  bool registerFunction(Function function) {
    final name = function.name;
    if (name.isEmpty) {
      return false;
    }
    functionMap[name] = function;
    return true;
  }
}
