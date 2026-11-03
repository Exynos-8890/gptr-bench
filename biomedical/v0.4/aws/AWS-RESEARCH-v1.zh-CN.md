# AWS 单机存储与费用核实

核实日期：2026-10-31；区域：us-east-1；币种：USD。

[官方区域价格表](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonEC2/current/us-east-1/index.csv)的 gp3 条目生效日期为2026-10-01：容量$0.08/GB-month；额外IOPS为$0.005/IOPS-month；额外吞吐为$0.04/MiB/s-month。吞吐原始单位为$40.96/GiB/s-month，除1024即$0.04。[三个SKU快照](AWS-EBS-PRICING-v1.zh-CN.json)。

建议数据盘2 TiB gp3、3000 IOPS、250 MiB/s；系统盘100 GiB gp3，保持默认性能。gp3自带3000 IOPS和125 MiB/s；250 MiB/s满足0.25 MiB/s/IOPS的比例限制。[官方性能规格](https://docs.aws.amazon.com/ebs/latest/userguide/general-purpose.html)。

上述两盘容量共2148 GiB。月费估算为2148×0.08＋(250−125)×0.04＝$176.84。按30天/月折算，7天$41.26，14天$82.53；这是预留容量费用，与实际写入量不同。

一个公网IPv4为$0.005/小时，即7天$0.84；闲置Elastic IP也收费。[IPv4计价](https://aws.amazon.com/vpc/pricing/)。EC2停止后不收计算费，但EBS持续收费。[实例停止规则](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-lifecycle.html)。

正式计时建议按需实例。Spot可因容量回收而中断，通常只有两分钟通知，会打断长R任务；这是本项目的选型判断。[Spot通知](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-instance-termination-notices.html)。

基础估算不包含模型费用、快照/S3、出网、税费或企业已有网络服务费用。单机若直接联网无需额外NAT网关；若公司要求私有子网，应按公司网络计费补算。[网络计价](https://aws.amazon.com/vpc/pricing/)。

价格页的$0.06吞吐示例没有指定us-east-1，不能替代上述区域SKU报价。内存与核心选型由主报告另行比较；本建议不要求高核心数。

主方案采用x8i.2xlarge，官方Linux按需价$0.87532/小时。[EC2区域价格数据](https://b0.p.awsstatic.com/pricing/2.0/meteredUnitMaps/ec2/USD/current/ec2-ondemand-without-sec-sel/US%20East%20(N.%20Virginia)/Linux/index.json)。按连续开机、上述磁盘、一个IPv4计算，7天约$189.16，14天约$378.31，30天约$810.67；均未含上列额外项目。数据盘250 MiB/s为本项目配置选择，主报告另核对实例持续EBS带宽。
