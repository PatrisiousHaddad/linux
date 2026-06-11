# Linux Kernel — Repository Overview

This document is a high-level map of this source tree, written to help a new
contributor (human or AI agent) quickly build a mental model of where things
live. It is grounded in the actual directories and files present in this repo
rather than generic kernel theory.

- **Project:** Linux kernel
- **Version (from `Makefile`):** `VERSION = 7`, `PATCHLEVEL = 1`, `SUBLEVEL = 0`,
  `EXTRAVERSION = -rc7`, `NAME = Baby Opossum Posse` (i.e. 7.1-rc7).
- **License:** GPL-2.0, see `COPYING` and `LICENSES/`.
- **Top-level entry docs:** `README`, `Documentation/`.

> AI agents note: `README` (the "AI Coding Assistant" section) requires reading
> `Documentation/process/coding-assistants.rst` before contributing. Key rules
> there: agents MUST NOT add `Signed-off-by` tags (only a human can certify the
> DCO), and AI-assisted commits should carry an `Assisted-by:` tag.

---

## Top-level layout at a glance

| Path | What it holds |
| --- | --- |
| `arch/` | Per-CPU-architecture code (boot, low-level entry, MM, KVM host bits). |
| `kernel/` | Core kernel: scheduler, locking, RCU, time, signals, tracing, BPF. |
| `mm/` | Memory management (page allocator, slab, reclaim, page tables, DAMON). |
| `fs/` | VFS layer plus individual filesystem implementations. |
| `net/` | Networking stack: core, protocol families, netfilter, wireless. |
| `block/` | Block layer and I/O schedulers. |
| `drivers/` | Device drivers (by far the largest tree, ~140+ subdirs). |
| `sound/` | Audio subsystem (ALSA core and drivers). |
| `security/` | LSM framework and security modules (SELinux, AppArmor, etc.). |
| `crypto/` | Kernel crypto API and algorithm implementations. |
| `ipc/` | System V / POSIX IPC (message queues, semaphores, shared memory). |
| `io_uring/` | The io_uring asynchronous I/O subsystem. |
| `virt/` | Virtualization core (`virt/kvm/`) shared across architectures. |
| `init/` | Kernel startup: `init/main.c`, initramfs, root mount. |
| `lib/` | Generic library code (data structures, CRC, compression, KUnit). |
| `include/` | Public/in-tree headers (`include/linux/`, `include/uapi/`, asm-generic). |
| `rust/` | Rust support: kernel crate, bindings, and vendored crates. |
| `scripts/` | Build/check tooling (Kconfig, `checkpatch.pl`, coccinelle, dtc). |
| `tools/` | Userspace tooling and tests (perf, bpf, selftests, KUnit harness). |
| `samples/` | Example/sample code for various subsystems. |
| `Documentation/` | The canonical kernel documentation (reStructuredText). |
| `usr/`, `certs/`, `block/`, `crypto/` | Initramfs packing, module-signing certs, etc. |
| `Makefile`, `Kbuild`, `Kconfig` | Top of the Kbuild/Kconfig build system. |

---

## Subsystems in detail

### Boot and initialization — `init/`, `arch/*/boot`
The kernel's C-level entry point is `init/main.c` (`start_kernel()`), which
brings up subsystems and eventually runs the first userspace process. Root
device / initramfs mounting lives in `init/do_mounts.c` and
`init/initramfs.c`; the initial task is built in `init/init_task.c`. The very
earliest, architecture-specific boot/decompression code lives under each
`arch/<arch>/boot/` (e.g. `arch/x86/boot`).

### Architecture-specific code — `arch/`
One directory per supported ISA: `alpha`, `arc`, `arm`, `arm64`, `csky`,
`hexagon`, `loongarch`, `m68k`, `microblaze`, `mips`, `nios2`, `openrisc`,
`parisc`, `powerpc`, `riscv`, `s390`, `sh`, `sparc`, `um` (User Mode Linux),
`x86`, `xtensa`. A typical arch (see `arch/x86/`) is organized into `boot/`,
`entry/` (syscall/interrupt entry), `kernel/` (arch core such as
`arch/x86/kernel/cpu`, `apic`, `crash.c`), `mm/` (page-table/fault handling),
`kvm/` (virtualization host), `lib/`, `crypto/`, plus `Kconfig`/`Makefile`.

### Core kernel — `kernel/`
The heart of the OS. Notable areas:
- **Process lifecycle:** `kernel/fork.c`, `kernel/exit.c`, `kernel/exec_domain.c`,
  `kernel/kthread.c`, `kernel/signal.c`, `kernel/ptrace.c`.
