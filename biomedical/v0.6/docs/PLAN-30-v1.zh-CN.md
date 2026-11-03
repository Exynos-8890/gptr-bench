---
title: 16 GiB主机与30任务扩展方案
subtitle: v0.5.0-draft.3调整输入与主机 · v0.6.0-draft.1规划30任务
更新时间UTC: 2026-10-31T07:49:56Z
lang: zh
template: doc
outline: left
theme: paper
---

## A 结论：先16 GiB，任务扩到30个

```callout ok 一台r6a.large，串行运行30个科研任务
主机改为2 vCPU、16 GiB，按需$0.1134／小时。
先保留现有10项，再增加20个不同科研问题。
50项保留为下一阶段目标。
```

30项可以作为本轮明确的建设目标。
50项也有扩展空间，但会增加数据准备、检查器和真实重复的工作量。
当前新增20项是方案，不是已经实现或跑完的实验。

| 本轮调整 | 具体结果 |
|---|---|
| AWS主机 | 16 GiB的r6a.large；未启动资源 |
| T03 | 从96样本恢复原576样本，给足计算时间 |
| T05 | 全源GWAS优先预检；chr1—3保留为明确标识的回退 |
| 其他七项 | 取消无实测依据的乐观预算，保留原数据范围 |
| 扩展口径 | 30个科学问题，约19类来源家族；不是30个独立队列 |

本轮再次用AWS CLI核实了16 GiB规格及Linux按需价。
[报价证据](../../v0.5/aws/AWS-16G-v3.zh-CN.json)和[官方机型表](https://docs.aws.amazon.com/ec2/latest/instancetypes/mo.html)可查证。

## B 后九项到底有没有被裁小

**确实有两项：T03和T05。** 其余七项在v0.5没有继续裁数据。
上版把五项预算估得偏低，缺少完整真实输入实测支持。
本次修正这些估计，不把预算变化当成已经节省的内存。

| 任务 | v0.5此前是否新裁数据 | 当前处理 | 审慎预算GiB，非完整实测峰值 |
|---|---|---|---:|
| T01 单细胞 | 是，完整队列改为25万目标 | 仍以25万为目标；先过16 GiB门槛 | 8—12 |
| T02 临床生存 | 无；完整2509人 | 保留全部；自然就是小输入 | 2—4 |
| T03 转录组 | 是，576改为96样本 | 恢复576样本、60660基因、1240通路 | 4—8 |
| T04 人群遗传 | 无；原来就选chr22的5000—10000个位点 | 保留原科学范围，预算恢复宽裕 | 4—8 |
| T05 GWAS | 是，全源改为chr1—3 | 流式准备全源八字段，测全流程后决定 | 全源旧预估8—32，能否装入待测 |
| T06 ATAC | 无；仍为两个重复的完整处理后peak | 保留原范围 | 4—8 |
| T07 蛋白候选 | 无；完整GB1的149360变体 | 保留完整assay与稀疏特征 | 4—8 |
| T08 蛋白组 | 无；完整处理后蛋白矩阵 | 保留原范围和科学筛选 | 4—8 |
| T09 代谢组 | 无；完整968人×189代谢物 | 保留完整分析与验证 | 2—4 |
| T10 空间组 | 无；全3813个spot，原设top500分析特征 | 全稀疏输入保留；旧预算上界需实测 | 8—16 |

T03原全量尝试在1800秒后超时，当时采样峰值约3.006 GiB。
它尚未完成，不能把该值当作最终峰值。
已有记录建议把完整任务预算提高到14400秒，保留同一分析流程。
T05的科学QC和全表排序仍放在计时内，流式准备不提前替它做分析。

[逐项源码审计](../../v0.5/aws/SCOPE-16G-AUDIT-v1.zh-CN.md)列出原始限制、行号和测量记录。

## C 16 GiB怎么留余量

```flow LR
16 GiB物理内存 -> 一次只跑一个实验组: 不叠加30项内存
一次只跑一个实验组 -> 完整预检: 含计算、状态保存与检查
完整预检 -> 10 GiB预警: 拟实现的保护阈值
10 GiB预警 -> 11 GiB停止: 保留失败记录
完整预检 -> 系统可用内存至少3 GiB: 不足时更早停止
```

启动重任务前，优先要求至少12 GiB可用内存。
这些门槛已写入方案，尚待实现到新版runner。
T01、T05、T10仍需重点验证，不能先承诺全部全量装得下。

T01先试25万；未过门槛，再用预声明的20万或15万真实子集。
T05先争取全源，失败后保留证据并单独标识染色体子集。
16 GiB方案暂停此前可选的30万细胞加大档。

内存预算是估计，不是必须消耗的配额。
更多任务串行执行，主要增加总运行时间和产物空间。

## D 新增20项：每一项都是不同的科研终点

原T01—T10保留，新增T11—T30如下。
表中内存是未测规划区间；文件大小和读取GB待数据清单冻结。

| ID／新增任务 | 真实数据来源 | 三个科研阶段 | 内存GiB／规划R块 |
|---|---|---|---|
| T11 单细胞谱系内伪bulk差异表达 | [GSE236581](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE236581) | 患者谱系聚合→配对表达差异→留患者验证 | 6—10／26 |
| T12 乳腺癌表达分型与稳定性 | [METABRIC表达](https://github.com/cBioPortal/datahub/tree/master/public/brca_metabric) | 表达对齐→表达分型→重采样稳定性 | 4—8／24 |
| T13 拷贝数剂量与基因表达耦合 | [METABRIC拷贝数＋表达](https://github.com/cBioPortal/datahub/tree/master/public/brca_metabric) | 跨组学对齐→剂量关联→保留样本验证 | 4—8／24 |
| T14 体细胞突变共现与互斥 | [METABRIC突变](https://github.com/cBioPortal/datahub/tree/master/public/brca_metabric) | 突变覆盖审计→共现互斥检验→负荷敏感性 | 2—4／24 |
| T15 肺癌共表达模块与临床关联 | [TCGA-LUAD](https://portal.gdc.cancer.gov/projects/TCGA-LUAD) | 表达规范化→共表达模块→临床与稳定性验证 | 4—8／26 |
| T16 GB1适应度景观的上位性分解 | [ProteinGym GB1](https://raw.githubusercontent.com/OATML-Markslab/ProteinGym/main/reference_files/DMS_substitutions.csv) | 实测景观审计→上位性分解→保留组合验证 | 2—4／24 |
| T17 代谢物差异效应与相关模块 | [MTBLS90](https://www.ebi.ac.uk/metabolights/MTBLS90) | 矩阵审计→差异效应与模块→稳健性验证 | 2—4／22 |
| T18 全血甲基化与年龄关联 | [GSE40279＊](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE40279) | 探针与年龄审计→校正年龄关联→受试者验证 | 6—10／26 |
| T19 血细胞甲基化标记与供者外验证 | [FlowSorted.Blood.450k](https://bioconductor.org/packages/release/data/experiment/html/FlowSorted.Blood.450k.html) | 分选细胞审计→标记构建→供者外验证 | 4—8／24 |
| T20 结直肠癌微生物差异丰度 | [CRC微生物队列](https://waldronlab.io/curatedMetagenomicDataAnalyses/articles/MLdatasets.html) | 丰度单位审计→差异丰度→留队列验证 | 2—4／24 |
| T21 微生物标记的跨队列泛化 | [CRC跨研究队列](https://waldronlab.io/curatedMetagenomicDataAnalyses/articles/MLdatasets.html) | 防止受试者重叠→训练队列调参→新队列校准 | 2—4／26 |
| T22 CRISPR谱系选择性依赖 | [DepMap＊](https://bioconductor.org/packages/release/data/experiment/html/depmap.html) | 依赖矩阵审计→谱系选择性→协变量与重采样 | 4—8／24 |
| T23 突变背景下的依赖关联 | [DepMap＊](https://bioconductor.org/packages/release/data/experiment/html/depmap.html) | 突变依赖对齐→背景关联→谱系外验证 | 4—8／26 |
| T24 CRISPR共必需性模块 | [DepMap＊](https://bioconductor.org/packages/release/data/experiment/html/depmap.html) | 基因范围声明→共必需模块→重采样验证 | 4—8／26 |
| T25 药物敏感性的基因组关联与预测 | [DepMap药敏＊](https://bioconductor.org/packages/release/data/experiment/html/depmap.html) | 药敏组学对齐→关联和调参→保留细胞系验证 | 4—8／28 |
| T26 TCR抗原特异性与收敛基序 | [VDJdb](https://github.com/antigenomics/vdjdb-db) | 序列与克隆审计→抗原基序→供者或克隆外验证 | 2—4／24 |
| T27 人类剪接数量性状位点 | [GEUVADIS chr19／CEU](https://bioconductor.org/packages/release/data/experiment/html/GeuvadisTranscriptExpr.html) | 基因型转录本对齐→剪接QTL→置换与敏感性 | 4—8／28 |
| T28 RNA结合蛋白敲低的差异外显子使用 | [pasilla](https://bioconductor.org/packages/release/data/experiment/html/pasilla.html) | 外显子设计审计→差异使用→过滤与设计验证 | 2—4／26 |
| T29 糖皮质激素的供者配对转录反应 | [airway](https://bioconductor.org/packages/release/data/experiment/html/airway.html) | 供者配对审计→处理效应→通路和留供者验证 | 2—4／24 |
| T30 细胞周期转录振荡与跨实验相位复现 | [yeastCC](https://bioconductor.org/packages/release/data/experiment/html/yeastCC.html) | 时间点审计→周期与相位→跨实验复现 | 2—4／26 |

＊T18及T22—T25仍需核实实际文件访问，现为条件候选。
正式纳入前必须取得可核验的真实输入和固定版本。
T27的数据包原有范围是chr19／CEU，不宣称覆盖全基因组。
[完整任务设计与访问说明](TASK30-SOURCES-v1.zh-CN.md)保留三阶段细节和预期产物。

## E 任务复杂度怎样保持

```flow LR
一个独立科研问题 -> 请求一数据审计: 形成可检查的输入状态
请求一数据审计 -> 请求二核心推断: 拟合、效应与不确定性
请求二核心推断 -> 请求三验证与修改: 稳健性、独立验证与报告
请求三验证与修改 -> 独立数值检查器: 不是只看模型文字答案
```

现有10项共有218个已实现的参考R块。
新增20项规划502块，完成后总计约720块。
这些是实质计算块，不是已经观察到的function-call次数。
真实R调用、CLI工具、模型请求和文件读取次数仍分别记录。

同一数据可以支持不同科研问题。
例如，T02做生存分析，T12做表达分型，T14做突变共现。
它们共享队列，汇总时按来源家族分组，不能当作独立队列复现。
三轮请求、重复运行和随机种子变化不增加任务数。

参考论文作者公开页列出50／100个任务。
其82.9 GB是整个公开仓库文件量，不是单任务内存。
我们借鉴其多步科研与过程检查，不声称已经取得全部受限任务包。
来源：[作者BiomniBench-DA页面](https://huggingface.co/datasets/phylobio/BiomniBench-DA)。

## F 30与50意味着多少次执行

沿用五组、GPT 6.1 SOL／low和原重复规则。
每任务真实A1／C1各3次，标准A2／C2／C3各10次。
每条通过验证且兼容的A1轨迹，再做10次fake回放。

| 科研任务数 | 真实轨迹 | 标准对照执行 | 捕获轨迹回放上限 | 计划有效执行范围 |
|---|---:|---:|---:|---:|
| 10 | 60 | 300 | 300 | 360—660 |
| 30 | 180 | 900 | 900 | 1080—1980 |
| 50 | 300 | 1500 | 1500 | 1800—3300 |

捕获轨迹不兼容时保留原因，不补造回放结果。
表内不含诊断、失败重试和中断尝试，这些另行保留。
真实轨迹数不是模型API调用次数。

16 GiB机型若连续运行一周，按此前200 GiB盘和IPv4约$23.57。
该金额假设磁盘和地址也只保留同样时长，不包含模型费用。
磁盘整月保留另按约$16／月计费；快照费用另算。
30项总耗时尚未测出，不能把一周机费当成全套完工报价。
[计费依据](../../v0.5/aws/AWS-PRICING-v2.zh-CN.json)与[当前AWS与镜像存储方案](../../v0.5/docs/REPORT.zh-CN.html)保留计算口径。

## G 落地顺序与50任务扩展门槛

```timeline v
第一步 | 修正现有十项 | 16 GiB内存保护；恢复T03；预检全源T05
第二步 | 实现新增二十项 | 固定数据、参考分析、独立检查器与离线验证
第三步 | 每类代表任务试跑 | 冻结真实输入、时间预算及读取测量边界
第四步 | 三批正式收集 | 每批十任务，逐任务报告结果与失败
第五步 | 评估扩到五十项 | 完成三十项后，再增加新的科学覆盖
```

当前runner只识别T01—T10，还需要泛化注册与检查器加载。
新增任务尚未写成实现代码，访问待核验项也尚未取得数据。
正式运行前先完成这些工作，并沿用你的逐任务汇报方式。

## H 版本与查证入口

| 位置 | 内容 |
|---|---|
| [v0.5方案](../../v0.5/plan.md) | draft.3：16 GiB、恢复数据范围与门槛 |
| [v0.5任务配置](../../v0.5/tasks.json) | 原十任务，218参考块，主机与预算修订 |
| [v0.6方案](../plan.md) | draft.1：三十任务的设计、实现门槛和计数 |
| [v0.6任务目录](../tasks.json) | 三十项结构化清单；明确已有与待实现 |
| [来源研究](TASK30-SOURCES-v1.zh-CN.md) | 新增二十项的一手来源和完整设计 |
| [数据裁剪审计](../../v0.5/aws/SCOPE-16G-AUDIT-v1.zh-CN.md) | 哪些真的裁过、哪些只是预算变低 |
| [方案核验记录](../../runs/v06-plan-review/validation.json) | 任务计数、引用链接、源码哈希和跨方案检查 |

所有方案有版本号、修改UTC和历史记录。
中文报告和HTML继续Git ignore。
本轮未启动AWS资源、模型调用或正式计算。
