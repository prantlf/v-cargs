# Command-line Arguments

Parses command-line arguments to statically typed options or a string map with the help of usage description.

* Legible configuration inferred from the usage instructions text.
* Full control over the usage text.
* Checks for unknown and required options, invalid value types and arithmetic overflow.
* Compatibility with the [getopt and getopt_long] standards.

## Synopsis

Specify usage description and version of the command-line tool. Declare a structure with all command-line options. Import the command-line parser and parse the options and arguments:

```go
import os
import prantlf.cargs { parse, Input }

// Describe usage of the command-line tool.
usage := 'Converts YAML input to JSON output.

Usage: yaml2json [options] [<yaml-file>]

  <yaml-file>         read the YAML input from a file

Options:
  -o|--output <file>   write the JSON output to a file
  -i|--indent <count>  write the JSON output to a file
  -p|--pretty          prints the JSON output with line breaks and indented
  -V|--version         prints the version of the executable and exits
  -h|--help            prints the usage information and exits

If no input file is specified, it will be read from standard input.

Examples:
  $ yaml2json config.yaml -o config.json -p
  $ cat config.yaml | yaml2json > config.json'

// Declare a structure with all command-line options.
struct Opts {
  output string
  indent int
  pretty bool
}

// Parse command-line options and arguments.
opts, args := parse[Opts](usage, Input{ version: '0.0.1' })!
if args.len > 0 {
  // Process file names from the args array.
} else {
  // Read from the standard input.
}
```

## Installation

You can install this package either from [VPM] or from GitHub:

```txt
v install prantlf.cargs
v install --git https://github.com/prantlf/v-cargs
```

## API

The following functions and types are exported:

### parse[T](usage string, input Input) !(T, []string)

Parses the command line, separating options and other arguments. Options will be set to the statically-typed structure and other arguments returned as an array of strings. The list of options will be inferred from the usage description.

```go
usage := '...

Options:
  -o|--output <file>  write the JSON output to a file
  -p|--pretty         prints the JSON output with line breaks and indented

...'

struct Opts {
  output string
  pretty bool
}

opts, args := parse[Opts](usage, Input{ version: '0.0.1' })!
```

### parse_to[T](usage string, input Input, mut opts T) ![]string

Parses the command line, separating options and other arguments, while setting the field values in an already created object. It can be used to override options initially read from configuration file from the command-line, for example. See [prantlf.config] for more information.

### Usage Instructions

The `usage` parameter is the formatted text to be presented as usage instructions. It's supposed to contain a line Starting with `Options:`, which is followed by links listing the options:

    Options:
      -o|--output <file>  write the JSON output to a file
      -p|--pretty         prints the JSON output with line breaks and indented

An option-line can contain a short (single-letter) option, a long option or both. The option can be either a boolean flag or an variable with a value.

    -p             a boolean flag, short variant only
    --line-breaks  a boolean flag, long variant only
    -v|--verbose   a boolean flag, both short and long variants
    -o <file>      a variable with a value

Short and long option variants can be delimited either by `|` or by `,`, which can be followed by a space. A value of a variable can be enclose either in `<` and `>`, or in `[` and `]`.

If a negative option is entered, the field in the options structure has to be still positive - without the `no_` prefix. This is usually used to declare flags, which are enabled by default and can be disabled by the negative option:

    --no-line-breaks  a boolean flag, long variant only

### Options

Two command-line options will be recognised and processed by the `parse` function itself:

* `-V|--version` - prints the version of the executable and exits
* `-h|--help` - prints the usage information and exits

Short (single-letter) options can be condensed together. For example, instead of `-l -p`, you can write `-lp` on the command line.

Names of fields in the options structure are inferred from the command-line option names with several changes to ensure valid V syntax:

* The long variant of an option will be mapped to its field name. The short variant will be used only if the long variant is missing.
* Upper-case letters will converted to lower-case.
* Dashes (`-`) in an option name will be converted to underscores (`_`) in its field name.

