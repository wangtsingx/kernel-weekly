# 🔍 内核邮件列表周刊 — 2026-08-25

> 自动爬取 [lore.kernel.org](https://lore.kernel.org) 邮件列表，AI 分析生成
> 覆盖时间：2026-08-18 至 2026-08-25
> 数据源：linux-kernel (lkml), netdev, linux-mm, linux-block, linux-pm, linux-security-module, stable, regressions
> 采集方式：git clone public-inbox 仓库（`--shallow-since` 浅克隆）

---

## 📊 本周概览

| 指标 | 数量 |
|------|------|
| 邮件总数 | 20,256 |
| 原始帖子（非回复） | 10,265 |
| 补丁邮件 | ~9,236 |
| RFC 邮件 | 816 |
| Bug 报告 | 142 |
| CVE 相关 | 3 |
| 回归报告（用户报告） | 6 |
| syzbot 报告 | 96 |
| GIT PULL 请求（v7.3 合并窗口） | 83+ |
| UAF/use-after-free 相关 | 450 |
| KASAN 报告 | 129 |
| 死锁/lockdep | 59 |

### 各邮件列表分布

| 邮件列表 | 总邮件数 | 原始帖子 | 补丁 |
|----------|---------|---------|------|
| linux-kernel | 12,072 | 5,512 | 4,894 |
| stable | 3,912 | 2,898 | 2,778 |
| netdev | 1,940 | 838 | 777 |
| linux-mm | 1,408 | 539 | 467 |
| linux-pm | 436 | 244 | 225 |
| linux-block | 283 | 134 | 113 |
| linux-security-module | 120 | 39 | 36 |
| regressions | 85 | 21 | 6 |

### 子系统补丁分布（估算）

| 子系统 | 补丁数 |
|--------|--------|
| 内存管理 (mm/) | ~1,445 |
| 网络 (net/) | ~1,571 |
| GPU/DRM | ~701 |
| 设备树 (dt-bindings) | ~647 |
| ARM/ARM64 | ~646 |
| 文件系统 (fs/) | ~419 |
| IIO | ~394 |
| 媒体 (media) | ~308 |
| 时钟 (clk) | ~245 |
| USB/HID | ~234 |
| 调度/性能/BPF | ~222 |
| 电源/温控 | ~215 |
| Rust | ~177 |
| 块设备/IO | ~176 |
| 安全 (security) | ~154 |

### 本周活跃贡献者 Top 10

| 排名 | 贡献者 | 邮件数 |
|------|--------|--------|
| 1 | Greg Kroah-Hartman | 1,756 |
| 2 | Sasha Levin | 306 |
| 3 | syzbot | 243 |
| 4 | Jakub Kicinski | 241 |
| 5 | Konrad Dybcio | 228 |
| 6 | Krzysztof Kozlowski | 201 |
| 7 | David Hildenbrand | 192 |
| 8 | Abel Vesa | 180 |
| 9 | Lorenzo Stoakes | 158 |
| 10 | Jonathan Cameron | 136 |

---

## 🔴 严重问题

> 本周发现 3 个 CVE 和多个严重 Bug，涉及安全漏洞、内核崩溃和数据损坏。

### 1. CVE-2025-38616: kTLS ULP 数据消失导致 use-after-free

- **邮件列表**: linux-kernel / stable
- **发件人**: Artem Dinaburg (Trail of Bits)
- **类型**: 安全漏洞 / use-after-free
- **严重程度**: 🔴 严重
- **影响子系统**: net/tls
- **描述**: 内核 TLS (kTLS) 实现中，数据可能在 TLS ULP (Upper Layer Protocol) 处理过程中消失，导致 use-after-free。该漏洞已在 6.6.103+、6.12.43+、6.18+ 和 7.1+ 中修复，但 6.1.y 是唯一仍缺失修复的受支持稳定分支。KASAN v6.1.182 构建可复现此问题。
- **修复方案**: 两个补丁组合修复：(1) 将 `strp->msg_ready` 从 bitfield 转为 bool 以支持 `WRITE_ONCE()`；(2) 正确处理 TLS ULP 下的数据消失问题。已在 v6.1.183 上验证，1000 轮复现测试通过。
- **链接**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/e8a3828b253a108759933630e8c5357e3682e7d9/)

### 2. CVE-2026-64561: KVM x86 MMU 过时页表根

