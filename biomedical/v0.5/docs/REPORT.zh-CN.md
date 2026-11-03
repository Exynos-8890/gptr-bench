---
title: v0.5 · 重新实验计划
subtitle: 待准备与验证 · 三轮用户提示词逐字相同 · 尚未启动新实验
lang: zh
template: doc
theme: paper
outline: left
文档修订: 7（重做方案）
旧金山更新时间: 11月01日 21:23
基于方案: 0.5.0-draft.10
---

## A 目标与比较方法

```callout info 当前状态：准备重做，尚未启动
先完成提示词对齐和发送前验证，再进入新的pilot。
A1与C1的三个完整用户request必须逐字相同。
本页仅保留计划，不展示运行进度或实验结果。
```

本实验比较常驻R会话与普通脚本工作流在连续科研分析中的表现。
首项任务为真实单细胞T01，其余T02—T10按顺序扩展。

| 组别 | 执行方式 | 每项计划重复 |
|---|---|---|
| A1 | 真实模型驱动gptr，保留同一R会话 | 3次 |
| C1 | 真实Codex组织普通R脚本与文件 | 3次 |
| A2 | 固定fake provider驱动实际gptr循环 | 10次 |
| C2 | 每次用户请求新建R，恢复已声明依赖 | 10次 |
| C3 | 单个R进程批量执行同一参考计算 | 10次 |

每项含36次基础尝试。每条兼容A1轨迹另做10次captured回放。
捕获轨迹必须先通过干净状态执行与科学检查，才交给fake provider。

两真实组用户输入一致；框架、工具和状态管理方式作为被比较条件。
真实模型运行与固定参考回放分别统计。

## B 十项真实任务与科学工作

| 任务与代码 | 真实研究数据与规模 | 请求一 | 请求二 | 请求三 | 参考计算块 |
|---|---|---|---|---|---|
| [T01 单细胞](../../tasks/v04/t01.R) | GSE236581；本次重做15万细胞×36027基因 | 质控、患者与细胞谱系组成 | 配对组织比较、1000次患者bootstrap | 纵向变化、质控敏感性与标志物证据 | 20（6／8／6） |
| [T02 临床生存](../../tasks/v04/t02.R) | METABRIC；2509人 | 缺失与生存数据审计、KM曲线 | Cox模型、比例风险与影响诊断 | 敏感性分析、不确定性与研究报告 | 18（5／7／6） |
| [T03 转录组](../../tasks/v04/t03.R) | TCGA-LUAD；576样本×60660基因 | 样本审计、基因过滤、TMM与PCA | edgeR差异表达、通路分析 | 58对患者与过滤方案敏感性分析 | 24（7／10／7） |
| [T04 人群遗传](../../tasks/v04/t04.R) | 1000G；2504人，chr22约5000—10000位点 | 缺失、等位基因频率与群体内HWE | LD筛选、PCA和群体间Fst | LD与质控阈值变化的稳健性 | 22（7／9／6） |
| [T05 GWAS解释](../../tasks/v04/t05.R) | GCST006900真实BMI汇总统计 | 坐标、等位基因与重复审计 | 位点区域、基因映射、Reactome富集 | 区域与映射窗口敏感性、证据解释 | 20（6／8／6） |
| [T06 ATAC调控](../../tasks/v04/t06.R) | ENCODE ENCSR214QZO；两个生物重复 | peak质控、重复一致性与共识区域 | TSS注释、匹配背景与启动子富集 | 窗口与强度筛选敏感性、候选基因 | 20（6／8／6） |
| [T07 蛋白候选](../../tasks/v04/t07.R) | ProteinGym GB1；149360个实测变体 | 序列审计、冻结数据划分、稀疏特征 | 加性与成对模型调参、独立测试 | 多样性约束候选、bootstrap与稳定性 | 24（7／10／7） |
| [T08 蛋白组](../../tasks/v04/t08.R) | PDC000173乳腺癌蛋白矩阵 | 样本、缺失、批次与设计矩阵审计 | limma亚型差异与功能富集 | 缺失处理、蛋白过滤和效应稳定性 | 22（6／9／7） |
| [T09 代谢组](../../tasks/v04/t09.R) | MTBLS90；968人×189代谢物 | 审计、冻结训练与测试、预处理 | 3×3嵌套交叉验证、留出预测与校准 | 20次置换、bootstrap与预处理敏感性 | 24（7／10／7） |
| [T10 空间组](../../tasks/v04/t10.R) | 10x乳腺癌；3813个组织spot | spot质控、变异基因和空间邻接图 | 空间分区、Moran I与199次置换 | 邻域与质控敏感性、分区稳定性 | 24（7／10／7） |



沿用v0.4的科学模块，合计218个参考计算块。
参考块数与模型实际function call分别记录。

