module cargs

struct Empty {}

fn test_() ! {
	parse[Empty]('help', Input{ args: ['-h'] })!
	assert false
}
