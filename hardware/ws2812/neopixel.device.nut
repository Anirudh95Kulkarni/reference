/*
Copyright (C) 2014 electric imp, inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
and associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, 
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE 
AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/* WS2812 "Neopixel" LED Driver
 * 
 * Uses SPI to emulate 1-wire
 * http://learn.adafruit.com/adafruit-neopixel-uberguide/advanced-coding
 *
 */

// constants for using SPI to emulate 1-wire
const BYTESPERPIXEL = 27;
const BYTESPERCOLOR = 9; // BYTESPERPIXEL / 3
const SPICLK = 7500; // SPI clock speed in kHz

// this string contains the "equivalent waveform" to send the numbers 0-255 over SPI at 7.5MHz.
// 9 bytes of string are required to send 1 byte of emulated 1-wire data. 
// For example, to add a byte containing the number "14" to the frame:
// bits.slice(14 * 9, (14 * 9) + 9);
const bits = "\xE0\x70\x38\x1C\x0E\x07\x03\x81\xC0\xE0\x70\x38\x1C\x0E\x07\x03\x81\xF8\xE0\x70\x38\x1C\x0E\x07\x03\xF1\xC0\xE0\x70\x38\x1C\x0E\x07\x03\xF1\xF8\xE0\x70\x38\x1C\x0E\x07\xE3\x81\xC0\xE0\x70\x38\x1C\x0E\x07\xE3\x81\xF8\xE0\x70\x38\x1C\x0E\x07\xE3\xF1\xC0\xE0\x70\x38\x1C\x0E\x07\xE3\xF1\xF8\xE0\x70\x38\x1C\x0F\xC7\x03\x81\xC0\xE0\x70\x38\x1C\x0F\xC7\x03\x81\xF8\xE0\x70\x38\x1C\x0F\xC7\x03\xF1\xC0\xE0\x70\x38\x1C\x0F\xC7\x03\xF1\xF8\xE0\x70\x38\x1C\x0F\xC7\xE3\x81\xC0\xE0\x70\x38\x1C\x0F\xC7\xE3\x81\xF8\xE0\x70\x38\x1C\x0F\xC7\xE3\xF1\xC0\xE0\x70\x38\x1C\x0F\xC7\xE3\xF1\xF8\xE0\x70\x38\x1F\x8E\x07\x03\x81\xC0\xE0\x70\x38\x1F\x8E\x07\x03\x81\xF8\xE0\x70\x38\x1F\x8E\x07\x03\xF1\xC0\xE0\x70\x38\x1F\x8E\x07\x03\xF1\xF8\xE0\x70\x38\x1F\x8E\x07\xE3\x81\xC0\xE0\x70\x38\x1F\x8E\x07\xE3\x81\xF8\xE0\x70\x38\x1F\x8E\x07\xE3\xF1\xC0\xE0\x70\x38\x1F\x8E\x07\xE3\xF1\xF8\xE0\x70\x38\x1F\x8F\xC7\x03\x81\xC0\xE0\x70\x38\x1F\x8F\xC7\x03\x81\xF8\xE0\x70\x38\x1F\x8F\xC7\x03\xF1\xC0\xE0\x70\x38\x1F\x8F\xC7\x03\xF1\xF8\xE0\x70\x38\x1F\x8F\xC7\xE3\x81\xC0\xE0\x70\x38\x1F\x8F\xC7\xE3\x81\xF8\xE0\x70\x38\x1F\x8F\xC7\xE3\xF1\xC0\xE0\x70\x38\x1F\x8F\xC7\xE3\xF1\xF8\xE0\x70\x3F\x1C\x0E\x07\x03\x81\xC0\xE0\x70\x3F\x1C\x0E\x07\x03\x81\xF8\xE0\x70\x3F\x1C\x0E\x07\x03\xF1\xC0\xE0\x70\x3F\x1C\x0E\x07\x03\xF1\xF8\xE0\x70\x3F\x1C\x0E\x07\xE3\x81\xC0\xE0\x70\x3F\x1C\x0E\x07\xE3\x81\xF8\xE0\x70\x3F\x1C\x0E\x07\xE3\xF1\xC0\xE0\x70\x3F\x1C\x0E\x07\xE3\xF1\xF8\xE0\x70\x3F\x1C\x0F\xC7\x03\x81\xC0\xE0\x70\x3F\x1C\x0F\xC7\x03\x81\xF8\xE0\x70\x3F\x1C\x0F\xC7\x03\xF1\xC0\xE0\x70\x3F\x1C\x0F\xC7\x03\xF1\xF8\xE0\x70\x3F\x1C\x0F\xC7\xE3\x81\xC0\xE0\x70\x3F\x1C\x0F\xC7\xE3\x81\xF8\xE0\x70\x3F\x1C\x0F\xC7\xE3\xF1\xC0\xE0\x70\x3F\x1C\x0F\xC7\xE3\xF1\xF8\xE0\x70\x3F\x1F\x8E\x07\x03\x81\xC0\xE0\x70\x3F\x1F\x8E\x07\x03\x81\xF8\xE0\x70\x3F\x1F\x8E\x07\x03\xF1\xC0\xE0\x70\x3F\x1F\x8E\x07\x03\xF1\xF8\xE0\x70\x3F\x1F\x8E\x07\xE3\x81\xC0\xE0\x70\x3F\x1F\x8E\x07\xE3\x81\xF8\xE0\x70\x3F\x1F\x8E\x07\xE3\xF1\xC0\xE0\x70\x3F\x1F\x8E\x07\xE3\xF1\xF8\xE0\x70\x3F\x1F\x8F\xC7\x03\x81\xC0\xE0\x70\x3F\x1F\x8F\xC7\x03\x81\xF8\xE0\x70\x3F\x1F\x8F\xC7\x03\xF1\xC0\xE0\x70\x3F\x1F\x8F\xC7\x03\xF1\xF8\xE0\x70\x3F\x1F\x8F\xC7\xE3\x81\xC0\xE0\x70\x3F\x1F\x8F\xC7\xE3\x81\xF8\xE0\x70\x3F\x1F\x8F\xC7\xE3\xF1\xC0\xE0\x70\x3F\x1F\x8F\xC7\xE3\xF1\xF8\xE0\x7E\x38\x1C\x0E\x07\x03\x81\xC0\xE0\x7E\x38\x1C\x0E\x07\x03\x81\xF8\xE0\x7E\x38\x1C\x0E\x07\x03\xF1\xC0\xE0\x7E\x38\x1C\x0E\x07\x03\xF1\xF8\xE0\x7E\x38\x1C\x0E\x07\xE3\x81\xC0\xE0\x7E\x38\x1C\x0E\x07\xE3\x81\xF8\xE0\x7E\x38\x1C\x0E\x07\xE3\xF1\xC0\xE0\x7E\x38\x1C\x0E\x07\xE3\xF1\xF8\xE0\x7E\x38\x1C\x0F\xC7\x03\x81\xC0\xE0\x7E\x38\x1C\x0F\xC7\x03\x81\xF8\xE0\x7E\x38\x1C\x0F\xC7\x03\xF1\xC0\xE0\x7E\x38\x1C\x0F\xC7\x03\xF1\xF8\xE0\x7E\x38\x1C\x0F\xC7\xE3\x81\xC0\xE0\x7E\x38\x1C\x0F\xC7\xE3\x81\xF8\xE0\x7E\x38\x1C\x0F\xC7\xE3\xF1\xC0\xE0\x7E\x38\x1C\x0F\xC7\xE3\xF1\xF8\xE0\x7E\x38\x1F\x8E\x07\x03\x81\xC0\xE0\x7E\x38\x1F\x8E\x07\x03\x81\xF8\xE0\x7E\x38\x1F\x8E\x07\x03\xF1\xC0\xE0\x7E\x38\x1F\x8E\x07\x03\xF1\xF8\xE0\x7E\x38\x1F\x8E\x07\xE3\x81\xC0\xE0\x7E\x38\x1F\x8E\x07\xE3\x81\xF8\xE0\x7E\x38\x1F\x8E\x07\xE3\xF1\xC0\xE0\x7E\x38\x1F\x8E\x07\xE3\xF1\xF8\xE0\x7E\x38\x1F\x8F\xC7\x03\x81\xC0\xE0\x7E\x38\x1F\x8F\xC7\x03\x81\xF8\xE0\x7E\x38\x1F\x8F\xC7\x03\xF1\xC0\xE0\x7E\x38\x1F\x8F\xC7\x03\xF1\xF8\xE0\x7E\x38\x1F\x8F\xC7\xE3\x81\xC0\xE0\x7E\x38\x1F\x8F\xC7\xE3\x81\xF8\xE0\x7E\x38\x1F\x8F\xC7\xE3\xF1\xC0\xE0\x7E\x38\x1F\x8F\xC7\xE3\xF1\xF8\xE0\x7E\x3F\x1C\x0E\x07\x03\x81\xC0\xE0\x7E\x3F\x1C\x0E\x07\x03\x81\xF8\xE0\x7E\x3F\x1C\x0E\x07\x03\xF1\xC0\xE0\x7E\x3F\x1C\x0E\x07\x03\xF1\xF8\xE0\x7E\x3F\x1C\x0E\x07\xE3\x81\xC0\xE0\x7E\x3F\x1C\x0E\x07\xE3\x81\xF8\xE0\x7E\x3F\x1C\x0E\x07\xE3\xF1\xC0\xE0\x7E\x3F\x1C\x0E\x07\xE3\xF1\xF8\xE0\x7E\x3F\x1C\x0F\xC7\x03\x81\xC0\xE0\x7E\x3F\x1C\x0F\xC7\x03\x81\xF8\xE0\x7E\x3F\x1C\x0F\xC7\x03\xF1\xC0\xE0\x7E\x3F\x1C\x0F\xC7\x03\xF1\xF8\xE0\x7E\x3F\x1C\x0F\xC7\xE3\x81\xC0\xE0\x7E\x3F\x1C\x0F\xC7\xE3\x81\xF8\xE0\x7E\x3F\x1C\x0F\xC7\xE3\xF1\xC0\xE0\x7E\x3F\x1C\x0F\xC7\xE3\xF1\xF8\xE0\x7E\x3F\x1F\x8E\x07\x03\x81\xC0\xE0\x7E\x3F\x1F\x8E\x07\x03\x81\xF8\xE0\x7E\x3F\x1F\x8E\x07\x03\xF1\xC0\xE0\x7E\x3F\x1F\x8E\x07\x03\xF1\xF8\xE0\x7E\x3F\x1F\x8E\x07\xE3\x81\xC0\xE0\x7E\x3F\x1F\x8E\x07\xE3\x81\xF8\xE0\x7E\x3F\x1F\x8E\x07\xE3\xF1\xC0\xE0\x7E\x3F\x1F\x8E\x07\xE3\xF1\xF8\xE0\x7E\x3F\x1F\x8F\xC7\x03\x81\xC0\xE0\x7E\x3F\x1F\x8F\xC7\x03\x81\xF8\xE0\x7E\x3F\x1F\x8F\xC7\x03\xF1\xC0\xE0\x7E\x3F\x1F\x8F\xC7\x03\xF1\xF8\xE0\x7E\x3F\x1F\x8F\xC7\xE3\x81\xC0\xE0\x7E\x3F\x1F\x8F\xC7\xE3\x81\xF8\xE0\x7E\x3F\x1F\x8F\xC7\xE3\xF1\xC0\xE0\x7E\x3F\x1F\x8F\xC7\xE3\xF1\xF8\xFC\x70\x38\x1C\x0E\x07\x03\x81\xC0\xFC\x70\x38\x1C\x0E\x07\x03\x81\xF8\xFC\x70\x38\x1C\x0E\x07\x03\xF1\xC0\xFC\x70\x38\x1C\x0E\x07\x03\xF1\xF8\xFC\x70\x38\x1C\x0E\x07\xE3\x81\xC0\xFC\x70\x38\x1C\x0E\x07\xE3\x81\xF8\xFC\x70\x38\x1C\x0E\x07\xE3\xF1\xC0\xFC\x70\x38\x1C\x0E\x07\xE3\xF1\xF8\xFC\x70\x38\x1C\x0F\xC7\x03\x81\xC0\xFC\x70\x38\x1C\x0F\xC7\x03\x81\xF8\xFC\x70\x38\x1C\x0F\xC7\x03\xF1\xC0\xFC\x70\x38\x1C\x0F\xC7\x03\xF1\xF8\xFC\x70\x38\x1C\x0F\xC7\xE3\x81\xC0\xFC\x70\x38\x1C\x0F\xC7\xE3\x81\xF8\xFC\x70\x38\x1C\x0F\xC7\xE3\xF1\xC0\xFC\x70\x38\x1C\x0F\xC7\xE3\xF1\xF8\xFC\x70\x38\x1F\x8E\x07\x03\x81\xC0\xFC\x70\x38\x1F\x8E\x07\x03\x81\xF8\xFC\x70\x38\x1F\x8E\x07\x03\xF1\xC0\xFC\x70\x38\x1F\x8E\x07\x03\xF1\xF8\xFC\x70\x38\x1F\x8E\x07\xE3\x81\xC0\xFC\x70\x38\x1F\x8E\x07\xE3\x81\xF8\xFC\x70\x38\x1F\x8E\x07\xE3\xF1\xC0\xFC\x70\x38\x1F\x8E\x07\xE3\xF1\xF8\xFC\x70\x38\x1F\x8F\xC7\x03\x81\xC0\xFC\x70\x38\x1F\x8F\xC7\x03\x81\xF8\xFC\x70\x38\x1F\x8F\xC7\x03\xF1\xC0\xFC\x70\x38\x1F\x8F\xC7\x03\xF1\xF8\xFC\x70\x38\x1F\x8F\xC7\xE3\x81\xC0\xFC\x70\x38\x1F\x8F\xC7\xE3\x81\xF8\xFC\x70\x38\x1F\x8F\xC7\xE3\xF1\xC0\xFC\x70\x38\x1F\x8F\xC7\xE3\xF1\xF8\xFC\x70\x3F\x1C\x0E\x07\x03\x81\xC0\xFC\x70\x3F\x1C\x0E\x07\x03\x81\xF8\xFC\x70\x3F\x1C\x0E\x07\x03\xF1\xC0\xFC\x70\x3F\x1C\x0E\x07\x03\xF1\xF8\xFC\x70\x3F\x1C\x0E\x07\xE3\x81\xC0\xFC\x70\x3F\x1C\x0E\x07\xE3\x81\xF8\xFC\x70\x3F\x1C\x0E\x07\xE3\xF1\xC0\xFC\x70\x3F\x1C\x0E\x07\xE3\xF1\xF8\xFC\x70\x3F\x1C\x0F\xC7\x03\x81\xC0\xFC\x70\x3F\x1C\x0F\xC7\x03\x81\xF8\xFC\x70\x3F\x1C\x0F\xC7\x03\xF1\xC0\xFC\x70\x3F\x1C\x0F\xC7\x03\xF1\xF8\xFC\x70\x3F\x1C\x0F\xC7\xE3\x81\xC0\xFC\x70\x3F\x1C\x0F\xC7\xE3\x81\xF8\xFC\x70\x3F\x1C\x0F\xC7\xE3\xF1\xC0\xFC\x70\x3F\x1C\x0F\xC7\xE3\xF1\xF8\xFC\x70\x3F\x1F\x8E\x07\x03\x81\xC0\xFC\x70\x3F\x1F\x8E\x07\x03\x81\xF8\xFC\x70\x3F\x1F\x8E\x07\x03\xF1\xC0\xFC\x70\x3F\x1F\x8E\x07\x03\xF1\xF8\xFC\x70\x3F\x1F\x8E\x07\xE3\x81\xC0\xFC\x70\x3F\x1F\x8E\x07\xE3\x81\xF8\xFC\x70\x3F\x1F\x8E\x07\xE3\xF1\xC0\xFC\x70\x3F\x1F\x8E\x07\xE3\xF1\xF8\xFC\x70\x3F\x1F\x8F\xC7\x03\x81\xC0\xFC\x70\x3F\x1F\x8F\xC7\x03\x81\xF8\xFC\x70\x3F\x1F\x8F\xC7\x03\xF1\xC0\xFC\x70\x3F\x1F\x8F\xC7\x03\xF1\xF8\xFC\x70\x3F\x1F\x8F\xC7\xE3\x81\xC0\xFC\x70\x3F\x1F\x8F\xC7\xE3\x81\xF8\xFC\x70\x3F\x1F\x8F\xC7\xE3\xF1\xC0\xFC\x70\x3F\x1F\x8F\xC7\xE3\xF1\xF8\xFC\x7E\x38\x1C\x0E\x07\x03\x81\xC0\xFC\x7E\x38\x1C\x0E\x07\x03\x81\xF8\xFC\x7E\x38\x1C\x0E\x07\x03\xF1\xC0\xFC\x7E\x38\x1C\x0E\x07\x03\xF1\xF8\xFC\x7E\x38\x1C\x0E\x07\xE3\x81\xC0\xFC\x7E\x38\x1C\x0E\x07\xE3\x81\xF8\xFC\x7E\x38\x1C\x0E\x07\xE3\xF1\xC0\xFC\x7E\x38\x1C\x0E\x07\xE3\xF1\xF8\xFC\x7E\x38\x1C\x0F\xC7\x03\x81\xC0\xFC\x7E\x38\x1C\x0F\xC7\x03\x81\xF8\xFC\x7E\x38\x1C\x0F\xC7\x03\xF1\xC0\xFC\x7E\x38\x1C\x0F\xC7\x03\xF1\xF8\xFC\x7E\x38\x1C\x0F\xC7\xE3\x81\xC0\xFC\x7E\x38\x1C\x0F\xC7\xE3\x81\xF8\xFC\x7E\x38\x1C\x0F\xC7\xE3\xF1\xC0\xFC\x7E\x38\x1C\x0F\xC7\xE3\xF1\xF8\xFC\x7E\x38\x1F\x8E\x07\x03\x81\xC0\xFC\x7E\x38\x1F\x8E\x07\x03\x81\xF8\xFC\x7E\x38\x1F\x8E\x07\x03\xF1\xC0\xFC\x7E\x38\x1F\x8E\x07\x03\xF1\xF8\xFC\x7E\x38\x1F\x8E\x07\xE3\x81\xC0\xFC\x7E\x38\x1F\x8E\x07\xE3\x81\xF8\xFC\x7E\x38\x1F\x8E\x07\xE3\xF1\xC0\xFC\x7E\x38\x1F\x8E\x07\xE3\xF1\xF8\xFC\x7E\x38\x1F\x8F\xC7\x03\x81\xC0\xFC\x7E\x38\x1F\x8F\xC7\x03\x81\xF8\xFC\x7E\x38\x1F\x8F\xC7\x03\xF1\xC0\xFC\x7E\x38\x1F\x8F\xC7\x03\xF1\xF8\xFC\x7E\x38\x1F\x8F\xC7\xE3\x81\xC0\xFC\x7E\x38\x1F\x8F\xC7\xE3\x81\xF8\xFC\x7E\x38\x1F\x8F\xC7\xE3\xF1\xC0\xFC\x7E\x38\x1F\x8F\xC7\xE3\xF1\xF8\xFC\x7E\x3F\x1C\x0E\x07\x03\x81\xC0\xFC\x7E\x3F\x1C\x0E\x07\x03\x81\xF8\xFC\x7E\x3F\x1C\x0E\x07\x03\xF1\xC0\xFC\x7E\x3F\x1C\x0E\x07\x03\xF1\xF8\xFC\x7E\x3F\x1C\x0E\x07\xE3\x81\xC0\xFC\x7E\x3F\x1C\x0E\x07\xE3\x81\xF8\xFC\x7E\x3F\x1C\x0E\x07\xE3\xF1\xC0\xFC\x7E\x3F\x1C\x0E\x07\xE3\xF1\xF8\xFC\x7E\x3F\x1C\x0F\xC7\x03\x81\xC0\xFC\x7E\x3F\x1C\x0F\xC7\x03\x81\xF8\xFC\x7E\x3F\x1C\x0F\xC7\x03\xF1\xC0\xFC\x7E\x3F\x1C\x0F\xC7\x03\xF1\xF8\xFC\x7E\x3F\x1C\x0F\xC7\xE3\x81\xC0\xFC\x7E\x3F\x1C\x0F\xC7\xE3\x81\xF8\xFC\x7E\x3F\x1C\x0F\xC7\xE3\xF1\xC0\xFC\x7E\x3F\x1C\x0F\xC7\xE3\xF1\xF8\xFC\x7E\x3F\x1F\x8E\x07\x03\x81\xC0\xFC\x7E\x3F\x1F\x8E\x07\x03\x81\xF8\xFC\x7E\x3F\x1F\x8E\x07\x03\xF1\xC0\xFC\x7E\x3F\x1F\x8E\x07\x03\xF1\xF8\xFC\x7E\x3F\x1F\x8E\x07\xE3\x81\xC0\xFC\x7E\x3F\x1F\x8E\x07\xE3\x81\xF8\xFC\x7E\x3F\x1F\x8E\x07\xE3\xF1\xC0\xFC\x7E\x3F\x1F\x8E\x07\xE3\xF1\xF8\xFC\x7E\x3F\x1F\x8F\xC7\x03\x81\xC0\xFC\x7E\x3F\x1F\x8F\xC7\x03\x81\xF8\xFC\x7E\x3F\x1F\x8F\xC7\x03\xF1\xC0\xFC\x7E\x3F\x1F\x8F\xC7\x03\xF1\xF8\xFC\x7E\x3F\x1F\x8F\xC7\xE3\x81\xC0\xFC\x7E\x3F\x1F\x8F\xC7\xE3\x81\xF8\xFC\x7E\x3F\x1F\x8F\xC7\xE3\xF1\xC0\xFC\x7E\x3F\x1F\x8F\xC7\xE3\xF1\xF8";
// This string holds three "zero" bytes [0,0,0]; clears a pixel when written to the frame
imp.enableblinkup(false);

