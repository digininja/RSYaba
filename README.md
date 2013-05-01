![alt text](http://www.randomstorm.com/images/rsyaba.png "RSYaba")

rsyaba - RS Yet Another Brute Attacker
========================================

Copyright(c) 2010, RandomStorm Limited - www.randomstorm.com  
Robin Wood <robin.wood@randomstorm.com>  
Version 1.0.1

RSYaba is tool to run brute force attacks against various services in a similar
way to Hydra and Medusa. I started writing it as I found both had troubles with
HTTP and getting SSH to work was fiddly so I though why not write my own.

It is also written in Ruby so modifying the scripts is a lot simpler than having 
to change C/C++ code then recompile. All the modules so far are based on standard
Ruby gems so they handle all the protocol stuff which means there is a nice
level of abstraction for the actual attack framework.

While writing the HTTP module I added a feature that is missing in all the other
HTTP bruteforcers I've tried, the ability to handle authentication that relies
on a cookie already being set and, even stricter, forms that use unique tokens
to prevent brute force attacks. 

Each module has its own README in the docs directory

And its RSYaba because RSYabf doesn't sound quite as good.

Installation
============

Untar the tarball and make rsyaba.rb executable.

For HTTP you'll need the hpricot gem

```sudo gem install hpricot```

For SSH you'll need to install the net-ssh gem

```sudo gem install net-ssh```

and for MySQL you'll need the mysql gem which on Debian depends on the mysql
client dev libraries

```
sudo apt-get install libmysqlclient-dev
sudo gem install mysql
```

Usage
=====

To get basic help simply run

```./rsyaba.rb --help```

To list all supported protocols

```./rsyaba.rb --list_protocols```

To get help on a specific protocol

```./rsyaba.rb http --help```

To run an attack with words from the 100_words.txt file and usernames from user_list

```./rsyaba.rb http --host www.example.com --path /login.php --wordlist 100_words.txt -u user_list```

To do the attack taking the word list from stdin using rsmangler to generate the
list, a single username of robin

```rsmangler.rb -f names | ./rsyaba.rb ssh --wordlist - -U robin --host example.com```

To do a HTTPS attack against a token protected site knowing the token is stored
in the field token and that on a successful login the word "Success" is
displayed on the screen

```
./rsyaba.rb https --host www.example.com --path /login/with_token.php -w 100_words.txt  --success_message="Success" --token_field="token" -U robin
```

Most of the generic command line options should be self explanatory, the only
one that isn't is the throttleback option, for more information on that see the
SSH module docs in docs/README.ssh.

For information on specific modules look in the docs directory.

License
=======

This project released under the Creative Commons Attribution-Share Alike 2.0 
UK: England & Wales

( http://creativecommons.org/licenses/by-sa/2.0/uk/ )

Bugs, Comments, Feedback
========================

Feel free to get in touch, robin.wood@randomstorm.com
