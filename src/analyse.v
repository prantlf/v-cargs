module cargs

import regex
import prantlf.debug { new_debug }

const d = new_debug('cargs')

struct Opt {
mut:
	short string
	long  string
	val   string
}

fn analyse_usage(text string, anywhere bool) []Opt {
	mut re_def := regex.regex_opt('^\\s*-([^\\-])?(?:[|,]\\s*-)?(?:-([^ ]+))?(?:\\s+[<\\[]([^>\\]]+)[>\\]])?') or {
		panic(err)
	}
	mut opts := []Opt{}
	mut in_opts := false
	lines := text.split_into_lines()
	for line in lines {
		if in_opts || anywhere {
			if line.len == 0 && !anywhere {
				break
			}
			if re_def.matches_string(line) {
				cargs.d.log('option matched: "%s"', line)
				grp_opt := re_def.get_group_list()
				mut opt := Opt{}
				if grp_opt[0].start >= 0 {
					opt.short = line[grp_opt[0].start..grp_opt[0].end]
				}
				if grp_opt[1].start >= 0 {
					opt.long = line[grp_opt[1].start..grp_opt[1].end]
				}
				if grp_opt[2].start >= 0 {
					opt.val = line[grp_opt[2].start..grp_opt[2].end]
				}
				if opt.long.starts_with('no-') {
					orig_name := opt.long
					opt.long = opt.long[3..]
					cargs.d.log('option short: "%s", long: "%s" (originally "%s"), value: "%s"',
						opt.short, opt.long, orig_name, opt.val)
				} else {
					cargs.d.log('option short: "%s", long: "%s", value: "%s"', opt.short,
						opt.long, opt.val)
				}
				opts << opt
			} else {
				cargs.d.log('option not matched: "%s"', line)
			}
		} else if line.contains('Options:') {
			in_opts = true
		}
	}
	if cargs.d.is_enabled() {
		if opts.len == 0 {
			cargs.d.log_str('no options detected')
		} else {
			cargs.d.log('%d options detected', opts.len)
		}
	}
	return opts
}
