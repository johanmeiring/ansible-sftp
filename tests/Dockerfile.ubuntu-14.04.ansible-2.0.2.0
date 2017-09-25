FROM ubuntu:14.04
RUN apt-get update

# Install OpenSSH server
RUN apt-get install -y openssh-server

# Install Ansible
RUN apt-get install -y software-properties-common git python-pip python-dev libffi-dev libssl-dev
RUN pip install -U setuptools
RUN pip install 'ansible==2.0.2.0'

# Install Ansible inventory file
RUN mkdir /etc/ansible/ && echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts
