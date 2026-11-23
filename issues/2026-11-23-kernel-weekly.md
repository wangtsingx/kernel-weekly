> 自动爬取 lore.kernel.org 邮件列表，AI 分析生成
> 覆盖时间：2026-11-16 至 2026-11-23
> 数据源：linux-kernel, netdev, linux-mm, linux-block, linux-pm, linux-security-module, stable, regressions

## 📊 本周概览

| 指标 | 数量 |
|------|------|
| 邮件总数 | 22,898 |
| 原始帖子（非回复） | 22,898 |
| 补丁（含 PATCH） | 21,109 |
| RFC 提案 | 1,013 |
| 补丁系列（0/N 系列） | 728 |

> **注**：本周 netdev、linux-mm、linux-pm、linux-security-module、stable 列表的 git 仓库 clone 因网络原因未能成功，数据主要来自 linux-kernel（22,199）、linux-block（582）和 regressions（117）。

### 类型分布
- bug/崩溃: 673
- 安全漏洞: 334
- 性能问题: 179
- 回归问题: 136
- 功能补丁: ~15,000
- 修复补丁: ~5,000
- 讨论/RFC: 1,013

### 严重程度分布
- 🔴 严重: 12
- 🟠 高: 35
- 🟡 中: 80
- 🟢 低: ~22,771

## 🔴 严重问题

> 本周发现 12 个严重问题

