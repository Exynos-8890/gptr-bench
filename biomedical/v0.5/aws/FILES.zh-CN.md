---
title: 代码已精简，AWS环境已就绪
subtitle: 本地与服务器一致 · 版本8f8d29d8 · 未启动真实模型实验
lang: zh
template: doc
theme: blueprint
outline: left
---
## A 当前结果
```callout ok 删除外围保护，直接串行运行
核心运行文件从57个减到44个，删去1469行代码。
本地与AWS的44个文件、27个兼容链接全部一致。
gptr包单独核对，148个源码与资源文件一致。
```

```flow LR
[输入数据SHA256匹配] -> [直接运行任务]
[直接运行任务] -> [保存产物与测量]
[保存产物与测量] -> [科学结果核对]
```

原始数据和历史结果保持原位。
安装环境、下载与准备数据不计入正式实验耗时。
本次真实模型请求数为0。

## B 具体删掉了什么
```chart bar horizontal unit=行
| 整理前 | 现在
主入口run.py | 422 | 234
共享执行模块 | 538 | 209
```

| 已删除 | 现在怎样处理 |
|---|---|
| freeze与多重锁定 | 直接运行pilot或formal |
| 主机、环境、版本反复比对 | 环境准备时确认一次，实验保留版本记录 |
| 独立profile审计进程 | 运行前核对输入SHA256 |
| 内存门槛与监督器 | 不再启动额外内存监督进程 |
| 自定义后台作业状态机 | 长任务直接使用nohup |
| 容量探针与独立读取校准工具 | 不再作为启动前置步骤 |
| 旧调度入口、预检和交付包装 | 使用当前统一入口 |

实验仍记录请求、工具、读取次数、耗时和RSS。
这些是要比较的测量值，不是启动门槛。
每次尝试的时间与token预算继续记录。
科学结果检查器保留，用于判断产物是否满足任务。

## C AWS环境与数据已核对
```flow LR
[4个原始下载文件] -> [SHA256全部匹配]
[15万细胞input.rds] -> [SHA256匹配]
[R与gptr依赖可加载] -> [当前环境检查通过]
[Codex已登录] -> [当前环境检查通过]
[当前环境检查通过] -> [6项离线测试通过]
```

| 项目 | 实际状态 |
|---|---|
| 实例 | 原有r6a.large继续使用 |
| R与Python | R4.3.3；Python3.12.3 |
| gptr与分析依赖 | 可加载，复用实例已有安装 |
| Codex | 0.165.0；已登录 |
| 原始文件 | 四份GSE236581下载文件均匹配记录的哈希 |
| 正式候选输入 | 15万细胞RDS匹配记录的哈希 |
| 云端验收 | 新preflight通过，6项离线测试通过 |
| 实际离线执行 | A2、C2、C3均产生正确的科学产物 |

临时SSH放行已撤销，原访问范围已恢复。
模型登录状态不代表本次已经验证模型服务额度。

## D 现在只需要这样使用
```tree
v0.5/aws/
  run.py | 统一入口，默认T01与15万细胞
  tasks.json | 必需实验配置
  shared/ | 执行、测量与科学检查
  tasks/ | 科研计算
  prepare/、tools/ | 数据下载、转换与真实细胞选取
  setup-linux.sh | 新环境安装
  with-env.sh | 固定运行环境和数值线程
  code.py、links.tsv | 两端源码哈希与兼容路径
```

从AWS的/data/gptr目录运行：
```bash
b=biomedical/v0.5/aws
# 当前环境和输入检查，不调用模型
bash "$b/with-env.sh" python3 "$b/run.py" preflight
# 无真实模型的三个参考执行组
bash "$b/with-env.sh" python3 "$b/run.py" offline
```

新一轮真实实验使用同一入口，无需freeze或重复的live参数：
```bash
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" pilot
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" formal
```

```callout info 当前完成的是代码精简与环境准备
新实验尚未启动。
A1与C1提示词逐字一致的修改仍需完成。
原生R文档录制与回放的benchmark接入仍未实施。
```

[打开精简后的运行入口](run.py) · [运行说明](README.md) · [环境与哈希证据](../../runs/v05-simplification-20261102T184839Z/environment.json) · [服务器验收记录](../../runs/v05-simplification-20261102T184839Z/remote-verification.json)
