# Running

Run these in the command line:

    $ cd dart-multipart-bug
    $ dart server.dart 1337

Then connect to `localhost:1337`. Note that you may substitute the port. Now, pick a file (it can be anything, even a blank file demonstrates an issue). When you hit Submit, the server will hang indefinitely.

# The Issue

The issue is that the MIME package does not set a handler for `onListen` for a `_MimeMultipart` object. Instead, it *assumes* that you will `listen()` to the multipart stream synchronously the moment you get it. I have a patch below which fixes the issue (although I have not tested it extensively to make sure it doesn't break anything).

**Here is how I found the issue.**

I am using a MIME multipart transformer to get data from a file upload. all works well if I immediately `listen()` to the `MimeMultipart` object. However, if I wait for the runloop to run before attempting to `listen()`, I never get any callbacks.

    .listen((HttpMultipartFormData formData) {
      // if I do this, it works:
      // print('listening for data...');
      // formData.listen((x) => print('got data of length ${x.length}'));
      
      // this does NOT work
      Duration duration = new Duration(seconds: 1);
      new Timer(duration, () {
        print('listening for data...');
        formData.listen((x) => print('got data of length ${x.length}'));
      });
    }

# Patch

The problem is in the `mime/bound_multipart_stream.dart` file. This patch will fix it (in the current version, *0.9.0+3*):

    --- /Users/alex/.pub-cache/hosted/pub.dartlang.org/mime-0.9.0+3/lib/src/bound_multipart_stream.dart	2014-05-30 12:47:51.000000000 -0400
    +++ /Users/alex/Desktop/bound_multipart_stream.dart	2014-07-21 22:36:41.000000000 -0400
    @@ -173,7 +173,9 @@ class BoundMultipartStream {
          boundaryPrefix = _boundaryIndex;
 
          while ((_index < _buffer.length) && _state != _FAIL && _state != _DONE) {
    -       if (_multipartController != null && _multipartController.isPaused) {
    +       if (_multipartController != null &&
    +           (_multipartController.isPaused ||
    +           !_multipartController.hasListener)) {
              return;
            }
            int byte;
    @@ -292,6 +294,7 @@ class BoundMultipartStream {
                break;
 
              case _HEADER_ENDING:
    +           var isDoneAdding = false; // set to true after add() call
                _expectByteValue(byte, CharCode.LF);
                _multipartController = new StreamController(
                    sync: true,
    @@ -301,9 +304,16 @@ class BoundMultipartStream {
                    onResume: () {
                      _resumeStream();
                      _parse();
    +               },
    +               onListen: () {
    +                 if (isDoneAdding) {
    +                   _resumeStream();
    +                   _parse();
    +                 }
                    });
                _controller.add(
                    new _MimeMultipart(_headers, _multipartController.stream));
    +           isDoneAdding = true;
                _headers = null;
                _state = _CONTENT;
                contentStartIndex = _index + 1;

# Workaround

As a temporary workaround, I have found that I can start listening, `pause()` the subscription, and then `resume()` it when I need the data:

    .listen((MimeMultipart formData) {
      var a = formData.listen((x) => print('got data of length ${x.length}'));
      a.pause();
      Duration duration = new Duration(seconds: 1);
      new Timer(duration, () {
        print('listening for data...');
        a.resume();
      });
    }

However, this will not allow me to use nice utilities like `pipe()` in the future.
