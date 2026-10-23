# Third-party notices

`libsymphonia`, the native library in `packages/symphonia/binaries/`, is built from the `discord_luau_symphonia` crate in this folder, which is MIT like the rest of discord-luau. It statically links the Rust crates below.

`notices.sh` generates this file from `cargo metadata` over the release dependency graph, without dev-dependencies. Run `bash notices.sh` here after changing `Cargo.toml` or `Cargo.lock`, rather than editing this file.

## Crates in the library

| Crate | Version | Licence | Used under | Repository |
|---|---|---|---|---|
| audio-codec-algorithms | 0.8.1 | 0BSD OR Apache-2.0 | 0BSD | https://github.com/karip/audio-codec-algorithms |
| audioadapter | 5.0.0 | MIT OR Apache-2.0 | MIT | https://github.com/HEnquist/audioadapter-rs |
| audioadapter-buffers | 5.2.0 | MIT OR Apache-2.0 | MIT | https://github.com/HEnquist/audioadapter-buffers-rs |
| audioadapter-sample | 5.2.0 | MIT OR Apache-2.0 | MIT | https://github.com/HEnquist/audioadapter-sample-rs |
| bitflags | 2.13.2 | MIT OR Apache-2.0 | MIT | https://github.com/bitflags/bitflags |
| bytemuck | 1.25.2 | Zlib OR Apache-2.0 OR MIT | Zlib | https://github.com/Lokathor/bytemuck |
| extended | 0.1.0 | MIT | MIT | https://github.com/depp/extended-rs |
| lazy_static | 1.5.1 | MIT OR Apache-2.0 | MIT | https://github.com/rust-lang-nursery/lazy-static.rs |
| log | 0.4.34 | MIT OR Apache-2.0 | MIT | https://github.com/rust-lang/log |
| num-complex | 0.4.6 | MIT OR Apache-2.0 | MIT | https://github.com/rust-num/num-complex |
| num-integer | 0.1.47 | MIT OR Apache-2.0 | MIT | https://github.com/rust-num/num-integer |
| num-traits | 0.2.19 | MIT OR Apache-2.0 | MIT | https://github.com/rust-num/num-traits |
| primal-check | 0.3.4 | MIT OR Apache-2.0 | MIT | https://github.com/huonw/primal |
| realfft | 3.5.0 | MIT | MIT | https://github.com/HEnquist/realfft |
| regex-lite | 0.1.9 | MIT OR Apache-2.0 | MIT | https://github.com/rust-lang/regex |
| rubato | 5.0.1 | MIT OR Apache-2.0 | MIT | https://github.com/HEnquist/rubato |
| rustfft | 6.4.1 | MIT OR Apache-2.0 | MIT | https://github.com/ejmahler/RustFFT |
| smallvec | 1.16.3 | MIT OR Apache-2.0 | MIT | https://github.com/servo/rust-smallvec |
| strength_reduce | 0.2.4 | MIT OR Apache-2.0 | MIT | http://github.com/ejmahler/strength_reduce |
| symphonia | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-bundle-flac | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-bundle-mp3 | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-codec-aac | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-codec-adpcm | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-codec-alac | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-codec-pcm | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-codec-vorbis | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-common | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-core | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-format-caf | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-format-isomp4 | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-format-mkv | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-format-ogg | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-format-riff | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| symphonia-metadata | 0.6.1 | MPL-2.0 | MPL-2.0 | https://github.com/pdeljanov/Symphonia |
| transpose | 0.2.3 | MIT OR Apache-2.0 | MIT | https://github.com/ejmahler/transpose |
| windowfunctions | 0.1.1 | MIT | MIT | https://github.com/HEnquist/windowfunctions-rs |

The library also contains the Rust standard library, compiled by the toolchain that `rust-toolchain.toml` pins. It is MIT OR Apache-2.0, and its notices are in that toolchain's `share/doc/rust/COPYRIGHT-library.html` and at https://github.com/rust-lang/rust.

## Crates used only to build it

