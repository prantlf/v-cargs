module cargs

import os
import math
import strconv
import v.reflection
import prantlf.pcre { NoMatch, pcre_compile }
import prantlf.strutil { replace_u8 }

pub struct Input {
pub mut:
	version                string
	args                   ?[]string
	disable_short_negative bool
	ignore_number_overflow bool
}

pub fn parse[T](usage string, input &Input) !(&T, []string) {
	d.log_str('parse command-line usage and create options')
	mut cfg := &T{}
	cmds := parse_to(usage, input, mut cfg)!
	return cfg, cmds
}

pub fn parse_to[T](usage string, input &Input, mut cfg T) ![]string {
	d.log_str('parse command-line usage and fill options')
	re_opt := pcre_compile(r'^-(?:([^\-])|-([^ =]+))(?:\s*=(.+))?$', 0)!

	opts := analyse_usage(usage)
	raw_args := input.args or { os.args[1..] }
	args := split_short_opts(opts, raw_args)!

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
					out := if input.version.len > 0 {
						input.version
					} else {
						'unknown'
					}
					println(out)
					exit(0)
				}
				'-h', '--help' {
					println(usage)
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

			if opt, flag := opts.find(name, input) {
				if opt.val.len > 0 {
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
					set_flag(mut cfg, opt, flag)!
				}
				applied << opt
			} else {
				return error('unknown option "${arg}"')
			}
		} else {
			cmds << arg
		}
	}

	check_applied(cfg, applied)!

	for i < l {
		cmds << args[i]
		i++
	}
	return cmds
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

fn (opts []Opt) find(arg string, input Input) ?(Opt, bool) {
	mut flag := true
	name := if arg.starts_with('no-') {
		flag = false
		arg[3..]
	} else {
		arg
	}

	for opt in opts {
		if name.len == 1 {
			if name == opt.short {
				return opt, true
			} else if !input.disable_short_negative && name[0] < u8(`a`)
				&& name[0] == opt.short[0] & ~32 {
				return opt, false
			}
		} else {
			if name == opt.long {
				return opt, flag
			}
		}
	}
	return none
}

fn check_applied[T](cfg T, applied []Opt) ! {
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
			if name == arg_name {
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

		if name == arg_name {
			ino := nooverflow || input.ignore_number_overflow

			if d.is_enabled() {
				if d.is_enabled() {
					split := if sep.len > 0 {
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
			} $else $if field.typ is int || field.typ is ?int {
				cfg.$(field.name) = get_int[int](val, ino)!
			} $else $if field.typ is u8 || field.typ is ?u8 {
				cfg.$(field.name) = get_int[u8](val, ino)!
			} $else $if field.typ is u16 || field.typ is ?u16 {
				cfg.$(field.name) = get_int[u16](val, ino)!
			} $else $if field.typ is u32 || field.typ is ?u32 {
				cfg.$(field.name) = get_int[u32](val, ino)!
			} $else $if field.typ is u64 || field.typ is ?u64 {
				cfg.$(field.name) = get_int[u64](val, ino)!
			} $else $if field.typ is i8 || field.typ is ?i8 {
				cfg.$(field.name) = get_int[i8](val, ino)!
			} $else $if field.typ is i16 || field.typ is ?i16 {
				cfg.$(field.name) = get_int[i16](val, ino)!
			} $else $if field.typ is i64 || field.typ is ?i64 {
				cfg.$(field.name) = get_int[i64](val, ino)!
			} $else $if field.typ is f32 || field.typ is ?f32 {
				cfg.$(field.name) = get_float[f32](val, ino)!
			} $else $if field.typ is f64 || field.typ is ?f64 {
				cfg.$(field.name) = get_float[f64](val, ino)!
				// } $else $if field.typ is rune || field.typ is ?rune {
				// 	cfg.$(field.name) = get_char[rune](val)!
				// } $else $if field.typ is char || field.typ is ?char {
				// 	cfg.$(field.name) = get_char[char](val)!
			} $else $if field.typ is string || field.typ is ?string {
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
	if sep.len > 0 {
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
		// } $else $if T is rune {
		// 	return get_char[rune](val)!
		// } $else $if T is char {
		// 	return get_char[char](val)!
	} $else $if T is string {
		return val
	} $else $if T.is_enum {
		orig_val := cfg.$(field.name)
		return get_enum(val, orig_val)!
	} $else {
		return error('${val} cannot be converted to ${type_name(T.idx)}')
	}
}

fn set_flag[T](mut cfg T, opt Opt, flag bool) ! {
	name := opt.field_name()
	$for field in T.fields {
		mut arg_name := field.name
		for attr in field.attrs {
			if attr.starts_with('arg: ') {
				arg_name = attr[5..]
			}
		}

		if name == arg_name {
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
	if num := strconv.atoi(val) {
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
	return if typ := reflection.get_type(idx) {
		if typ.sym.info is reflection.Enum {
			typ.sym.info.vals
		} else {
			error('${typ.name} not an enum')
		}
	} else {
		error('unknown enum')
	}
}

fn get_int[T](val string, ignore_overflow bool) !T {
	if num := strconv.atoi(val) {
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
	if num := strconv.atof64(val) {
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

// fn get_char[T](val string) !T {
// 	if val.len != 1 {
// 		return error('unable to convert "${val}" to a single character')
// 	}
// 	return val[0]
// }

fn (opt Opt) field_name() string {
	name := if opt.long.len > 0 {
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
	return if opt.short.len > 0 {
		if opt.long.len > 0 {
			'${opt.short}|${opt.long}'
		} else {
			opt.short
		}
	} else {
		opt.long
	}
}

fn type_name(idx int) string {
	return if typ := reflection.get_type(idx) {
		typ.name
	} else {
		'unknown'
	}
}
