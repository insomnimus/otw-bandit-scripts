# set -x
openssl s_client -connect localhost:30001 -ign_eof </etc/bandit_pass/bandit15 | (
	while read -r s; do
		if [[ $s == 'Correct!' ]]; then
			read -r s
			printf '%s\n' "$s"
			break
		fi
	done
)
