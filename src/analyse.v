module cargs

import regex

struct Opt {
mut:
	short string
	long  string
	val   string
}

fn analyse_usage(text string) []Opt {
	mut re_opt := regex.regex_opt('^\\s*-([^\\-])?(?:[|,]\\s*-)?(?:-([^ ]+))?(?:\\s+[<\\[]([^>\\]]+)[>\\]])?') or {
		panic(err)
	}
	mut opts := []Opt{}
	mut in_opts := false
	lines := text.split_into_lines()
	for line in lines {
		if in_opts {
			if line.len == 0 {
				break
			}
			if re_opt.matches_string(line) {
				grp_opt := re_opt.get_group_list()
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
				opts << opt
			}
		} else if line.contains('Options:') {
			in_opts = true
		}
	}
	return opts
}
