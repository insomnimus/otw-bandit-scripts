param (
	[Parameter(mandatory, position = 0)]
	[int] $level
)

if($level -eq 14) {
	ssh -i ./bandit.privkey -p 2220 "bandit$level@bandit.labs.overthewire.org"
} else {
	ssh -p 2220 "bandit$level@bandit.labs.overthewire.org"
}
