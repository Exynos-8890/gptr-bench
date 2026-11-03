# 从10个任务扩到30个：20个新增任务与一手来源

报告版本：1.0。核验UTC：2026-10-31T07:47:40+00:00。

## 结论和计数口径

建议先完成30个科学任务，保留50个作为下一阶段目标。下面20项是新增设计，尚未实现或运行。三轮请求是每项任务内部的阶段，不另算三个任务；随机种子、阈值变化和同一轨迹重放也不新增任务数。

当前20项并非20个全新独立队列：METABRIC、TCGA-LUAD、GB1、MTBLS90和GSE236581沿用现有研究家族；同时新增甲基化、微生物、CRISPR/药敏、免疫受体、sQTL、剪接扰动、药物转录扰动和时间序列来源。报告必须同时列“任务数”和“数据家族/研究队列数”，按数据家族做分组汇总与不确定性分析，不能把共享队列的任务当独立复现。

## 与参考论文的关系

[作者官方BiomniBench-DA页面](https://huggingface.co/datasets/phylobio/BiomniBench-DA)明确公开50个任务、总任务数100个，当前展示文件总量82.9GB。此值是整个公开仓库总文件量，不是某一个任务的输入，更不是单任务RAM。文件仍要求登录并接受信息分享条件；本次未接受或绕过。参考的是多步真实科研问题和过程校验，不冒充已经取得作者全部50个任务包。

## 新增任务总览

所有内存区间都是16GiB单机、单任务、单进程为主的未测规划。最终能否纳入需跑完整工作流、序列化及检查器的峰值。不为了占满内存填充数据；输入与读取GB均待逐文件冻结和I/O探针核实。

| ID | 新任务 | 科研终点 | 规划内存GiB（未测） | 规划实质R块（不是实测function call） |
|---|---|---|---:|---:|
|T11|单细胞谱系内伪bulk差异表达|复用T01队列，科研目标从细胞组成改为细胞内表达变化|6–10|26|
|T12|乳腺癌表达分型与稳定性|复用T02研究队列，但新增表达输入与非生存科研目标|4–8|24|
|T13|拷贝数剂量与基因表达耦合|同METABRIC队列；新增跨组学输入和剂量效应目标|4–8|24|
|T14|体细胞突变共现与互斥|同METABRIC队列；新增突变输入，终点为基因对关系|2–4|24|
|T15|肺癌共表达模块与临床关联|复用T03输入，但研究终点从基因差异改为模块结构|4–8|26|
|T16|GB1适应度景观的上位性分解|复用T07完整实测GB1；终点为可检验非加性而非候选预测|2–4|24|
|T17|代谢物差异效应与相关模块|复用T09；终点从分类预测改为代谢物效应与模块|2–4|22|
|T18|全血甲基化与年龄关联|新增甲基化研究队列；不把所有探针同时复制多份|6–10|26|
|T19|血细胞甲基化标记与供者外验证|新增分选血细胞队列，与T18不共享受试者|4–8|24|
|T20|结直肠癌微生物差异丰度|新增微生物研究家族；与T21复用队列但统计目标不同|2–4|24|
|T21|微生物标记的跨队列泛化|与T20相关但独立目标是跨队列预测泛化|2–4|26|
|T22|CRISPR谱系选择性依赖|新增CRISPR数据家族；与T23/T24/T25共享细胞系家族|4–8|24|
|T23|突变背景下的依赖关联|复用CRISPR家族；目标为突变—基因依赖关联而非谱系差异|4–8|26|
|T24|CRISPR共必需性模块|复用CRISPR家族；目标为基因网络/模块而非T22/T23组间效应|4–8|26|
|T25|药物敏感性的基因组关联与预测|同细胞系家族但新增药物响应模态和研究终点|4–8|28|
|T26|TCR抗原特异性与收敛基序|新增免疫受体家族；不使用GPU模型或全长结构预测|2–4|24|
|T27|人类剪接数量性状位点|新增表达—基因型配对家族；与T04同祖源项目但个体ID重叠需记录|4–8|28|
|T28|RNA结合蛋白敲低的差异外显子使用|新增果蝇扰动队列；终点为外显子使用而非仅基因表达|2–4|26|
|T29|糖皮质激素的供者配对转录反应|新增药物扰动研究；不与T03肺癌病例对照队列合并|2–4|24|
|T30|细胞周期转录振荡与跨实验相位复现|新增酵母时间序列家族；终点为周期/相位而非病例组差异|2–4|26|

## 可直接转为候选任务注册表的结构

每项三阶段都需要保留中间产物和独立数值检查；具体统计设计必须在任务冻结前审定。标记为条件候选的任务先核实访问与字段，再进入实现；不以门户说明代替实际下载测试。

```json
[
  {
    "id": "T11",
    "name": "单细胞谱系内伪bulk差异表达",
    "dataset_family": "single",
    "source_url": "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE236581",
    "data_scope": "GSE236581，同T01的真实子集和全部基因",
    "reuse_policy": "复用T01队列，科研目标从细胞组成改为细胞内表达变化",
    "requests": [
      "按患者×组织×时点×谱系汇总真实计数并审计重复单位",
      "在有配对的患者内拟合表达差异并作通路检验",
      "留一患者与低表达过滤敏感性，报告效应及局限"
    ],
    "artifacts": [
      "pseudobulk-counts.csv",
      "paired-expression.csv",
      "pathway-effects.csv",
      "patient-leaveout.csv"
    ],
    "working_memory_gib_estimate": [
      6,
      10
    ],
    "reference_r_blocks_planned": 26,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "来源和现有输入已知；25万细胞矩阵仍待准备"
  },
  {
    "id": "T12",
    "name": "乳腺癌表达分型与稳定性",
    "dataset_family": "metabric",
    "source_url": "https://github.com/cBioPortal/datahub/tree/master/public/brca_metabric",
    "data_scope": "METABRIC表达矩阵、临床样本表、已有分型标签",
    "reuse_policy": "复用T02研究队列，但新增表达输入与非生存科研目标",
    "requests": [
      "对齐表达和样本，按无标签规则选变异基因",
      "无监督聚类并用独立保留的分型标签评价一致性",
      "患者重采样和特征选择稳定性，输出可复现分型证据"
    ],
    "artifacts": [
      "sample-expression-audit.csv",
      "clusters.csv",
      "subtype-concordance.csv",
      "cluster-stability.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方目录确认表达文件存在；下载清单、重叠样本数待冻结"
  },
  {
    "id": "T13",
    "name": "拷贝数剂量与基因表达耦合",
    "dataset_family": "metabric",
    "source_url": "https://github.com/cBioPortal/datahub/tree/master/public/brca_metabric",
    "data_scope": "METABRIC data_cna.txt与data_mrna_illumina_microarray.txt",
    "reuse_policy": "同METABRIC队列；新增跨组学输入和剂量效应目标",
    "requests": [
      "统一基因与样本ID，审计缺失和拷贝数分层",
      "计算基因拷贝数与表达的剂量关系并控制分型",
      "在保留样本复核效应及缺失/亚型敏感性"
    ],
    "artifacts": [
      "cna-expression-alignment.csv",
      "dosage-effects.csv",
      "subtype-adjusted-effects.csv",
      "heldout-effects.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方目录确认两种文件存在；具体文件尺寸待核实"
  },
  {
    "id": "T14",
    "name": "体细胞突变共现与互斥",
    "dataset_family": "metabric",
    "source_url": "https://github.com/cBioPortal/datahub/tree/master/public/brca_metabric",
    "data_scope": "METABRIC data_mutations.txt与临床分型表",
    "reuse_policy": "同METABRIC队列；新增突变输入，终点为基因对关系",
    "requests": [
      "按覆盖面和预先规定频率规则构建患者×基因事件矩阵",
      "分析共现/互斥，控制事件负担和分型并校正多重检验",
      "重采样验证基因对与混杂敏感性，输出网络及证据"
    ],
    "artifacts": [
      "mutation-audit.csv",
      "pair-associations.csv",
      "burden-adjusted-pairs.csv",
      "pair-stability.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方目录确认突变和临床表存在；基因面板与病例覆盖待审计"
  },
  {
    "id": "T15",
    "name": "肺癌共表达模块与临床关联",
    "dataset_family": "luad",
    "source_url": "https://portal.gdc.cancer.gov/projects/TCGA-LUAD",
    "data_scope": "TCGA-LUAD，已有576样本计数和临床信息",
    "reuse_policy": "复用T03输入，但研究终点从基因差异改为模块结构",
    "requests": [
      "归一化并按预先规则筛高变异基因，审计批次",
      "构建分块共表达网络和模块特征，检验临床关联",
      "留批次/患者重采样与模块富集，报告稳定模块"
    ],
    "artifacts": [
      "network-input-audit.csv",
      "gene-modules.csv",
      "module-trait-effects.csv",
      "module-stability.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 26,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "现有计数输入已准备；具体临床变量和网络筛选上限待冻结"
  },
  {
    "id": "T16",
    "name": "GB1适应度景观的上位性分解",
    "dataset_family": "protein",
    "source_url": "https://raw.githubusercontent.com/OATML-Markslab/ProteinGym/main/reference_files/DMS_substitutions.csv",
    "data_scope": "ProteinGym的GB1真实组合突变适应度",
    "reuse_policy": "复用T07完整实测GB1；终点为可检验非加性而非候选预测",
    "requests": [
      "对齐野生型、单突变与组合突变，核对适应度尺度",
      "估计加性基线和成对/高阶上位性，并报告位点效应",
      "在保留组合和重采样中检验分解误差及可达适应路径"
    ],
    "artifacts": [
      "variant-effect-audit.csv",
      "epistasis.csv",
      "heldout-decomposition.csv",
      "accessible-paths.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方ProteinGym参考清单已核实；现有GB1输入可复用，缺失单突变处理须冻结"
  },
  {
    "id": "T17",
    "name": "代谢物差异效应与相关模块",
    "dataset_family": "metabolite",
    "source_url": "https://www.ebi.ac.uk/metabolights/MTBLS90",
    "data_scope": "MTBLS90真实代谢矩阵和受试者元数据",
    "reuse_policy": "复用T09；终点从分类预测改为代谢物效应与模块",
    "requests": [
      "检查缺失、变换和受试者协变量，保留真实观测",
      "估计协变量调整的代谢物效应及相关模块并校正多重检验",
      "插补/完整病例、重采样和模块稳健性分析"
    ],
    "artifacts": [
      "metabolite-audit.csv",
      "adjusted-effects.csv",
      "metabolite-modules.csv",
      "robustness.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 22,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "研究入口与已有任务已知；源站JS展示，具体变量与矩阵沿用本地准备清单"
  },
  {
    "id": "T18",
    "name": "全血甲基化与年龄关联",
    "dataset_family": "aging",
    "source_url": "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE40279",
    "data_scope": "GSE40279，候选全血450K甲基化与年龄元数据",
    "reuse_policy": "新增甲基化研究队列；不把所有探针同时复制多份",
    "requests": [
      "核对探针、样本、年龄和批次，按固定QC排除无效探针",
      "分块拟合年龄关联与可用协变量，校正多重检验",
      "性别/批次和留组验证，给出可复核年龄相关位点与效应"
    ],
    "artifacts": [
      "methylation-audit.csv",
      "age-effects.csv",
      "age-cpg-replication.csv",
      "confounder-sensitivity.csv"
    ],
    "working_memory_gib_estimate": [
      6,
      10
    ],
    "reference_r_blocks_planned": 26,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "条件候选：GEO当前验证码/直接目录访问失败；正式纳入前必须核对文件清单和元数据；不声称已下载"
  },
  {
    "id": "T19",
    "name": "血细胞甲基化标记与供者外验证",
    "dataset_family": "blood",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/FlowSorted.Blood.450k.html",
    "data_scope": "FlowSorted.Blood.450k真实分选血细胞450K数据",
    "reuse_policy": "新增分选血细胞队列，与T18不共享受试者",
    "requests": [
      "核对供者和细胞类型，进行固定甲基化预处理",
      "选择细胞类型标记并构建可解释参考签名",
      "按供者留出验证签名区分能力与标记稳定性"
    ],
    "artifacts": [
      "donor-celltype-audit.csv",
      "celltype-cpg-markers.csv",
      "donor-heldout-predictions.csv",
      "signature-stability.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方数据包确认提供450K原始数据对象及细胞类型相关CpG；供者数/具体处理对象待清单确认"
  },
  {
    "id": "T20",
    "name": "结直肠癌微生物差异丰度",
    "dataset_family": "microbe",
    "source_url": "https://waldronlab.io/curatedMetagenomicDataAnalyses/articles/MLdatasets.html",
    "data_scope": "curatedMetagenomicData，预选ZellerG_2014/FengQ_2015相对丰度和元数据",
    "reuse_policy": "新增微生物研究家族；与T21复用队列但统计目标不同",
    "requests": [
      "对齐两队列的物种与宿主变量，审计零值和组成效应",
      "队列内估计混杂调整的物种效应，再汇总方向与异质性",
      "不同零值处理与可用协变量敏感性，输出复核效应"
    ],
    "artifacts": [
      "microbiome-cohort-audit.csv",
      "species-effects.csv",
      "cross-cohort-effects.csv",
      "compositional-sensitivity.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "维护者分析站明确列出上述CRC研究；具体资源日期与字节数待冻结，不把相对丰度伪装原始计数"
  },
  {
    "id": "T21",
    "name": "微生物标记的跨队列泛化",
    "dataset_family": "microbe",
    "source_url": "https://waldronlab.io/curatedMetagenomicDataAnalyses/articles/MLdatasets.html",
    "data_scope": "同T20，固定研究队列、疾病定义与元数据",
    "reuse_policy": "与T20相关但独立目标是跨队列预测泛化",
    "requests": [
      "以整队列留出划分训练/验证，训练内完成变换和特征选择",
      "拟合稀疏分类器并只用训练内CV调参",
      "在外部队列评价判别/校准、疾病比例变化与站点敏感性"
    ],
    "artifacts": [
      "cohort-splits.csv",
      "training-only-features.csv",
      "external-predictions.csv",
      "calibration.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 26,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "处理数据目录公开；队列标签、研究许可与是否存在重叠受试者待验证"
  },
  {
    "id": "T22",
    "name": "CRISPR谱系选择性依赖",
    "dataset_family": "depmap",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/depmap.html",
    "data_scope": "固定一版DepMap基因效应矩阵、细胞系谱系元数据",
    "reuse_policy": "新增CRISPR数据家族；与T23/T24/T25共享细胞系家族",
    "requests": [
      "对齐细胞系与基因效应并审计谱系、批次和缺失",
      "估计谱系选择性基因依赖与泛必需基因背景",
      "在保留细胞系和重采样中验证选择性与效应"
    ],
    "artifacts": [
      "cell-line-audit.csv",
      "lineage-dependencies.csv",
      "common-essential-background.csv",
      "heldout-selectivity.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "条件候选：官方包确认公开处理类型，但DepMap门户当前人机验证；不声称源CSV已可无凭据直下"
  },
  {
    "id": "T23",
    "name": "突变背景下的依赖关联",
    "dataset_family": "depmap",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/depmap.html",
    "data_scope": "同版DepMap基因效应、mutation calls与细胞系元数据",
    "reuse_policy": "复用CRISPR家族；目标为突变—基因依赖关联而非谱系差异",
    "requests": [
      "构建可追溯突变状态并审计谱系混杂、阳性组规模",
      "在预先定义候选关系/频率规则下估计依赖差异并控制谱系",
      "按谱系保留验证与标签置换，报告候选合成致死关联"
    ],
    "artifacts": [
      "mutation-dependency-audit.csv",
      "conditional-dependencies.csv",
      "lineage-heldout-effects.csv",
      "permutation-calibration.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 26,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "条件候选，同T22；只称关联候选，不把观察数据称为已验证合成致死机制"
  },
  {
    "id": "T24",
    "name": "CRISPR共必需性模块",
    "dataset_family": "depmap",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/depmap.html",
    "data_scope": "同版DepMap基因效应矩阵，全部合格细胞系",
    "reuse_policy": "复用CRISPR家族；目标为基因网络/模块而非T22/T23组间效应",
    "requests": [
      "按无结果标签规则筛适用基因，移除谱系共同趋势",
      "分块计算残差依赖相关并构建共必需性网络/模块",
      "保留细胞系评估模块稳定性和随机网络对照"
    ],
    "artifacts": [
      "coessentiality-input-audit.csv",
      "coessentiality-edges.csv",
      "gene-modules.csv",
      "module-validation.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 26,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "条件候选，同T22；基因数上限是预先声明的分析规则，不声称全基因两两检验已跑完"
  },
  {
    "id": "T25",
    "name": "药物敏感性的基因组关联与预测",
    "dataset_family": "depmap",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/depmap.html",
    "data_scope": "固定DepMap drug_dependency、基因表达/突变与细胞系元数据",
    "reuse_policy": "同细胞系家族但新增药物响应模态和研究终点",
    "requests": [
      "按药物和细胞系对齐实测响应，审计浓度/批次及缺失",
      "估计突变/表达与药敏关联，训练内调参建立响应模型",
      "整谱系留出评价响应预测、校准与药物间异质性"
    ],
    "artifacts": [
      "drug-response-audit.csv",
      "genomic-drug-associations.csv",
      "lineage-heldout-predictions.csv",
      "drug-calibration.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 28,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "条件候选：数据包说明19Q3起提供drug_dependency；具体可用发布版、字段与资源访问待核实"
  },
  {
    "id": "T26",
    "name": "TCR抗原特异性与收敛基序",
    "dataset_family": "tcr",
    "source_url": "https://github.com/antigenomics/vdjdb-db",
    "data_scope": "VDJdb固定日期发布，TCR序列、抗原/MHC和来源研究字段",
    "reuse_policy": "新增免疫受体家族；不使用GPU模型或全长结构预测",
    "requests": [
      "去重并保留来源研究，统一CDR3、V/J与HLA注释",
      "在固定抗原组内计算基序、收敛性并构造匹配背景",
      "按研究留出/置换验证基序，报告HLA和证据等级敏感性"
    ],
    "artifacts": [
      "receptor-provenance.csv",
      "epitope-motifs.csv",
      "study-heldout-motifs.csv",
      "hla-sensitivity.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "维护者GitHub确认公开发布和记录语义；具体发行文件、大小和固定版本待冻结"
  },
  {
    "id": "T27",
    "name": "人类剪接数量性状位点",
    "dataset_family": "qtl",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/GeuvadisTranscriptExpr.html",
    "data_scope": "GeuvadisTranscriptExpr，GEUVADIS CEU个体chr19转录本表达和双等位基因型",
    "reuse_policy": "新增表达—基因型配对家族；与T04同祖源项目但个体ID重叠需记录",
    "requests": [
      "对齐受试者、基因型与转录本，审计等位基因、表达与群体变量",
      "在明确cis窗口检验基因型与转录本使用比例的关联",
      "受试者置换与表达过滤稳健性，报告sQTL候选和校准"
    ],
    "artifacts": [
      "qtl-sample-allele-audit.csv",
      "cis-sqtl.csv",
      "permutation-fdr.csv",
      "isoform-sensitivity.csv"
    ],
    "working_memory_gib_estimate": [
      4,
      8
    ],
    "reference_r_blocks_planned": 28,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方包明确只有chr19与CEU；这是公开数据包原有范围，不冒充全基因组或全部GEUVADIS人群"
  },
  {
    "id": "T28",
    "name": "RNA结合蛋白敲低的差异外显子使用",
    "dataset_family": "pasilla",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/pasilla.html",
    "data_scope": "pasilla真实每基因/每外显子RNA-seq计数",
    "reuse_policy": "新增果蝇扰动队列；终点为外显子使用而非仅基因表达",
    "requests": [
      "对齐外显子、基因与敲低设计，审计文库类型和计数",
      "拟合外显子×条件交互并在基因内/跨基因控制多重检验",
      "覆盖度过滤与基因总表达敏感性，核对事件图和效应"
    ],
    "artifacts": [
      "exon-design-audit.csv",
      "differential-exon-usage.csv",
      "gene-level-adjustment.csv",
      "exon-sensitivity.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 26,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方包确认真实RNAi敲低数据和基因/外显子计数；具体样本数、尺寸以冻结对象为准"
  },
  {
    "id": "T29",
    "name": "糖皮质激素的供者配对转录反应",
    "dataset_family": "airway",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/airway.html",
    "data_scope": "airway/GSE52778，四个人气道平滑肌细胞系的处理/对照计数",
    "reuse_policy": "新增药物扰动研究；不与T03肺癌病例对照队列合并",
    "requests": [
      "审计四细胞系的配对设计、处理和表达质量",
      "估计供者内药物表达反应与预先声明通路效应",
      "留一细胞系重算，检验反应方向和通路稳健性"
    ],
    "artifacts": [
      "paired-drug-design.csv",
      "drug-response-expression.csv",
      "pathway-response.csv",
      "donor-leaveout.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 24,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方包确认四细胞系和dexamethasone处理；全原始基因计数可取，不导入FASTQ"
  },
  {
    "id": "T30",
    "name": "细胞周期转录振荡与跨实验相位复现",
    "dataset_family": "yeast",
    "source_url": "https://bioconductor.org/packages/release/data/experiment/html/yeastCC.html",
    "data_scope": "yeastCC，Spellman及Pramila/Breeden真实时间序列微阵列",
    "reuse_policy": "新增酵母时间序列家族；终点为周期/相位而非病例组差异",
    "requests": [
      "对齐同步实验、采样时间和基因，审计缺失与尺度",
      "拟合周期回归/谐波模型，校正多重检验并估计相位",
      "在独立同步实验验证周期和相位，置换检验及时间间隔敏感性"
    ],
    "artifacts": [
      "time-series-audit.csv",
      "periodic-genes.csv",
      "phase-replication.csv",
      "time-permutation.csv"
    ],
    "working_memory_gib_estimate": [
      2,
      4
    ],
    "reference_r_blocks_planned": 26,
    "input_size": "待清单核实",
    "read_gb": "待准备文件和I/O探针核实",
    "implementation_status": "新增任务，未实现/未运行",
    "access_status": "官方包确认来自两组真实细胞周期研究；具体时间点和矩阵字节待冻结"
  }
]
```

## 访问、来源与实现约束

- 甲基化GSE40279：本次GEO显示验证码，直接FTP列表未由浏览工具取到。该项明确为条件候选；不能声称已验证完整656样本矩阵或下载字节数。若无法取得公开处理数据，应替换为来源可核实的队列，不伪造数据。
- DepMap：官方[数据包说明](https://bioconductor.org/packages/release/data/experiment/html/depmap.html)确认CRISPR、RNAi、表达、拷贝数、突变、药物依赖等处理数据类型；当前门户有人机验证。应先核实固定发布版的源文件清单。现版depmap包Imports含httr2，不能把该包加入gptr或作为网络桥接；固定CSV/资源由现有curl取用并转为普通R输入。
- 微生物组：[维护者的研究清单与导出说明](https://waldronlab.io/curatedMetagenomicDataAnalyses/articles/MLdatasets.html)列出CRC研究及CSV.gz导出；[原项目](https://github.com/waldronlab/curatedMetagenomicData)区分species相对丰度、基因家族、通路等对象。只取目标处理模态。相对丰度乘深度所得数值不是新生成的原始实测计数，不能混称。
- METABRIC：[官方目录](https://github.com/cBioPortal/datahub/tree/master/public/brca_metabric)实际列出data_cna.txt、data_mutations.txt、data_mrna_illumina_microarray.txt和临床表；具体基因/样本重叠及版本需冻结。
- GEUVADIS：[官方数据包](https://bioconductor.org/packages/release/data/experiment/html/GeuvadisTranscriptExpr.html)仅CEU个体chr19；[原研究家族入口](https://www.internationalgenome.org/data-portal/data-collection/geuvadis)描述更大RNA-seq集合。不能把小包范围写成全基因组任务。
- [VDJdb维护者仓库](https://github.com/antigenomics/vdjdb-db)说明每条观测包含受体、peptide-MHC及实验证据、来源研究；任务必须按来源研究划分，避免重复受体/重复研究泄漏。
- [pasilla](https://bioconductor.org/packages/release/data/experiment/html/pasilla.html)、[airway](https://bioconductor.org/packages/release/data/experiment/html/airway.html)、[yeastCC](https://bioconductor.org/packages/release/data/experiment/html/yeastCC.html)来自真实研究而非模拟；它们的公开处理输入相对小，作用是覆盖剪接、配对药物扰动和时间序列，不能宣称这些任务都是“大文件加载压力”。

## 从30到50的边界

20个新增任务的参考R块计划合计502，加现有218为720个规划实质计算块。它们不是已观察到的模型function call数量。50任务可以继续扩展，但应新增约20个科学目标与合格输入/独立检查器，不能只增加重复次数或把每轮请求拆算。建议先按10→20→30逐批验收，数据家族覆盖和内存门槛通过后再扩50。

## Verification log

- 已读作者HF公开卡片，确认公开50/总100、82.9GB和访问条件；未读取受限文件。
- 已读Bioconductor一手数据包说明：airway、pasilla、FlowSorted.Blood.450k、depmap、GeuvadisTranscriptExpr、yeastCC；未安装或下载这些数据包。
- 已读维护者cBioPortal目录、ProteinGym参考CSV、VDJdb仓库及curatedMetagenomicData维护者分析站。
- GEO GSE40279验证码、DepMap门户人机验证、GDC/MetaboLights动态页显示限制已明确记录；相应实际文件访问待核验。
- 本次不运行模型、不创建AWS资源、不把20项候选称作已实现。未编辑主计划或任务注册表。