// clearString = [0,0,0]
const clearString = "\xE0\x70\x38\x1C\x0E\x07\x03\x81\xC0\xE0\x70\x38\x1C\x0E\x07\x03\x81\xC0\xE0\x70\x38\x1C\x0E\x07\x03\x81\xC0";

class neoPixels {
    spi = null;
    frameSize = null;
    frame = null;

    // _spi - A configured spi (MSB_FIRST, 7.5MHz)
    // _frameSize - Number of Pixels per frame
    constructor(_spi, _frameSize) {
        this.spi = _spi;
        this.frameSize = _frameSize;
        this.frame = blob(frameSize*27 + 1);
        
        clearFrame();
        writeFrame();
    }

    // sets a pixel in the frame buffer
    // but does not write it to the pixel strip
    // color is an array of the form [r, g, b]
    function writePixel(p, color) {
        frame.seek(p*BYTESPERPIXEL);
        local r = color[0] * BYTESPERCOLOR;
        local g = color[1] * BYTESPERCOLOR;
        local b = color[2] * BYTESPERCOLOR;
        frame.writestring(bits.slice(g, g+BYTESPERCOLOR));
        frame.writestring(bits.slice(r, r+BYTESPERCOLOR));
        frame.writestring(bits.slice(b, b+BYTESPERCOLOR));    
    }
    
    // clears the frame buffer
    // but does not write it to the pixel strip
    function clearFrame() {
      for (local p = 0; p < frameSize; p++) frame.writestring(clearString);
      frame.writen(0x00,'c');
    }
    
    // writes the frame buffer to the pixel strip
    // ie - this function changes the pixel strip
    function writeFrame() {
        spi.write(frame);
    }
}

// The number of pixels in your chain
// (this is for an 8x8 grid)
const NUMPIXELS = 64;

spi <- hardware.spi257;
spi.configure(MSB_FIRST, SPICLK);
pixels <- neoPixels(spi, NUMPIXELS);

i <- 0;
function loop() {
    imp.wakeup(0.05, loop)

    // increment to next pixel
    i++;
    if (i > NUMPIXELS) i = 0;
    
    // clear the frame, set pixel red, then write to pixelstrip
    pixels.clearFrame();
    pixels.writePixel(i, [255, 0, 0]);
}

loop();
