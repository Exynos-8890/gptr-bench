# Portable replay — terminal output only

只需保存 [replay.R](replay.R)，在新的 R 进程中运行：

```bash
Rscript --vanilla replay.R
```

**没有参数，不需要指定工作区、包库、GPTR_SOURCE 或输出路径。**

脚本自动从 GitHub 安装 gptr 1.0.1 的固定 commit：
`5e2992b13824fbf5218428d379a336dd44acddbb`。

- 包、下载和 gptr 会话配置使用临时位置，隔离用户自己的 R 包与配置。
- 工作目录由脚本自动选择；不向启动目录写入结果。
- 版本、外层耗时、内部 elapsed、差值和倍数直接打印到终端。
- 不导出 HTML、CSV、trace 或结果日志；运行库内部会话文件随临时目录清理。
- 正常完成或 R 错误退出时，恢复原目录并删除临时工作目录和包库。

安装包仍需要临时磁盘文件；这不是纯内存安装。Rscript 正常退出也会清理其会话临时目录。强制终止进程时，退出清理可能无法执行。

## 实际工具代码

```r
if (!exists("x")) x = NULL; sum(nchar(gsub("[0-9]", "", x)))
```

`x` 是预先在内存生成的 400 万个合成 ID。实际计算为去掉数字，再统计剩余字符数。没有模型请求、API key、Codex CLI、sleep 或人为等待。

下载、安装与数据生成均在工具计时之前。内部 elapsed 包含执行后的处理，不是单独计时的字符串操作。这是合成 MCP 最小复现，不是原始 T03 数据的完整重跑。

需要 R >= 4.2、CRAN/GitHub 网络访问，以及平台所需的 R 包编译依赖。首次准备过程会打印安装信息。脚本使用临时库，因此每次新运行都会重新安装。

Linux 和 macOS 已验证过独立安装流程；Windows 未实测。历史便携版本的测量保留在 [measurements.csv](measurements.csv) 和 [verification.json](verification.json)，这些是已有验证资料，不是脚本每次生成的文件。不同机器的耗时与倍数会变化。

清理版本已在 macOS 完整验证：外层 5.620 秒、内部 2.967 秒、工具错误 FALSE。R 退出码为 0；专用测试临时根目录的剩余条目数为 0。本次验证只打印输出，没有保存新的结果日志。

## 关键测量

| 脚本版本 | 平台 | 外层 | 内部 elapsed | 差值 |
|---|---|---:|---:|---:|
| 便携版，加入退出清理之前 | AWS Linux | 7.836 秒 | 2.762 秒 | 5.074 秒 |
| 便携版，加入退出清理之前 | macOS | 5.461 秒 | 3.185 秒 | 2.276 秒 |
| **当前自动清理版** | **macOS** | **5.620 秒** | **2.967 秒** | **2.653 秒** |

当前自动清理版只在 macOS 完整验证过，尚未在 AWS 重测。前两次的原始终端输出见 [Linux](evidence/linux-before-cleanup.log) 和 [macOS](evidence/macos-before-cleanup.log)。当前版的验证仅保留控制台观察结果，未另存原始日志；verification.json 明确区分两者。