These are procedural macros and build scripts. They run while the library compiles, and none of their code is in it.

| Crate | Version | Licence | Repository |
|---|---|---|---|
| autocfg | 1.5.1 | Apache-2.0 OR MIT | https://github.com/cuviper/autocfg |
| proc-macro2 | 1.0.107 | MIT OR Apache-2.0 | https://github.com/dtolnay/proc-macro2 |
| quote | 1.0.47 | MIT OR Apache-2.0 | https://github.com/dtolnay/quote |
| syn | 2.0.119 | MIT OR Apache-2.0 | https://github.com/dtolnay/syn |
| unicode-ident | 1.0.27 | (MIT OR Apache-2.0) AND Unicode-3.0 | https://github.com/dtolnay/unicode-ident |
| visibility | 0.1.1 | Zlib OR MIT OR Apache-2.0 | https://github.com/danielhenrymantilla/visibility.rs |

## Licence choices

- A crate offered under a licence that needs no notice in a binary (0BSD, MIT-0, Unlicense, CC0-1.0, Zlib, BSL-1.0) is used under that licence and listed above only.
- Otherwise, a crate offered under MIT, alone or as one of its choices, is used under MIT, and its MIT notice is below.
- The crates under MPL-2.0 are used unmodified, as published on crates.io. The licence text is in `licences/symphonia` at the root of this repository. Their source is on crates.io, at `https://crates.io/crates/<name>/<version>` for each crate, and in their repositories:
  - https://github.com/pdeljanov/Symphonia: symphonia 0.6.1, symphonia-bundle-flac 0.6.1, symphonia-bundle-mp3 0.6.1, symphonia-codec-aac 0.6.1, symphonia-codec-adpcm 0.6.1, symphonia-codec-alac 0.6.1, symphonia-codec-pcm 0.6.1, symphonia-codec-vorbis 0.6.1, symphonia-common 0.6.1, symphonia-core 0.6.1, symphonia-format-caf 0.6.1, symphonia-format-isomp4 0.6.1, symphonia-format-mkv 0.6.1, symphonia-format-ogg 0.6.1, symphonia-format-riff 0.6.1, symphonia-metadata 0.6.1

## Licence texts

### audioadapter 5.0.0, audioadapter-buffers 5.2.0, audioadapter-sample 5.2.0

```text
Copyright (c) 2026 Henrik Enquist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### bitflags 2.13.2, log 0.4.34, num-complex 0.4.6, num-integer 0.1.47, num-traits 0.2.19, regex-lite 0.1.9

```text
Copyright (c) 2014 The Rust Project Developers

Permission is hereby granted, free of charge, to any
person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the
Software without restriction, including without
limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice
shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

### extended 0.1.0

```text
Copyright 2022 Dietrich Epp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### lazy_static 1.5.1

```text
Permission is hereby granted, free of charge, to any
person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the
Software without restriction, including without
limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice
shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

### primal-check 0.3.4

```text
Copyright (c) 2014 Huon Wilson

Permission is hereby granted, free of charge, to any
person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the
Software without restriction, including without
limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice
shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

### realfft 3.5.0

realfft 3.5.0 ships no MIT licence file. Its Cargo.toml declares MIT, so this is the standard MIT text with the authors its Cargo.toml names.

```text
Copyright (c) HEnquist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### rubato 5.0.1

```text
Copyright (c) 2020 Henrik Enquist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### rustfft 6.4.1, strength_reduce 0.2.4

```text
Copyright (c) 2015 The RustFFT Developers

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### smallvec 1.16.3

```text
Copyright (c) 2018 The Servo Project Developers

Permission is hereby granted, free of charge, to any
person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the
Software without restriction, including without
limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice
shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

### transpose 0.2.3

```text
Copyright (c) 2022 The transpose Developers

Permission is hereby granted, free of charge, to any
person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the
Software without restriction, including without
limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice
shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

### windowfunctions 0.1.1

```text
Copyright (c) 2025 Henrik Enquist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
