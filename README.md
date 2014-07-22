# Running

Run these in the command line:

    $ cd dart-multipart-bug
    $ dart server.dart 1337

Then connect to `localhost:1337`. Note that you may substitute the port. Now, pick a file (it can be anything, even a blank file demonstrates an issue). When you hit Submit, the server will hang indefinitely.

# The Issue

I am not sure if this is actually an issue with the `mime` package, the `http_server` package, or *me*. I could just misunderstand how streams are supposed to work in this particular case.

I am using a MIME multipart transformer with a multipart parser. When I get the callback with an `HttpMultipartFormData` object, all works well if I immediately `listen()` to it. However, if I wait for the runloop to run before attempting to `listen()`, I never get any callbacks.

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