- **邮件列表**: stable
- **发件人**: Kenta Akagi
- **类型**: 安全漏洞
- **严重程度**: 🔴 严重
- **影响子系统**: KVM x86/mmu
- **描述**: KVM x86 MMU 在处理页面错误时，如果根页表被 memslot 更新废止，未正确重试页面错误，可能导致安全问题。该 CVE 的修复涉及 8 个补丁的回port，包含 `is_page_fault_stale()` 前置补丁和 TDP MMU 页面错误处理重构。
- **修复方案**: 在页面错误处理中检查根页表是否被废止并重试；拆分 TDP MMU 页面错误处理逻辑。此修复也是 CVE-2026-46113 和 CVE-2026-53359 修复的前置依赖。
- **链接**: [lore.kernel.org/stable](https://lore.kernel.org/stable/707173d9b876d73b7ead50e583b93a809833069e/)

### 3. CVE-2026-74484: binfmt_misc 沙箱挂载自引用 DoS

- **邮件列表**: linux-mm
- **发件人**: Ye Weihua (华为)
- **类型**: 安全漏洞 / 拒绝服务
- **严重程度**: 🔴 严重
- **影响子系统**: fs/binfmt_misc
- **描述**: CVE-2026-74484 的引入提交为 `21ca59b365c0` ("binfmt_misc: enable sandboxed mounts", v6.7)。在沙箱挂载功能引入之前，非特权用户或容器无法在受限命名空间中触发自引用 DoS。此提交标记了 `.vulnerable` 文件以追踪受影响版本。
- **链接**: [lore.kernel.org/linux-mm](https://lore.kernel.org/linux-mm/2b09f8f3a21f16446f13cb48c9823c27bfd2c1e4/)

### 4. ARM64 服务器调度器崩溃：rq->curr 悬空指针

- **邮件列表**: linux-kernel
- **发件人**: Wanwu Li (麒麟软件)
- **类型**: 内核崩溃 / 疑似硬件相关
- **严重程度**: 🔴 严重
- **影响子系统**: sched/core
- **描述**: 自 2025 年起，在十余台 ARM64 生产服务器（均为海思鲲鹏 920 / HIP08 / TaiShan v110 核心，96-256 CPU）上观察到偶发性内核崩溃。崩溃前正常运行时间从 23 天到 300 天不等。崩溃时 `rq->curr` 指向的任务与实际运行任务不一致（`rq->curr != current`），导致调度器路径中的空指针解引用。所有崩溃均发生在 CPU 空闲转换路径（do_idle/schedule_idle 或空闲 CPU 收到定时器唤醒）。尽管 `context_switch` 中的 `rq->curr` 赋值后有多重内存屏障（`finish_lock_switch` 释放锁 + `dsb(ish)` + `dsb(sy)` before WFI），dump 显示该存储仍不可见，怀疑可能是平台/硬件层面的存储一致性异常。
- **影响范围**: 海思鲲鹏 920 大规模 ARM64 部署（昆仑 2280、华鲲 TG225 B1）
- **当前状态**: 寻求社区帮助，可提供完整 vmcore 和反汇编
- **链接**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/3d1bacf9a663a74960fdbf8dd7fb1b1fca755f6e/)

### 5. BPF JIT may_goto 私有栈状态损坏

- **邮件列表**: linux-kernel
- **发件人**: Jérémy Jean
- **类型**: JIT 编译器 Bug / 状态损坏
- **严重程度**: 🟠 高
- **影响子系统**: bpf/x86 JIT
- **描述**: x86 timed may_goto 路径在私有栈程序中存在验证器/JIT 状态不匹配 Bug。根因是 timed may_goto 修复通过 `BPF_REG_AX` 传递栈偏移，而 x86 trampoline 从原生 `%rbp` 重建计数器指针。启用私有栈 JIT 模式后，普通 BPF 帧指针访问从 `%rbp` 重映射到 `%r9`，但 `arch_bpf_timed_may_goto()` 仍使用 `%rbp`，导致读写原生 JIT 栈帧而非私有 BPF 栈。该 Bug 由 `2fb761823ead` 引入，在 v7.2 上已复现，但 KASAN 不触发因为错误写操作仍在原生 JIT 栈帧范围内。保存寄存器损坏可观测。
- **修复方案**: 待提交（作者表示修复较微妙，可能涉及多架构文件）
- **链接**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/d35f2d584829653b47e8c37f488669e4f9496b85/)

### 6. USB Gadget f_uvc Extension Unit 描述符堆溢出

