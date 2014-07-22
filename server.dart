import 'dart:io';
import 'dart:async';
import 'package:mime/mime.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart server.dart <port>');
    stderr.flush().then((_) => exit(1));
    return;
  }
  
  int port = int.parse(args[0]);
  var bindCb = (x) => x.listen(requestHandler);
  var errorCb = (_) {
    print('Failed to listen on port $port');
    exit(1);
  };

  HttpServer.bind(InternetAddress.ANY_IP_V4, port)
      .then(bindCb)
      .catchError(errorCb);
}

bool isMultipartUpload(HttpRequest req) {
  return req.method == 'POST' &&
      req.headers.contentType.mimeType == 'multipart/form-data';
}

void requestHandler(HttpRequest request) {
  if (isMultipartUpload(request)) {
    return handleFileUpload(request);
  }
  
  // write the index
  HttpResponse response = request.response;
  new File('index.html').readAsBytes().then((body) {
    response.headers.contentType = ContentType.parse('text/html');
    response..add(body)..close();
  }).catchError((error) {
    response.headers.contentType = ContentType.parse('text/plain');
    response.statusCode = 500;
    response..write('Error reading file: $error')..close();
  });
}

void handleFileUpload(HttpRequest request) {
  String boundary = request.headers.contentType.parameters['boundary'];
  request.transform(new MimeMultipartTransformer(boundary))
    .listen((MimeMultipart formData) {
      // if I do this, it works:
      // print('listening for data...');
      // formData.listen((x) => print('got data of length ${x.length}'));
      
      // this does NOT work
      Duration duration = new Duration(seconds: 1);
      new Timer(duration, () {
        print('listening for data...');
        formData.listen((x) => print('got data of length ${x.length}'));
      });
    }, onDone: () {
      HttpResponse response = request.response;
      response.headers.contentType = ContentType.parse('text/html');
      response..write('Upload complete!')..close();
    });
}
