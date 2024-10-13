# Over The Wire: Bandit
This repository contains solver scripts for [overthewire.org's Bandit game](https://overthewire.org/wargames/bandit/).

## Usage
First install the `sshpass` utility (`pacman -S sshpass`, `apt install sshpass` etc).
You'll also need `ssh` and `scp`.

Then invoke the `solve.sh` script with the level you want. The script will solve all levels leading up to and including that level and print the passwords.
Note that the solution for level `N` is the password for level `N -> N+1`.

You can also save and load the passwords to not tax the overthewire servers.

```shell
# Solve up to level 5
./solve.sh 5
# Solve up to level 5 and save progress
./solve.sh 5 --save ./solutions.txt
# Solve up to level 10, loading previously saved solutions
./solve.sh 10 --load ./solutions.txt
# You can specify --save and --load at the same time
./solve.sh 12 --save=solutions.txt --load=solutions.txt
# To see rest of the usage:
./solve.sh --help
```

> Note that level 13's solution is not a password; it's an ssh key that's saved to a temporary location.
