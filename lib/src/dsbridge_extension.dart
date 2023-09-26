extension SymbolExtension on Symbol {
  String get name {
    RegExp regex = RegExp(r'^Symbol\("(.+)"\)$');
    final match = regex.firstMatch(toString());
    return match?.group(1) ?? '';
  }
}

extension FunctionExtension on Function {
  String get name {
    RegExp regex = RegExp(r"from Function '([^@]+)(@?)(\d*)':.$");
    final match = regex.firstMatch(toString());
    return match?.group(1) ?? '';
  }
}
