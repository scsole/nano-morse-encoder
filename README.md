# Tang Nano - Morse Encoder

Generate a single bit Morse code output using a UART interface. When a complete
8-bit digit is received, the digit is encoded as Morse code and transmitted.

The resources linked at the bottom of this page contain great information on
setting up the UART connection. I needed to reflash the CH3552T chip on my
board as described in the first link.

## Synthesis

This project can be synthesized using `GowinSynthesis` in the Gowin IDE (Under
`Project` > `Configuration` > `Synthesize` > `General`). Other tools may
work. Also in the configuration menu, `DONE` and `RECONFIG_N` must be
configured as Dual-Purpose Pins to use the UART interface.

## Usage

Once flashed (e.g. with the Gowin programmer or
[openFPGALoader](https://github.com/trabucayre/openFPGALoader)), you can send
characters via the Nano's second RS232 serial port. On Linux, that would
likely be `/dev/ttyUSB1` (`ttyUSB0` is used for programming).

The program will store all received characters in a small FIFO buffer. When a
character starts being transmitted (the onboard LED should flash the Morse
code sequence), the character is also transmitted back to the connected
device via the serial port.

To send data to you device, you can use any program capable of serial
communication.

### Screen

```
$ screen /dev/ttyUSB1 9600
```

To exit `screen`, use `ctrl` + `A`, then `\`,  followed by `y` to confirm.

### Platform IO monitor (via CLI)

```
$ pio device monitor -p /dev/ttyUSB1 -b 9600
```

## Resources

- [UART communication between Tang Nano FPGA and PC](https://qiita.com/ciniml/items/05ac7fd2515ceed3f88d)
- [Tang Nano Exploration](https://github.com/scsole/tang-nano-exploration) - My slowly evolving documentation on getting started with the Tang Nano
- [Another Wishbone Controlled UART](https://github.com/ZipCPU/wbuart32) - UART modules used in this project
