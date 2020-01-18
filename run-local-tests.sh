#!/bin/bash
set -e

run_test() {
  echo "Testing role on Ansible version $3 on $1 $2....."
  docker pull $1:$2
  docker build --rm=true --file=tests/Dockerfile.$1-$2.ansible-$3 --tag=$1-$2:ansible-$3 tests
  container_id=$(mktemp)
  docker run --rm=true --detach --volume="${PWD}":/etc/ansible/roles/role_under_test:ro $1-$2:ansible-$3 /sbin/init > "${container_id}"
  docker exec --tty "$(cat ${container_id})" env TERM=xterm python --version
  docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml --syntax-check
  docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml
  docker exec --tty "$(cat ${container_id})" env TERM=xterm grep "user1" /etc/shadow && (echo 'User created' && exit 0) || (echo 'User not created' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm test -d /home/user1/test1 && (echo 'Directory created' && exit 0) || (echo 'Directory not created' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm grep "foobar" /etc/group && (echo 'Group created' && exit 0) || (echo 'Group not created' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm stat -c '%G' /var/tmp/user2
  docker exec --tty "$(cat ${container_id})" env TERM=xterm '[ $(stat --format '%G' /var/tmp/user2) = "foobar" ]' && (echo 'Good directory ownership' && exit 0) || (echo 'Wrong directory ownership' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm '[ $(stat --format '%G' /home/user1) = "sftpusers" ]' && (echo 'Good directory ownership' && exit 0) || (echo 'Wrong directory ownership' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm test -d /home/user1/test3 && (echo 'User Directory created' && exit 0) || (echo 'User Directory not created' && exit 1)
  docker exec "$(cat ${container_id})" ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml | grep -q 'changed=0.*failed=0' && (echo 'Idempotence test: pass' && exit 0) || (echo 'Idempotence test: fail' && exit 1)
  docker stop "$(cat ${container_id})"
}

run_test ubuntu 16.04 2.5
run_test ubuntu 16.04 2.9

run_test ubuntu 18.04 2.5
run_test ubuntu 18.04 2.9

run_test centos 7 2.5
run_test centos 7 2.9

run_test centos 8 2.5
run_test centos 8 2.9
