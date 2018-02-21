# DSITx
FPGA implementation of DSITx (single lane) used in conjunction with ipod nano 7th gen display

This is a generic (behavioral) code for MIPI DSI Tx. Can drive the Ipod Nano 7th gen LCD display without a problems. Developed on Lattice MachXO2 dev board (the one with 7000HE).

For more information please go to http://mightydevices.com/?p=681

Operation
--------------
1. FPGA reads bytes from on-board FTDI chip (one port used as USART, other one is for programming the FPGA - obviously)
2. Bytes are pushed into SLIP decoder (slip is used to turn raw UART byte stream to frames with start/end delimiters)
3. Decoded bytes and frame signal are used to drive the DPHY
4. DPHY does the Low-power <-> High Speed mode transitions and pushes all the data on the data/clock lane

Image data is provided by node.js software

Demo Clip (youtube):

[![Alt text](https://img.youtube.com/vi/I9neWU76nZ0/0.jpg)](https://www.youtube.com/watch?v=I9neWU76nZ0)
