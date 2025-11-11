all: format lint test

test:
	/usr/bin/nvim --headless -u scripts/minimal-for-lazy.lua -c "PlenaryBustedDirectory lua/spec { minimal_init='./scripts/minimal-for-lazy.lua', sequential=true, }"


lint:
	luacheck lua

format:
	stylua lua

