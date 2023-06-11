module cargs

import os
import math
import regex
import strconv
import v.reflection

pub struct Input {
pub mut:
	version                string
	args                   ?[]string
	disable_short_negative bool
	ignore_number_overflow bool
}

pub fn parse[T](usage string, input Input) !(T, []string) {
	mut re_opt := regex.regex_opt('^-([^\\-])|(?:-([^ =]+))(?:\\s*=(.+))?$') or { panic(err) }
	opts := analyse_usage(usage)
	args := input.args or { os.args[1..] }

	mut cfg := T{}
	mut cmds := []string{}
	mut i := 0
	l := args.len
	for i < l {
		arg := args[i]
		i++
		if arg == '--' {
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
			start, _ := re_opt.match_string(arg)
			if start < 0 {
				return error('invalid argument "${arg}"')
			}
			grp_opt := re_opt.get_group_list()
			name := if grp_opt[0].start >= 0 {
				arg[grp_opt[0].start..grp_opt[0].end]
			} else if grp_opt[1].start >= 0 {
				arg[grp_opt[1].start..grp_opt[1].end]
			} else {
				return error('malformed argument "${arg}"')
			}
			if opt, flag := opts.find(name, input) {
				if opt.val.len > 0 {
					val := if grp_opt[2].start >= 0 {
						arg[grp_opt[2].start..grp_opt[2].end]
					} else {
						if i == l {
							return error('missing value of "${arg}"')
						}
						idx := i
						i++
						args[idx]
					}
					set_val(mut cfg, opt, val, input)!
				} else {
					if grp_opt[2].start >= 0 {
						return error('extra value of "${arg}"')
					}
					set_flag(mut cfg, opt, flag)!
				}
			} else {
				return error('unknown argument "${arg}"')
			}
		} else {
			cmds << arg
		}
	}
	for i < l {
		cmds << args[i]
		i++
	}
	return cfg, cmds
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

fn set_val[T](mut cfg T, opt Opt, val string, input Input) ! {
	name := opt.field_name()
	ino := input.ignore_number_overflow
	$for field in T.fields {
		if field.name == name {
			$if field.is_enum {
				cfg.$(field.name) = get_enum(val, field.typ)!
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
			} $else $if field.typ is string || field.typ is ?string {
				cfg.$(field.name) = val
			} $else $if field.is_array {
				cfg.$(field.name) = unmarshal_array(typ.$(field.name), val, opts)!
			} $else {
				return error('${opt.name()} uncompatible with ${type_name(field.typ)} of ${type_name(T.idx)}.${field.name}')
			}
		}
	}
}

fn set_flag[T](mut cfg T, opt Opt, flag bool) ! {
	name := opt.field_name()
	$for field in T.fields {
		if field.name == name {
			$if field.typ is bool {
				cfg.$(field.name) = flag
			} $else $if field.typ is ?bool {
				cfg.$(field.name) = flag
			} $else {
				return error('${opt.name()} uncompatible with flag ${type_name(T.idx)}.${field.name}')
			}
		}
	}
}

fn get_enum(val string, typ int) !int {
	if num := strconv.atoi(val) {
		return num
	} else {
		enums := enum_vals(typ)!
		idx := enums.index(val)
		if idx >= 0 {
			return idx
		} else {
			return error('"${val}"" not in ${type_name(typ)} enum')
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
		if !ignore_overflow && num != i {
			return error('unable to convert "${num}" to ${T.name}')
		}
		return i
	}
	return error('"${val}" is not an integer')
}

fn get_float[T](val string, ignore_overflow bool) !T {
	if num := strconv.atof64(val) {
		f := T(num)
		if !ignore_overflow && num - f > math.smallest_non_zero_f64 {
			return error('unable to convert "${num}" to ${T.name}')
		}
		return f
	}
	return error('"${val}" is not a number')
}

fn (opt Opt) field_name() string {
	name := if opt.long.len > 0 {
		if opt.long.contains_u8(`-`) {
			opt.long.replace_char(`-`, `_`, 1)
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
