module cargs

fn test_no_opts() {
	opts := analyse_usage('', false, false)
	assert opts.len == 0
}

fn test_no_options_line() {
	opts := analyse_usage('
Options:
  -l|--line-break     append a line break to the JSON output
',
		true, false)
	assert opts.len == 1
	assert opts[0].short == 'l'
	assert opts[0].long == 'line-break'
	assert opts[0].val == ''
}

fn test_flag() {
	opts := analyse_usage('
Options:
  -l|--line-break  append a line break to the JSON output
',
		false, false)
	assert opts.len == 1
	assert opts[0].short == 'l'
	assert opts[0].long == 'line-break'
	assert opts[0].val == ''
}

fn test_short_flag() {
	opts := analyse_usage('
Options:
  -l  append a line break to the JSON output
', false,
		false)
	assert opts.len == 1
	assert opts[0].short == 'l'
	assert opts[0].long == ''
	assert opts[0].val == ''
}

fn test_long_flag() {
	opts := analyse_usage('
Options:
  --line-break  append a line break to the JSON output
',
		false, false)
	assert opts.len == 1
	assert opts[0].short == ''
	assert opts[0].long == 'line-break'
	assert opts[0].val == ''
}

fn test_no_negative() {
	opts := analyse_usage('
Options:
  --no-line-break  do not append a line break to the JSON output
',
		false, true)
	assert opts.len == 1
	assert opts[0].short == ''
	assert opts[0].long == 'no-line-break'
	assert opts[0].val == ''
}

fn test_val() {
	opts := analyse_usage('
Options:
  -o|--output <file>  write the JSON output to a file
',
		false, false)
	assert opts.len == 1
	assert opts[0].short == 'o'
	assert opts[0].long == 'output'
	assert opts[0].val == 'file'
}

fn test_short_val() {
	opts := analyse_usage('
Options:
  -o <file>  write the JSON output to a file
', false,
		false)
	assert opts.len == 1
	assert opts[0].short == 'o'
	assert opts[0].long == ''
	assert opts[0].val == 'file'
}

fn test_long_val() {
	opts := analyse_usage('
Options:
  --output [file]  write the JSON output to a file
',
		false, false)
	assert opts.len == 1
	assert opts[0].short == ''
	assert opts[0].long == 'output'
	assert opts[0].val == 'file'
}
