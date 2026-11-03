# v0.5前十任务：AWS只读CLI预检与明日部署依据

报告版本：1.0。实测UTC：2026-10-31T08:13:24Z—08:13:30Z。
范围：`us-east-1`、一台`r6a.large`、40 GiB系统盘＋160 GiB数据盘gp3。
本次全部为Get/Describe读取，没有运行创建、启动、修改、删除或DryRun开机操作。
账户ID、ARN和网络资源ID未写入本报告；身份只保留不可逆指纹。
完整脱敏结果：[AWS-PREFLIGHT-RESEARCH-v1.zh-CN.json](AWS-PREFLIGHT-RESEARCH-v1.zh-CN.json)。

## 1. 核验结果

| 检查 | 实际结果 | 结论边界 |
|---|---|---|
| AWS CLI与认证 | CLI 2.35.24；`sts get-caller-identity`退出0 | 当前凭据有效，不证明有创建权限 |
| 机型 | 2vCPU、16384MiB、x86_64、非突发、默认EBS优化 | 与16 GiB方案一致 |
| 区域提供 | r6a.large列在1a／1b／1c／1d／1f | **没有1e**；列表不是即时容量保证 |
| Standard按需配额 | `L-1216C47A`值256vCPU | 配额上限足够容纳一台2vCPU；仍需开机时复核余量 |
| 区域现有实例 | 未列出pending／running／stopping／stopped实例 | 本次区域快照，非全球资源盘点 |
| 默认VPC | 1个 | 无需默认假设必须新建网络 |
| 子网 | 6个默认子网；均available、自动公网IP开启、各4091个可用IPv4 | 五个与r6a.large提供区重合；不可选1e |
| 公网路由 | 1个IGW；1条活动的0.0.0.0/0到IGW默认路由 | 仍需在最终选定子网上复核路由/NACL关联 |
| 安全组 | 3个，含默认组 | 尚未验证当前客户端CIDR入站访问；不等于可SSH |
| SSH密钥对 | 1个现有key pair | 尚未确认本机持有匹配私钥，不依赖它自动可用 |
| Ubuntu镜像 | 官方SSM参数成功，镜像available且属Canonical | 可固定镜像ID；不等于创建权限已通过 |

镜像公共参数：

```text
/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id
```

本次解析为`ami-0d6dd9e8265d48906`，SSM参数版本80。
镜像名`ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20261023`。
架构x86_64，HVM，EBS根设备`/dev/sda1`，创建时间2026-10-23T10:42:34Z。
明日应再查一次并把实际使用的镜像ID／创建日冻结到运行清单，不能只记录浮动`current`别名。
来源：[Canonical官方镜像查找规则](https://ubuntu.com/aws/docs/aws-how-to/instances/find-ubuntu-images/)。

## 2. 本次实际使用的只读CLI类别

- `sts get-caller-identity`：当前身份，报告只保存SHA256短指纹。
- `ec2 describe-instance-types`、`describe-instance-type-offerings`：机型与AZ。
- `service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A`：按需Standard配额。
- `ec2 describe-vpcs`、`describe-subnets`、`describe-security-groups`：现有网络。
- `ec2 describe-route-tables`、`describe-internet-gateways`、`describe-network-acls`：路由与公网条件。
- `ssm get-parameter`、`ec2 describe-images`：镜像别名、架构、所有者和根设备。
- `ec2 describe-key-pairs`、`describe-instances`：密钥元数据计数和实例状态计数。

所有命令显式使用`--region us-east-1 --output json --no-cli-pager`。
全部退出0；记录中保留检查时间和操作名，没有保存任意原始stderr或凭据。

## 3. 明日需要的最小AWS流程

1. 明确获准开始计费后，复查上述快照；从1a／1b／1c／1d／1f中选有提供且网络有效的子网。
2. 选一台按需Linux r6a.large，固定上述或复核后的Canonical Ubuntu 24.04 amd64镜像。
3. 选择本机确实持有匹配私钥的key pair；否则先准备公钥导入方案，不生成或传播私钥。
4. 为本实验使用最小安全组：SSH TCP22仅允许当时用户/公司出口CIDR，不能使用0.0.0.0/0；允许必要的出站HTTPS等下载流量。
5. 系统40 GiB、数据160 GiB，均gp3；自动公网IPv4。该单机流程无需新建NAT Gateway、负载均衡器或固定Elastic IP。
6. 创建后确认EC2状态检查、两个卷、文件系统与挂载均正常，再安装Linux版R与依赖、Codex和Python环境并冻结版本。
7. 导入代码和数据后核对哈希，运行离线验收；T01/T05/T10先经过16 GiB完整流程门槛，再进入真实模型/正式收集。

默认VPC/子网可以已有公网条件，但可能被账户维护者改过，因此实际选择后仍要看关联路由、安全组与NACL。
依据：[AWS默认VPC网络说明](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-vpc.html)、[默认子网](https://docs.aws.amazon.com/vpc/latest/userguide/default-subnet.html)。
SSH来源限制与“默认安全组不等于可SSH”依据：[AWS安全组说明](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)。

## 4. 权限、容量和DryRun不能混为一谈

当前所有Describe/Get成功，只能证明这些读取权限有效。`ec2:RunInstances`、卷、标签、网络等写入权限本次没有实际验证，也不应靠尝试真实开机来验证。

官方RunInstances的`DryRun=true`只做所需权限检查，正常权限成功回执是错误码`DryRunOperation`，缺权限是`UnauthorizedOperation`；它不是实例已经创建，也不能证明即时容量、系统就绪或实验可完成。本次没有做DryRun，因为尚未固定开机请求的子网、安全组和SSH选择，也没有必要猜这些参数。

Standard配额按vCPU和区域计算。当前查询上限256、实例列表未见活动实例，对一台2vCPU候选没有发现明显配额阻塞；这仍是本次读取时点，不承诺明日无并发变化。
依据：[AWS按需机型配额](https://docs.aws.amazon.com/ec2/latest/instancetypes/ec2-instance-quotas.html)、[RunInstances与DryRun契约](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RunInstances.html)。

## 5. 停机、数据与镜像

短期不用：任务结束、结果写盘后正常Stop。EBS上的系统环境和数据保留；普通Stop会丢失RAM，自动公网IPv4通常释放，Start时重新分配。计算费停止，但保留EBS、快照或Elastic IP仍可能计费。

长期不用：先做AMI与磁盘快照并验证可恢复，再按单独授权释放实例／卷；不能把Terminate当成Stop。AMI必须检查系统盘及数据盘的映射覆盖。恢复后先完成卷初始化，再进行正式数据加载测量，避免把快照块恢复延迟算入A1/C1加载差异。

依据：[Stop/Start行为与计费](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/how-ec2-instance-stop-start-works.html)、[AMI与附加EBS卷](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/creating-an-ami-ebs.html)、[EBS恢复初始化](https://docs.aws.amazon.com/ebs/latest/userguide/initalize-volume.html)。

## 6. 现在仍未证明的事项

- 实际开机请求的写入权限和即时容量。
- 最终子网＋安全组＋NACL＋本地私钥的端到端连接。
- 远程R／Codex依赖、模型认证及科学环境版本兼容性。
- 25万细胞完整T01、T05全源、T10完整流程在11 GiB门槛内通过。
- v0.5 profile adapter／资源保护代码及所有真实数据清单已经完成。

因此可以把明日目标写成“获准开机后完成环境／数据／离线预检，按门槛逐任务开始pilot”；不能仅凭本报告就承诺明日全部十任务正式收集会完成。
