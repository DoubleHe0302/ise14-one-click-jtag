# universal_flash.bat 详细操作指南

本指南说明如何使用 `universal_flash.bat`：重新编译 ISE 工程、生成 `.bit` 和 `.mcs`，并通过 JTAG 擦写和校验板载 SPI Flash，让 FPGA 下次上电时加载新程序。

> **擦写会覆盖 Flash 原有内容。**如果需要保留原有上电程序，先保存可用于恢复的原始文件。写入失败或中断后，不能假定旧程序仍然存在。
>
> 以下 W25Q128BV 等数值是当前 PWM 开发板已有记录中的设置。换板或换 Flash 时必须重新核对，不能直接照搬。

## 一、适用范围与准备

- 适用于 Windows、ISE 14.7 的 `.xise` 工程。脚本目前仅支持 **SPI x1**，不适用于直接套用到 SPI x2/x4、BPI 或其他配置方式。
- ISE 工程中必须已正确设置并保存 FPGA 器件、Implementation Top、引脚和时钟约束，以及适合板卡的启动时钟和 SPI 配置；顶层要能从工程文件中明确读取，输出 `.bit` 文件名需与顶层模块名一致。
- 工程目录完整路径和 `.xise` 文件名使用英文、数字和空格，不使用中文或 `& | < > % ! ^`。源文件路径也建议使用英文。
- 本机脚本内的 ISE 环境路径是 `D:\FPGA\14.7\ISE_DS\settings64.bat`。如果换电脑或重装 ISE，右键用记事本打开 `.bat`，找到 `$settings = '...'`，改成新的实际路径并保存。
- 烧写时 FPGA 引脚状态可能变化。**关闭 MIC4428 的 VS 和其他受影响的外部功率级电源**；保持 FPGA 开发板及 JTAG 下载器正常供电。写入过程中不要断开 FPGA 板电源、拔掉 USB 或 JTAG 排线。

## 二、复制脚本并保存工程

1. 在新工程中找到 `.xise` 文件所在目录。
2. 将 `universal_flash.bat` 复制到该目录，与 `.xise` 文件同级；该批处理可单独使用，不需要复制其他脚本。
3. 修改并保存你的 Verilog 或 VHDL 源文件、约束和 ISE 工程设置。
4. 保存并关闭 ISE Project Navigator，以及可能占用 JTAG 下载器的 iMPACT 界面。
5. 连接下载器 USB、JTAG 排线并给 FPGA 开发板上电。关闭 MIC4428 VS 和其他受影响的外部驱动电源。

当前 PWM 工程示例目录：

```text
C:\FPGA_Projects\PWM_40k_4Phase_Project
```

## 三、启动编译

1. 在 `.xise` 同级目录双击 `universal_flash.bat`。
2. 如果该目录有多个 `.xise`，窗口会列出编号，并提示 `Choose project number`。输入正确工程前面的编号，按回车。
3. 检查窗口显示的 `Project`（工程名）、`Top`（顶层模块）和 `FPGA`（器件）。如有不符，关闭窗口，回 ISE 修正并保存后重新运行。
4. 等待综合、实现和 bit 文件生成。完成后显示 `BUILD COMPLETE` 和 `Built bit file`。

这时只是生成了 `.bit`，**还没有擦写 Flash**。如果报告编译失败，查看工程目录中的 `ise_generic_build.log`，修复后重新运行；不要使用旧 `.bit`。

## 四、填写 Flash 参数

编译完成后，窗口依次询问三项。**每项都要输入，输入后按回车；不能把括号中的示例当成自动填入的默认值。**如果前一项输入错误或空着，关闭窗口并重新运行脚本。

### 1. Flash 型号

看到：

```text
Enter exact iMPACT SPI Flash name (example W25Q128BV):
```

当前 PWM 板的已有记录为 `W25Q128BV`。核对板上芯片型号和 iMPACT 支持名称后，输入：

```text
W25Q128BV
```

按回车。其他板卡请输入该板的准确型号。

### 2. Flash 容量

看到：

```text
Enter Flash capacity in KiB (example 16384 for 128 Mbit):
```

当前板的记录是 128 Mbit，即 16 MiB、**16384 KiB**，输入：

```text
16384
```

按回车。这里单位是 **KiB**，不是 Mbit；换 Flash 时要按实际容量换算。

### 3. SPI 数据宽度

看到：

```text
Enter configured SPI bus width (1, 2 or 4):
```

虽然提示列出了 1、2、4，**当前脚本只支持 1**。当前 PWM 工程记录使用 SPI x1，因此输入：

```text
1
```

按回车。不要对其他板卡假设 x1 正确；须核对工程 bit 配置、Flash 与板卡启动模式。

