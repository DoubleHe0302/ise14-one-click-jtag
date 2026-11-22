# ISE 14.7 一键编译与 JTAG 下载

Windows 批处理脚本：从 Xilinx ISE `.xise` 工程自动生成 `.bit`，并通过 iMPACT 下载到 FPGA 或写入 SPI Flash。复制脚本到工程目录即可使用，无需安装额外脚本。

| 脚本 | 操作 | 断电后 |
| --- | --- | --- |
| [universal_program.bat](universal_program.bat) | 编译并通过 JTAG 配置 FPGA | 临时配置丢失 |
| [universal_flash.bat](universal_flash.bat) | 编译、生成 MCS，擦写并请求校验 SPI Flash | FPGA 可从配置正确的 Flash 重新启动 |

## 开始使用

1. 安装 Windows 版 ISE 14.7，保证 `xtclsh`、`promgen`、`impact` 和 JTAG 驱动可以正常工作。ISE 软件和下载器不包含在本仓库。
2. 将所需 `.bat` 复制到 `.xise` 文件所在文件夹。脚本中默认的 ISE 环境路径为 `D:\FPGA\14.7\ISE_DS\settings64.bat`；如与你的电脑不一致，用文本编辑器打开脚本，修改 `$settings` 为实际路径。
3. 在 ISE 中设置并保存顶层模块、目标器件、约束和板卡配置，保存源码，关闭 ISE 和 iMPACT 界面。
4. 连接 JTAG，打开 FPGA 板电源，关闭受 FPGA 引脚状态变化影响的外部驱动和功率级电源。双击脚本并按窗口提示操作。
5. 下载后先测量输出；Flash 操作还应查看编程、校验日志，并在保持外部驱动关闭时完全断电重启、检查上电输出。

操作前请阅读：

- [ISE 14.7 通用一键脚本使用指南](docs/usage-guide.md)
- [临时 JTAG 下载详细操作指南](docs/program-guide.md)
- [Flash 擦写详细操作指南](docs/flash-guide.md)

## 范围和注意事项

- 脚本读取 `.xise` 中保存的 Implementation Top、Device，执行完整重新编译，并要求生成的 bit 文件名与顶层模块名一致。工程目录中存在多个 `.xise` 时可以选择。
- 工程目录完整路径与 `.xise` 文件名需为 ASCII，且不能包含 `& | < > % ! ^` 等 CMD 特殊字符；其他源文件也建议使用英文路径。
- Flash 模板仅支持 **SPI x1**。Flash 型号、容量、JTAG 位置、板卡启动模式和 bit 配置必须与实际硬件一致；W25Q128BV、16384 KiB 仅是示例。
- **Flash 擦写会覆盖原有内容。**脚本先要求确认外部功率级已关闭，再在擦写前要求输入 `FLASH`。擦写或校验失败后，不能假定旧内容仍然有效。
- Flash 分支请求 iMPACT 校验，但末尾的 `Flash operation completed` 不是校验通过的充分证据；请检查 `ise_generic_program.log` 中针对 Flash 的编程与校验结果。
- 已由用户在 Spartan-6 XC6SLX16、W25Q128BV SPI x1 板上测试 JTAG 下载和 Flash 烧写、校验。其他 FPGA、Flash、JTAG 下载器及软件组合的兼容性尚未验证。

脚本日志位于工程目录，重新运行会覆盖对应日志。旧版 ISE 对路径和环境较敏感，其他工程可能需要调整。

## 许可证

[MIT License](LICENSE)。Xilinx、AMD、ISE、iMPACT 等名称和软件属于其各自权利人，本项目不附带或重新分发这些软件。
