# FrogBlog

A simple blog editor for macOS. 

![](https://robdodson.net/FrogBlog/images/FrogBlogIcon-128x128.png)

---

FrogBlog installs HTML,CSS and PHP files on your web server to display the blog. Super simple system. Comes with easy to modify default template files. 

Currently the only way files are uploaded to the server is via sftp with public key login.

The editor supports markdown and has a preview window.

Export/Import writes/reads standard json files.

All data is stored in a local Sqlite database on your Mac.

---

![](https://robdodson.net/FrogBlog/images/screencap.png)

---

Todo:

* Don't load articles and images into memory until editing
* Update export/import to handle images
* some kind of syncing 
	- Investigate using GRDB json export/import to/from the web server
* RSS support
* Support password login to server
