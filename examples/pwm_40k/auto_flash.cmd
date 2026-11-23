setMode -bs
setCable -port auto
Identify -inferir
identifyMPM
assignFile -p 1 -file "pwm_40k.bit"
attachflash -position 1 -spi "W25Q128BV"
assignfiletoattachedflash -position 1 -file "pwm_40k_auto_flash.mcs"
Program -p 1 -dataWidth 1 -spionly -e -v -loadfpga
quit
