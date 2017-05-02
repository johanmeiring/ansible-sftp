# SFTP-Server

[![Build Status](https://travis-ci.org/johanmeiring/ansible-sftp.svg?branch=master)](https://travis-ci.org/johanmeiring/ansible-sftp)

An Ansible role which configures an OpenSSH server for chrooted SFTP access.  The role is built in such a way that it will not unnecessarily alter a user's OpenSSH customisations.  Instead, it simply changes the crucial bits that it needs to, and adds the rest of its configuration in the form of a custom config block (OpenSSH's lack of some form of conf.d/ support forces this behaviour).

## Requirements

It is advisable that `scp_if_ssh` be set to `true` in the `ssh_connection` section of your `ansible.cfg` file, seeing as how Ansible uses SFTP for file transfers by default, and you can easily lock yourself out of your server's SFTP by using this role.  The SCP fallback will continue to work.  Example config:

```ini
; ansible.cfg
...
[ssh_connection]
scp_if_ssh=True
```

Other than that, only Ansible itself is required.  Tested using Ansible 2.0.2.0, 2.1.0.0 and 2.2.1.0.  Works on Ubuntu 14.04 and 16.04, untested on other versions.  Some work has been done on supporting RHEL, though this is not currently officially supported by the original author (further contributions are obviously welcome ;-)

## Role Variables

The following role variables are relevant:

* `sftp_home_partition`: The partition where SFTP users' home directories will be located.  Defaults to "/home".
* `sftp_group_name`: The name of the Unix group to which all SFTP users must belong.  Defaults to "sftpusers".
* `sftp_directories`: A list of directories that need to be created automatically by default for all SFTP user. Defaults to a blank list (i.e. "[]").
  * Values can be plain strings, or dictionaries containing `name` and (optionally) `mode` key/value pairs.
* `sftp_allow_passwords`: Whether or not to allow password authentication for SFTP. Defaults to False.
* `sftp_enable_selinux_support`: Whether or not to explicitly enable SELinux support. Defaults to False.
* `sftp_enable_logging`: Enable logging. Auth logs will be written to `/var/log/sftp/auth.log`, and SFTP activity logs will be written to `/var/log/sftp/verbose.log`. Defaults to False.
* `sftp_users`: A list of users, in map form, containing the following elements:
  * `name`: The Unix name of the user that requires SFTP access.
  * `password`: A password hash for the user to login with.  Blank passwords can be set with `password: ""`.  NOTE: It appears that `UsePAM yes` and `PermitEmptyPassword yes` need to be set in `sshd_config` in order for blank passwords to work properly.  Making those changes currently falls outside the scope of this role and will need to be done externally.
  * `shell`: Boolean indicating if the user should have a shell access (default to `True`).
  * `authorized`: An optional list of files placed in `files/` which contain valid public keys for the SFTP user.
  * `sftp_directories`: A list of directories that need to be individually created for an SFTP user. Defaults to a blank list (i.e. "[]").


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
    - sftp_directories:
      - imports
      - exports
      - { name: public, mode: 755 }
      - other
  roles:
    - sftp-server
```

## License

Licensed under the MIT License. See the LICENSE file for details.
