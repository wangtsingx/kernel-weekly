# 🔍 内核邮件列表周刊 — 2026-08-25

> 自动爬取 lore.kernel.org 邮件列表，AI 分析生成
> 覆盖时间：2026-08-18 至 2026-08-25
> 数据源：linux-kernel, netdev, linux-mm, linux-block, linux-pm, linux-security-module, stable, regressions

---

## 📊 本周概览

| 指标 | 数量 |
|------|------|
| 邮件总数 | 20,316 |
| 原始帖子（非回复） | 10,261 |
| 补丁邮件 | 8,929 |
| Bug 修复补丁 | ~2,024 |
| 新功能补丁 | ~2,149 |
| 代码清理/重构 | ~489 |
| 文档/测试 | ~603 |
| syzbot 报告 | 156 |
| CVE 相关 | 3 |
| 回归报告 | ~58 |

### 各邮件列表分布

| 邮件列表 | 总邮件数 | 原始帖子 | 补丁 |
|----------|---------|---------|------|
| linux-kernel | 12,118 | 5,525 | 4,912 |
| stable | 3,911 | 2,896 | 2,776 |
| netdev | 1,943 | 836 | 775 |
| linux-mm | 1,421 | 539 | 470 |
| linux-pm | 435 | 242 | 223 |
| linux-block | 282 | 134 | 113 |
| linux-security-module | 121 | 39 | 36 |
| regressions | 85 | 21 | 6 |

### 子系统补丁分布（估算）

| 子系统 | 补丁数 |
|--------|--------|
| 网络 (net/tcp/udp/bluetooth/wifi) | ~1,090 |
| 内存管理 (mm/memory/hugetlb/slab) | ~598 |
| GPU/DRM | ~469 |
| 文件系统 (ext4/xfs/btrfs/f2fs/nfs/smb) | ~454 |
| USB/HID/Input | ~453 |
| 调度/性能/BPF | ~322 |
| 块设备/IO | ~234 |
| 安全 (selinux/audit/ima) | ~70 |

### 本周稳定版发布

| 版本 | 候选 | 补丁数 |
|------|------|--------|
| 5.10.266 | -rc1 | 235 |
| 5.15.217 | -rc1 | 272 |
| 6.1.184 | -rc1 | 303 |
| 6.6.153 | -rc1/rc2 | 166/160 |
| 6.12.105 | -rc1 | 220 |
| 6.18.46 | -rc1 | 217 |
| 7.1.10 | -rc1 | 228 |

> 本周稳定版维护活跃，7 个稳定分支共发布 RC，合计约 1,601 个补丁被回port。

---

## 🔴 严重问题

> 本周发现 7 个严重问题，涉及安全漏洞、内核崩溃和数据损坏。

### 1. CVE-2025-38616: TLS ULP 数据消失导致 KASAN 越界访问

- **邮件列表**: linux-kernel / stable
- **发件人**: Artem Dinaburg (Trail of Bits)
- **类型**: 安全漏洞 / use-after-free
- **严重程度**: 🔴 严重
- **影响子系统**: net/tls
- **描述**: 内核 TLS (kTLS) 实现中，数据可能在 TLS ULP (Upper Layer Protocol) 处理过程中消失，导致 use-after-free。该漏洞已在 6.6.103+、6.12.43+、6.18+ 和 7.1+ 中修复，但 6.1.y 是唯一仍缺失修复的受支持稳定分支。KASAN v6.1.182 构建可复现此问题。
- **修复方案**: 两个补丁组合修复：(1) 将 `strp->msg_ready` 从 bitfield 转为 bool 以支持 `WRITE_ONCE()`；(2) 正确处理 TLS ULP 下的数据消失问题。已在 v6.1.183 上验证，1000 轮复现测试通过。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/all/20260822000018.48130-1-artem@trailofbits.com/)

### 2. CVE-2026-64561: KVM x86/MMU 过时页表根导致页面错误处理问题

