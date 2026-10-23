# 🔍 内核邮件列表周刊 — 2026-08-25

> 自动爬取 lore.kernel.org 邮件列表，AI 分析生成
> 覆盖时间：2026-08-18 至 2026-08-25
> 数据源：linux-kernel, netdev, linux-mm, linux-block, linux-pm, linux-security-module, stable, regressions

---

## 📊 本周概览

| 指标 | 数量 |
|------|------|
| 邮件总数 | 20,237 |
| 原始帖子（非回复） | 10,008 |
| 补丁邮件 | 8,904 |
| GIT PULL 请求 | 290 |
| syzbot 报告 | 246 |
| CVE 相关 | 3 个（CVE-2025-38616, CVE-2026-64561, CVE-2026-74484） |
| 回归报告（原始） | 27 |
| 涉及稳定版分支 | 7 个（5.10, 5.15, 6.1, 6.6, 6.12, 6.18, 7.1） |

### 各邮件列表分布

| 邮件列表 | 邮件数 |
|----------|--------|
| linux-kernel | 12,061 |
| stable | 3,914 |
| netdev | 1,940 |
| linux-mm | 1,398 |
| linux-pm | 437 |
| linux-block | 282 |
| linux-security-module | 120 |
| regressions | 85 |

### 子系统补丁分布（估算）

| 子系统 | 补丁数 |
|--------|--------|
| 网络 (net/tcp/udp/bluetooth/wifi/mptcp) | ~3,949 |
| 内存管理 (mm/hugetlb/slab/mglru) | ~2,432 |
| 架构 (x86/arm64/riscv/powerpc) | ~2,033 |
| GPU/DRM | ~1,235 |
| 调度/BPF/perf/tracing | ~1,331 |
| 电源/热管理 | ~1,205 |
| 块设备/NVMe/SCSI | ~834 |
| 文件系统 (ext4/xfs/btrfs/smb) | ~736 |
| 测试 | ~795 |
| USB/HID/Input | ~714 |
| 安全 (selinux/apparmor/landlock/keys) | ~387 |
| Rust | ~224 |

### 本周稳定版发布

| 分支 | 版本 | 补丁数 |
|------|------|--------|
| 5.10.y | 5.10.266-rc1 | 235 |
| 5.15.y | 5.15.217-rc1 | 272 |
| 6.1.y | 6.1.184-rc1 | 303 |
| 6.6.y | 6.6.153-rc2 | 160 |
| 6.12.y | 6.12.105-rc1 | 220 |
| 6.18.y | 6.18.46-rc1 | 217 |
| 7.1.y | 7.1.10-rc1 | 228 |

---

## 🔴 严重问题

> 本周发现 10 个严重问题，涉及安全漏洞、内核崩溃和数据损坏

### 1. CVE-2025-38616: TLS ULP 数据丢失（6.1.y 回填修复）
- **邮件列表**: stable
- **类型**: 安全漏洞
- **严重程度**: 🔴 严重
- **影响子系统**: net/tls
- **描述**: TLS ULP (Upper Layer Protocol) 层存在数据丢失漏洞。当数据从 TLS ULP 下方消失时（如 TCP 层操作），TLS 层可能读取到无效数据。该漏洞已在 6.6.y（自 6.6.103）、6.12.y（自 6.12.43）、6.18.y 和 7.1.y 中修复，但 6.1.y 是唯一仍缺少修复的支持分支。补丁包含两个提交：一个前提修复（将 `msg_ready` 从位域转换为 `bool` 以支持 `WRITE_ONCE`），以及实际的 CVE 修复。
- **修复方案**: 回填 Jakub Kicinski 的 `tls: handle data disappearing from under the TLS ULP` 和 Sabrina Dubroca 的 `tls: fix lockless read of strp->msg_ready in ->poll`。已在 KASAN v6.1.182 构建上验证，打了补丁的内核通过了 1,000 轮复现测试。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/all/20260822000018.48130-1-artem@trailofbits.com/)

