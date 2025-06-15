
# SSH socks checker

A very small Debian package for checking ssh-tunnel connectivity.

# How it works?
If your ssh-tunnel connection is lost, the ssh-socks-checker will detect it destroy the previous connection, and establish a new ssh-tunnel connection automatically.
It is very useful when the internet connection is unstable.

Dependencies:\
`jq`\
`sshpass`\
`curl`

# Install

```
// first install dependencies
# sudo apt install jq curl sshpass

// build deb package
# dpkg-deb -b [ssh-socks-checker-dir] ssh-socks-checker.deb
// install it
# sudo dpkg -i ssh-socks-checker.deb
```

# Config

To config `ssh-socks-checker`, you need to edit the `/etc/ssh-socks-checker/config.json` config file.


```
{
  "socks_host": "127.0.0.1",
  "socks_port": "1080",
  "server": "[server-ip]", // for example: 10.10.10.10
  "server_port": [server-port], // for example: 22
  "server_username": "[ssh-username]",
  "server_password": "[ssh-password]",
  "check_url": "[checker-url]", // default: http://example.com
  "recheck_time_sec": [connection check interval in sec], // for example: 20
  "timeout": [checking timeout] // for example: 5
}
```


## Contributing

Contributions are always welcome! :)