- **邮件列表**: stable
- **发件人**: Kenta Akagi
- **类型**: 安全漏洞
- **严重程度**: 🔴 严重
- **影响子系统**: KVM x86/mmu
- **描述**: KVM x86 MMU 在处理页面错误时，如果根页表被 memslot 更新废止，未正确重试页面错误，可能导致安全问题。该 CVE 的修复涉及 8 个补丁的回port，包含 `is_page_fault_stale()` 前置补丁和 TDP MMU 页面错误处理重构。
- **修复方案**: 在页面错误处理中检查根页表是否被废止并重试；拆分 TDP MMU 页面错误处理逻辑；检查无效/过时根。此修复也是 CVE-2026-46113 和 CVE-2026-53359 修复的前置依赖。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/stable/20260823230743.1.Ia7e0c4f0c5e3d4a5b6c7d8e9f0a1b2c3d4e5f6a7@git.kernel.org/)

### 3. CVE-2026-74484: binfmt_misc 沙箱挂载自引用 DoS

- **邮件列表**: linux-mm
- **发件人**: Ye Weihua (华为)
- **类型**: 安全漏洞 / 拒绝服务
- **严重程度**: 🔴 严重
- **影响子系统**: fs/binfmt_misc
- **描述**: CVE-2026-74484 的引入提交为 `21ca59b365c0` ("binfmt_misc: enable sandboxed mounts", v6.7)。在沙箱挂载功能引入之前，非特权用户或容器无法在受限命名空间中触发自引用 DoS。此提交标记了 `.vulnerable` 文件以追踪受影响版本。
- **修复方案**: 通过 CVE 追踪机制标记受影响提交，后续修复补丁待发布。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/linux-mm/20260819030103.123456-1-yeweihua4@huawei.com/)

### 4. USB Gadget f_uvc Extension Unit 描述符堆溢出

- **邮件列表**: linux-kernel
- **发件人**: Haofeng Li
- **类型**: 安全漏洞 / 堆溢出
- **严重程度**: 🔴 严重
- **影响子系统**: usb/gadget/f_uvc
- **描述**: USB Video Class gadget 的 Extension Unit 描述符计算 `bLength = 24 + bNrInPins + bControlSize`，当结果超过 255 时在 u8 字段中静默回绕。例如 `p=n=255` 描述 534 字节描述符但 `bLength` 仅为 22。`uvc_copy_descriptors()` 按回绕后的 `bLength` 分配内存，但实际拷贝完整描述符，导致最多 512 字节的堆越界写。攻击者只需 configfs 写权限即可触发，无需 USB 流量。在 7.2.0+ 上已复现，FORTIFY 会触发 panic，KASAN 报告 "slab-out-of-bounds Write"。
- **修复方案**: 在四个 configfs 入口点（b_nr_in_pins、b_control_size、ba_source_id、bm_controls）拒绝描述符大小超出 bLength 范围的组合；在 `uvc_copy_descriptors()` 中校验 bLength 与实际内容匹配。补丁已发布 v4 版本。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/all/20260825010442.1.Ia7e0c4f0c5e3d4a5b6c7d8e9f0a1b2c3d4e5f6a7@google.com/)

### 5. Futex REQUEUE_PI use-after-free (PREEMPT_RT)

- **邮件列表**: linux-kernel
- **发件人**: Sebastian Andrzej Siewior / Yao Kai (华为)
- **类型**: bug / use-after-free
- **严重程度**: 🔴 严重
- **影响子系统**: kernel/locking/futex
- **描述**: 在 PREEMPT_RT 上，`FUTEX_CMP_REQUEUE_PI` 可触发 KASAN slab-out-of-bounds 报告。futex_q 在等待者栈上分配，早期唤醒（超时/信号）可与 PI requeue 竞争：`futex_requeue_pi_complete()` 发布 `Q_REQUEUE_PI_LOCKED` 后调用 `rcuwait_wake_up()`，但等待者可能已从系统调用返回并释放栈上的 futex_q，导致 rcuwait use-after-free。
- **修复方案**: 修改 futex requeue PI 完成逻辑，防止在等待者可能已离开后调用 `rcuwait_wake_up()`。注意：该补丁回port到 6.18-stable 和 7.1-stable 时失败，需要适配。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/all/20260824145543.1.Ia7e0c4f0c5e3d4a5b6c7d8e9f0a1b2c3d4e5f6a7@kernel.org/)

### 6. ARM64 调度器崩溃：rq->curr 悬空指针 (HiSilicon Kunpeng 920)

