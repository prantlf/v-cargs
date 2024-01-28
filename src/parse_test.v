module cargs

struct Two {
	line_break bool
	output     string
}

struct TwoTrue {
	line_break bool = true
	output     string
}

struct TwoNegative {
	no_line_break bool
}

struct TwoPositiveTrue {
	line_break bool = true
}

struct TwoPositiveFalse {
	line_break bool
}

fn test_no_opts_no_args() {
	opts, args := parse[Two]('', Input{ args: [] })!
	assert opts.line_break == false
	assert opts.output == ''
	assert args == []
}

fn test_opts_no_args() {
	opts, args := parse[Two]('
Options:
  -l|--line-break     append a line break to the JSON output
  -o|--output <file>  write the JSON output to a file
',
		Input{ args: [] })!
	assert opts.line_break == false
	assert opts.output == ''
	assert args == []
}

fn test_opts_args() {
	opts, args := parse[Two]('
Options:
  -l|--line-break     append a line break to the JSON output
  -o|--output <file>  write the JSON output to a file
',
		Input{ args: ['-l', '-o', 'ci.yaml'] })!
	assert opts.line_break == true
	assert opts.output == 'ci.yaml'
	assert args == []
}

fn test_opts_args_to() {
	mut opts := Two{}
	args := parse_to('
Options:
  -l|--line-break     append a line break to the JSON output
  -o|--output <file>  write the JSON output to a file
',
		Input{ args: ['-l', '-o', 'ci.yaml'] }, mut opts)!
	assert opts.line_break == true
	assert opts.output == 'ci.yaml'
	assert args == []
}

fn test_no_options_line() {
	opts, args := parse[Two]('
  -l|--line-break     append a line break to the JSON output
',
		Input{ args: ['-l'], options_anywhere: true })!
	assert opts.line_break == true
}

fn test_no_negative_options() {
	opts, args := parse[TwoNegative]('
Options:
  -n|--no-line-break  do not append a line break to the JSON output
',
		Input{ args: ['-n'], no_negative_options: true })!
	assert opts.no_line_break == true
}

fn test_negative_option() {
	opts, args := parse[TwoPositiveTrue]('
Options:
  -N|--no-line-break  do not append a line break to the JSON output
',
		Input{ args: ['-N'] })!
	assert opts.line_break == false
}

fn test_positive_option() {
	opts, args := parse[TwoPositiveFalse]('
Options:
  -N|--no-line-break  do not append a line break to the JSON output
',
		Input{ args: ['-n'] })!
	assert opts.line_break == true
}

fn test_neg_short_flag() {
	opts, args := parse[Two]('
Options:
  -l, --line-break  append a line break to the JSON output
',
		Input{ args: ['-L'] })!
	assert opts.line_break == false
	assert args == []
}

fn test_neg_long_flag() {
	opts, args := parse[Two]('
Options:
  -l|--line-break  append a line break to the JSON output
',
		Input{ args: ['--no-line-break'] })!
	assert opts.line_break == false
	assert args == []
}

fn test_neg_long_flag_declaration() {
	opts, args := parse[TwoTrue]('
Options:
  --no-line-break  append a line break to the JSON output
',
		Input{ args: ['--no-line-break'] })!
	assert opts.line_break == false
	assert args == []
}

fn test_arg() {
	_, args := parse[Two]('', Input{ args: ['test'] })!
	assert args == ['test']
}

fn test_dash() {
	_, args := parse[Two]('', Input{ args: ['-'] })!
	assert args == ['-']
}

fn test_dash_arg() {
	_, args := parse[Two]('', Input{ args: ['--', '-test'] })!
	assert args == ['-test']
}

struct Condensed {
	o bool
	t bool
}

