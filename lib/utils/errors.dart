class HttpStatusError extends Error {
  final String request;
  final String? error;
  final int code;
  HttpStatusError(this.request, this.code, {this.error});

  @override
  String toString() {
    final msg = error == null ? "" : "message: $error, ";
    return "HttpStatusError: $request, $msg"
        "Status Code: $code";
  }
}

class NotLoginError extends Error {
  @override
  String toString() => "NotLoginError";
}