### 2. CVE-2026-64561: KVM x86 MMU 页面错误重试缺陷（5.15.y 回填修复）
- **邮件列表**: stable
- **类型**: 安全漏洞
- **严重程度**: 🔴 严重
- **影响子系统**: KVM x86 MMU
- **描述**: KVM x86 MMU 在处理页面错误时未正确检查根是否被 memslot 更新失效，可能导致虚拟机逃逸或权限提升。这是 v2 回填版本（v1 为 Sasha Levin 的系列），包含 8 个补丁，重构了 TDP MMU 页面错误处理路径，并在 `kvm_tdp_mmu_page_fault()` 中使用 `is_page_fault_stale()` 检查。
- **修复方案**: 回填 Sean Christopherson 等人的 8 个补丁，包括重命名 `mmu_notifier_*` 为 `mmu_invalidate_*`、拆分 TDP MMU 页面错误处理、检查无效/过期根等。涉及 14 个文件，+223/-128 行。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/all/20260823130743.1-k@mgml.me/)

### 3. CVE-2026-74484: binfmt_misc 沙箱挂载自引用 DoS
- **邮件列表**: linux-mm
- **类型**: 安全漏洞
- **严重程度**: 🔴 严重
- **影响子系统**: binfmt_misc
- **描述**: CVE-2026-74484 的引入提交被更正为 `21ca59b365c0` ("binfmt_misc: enable sandboxed mounts", v6.7)。在该提交之前，非特权用户或容器无法在受限命名空间中触发自引用 DoS。沙箱挂载功能引入后，攻击面被扩大。
- **修复方案**: 已由 Greg KH 确认并推送更新记录。`.vulnerable` 文件已创建指向引入提交。

