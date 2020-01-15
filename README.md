# SFTP-Server

[![Ansible Role](https://img.shields.io/ansible/role/991.svg)](https://galaxy.ansible.com/johanmeiring/sftp-server/) [![Software License](https://img.shields.io/badge/License-MIT-orange.svg?style=flat-round)](https://github.com/johanmeiring/ansible-sftp/blob/master/LICENSE) [![Build Status](https://travis-ci.com/johanmeiring/ansible-sftp.svg?branch=master)](https://travis-ci.com/johanmeiring/ansible-sftp)

An Ansible role which configures an OpenSSH server for chrooted SFTP access.  The role is built in such a way that it will not unnecessarily alter a user's OpenSSH customisations.  Instead, it simply changes the crucial bits that it needs to, and adds the rest of its configuration in the form of a custom config block (OpenSSH's lack of some form of conf.d/ support forces this behaviour).

## Requirements

It is advisable that `scp_if_ssh` be set to `true` in the `ssh_connection` section of your `ansible.cfg` file, seeing as how Ansible uses SFTP for file transfers by default, and you can easily lock yourself out of your server's SFTP by using this role.  The SCP fallback will continue to work.  Example config:

```ini
; ansible.cfg
...
[ssh_connection]
scp_if_ssh=True
```

Other than that, only Ansible itself is required.  Tested using Ansible 2.0.2.0, 2.2.2.0 and 2.3.0.0.  Works on Ubuntu 14.04 and 16.04, untested on other versions.  Some work has been done on supporting RHEL, though this is not currently officially supported by the original author (further contributions are obviously welcome ;-)

## Role Variables

The following role variables are relevant:

* `sftp_home_partition`: The partition where SFTP users' home directories will be located.  Defaults to "/home".
* `sftp_group_name`: The name of the Unix group to which all SFTP users must belong.  Defaults to "sftpusers".
* `sftp_directories`: A list of directories that need to be created automatically by default for all SFTP user. Defaults to a blank list (i.e. "[]").
  * Values can be plain strings, or dictionaries containing `name` and (optionally) `mode` key/value pairs.
* `sftp_start_directory`: A directory that need to be part of sftp_directories values and that is the start directory of new sftp connection. Disable by default with an empty string value.
* `sftp_allow_passwords`: Whether or not to allow password authentication for SFTP. Defaults to False.
* `sftp_enable_selinux_support`: Whether or not to explicitly enable SELinux support. Defaults to False.
* `sftp_enable_logging`: Enable logging. Auth logs will be written to `/var/log/sftp/auth.log`, and SFTP activity logs will be written to `/var/log/sftp/verbose.log`. Defaults to False.
* `sftp_users`: A list of users, in map form, containing the following elements:
  * `name`: The Unix name of the user that requires SFTP access.
  * `group`: An optional user primary group. If set, it will be used for the user's home permission. Otherwise, the `sftp_group_name` is used.
  * `password`: A password hash for the user to login with - ie `openssl passwd -1 -salt salty passpass`.  Blank passwords can be set with `password: ""`.  NOTE: It appears that `UsePAM yes` and `PermitEmptyPassword yes` need to be set in `sshd_config` in order for blank passwords to work properly.  Making those changes currently falls outside the scope of this role and will need to be done externally.
  * `shell`: Boolean indicating if the user should have a shell access (default to `True`).
  * `authorized`: An optional list of files placed in `files/` which contain valid public keys for the SFTP user.
  * `sftp_directories`: A list of directories that need to be individually created for an SFTP user. Defaults to a blank list (i.e. "[]").
  * `append`: Boolean to add `sftp_group_name` to the user groups (if any) instead of setting it (default to `False`).
  * `mode`: The users home directory mode (defaults to `0750`).
  * `skeleton`: An optional home skeleton directory (e.g: /dev/null). Default to system defaults.
  * `home`: An optional home directory (e.g: /home/bob). Default to `sftp_home_partition/name`.
* `sftp_nologin_shell`: The "nologin" user shell. (defaults to /sbin/nologin.)

Notes:

* The `sftp_nologin_shell` setting defines the shell assigned to sftp_users when the sftp user's shell is set to False. (The nologin shell ensures the user may only use SFTP and have no other login permissions.) This value may vary depending on the operating system version.

## Example Playbook

```yaml
---
- name: test-playbook | Test sftp-server role
  hosts: all
  become: yes
  become_user: root
  vars:
    - sftp_users:
      - name: peter
        password: "$1$salty$li5TXAa2G6oxHTDkqx3Dz/" # passpass
        shell: False
        sftp_directories:
        - directory_only_for_peter1
        - directory_only_for_peter2
      - name: sally
        password: ""
        authorized: [sally.pub]
        home: /var/tmp/sally
        append: True
    - sftp_directories:
      - imports
      - exports
      - { name: public, mode: 755 }
      - other
  roles:
    - sftp-server
```

## License

This Ansible role is distributed under the MIT License.  See the LICENSE file for more details.

## Donations

Donations are very welcome, and can be made to the following addresses:

* BTC: 1AWHJcUBha35FnuuWat9urRW2FNc4ftztv
* ETH: 0xAF1Aac4c40446F4C46e55614F14d9b32d712ECBc
