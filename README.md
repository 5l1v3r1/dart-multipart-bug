# Running

Run these in the command line:

    $ cd dart-multipart-bug
    $ dart server.dart 1337

Then connect to `localhost:1337`. Note that you may substitute the port. Now, pick a file (it can be anything, even a blank file demonstrates an issue). When you hit Submit, the server will hang indefinitely.

# The Issue

I am not sure if this is actually an issue with the `mime` package or if I just misunderstand how to use it.

I am using a MIME multipart transformer to get data from a file upload. all works well if I immediately `listen()` to the `MimeMultipart` object. However, if I wait for the runloop to run a while before attempting to `listen()`, I never get any callbacks.

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