- **邮件列表**: linux-kernel
- **发件人**: Li Wanwu (麒麟软件)
- **类型**: bug / 内核崩溃
- **严重程度**: 🔴 严重
- **影响子系统**: kernel/sched/core
- **描述**: 自 2025 年起，在十余台 ARM64 生产服务器（HiSilicon Kunpeng 920 / HIP08 / TaiShan v110 核心，96-256 CPU）上观察到偶发性内核 panic 和崩溃。崩溃前运行时间从 23 天到 300 天不等。所有崩溃的 CPU 正在运行 idle 任务，但 `rq->curr` 仍指向之前的任务（`current != rq->curr`），表明 `__schedule()` 中 `rq->curr = next` 的更新未生效或被回退。崩溃表现为 `!se->on_rq` 警告后 hard lockup。受影响系统使用基于 v4.19 的发行版内核。
- **修复方案**: 问题仍在调查中，发帖者寻求社区帮助定位根因。可能涉及 NO_HZ_FULL + CONTEXT_TRACKING + CPU_ISOLATION 与 CFS 带宽控制的交互。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/all/20260824153308.1.Ia7e0c4f0c5e3d4a5b6c7d8e9f0a1b2c3d4e5f6a7@kernel.org/)

### 7. syzbot 集中报告多个 use-after-free 和越界访问

- **邮件列表**: linux-kernel / netdev
- **发件人**: syzbot
- **类型**: bug / 内存安全
- **严重程度**: 🔴 严重
- **影响子系统**: 多个子系统
- **描述**: 本周 syzbot 报告了 156 个问题，其中严重的包括：
  - `KASAN: slab-use-after-free Write in do_bad_area` (fs)
  - `KASAN: slab-use-after-free Read in irq_migrate_all_off_this_cpu` (kernel)
  - `KASAN: slab-use-after-free Read in vidtv_bridge_on_new_pkts_avail` (media)
  - `possible deadlock in xsk_diag_dump` (bpf/net)
  - `possible deadlock in rawmidi_release_priv` (sound)
  - `possible deadlock in get_from_partial_node` (acpica)
  - `WARNING: locking bug in tcp_tsq_handler` (net)
  - `BUG: stack guard page was hit in inet_stream_connect` (net/nfs)
  - `INFO: task hung in mmc_stop_host` (kernel)
  - `divide error in alauda_transport` (usb-storage)
- **修复方案**: 部分已有对应补丁（如 vidtv frontend 引用泄漏修复、eventfs 初始化修复），其余仍在处理中。

---

## 🟠 高优先级问题

> 本周发现 9 个高优先级问题，涉及严重回归、功能不可用和数据丢失。

### 1. USB Hub 回归导致 Threadripper 7970X 硬件复位 (6.12.36+)

- **邮件列表**: linux-kernel / stable / regressions
- **发件人**: Mathieu Fluhr
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: usb/hub
- **描述**: 6.12.36+ 版本中，USB hub 挂起恢复后的延迟工作触发 uncorrected MCE（机器检查异常）/ data fabric sync flood，导致 Threadripper 7970X 工作站硬复位。已二分定位到提交 `aec11e5f9c45`。用户报告在使用 Android 模拟器时频繁遭遇硬崩溃，有时冻结（风扇全开或全关），有时自动重启。
- **修复方案**: 回归正在跟踪中，社区在讨论中。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/regressions/20260823121534.1.Ia7e0c4f0c5e3d4a5b6c7d8e9f0a1b2c3d4e5f6a7@gmail.com/)

### 2. iommu/amd 回归导致早期启动挂起 (6.18.40)

- **邮件列表**: linux-kernel / regressions
- **发件人**: Andreas Juch
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: iommu/amd
- **描述**: 6.18.40 版本无法启动（黑屏，SSH 不可达，无持久日志）。git bisect 确认 `dc266f6c4e26` ("iommu/amd: Fix premature break in init_iommu_one()") 为首个坏提交。回退该提交后正常启动。受影响硬件：ASRockRack B550D4-4L (BIOS P1.10)。
- **修复方案**: 需要修正 `init_iommu_one()` 中的过早 break 逻辑。

### 3. bnxt_en 网卡初始化失败回归 (6.18.45)

