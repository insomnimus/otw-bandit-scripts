for f in ~/inhere/*; do
	s="$(file -b "$f")"
	if [[ $s == *"ASCII"* ]]; then
		exec cat "$f"
	fi
done

exit 1
