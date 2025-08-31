module cargs

import os
import math
import strconv { atof64, atoi }
import v.reflection { Enum, get_type }
import prantlf.pcre { NoMatch, RegEx, pcre_compile }
import prantlf.strutil { replace_u8 }

pub struct Input {
pub mut:
	version                string
	args                   ?[]string
	disable_short_negative bool
	ignore_number_overflow bool
	options_anywhere       bool
	no_negative_options    bool
}

pub struct Scanned {
	opts  []Opt
	args  []string
	usage string
}

struct NoArg {
	Error
}

const re_opt = compile_re()

fn compile_re() &RegEx {
	return pcre_compile(r'^-(?:([^\-])|-([^ =]+))(?:\s*=(.+))?$', 0) or { panic(err) }
}

pub fn parse[T](usage string, input &Input) !(&T, []string) {
	mut cfg := &T{}
	cmds := parse_to(usage, input, mut cfg)!
	return cfg, cmds
}

pub fn parse_scanned[T](scanned &Scanned, input &Input) !(&T, []string) {
	mut cfg := &T{}
	cmds := parse_scanned_to(scanned, input, mut cfg)!
	return cfg, cmds
}

pub fn parse_to[T](usage string, input &Input, mut cfg T) ![]string {
	scanned := scan(usage, input)!
	return parse_scanned_to[T](scanned, input, mut cfg)
}

pub fn parse_scanned_to[T](scanned &Scanned, input &Input, mut cfg T) ![]string {
	d.log_str('parse command-line arguments and fill configuration')
	opts := scanned.opts
	args := scanned.args

	mut cmds := []string{}
	mut applied := []Opt{}

	l := args.len
	mut i := 0
	for i < l {
		arg := args[i]
		i++

		if arg == '--' {
			d.log_str('argument separator detected')
			break
		}

		if arg.len > 1 && arg[0] == `-` {
			match arg {
				'-V', '--version' {
					out := if input.version != '' {
						input.version
					} else {
						'unknown'
					}
					println(out)
					exit(0)
				}
				'-h', '--help' {
					println(scanned.usage)
					exit(0)
				}
				else {}
			}

			m := re_opt.exec(arg, 0) or {
				if err is NoMatch {
					return error('invalid argument "${arg}"')
				}
				return err
			}
			mut name := if start, end := m.group_bounds(1) {
				arg[start..end]
			} else if start, end := m.group_bounds(2) {
				arg[start..end]
			} else {
				return error('malformed argument "${arg}"')
			}
			d.log('option "%s" detected', name)

			if opt, flag := opts.find_opt_and_flag(name, input) {
				if opt.val != '' {
					val := if start, end := m.group_bounds(3) {
						arg[start..end]
					} else {
						if i == l {
							return error('missing value of "${arg}"')
						}
						idx := i
						i++
						args[idx]
					}
					d.log('value "%s" used', val)
					set_val(mut cfg, opt, val, input)!
				} else {
					if _, _ := m.group_bounds(3) {
						return error('extra value of "${arg}"')
					}
					if d.is_enabled() {
						d.log_str('flag "${flag}" used')
					}
					set_flag(mut cfg, opt, flag, input.no_negative_options)!
				}
				applied << opt
			} else {
				return error('unknown option "${arg}"')
			}
		} else {
			cmds << arg
		}
	}

	check_applied(cfg, applied, input.no_negative_options)!

	for i < l {
		cmds << args[i]
		i++
	}
	return cmds
}

pub fn scan(usage string, input &Input) !Scanned {
	d.log_str('scan command-line usage and fill options')
	opts := analyse_usage(usage, input.options_anywhere, input.no_negative_options)
	raw_args := input.args or { os.args[1..] }
	args := split_short_opts(opts, raw_args)!
	return Scanned{opts, args, usage}
}

pub fn needs_val(scanned &Scanned, arg_name string) !bool {
	d.log('check if command-line argument "%s" has a value', arg_name)
	opt := scanned.opts.find_opt(arg_name) or { return error('unknown option "${arg_name}"') }
	return opt.val.len != 0
}

pub fn get_val(scanned &Scanned, arg_name string, def_val string) !string {
	d.log('get value of command-line argument "%s"', arg_name)
	opt := scanned.opts.find_opt(arg_name) or { return error('unknown option "${arg_name}"') }
	if opt.val == '' {
		return error('"${arg_name}" supports no value')
	}

	if val := get_arg(scanned, opt) {
		return val
	} else {
		if err is NoArg {
			return def_val
		} else {
			return err
		}
	}
}

