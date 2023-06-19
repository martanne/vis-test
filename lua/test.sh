#!/bin/sh

export VIS_PATH=.
[ -z "$VIS" ] && VIS="../../vis"
$VIS -v

if ! $VIS -v | grep '+lua' >/dev/null 2>&1; then
	echo "vis compiled without lua support, skipping tests"
	exit 0
fi

type busted >/dev/null 2>&1 || {
	echo "busted(1) not found, skipping tests"
	exit 0
}

TESTS_OK=0
TESTS_RUN=0

if [ $# -gt 0 ]; then
	test_files=$*
else
	test_files="$(find . -type f -name '*.lua' -a ! -name visrc.lua)"
fi

for t in $test_files; do
	TESTS_RUN=$((TESTS_RUN + 1))
	t=${t%.lua}
	t=${t#./}
	printf "%-30s" "$t"
	mkfifo infifo
	$VIS "$t.in" <infifo 2> /dev/null > "$t.busted" &
	for i in 1;	do sleep 0.1s; echo ":qall!"; done > infifo &
	wait %1 && wait %2
	if [ $? -ne 0 ]; then
		printf "FAIL\n"
		cat "$t.busted"
	else
		TESTS_OK=$((TESTS_OK + 1))
		printf "OK\n"
	fi
	rm infifo
done

printf "Tests ok %d/%d\n" $TESTS_OK $TESTS_RUN

# set exit status
[ $TESTS_OK -eq $TESTS_RUN ]
