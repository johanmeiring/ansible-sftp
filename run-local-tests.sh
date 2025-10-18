#!/bin/bash
set -e

run_test() {
  ANSIBLE_BIN=/root/.local/share/pipx/venvs/ansible/bin/ansible
  ANSIBLE_PLAYBOOK_BIN=/root/.local/share/pipx/venvs/ansible/bin/ansible-playbook

  echo "Testing role on Ansible version $3 on $1 $2....."
  docker pull $1:$2
  docker build --rm=true --file=tests/Dockerfile.$1-$2.ansible-$3 --tag=$1-$2:ansible-$3 tests
  container_id=$(mktemp)

  # Trap to ensure container cleanup on exit
  cleanup() {
    if [ -f "${container_id}" ] && [ -s "${container_id}" ]; then
      echo "Cleaning up container..."
      docker stop "$(cat ${container_id})" 2>/dev/null || true
      rm -f "${container_id}"
    fi
  }
  trap cleanup EXIT

  docker run --rm=true --detach --volume="${PWD}":/etc/ansible/roles/role_under_test:ro $1-$2:ansible-$3 sleep infinity > "${container_id}"
  docker exec --tty "$(cat ${container_id})" env TERM=xterm ${ANSIBLE_BIN} --version
  docker exec --tty "$(cat ${container_id})" env TERM=xterm ${ANSIBLE_PLAYBOOK_BIN} /etc/ansible/roles/role_under_test/tests/test.yml --syntax-check
  docker exec --tty "$(cat ${container_id})" env TERM=xterm ${ANSIBLE_PLAYBOOK_BIN} /etc/ansible/roles/role_under_test/tests/test.yml
  docker exec --tty "$(cat ${container_id})" env TERM=xterm grep "user1" /etc/shadow && (echo 'User created' && exit 0) || (echo 'User not created' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm test -d /home/user1/test1 && (echo 'Directory created' && exit 0) || (echo 'Directory not created' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm grep "foobar" /etc/group && (echo 'Group created' && exit 0) || (echo 'Group not created' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm stat -c '%G' /var/tmp/user2
  docker exec --tty "$(cat ${container_id})" env TERM=xterm '[ $(stat --format '%G' /var/tmp/user2) = "foobar" ]' && (echo 'Good directory ownership' && exit 0) || (echo 'Wrong directory ownership' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm '[ $(stat --format '%G' /home/user1) = "sftpusers" ]' && (echo 'Good directory ownership' && exit 0) || (echo 'Wrong directory ownership' && exit 1)
  docker exec --tty "$(cat ${container_id})" env TERM=xterm test -d /home/user1/test3 && (echo 'User Directory created' && exit 0) || (echo 'User Directory not created' && exit 1)
  docker exec "$(cat ${container_id})" ${ANSIBLE_PLAYBOOK_BIN} /etc/ansible/roles/role_under_test/tests/test.yml | grep -q 'changed=1.*failed=0' && (echo 'Idempotence test: pass' && exit 0) || (echo 'Idempotence test: fail' && exit 1)

  # Container will be stopped by the trap on exit
}

run_test ubuntu 24.04 11
run_test ubuntu 24.04 12