pub fn get_flag(scanned &Scanned, arg_name string) !bool {
	d.log('get command-line flag "%s"', arg_name)
	opt := scanned.opts.find_opt(arg_name) or { return error('unknown option "${arg_name}"') }
	if opt.val.len != 0 {
		return error('"${arg_name}" requires a value')
	}

	if _ := get_arg(scanned, opt) {
		return true
	} else {
		if err is NoArg {
			return false
		} else {
			return err
		}
	}
}

fn get_arg(scanned &Scanned, opt &Opt) !string {
	args := scanned.args

	l := args.len
	mut i := 0
	for i < l {
		arg := args[i]
		i++

		if arg == '--' {
			d.log_str('argument separator detected')
			break
		}

		if arg.len > 1 && arg[0] == `-` {
			m := re_opt.exec(arg, 0) or {
				if err is NoMatch {
					return error('invalid argument "${arg}"')
				}
				return err
			}
			mut name := if start, end := m.group_bounds(1) {
				arg[start..end]
			} else if start, end := m.group_bounds(2) {
				arg[start..end]
			} else {
				return error('malformed argument "${arg}"')
			}
			d.log('option "%s" detected', name)

			if opt.has_name(name) {
				if opt.val.len != 0 {
					val := if start, end := m.group_bounds(3) {
						arg[start..end]
					} else {
						if i == l {
							return error('missing value of "${arg}"')
						}
						idx := i
						i++
						args[idx]
					}
					d.log('value "%s" found', val)
					return val
				} else {
					if _, _ := m.group_bounds(3) {
						return error('unexpected value of "${arg}"')
					} else {
						d.log_str('flag found')
						return ''
					}
				}
			}
		}
	}

	typ := if opt.val.len != 0 {
		'value'
	} else {
		'flag'
	}
	d.log('%s not found', typ)
	return NoArg{}
}

fn split_short_opts(opts []Opt, raw_args []string) ![]string {
	re_cond := pcre_compile(r'^-\w+$', 0)!
	mut args := []string{}

	l := raw_args.len
	mut i := 0
	for i < l {
		arg := raw_args[i]
		if arg == '--' {
			break
		}

		i++
		if arg.len > 1 && arg[0] == `-` && arg[1] != `-` {
			if re_cond.matches(arg, 0)! {
				d.log('splitting "%s" to separate options', arg)
				for j := 1; j < arg.len; j++ {
					args << '-${rune(arg[j])}'
				}
				continue
			} else {
				d.log('keeping "%s" as single option', arg)
			}
		}
		args << arg
	}

	for i < l {
		args << raw_args[i]
		i++
	}
	return args
}

fn (opts []Opt) find_opt_and_flag(arg string, input Input) ?(Opt, bool) {
	mut flag := true
	name := if !input.no_negative_options && arg.starts_with('no-') {
		flag = false
		arg[3..]
	} else {
		arg
	}

	for opt in opts {
		if name.len == 1 {
			if name == opt.short {
				flag = if !input.disable_short_negative && !input.no_negative_options
					&& name[0] < u8(`a`) {
					false
				} else {
					true
				}
				return opt, flag
			} else if !input.disable_short_negative && !input.no_negative_options
				&& opt.short.len == 1 && name[0] & ~32 == opt.short[0] & ~32 {
				flag = if name[0] < u8(`a`) {
					false
				} else {
					true
				}
				return opt, flag
			}
		} else {
			if name == opt.long {
				return opt, flag
			}
		}
	}
	return none
}

fn (opts []Opt) find_opt(name string) ?Opt {
	for opt in opts {
		if name == opt.short || name == opt.long {
			return opt
		}
	}
	return none
}

fn (opt &Opt) has_name(name string) bool {
	return if name.len == 1 {
		name == opt.short
	} else {
		name == opt.long
	}
}

fn check_applied[T](cfg T, applied []Opt, no_negative bool) ! {
	mut valid := []Opt{}

	$for field in T.fields {
		mut arg_name := field.name
		mut required := false
		for attr in field.attrs {
			if attr.starts_with('arg: ') {
				arg_name = attr[5..]
			} else if attr == 'required' {
				required = true
			}
		}
		if d.is_enabled() {
			not_required := if required {
				''
			} else {
				'not '
			}
			d.log('checking field "%s", a %srequired argument "%s"', field.name, not_required,
				arg_name)
		}

		mut found := false
		for opt in applied {
			name := opt.field_name()
			if name == field.name || opt.long == arg_name {
				valid << opt
				found = true
				break
			}
		}

		if required && !found {
			return error('missing required ${arg_name}')
		}
	}
	if valid.len != applied.len {
		for opt in applied {
			if opt !in valid {
				return error('inappliccable argument ${opt.name()}')
			}
		}
	}
}

