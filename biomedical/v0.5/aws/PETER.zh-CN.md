---
title: 对，真实T01实验应该运行peter()
subtitle: 我刚才把参考分析讲成了任务入口，造成了混淆
lang: zh
template: doc
theme: blueprint
---
## A 你要看的是真实实验这条路径
```flow LR
[T01数据与三条prompt] -> [peter调用真实模型]
[peter调用真实模型] -> [模型生成并执行R代码]
[模型生成并执行R代码] -> [保存轨迹与分析结果]
```
A1目前确实调用peter()，位置在shared/runner.R。
任务入口应让这件事一眼可见。
现在它藏在共享调度层中，目录表达仍不够清楚。

下面只展示核心逻辑，省略环境配置与测量：
```r title="T01真实实验 · 示意"
prompts = jsonlite::read_json("prompts.json")$T01
s = peter(prompt = prompts[[1]], model = "codex/gpt-6.1-sol",
          envir = home, mode = "auto")
peter(s, prompt = prompts[[2]])
peter(s, prompt = prompts[[3]])
```
home是预先载入raw数据的R环境。
三轮使用同一个会话，模型自行决定分析代码。

## B 我刚才整理的是另一条路径
| 文件或实验组 | 实际作用 |
|---|---|
| A1：peter与真实模型 | 测量真实智能体如何完成T01 |
| C1：原生Codex | 用同样的prompt完成T01，作为真实模型对照 |
| t01-analysis.R | 人工写好的参考计算，用于离线对照 |
| A2：peter与fake provider | 执行参考代码或已捕获轨迹，不请求真实模型 |
| C2、C3 | 以不同R进程方式执行参考代码 |
| t01-check.R | 核对最终科学产物 |

```callout warn 参考分析不是模型的现场答案
A1不会直接执行t01-analysis.R作为答案。
刚才的离线测试通过，也不代表真实模型完成了实验。
```

## C 目录还需要表达清楚这层区别
```tree
更清楚的职责划分（建议，尚未改动）
  真实实验入口 | 读取prompt，调用peter或Codex，保存轨迹
  reference/ | 人工参考分析，用于离线对照
  checks/ | 最终科学结果核对
  prepare/ | 数据准备与哈希
```
我之前主要整理了参考代码，没有把真实入口变得直观。
你指出的是入口设计问题，不是你误解了peter。

[查看当前peter调用位置](shared/runner.R) · [查看共用prompt](prompts.json)