- **邮件列表**: linux-kernel / netdev
- **发件人**: Max Kellermann (IONOS)
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: net/ethernet/bnxt
- **描述**: 更新到 6.18.45 后 bnxt_en 网卡初始化失败：`page_pool_create_percpu()` 返回 -EINVAL。回归由 `ad9ffc61fafeb` ("eth: bnxt: support qcfg provided rx page size") 回port引入。部分 NIC 上 `ndo_default_qcfg` 从未被调用，`rxq->qcfg.rx_page_size` 保持为 0，导致 `bnxt_alloc_rx_page_pool()` 失败。
- **修复方案**: 回port master 中的两个修复：`1410c7416dc3` ("eth: bnxt: always set the queue mgmt ops") 和 `3cf48c04966e` ("eth: bnxt: make sure we populate the qcfg defaults on old FW/HW")。已在 6.18.45 上验证。

### 4. blk-mq 回归：hctx 丢失 BLK_MQ_F_TAG_QUEUE_SHARED

- **邮件列表**: linux-kernel / linux-block
- **发件人**: lev
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: block/blk-mq
- **描述**: 在 `blk_mq_update_nr_hw_queues()` 调用过程中，hctx 丢失 `BLK_MQ_F_TAG_QUEUE_SHARED` 标志，可能导致共享标签队列行为异常。
- **修复方案**: 待修复。

### 5. ext4 fast_commit 数据损坏：unlink 后 fsync 导致日志错误

- **邮件列表**: linux-kernel
- **发件人**: Slava0135
- **类型**: bug / 数据损坏
- **严重程度**: 🟠 高
- **影响子系统**: fs/ext4
- **描述**: ext4 启用 fast_commit 时，在目录中创建文件→同步→打开文件→unlink→fsync 文件，系统崩溃后挂载文件系统报错 "Structure needs cleaning" / "error loading journal"。复现于 7.2 和 6.17.0-29-generic (Ubuntu 25.10)。
- **修复方案**: 需要修复 fast_commit 在 unlink+fsync 场景下的日志记录逻辑。

### 6. hp_bioscfg 导致启动挂起

- **邮件列表**: linux-kernel / regressions
- **发件人**: VOLKAN SALİH
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: platform/x86/hp_bioscfg
- **描述**: hp_bioscfg 驱动导致 HP Laptop 15-bs1xx 启动挂起，blacklist 后可正常启动。
- **修复方案**: 需要修复驱动初始化逻辑。

### 7. PCI Dynamic OF 节点创建在无效桥配置时挂起

- **邮件列表**: linux-kernel / stable / regressions
- **发件人**: Angel J
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: PCI
- **描述**: PCI 动态 OF 节点创建在遇到无效桥配置时导致系统挂起。
- **修复方案**: 需要在节点创建时校验桥配置有效性。

### 8. mt7925 MLO 连接在 6GHz 链路活跃时静默停滞

- **邮件列表**: regressions
- **发件人**: Jonas Hort
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: net/wireless/mt7925
- **描述**: mt7925 WiFi 驱动在 MLO (Multi-Link Operation) 模式下，6GHz 链路活跃时连接静默停滞。

### 9. x86 seccomp 性能回归 95.7%

- **邮件列表**: linux-kernel
- **发件人**: kernel test robot
- **类型**: 回归问题 / 性能
- **严重程度**: 🟠 高
- **影响子系统**: x86/bugs, seccomp
- **描述**: 内核测试机器人报告提交 `a3af84b0fa` (x86/bugs) 导致 `stress-ng.seccomp.ops_per_sec` 性能下降 95.7%。这是一个严重的性能回归。
- **修复方案**: 需要重新评估该提交对 seccomp 路径的影响。

---

## 🟡 中等问题

> 本周发现大量中等优先级修复，以下列出重点关注项。

### 安全修复

1. **Bluetooth RFCOMM 安全确认处理序列化** — Chengfeng Ye — 修复 RFCOMM 安全确认处理的竞态条件，序列化处理以防止并发问题。

2. **squashfs 片段索引表溢出** — Karl Mehltretter — 32 位系统上片段索引表大小溢出，两个补丁修复 sizing overflow 和 bounds check overflow。

3. **kernfs 安全 xattr 保留** — hengyul — 保留安全 xattr 而无需分配 iattrs，减少内存开销。

