strings data.txt |
	sed -nr 's/.*===* *(.+)/\1/gp' |
	tail -1
