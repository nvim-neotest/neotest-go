local patterns = {
	testfile = '^%s%s%s%s(.*_test.go):(%d+): ',
	testlog = '^%s%s%s%s%s%s%s%s',
	error = { 'error' },
}

return patterns
