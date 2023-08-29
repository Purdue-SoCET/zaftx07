# zaftx07

Proof-of-concepts using Zig to program the AFTx07 microcontroller in a bare-metal environment.

## Setup

Install [Zig 0.11](https://ziglang.org/download/) and install it in your $PATH.

## Running

The build script assumes you have the environment variable `$AFTX07_ROOT` set to the root directory of [AFTx07](https://github.com/Purdue-SoCET/AFTx07).

Aftwards, you can build by running:
```
zig build
```

And run the binary using by running:
```
zig build run
```

## License

This repository is licensed under the Apache 2.0 license.
