# universal_program.bat：临时 JTAG 下载详细指南

`universal_program.bat` 将工程重新编译并把 `.bit` 配置到 FPGA 的易失性存储区。它不会更新板载 Flash；FPGA 断电后临时配置消失，重新上电时会按板卡设置加载原有配置。

## 一、准备

1. 安装 ISE 14.7 和下载器驱动。用文本编辑器打开批处理，检查 `$settings` 指向本机的 `settings64.bat`；当前默认 `D:\FPGA\14.7\ISE_DS\settings64.bat`。
2. 将脚本复制到 `.xise` 工程同级目录。目录完整路径和 `.xise` 文件名应为 ASCII，并避开 `& | < > % ! ^`。
3. 在 ISE 中明确设置并保存 Implementation Top、Device、引脚及其余约束，保存所有源码并关闭 ISE 和 iMPACT。
4. 连接 JTAG 下载器和 FPGA 板，给板卡供电。关闭受 FPGA 引脚状态变化影响的外部驱动和功率级电源；如 MIC4428 系统，关闭 VS。

## 二、编译并下载

1. 双击 `universal_program.bat`。如果目录里有多个 `.xise`，按提示输入目标工程编号并回车。
2. 检查显示的工程、顶层和 FPGA 器件；等待综合、实现和 bit 文件生成。`BUILD COMPLETE` 表示编译流程结束，bit 文件仍需后续下载。
3. 看到 `FPGA JTAG chain position [1]` 时，输入目标 FPGA 的 JTAG 链位置并回车；直接回车采用 1。多器件链必须先核实位置。
4. 确认外部驱动电源关闭、FPGA 和下载器保持上电后，按提示输入大写 `CHECK` 并回车。想取消时关闭窗口或输入其他内容。
5. 脚本识别 JTAG 链并检查目标位置的 FPGA 型号，通过后执行 SRAM 下载。不要中途断电或拔线。
6. 看到 `FPGA SRAM programming confirmed` 表示脚本识别到下载成功提示。保持外部驱动关闭，先测量 FPGA 输出；确认后再恢复外部驱动供电。

## 三、检查和排错

- 编译失败：查看工程目录 `ise_generic_build.log`，核对工程设置、代码和 ISE 路径。
- 找不到工程或顶层：脚本必须放在 `.xise` 同级；确认 ISE 中已保存明确的 Implementation Top。脚本假设 bit 文件名与顶层名一致。
- JTAG 识别失败：查看 `ise_generic_identify.log`，检查 FPGA 上电、下载器、排线、驱动及链位置。
- 下载未确认：查看 `ise_generic_program.log`，确认目标器件的实际状态与 iMPACT 消息。日志会在下次运行对应步骤时覆盖。
- 下载后输出不对：核对所选工程、源码和探针接线；断电后临时配置会消失，因此在不断电情况下测量。确认故障前保持外部驱动关闭。

需要断电保存时，请参阅 [Flash 擦写指南](flash-guide.md)。不同工程、器件及板卡的兼容性以实际测试为准。
