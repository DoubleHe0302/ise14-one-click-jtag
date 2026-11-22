# ISE 14.7 通用一键脚本使用指南

## 适用范围

本工具针对 Windows 上 Xilinx ISE 14.7 的 `.xise` 工程。两个 `.bat` 均可单独使用，不依赖本文件夹中的其他脚本。脚本会读取工程中保存的 Implementation Top 和 Device，运行完整编译并查找与顶层同名的 `.bit`。多个 `.xise` 时按提示选择。

当前脚本假定工程已在 ISE 中正确设置顶层、器件、引脚、时钟和生成 bit 的选项。某些不同器件、配置方式或工程可能有额外要求，不保证全部板卡均可直接使用。自动顶层未被明确保存、bit 文件名不同、非 SPI Flash 或 SPI x2/x4 的情况需要针对工程修改脚本。

ISE 路径目前为 `D:\FPGA\14.7\ISE_DS\settings64.bat`。换电脑或重装 ISE 后，用文本编辑器打开相应 bat，找到 `$settings = '...'` 改为实际路径。为了兼容旧 ISE 和命令行，工程目录路径与 `.xise` 文件名请用英文、数字和空格，避免中文及 `& | < > % ! ^` 等字符。其他源文件也建议使用英文路径和文件名。

## 使用方法

1. 将所需脚本复制到 `.xise` 工程文件同级目录。两个脚本可以都复制，也可以仅复制一个。
2. 在 ISE 中预先设置并保存正确的顶层、器件、约束和配置选项。保存源码，关闭 ISE 和 iMPACT 图形界面。
3. 连接 JTAG 下载器，给 FPGA 板正常上电；关闭所有可能受 FPGA 管脚变化影响的外部驱动和功率级电源。
4. 双击所选脚本：
   - `universal_program.bat`：编译并临时下载到 FPGA SRAM，断电失效。
   - `universal_flash.bat`：编译、生成 MCS，选择性擦写 SPI Flash，断电保存。
5. 按提示选择工程（如有多个），检查显示的顶层、FPGA 型号。
6. Flash 脚本要求填写**实际板卡**的 Flash 型号、容量（KiB）和 SPI 宽度。只支持 x1。容量示例：128 Mbit = 16 MiB = 16384 KiB。型号必须是 iMPACT 中支持的精确名称；不要仅因为示例填写 `W25Q128BV`。bit 的启动时钟、总线宽度和板卡启动模式也须匹配。
7. 输入 FPGA 所在 JTAG 链位置，默认 1；关闭外部驱动后输入大写 `CHECK`。脚本先识别 JTAG 链并核对该位置的器件型号。
8. Flash 操作会提示擦除并覆盖原内容，确认无误后输入大写 `FLASH`。写入过程中不要断电、拔线。
9. 临时下载成功后测量输出；Flash 烧写时校验已被请求，需检查 `ise_generic_program.log` 中的 Flash 编程和校验结果。随后在外部驱动关闭的状态下完全断电重启，再测量输出；确认无误后才恢复外部驱动供电。

脚本生成的日志：`ise_generic_build.log`、`ise_generic_identify.log`、`ise_generic_program.log`，Flash 脚本另有 `ise_generic_promgen.log`。每次运行对应步骤会覆盖同名日志。Flash 写入失败时，Flash 内容可能已被部分擦除或写入，不能假定旧程序仍然存在。

已在 Spartan-6 XC6SLX16 和 W25Q128BV SPI x1 开发板上测试 JTAG 下载及 Flash 擦写、校验；其他板卡的兼容性尚未验证。请检查日志并通过断电重启确认。
