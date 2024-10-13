#!/usr/bin/env bash

scriptdir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
scriptname="$(basename -- "$0")"

level=""
save=""
load=""
cooldown=2s
declare -i n_ssh=0
declare -A solutions

bandit14_privkey=/tmp/bandit14.privkey

set -e

{
	function err() {
		echo 1>&2 "error: $*"
		exit 1
	}

	function show-help() {
		cat <<-END
			usage: $scriptname [OPTIONS] <LEVEL>

			Solves overthewire.org's Bandit levels

			OPTIONS:
			  -s, --save: Save solutions to a file
			  -l, --load: Load solutions from a file
			  -c, --cooldown: Sleep some duration between ssh calls [default: "$cooldown"]
			  -h, --help: Show usage information
		END

		exit 0
	}

	argv=()
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--?*=*)
			argv+=("${1%%=*}" "${1#*=}")
			;;
		-[!-]*)
			for ((i = 1; i < ${#1}; i++)); do
				c="${1:i:1}"
				argv+=("-$c")
				if [[ $c == [slc] && $i -lt ${#1}-1 ]]; then
					# It's a known option with a value attached.
					argv+=("${1:i+1}")
					break
				fi
			done
			;;
		*)
			argv+=("$1")
			;;
		esac
		shift
	done

	set -- "${argv[@]}"
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help) show-help ;;
		-s | --save)
			if ! shift; then
				err "the option $1 requires a value but no value was provided"
			fi
			save="$1"
			;;
		-l | --load)
			if ! shift; then
				err "the option $1 requires a value, but no value was provided"
			fi
			load="$1"
			;;
		-c | --cooldown)
			if ! shift; then
				err "the option $1 requires a value, but no value was provided"
			fi
			cooldown="$1"
			;;
		-*) err "unknown option $1" ;;
		*)
			if [[ -n $level ]]; then
				err "you can only solve one level at a time"
			elif [[ ! $1 =~ ^[0-9]+$ ]]; then
				err "invalid level number: $1"
			fi
			level="$1"
			;;
		esac

		shift
	done

	if [[ -z $level ]]; then
		err "missing required argument: level number"
	fi
}

set -ue

function get-solver() {
	local lvl="$1"
	if [[ $lvl == 13 ]]; then
		return
	fi

	local z
	for z in "" 0 00 000; do
		local p="$scriptdir/solvers/$z$lvl.sh"
		if [[ -f $p ]]; then
			local s
			s="$(cat -- "$p")"
			if [[ $s =~ ^[[:space:]]*$ ]]; then
				err "the solver for $lvl is empty"
			fi
			printf %s "$p"
			return
		fi
	done

	err "no solver for level $lvl found in $scriptdir/solvers"
}

function solve() {
	local -i lvl="$1"
	local password="$2"
	if [[ $lvl == -1 ]]; then
		echo bandit0
		return
	fi

	# Is it cached?
	local solution="${solutions["$lvl"]:-}"
	if [[ -n $solution ]]; then
		printf %s "$solution"
		return
	fi

	local solver
	solver="$(get-solver "$lvl")"
	script="$(cat -- "$solver")"
	if [[ $n_ssh != 0 ]]; then
		sleep "$cooldown"
	fi

	local output
	if [[ $lvl == 14 ]]; then
		output="$(ssh -i "$bandit14_privkey" -p 2220 "bandit$lvl@bandit.labs.overthewire.org" "$script")"
	else
		output="$(sshpass -p "$password" ssh -C -p 2220 "bandit$lvl@bandit.labs.overthewire.org" "$script" 2>&1)"
	fi
	((n_ssh++))
	password="$(tail -1 <<<"$output")"
	printf %s "$password"
}

{
	if [[ -n $load ]]; then
		if [[ ! -e $load ]]; then
			err "the load file specified with -l/--load does not exist: $load"
		fi

		while read -r s; do
			if [[ ! $s =~ ^level[[:space:]]+[0-9]+[[:space:]]*:[[:space:]]*.+$ ]]; then
				continue
			fi

			prefix="${s%%[0-9]*}"
			s="${s:${#prefix}}"

			declare -i l=${s%%:*}
			s="${s:1+${#l}}"
			s="${s#"${s%%[![:space:]]*}"}"
			p="${s%"${s##*[![:space:]]}"}"

			solutions["$l"]="$p"
		done <"$load"
	fi
}

# Ensure we have solvers for all levels leading up to this one
for ((i = level; i > 0; i--)); do
	if [[ -z ${solutions["$i"]:-} ]]; then
		get-solver "$i" >/dev/null
	fi
done

password=bandit0
for ((i = 0; i <= level; i++)); do
	if [[ $i == 13 ]]; then
		if [[ $n_ssh != 0 ]]; then
			sleep "$cooldown"
		fi
		((n_ssh++))
		sshpass -p "$password" scp -P 2220 "bandit$i@bandit.labs.overthewire.org:sshkey.private" "$bandit14_privkey"
		chmod 0600 "$bandit14_privkey"
		continue
	fi
	password="$(solve "$i" "$password")"
	echo 1>&2 "level $i: $password"
	solutions["$i"]="$password"
done

{
	if [[ -n $save ]]; then
		# Write in sorted order
		max=-999
		for l in "${!solutions[@]}"; do
			if [[ $l -gt "$max" ]]; then
				max="$l"
			fi
		done

		for ((i = 0; i <= max; i++)); do
			s="${solutions["$i"]:-}"
			if [[ -n $s ]]; then
				echo "level $i: ${solutions["$i"]}"
			fi
		done >"$save"
	fi
}
