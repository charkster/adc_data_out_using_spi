# adc_data_out_using_spi
Systemverilog code to output 16bit ADC data to an external SPI memory.

In order to store more ADC conversions outside of the IC, this simple SPI master design can be used. The largest benefit of streaming out ADC conversion data on the SPI bus is **using the oscilloscope's SPI decoding to be able to simultaneously view ADC input and conversion value**. A bus format recognizable (decode-able) by the oscilloscope is needed to get the real-time decoding. The digital gate overhead for including this is minimal and digital test mux pins could be used to selectively output the SCK, MOSI and CS_N signals.

If you added a SPI DAC to the evaluation board you could even compare a delayed version of the ADC analog input with itself (address data would need to configured to be static and single byte). The point is that driving ADC conversion data out using the SPI bus format is useful.

![picture](https://github.com/charkster/adc_data_out_using_spi/blob/main/single_cycle.png)