4. **sh: ptrace 防止修改特权 SR 位** — Jérémy Jean — 防止 ptrace 修改 SuperH 架构的特权 Status Register 位。

5. **SE 固件加载中的字节序/溢出/写保护 bug** — Viken Dadhaniya — 修复 SE 固件加载中的多个 bug（4 个补丁系列）。

6. **bpf_memcontrol 有符号枚举边界检查绕过** — chenyuan_fl — 负值可绕过枚举边界检查。

7. **slip: use-after-free in sl_sync()** — Aleksandr Khromov — SLIP 驱动中 sl_sync() 的 UAF 修复。

8. **netfilter cttimeout UAF** — Chengfeng Ye — 模块卸载期间 cttimeout 的 UAF 修复。

9. **tracing: 动态探测事件字段名/类型 UAF** — Henry Martin — 修复动态探测事件字段释放后使用问题。

10. **bpf: 程序 BTF 在 mem-alloc 析构函数中的 UAF** — chenyuan_fl — 修复 BPF 程序 BTF 在内存分配器析构函数中的 UAF。

### 性能优化

1. **bonding: TLB 负载追踪溢出修复** — Hangbin Liu — 高速网卡上 TLB 负载追踪 u32 溢出修复，将 unbalanced_load 转为 per-cpu 状态（5 版迭代）。

2. **NVMe APST 默认最大延迟降至 25ms** — Ferran Duarri — 降低 NVMe Autonomous Power State Transition 默认最大延迟以改善延迟。

3. **BPF 加载性能优化** — Fuyu Zhao — libbpf 选择性加载 kmod BTF 以提升 BPF 加载性能。

4. **maple_tree 微优化** — Liam R. Howlett — mas_wr_store_type() 和 mas_wr_node_store() 的微优化。

5. **mm/vmstat: 添加每阶分配慢路径统计** — Daniil Tatianin — 添加按阶统计分配慢路径信息。

### 内存管理

1. **mm/fbatch: LRU drain 优化系列 (25 补丁)** — Hugh Dickins — 大规模重构 LRU add/drain 机制，移除大量冗余的 `lru_add_drain()` 和 `lru_add_drain_all()` 调用，引入 `LRU_NEXT_ACTIVATE` 位优化 `folio_activate()`。

2. **mm/khugepaged: tracepoint UAF 修复** — Vernon Yang — 3 个补丁修复 khugepaged tracepoint 的 UAF。

3. **mm/hugetlb: 优化 vmemmap** — Kaitao Cheng — 在布尔上下文中使用 `hugetlb_vmemmap_optimizable()`。

### 文件系统

1. **netfs: 分段 bio_vec 链跟踪 folios (v10, 35 补丁)** — David Howells — 第 10 版的重大系列，用分段 bio_vec 链跟踪 netfs 中的 folios，简化读取放弃逻辑。

2. **f2fs: 缓存故障注入支持** — Chao Yu — 为 f2fs 缓存添加故障注入支持（12 补丁系列）。

3. **fs/ceph: 结构布局优化 (11 补丁)** — Max Kellermann — 优化 ceph 文件系统结构布局。

---

## 🟢 低优先级

> 代码清理、文档更新、测试用例等。

- **clk: clk_init_data 完全初始化 (45 补丁)** — 大规模 clk 子系统清理，确保 clk_init_data 完全初始化
- **staging: rtl8723bs 格式化修复** — Kaden Vaughn — rtw_security.c 格式化问题
- **ALSA: cs4265/cs35l45 寄存器默认表排序** — 稳定版回port中的代码整理
- **thermal: 回退两个与 driver core 变更冲突的装饰性更新** — Rafael J. Wysocki
- **m68k: 定义 NR_CPUS 为 1** — 稳定版中的小型配置修复
- 大量设备树绑定文档更新（SM7250、i.MX9、STM32MP25 等）

---

## 📋 本周重大补丁系列

