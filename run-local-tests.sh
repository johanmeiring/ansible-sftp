#!/bin/bash
set -e

run_test() {
  echo "Testing role on Ansible version $3 on $1 $2....."
  docker pull $1:$2
  docker build --rm=true --file=tests/Dockerfile.$1-$2.ansible-$3 --tag=$1-$2:ansible-$3 tests
  container_id=$(mktemp)
  docker run --rm=true --detach --volume="${PWD}":/etc/ansible/roles/role_under_test:ro $1-$2:ansible-$3 /sbin/init > "${container_id}"
  docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml --syntax-check
  docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml
  docker exec --tty "$(cat ${container_id})" env TERM=xterm grep "user1" /etc/shadow && (echo 'User created' && exit 0) || (echo 'User not created' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm test -d /home/user1/test1 && (echo 'Directory created' && exit 0) || (echo 'Directory not created' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm test -d /home/user1/test3 && (echo 'User Directory created' && exit 0) || (echo 'User Directory not created' && exit 1)
  docker exec "$(cat ${container_id})" ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml | grep -q 'changed=0.*failed=0' && (echo 'Idempotence test: pass' && exit 0) || (echo 'Idempotence test: fail' && exit 1)
  docker stop "$(cat ${container_id})"
}

run_test ubuntu 14.04 2.2.2.0
run_test ubuntu 14.04 2.3.0.0

run_test ubuntu 16.04 2.2.2.0
run_test ubuntu 16.04 2.3.0.0

run_test centos 6 2.2.2.0
run_test centos 6 2.3.0.0

run_test centos 7 2.2.2.0
run_test centos 7 2.3.0.0
