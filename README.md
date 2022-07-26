# FrogBlog
A simple blog editor for macOS. 

![](https://robdodson.net/FrogBlog/images/FrogBlogIcon-128x128.png)

---

FrogBlog installs HTML,CSS and PHP files on your web server to display the blog. Super simple system. Comes with easy to modify default template files. 

Currently the only way files are uploaded to the server is via sftp with public key login.

The editor supports markdown and has a preview window.

Export/Import writes/reads standard json files.

All data is stored in a local Sqlite database on your Mac.

### libssh2

This project needs to link to [libssh2](https://libssh2.org). Here is a way to do it:

Clone [](https://github.com/build-xcframeworks/libssh2) and built it. Then add it to this Xcode project. Details:

$ git clone https://github.com/build-xcframeworks/libssh2
$ cd libssh2
Before running libssh2.sh I edited it to not use libz. I changed all references to --with-libz to --without-libz. I don't need libz and I don't want to install it. I also changed the LIBSSH2 from 1.9.0 to 1.10.0 at the top of libssh2.sh

Now build the build-xcframeworks/libssh2 project. This will download and build libssh2. It will also download libcrypto and libssl.
$ bash libssh2.sh

You may also need to codesign the library files. Run this in the libssh2 folder
$ find . -name ".a" | xargs codesign -s "Your Team ID"

Now back in Xcode add libssh2.xcframework and libcrypto.xcframework from the libssh2 folder to your project. libssh2.xcframework is in the output folder and libcrypto.xcframework is in the 3.2.2 folder.

---

![](https://robdodson.net/FrogBlog/images/screencap.png)

---

Todo:

* Don't load articles and images into memory until editing
* Support password login to server?