- **Scheduler:** `kernel/sched/` — `core.c` (the main scheduler),
  `fair.c` (CFS/EEVDF fair class), `rt.c`, `deadline.c`, `idle.c`,
  `ext.c`/`ext_idle.c` (sched_ext / BPF schedulers), PELT load tracking in
  `pelt.c`, and `topology.c`.
- **Locking:** `kernel/locking/` — `mutex.c`, `rwsem.c`, `spinlock.c`,
  `qspinlock.c`, `rtmutex.c`, plus the `lockdep.c` validator.
- **RCU:** `kernel/rcu/` — `tree.c` (tree RCU), `tiny.c`, `srcutree.c`.
- **Time/timers:** `kernel/time/`. **Workqueues:** `kernel/workqueue.c`.
- **Tracing/observability:** `kernel/trace/`, `kernel/events/` (perf core).
- **BPF:** `kernel/bpf/`. **Control groups:** `kernel/cgroup/`.
- **Power/PM:** `kernel/power/`. **Live patching:** `kernel/livepatch/`.

### Memory management — `mm/`
Physical/virtual memory and reclaim. Key files: `mm/page_alloc.c` (buddy
allocator), `mm/slub.c` (SLUB slab allocator), `mm/memory.c` (page-fault and
page-table handling), `mm/vmscan.c` (reclaim), `mm/huge_memory.c` and
`mm/hugetlb.c` (huge pages), `mm/filemap.c` (page cache), `mm/gup.c`
(get_user_pages), `mm/compaction.c`. The `mm/damon/` subdir holds the DAMON
data-access monitor.

### Filesystems — `fs/`
The Virtual File System layer plus concrete filesystems:
- **VFS core:** `fs/namei.c` (path lookup), `fs/dcache.c` (dentry cache),
  `fs/inode.c`, `fs/file.c`/`fs/file_table.c`, `fs/buffer.c`, `fs/exec.c`,
  `fs/aio.c`, `fs/eventpoll.c`, ELF loading via `fs/binfmt_elf.c`.
- **Filesystems (one dir each):** `fs/ext4/`, `fs/btrfs/`, `fs/f2fs/`,
  `fs/xfs` (where present), `fs/fat`/`fs/exfat`, network FS like `fs/nfs`/`fs/ceph`/`fs/9p`,
  pseudo FS like `fs/proc`, `fs/debugfs`, `fs/configfs`, plus overlay/stacking
  helpers (`fs/backing-file.c`).

### Block layer — `block/`
Generic block I/O between filesystems and storage drivers:
`block/blk-core.c` and the `blk-mq` multi-queue machinery, integrity
(`block/bio-integrity*.c`), and I/O schedulers such as BFQ
(`block/bfq-iosched.c`).

### Networking — `net/`
- **Core:** `net/core/` (e.g. `net/core/dev.c`, the netdevice core), `net/socket.c`.
- **Protocol families:** `net/ipv4/` (incl. `net/ipv4/tcp.c`), `net/ipv6/`,
  `net/mptcp/`, `net/tls/`, `net/sctp/`, `net/unix/`.
- **Filtering/QoS:** `net/netfilter/`, `net/sched/` (traffic control), `net/xdp/`.
- **Wireless:** `net/wireless/`, `net/mac80211/`, plus Bluetooth `net/bluetooth/`.
- Headers in `include/net/`; device drivers live separately under `drivers/net/`.

### Device drivers — `drivers/`
The largest part of the tree. Each subsystem is its own subdirectory, e.g.
`drivers/net/` (NICs), `drivers/gpu/` (incl. `drivers/gpu/drm/`), `drivers/usb/`,
`drivers/pci/`, `drivers/scsi/`, `drivers/nvme` (storage), `drivers/i2c/`,
`drivers/gpio/`, `drivers/iommu/`, `drivers/md/` (RAID/device-mapper),
`drivers/mmc/`, `drivers/input/`, and the driver-model core in `drivers/base/`.

### Security — `security/`
The Linux Security Module (LSM) framework lives in `security/security.c` /
`security/lsm_init.c`, with individual modules in `security/selinux/`,
`security/apparmor/`, `security/smack/`, `security/tomoyo/`, `security/yama/`,
`security/landlock/`, and capability logic in `security/commoncap.c`. Keyring
support is under `security/keys/`.

### Crypto, IPC, io_uring, virtualization
- `crypto/` — the kernel crypto API and cipher/hash/compression algorithms.
- `ipc/` — System V & POSIX IPC: `ipc/msg.c`, `ipc/sem.c`, `ipc/shm.c`, `ipc/mqueue.c`.
- `io_uring/` — async I/O ring; entry point `io_uring/io_uring.c` with per-op
  files (`rw.c`, `net.c`, `poll.c`, etc.) and worker pool `io-wq.c`.