fn test_condensed() {
	opts, args := parse[Condensed]('
Options:
  -o
	-t
', Input{ args: ['-ot'] })!
	assert opts.o == true
	assert opts.t == true
	assert args == []
}

enum Human {
	man
	woman
}

struct Integrals {
	human Human
	u8    u8
	u16   u16
	u32   u32
	u64   u64
	i8    i8
	i16   i16
	int   int
	i64   i64
	f32   f32
	f64   f64
	rune  rune
	char  char
}

fn test_integral_types() {
	opts, args := parse[Integrals]('
Options:
  --human <enum>
  --u8 <num>
  --u16 <num>
  --u32 <num>
  --u64 <num>
  --i8 <num>
  --i16 <num>
  --int <num>
  --i64 <num>
  --f32 <num>
  --f64 <num>
  --rune <rune>
  --char <char>
',
		Input{
		args: ['--human=woman', '--u8=1', '--u16=2', '--u32=3', '--u64=4', '--i8=5', '--i16=6',
			'--int=7', '--i64=8', '--f32=9.1', '--f64=9.2', '--rune=a', '--char=b']
	})!
	assert opts.human == .woman
	assert opts.u8 == 1
	assert opts.u16 == 2
	assert opts.u32 == 3
	assert opts.u64 == 4
	assert opts.i8 == 5
	assert opts.i16 == 6
	assert opts.int == 7
	assert opts.i64 == 8
	assert opts.f32 == 9.1
	assert opts.f64 == 9.2
	assert opts.rune == `a`
	assert opts.char == `b`
	assert args == []
}

// struct Optionals {
// 	human ?Human
// 	u8    ?u8
// 	u16   ?u16
// 	u32   ?u32
// 	u64   ?u64
// 	i8    ?i8
// 	i16   ?i16
// 	int   ?int
// 	i64   ?i64
// 	f32   ?f32
// 	f64   ?f64
// 	s     ?string
// 	b     ?bool
// }

// fn test_optional_types() {
// 	opts, args := parse[Optionals]('
// Options:
//   --human <enum>
//   --u8 <num>
//   --u16 <num>
//   --u32 <num>
//   --u64 <num>
//   --i8 <num>
//   --i16 <num>
//   --int <num>
//   --i64 <num>
//   --f32 <num>
//   --f64 <num>
//   -s <str>
//   -b
// ',
// 		Input{
// 		args: ['--human=1', '--u8=1', '--u16=2', '--u32=3', '--u64=4', '--i8=5', '--i16=6', '--int=7',
// 			'--i64=8', '--f32=9.1', '--f64=9.2', '-s=s', '-b']
// 	})!
// 	assert opts.human? == .woman
// 	assert opts.u8? == 1
// 	assert opts.u16? == 2
// 	assert opts.u32? == 3
// 	assert opts.u64? == 4
// 	assert opts.i8? == 5
// 	assert opts.i16? == 6
// 	assert opts.int? == 7
// 	assert opts.i64? == 8
// 	assert opts.f32? == 9.1
// 	assert opts.f64? == 9.2
// 	assert opts.s? == 's'
// 	assert opts.b? == true
// 	assert args == []
// }

struct Positives {
	b bool
}

fn test_positives() {
	opts, args := parse[Positives]('
Options:
  -B
', Input{
		args: ['-B']
		disable_short_negative: true
	})!
	assert opts.b == true
	assert args == []
}

fn test_wrong_enum() {
	parse[Integrals]('
Options:
  --human [enum]
', Input{ args: ['--human', 'dummy'] }) or {
		assert err.msg() == '"dummy" not in Human enum'
		return
	}
	assert false
}

fn test_no_integer() {
	parse[Integrals]('
Options:
  --u8 <num>
', Input{ args: ['--u8=s'] }) or {
		assert err.msg() == '"s" is not an integer'
		return
	}
	assert false
}

fn test_no_number() {
	parse[Integrals]('
Options:
  --f64 <num>
', Input{ args: ['--f64=s'] }) or {
		assert err.msg() == '"s" is not a number'
		return
	}
	assert false
}

fn test_overflow() {
	parse[Integrals]('
Options:
  --u8 <num>
', Input{ args: ['--u8=1234'] }) or {
		assert err.msg() == 'unable to convert "1234" to u8'
		return
	}
	assert false
}

fn test_no_overflow() {
	opts, args := parse[Integrals]('
Options:
  --u8 <num>
', Input{
		args: ['--u8=1234']
		ignore_number_overflow: true
	})!
	assert opts.u8 == u8(210)
	assert args == []
}

fn test_unknown_arg() {
	parse[Integrals]('
Options:
  --u8 <num>
', Input{ args: ['--u16=1'] }) or {
		assert err.msg() == 'unknown option "--u16=1"'
		return
	}
	assert false
}

fn test_invalid_arg() {
	parse[Integrals]('
Options:
  --u8 <num>
', Input{ args: ['-u8=1'] }) or {
		assert err.msg() == 'invalid argument "-u8=1"'
		return
	}
	assert false
}

fn test_missing_arg() {
	parse[Integrals]('
Options:
  --u8 <num>
', Input{ args: ['--u8'] }) or {
		assert err.msg() == 'missing value of "--u8"'
		return
	}
	assert false
}

fn test_extra_arg() {
	parse[Positives]('
Options:
  -b
', Input{ args: ['-b=test'] }) or {
		assert err.msg() == 'extra value of "-b=test"'
		return
	}
	assert false
}