### 4. USB Gadget f_uvc Extension Unit 描述符堆溢出
- **邮件列表**: linux-kernel
- **类型**: 安全漏洞
- **严重程度**: 🔴 严重
- **影响子系统**: USB gadget / UVC
- **描述**: f_uvc 的 Extension Unit 描述符长度计算存在整数溢出。`bNrInPins` 和 `bControlSize` 各接受 0..255 范围，描述符实际长度为 24 + p + n 字节，但存储在 `u8 bLength` 字段中，当超过 255 时静默回绕。`uvc_copy_descriptors()` 按回绕后的 `bLength` 分配缓冲区，但 `UVC_COPY_XU_DESCRIPTOR()` 按实际大小拷贝，导致最多 512 字节的堆越界写入。攻击链：对 UVC gadget 的 configfs 属性有写权限即可触发，无需 USB 流量，单次 bind 即可。
- **修复方案**: 在所有四个 configfs 入口点拒绝描述符不适合 `bLength` 的组合，并使 `uvc_copy_descriptors()` 拒绝 `bLength` 与内容不匹配的 Extension Unit。补丁已到 v4 版本，经 Andy Shevchenko 等审查。
- **补丁链接**: [lore.kernel.org](https://lore.kernel.org/all/20260825010442.1-haofeng.li@buaa.edu.cn/)

### 5. SMB3 客户端加密写入数据丢失
- **邮件列表**: regressions
- **类型**: bug/数据损坏
- **严重程度**: 🔴 严重
- **影响子系统**: fs/smb/client, netfs
- **描述**: 对加密 SMB3 挂载的大缓冲写入可能丢失数据。每个 `write()` 返回成功，但一个或多个 `wsize` 大小的范围永远不到达服务器。根因：每个加密写入需要一个 order-4 的连续分配（4 MiB wsize，1027 个 scatterlist 条目），当 `kzalloc(GFP_NOFS)` 失败返回 `-ENOMEM` 时，该错误不被分类为可重试（仅 `-EAGAIN` 和 `-ECONNABORTED` 重试），子请求被标记为 `NETFS_SREQ_FAILED` 且不重发。从 6.1 升级到 6.12.53 后发现。
- **修复方案**: 将 `-ENOMEM` 分类为可重试错误，或在 netfs 层增加内存分配重试机制。

### 6. ext4 fast_commit 日志损坏（fsync 未链接文件后崩溃）
- **邮件列表**: linux-kernel
- **类型**: bug/数据损坏
- **严重程度**: 🔴 严重
- **影响子系统**: ext4, journal
- **描述**: 在 ext4 启用 fast_commit 时，以下操作序列导致崩溃后无法挂载文件系统（"Structure needs cleaning"）：(1) 创建目录和文件 (2) 同步文件系统 (3) 打开文件 (4) 删除文件 (5) 对文件调用 fsync (6) 系统崩溃。在 Linux 7.2 和 6.17.0-29-generic 上复现。
- **修复方案**: 需要修复 fast_commit 在处理未链接文件 fsync 时的日志记录逻辑。已提供 C 语言复现程序。

### 7. sched/fair: enqueue 路径除零错误导致内核 Panic
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🔴 严重
- **影响子系统**: sched/fair
- **描述**: `__calc_prop_weight()` 在 enqueue 路径中触发除零错误，导致 kernel panic。在 CachyOS 7.2.0 上复现，idle CPU 接收唤醒 IPI 时在 `enqueue_task_fair` 中崩溃。由于 swapper 无法被杀死，直接 panic 而非 oops。问题与 flat-hierarchy 系列相关，cpuset 的 effective mask 为空导致除零。
- **修复方案**: 需要在 `__calc_prop_weight()` 中添加除零保护，或修复导致 cpuset effective mask 为空的根因。

### 8. keys: keyctl_chown_key 竞争条件导致 Use-After-Free
- **邮件列表**: linux-security-module
- **类型**: 安全漏洞
- **严重程度**: 🔴 严重
- **影响子系统**: security/keys
- **描述**: `keyctl_chown_key()` 在持有 `key->sem` 时替换 `key->user`，释放信号量后丢弃旧的 `key_user` 引用。但 `/proc/keys` 迭代器和 `find_keyring_by_name()` 在持有不相关锁的情况下解引用 `key->user`，导致竞争窗口：CPU 0 读取旧的 `key->user` → CPU 1 替换并释放 → CPU 0 读取已释放内存。影响版本：自 `454804ab0302` 起。
- **修复方案**: 使用 `key_user_lock` 序列化命名空间映射读取和指针替换。

### 9. Landlock: hook_path_link Use-After-Free
- **邮件列表**: linux-security-module
- **类型**: 安全漏洞
- **严重程度**: 🔴 严重
- **影响子系统**: security/landlock
- **描述**: `current_check_refer_path()` 在不持有引用或锁的情况下读取 `old_dentry->d_parent`。`hook_path_link()` 没有保护：`do_linkat()` 持有源 dentry 的引用但不锁定或引用其父目录，因此并发 `rename(2)` 可以在 `security_path_link()` 运行时重新设置源的父目录，原父目录随后被移除并释放。任何能用 `LANDLOCK_ACCESS_FS_REFER` 沙箱化自己的进程都可通过 `linkat(2)` 循环与 `rename(2)` 和 `rmdir(2)` 竞争触发。KASAN 确认 slab-use-after-free。
- **修复方案**: 使用 `dget_parent()` 获取父目录引用，在层次遍历和审计记录完成后释放。`Cc: stable` 已添加。

### 10. khugepaged Tracepoint Use-After-Free
- **邮件列表**: linux-mm
- **类型**: bug/崩溃
- **严重程度**: 🔴 严重
- **影响子系统**: mm/khugepaged
- **描述**: khugepaged 的 tracepoints 接收 folio 指针并调用 `folio_pfn()`，但此时 folio 可能已不再有效：在 `folio_put()`、`folio_unlock()` 或 `pte_unmap_unlock()` 之后被释放，或者根本不是 folio 而是 xarray 编码的 swap 条目。在经典 SPARSEMEM 上，一旦启用 trace event 就会导致 khugepaged oops。
- **修复方案**: 直接传递 pfn 给 tracepoints，在 folio 仍然被 pin 时捕获。v3 版本关闭了 UAF 窗口。

---

## 🟠 高优先级问题

> 本周发现 12 个高优先级问题，涉及功能不可用和严重回归

### 1. USB Hub 回归：Threadripper 7970X 上 MCE / 数据架构同步洪泛
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: USB, xHCI, CPU idle
- **描述**: 自 6.12.36+ 起，USB hub 恢复后的延迟工作触发未纠正的 MCE 和数据架构同步洪泛，导致 Threadripper 7970X 硬件重置。已二分定位到 `aec11e5f9c45`。复现条件：CPU 进入 C2 空闲状态时触发（`processor.max_cstate=1` 可规避）。普通用户通过 USB 设备访问即可导致系统完全崩溃。Mario Limonciello 认为这可能是平台固件 bug。
- **修复方案**: 等待进一步分析，可能需要 OEM 更新 BIOS 或内核中规避特定 xHCI 控制器行为。

### 2. iommu/amd: 启动挂起回归
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: iommu/amd
- **描述**: 提交 `dc266f6c4e26` ("iommu/amd: Fix premature break in init_iommu_one()") 导致 NixOS 系统 6.18.40 无法启动。根因：IVRS 广告的 EFR 与 IOMMU MMIO 寄存器读取的实际 EFR 不同，该补丁暴露了已有的 bug。
- **修复方案**: Vasant Hegde 提供了初步修复补丁，正确修复 `late_iommu_features_init()` 使用实际 EFR。

### 3. bnxt_en: page_pool_create_percpu() 失败导致网卡无法启动
- **邮件列表**: netdev
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: net/bnxt_en, page_pool
- **描述**: 6.18.45 上 bnxt_en 网卡无法启动，日志显示 `page_pool_create_percpu() gave up with errno -22`。
- **修复方案**: 修复已在本周排队的 page_pool 补丁中。

### 4. blk-mq: hctx 在 nr_hw_queues 更新时丢失 TAG_QUEUE_SHARED 标志
- **邮件列表**: linux-block
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: block/blk-mq, NVMe
- **描述**: `blk_mq_update_nr_hw_queues()` 后，tag set 上的每个 hctx 可能丢失 `BLK_MQ_F_TAG_QUEUE_SHARED` 标志。`blk_mq_alloc_hctx()` 刻意屏蔽该位，但 `__blk_mq_realloc_hw_ctxs()` 在队列数不变时也会重新初始化每个 hctx，且不重新应用该标志。导致 NVMe-TCP/RDMA 每次重连或控制器重置都触发此问题。标志丢失交替出现，可能是未被注意到的原因。
- **修复方案**: 在 `__blk_mq_update_nr_hw_queues()` 的重新分配路径中重新应用 `BLK_MQ_F_TAG_QUEUE_SHARED` 标志。

### 5. PCI: Dynamic OF Node 创建在无效桥配置上挂起
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: PCI
- **描述**: v6.17-rc1 引入的动态 PCI OF 节点代码在 Dell XPS 8940 (Intel i7-11700, Rocket Lake) 上导致启动极早失败。`CONFIG_PCI_DYNAMIC_OF_NODES=y` 时显示黑屏，机器挂起。v6.19-rc5 因 RP1 驱动不再选择该选项而正常启动。
- **修复方案**: 在创建动态 OF 节点时跳过无效的桥配置。

### 6. hp_bioscfg: 模块初始化导致启动挂起
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: platform/x86, hp_bioscfg
- **描述**: HP Laptop 15-bs1xx 上 hp_bioscfg 模块初始化时导致启动挂起。7.0.0-30-generic 受影响，6.17.0-40-generic 正常。黑名单 `hp_bioscfg` 或 `acpi=off` 可规避。

### 7. Bluetooth: btrtl RTL8761B 扫描修复导致其他设备不可用
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: Bluetooth/btrtl
- **描述**: 提交 `5ead2063611a` 为所有 CHIP_ID_8761B 设置 `HCI_QUIRK_BROKEN_EXT_SCAN`，在 USB 0bda:a728 上验证有效，但破坏了 0bda:8771：扩展扫描正常工作，但固件停止响应传统扫描禁用命令，导致控制器重置，所有已连接 BLE 设备断开。已到达 7.1.9 和 6.18.45。
- **修复方案**: 回退该提交，恢复 v7.2 前的行为。基于检测的修复正在讨论中。

### 8. futex: 私有哈希增长在高负载下可能无法完成
- **邮件列表**: regressions
- **类型**: 性能问题/回归
- **严重程度**: 🟠 高
- **影响子系统**: futex
- **描述**: futex 私有哈希增长需要所有线程暂时不使用 futex，以便引用计数器降至 0 完成转换。但在高负载下（如 96 线程持续执行 `FUTEX_WAKE_PRIVATE`），引用计数器永远不降至 0，转换可能数十秒无法完成。
- **修复方案**: Thomas Gleixner 正在参与讨论，可能需要改进转换机制或允许强制转换。

### 9. powercap: intel_rapl PMU 解绑时内核 Panic
- **邮件列表**: linux-pm
- **类型**: bug/崩溃
- **严重程度**: 🟠 高
- **影响子系统**: powercap/intel_rapl
- **描述**: `rapl_package_add_pmu()` 失败时将全局 `rapl_pmu.pmu` 结构清零并返回错误，但先前已探测的包保留 `has_pmu = true`。驱动解绑时对清零的结构调用 `perf_pmu_unregister()`，导致 NULL list head 上的 `list_del_rcu()` 引发内核 panic。
- **修复方案**: 在尝试注销前检查 PMU 是否实际已注册。已由 Rafael Wysocki 作为 7.3-rc 材料应用。

### 10. AppArmor: Unix Socket ctx->peer NULL 指针解引用
- **邮件列表**: linux-security-module
- **类型**: bug/崩溃
- **严重程度**: 🟠 高
- **影响子系统**: security/apparmor
- **描述**: `aa_unix_file_perm` 的辅助函数假设 `ctx->peer` 已设置，但 `ctx->peer` 仅对流连接和 socket pair 记录。`unix_dgram_connect` 设置 `unix_peer(sk)` 但不经过该路径，因此已连接的 AF_UNIX 数据报 socket 有 `unix_peer(sk)` 但 `ctx->peer` 仍为 NULL，首次需要重新验证的写入触发 NULL 指针解引用。
- **修复方案**: 在辅助函数中检查 `ctx->peer` 是否为 NULL，或在 `unix_dgram_connect` 路径中设置 `ctx->peer`。

### 11. loop: lo_rw_aio() NULL 指针解引用
- **邮件列表**: linux-block
- **类型**: bug/崩溃
- **严重程度**: 🟠 高
- **影响子系统**: block/loop
- **描述**: syzbot 报告 `lo_rw_aio()` 中的 NULL 指针解引用。分析认为由提交 `65565ca5f99b` 引入的时序变化暴露。Tetsuo Handa 和 Bart Van Assche 正在讨论修复方案，分歧在于是否需要显式 `synchronize_rcu()` 和 `drain_workqueue()`。Handa 指出 `__loop_clr_fd()` 中无法安全调用这些函数（锁反转风险）。
- **修复方案**: v6 补丁引入待处理 I/O 请求的宽限期刷新。讨论仍在进行中。

### 12. MPTCP: 14 补丁修复系列（v7.3-rc1）
- **邮件列表**: netdev
- **类型**: 修复补丁
- **严重程度**: 🟠 高
- **影响子系统**: net/mptcp
- **描述**: Matthieu Baerts 提交了 14 个 MPTCP 修复，覆盖 v5.7 到 v7.3-rc0 的多个问题，包括：fallback socket 的 RTX 定时器错误调度、SYN cookies 中 backup 标志丢失、ADD_ADDR ID 溢出、uninit-value in `mptcp_write_data_fin`、selftests 中的 UAF 等。

---

## 🟡 中等问题

> 本周发现 8 个中等问题

### 1. thermal: gov_power_allocator NULL 指针解引用
- **类型**: bug/崩溃 | 🟡 中 | **子系统**: thermal
- **描述**: `power_allocator_update_tz()` 无条件从 `params->trip_max` 派生 trip 描述符，但 `params->trip_max` 允许为 NULL（当区域既无被动也无主动 trip 点时），导致解引用虚假指针。
- **修复方案**: 在 `params->trip_max` 为 NULL 时提前返回。

### 2. mm/hugetlb: memfd 错误路径 resv_huge_pages 双重递减
- **类型**: bug | 🟡 中 | **子系统**: mm/hugetlb
- **描述**: `alloc_hugetlb_folio_reserve()` 不设置 `HPageRestoreReserve`，当 `hugetlb_add_to_page_cache()` 失败时，`folio_put()` 不恢复预留，随后的 `hugetlb_unreserve_pages()` 再次递减，导致每次失败分配 `resv_huge_pages` 偏差 1。
- **修复方案**: 在 `alloc_hugetlb_folio_reserve()` 中消费预留时设置 `HPageRestoreReserve`。

### 3. mm/vmalloc: vmap_purge_lock 内存压力下活锁
- **类型**: bug | 🟡 中 | **子系统**: mm/vmalloc

### 4. amd-pstate: Cezanne (Ryzen 7 5800U) 数据架构同步洪泛
- **类型**: bug | 🟡 中 | **子系统**: cpufreq/amd-pstate
- **描述**: Bugzilla #221909 报告 amd-pstate 在 Cezanne 平台上 CPPC max_perf 控制的数据架构同步洪泛问题。

### 5. ASoC: amd: acp6x PDM DMA 内存泄漏
- **类型**: bug | 🟡 中 | **子系统**: ASoC/amd

### 6. can: usb: f81604: struct 大小不匹配
- **类型**: bug | 🟡 中 | **子系统**: can/usb

### 7. mm/mglru: 潜在 generation folio 数量泄漏
- **类型**: bug | 🟡 中 | **子系统**: mm/mglru

### 8. acp6x: PDM 中断禁用函数清除 mask 位错误
- **类型**: bug | 🟡 中 | **子系统**: ASoC/amd/renoir

---

## 🟢 低优先级

> 本周发现多个低优先级问题（简要列出）

- **IMA**: 允许用户通过 `IMA_MEASURE_PCR_IDX` 指定 PCR 索引
- **keys**: 拒绝超过索引长度的描述
- **loop**: 分拆 `loop_change_fd()`、修复递归检测和竞争条件（Bart Van Assche 13 补丁系列）
- **blk-wbt**: 设置延迟时始终将 `enable_state` 改为 `MANUAL`
- **NVMe multipath**: 修复分区的 diskstats
- **mempolicy**: 修复 `alloc_pages_bulk_weighted_interleave()` 中的睡眠分配
- **maple_tree**: 文档修复、死代码清理（Liam Howlett v3 19 补丁系列）
- **selftests**: cgroup zswap 修复、mm 修复
- **cpufreq**: acpi-cpufreq P-state 索引不匹配修复

---

## 📋 v7.3 合并窗口进展

本周是 v7.3-rc1 合并窗口周，Linus Torvalds 合并了大量子系统 GIT PULL 请求（共 290 个），涵盖：

| 子系统 | 维护者 |
|--------|--------|
| MM | Andrew Morton |
| 网络 | Jakub Kicinski |
| 块设备 | Jens Axboe |
| x86 (entry/mm/tdx/cache/cpu/alternatives) | Dave Hansen / Borislav Petkov |
| KVM | Paolo Bonzini |
| PCI | Bjorn Helgaas |
| RISC-V | Paul Walmsley |
| Btrfs | David Sterba |
| RCU | Paul E. McKenney |
| Rust | Miguel Ojeda |
| 安全 (capabilities/landlock/integrity) | Serge Hallyn / Mickaël Salaün / Mimi Zohar |
| 热管理 | Rafael J. Wysocki |
| 文件系统 (ext4/exfat/ksmbd/smb/ntfs3) | Ted Ts'o / Namjae Jeon / Paulo Alcantara |
| 声卡 | Takashi Iwai |
| 加密 | Herbert Xu |

Linus 对 x86/alternatives 的评论：移除 smp_locks alternatives 机制（用于在 UP 机器上运行 SMP 内核时 patch out lock 前缀），表示"早该做了"。

---

## 📝 本周技术趋势分析

1. **安全审计持续深入**：本周出现 3 个 CVE 和多个堆溢出/UAF 修复。USB gadget f_uvc 的 Extension Unit 描述符整数溢出特别值得关注——configfs 接口的整数溢出攻击面此前未被充分重视。keys 和 landlock 的 UAF 都需要特定竞争条件触发，但均可被非特权用户利用。

2. **v7.3 合并窗口活跃**：本周有 290 个 GIT PULL 请求被处理，涵盖几乎所有主要子系统。Rust 子系统继续推进，i2c Rust 驱动首次通过 GIT PULL 合入。

3. **稳定版维护负担沉重**：7 个稳定分支同时发布 RC，合计超过 1,635 个补丁。5.10（235 补丁）和 6.1（303 补丁）作为最老的支持分支仍然接收大量修复。

4. **AMD 平台稳定性问题集中爆发**：Threadripper 7970X 的 USB hub MCE 回归和 Cezanne (Ryzen 7 5800U) 的 amd-pstate 数据架构同步洪泛，加上 iommu/amd 的启动挂起回归，显示 AMD 平台在 C-state 和 IOMMU 交互方面存在深层次固件/驱动协调问题。

5. **回归跟踪机制有效运作**：regressions 邮件列表本周活跃，多个严重回归被及时报告和二分定位。USB hub MCE、iommu/amd 启动挂起、PCI Dynamic OF 节点挂起等都得到了开发者快速响应。

6. **内存管理修复持续**：khugepaged tracepoint UAF、hugetlb 双重递减、mglru folio 泄漏、vmalloc 活锁等多个 mm 修复显示内存管理子系统的复杂性和持续维护需求。

7. **蓝牙子系统兼容性问题**：RTL8761B 的 LE 扫描修复"一人之药他人之毒"——修复一个设备的同时破坏了另一个设备，凸显 USB 蓝牙控制器固件差异性问题。回退是本周的正确决策。

8. **调度器 flat-hierarchy 系列引入新问题**：sched/fair 的除零 panic 表明 flat-hierarchy 重构系列引入了未预见的边界条件（空 cpuset effective mask），需要更多测试和除零保护。

---

*由 Multica autopilot 自动生成于 2026-08-25*
*数据采集方式: git clone lore.kernel.org public-inbox 仓库 (HTTP API 受 Anubis 机器人保护)*
