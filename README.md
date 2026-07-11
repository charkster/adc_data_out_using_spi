# adc_data_out_using_spi_or_qspi
Systemverilog code to output 16bit ADC data to an external SPI/QSPI memory.

In order to store more ADC conversions outside of the IC, this simple SPI master design can be used. The largest benefit of streaming out ADC conversion data on the SPI bus is **using the oscilloscope's SPI decoding to be able to simultaneously view ADC input and conversion value**. A bus format recognizable (decode-able) by the oscilloscope is needed to get the real-time decoding. The digital gate overhead for including this is minimal and digital test mux pins could be used to selectively output the SCK, MOSI and CS_N signals.

If you place a standard SPI DAC IC on the evaluation board you could even compare a delayed version of the ADC analog input with itself (address data would need to configured to be static and single byte). The point is that driving ADC conversion data out using the SPI bus format is very useful.

![picture](https://github.com/charkster/adc_data_out_using_spi/blob/main/single_cycle.png)

**UPDATE**

I added a QSPI version. There is a PSRAM command to enable QSPI timing and this version does not use it.

When QSPI speed is needed, it would make sense to remain in the "DATA" fsm state and output data as a block transfer (where the command and address are just sent once and lots of ADC data follows). The address counter could be repurposed to transition to the "IDLE" state when the last valid PSRAM address is approached (as to not over-write the memory).

![picture](https://github.com/charkster/adc_data_out_using_spi/blob/main/qspi_single_cycle.png)
