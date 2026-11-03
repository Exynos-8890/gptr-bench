---
title: gptr v0.4 · T02 正式实验报告
subtitle: 正式收集完成，回放兼容性见后文
lang: zh
template: doc
outline: left
theme: paper
实验计划: 0.4.0-draft.4
更新时间UTC: 2026-10-30T23:52:41+00:00
---

## A 当前结论与研究范围

```callout info 正式收集完成，回放兼容性见后文
计划内真实尝试已记录6/6次。
另有可用性补测2次；有效真实试验共6次。
标准执行对照已完成30/30次。
当前全部已记录执行中，36/38次通过检查。
```

本页汇总原始正式记录及同一冻结配置的额度补测，不混入预跑。
真实模型、参考计算和捕获轨迹回放分别统计。
时长中位数只计算通过检查的执行，失败数量同时列出。

## B 数据与实验设计

真实数据来自 METABRIC 乳腺癌队列，共2509位患者、7个变量。
原始公开文件为408387字节的临床文本表。
准备后的 RDS 为173149字节（约0.000173 GB）。
质控后的共同分析队列为1874人，其中1089个死亡事件。
[数据来源与转换记录](../../data/v04/T02/dataset.json) · [本地 RDS](../../data/v04/T02/input.rds)

| 条件 | 冻结内容 |
|---|---|
| 模型与推理 | gpt-6.1-sol / low |
| 数据文件大小 | 173149字节 |
| 并行任务数 | 1 |
| 数据SHA-256 | `14834db35e5b4e84917c47174ff1a38a9914dc73beb81d0a2d2ce35572d40b5f` |

A1使用gptr常驻R会话；C1使用同模型的普通R脚本与文件。
A2经过实际gptr循环回放，C2每轮请求恢复状态，C3批量执行。
三轮请求覆盖数据审计、主要分析和稳健性验证。
[完整清单](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/manifest.json)保留实际数据规模、来源与环境。

## C 分组时长与正确性

| 组别 / 来源 | 通过 / 已执行 | 成功时长中位数（秒） | 成功时长范围（秒） |
|---|---:|---:|---:|
| A1 / live | 3 / 4 | 154.184 | 142.208—175.980 |
| A2 / canonical | 10 / 10 | 11.310 | 11.060—12.637 |
| C1 / live | 3 / 4 | 124.794 | 117.870—135.629 |
| C2 / canonical | 10 / 10 | 3.106 | 3.036—3.388 |
| C3 / canonical | 10 / 10 | 1.427 | 1.371—1.681 |

**真实模型执行：成功时长中位数。**

```chart bar horizontal unit=秒
A1 / live | 154.184
C1 / live | 124.794
```

**计算与回放对照：成功时长中位数。**

```chart bar horizontal unit=秒
A2 / canonical | 11.310
C2 / canonical | 3.106
C3 / canonical | 1.427
```

样本未收齐时，这些数字仅表示当前进度。
少量真实重复只能用于探索性比较，不能直接推断因果。

## D 真实试验的读取与工具调用

| 试验 | 状态 | 原始数据加载次数 | 加载耗时（毫秒） | R执行数 | 全部可见工具数 |
|---|---|---:|---:|---:|---:|
| A1-1 | ok | 1 | 3 | 8 | 20 |
| C1-1 | ok | 4 | 12 | 4 | 9 |
| A1-2 | ok | 1 | 2 | 6 | 14 |
| C1-2 | ok | 4 | 9 | 4 | 9 |
| A1-3 | error | 1 | 2 | 0 | 1 |
| C1-3 | error | 0 | 0 | 0 | 0 |
| A1-4（额度补测） | ok | 1 | 3 | 5 | 15 |
| C1-4（额度补测） | ok | 3 | 8 | 3 | 8 |

RDS读取耗时包含反序列化，不等于纯磁盘传输时间。
R执行数与全部可见工具数是不同指标。
CLI内部未公开的模型轮次、请求次数与美元费用保留为未知。

## E A1三轮请求的完整时间线

选择当前成功试验中的中间一例：A1-2。

![A1请求、R执行与RDS读取的实测时间线](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/A1-2/timeline.png)
[数值记录](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/A1-2/timeline.csv) · [检查结果](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/A1-2/evaluation.json)
请求、工具和读取区间存在重叠，不能直接相加。
图中未归属的时间不能直接解释为纯模型思考。

## F C1三轮请求的完整时间线

选择当前成功试验中的中间一例：C1-2。

![C1请求、R执行与RDS读取的实测时间线](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/C1-2/timeline.png)
[数值记录](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/C1-2/timeline.csv) · [检查结果](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/C1-2/evaluation.json)
请求、工具和读取区间存在重叠，不能直接相加。
图中未归属的时间不能直接解释为纯模型思考。

## G 回放兼容性、失败与查证

三条成功 A1 轨迹均未通过纯 R 回放兼容检查。
其中补测轨迹遗漏由其他工具写出的 research-report.md。
这不改变原始真实运行的正确性，但不能计作有效 fake 回放。
捕获轨迹只有通过干净环境验证，才会转为fake回复。
标准A2与捕获轨迹回放使用不同的来源标签。
- trajectory-1：未通过兼容验证。[记录](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/trajectory-1/compatibility.json)
- trajectory-2：未通过兼容验证。[记录](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/trajectory-2/compatibility.json)
- trajectory-4：未通过兼容验证。[记录](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-quota-retry-1/trajectory-4/compatibility.json)
- A1-3：服务额度阻断，消耗13.629秒。
- C1-3：服务额度阻断，消耗2.148秒。

额度失败与补测均保留。补测未替换原始尝试，也不混入预跑。
[补测及后续回放记录](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-quota-retry-1/results.json)

[逐次统计](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/summary.csv) · [完整结果](/Users/macbook/Documents/Repos/gptr/dev/bench/biomedical/runs/v04-T02-formal-1/T02/results.json)

下载、准备、独立检查和绘图位于正式计时之外。
正式任务完成后，先简报和更新HTML，再进入下一个任务。