- **邮件列表**: linux-kernel
- **类型**: 安全漏洞 / 堆溢出
- **严重程度**: 🟠 高
- **影响子系统**: usb/gadget/f_uvc
- **描述**: USB Gadget f_uvc 驱动在处理 Extension Unit 描述符时存在堆溢出。configfs 接口的整数溢出导致分配的缓冲区不足，后续写入超出缓冲区边界。同周还修复了 f_uac1_legacy 的类似堆溢出问题（`f_audio_out_ep_complete()`）。
- **修复方案**: 已提交 v4 版补丁修复。
- **链接**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/c9e8c69f393efb6f77308ca61f37ee080c02b817/)

### 7. sched/fair 除零错误

- **邮件列表**: linux-kernel
- **发件人**: Jake Steinman
- **类型**: 内核崩溃 / 除零
- **严重程度**: 🟠 高
- **影响子系统**: sched/fair
- **描述**: 调度器 CFS 公平调度类在 `__calc_prop_weight()` 入队路径中发生除零错误，来自 flat-hierarchy 系列。
- **链接**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/d5158b4cc25cedf2c766956c0ced436dd9ce7c3d/)

---

## 🟡 重要回归报告

> 本周 regressions 邮件列表和各子系统列表共报告 6 个用户级回归（不含 KernelCI 构建失败）。

### 1. USB Hub 恢复后 Threadripper MCE 崩溃

- **报告人**: Mathieu Fluhr
- **影响版本**: 6.12.36+
- **已二分**: `aec11e5f9c45`
- **描述**: USB hub post-resume 延迟工作触发未纠正 MCE / 数据结构同步洪泛，导致 AMD Threadripper 7970X 系统崩溃。多个开发者参与讨论，Mario Limonciello (AMD) 参与协调。
- **链接**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/33b4a8603f790127307b22f3689ceffe3064b133/)

### 2. iommu/amd 早期启动挂起

- **报告人**: Andreas Juch
- **描述**: "Fix premature break in init_iommu_one()" 修复引入了新的启动挂起问题。Joerg Roedel (IOMMU 维护者) 和 Vasant Hegde 参与修复讨论。
- **链接**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/e76121949c7a4c484a05ad7f885ff51ff53496df/)

### 3. bnxt_en 网卡初始化失败

