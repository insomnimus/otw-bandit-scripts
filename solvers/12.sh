tmp="$(mktemp -d)"
cd "$tmp"
xxd -r ~/data.txt data
f=data

while : true; do
	s="$(file -b ./*)"
	case "$s" in
	*gzip*)
		mv ./* data.gz
		gunzip data.gz
		;;
	*bzip2*)
		bunzip2 ./* &>/dev/null
		;;
	*tar*)
		f="$(echo ./*)"
		tar -xf $f && rm $f
		;;
	*text*)
		sed -nr 's/The password is //gip' ./*
		break
		;;
	*)
		echo "unhandled data type: $s"
		break
		;;
	esac
done
