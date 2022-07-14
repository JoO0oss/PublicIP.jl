# publicIP.jl
A command line tool to get the public IP address of your network. Made with Julia and bash commands from within the `.jl` Julia program file.

<br>

## Installation
Create a new folder in your home directory, for example `~/publicip/`, and copy `publicIP.jl` from [src](https://github.com/JoO0oss/PublicIP.jl/tree/main/src) into there (you don't _need_ to copy `cache` from `src`, it will generate a new one the first time you run it). Add `alias publicip='julia /home/USERNAME/publicip/publicip.jl'` to `~/.bash_aliases`, or just create that file and add the command in if you don't have `.bash_aliases` already.

Thus `publicip` runs the Julia program with the ability to add options and command line arguments as you please.

## Usage
-e   --error        to show outputs to help troubleshoot errors.
-f   --force        to force the use of servers instead of cached data.
-h   --help         show this help screen.
-n   --no-newline   stop the program adding a newline at the end.
-v   --verbose      show a bit more about where/how the output was produced.
     --version      show version information.

Use on its own to simply print the IP address of your network.
```
~$ publicip
123.234.321.1
~$
```

Use `-n` or `--no-newline` if you want to make a call to this like an API, and want exactly the address and no more.
```
~$ publicip
123.234.321.1~$
```

Use `-f` or `--force` to make sure a new request is made from a server, rather than using cached data.
```
~$ publicip -f
123.234.321.1
~$
```

Use `-v` or `--verbose` to show which website/server was used to get the data.
```
~$ publicip -v
IP Address: 123.234.321.1
Server used: ipecho.net  	(results from cache)
~$
```

Combine `-v` with `-f` or other options, to get, for example

```
~$ publicip -v
IP Address: 123.234.321.1
Server used: ipecho.net
~$
```

## License
I have done my best to make sure I only connect to servers that don't mind being used like this. However, if a web service you are in control of is used here, and you should like it not to be, please make an issue and I should be able to remove that from the code here promptly.

Code given here licensed under [GPL v2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