本次先重做T01，保留全部36027个基因。
T01按15万真实细胞输入准备；更大档位另行冻结，不混入同一批比较。

## C 对齐方案：两组共用同一组三轮消息

```flow TB
[唯一一份三轮用户消息] -> [发送前逐轮核对UTF8字节与SHA256]
[发送前逐轮核对UTF8字节与SHA256] -> [A1接收相同request1到3]
[发送前逐轮核对UTF8字节与SHA256] -> [C1接收相同request1到3]
```

第一轮中的公共说明也必须一致，不单独追加某一组的执行说明。
消息只使用input.rds和当前工作目录，不插入各组不同的绝对路径。
I/O采样与工具配置由runner处理，不改变用户提示词。

提前声明统计方法；每轮只完成当轮产物，最终报告留在第三轮。
以下是拟采用的完整消息，需落实到runner后再验证。

### Request 1 · 公共说明与质控

```text title="A1与C1共用 Request1 草案"
Analyze genuine GSE236581 sparse counts without dense full-matrix copies. raw contains counts, metadata and
features; metadata columns Patient,Tissue,Treatment,MajorCellType,barcode. Use all supplied observations. Set
seed20261027 for stochastic procedures. Emit unrounded CSVs and patient-level inference, never cell-level
pseudoreplication. Tissue contrast is Tumor minus Normal at time I; longitudinal contrast is Tumor IV minus I.
Immune lineages T,B,Mye,ILC form the immune denominator. Use QC1000UMI/500genes; sensitivity2000/1000. No clinical
response labels exist. Write requested outputs in the current working directory and keep that directory unchanged.
Complete only the analyses and artifacts requested in the current request. The complete artifact list below is the
final contract after request3, not a requirement to finish future requests early. Final required artifacts after
request3 (exact filenames): cell-qc.csv, cohort-audit.csv, patient-audit.csv, patient-composition.csv,
paired-patient-audit.csv, tissue-comparison.csv, statistical-audit.csv, longitudinal.csv,
longitudinal-patient-values.csv, sensitivity.csv, marker-evidence.csv, tissue-composition.png,
longitudinal-composition.png, research-report.md. Required case-sensitive CSV column names (extra columns allowed):
cell-qc.csv: barcode, n_count, n_feature; cohort-audit.csv: n_cells, n_genes, patients, total_umi, nonzero;
patient-audit.csv: Patient, Tissue, Treatment; patient-composition.csv: Patient, Tissue, Treatment, lineage,
n_cells, denominator, proportion; paired-patient-audit.csv: lineage, n_pairs, patients; tissue-comparison.csv:
lineage, n_pairs, estimate, ci_low, ci_high, p_value, fdr; statistical-audit.csv: unit, contrast, denominator, ci,
test, multiplicity; longitudinal.csv: lineage, n_pairs, estimate, ci_low, ci_high, p_value, fdr;
longitudinal-patient-values.csv: Patient, Tissue, Treatment, lineage, n_cells, denominator, proportion;
sensitivity.csv: lineage, n_pairs, estimate, ci_low, ci_high, p_value, setting, fdr; marker-evidence.csv: lineage,
value, gene. Declared input profile: cells-150000. Interpret results only for this supplied cohort/scope; do not
claim full source when subsetted. For all paired contrasts requested in later requests, use the mean patient-paired
difference,1000 patient-bootstrap percentile95%CI, paired Wilcoxon(exactFALSE), and the declared BH correction. The
supplied dataset is input.rds in the current working directory. Reuse raw if already available; otherwise read
input.rds into raw. Do not install packages or access benchmark reference implementations or evaluators.

Check dimensions/IDs; write cell-qc.csv(barcode,n_count,n_feature),
cohort-audit.csv(n_cells,n_genes,patients,total_umi,nonzero), patient-audit.csv and
patient-composition.csv(Patient,Tissue,Treatment,lineage,n_cells,denominator,proportion), including zero lineages
in each observed immune group.
```

### Request 2 · 组织配对分析

```text title="A1与C1共用 Request2 草案"
Use paired patients at I for Normal/Tumor comparison, mean paired proportion difference, 1000 patient-bootstrap
percentile95%CI, paired Wilcoxon(exactFALSE), BH across4lineages. Write
paired-patient-audit.csv(lineage,n_pairs,patients);
tissue-comparison.csv(lineage,n_pairs,estimate,ci_low,ci_high,p_value,fdr); statistical-audit.csv and
tissue-composition.png. No-pair estimates/CI areNA and P=1.
```

### Request 3 · 纵向、敏感性与报告

