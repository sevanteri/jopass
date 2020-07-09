# Jopass
Wrapper for 1Password cli `op` written in Janet-lang

Utilises GPG to decrypt the password for `op`.

Remember to upgrade your 1Password cli to the latest version.


Jopass is designed to work similarly to the amazing [standard unix password manager](https://www.passwordstore.org/). Simply running `jopass` gives you a list of all your passwords and running `jopass "password title"` gives you the password which you can pipe anywhere you want. The password can also be copied to your clipboard (`xclip) `or even typed straight to the text input (`xdotool`).

In addition to passwords, with Jopass you can get the username and even the TOTP codes for your items. Again, these can be piped, copied or typed.

The help output shows all the options you can use:

```
usage: jopass [option] ...

Print/copy/type your 1Password passwords/usernames/TOTPs easily.

 Optional:
 -a, --account VALUE                         Account shorthand
 -c, --copy                                  Copy to clipboard
 -h, --help                                  Show this help message.
 -t, --totp                                  Get TOTP code
 -T, --type                                  Type it
 -u, --username                              Get username
```

## Example use

No need to copy your TOTP token from your phone or the desktop apps. Just pipe it.

`jopass "my aws profile" -t | aws-mfa --profile my-profile`


## TODO
- Cache items for faster listing.
- dmenu / rofi menus.
- Make decrypting and typing software configurable.
- Optionally cache passwords? Maybe useful for frequently used passwords.
- Use item UUIDs instead of their name.


## License

MIT