- **报告人**: Holger Kiehl
- **影响版本**: 6.18.45
- **描述**: bnxt_en 驱动在 `page_pool_create_percpu` 中以 errno -22 (-EINVAL) 失败，导致 Broadcom 网卡无法初始化。
- **链接**: [lore.kernel.org/netdev](https://lore.kernel.org/netdev/b06e4f9194f6640fa45a630679acb9807ca0572c/)

### 4. blk-mq 标签队列共享标志丢失

- **报告人**: lev
- **描述**: blk-mq 在 `blk_mq_update_nr_hw_queues()` 过程中丢失 `BLK_MQ_F_TAG_QUEUE_SHARED` 标志，可能导致 I/O 性能问题或死锁。

### 5. PCI 动态 OF 节点创建挂起

- **报告人**: Angel J
- **描述**: PCI 动态 OF (Device Tree) 节点创建在无效桥配置时导致系统挂起。

### 6. hp_bioscfg 启动挂起

- **报告人**: VOLKAN SALİH
- **描述**: HP Laptop 15-bs1xx 上 hp_bioscfg 导致启动挂起，黑名单可绕过。

### 其他回归相关

- **mt7925 MLO 连接静默中断**: 6GHz 链接激活时 Wi-Fi MLO 连接静默停滞
- **PCIe/qcom WCN7850 链路卡死**: Surface Pro 11 (X1E80100) PCIe 链路卡在 Polling 状态
- **qcom PAS TZ API 迁移**: 破坏 TrustZone 无 PAS 设备的 GPU 和 modem (sc7180 trogdor)
- **v6.19+ mkdirat 回归**: `end_dirop()` 解锁错误 inode 并泄漏父 `i_rwsem`（仍存在于 7.2-rc7）
- **KernelCI 构建回归**: 多个稳定分支出现 `bh_work` 成员缺失、`__struct_size` 未声明等构建问题

---

## 🟠 安全修复亮点

### 密钥子系统 Use-After-Free

- **邮件列表**: linux-security-module
- **描述**: `key_user` 结构在密钥所有权变更期间存在 use-after-free，可能导致权限提升。
- **链接**: [lore.kernel.org/linux-security-module](https://lore.kernel.org/linux-security-module/af40eb0e70f61bdd4e178005afa6a2f8111100a8/)

### Landlock Use-After-Free

- **邮件列表**: linux-security-module
- **描述**: Landlock 安全模块中源目录的父目录存在 use-after-free。
- **链接**: [lore.kernel.org/linux-security-module](https://lore.kernel.org/linux-security-module/be27dc65916b2f2b93283dd832cd743b4a192973/)

### SRCU 误报警告

- **邮件列表**: linux-kernel
- **发件人**: Sunho Park
- **描述**: `cleanup_srcu_struct()` 在 `78a38cbf6f20` 之后出现误报 WARN，可能导致误判 SRCU 清理失败。
- **链接**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/8b0da5a07b46b9b6edbdaef2f5649e2eea90d9e8/)

### 本周 syzbot 报告概览

本周 syzbot 共发现 96 个唯一报告，主要涉及：

| 子系统 | 问题类型 | 关键函数 |
|--------|---------|---------|
| block | KASAN slab-out-of-bounds | seq_buf_putmem |
| block | RCU stall | blkdev_common_ioctl |
| block | possible deadlock | blkg_conf_prep / ocfs2_read_blocks |
| btrfs | kernel BUG | btrfs_subpage_assert |
| btrfs | WARNING | btrfs_add_to_free_space_tree |
| bpf | possible deadlock | xsk_diag_dump |
| bpf | UBSAN array-out-of-bounds | print_bpf_insn |
| RDMA/siw | KASAN slab-use-after-free | siw_accept |
| lockd | KASAN slab-use-after-free | nlm_async_call |
| net/ipv6 | KASAN slab-use-after-free | ip6gre_tunnel_xmit |
| NFC | KASAN slab-use-after-free | nfc_llcp_rx_skb |
| timer | KASAN slab-use-after-free | __timer_delete |
| fbcon | KASAN slab-out-of-bounds | soft_cursor |
| hfsplus | KASAN global-out-of-bounds | hfsplus_ext_write_extent |

---

## 📦 本周稳定版发布

本周 Greg Kroah-Hartman 发布了 7 个稳定分支的 14 个版本（含 RC）：

| 版本 | 候选 | 补丁数 |
|------|------|--------|
| 5.10.265 | -rc1 | 389 |
| 5.10.266 | -rc1 | 235 |
| 5.15.216 | -rc1 | 456 |
| 5.15.217 | -rc1 | 272 |
| 6.1.183 | -rc1 | 609 |
| 6.1.184 | -rc1 | 303 |
| 6.6.152 | -rc1 | 156 |
| 6.6.153 | -rc1 | 166 |
| 6.6.153 | -rc2 | 160 |
| 6.12.104 | -rc1 | 181 |
| 6.12.105 | -rc1 | 220 |
| 6.18.45 | -rc1 | 250 |
| 6.18.46 | -rc1 | 217 |
| 7.1.10 | -rc1 | 228 |

> 本周稳定版维护极其活跃，7 个稳定分支共发布 14 个版本，合计约 3,842 个补丁被回port。其中 6.1.183-rc1 单次包含 609 个补丁，为本周最大规模回port。6.6.153 是唯一发布了 rc2 的版本。

---

## 🚀 本周大型补丁系列

| 系列名称 | 补丁数 | 版本 | 说明 |
|----------|--------|------|------|
| mm/collapse: 基于 migration 原语重建 collapse | 57 | RFC | THP 折叠机制大规模重构 |
| clk: qcom: CX 电源域绑定到 GCC | 47 | v3 | Qualcomm 时钟子系统电源域改进 |
| clk: 确保 clk_init_data 完全初始化（第二部分） | 45 | — | clk 子系统大规模清理 |
| DEPT (DEPendency Tracker) | 40 | v19 | 依赖跟踪器，第 19 版迭代 |
| phy: rockchip: usbdp 清理 | 38 | v14 | Rockchip USB/DP PHY 驱动清理 |
| netfs: 分段 bio_vec 链 | 35 | v10 | netfs folio 跟踪重构 |
| gpu: nova-core r000 GSP 固件启动 | 31 | v2 | NVIDIA nova-core 驱动 GSP 固件引导 |
| media: 多上下文操作支持 | 27 | v2 | 媒体设备多上下文支持 |
| mm/fbatch: LRU drain 优化 | 25 | — | LRU drain 机制大规模重构 |
| fs-verity XFS 支持 | 25 | v15 | XFS 文件系统 fs-verity 支持 |
| pkeys-based 页表加固 | 25 | RFC v9 | 基于 pkeys 的页表加固 |
| unwind_user: .eh_frame 处理 | 25 | RFC v2 | 用户态栈展开 .eh_frame 实现 |
| pidfd: 最小进程 spawn 构建器 | 24 | RFC | pidfd 进程创建 API |
| iommu/amd: 硬件加速虚拟化 IOMMU (vIOMMU) | 24 | v4 | AMD vIOMMU 支持 |
| SIMD/eGPRs/SSP 寄存器 perf 采样 | 23 | v10 | x86 SIMD 寄存器性能采样 |
| perf/KVM: PMU 分区 | 23 | — | x86 平台 PMU 分区支持 |
| coredump: 稀疏 coredump | 22 | v2 | 允许在 coredump socket 上创建稀疏 coredump |
| FRED + KVM VMX | 22 | v9 | FRED 与 KVM 集成 |
| PCI/P2PDMA: ACS egress 控制修复 | 18 | v4 | PCI P2P DMA ACS 处理修复 |
| HVO 支持 on arm64 | 18 | — | arm64 HugeTLB Vmemmap Optimization |
| iommu/riscv: MSI 重映射、IOMMU_DMA 和 VFIO | 21 | v4 | RISC-V IOMMU 完整支持 |
| maple_tree: 锁检查和清理 | 19 | v3 | maple tree lockdep 增强 |

---

## 🔀 本周 GIT PULL 请求（v7.3 合并窗口）

本周为 v7.3 合并窗口活跃期，子系统维护者提交了 83+ 个 GIT PULL 请求：

**架构/平台**: alpha, ARM/soc, LoongArch, MIPS, m68k, parisc, RISC-V, s390, x86 (alternatives/cache/cleanups/cpu/entry/misc/mm/tdx)

**核心子系统**: Block, Btrfs, Crypto, DMA (dmaengine/dma-mapping), Driver core, IRQ, locking, Modules, RCU, scheduler, slab, printk, probes, livepatching, liveupdate

**设备/驱动**: Bluetooth, DRM, firewire, gpio, HID, I2C, I3C, Mailbox, MMC, PCI, power-supply, Soundwire, thermal, VFIO, vhost/vdpa/virtio

**文件系统**: eCryptfs, exfat, ext4, NFSD, ntfs3, SMB client

**网络**: Networking, ksmbd

**安全**: capabilities, integrity, Landlock

**其他**: auxdisplay, configfs, fbdev, FWCTL, IOMMUFD, perf-tools, RDMA, ras/core, rust-i2c-next

> ⚠️ 值得注意：Steve French 被 replaced 为 CIFS 维护者（smb: client: replace Steve French as CIFS maintainer）。

---

## 📝 本周技术趋势分析

### 1. 安全加固持续深入

本周出现 3 个 CVE 和多个堆溢出/UAF 修复。USB gadget 子系统的 f_uvc 和 f_uac1_legacy 堆溢出展示了 configfs 接口的整数溢出攻击面。密钥子系统和 Landlock 的 UAF 修复表明安全模块的边界条件仍需持续审计。CVE-2025-38616 的 kTLS UAF 修复过程展示了稳定分支回port的复杂性——6.1.y 是最后一个仍缺失修复的受支持分支，需要特殊的 bitfield→bool 改动以支持 `WRITE_ONCE()`。

### 2. 稳定版维护工作量巨大

7 个稳定分支同时发布 14 个版本，合计超过 3,800 个补丁。6.1.183-rc1 单次 609 个补丁和 5.15.216-rc1 的 456 个补丁显示长期支持内核的维护负担在持续增长。5.10（最老的支持分支）仍然接收大量修复（265→266 两版共 624 个补丁）。Greg Kroah-Hartman 以 1,756 封邮件高居贡献榜首，其中绝大部分为稳定版维护工作。

### 3. ARM64 服务器稳定性问题值得关注

麒麟软件报告的海思鲲鹏 920 调度器 `rq->curr` 悬空指针问题影响十余台生产服务器，崩溃前运行时间长达 300 天。该问题发生在空闲转换路径，尽管有多重内存屏障保护（`finish_lock_switch` 释放锁 + `dsb(ish)` + `dsb(sy)` before WFI），存储仍不可见。开发者怀疑可能是平台/硬件层面的存储一致性异常。这可能影响大规模 ARM64 部署的长期稳定性，值得 ARM64 服务器用户和平台厂商关注。

### 4. BPF JIT 安全性提升

本周发现了 BPF JIT may_goto 在私有栈模式下的状态损坏 Bug（寄存器映射错误导致读写错误栈帧），同时社区积极推动 BPF JIT 的 KASAN 检查支持（`bpf-next v7` 系列），以及 m68k 架构的 BPF JIT 编译器初始支持。这些工作表明 BPF 子系统正在加强运行时安全验证和架构覆盖。

### 5. v7.3 合并窗口活跃

本周大量 GIT PULL 请求集中提交，涵盖几乎所有主要子系统。特别是 x86 子系统拆分为 8 个独立 PULL 请求（alternatives/cache/cleanups/cpu/entry/misc/mm/tdx），显示 x86 维护流程的精细化。CIFS 维护者更替也是本周重要的人事变动。新子系统 FWCTL（Firmware Control）和 IOMMUFD 的 PULL 请求显示内核正在发展新的设备控制框架。

### 6. 内存管理重构持续推进

mm/collapse 基于 migration 原语的重建（57 补丁 RFC）、mm/fbatch LRU drain 优化（25 补丁）、maple_tree 锁检查（19 补丁 v3）等大系列继续迭代。Hugh Dickins 的 mm/fbatch 系列系统性移除冗余 LRU drain 调用，有望改善大规模系统性能。mm/khugepaged tracepoint UAF 修复也表明内存管理子系统的调试基础设施在持续完善。

### 7. 回归跟踪机制有效运作

regressions 邮件列表本周活跃，6 个用户级回归被及时报告和二分定位。USB hub Threadripper MCE 回归引发了多个开发者的深入讨论（Michal Pecio、Lovekesh Solanki、Mario Limonciello 等），iommu/amd 启动挂起回归有 IOMMU 维护者 Joerg Roedel 直接参与修复。KernelCI 也报告了多个稳定分支的构建回归（`bh_work` 成员缺失影响 5.10/5.15/6.1/6.6 四个分支），显示自动化 CI 在捕获回port错误方面的价值。

### 8. Rust 生态持续扩展

本周 Rust 相关补丁达到 177 个，包括 rust-i2c-next 的 GIT PULL 请求和 rust kunit 断言增强（可选断言以捕获 taint 和 lockdep 警告），显示 Rust 在内核中的使用范围正在从驱动向测试基础设施扩展。

---

## 🔗 关键链接

- **lore.kernel.org 主站**: [https://lore.kernel.org](https://lore.kernel.org)
- **linux-kernel 列表**: [https://lore.kernel.org/lkml/](https://lore.kernel.org/lkml/)
- **netdev 列表**: [https://lore.kernel.org/netdev/](https://lore.kernel.org/netdev/)
- **regressions 列表**: [https://lore.kernel.org/regressions/](https://lore.kernel.org/regressions/)
- **CVE-2025-38616 TLS 修复**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/e8a3828b253a108759933630e8c5357e3682e7d9/)
- **CVE-2026-64561 KVM MMU 修复**: [lore.kernel.org/stable](https://lore.kernel.org/stable/707173d9b876d73b7ead50e583b93a809833069e/)
- **CVE-2026-74484 binfmt_misc**: [lore.kernel.org/linux-mm](https://lore.kernel.org/linux-mm/2b09f8f3a21f16446f13cb48c9823c27bfd2c1e4/)
- **ARM64 调度器崩溃**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/3d1bacf9a663a74960fdbf8dd7fb1b1fca755f6e/)
- **BPF JIT may_goto Bug**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/d35f2d584829653b47e8c37f488669e4f9496b85/)
- **USB Hub Threadripper 回归**: [lore.kernel.org/lkml](https://lore.kernel.org/lkml/33b4a8603f790127307b22f3689ceffe3064b133/)

---

## ⚖️ 免责声明

- 本周刊基于 lore.kernel.org 公开邮件列表自动爬取和 AI 分析生成
- 补丁分类和严重程度评估为 AI 自动判断，可能与实际影响有出入
- 子系统补丁分布为基于邮件标题的估算，不代表精确统计
- lore.kernel.org 链接中的邮件哈希来自 public-inbox git 仓库
- 如需精确数据，请直接查阅原始邮件列表

---

*Generated: 2026-08-25 | Data: 20,256 emails from 8 mailing lists | [Repository](https://github.com/wangtsingx/kernel-weekly)*
