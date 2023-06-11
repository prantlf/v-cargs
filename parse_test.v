module cargs

struct Two {
	line_break bool
	output     string
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
',
		Input{
		args: ['--human=woman', '--u8=1', '--u16=2', '--u32=3', '--u64=4', '--i8=5', '--i16=6',
			'--int=7', '--i64=8', '--f32=9.1', '--f64=9.2']
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
	assert args == []
}

struct Optionals {
	human ?Human
	u8    ?u8
	u16   ?u16
	u32   ?u32
	u64   ?u64
	i8    ?i8
	i16   ?i16
	int   ?int
	i64   ?i64
	f32   ?f32
	f64   ?f64
	s     ?string
	b     ?bool
}

fn test_optional_types() {
	opts, args := parse[Optionals]('
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
  -s <str>
  -b
',
		Input{
		args: ['--human=1', '--u8=1', '--u16=2', '--u32=3', '--u64=4', '--i8=5', '--i16=6', '--int=7',
			'--i64=8', '--f32=9.1', '--f64=9.2', '-s=s', '-b']
	})!
	assert opts.human? == .woman
	assert opts.u8? == 1
	assert opts.u16? == 2
	assert opts.u32? == 3
	assert opts.u64? == 4
	assert opts.i8? == 5
	assert opts.i16? == 6
	assert opts.int? == 7
	assert opts.i64? == 8
	assert opts.f32? == 9.1
	assert opts.f64? == 9.2
	assert opts.s? == 's'
	assert opts.b? == true
	assert args == []
}

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

// TODO: Use [enum] here
fn test_wrong_enum() {
	parse[Integrals]('
Options:
  --human <enum>
', Input{ args: ['--human', 'dummy'] }) or {
		assert err.msg() == '"dummy"" not in Human enum'
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
	assert opts.u8 == u8(1234)
	assert args == []
}

fn test_unknown_arg() {
	opts, args := parse[Integrals]('
Options:
  --u8 <num>
', Input{ args: ['--u16=1'] }) or {
		assert err.msg() == 'unknown argument "--u16=1"'
		return
	}
	assert false
}

fn test_invalid_arg() {
	opts, args := parse[Integrals]('
Options:
  --u8 <num>
', Input{ args: ['-u8=1'] }) or {
		assert err.msg() == 'invalid argument "-u8=1"'
		return
	}
	assert false
}

fn test_missing_arg() {
	opts, args := parse[Integrals]('
Options:
  --u8 <num>
', Input{ args: ['--u8'] }) or {
		assert err.msg() == 'missing value of "--u8"'
		return
	}
	assert false
}

fn test_extra_arg() {
	opts, args := parse[Positives]('
Options:
  -b
', Input{ args: ['-b=test'] }) or {
		assert err.msg() == 'extra value of "-b=test"'
		return
	}
	assert false
}