## 五、生成 MCS 并确认 JTAG

1. 脚本运行 `promgen`，生成 `<顶层名>_generic_flash.mcs`。当前工程对应 `pwm_40k_generic_flash.mcs`。看到 `Generated:` 表示脚本检测到该文件已生成；**此时 Flash 仍未擦写**。
2. 出现 `FPGA JTAG chain position [1]`：输入 FPGA 在 JTAG 链中的位置，按回车。直接回车采用 1。当前板之前的 JTAG 日志显示 FPGA 位于位置 1；其他板卡须先确认。
3. 出现关闭外部驱动的警告。再次确认 **MIC4428 VS 已关闭**，FPGA 板和 JTAG 下载器仍正常供电；然后输入大写 `CHECK` 并回车。输入其他内容会取消。
4. 脚本识别 JTAG 链，核对该位置的 FPGA 型号是否与工程中的器件一致。显示 `JTAG FPGA identification matches.` 表示检查通过；识别失败请先检查连接、电源、驱动及链位置。

> JTAG 器件识别通过，只说明指定位置的 FPGA 与工程器件匹配，并不自动证明板载 Flash 型号、容量或 SPI 配置已正确。

## 六、确认擦写 Flash

1. 出现 `FINAL WARNING` 时，再核对窗口显示的 Flash 型号、容量和宽度，确认输入正确、可以覆盖原内容、外部驱动供电已关闭。
2. 确认后输入大写 `FLASH`，按回车。输入其他内容或在执行前关闭窗口可以取消。
3. 脚本会通过 iMPACT 请求**擦除、编程并校验** Flash。等待完成；不要在过程中断电、拔线或关闭窗口。
4. 若显示 `[ERROR]`，保持外部驱动关闭，查看工程目录的 `ise_generic_program.log`。如果已开始擦写，Flash 可能处于部分擦除或部分写入状态，需要排查后重新烧写。

## 七、检查日志并断电验证

脚本出现 `Flash operation completed. Verification was requested` 仅表示流程结束且**已请求校验**，不能单靠这一行断定 Flash 编程和校验均已成功。打开工程目录中的 `ise_generic_program.log`，查看针对 Flash 的编程结果以及校验结果；如果结果不明确或有错误，请保留日志并检查，不要假定写入成功。日志每次执行相应步骤会被覆盖。

确认 Flash 编程和校验成功后：

1. 保持 MIC4428 VS 和其他外部驱动电源关闭，完全切断 FPGA 开发板电源。
2. 拔掉 JTAG 下载器，再仅给开发板正常上电；不要重新运行下载脚本。
3. 对当前 PWM 工程，用示波器检查四路 40 kHz 波形与相对延时是否符合最新参数；其他工程则检查对应的预期输出。
4. 确认上电自动运行、输出正确后，才接通 MIC4428 VS 和其他外部驱动电源。

如果断电重启后恢复旧程序或没有预期输出，保持外部驱动关闭，检查是否真的写入 Flash、校验是否成功、板卡启动模式与 SPI x1 设置是否匹配，以及 `.mcs` 是否由本次最新 `.bit` 生成。

## 八、常见错误和日志

| 提示或现象 | 含义与处理 |
| --- | --- |
| `No .xise project in this folder` | 把脚本复制到正确的 `.xise` 同级目录。 |
| `Project path must use ASCII` | 工程完整路径包含中文或不支持的命令行字符；改用符合要求的路径。 |
| `ISE settings not found` | 检查脚本中 `$settings` 是否指向本机实际的 `settings64.bat`。 |
| `Cannot determine top module` | 在 ISE 中明确设置 Implementation Top、保存工程，再运行脚本。 |
| `Invalid Flash settings` | 型号、容量或宽度为空或格式错误；重新运行，逐项填写。 |
| `This template supports SPI x1 only` | 本脚本不支持所选宽度；不要强行套用，需针对板卡修改流程。 |
| `JTAG identification did not confirm` | 检查板卡电源、USB、JTAG 排线、驱动、位置，以及是否有其他程序占用下载器。 |
| `Programming failed or was not confirmed` | 保持外部驱动关闭，查看 `ise_generic_program.log`；Flash 内容可能已改变。 |

日志位于工程目录：`ise_generic_build.log`（编译）、`ise_generic_promgen.log`（MCS 生成）、`ise_generic_identify.log`（JTAG 识别）、`ise_generic_program.log`（编程与校验）。并非每次运行都会产生或更新所有日志；查看修改时间，避免把旧日志当成本次结果。

已在 Spartan-6 XC6SLX16 与 W25Q128BV SPI x1 板卡上测试 Flash 编程与校验；其他板卡尚未验证，仍需检查日志及断电重启后的输出。
