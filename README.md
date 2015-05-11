audio_nr
=====
A simple REST server with Sinatra which processes Noise Reduction

To Run this code, follow these steps

### Setting up Sinatra
```
$ gem install sinatra
```

### Creating directorynecessary for record files
```
$ mkdir records
```

### Installing SoX
You might want to find out the latest version of SoX in [SourceForge SoX download page](http://sourceforge.net/projects/sox/files/sox/)

```
$ wget http://kent.dl.sourceforge.net/sourceforge/sox/sox-14.4.2.tar.zip
$ tar -xzvf sox-14.4.2.tar.zip
$ cd sox-14.4.2
$ ./configure
$ make
$ sudo make install
```
