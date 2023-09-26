abstract class CompletionHandler {
  void complete([dynamic retValue]);

  void setProgressData(dynamic value);
}

typedef OnReturnValue = Function(dynamic retValue);
