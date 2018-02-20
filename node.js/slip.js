/* we use serial port for communication */
const SerialPort = require('serialport');
/* streams */
const Stream = require('stream');

/* characters used for slip encoding */
const CHAR_FRAME        = 0xc0;
const CHAR_ESC          = 0xdb;
const CHAR_ESC_END      = 0xdc;
const CHAR_ESC_ESC      = 0xdd;

/* receive buffer states */
const STATE_FRAME       = 0;
const STATE_NORMAL      = 1;
const STATE_ESC         = 2;
const STATE_DONE        = 3;

/* slip protocol class */
class Slip extends Stream.Duplex
{
    /* class constructor */
    constructor (options)
    {
        /* call event emitter class constructor */
        super();
        
        /* store options values */
        this._portName = options.portName;
        this._baudRate = options.baudRate || 115200;
        this._rxBufLength = options.rxBufLength || 512;
        
        /* receive buffer */
        this._rxBuf = new Buffer(this._rxBufLength);
        this._rxLength = 0;
        this._rxState = 0;
        
        /* open serial port */
        this._sp = new SerialPort(this._portName, {
            baudRate : this._baudRate });
        
        /* listen to events */
        this._sp.once('open', () => {
            /* flush serial port */
            this._sp.flush();
            /* subscribe for data events */
            this._sp.on('data', this._onData.bind(this));
            this.emit('open');
        });
        /* error & close */
        this._sp.once('error', (err) => this.emit('error', err));
        this._sp.once('close', () => this.emit('close'));
    }
    
    /* close serial port */
    close(callback)
    {
        /* cleanup */
        this.removeAllListeners('data');
        this._sp.close(callback);
    }
    
    /* read function */
    _read(size)
    {
    }
    
    /* write function */
    _write(chunk, encoding, callback)
    {
        /* temporary buffers for sending special characters */
        var frame = Buffer.from([CHAR_FRAME]);
        var esc_end = Buffer.from([CHAR_ESC, CHAR_ESC_END]);
        var esc_esc = Buffer.from([CHAR_ESC, CHAR_ESC_ESC]);
        /* byte counter */
        var i = 0;
        
        /* write data */
        var write = () => {
            /* buffer to be sent */
            var toSend = null;
            /* still got some data to process? */
            if (i < chunk.byteLength) {
                /* switch on data value */
                switch (chunk[i]) {
                /* special characters that need escaping */
                case CHAR_FRAME : toSend = esc_end; i++; break;
                case CHAR_ESC : toSend = esc_esc; i++; break;
                /* normal data bytes */
                default : {
                    /* take as many normal characters as you can */
                    for (var j = i; j < chunk.byteLength; j++)
                        if (chunk[j] == CHAR_FRAME ||
                            chunk[j] == CHAR_ESC)
                            break;
                    /* build up buffer */
                    toSend = chunk.slice(i, j);
                    //toSend = true;
                    i = j;
                } break;
                }
            }
            /* send data */
            if (toSend) {
                var x = this._sp.write(toSend, write);
                if (x == false)
                    console.log('FALSE!');
            /* last callback: send frame end */
            } else {
                this._sp.write(frame);
                this._sp.drain(callback);
            }
        }
        
        /* this will initiate the process and send SOF */
        this._sp.write(frame, write);
    }
    
    /* data received event callback */
    _onData(data)
    {        
        /* done flag used for marking frame completeness */
        var done = false;

        /* process incoming bytes */
        for (var i = 0; i < data.byteLength; i++) {
            /* got starting sequence? */
            if (this._rxState == STATE_FRAME && data[i] == CHAR_FRAME) {
                this._rxState = STATE_NORMAL;
            /* in the middle of frame? */
            } else if (this._rxState == STATE_NORMAL) {
                /* end of frame? */
                if (data[i] == CHAR_FRAME) {
                    /* this way we consume subsequent 0xc0's */
                    if (this._rxLength != 0) 
                        done = true;
                /* escaping character? */
                } else if (data[i] == CHAR_ESC) {
                    this._rxState = STATE_ESC;
                /* normal character? */
                } else {
                    this._rxBuf[this._rxLength++] = data[i];
                }
            /* during escaping? */
            } else if (this._rxState == STATE_ESC) {
                /* store escaped character */
                this._rxBuf[this._rxLength++] = data[i] == CHAR_ESC_END ? 
                    CHAR_FRAME : CHAR_ESC;
                /* go back to normal state */
                this._rxState = STATE_NORMAL;
            }
            
            /* got complete frame? */
            if (done) {
                /* prepare resulting buffer */
                var b = Buffer.from(this._rxBuf.slice(0, 
                    this._rxLength));
                /* push data */
                this.push(b);
            }
            
            /* frame complete? buffer full? */
            if (done || this._rxBuf == this._rxLength) {
                /* reset state machine */
                this._rxState = STATE_FRAME;
                this._rxLength = 0;
                /* clear done flag */
                done = false;
            }
        }
    }
}

/* export slip class */
module.exports = Slip;