# PWM_40k 工程专用脚本示例

本目录保存了实际 PWM_40k 工程使用的两个 Windows 批处理及其依赖文件：

| 文件 | 用途 |
| --- | --- |
| `build_and_program.bat` | 编译后通过 JTAG 将 bit 临时下载到 FPGA；断电后配置丢失。 |
| `build_and_flash.bat` | 编译并生成 MCS，通过 JTAG 擦写板载 SPI Flash，并请求校验。 |
| `auto_build.tcl` | 两个批处理共同调用的 ISE 编译脚本。 |
| `auto_flash.cmd` | Flash 批处理调用的 iMPACT 命令文件。 |

这不是完整的 FPGA 工程：本目录不包含 `PWM_40k.xise`、`pwm_40k.v` 和 `pwm_40k.ucf`。使用时需将四个文件复制到现有 PWM_40k 工程的 `.xise` 同级目录，并确保工程源码和约束可用。其他项目请优先使用[通用脚本](../../README.md)。

## 固定设置

- 工程名 `PWM_40k.xise`，生成文件 `pwm_40k.bit`；ISE 环境路径为 `D:\FPGA\14.7\ISE_DS\settings64.bat`，其他安装位置需要修改两个批处理。
- JTAG 链第 1 个位置，目标器件为 XC6SLX16；Flash 示例为 W25Q128BV、128 Mbit、SPI x1。不同板卡必须先核对器件、容量、配置模式和链位置，不能直接套用。
- 在 ISE 中正确设置并保存工程后，保存源码并关闭 ISE 和 iMPACT 图形界面，再运行所需脚本。

## 使用与检查

1. 连接 JTAG 并给 FPGA 板供电；关闭 MIC4428 VS 和其他受引脚状态变化影响的外部驱动电源。
2. 双击需要的批处理。临时下载脚本在下载前暂停；确认 VS 已关闭后按键继续。Flash 脚本会提示擦除旧内容，确认硬件配置和断驱动供电后输入大写 `FLASH` 才执行擦写。
3. 下载后先测量输出。Flash 脚本请求校验，但其结束信息本身不证明 Flash 校验通过；请查看 `auto_flash.log` 中的 Flash 编程及校验结果。完全断电并在 VS 关闭的情况下重新上电，验证输出后再恢复驱动供电。

Flash 操作会覆盖原有内容，操作中不要断电或拔线；如果失败，不能假定旧内容仍然有效。脚本基于原工程硬件配置，不保证其他工程可用。更多操作说明见[通用脚本使用指南](../../docs/usage-guide.md)。
