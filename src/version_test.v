module cargs

struct Empty {}

fn test_() ! {
	parse[Empty]('', Input{ version: '0.0.1', args: ['-V'] })!
	assert false
}