fn set_val[T](mut cfg T, opt Opt, val string, input Input) ! {
	name := opt.field_name()
	$for field in T.fields {
		mut arg_name := field.name
		mut nooverflow := false
		mut sep := ''
		for attr in field.attrs {
			if attr.starts_with('arg: ') {
				arg_name = attr[5..]
			} else if attr.starts_with('split: ') {
				sep = attr[7..]
			} else if attr == 'split' {
				sep = ','
			} else if attr == 'nooverflow' {
				nooverflow = true
			}
		}

		if name == field.name || opt.long == arg_name {
			ino := nooverflow || input.ignore_number_overflow

			if d.is_enabled() {
				if d.is_enabled() {
					split := if sep != '' {
						'split with "${sep}"'
					} else {
						'no splitting'
					}
					overflow := if nooverflow {
						'ignored'
					} else {
						'checked'
					}
					d.log_str('setting value field "${field.name}" using argument "${arg_name}", ${split}, overflow ${overflow}')
				}
			}

			$if field.is_enum {
				orig_val := cfg.$(field.name)
				cfg.$(field.name) = get_enum(val, orig_val)!
			} $else $if field.typ is int {
				cfg.$(field.name) = get_int[int](val, ino)!
			} $else $if field.typ is ?int {
				cfg.$(field.name) = get_int[int](val, ino)!
			} $else $if field.typ is u8 {
				cfg.$(field.name) = get_int[u8](val, ino)!
			} $else $if field.typ is ?u8 {
				cfg.$(field.name) = get_int[u8](val, ino)!
			} $else $if field.typ is u16 {
				cfg.$(field.name) = get_int[u16](val, ino)!
			} $else $if field.typ is ?u16 {
				cfg.$(field.name) = get_int[u16](val, ino)!
			} $else $if field.typ is u32 {
				cfg.$(field.name) = get_int[u32](val, ino)!
			} $else $if field.typ is ?u32 {
				cfg.$(field.name) = get_int[u32](val, ino)!
			} $else $if field.typ is u64 {
				cfg.$(field.name) = get_int[u64](val, ino)!
			} $else $if field.typ is ?u64 {
				cfg.$(field.name) = get_int[u64](val, ino)!
			} $else $if field.typ is i8 {
				cfg.$(field.name) = get_int[i8](val, ino)!
			} $else $if field.typ is ?i8 {
				cfg.$(field.name) = get_int[i8](val, ino)!
			} $else $if field.typ is i16 {
				cfg.$(field.name) = get_int[i16](val, ino)!
			} $else $if field.typ is ?i16 {
				cfg.$(field.name) = get_int[i16](val, ino)!
			} $else $if field.typ is i64 {
				cfg.$(field.name) = get_int[i64](val, ino)!
			} $else $if field.typ is ?i64 {
				cfg.$(field.name) = get_int[i64](val, ino)!
			} $else $if field.typ is f32 {
				cfg.$(field.name) = get_float[f32](val, ino)!
			} $else $if field.typ is ?f32 {
				cfg.$(field.name) = get_float[f32](val, ino)!
			} $else $if field.typ is f64 {
				cfg.$(field.name) = get_float[f64](val, ino)!
			} $else $if field.typ is ?f64 {
				cfg.$(field.name) = get_float[f64](val, ino)!
			} $else $if field.typ is rune {
				cfg.$(field.name) = get_char[rune](val)!
			} $else $if field.typ is ?rune {
				cfg.$(field.name) = get_char[rune](val)!
			} $else $if field.typ is char {
				cfg.$(field.name) = get_char[char](val)!
			} $else $if field.typ is ?char {
				cfg.$(field.name) = get_char[char](val)!
			} $else $if field.typ is string {
				cfg.$(field.name) = val
			} $else $if field.typ is ?string {
				cfg.$(field.name) = val
			} $else $if field.is_array {
				mut arr := cfg.$(field.name)
				cfg.$(field.name) = add_val(mut arr, val, sep, ino)!
			} $else {
				return error('${opt.name()} incompatible with ${type_name(field.typ)} of ${type_name(T.idx)}.${field.name}')
			}
		}
	}
}

fn add_val[T](mut arr []T, val string, sep string, ignore_overflow bool) ![]T {
	if sep != '' {
		vals := val.split(sep)
		for item in vals {
			arr << convert_val[T](item, ignore_overflow)!
		}
	} else {
		arr << convert_val[T](val, ignore_overflow)!
	}
	return arr
}