struct Renamed {
	typ string @[arg: @type]
}

fn test_rename_arg() {
	opts, args := parse[Renamed]('
Options:
  -t|--type <type>  file type (textual or binary)
',
		Input{ args: ['-t', 'text'] })!
	assert opts.typ == 'text'
}

struct Required {
	typ string @[arg: @type; required]
}

fn test_required_arg() {
	parse[Required]('
Options:
  -t|--type <type>  file type (textual or binary)
', Input{ args: [] }) or {
		assert err.msg() == 'missing required type'
		return
	}
	assert false
}

fn test_inapplicable_arg() {
	parse[Positives]('
Options:
  -p|--pretty  prints the JSON output with line breaks and indented
',
		Input{ args: ['-p'] }) or {
		assert err.msg() == 'inappliccable argument p|pretty'
		return
	}
	assert false
}

struct Array {
	numbers []int
}

fn test_array_1() {
	opts, args := parse[Array]('
Options:
  -n, --numbers <number>
', Input{
		args: ['-n', '1']
	})!
	assert opts.numbers == [1]
}

fn test_array_2() {
	opts, args := parse[Array]('
Options:
  -n, --numbers <number>
', Input{
		args: ['-n', '1', '-n', '2']
	})!
	assert opts.numbers == [1, 2]
}

fn test_array_bad_type() {
	parse[Array]('
Options:
  -n, --numbers <number>
', Input{
		args: ['-n', 'one']
	}) or {
		assert err.msg() == '"one" is not an integer'
		return
	}
	assert false
}

struct DefaultSplit {
	numbers []int @[split]
}

fn test_array_split_default() {
	opts, args := parse[DefaultSplit]('
Options:
  -n, --numbers <number>  a list of numbers to use
',
		Input{
		args: ['-n', '1,2']
	})!
	assert opts.numbers == [1, 2]
}

struct CustomSplitRune {
	chars []rune @[split: ';']
}

fn test_array_split_custom_rune() {
	opts, args := parse[CustomSplitRune]('
Options:
  -c, --chars <char>  allowed characters
',
		Input{
		args: ['-c', 'a;b']
	})!
	assert opts.chars == [`a`, `b`]
}

struct CustomSplitChar {
	chars []char @[split: ';']
}

fn test_array_split_custom_char() {
	opts, args := parse[CustomSplitChar]('
Options:
  -c, --chars <char>  allowed characters
',
		Input{
		args: ['-c', 'a;b']
	})!
	assert opts.chars == [char(`a`), char(`b`)]
}

struct CustomSplit {
	chars []string @[split: ';']
}

fn test_array_split_custom() {
	opts, args := parse[CustomSplit]('
Options:
  -c, --chars <char>  allowed characters
',
		Input{
		args: ['-c', 'a;b']
	})!
	assert opts.chars == ['a', 'b']
}

fn test_needs_val() {
	input := Input{}
	scanned := scan('
Options:
  -l|--line-break     append a line break to the JSON output
  -o|--output <file>  write the JSON output to a file
',
		input)!
	assert !needs_val(scanned, 'line-break')!
	assert !needs_val(scanned, 'l')!
	assert needs_val(scanned, 'output')!
	assert needs_val(scanned, 'o')!
	if _ := needs_val(scanned, 'dummy') {
		assert false
	}
}

fn test_get_val() {
	input := Input{
		args: ['-c', 'cfg']
	}
	scanned := scan('
Options:
  -l|--line-break     append a line break to the JSON output
  -c|--config <file>  set the name of the configuration file
  -o|--output <file>  write the JSON output to a file
',
		input)!
	assert get_val(scanned, 'config', '')! == 'cfg'
	assert get_val(scanned, 'c', '')! == 'cfg'
	assert get_val(scanned, 'output', 'out')! == 'out'
	assert get_val(scanned, 'o', 'out')! == 'out'
	if _ := get_val(scanned, 'l', '') {
		assert false
	}
	if _ := get_val(scanned, 'dummy', '') {
		assert false
	}
}

fn test_get_flag() {
	input := Input{
		args: ['-i']
	}
	scanned := scan('
Options:
  -l|--line-break     append a line break to the JSON output
  -i|--init           create the configuration file with default values
  -o|--output <file>  write the JSON output to a file
',
		input)!
	assert get_flag(scanned, 'init')!
	assert get_flag(scanned, 'i')!
	assert !get_flag(scanned, 'line-break')!
	assert !get_flag(scanned, 'l')!
	if _ := get_flag(scanned, 'o') {
		assert false
	}
	if _ := get_flag(scanned, 'dummy') {
		assert false
	}
}
