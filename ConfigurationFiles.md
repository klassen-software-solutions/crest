# Crest Configuration Files

## Description

The operation of this program can be modified by the existance of configuration files. Specifically,
you can place a `.crestconfig.json` file in your home directory, or in the directory from which
you are running `crest`. (Say, for example, the project directory where you are developing your
web service.) In this way you can customize the program operation for the needs of a given 
project.

A configuration file in the local directory will override any settings found in the global file (the one
in your home directory), and many of the settings can also be overridden by command line
options.

The configuration files are JSON files consisting of a single dictionary where each key is
one of the following, and the contents are as described.

E.g.

{
"Private": true,
"URLPrefix": "http://mytestserver.local:8080/api/v2"
}

## Settings Deetails

### AutoPopulateRequestHeaders

By default `crest` adds a number of request headers automatically. They can be overridden
by manually specifying headers of the same name, but you can turn off the auto headers
completely by setting this to `false`. In that case only the headers that are absolutely required
for the HTTP protocol will be added.

e.g. `"AutoPopulateRequestHeaders": false` (Default is `true`)

This is turned off if `--no-auto-headers` is specified on the command line.

### AutoRecognizeRequestContent

By default `crest` will attempt to identify the contents of the standard input and set the
`Content-Type` header appropriately. However, there are the following limitations:

1. Presently only JSON and XML data are recognized.
2. If the data is too large (by default over 2048 bytes), then it will be sent as chunked data
to avoid keeping the entire contents in memory at once. In this case it will not be 
recognized.

By turning this off no `Content-Type` header will be added automatically, and you will
need to add it manually via the command line options.

E.g. `"AutoRecognizeRequestContent": false` (Default is `true`)

This is turned off if `--no-auto-headers` is specified on the command line.

### PrettyPrint

Be default `crest` will pretty print content that it recognizes. This will currently include content
of type `application/json` , `application/xml` or `text/xml`. In order for the pretty print to work the
following must be true:

- The `Content-Type` header must be specified and include a supported type,
- The actual content must match the supported type, and
- The actual content must come in one sections. That limits it to a size of 2048 bytes.

Pretty printing will also ensure we end with a newline, so even non pretty-printable types
will be more readable.

You can turn off the pretty printing by specifying `--pretty-print=false` on the command
line or setting `"PrettyPrint": false` in the configuration file.

Note that if the content does not match the `Content-Type` header, the original content
will still be printed.

### Private

By default `crest` adds a `User-Agent` key that includes information about the machine you
are running on. For example: `Crest/1.0.0 (macOS; Version 11.2.3 (Build 20D91); x86_64)`.
If you set `Private` to `true`, then the details will be left out and the `User-Agent` will simply
be reported as `Crest`. (You can override this as well by specifying your own `User_Agent` header
either in the configuration files or via the command line.)

E.g. `"Private": true` (Default is `false`)

### RequestHeaders

This configuration items allows you to set a dictionary of request headers to be aded to each
request. This is likely most useful for the local configuration file where you may have a
common set of headers required by the web service you are developing.

Any headers listed here will override any auto populated or auto recognized headers of the
same name.

Example:

"RequestHeaders": {
"My-Custom-Header": "some value",
"Content-Type": "text/html"
}

This is turned off if  `--no-auto-headers` is specified on the command line. In addition, any headers
added via the command line will override any headers listed here of the same name.

### ShowResponseHeaders

By default we don't show the response headers unless `--show-response-headers=true` has been specified 
on the command line. This configuration item can be used to change that and turn them on all the time.

E.g. `"ShowResponseHeaders": true` (Default is `false`)

### URLPrefix

This can be used to set a prefix that will automatically be prepended to the URL given on the command
line. This is likely to be most useful in the local `.crestconfig.json` where you can set it to be
the common part of the web service you are testing. This can save you a lot of typing.

Note that the `URLPrefix` will be ignored if the command line URL begins with `http:` or
`https:`.

E.g. `"URLPrefix": "http://mytestserver.local:8080/api/v2"` (Default is empty)

In this example, if you run the command `crest /contract/id871` it will actually perform 
a `GET` to the URL `http://mytestserver.local:8080/api/v2/contract/id871`.

