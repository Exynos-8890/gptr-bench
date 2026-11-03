# v0.5 AWS 16／32 GiB 选型调研

报告版本：2.0。核验UTC：2026-10-31T06:41:06+00:00。
范围：美国东部北弗吉尼亚 `us-east-1`，Linux 按需，共享租户，美元。
本次仅使用公开定价目录和已认证AWS CLI只读接口。未创建、启动或修改AWS资源。

## 建议申请

建议先按 **一台 `r6a.xlarge`，4 vCPU、32 GiB内存、x86_64、200 GiB总量gp3盘** 申请。
`r6a.large`为2 vCPU、16 GiB的省钱备选；能否采用由25万真实细胞全链路内存实测决定。
预算表按一个公网IPv4计费，200 GiB包括系统盘与数据盘，不重复加一份系统盘费用。
32 GiB推荐是为输入、稀疏运算临时对象、R与Codex进程留余量，不能代替父报告中的实际测量。

AWS CLI确认r6a两个规格都是非突发性能、x86_64实例；北弗吉尼亚提供这些类型。区域提供不等于某可用区即时容量保证。
来源：[官方内存机型规格](https://docs.aws.amazon.com/ec2/latest/instancetypes/mo.html)；本地JSON保存`describe-instance-types`及`describe-instance-type-offerings`返回。

## 候选与当前按需价格

| 机型 | vCPU | 内存 | 美元／小时 | 角色 |
|---|---:|---:|---:|---|
| r6a.large | 2 | 16 GiB | 0.11340 | 16GiB备选 |
| r6a.xlarge | 4 | 32 GiB | 0.22680 | 32GiB首选 |
| r6i.large | 2 | 16 GiB | 0.12600 | 同档价格参考 |
| r6i.xlarge | 4 | 32 GiB | 0.25200 | 同档价格参考 |
| r7i.large | 2 | 16 GiB | 0.13230 | 同档价格参考 |
| r7i.xlarge | 4 | 32 GiB | 0.26460 | 同档价格参考 |
| r7a.medium | 1 | 8 GiB | 0.07608 | 8GiB，不符合本轮需求 |
| r7a.large | 2 | 16 GiB | 0.15215 | 同档价格参考 |
| r7a.xlarge | 4 | 32 GiB | 0.30430 | 同档价格参考 |
| r8i.large | 2 | 16 GiB | 0.13892 | 同档价格参考 |
| r8i.xlarge | 4 | 32 GiB | 0.27784 | 同档价格参考 |
| r8i-flex.large | 2 | 16 GiB | 0.13197 | Flex对照，需额外评估持续计算性能 |
| r8i-flex.xlarge | 4 | 32 GiB | 0.26394 | Flex对照，需额外评估持续计算性能 |
| r8a.large | 2 | 16 GiB | 0.15976 | 同档价格参考 |
| r8a.xlarge | 4 | 32 GiB | 0.31952 | 同档价格参考 |

价格来源：[AWS官方Linux按需目录](https://b0.p.awsstatic.com/pricing/2.0/meteredUnitMaps/ec2/USD/current/ec2-ondemand-without-sec-sel/US%20East%20%28N.%20Virginia%29/Linux/index.json)，发布于2026-10-29T17:56:34Z。
对`r6a.large`、`r6a.xlarge`、`r6i.xlarge`、`r7i.xlarge`另外通过AWS CLI Pricing API重新查询，报价逐项一致。
API产品属性明确为Linux、Shared、NA、Used、No License required、OnDemand、`BoxUsage:<机型>`，未混入SAP或专用租户报价。
来源：[AWS CLI Pricing get-products](https://docs.aws.amazon.com/cli/latest/reference/pricing/get-products.html)；[完整本地报价证据](AWS-PRICING-v2.zh-CN.json)。

## 费用：实例＋总计200 GiB gp3＋一个公网IPv4

| 机型 | 100小时 | 168小时／一周 | 730小时／预算月 |
|---|---:|---:|---:|
| r6a.large | $14.03 | $23.57 | $102.43 |
| r6a.xlarge | $25.37 | $42.62 | $185.21 |
| r6i.xlarge | $27.89 | $46.86 | $203.61 |
| r7i.xlarge | $29.15 | $48.97 | $212.81 |

`r6a.xlarge`一周实例费用$38.10，磁盘约$3.68，IPv4约$0.84，合计约$42.62。
可先以$60作为单周AWS运行预算，实际运行时长仍取决于任务与模型响应。
以上不含税、出站流量、快照及模型费用，不代表整个十任务套件已经测得的一周完工成本。

gp3本区域价格为$0.08／GiB月，200 GiB整月$16。CLI Pricing API本次核实SKU `JG3KUJMBRGHV3N8G`。
gp3基础3000 IOPS与125 MiB/s吞吐包含在盘价中，本表未购买额外性能。
EBS费用用730小时作预算折算；正式账单按当月秒数计费，表中磁盘和IPv4保留时间假定与实例运行时间一致。
来源：[AWS EBS定价](https://aws.amazon.com/ebs/pricing/)，本地JSON含区域精确价格返回。

公网IPv4为$0.005／地址小时，使用中和闲置Elastic IP同价。来源：[AWS VPC定价](https://aws.amazon.com/vpc/pricing/)。
实例停止后按需计算费用停止，EBS与保留的Elastic IP仍可能计费。来源：[实例生命周期与计费](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-lifecycle.html)。

## 对读取性能实验的影响

`r6a.large`的实例EBS基线吞吐是81.25 MB/s，`r6a.xlarge`为156.25 MB/s，CLI读取返回已留存。
默认gp3卷的125 MiB/s吞吐还受实例EBS通道约束。AWS读RDS时间必须重新测，不能直接套用本机SSD结果。
新R进程不等于清空操作系统缓存。正式比较应使用同一AWS实例、相同输入与磁盘设置，报告缓存未控制。
200 GiB是初始磁盘容量建议；准备阶段、连续运行及保留产物的磁盘峰值仍需实际检查，不能当成已验证容量上限。

## 可查证记录

- [AWS-PRICING-v2.zh-CN.json](AWS-PRICING-v2.zh-CN.json)：原始产品条目、SKU、价格维度、生效日期、CPU/内存/EBS规格与预算计算。
- CLI只读命令：`aws pricing get-products`、`aws ec2 describe-instance-types`、`aws ec2 describe-instance-type-offerings`，均显式指定`--region us-east-1`。
- 推荐是否能降至16 GiB，等待父报告的25万细胞实测；此调研没有把计划内存区间冒充测量值。
