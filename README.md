# SPI

- **slave**: SPI slave version without SCK mode consideration
- **slave_fin**: SPI slave version with SCK mode consideration (Testbench updated)
1. Modified master in `tb_spi_rx.v`
2. Modified testbench in `tb_spi_rx_user_variant.v`

  ---
  ctrl = {cpha, cpol}
- mode1 : 2'b00 -> sample(first rising edge), shift(first falling edge)
-  mode2 : 2'b01 -> sample(first falling edge), shift(first rising edge)
-  mode3 : 2'b10 -> sample(second falling edge), shift(second rising edge)
-  mode4 : 2'b11 -> sample(second rising edge), shift(second falling edge)