```text title="A1与C1共用 Request3 草案"
Compute same paired statistics for Tumor I/IV in longitudinal.csv and all timepoint values; compare strictQC and
all-cell denominators in sensitivity.csv with setting. Write marker-evidence.csv for CD3D,CD3E,MS4A1,LYZ,NKG7(mean
all-cell CPM by lineage), longitudinal-composition.png and research-report.md with effects, robustness, source
limits and no unsupported response/causal claims. Output contract for sensitivity.csv: exactly eight rows, four
immune lineages for each of setting=strict_qc (2000 UMI/1000 genes, immune denominator) and
setting=all_cell_denominator (1000 UMI/500 genes, all-cell denominator). Both use Tumor minus Normal at I; apply BH
across these eight P values. Put additional sensitivity combinations in a separate file.
```

发送前要求：三轮消息的字节、长度和SHA256分别一致。
任一轮不同则停止，不启动正式比较。
每次真实尝试保存实际发送文本，不只保存模板。

## D 数据、环境与测量指标

| 配置 | 重做计划 |
|---|---|
| T01真实来源 | GSE236581，分层选择15万细胞，保留全部基因 |
| 输入文件 | input.rds；启动前核对来源、维度和SHA256 |
| 数据处理 | 预处理只整理格式与选取范围，科学计算保留在计时内 |
| 模型 | gpt-6.1-sol，固定low |
| 执行环境 | 一台r6a.large，2 vCPU、16 GiB；数值库线程1；串行 |
| R包 | 安装在准备阶段；每个必需包检查可加载和版本 |
| gptr | 从部署源码加载；保存Git提交及源码摘要 |
| 正式输入 | 各组同一份数据；独立会话与独立工作目录 |

| 指标 | 记录内容 |
|---|---|
| 整轮耗时 | 启动、读取、三轮交互及收尾 |
| 用户请求 | 每轮开始、结束和请求切换 |
| 工具 | R与全部工具的次数、区间、错误及修复 |
| 原始数据读取 | 次数、耗时、文件字节与逻辑读取总量 |
| 状态传递 | RDS保存与恢复次数、耗时及字节 |
| 模型使用 | 记录输入与输出token；费用不可核实则留空 |
| 内存 | 进程树采样RSS、主机可用内存与保护原因 |
| 正确性 | 对实际选定输入重新计算并独立核对产物 |

请求、工具和读取区间可能重叠，不直接相加。
readRDS耗时包含反序列化；未控缓存时不解释为磁盘带宽。
模型生成、通信和调度的合并区间，不直接称为thinking。

## E 执行顺序、资源保护与监督

```flow TB
[落实共用提示词并验证一致] -> [检查依赖与输入]
[检查依赖与输入] -> [五组pilot]
[五组pilot] -> [独立科学复核与读取校准]
[独立科学复核与读取校准] -> [冻结输入源码模型与预算]
[冻结输入源码模型与预算] -> [新目录收集36次基础尝试]
[新目录收集36次基础尝试] -> [兼容轨迹回放]
[兼容轨迹回放] -> [完整性与产物复核后生成新报告]
```

| 准备检查 | 启动条件 |
|---|---|
| 提示词一致性 | A1/C1三轮完整消息逐字相同 |
| 包环境 | 所有必需依赖能加载；保存版本与库路径 |
| 真实输入 | 来源和输入SHA256一致，规模符合选定档位 |
| 资源 | 启动前可用内存至少12 GiB |
| 运行保护 | 树RSS超过11 GiB或主机可用内存低于3 GiB时停止 |
| 冻结 | pilot通过后固定环境、输入、代码、模型与预算 |

新收集开始后，失败、超时、预算中止与不兼容轨迹单独保留。
不通过重跑直至成功的方式替换失败结果。

脚本持续执行和资源保护。Codex按里程碑与异常查看摘要。
观察等待超时后查看同一作业，不自动重启。

日志保留精确时间戳；展示页面使用旧金山时间，精确到分钟。

## F 目录与重跑前待办

| 位置 | 用途 |
|---|---|
| docs/REPORT.zh-CN.html | 当前唯一综合计划页面 |
| docs/REPORT.zh-CN.md | 该页面的可编辑源稿 |
| [plan.md](../plan.md) | 基础科学方案，提示词修订还需同步 |
| [tasks.json](../tasks.json) | 输入档位、任务与输出约定 |
| [run.py](../run.py) | 准备、pilot、冻结与正式运行入口 |
| [科学模块](../../tasks/v04/) | T01—T10的任务与独立检查 |
| [AWS运行手册](../aws/RUNBOOK.md) | 部署与运行命令 |
| [资源保护](../tools/supervise.py) | 内存与超时保护 |

重跑前待办：落实共用消息、移除单组提示追加、增加一致性检查。
随后同步基础方案与版本，完成离线验证，再准备新pilot。
这些代码修改尚未执行；修改文档不代表runner已经修复。

真实数据、运行代码和AWS连接配置保留，避免重新下载和部署。
本次不启动模型调用，不重置Git，不更改AWS实例状态。