fn convert_val[T](val string, ignore_overflow bool) !T {
	$if T is int {
		return get_int[int](val, ignore_overflow)!
	} $else $if T is u8 {
		return get_int[u8](val, ignore_overflow)!
	} $else $if T is u16 {
		return get_int[u16](val, ignore_overflow)!
	} $else $if T is u32 {
		return get_int[u32](val, ignore_overflow)!
	} $else $if T is u64 {
		return get_int[u64](val, ignore_overflow)!
	} $else $if T is i8 {
		return get_int[i8](val, ignore_overflow)!
	} $else $if T is i16 {
		return get_int[i16](val, ignore_overflow)!
	} $else $if T is i64 {
		return get_int[i64](val, ignore_overflow)!
	} $else $if T is f32 {
		return get_float[f32](val, ignore_overflow)!
	} $else $if T is f64 {
		return get_float[f64](val, ignore_overflow)!
	} $else $if T is rune {
		return get_char[rune](val)!
	} $else $if T is char {
		return get_char[char](val)!
	} $else $if T is string {
		return val
	} $else $if T.is_enum {
		orig_val := T{}
		return get_enum(val, orig_val)!
	} $else {
		return error('${val} cannot be converted to ${type_name(T.idx)}')
	}
	return error('unreachable code in convert_val')
}

fn set_flag[T](mut cfg T, opt Opt, flag bool, no_negative bool) ! {
	name := opt.field_name()
	$for field in T.fields {
		mut arg_name := field.name
		for attr in field.attrs {
			if attr.starts_with('arg: ') {
				arg_name = attr[5..]
			}
		}

		if name == field.name || opt.long == arg_name {
			if d.is_enabled() {
				d.log_str('setting flag "${name}" using argument "${arg_name}" to "${flag}"')
			}
			$if field.typ is bool {
				cfg.$(field.name) = flag
			} $else $if field.typ is ?bool {
				cfg.$(field.name) = flag
			} $else {
				return error('${opt.name()} incompatible with flag ${type_name(T.idx)}.${field.name}')
			}
		}
	}
}

fn get_enum[T](val string, orig_val T) !T {
	if num := atoi(val) {
		return unsafe { T(num) }
	} else {
		enums := enum_vals(T.idx)!
		idx := enums.index(val)
		if idx >= 0 {
			return unsafe { T(idx) }
		} else {
			return error('"${val}" not in ${type_name(T.idx)} enum')
		}
	}
}

fn enum_vals(idx int) ![]string {
	return if typ := get_type(idx) {
		if typ.sym.info is Enum {
			typ.sym.info.vals
		} else {
			error('${typ.name} not an enum')
		}
	} else {
		error('unknown enum')
	}
}

fn get_int[T](val string, ignore_overflow bool) !T {
	if num := atoi(val) {
		i := T(num)
		if num != i {
			if ignore_overflow {
				if d.is_enabled() {
					d.log_str('forcing conversion of "${num}" to "${i}')
				}
			} else {
				return error('unable to convert "${num}" to ${T.name}')
			}
		}
		return i
	}
	return error('"${val}" is not an integer')
}

fn get_float[T](val string, ignore_overflow bool) !T {
	if num := atof64(val) {
		f := T(num)
		if num - f64(f) > math.smallest_non_zero_f64 {
			if ignore_overflow {
				if d.is_enabled() {
					d.log_str('forcing conversion of "${num}" to "${f}')
				}
			} else {
				return error('unable to convert "${num}" to ${T.name}')
			}
		}
		return f
	}
	return error('"${val}" is not a number')
}

fn get_char[T](val string) !T {
	if val.len != 1 {
		return error('unable to convert "${val}" to a single character')
	}
	return val[0]
}

fn (opt Opt) field_name() string {
	name := if opt.long != '' {
		if opt.long.contains_u8(`-`) {
			replace_u8(opt.long, `-`, `_`)
		} else {
			opt.long
		}
	} else {
		opt.short
	}

	return if has_upper(name) {
		name.to_lower()
	} else {
		name
	}
}

fn has_upper(s string) bool {
	for i := 0; i < s.len; {
		ch := s[i]
		rune_len := utf8_char_len(ch)
		if rune_len == 1 {
			if ch >= `A` && ch <= `Z` {
				return true
			}
		}
		i += rune_len
	}
	return false
}

fn (opt Opt) name() string {
	return if opt.short != '' {
		if opt.long != '' {
			'${opt.short}|${opt.long}'
		} else {
			opt.short
		}
	} else {
		opt.long
	}
}

fn type_name(idx int) string {
	return if typ := get_type(idx) {
		typ.name
	} else {
		'unknown'
	}
}