If you write a short (single-letter) option for a boolean flag in upper-case, it will set the value `false` to the boolean field instead of `true`. If you write a long option for a boolean flag, you can negate its value by prefixing the option with `no-`:

    -P --no-line-breaks

Enum field types can be filled either by an integer or by the (string) name of the enum value.

Assigning boolean flags or variable values to option fields may fail. For example:

* If there's no field with the long name of the option.
* If the field type is boolean but the option isn't a boolean flag or vice versa.
* If the field type isn't a string and the field value cannot be converted from the string value.
* If the numeric field type is too small to accommodate the number converted from the string value.

An option with a value can be entered multiple times. All values can be stored in an array, for example:

```go
usage := '...

Options:
  -n, --numbers <number>  a list of numbers to use

...'

struct Opts {
  numbers []int
}
```

### Other Arguments

An option starts with `-` or `--` and has to consist of at least one more letter. A single dash (`-`) isn't an option, but another argument. An argument not starting with a dash (`-`) is a plain argument and not an option.

If you want to handle some argument as other arguments and not as options, put two dashes (`--`) on the command line and appends such arguments behind it. The two dashes (`--`) will be ignored. If you need the two dashes (`--`) as another argument, append them once more after the first ones to the command line.

### Input Fields

The following input fields are available:

| Field                    | Type        | Default     | Description                                                  |
|:-------------------------|:------------|:------------|:-------------------------------------------------------------|
| `version`                | `string`    | `'unknown'` | version of the tool to print if `-V|--version` is requested  |
| `args`                   | `?[]string` | `none`      | raw command-line arguments, defaults to `os.args[1..]`       |
| `disable_short_negative` | `bool`      | `false`     | disables handling uppercase letters as negated options       |
| `ignore_number_overflow` | `bool`      | `false`     | ignores an overflow when converting numbers to option fields |
| `options_anywhere`       | `bool`      | `false`     | do not look for options only after the line with `Options:`  |

### Advanced

If the transformation of options name to field name [described above](#options) is not enough, the argument name can be assigned to a specific field by the attribute `arg`. For example, set the command-line argument `type` to a field `typ`:

```go
usage := '...

Options:
  -t|--type <type>  file type (text or binary)

...'

struct Opts {
  typ string [arg: @type]
}
```

If you don't want to disable the checks for arithmetic overflow globally, but only for one field, it's possible by the attribute `nooverflow`. For example, set the command-line argument `type` to a field `typ`:

```go
usage := '...

Options:
  -r|--random <number>  the value to initialize random number generator with

...'

struct Opts {
  random i16 [nooverflow]
}
```

If you require an option to be always entered, it's possible by the attribute `required`. For example:

```go
usage := '...

Options:
  -f|--file <name>  the name of the output file

...'

struct Opts {
  file string [required]
}
```

If you need to supply multiple values for an option and you want to use more condensed syntax then repeating the option on the command line, you can supply all values only once, if there's a separator, which otherwise cannot be present within a value. For example, you can supply two comma-delimited integers as `-n 1,2` by the attribute `split`:

```go
usage := '...

Options:
  -n, --numbers <number>  a list of numbers to use

...'

struct Opts {
  numbers []int [split]
}
```

The default separator is `,` (comma). If you need a different one, you can choose the separator by the same attribute. For example, you can supply two semicolon-delimited characters as `-c a;b` by the attribute `split`:

```go
usage := '...

Options:
  -c, --chars <char>  allowed characters

...'

struct Opts {
  numbers []rune [split: ';']
}
```

## TODO

This is a work in progress.

* Add a string map as the parsing target.

[VPM]: https://vpm.vlang.io/packages/prantlf.cargs
[getopt and getopt_long]: https://en.wikipedia.org/wiki/Getopt
[prantlf.config]: https://github.com/prantlf/v-config
