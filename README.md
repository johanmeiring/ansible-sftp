# SFTP-Server
An Ansible role which configures an OpenSSH server for chrooted SFTP access.  The role is built in such a way that it will not unnecessarily alter a user's OpenSSH customisations.  Instead, it simply changes the crucial bits that it needs to, and adds the rest of its configuration in the form of a custom config block (OpenSSH's lack of some form of conf.d/ support forces this behaviour).

## Requirements
It is advisable that `scp_if_ssh` be set to `true` in the `ssh_connection` section of your `ansible.cfg` file, seeing as how Ansible uses SFTP for file transfers by default, and you can easily lock yourself out of your server's SFTP by using this role.  The SCP fallback will continue to work.  Example config:

```ini
; ansible.cfg
...
[ssh_connection]
scp_if_ssh=True
```

Other than that, only Ansible itself is required.  Tested using Ansible 2.0.2.0, 2.2.2.0 and 2.3.0.0, and 2.8.2.x  Works on Ubuntu 14.04, 16.04 and 18.04. Untested on other versions.  Some work has been done on supporting RHEL, though this is not currently officially supported by the original author (further contributions are obviously welcome ;-)

## Role Variables
The following role variables are relevant:

* `sftp_home_partition`: The partition where SFTP users' home directories will be located.  Defaults to "/home".
* `sftp_group_name`: The name of the Unix group to which all SFTP users must belong.  Defaults to "sftpusers".
* `sftp_directories`: A list of directories that need to be created automatically by default for all SFTP user. Defaults to a blank list (i.e. "[]").
  * Values can be plain strings, or dictionaries containing `name`, `group` and `mode` key/value pairs. (an ansible bug force us to accept only 3 digits for `mode`, not 4)
* `sftp_allow_passwords`: Whether or not to allow password authentication for SFTP users. Defaults to False. NOTE: if global SSH configuration does not allow to use passwords, setting this to True will not work (see and adapt `PasswordAuthentication` from SSH configuration).
* `sftp_enable_logging`: Enable logging. Auth logs will be written to `/var/log/sftp/auth.log`, and SFTP activity logs will be written to `/var/log/sftp/verbose.log`. Defaults to False.
* `sftp_groups`: A list of groups, in map form, containing the following elements:
  * `name`: The Unix name of the group that requires SFTP access.
  * `gid`: The group identifier.
  * `readonly`: Whether or not to enable readonly SFTP session for the current group. Defaults to False.
* `sftp_users`: A list of users, in map form, containing the following elements:
  * `name`: The Unix name of the user that requires SFTP access.
  * `password`: A password hash for the user to login with.  Blank passwords can be set with `password: ""`. See 'Notes' section above to checkout out how generate hashed password from plain-text password. NOTE: It appears that `UsePAM yes` and `PermitEmptyPassword yes` need to be set in `sshd_config` in order for blank passwords to work properly.  Making those changes currently falls outside the scope of this role and will need to be done externally. NOTE2: when updating this value, please check `update_password` property.
  * `update_password`: Set it to true when you need to force the password to be changed.
  * `uid` : Specify the user identifier on the system
  * `groups` : Define at which groups the user belongs to (i.e. "[]").
  * `shell`: Boolean indicating if the user should have a shell access (default to `True`).
  * `authorized`: An optional list of files placed in `files/` which contain valid public keys for the SFTP user.
  * `sftp_directories`: A list of directories that need to be individually created for an SFTP user. Defaults to a blank list (i.e. "[]").
  * `append`: Boolean to add `sftp_group_name` to the user groups (if any) instead of setting it (default to `False`).
* `sftp_nologin_shell`: The "nologin" user shell. (defaults to /sbin/nologin.)

## Notes
* The `sftp_nologin_shell` setting defines the shell assigned to sftp_users when the sftp user's shell is set to False. (The nologin shell ensures the user may only use SFTP and have no other login permissions.) This value may vary depending on the operating system version.
* Here is the way to generate a hashed password for `sftp_users`. The associated hash must be set into the `password` attribute.
```
pass='mypa$$w*rd' && ansible all -i localhost, -m debug -a "msg={{ '${pass}' | password_hash('sha512', 'mysecretsalt') }}"
localhost | SUCCESS => {
    "msg": "$6$mysecretsalt$CwBxxKCk8CiFIRrIW6pduZ5U0b8pcEaaSMTfDFrkxjwnFjCLP4Uv.5QGwnnKxfQpbi4nHcTPW1CY1iBpVQRcE/"
}
```
Every '\\' char in the plain-text password must be backslashed :
```
pass='mypa\\word' && ansible all -i localhost, -m debug -a "msg={{ '${pass}' | password_hash('sha512', 'mysecretsalt') }}"
localhost | SUCCESS => {
    "msg": "$6$mysecretsalt$WVhiKVoovyRrQ8AY9Q.l6BV797wWSkmnhgAMPvtXwO5HVNRD1r0bArRYvLnh9Uu0gh0urkeeybdJhoaXpYi270"
}
```
In the last example, the real password is 'mypa\word'

## Example Playbook
```yaml
---
- name: test-playbook | Test sftp-server role
  hosts: all
  become: yes
  become_user: root

  roles:
    - role: ansible-role-sftp
      sftp_allow_passwords: true
      sftp_enable_logging: true
      sftp_groups:
        - name: sftpusers
          gid: 1337
      sftp_directories:
        - imports
        - exports
        - { name: public, mode: 755, group: 'sftpusers' }
      sftp_users:
        - name: peter
          password: "$1$salty$li5TXAa2G6oxHTDkqx3Dz/" # passpass
          shell: False
          append: True
          groups:
            - sftpusers
          sftp_directories:
            - directory_only_for_peter1
            - directory_only_for_peter2
        - name: sally
          password: ""
          authorized: [sally.pub]
          append: True

```

## License
This Ansible role is distributed under the MIT License.  See the LICENSE file for more details.

## Thanks
- [johanmeiring](https://github.com/johanmeiring) for the hard work
- [Scalair](https://scalair.fr)