- `virt/kvm/` — architecture-independent KVM core, paired with each arch's
  `arch/<arch>/kvm/`.

### Rust support — `rust/`
In-tree Rust integration: the safe abstractions crate `rust/kernel/`
(e.g. `device.rs`, `fs.rs`, `block/`, `drm/`), generated C bindings in
`rust/bindings/`, `rust/uapi/`, helper shims in `rust/helpers/`, proc-macros in
`rust/macros/`, and vendored crates (`pin-init/`, `proc-macro2/`, `quote/`, `syn/`).

### Generic library code — `lib/`
Reusable, arch-independent helpers: data structures, string/bitmap ops, CRC
(`lib/crc/`), compression (`lib/lz4/`, `lib/zstd/`, `lib/xz/`, `lib/zlib_*`),
RAID math (`lib/raid6/`), and the **KUnit** test framework core in `lib/kunit/`
with in-tree tests under `lib/tests/`.

### Headers — `include/`
In-tree headers: `include/linux/` (core internal APIs), `include/uapi/`
(stable userspace ABI), `include/asm-generic/` (fallback arch headers),
plus per-subsystem trees like `include/net/`, `include/drm/`, `include/crypto/`,
`include/kunit/`.

---

## Build system, tooling, and tests

- **Build system (Kbuild/Kconfig):** top-level `Makefile`, `Kbuild`, and
  `Kconfig`, with per-directory `Makefile`/`Kconfig` files throughout the tree.
  Configuration symbols flow from `Kconfig` files into a `.config`.
- **`scripts/`:** developer/build tooling — `scripts/checkpatch.pl` (patch style
  checker), `scripts/coccinelle/` + `scripts/coccicheck` (semantic patches),
  `scripts/dtc/` (device-tree compiler), Kconfig front-ends in `scripts/kconfig`.
- **`tools/`:** standalone userspace programs and harnesses — `tools/perf/`,
  `tools/bpf/`, `tools/objtool/`, plus the **testing** tree:
  - `tools/testing/selftests/` — userspace kernel selftests (per-subsystem
    dirs such as `bpf/`, `cgroup/`, `net/`, `filesystems/`).
  - `tools/testing/kunit/` — KUnit runner that drives `lib/kunit/`.
  - `tools/testing/{vma,memblock,radix-tree,...}` — unit-test scaffolding for
    specific subsystems.
- **In-tree unit tests:** many `*_test.c` / `*_kunit.c` files live beside the
  code they cover (e.g. `kernel/resource_kunit.c`, `mm/dmapool_test.c`,
  `init/initramfs_test.c`).

---

## How to navigate this repo (for a new contributor)

1. **Start with the docs.** `README` routes you by role; the canonical guides
   live in `Documentation/`. For contributing, read
   `Documentation/process/development-process.rst`,
   `Documentation/process/coding-style.rst`, and
   `Documentation/process/submitting-patches.rst`. AI tooling must also read
   `Documentation/process/coding-assistants.rst`.

2. **Find the owner of any code with `MAINTAINERS`.** The top-level
   `MAINTAINERS` file maps file paths to maintainers and mailing lists. Use
   `scripts/get_maintainer.pl <path-or-patch>` to find who to CC.

3. **Map a feature to a directory using the table above.** Roughly: a syscall
   or core behavior → `kernel/`; memory behavior → `mm/`; a file/storage issue
   → `fs/` or `block/`; packets → `net/`; a specific device → `drivers/<class>/`;
   CPU-specific behavior → `arch/<arch>/`.

4. **Follow the build to the code.** Each directory's `Makefile` lists the
   objects compiled for a given `CONFIG_*` symbol, and the matching `Kconfig`
   explains the option. This is the fastest way to confirm whether a file is
   even built in a given configuration.

5. **Headers tell you the contract.** Internal APIs are declared in
   `include/linux/`; anything userspace depends on is in `include/uapi/`.
   Treat `include/uapi/` as a stable ABI — changes there are tightly constrained.

6. **Use the tooling before sending changes.** Run `scripts/checkpatch.pl` on
   your diff, build the relevant config, and run/extend tests in
   `tools/testing/selftests/` or KUnit (`tools/testing/kunit/`) where they exist.

7. **Search effectively.** Symbols are widely reused; prefer ripgrep
   (`rg <symbol>`) scoped to the relevant subsystem directory, and cross-check
   with `MAINTAINERS` to stay within the right subsystem.