### 1. fs/ceph: 多处 MDS map 使用后释放（UAF）漏洞系列
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🔴 严重
- **影响子系统**: fs/ceph
- **描述**: 徐晗翔 提交了一个包含 7 个独立 UAF（Use-After-Free）漏洞的系列报告，全部围绕 ceph 文件系统中 MDS（Metadata Server）map 的并发访问问题。多个代码路径在未持有 `mdsc->mutex` 的情况下读取 `mdsc->mdsmap`，而该 map 可能被并发更新释放，导致释放后读取。涉及 `ceph_get_tree()`、`ceph_statfs()`、`__ceph_setxattr()`、debugfs `mdsmap_show()`、caps renew、MDS reconnect 等多个路径。
- **修复方案**: 所有访问 `mdsc->mdsmap` 的路径都需在 `mdsc->mutex` 保护下进行，或使用 RCU/引用计数保护 map 生命周期。
- **补丁链接**: [ceph UAF 系列](https://lore.kernel.org/linux-kernel/)

### 2. syzbot: KASAN slab-use-after-free in ppp_disconnect_channel
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🔴 严重
- **影响子系统**: net/ppp
- **描述**: syzbot 报告 PPP 频道断开时存在 slab-use-after-free 读取，可能导致内核内存损坏或信息泄露。
- **修复方案**: 需要在 `ppp_disconnect_channel()` 中正确管理 channel 引用计数，确保断开时无并发访问。
- **补丁链接**: [syzbot 报告](https://lore.kernel.org/linux-kernel/)

### 3. ext4: silent data loss when a split at I/O completion gets ENOSPC
- **邮件列表**: linux-kernel / regressions
- **类型**: 回归问题
- **严重程度**: 🔴 严重
- **影响子系统**: fs/ext4
- **描述**: 回归报告：当 I/O 完成时进行 extent split 操作遇到 ENOSPC，ext4 会静默丢失数据，用户无感知。这是一个数据完整性问题，影响 v7.x 内核。
- **修复方案**: Zhang Yi 等已参与讨论，需确保 split 失败时正确回滚或报错而非静默丢弃。
- **补丁链接**: [回归报告](https://lore.kernel.org/regressions/)

### 4. timers/nohz: Oops in wake_up_nohz_cpu with cpumask index -1
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🔴 严重
- **影响子系统**: kernel/time (NOHZ)
- **描述**: Eryepa Yerepilov 报告 NOHZ 定时器子系统中 `wake_up_nohz_cpu()` 出现 oops，cpumask 索引为 -1，表明存在越界访问。Frederic Weisbecker 已参与分析。
- **修复方案**: 需检查 cpumask 索引计算逻辑，确保不出现 -1 的无效值。
- **补丁链接**: [BUG 报告](https://lore.kernel.org/linux-kernel/)

### 5. ext4: NULL pointer dereference in jbd2_journal_file_inode during inline data conversion
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🔴 严重
- **影响子系统**: fs/ext4, fs/jbd2
- **描述**: 在 inline data 转换过程中 `jbd2_journal_file_inode()` 出现 NULL 指针解引用。syzbot 也报告了相关的 `jbd2_journal_dirty_metadata` WARNING。Theodore Ts'o 参与了修复讨论。
- **修复方案**: William Chuang 提交了 [PATCH 0/2] 修复两个 journal credit 短缺问题，需在 inline data 转换前正确附加 jinode。
- **补丁链接**: [ext4 journal 修复](https://lore.kernel.org/linux-kernel/)

### 6. tls: socket use-after-free during device-down
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🔴 严重
- **影响子系统**: net/tls
- **描述**: kTLS 在网络设备 down 时存在 socket use-after-free，可能导致内核崩溃。Rishikesh Jethwani 提交了 v5 修复补丁，Jakub Kicinski 已审阅。
- **修复方案**: 在设备 down 事件中正确同步 TLS 上下文与 socket 生命周期。
- **补丁链接**: [PATCH net v5 1/2](https://lore.kernel.org/linux-kernel/)

## 🟠 高优先级问题

### 7. [REGRESSION] ublk: dispatched IO intermittently never posts its fetch completion (v7.0)
- **邮件列表**: linux-block / regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: block/ublk
- **描述**: ublk 驱动在 v7.0 中出现 IO 间歇性无法完成 fetch completion 的问题，导致 IO 挂起。Luciano Lo Giudice 报告，Ming Lei 和 Jens Axboe 参与讨论。
- **修复方案**: 需要 fix ublk IO 完成路径的竞态条件。

### 8. [REGRESSION] nouveau: GM108 hangs at boot since devinit double-running vbios scripts fix (6.18.64)
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: drm/nouveau
- **描述**: 6.18.64 中 "try to avoid double-running vbios scripts" 补丁导致 GM108 GPU 启动挂起。Sasha Levin 已参与标记 stable 回归。
- **修复方案**: 需要回滚或修复 devinit 补丁对 GM108 的适用性。

### 9. [REGRESSION] NFSv4 server: sec=krb5p mount fails with EIO in 6.1.192
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: fs/nfs
- **描述**: 6.1.192 稳定版中 NFSv4 使用 krb5p 安全模式挂载失败返回 EIO。Max Vozeler 报告，Sasha Levin 已参与。
- **修复方案**: 需要定位 6.1.192 中引入的 NFS 相关补丁并修复或回退。

### 10. [REGRESSION] brcmfmac BCM43602: DMAR read faults and firmware timeouts on 7.3.3
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: drivers/net/wireless/broadcom/brcm80211
- **描述**: BCM43602 WiFi 芯片在 7.3.3 中开启 intel_iommu 时出现 DMAR read faults 和固件超时，7.2.14 正常或使用 iommu=pt 可规避。
- **修复方案**: 需排查 DMA 映射相关的回归补丁。

### 11. [REGRESSION] r8169: RTL8127A SFP+ link fails to come up in 7.4-rc3
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: drivers/net/ethernet/realtek/r8169
- **描述**: RTL8127A（XID 6c9）SFP+ 链路在 7.4-rc3 中无法建立（inband/10gbase-r 模式）。Andrew Lunn 已参与排查。
- **修复方案**: 需要排查 7.4 开发周期中 r8169 的 PHY 配置变更。

### 12. [REGRESSION] ext4: silent data loss — ENOSPC split at I/O completion
（见严重问题 #3）

### 13. cxl/region: Fix self-deadlock when cxl_memdev_attach_region() fails
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🟠 高
- **影响子系统**: cxl
- **描述**: CXL 区域 attach 失败时出现自死锁。Junho Cha 提交了 v2 修复补丁。
- **修复方案**: 已有 [PATCH v2] 修复，需调整锁获取顺序。

### 14. firmware: arm_scmi: Fix deadlock between reboot notifier and forceful work
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🟠 高
- **影响子系统**: firmware/arm_scmi
- **描述**: SCMI 固件子系统在 reboot notifier 和 forceful work 之间存在死锁。Cristian Marussi 提交 v2 修复，Chengyu Liu 参与测试。
- **修复方案**: [PATCH v2 1/2] 调整 reboot 路径锁顺序。

### 15. driver core: platform: fix swnode use-after-free on device release
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🟠 高
- **影响子系统**: driver core, i2c
- **描述**: Johan Hovold 提交 8 补丁系列修复 software node 在设备释放时的 UAF，涉及 driver core 和 i2c core。v3 版本已提交。
- **修复方案**: [PATCH v3 0/8] 系列修复 swnode 生命周期管理。

### 16. wifi: ath9k_htc: fix use-after-free of tx cleanup timer after failed start
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🟠 高
- **影响子系统**: drivers/net/wireless/ath/ath9k
- **描述**: ath9k_htc 启动失败后 tx cleanup timer 存在 UAF。Mikołaj Pisula 提交 v2 修复。
- **修复方案**: [PATCH v2] 正确取消定时器并释放资源。

### 17. [REGRESSION] core scheduling latency with idle load
- **邮件列表**: linux-kernel
- **类型**: 性能问题
- **严重程度**: 🟠 高
- **影响子系统**: kernel/sched
- **描述**: 空闲负载下 core scheduling 出现调度延迟回归。Mihail Mihov 报告，K Prateek Nayak 参与分析。
- **修复方案**: 需排查 core scheduling 相关的调度器变更。

### 18. [REGRESSION] ALSA: hda/realtek: Higole F9B fixup breaks speakers on unrelated Apollo Lake laptop
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: sound/pci/hda
- **描述**: Higole F9B 的 ALSA fixup 导致无关的 Apollo Lake 笔记本扬声器损坏。Takashi Iwai 已参与修复。
- **修复方案**: 需收紧 fixup 的匹配条件，避免误匹配。

### 19. [REGRESSION] iwlwifi IO_PAGE_FAULT and Master Disable Timed Out
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: drivers/net/wireless/intel/iwlwifi
- **描述**: iwlwifi 出现 IO_PAGE_FAULT 和 Master Disable 超时。Thorsten Leemhuis 已标记。
- **修复方案**: 需排查 iwlwifi 的 DMA/PCI 相关变更。

### 20. [REGRESSION][NTFS] Linux 7.3.4 mounts 64K-cluster NTFS read-only after $MFTMirr mismatch
- **邮件列表**: regressions
- **类型**: 回归问题
- **严重程度**: 🟠 高
- **影响子系统**: fs/ntfs3
- **描述**: 7.3.4 中 64K 簇大小的 NTFS 卷因 $MFTMirr record 24 不匹配而被挂载为只读。Namjae Jeon 参与修复。
- **修复方案**: 已有补丁修复 SEEK_DATA/SEEK_HOLE 对 WOF 压缩和去重文件的处理。

### 21. syzbot: possible deadlock in vfs_iocb_iter_write (netfs?)
- **邮件列表**: linux-kernel
- **类型**: bug/崩溃
- **严重程度**: 🟠 高
- **影响子系统**: fs/netfs
- **描述**: syzbot 报告 netfs 写路径中 `vfs_iocb_iter_write` 存在潜在死锁。
- **修复方案**: 需分析锁依赖链并消除循环等待。

## 🟡 中等问题

### 22. net: emaclite / altera: Fix potential use-after-free during removal
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: net/ethernet
- **描述**: Guangshuo Li 提交两个补丁修复 emaclite 和 altera 网络驱动在设备移除时的 UAF。

### 23. dmaengine: Fix teardown races, resource leaks, and error handling (11-patch series)
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: dmaengine
- **描述**: Lee Jones 提交 11 补丁系列修复多个 DMA 引擎驱动的 teardown 竞态、资源泄漏和错误处理问题，涉及 jz4780、bestcomm、amlogic、ptdma、arm-dma350 等。

### 24. plx_dma fixes (6-patch series)
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: dmaengine/plx_dma
- **描述**: Logan Gunthorpe 提交 6 补丁修复 plx_dma 的描述符环泄漏、锁使用不当、RCU 下调用 pci_irq_vector 等问题。

### 25. usb: dwc2: fix low power issues found on stm32mp1 (7-patch series)
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: usb/dwc2
- **描述**: Fabrice Gasnier 提交 v5 系列（7 补丁）修复 stm32mp1 上 dwc2 的低功耗问题，包括中断风暴、PM 域关闭后恢复、VBUS 重复使能等。

### 26. [REGRESSION] ntfs3: files/dirs with ':' in name became inaccessible in 7.3
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: fs/ntfs3
- **描述**: 7.3 中默认开启 ADS 后，文件名含冒号的 NTFS 文件/目录变得不可访问。

### 27. [REGRESSION] i915: UHBR training fails with TB5 dock
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: drm/i915
- **描述**: i915 UHBR 训练在 TB5 dock 上失败，FFE 更新被跳过。Dave Airlie 参与讨论。

### 28. [REGRESSION] thunderbolt: Barlow Ridge DP tunnel reports UHBR20 for HBR3-only DP OUT
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: thunderbolt
- **描述**: Barlow Ridge 雷电控制器 DP 隧道在 HBR3-only DP 输出口报告 UHBR20，导致外接显示器黑屏（v7.2→v7.3 回归）。

### 29. [REGRESSION] gpio: shared-proxy: open-drain regulators on ODROID-HC4 fail with -EPERM
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: gpio
- **描述**: ODROID-HC4 上 open-drain 调节器因 shared-proxy GPIO 回归而失败返回 -EPERM。

### 30. [REGRESSION] netfilter: flowtable: XMIT_NEIGH flows sent to 00:00:00:00:00:00
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: net/netfilter
- **描述**: netfilter flowtable 中下一跳邻居条目消失后，XMIT_NEIGH 流量被发送到全零 MAC 地址。

### 31. iomap: fix offset truncation in iomap_fill_dirty_folios() on 32-bit
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: fs/iomap
- **描述**: 32 位系统上 `iomap_fill_dirty_folios()` 存在偏移截断问题。

### 32. can: j1939: fix null-ptr-deref in j1939_session_completed()
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: net/can
- **描述**: J1939 协议会话完成时存在空指针解引用。

### 33. KVM: PPC: BookE: Fix boot hang on preemptible kernels
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: arch/powerpc/kvm
- **描述**: KVM PPC BookE 在可抢占内核上启动挂起，v4 系列（3 补丁）修复中断处理。

### 34. LoongArch: KVM: Fix uninitialized stack read in dmsintc_inject_irq()
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: arch/loongarch/kvm
- **描述**: LoongArch KVM 中断注入存在未初始化栈读取。

### 35. btrfs: fix bytes_may_use underflow after failed tree block allocation
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: fs/btrfs
- **描述**: Btrfs 在树块分配失败后 bytes_may_use 下溢。

### 36. accel/rocket: Fix NULL deref and double-free in job submit error path
- **类型**: 修复补丁
- **严重程度**: 🟡 中
- **影响子系统**: drivers/accel/rocket
- **描述**: Rocket 加速器在 job 提交错误路径存在空指针解引用和双重释放。

### 37. [REGRESSION] Suspected amdgpu graphics regression on Ryzen 9 7950X since 6.18.58
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: drm/amdgpu
- **描述**: 6.18.58 后 Ryzen 9 7950X 上 amdgpu 出现图形回归。

### 38. [REGRESSION] Logitech G733 USB audio volume issue since Linux 7.3
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: sound/usb
- **描述**: Logitech G733 USB 音频设备在 7.3 中出现音量问题。

### 39. Unable to compile 6.12 kernels on SPARC64 since 6.12.105
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: arch/sparc
- **描述**: SPARC64 架构自 6.12.105 起无法编译内核。

### 40. [REGRESSION] rtsx_usb_sdmmc: RTS5129 no longer detects SD card
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: drivers/mmc/host/rtsx_usb_sdmmc
- **描述**: RTS5129 读卡器在内核更新后不再检测 SD 卡。

### 41. [REGRESSION] net: stmmac: v6.1.y clears xstats.pcpu_stats in __stmmac_open()
- **类型**: 回归问题
- **严重程度**: 🟡 中
- **影响子系统**: net/ethernet/stmicro/stmmac
- **描述**: 6.1.y 稳定版中 stmmac 在 `__stmmac_open()` 清除 xstats.pcpu_stats 导致回归。

### 42. [REGRESSION] x86: RCU in __module_address() slows kTLS+wrk workload
- **类型**: 性能问题
- **严重程度**: 🟡 中
- **影响子系统**: arch/x86, module
- **描述**: `__module_address()` 使用 RCU 后导致 kTLS+wrk 工作负载性能下降（KASAN+PROVE_LOCKING+kmemleak 配置下）。

## 🟢 低优先级

- drm/radeon: stop the GPU before kexec — kexec 前正确停止 GPU
- drm/gud: fix potential divide error due to optimisation — 优化导致的除零修复
- ksmbd: do not log a stale security descriptor as an error — 日志级别修正
- usb: octeon-hcd: fix kernel-doc — 文档修正
- mips: cavium-octeon: fix missing prototypes — 原型声明修复
- perf annotate: fix annotate crash for fused instructions — perf 工具修复
- mm/page_ext: remove unused page_ext_iter_get() — 清理未使用代码
- dmaengine: dmatest: Avoid unsigned underflow in min_odd() — 测试工具修复
- 多个 dt-bindings 文档更新和驱动小修复

## 📋 本周补丁统计

- 总补丁数: 21,109
- 补丁系列: 728
- RFC 提案: 1,013
- 已合入（含 Reviewed-by/Acked-by 标记）: ~3,500
- 讨论中: ~17,600

## 🔗 关键链接

- linux-kernel 列表: https://lore.kernel.org/lkml/
- linux-block 列表: https://lore.kernel.org/linux-block/
- regressions 列表: https://lore.kernel.org/regressions/
- 本周重点线程:
  - ceph UAF 系列: https://lore.kernel.org/linux-kernel/ (徐晗翔)
  - ublk IO 完成回归: https://lore.kernel.org/linux-block/
  - ext4 数据丢失回归: https://lore.kernel.org/regressions/
  - swnode UAF 修复系列: https://lore.kernel.org/linux-kernel/ (Johan Hovold)
  - LSM hook 重命名系列: https://lore.kernel.org/linux-kernel/

## 📝 本周技术趋势分析

本周内核社区活动非常活跃，共抓取 22,898 封邮件。主要趋势：

1. **文件系统安全修复集中爆发**：ceph 文件系统被发现 7 个 UAF 漏洞，ext4 出现静默数据丢失回归和 journal credit 短缺问题，ntfs3 出现多处兼容性回归。这表明文件系统并发访问路径的审计仍在持续，stable 内核的回归问题需要更多关注。

2. **DMA 引擎子系统大规模修复**：Lee Jones 和 Logan Gunthorpe 分别提交了 11 补丁和 6 补丁系列，系统性地修复了多个 DMA 引擎驱动的 teardown 竞态、资源泄漏和错误处理问题，反映出 DMA 子系统长期积累的技术债务正在被清理。

3. **回归问题数量显著**：本周 regressions 列表记录了 25+ 个独立回归线程，涵盖 GPU（nouveau、amdgpu、i915）、网络（r8169、brcmfmac、iwlwifi、stmmac）、存储（ublk、ntfs3）、音频（ALSA hda、USB audio）等多个子系统。7.3/7.4 开发周期的回归密度较高，需要 stable 团队重点关注。

4. **LSM Hook 架构演进**：本周期出现 17 补丁系列重构 LSM（Linux Security Module）hook 命名和参数传递，从 inode 级别向 path 级别迁移，这是安全子系统的重要架构改进。

5. **netfs/bvecq 重构持续推进**：David Howells 的 v18 系列（17 补丁）持续推进 netfs 子系统从 folioq 向 bvecq 迁移，涉及 afs、cifs 等文件系统。

6. **syzbot 持续发现深层问题**：本周 syzbot 报告了 PPP UAF、netfs 死锁、ext4 journal 警告、media GPF 等多个问题，持续为内核安全提供自动化测试保障。

---
*由 Multica autopilot 自动生成于 2026-11-23*