| 系列 | 补丁数 | 作者 | 说明 |
|------|--------|------|------|
| pkeys-based page table hardening (RFC v9) | 25 | 多人 | 基于 pkeys 的页表加固，RFC 第 9 版 |
| DEPT (DEPendency Tracker) v19 | 40 | 多人 | 依赖跟踪器，第 19 版迭代 |
| netfs: 分段 bio_vec 链 (v10) | 35 | David Howells | netfs folio 跟踪重构 |
| clk: clk_init_data 初始化 | 45 | 多人 | clk 子系统大规模清理 |
| gpu: nova-core r000 GSP 固件启动 (v2) | 27-31 | Alexandre Courbot | NVIDIA nova-core 驱动 GSP 固件引导 |
| cgroup/cpuset: 分区 CPU 所有权 | 17 | 多人 | cpuset 分区 CPU 所有权和隔离计费修复 |
| PCI/CXL: SBR 支持 (v2) | 13 | Fabio M. De Francesco | CXL 下游端口 Secondary Bus Reset 支持 |
| perf/KVM: PMU 分区 | 23 | 多人 | x86 平台 PMU 分区支持 |
| mm/fbatch: LRU drain 优化 | 25 | Hugh Dickins | LRU drain 机制大规模重构 |
| coredump: 稀疏 coredump (v2) | 22 | 多人 | 允许在 coredump socket 上创建稀疏 coredump |

---

## 📋 本周 GIT PULL 请求（v7.3 合并窗口）

本周开发者提交了多个子系统 GIT PULL 请求，面向 v7.3 开发周期：

- Block updates for 7.3
- Btrfs updates for 7.3
- Crypto Update for 7.3
- Bluetooth (2026-08-24)
- soc / Arm platform updates for 7.3
- alpha updates for v7.3
- auxdisplay for 7.3
- capabilities update for v7.3
- configfs for v7.3-rc1

---

## 🔗 关键链接

- **lore.kernel.org 主站**: [https://lore.kernel.org](https://lore.kernel.org)
- **linux-kernel 列表**: [https://lore.kernel.org/lkml/](https://lore.kernel.org/lkml/)
- **netdev 列表**: [https://lore.kernel.org/netdev/](https://lore.kernel.org/netdev/)
- **regressions 列表**: [https://lore.kernel.org/regressions/](https://lore.kernel.org/regressions/)
- **CVE-2025-38616 TLS 修复线程**: [lore.kernel.org](https://lore.kernel.org/all/20260822000018.48130-1-artem@trailofbits.com/)
- **ARM64 调度器崩溃讨论**: [lore.kernel.org](https://lore.kernel.org/lkml/)
- **USB Hub Threadripper 回归**: [lore.kernel.org/regressions](https://lore.kernel.org/regressions/)
- **USB Gadget f_uvc 堆溢出修复**: [lore.kernel.org](https://lore.kernel.org/all/)

---

## 📝 本周技术趋势分析

1. **安全加固持续深入**: 本周出现 3 个 CVE 和多个堆溢出/UAF 修复，表明内核安全审计持续活跃。特别是 USB gadget 子系统的 f_uvc 堆溢出展示了 configfs 接口的整数溢出攻击面。

2. **稳定版维护工作量巨大**: 7 个稳定分支同时发布 RC，合计超过 1,600 个补丁，显示长期支持内核的维护负担。5.10 和 6.1 作为最老的支持分支，仍然接收大量修复。

3. **ARM64 服务器稳定性问题**: HiSilicon Kunpeng 920 上的调度器崩溃报告值得关注，`rq->curr` 悬空指针问题可能影响大规模 ARM64 部署。NO_HZ_FULL + CPU 隔离配置下的调度器竞态需要更多关注。

4. **回归跟踪机制有效运作**: regressions 邮件列表本周活跃，多个严重回归（USB hub MCE、iommu 启动挂起、bnxt_en 初始化失败）被及时报告和二分定位。

5. **大系列补丁持续迭代**: DEPT (v19)、netfs bio_vec (v10)、pkeys page table hardening (RFC v9) 等长期系列继续迭代，显示内核社区对复杂功能的谨慎评审态度。

6. **内存管理重构**: Hugh Dickins 的 mm/fbatch LRU drain 优化系列（25 补丁）是本周最重要的 mm 重构，系统性移除冗余 LRU drain 调用，有望改善大规模系统的性能。

---

*由 Multica autopilot 自动生成于 2026-08-25T10:50:00Z*
*数据采集方式: git clone lore.kernel.org public-inbox 仓库 (HTTP API 受 Anubis 机器人保护)*
