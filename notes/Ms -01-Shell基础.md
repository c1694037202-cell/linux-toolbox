# Missing Semester 第 1 讲：课程概览与 Shell

> 归档位置建议：`linux-toolbox/notes/MS-01-Shell基础.md`
> 对应手册：第 1 月 D2（Shell 基础）、D3（文件系统与权限）、D6（管道与重定向）

---

## 0. 先分清三个词

| 词 | 是什么 |
|---|---|
| **终端(terminal)** | 一个显示文字的**窗口程序**（Windows Terminal、GNOME Terminal） |
| **Shell** | 在窗口里跑的那个**解释器程序**，负责读你的命令并执行（bash / zsh / fish） |
| **Bash** | Shell 的一种具体实现（Bourne Again SHell），Linux 默认 |

换终端不改变你的 shell，换 shell 也不改变终端。`echo $SHELL` 看当前是哪个。

---

## 1. Shell 是怎么理解你敲的那行字的

```bash
echo hello world
```

Shell 把这一行**按空白字符切成若干"词"**：

```
echo    hello    world
 ↑        ↑        ↑
程序名   参数1    参数2
```

**第一个词是要执行的程序，其余全部作为参数传给它。** 这条规则解释了 shell 里 80% 的诡异现象。

### 1.1 空格是分隔符 → 所以要转义

```bash
mkdir my photos          # 错！创建了 my 和 photos 两个目录
mkdir my\ photos         # 反斜杠转义空格，创建了一个叫 "my photos" 的目录
mkdir "my photos"        # 引号，同上
mkdir 'my photos'        # 同上
```

`\` 的含义是：**取消下一个字符的特殊含义**，让它变回普通字符。

### 1.2 单引号 vs 双引号（补充，课上没细讲但极其常用）

```bash
name=Alice
echo "Hello $name"       # Hello Alice    → 双引号内变量会展开
echo 'Hello $name'       # Hello $name    → 单引号内一切都是字面量
```

**经验规则：不确定就用双引号。** 尤其是变量引用一律写 `"$var"`，否则变量值里有空格时会被拆成多个参数（这是 shell 脚本第一大 bug 来源，D12 写 `backup.sh` 时会用上）。

### 1.3 `echo` 的真实用途

`echo` 不只是打印字符串，它是你**观察 shell 展开结果**的显微镜：

```bash
echo $PATH               # 看变量的值
echo *.txt               # 看通配符展开成了什么
echo ~                   # 看 ~ 展开成了什么
```

写复杂命令前先用 `echo` 打一遍，确认展开结果符合预期再真跑——特别是带 `rm` 的时候。

---

## 2. 命令是怎么被找到的：`$PATH`

```bash
echo $PATH
# /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

`PATH` 是一个用 `:` 分隔的目录列表。你敲 `ls`，shell 做的事是：

1. 判断 `ls` 里有没有 `/` → 没有，说明这不是路径，是个"名字"
2. **按顺序**遍历 PATH 里每个目录，找有没有名为 `ls` 的可执行文件
3. 找到第一个就执行，**后面的不再看**
4. 全都没有 → `command not found`

> **顺序很重要**：如果 `/usr/local/bin/python` 和 `/usr/bin/python` 都存在，跑的是 PATH 里排在前面的那个。日后"我明明装了新版本怎么还是旧的"，99% 是这个原因。

### 查询三兄弟

| 命令 | 作用 | 备注 |
|---|---|---|
| `which ls` | 打印会执行哪个文件 | 只查 PATH 里的**外部程序** |
| `type ls` | 打印它是什么**类型** | ⭐ 更该用这个 |
| `whereis ls` | 找程序 + 手册 + 源码 | 偶尔用 |

**为什么 `type` 更好**：有些命令根本不是文件，而是 shell 内置的（builtin）或别名（alias），`which` 会骗你。

```bash
type cd          # cd is a shell builtin        ← 没有 /bin/cd 这个文件！
type ll          # ll is an alias for ls -alF   ← 你自己在 .zshrc 里定义的
type ls          # ls is /usr/bin/ls
```

D5 的验收题"我敲 ls，系统是怎么找到这个程序的"，答案就是上面的 1-4 步 + 先查 alias/builtin 再查 PATH。

### 执行不在 PATH 里的程序

必须显式给出路径，所以自己写的脚本要这样跑：

```bash
./backup.sh              # ./ 不能省，否则 shell 会去 PATH 里找 backup.sh，找不到
/home/you/bin/backup.sh  # 绝对路径也行
```

想省掉 `./`，就把脚本目录加进 PATH（D5 的 `export PATH="$HOME/bin:$PATH"`）。

---

## 3. 在文件系统里导航

### 3.1 路径的两种写法

| | 例子 | 特点 |
|---|---|---|
| **绝对路径** | `/home/you/projects/leetcode` | 以 `/` 开头，从根目录起算，在哪都指同一个地方 |
| **相对路径** | `../notes/git.md` | 不以 `/` 开头，相对**当前工作目录** |

Linux 只有一棵树，根是 `/`，没有 Windows 的 C 盘 D 盘概念。
（WSL 里 Windows 的 C 盘被挂载在 `/mnt/c/`——见 D3 笔记，代码别放那儿。）

### 3.2 四个特殊路径符号

| 符号 | 含义 |
|---|---|
| `.` | 当前目录 |
| `..` | 上一级目录 |
| `~` | 当前用户的家目录，展开为 `/home/你的用户名` |
| `-` | **上一个**待过的目录（只用于 `cd`） |

```bash
pwd              # print working directory，我在哪
cd /usr/bin      # 去某处
cd ..            # 上一级 → /usr
cd ../..         # 上两级 → /
cd ~             # 回家；直接敲 cd 不带参数也是回家
cd -             # 回到上一个目录（在两个远隔的目录间反复横跳时救命）
```

`ls .` 列当前目录（等同于直接 `ls`），`ls ..` 列上级目录——**不用切过去就能看**，这是相对路径的价值。

### 3.3 `ls` 的常用参数

```bash
ls               # 简单列出
ls -a            # 显示隐藏文件（以 . 开头的，如 .git .zshrc）
ls -l            # 长格式，每个文件一行详细信息
ls -lh           # -h 让文件大小human-readable（4.0K 而不是 4096）
ls -la           # 组合使用（等于 -l -a）
ls -lt           # 按修改时间排序，最新的在前
ls --color=auto  # 彩色输出（一般已经在 alias 里了）
```

### 3.4 读懂 `ls -l` 的每一列 ⭐

```
drwxr-xr-x  2  you  staff  4096  Aug 22 10:30  projects
─┬─ ─┬────  ┬  ─┬─  ─┬───  ─┬──  ─────┬──────  ─┬──────
 │   │      │   │    │      │         │         └ 名字
 │   │      │   │    │      │         └ 最后修改时间
 │   │      │   │    │      └ 大小(字节)；对目录是目录项本身的大小，不是内容总和
 │   │      │   │    └ 所属组
 │   │      │   └ 所有者
 │   │      └ 硬链接数
 │   └ 权限位：三组 rwx，依次是 属主 / 属组 / 其他人
 └ 文件类型：d=目录  -=普通文件  l=符号链接  c=字符设备  b=块设备
```

**权限位对文件和对目录的含义完全不同**（这是 D3 的核心，很多人栽在这）：

| 位 | 对**文件** | 对**目录** |
|---|---|---|
| `r` | 能读内容 | 能 `ls` 列出里面有什么 |
| `w` | 能改内容 | 能在里面**创建/删除**文件 ← 注意：删文件看的是**目录**的 w，不是文件的 w |
| `x` | 能作为程序执行 | 能 `cd` 进去、能穿过它访问下层 |

数字表示法：`r=4, w=2, x=1`，三位相加。

- `chmod 755 f` → `rwxr-xr-x`（属主全权，其他人可读可执行）——**脚本和目录的标配**
- `chmod 644 f` → `rw-r--r--`（属主读写，其他人只读）——**普通文件的标配**

> D3 验收题：`-rwxr-xr--` 逐位解释 =
> 普通文件 / 属主可读写执行 / 同组可读可执行 / 其他人只能读。

---

## 4. 操作文件

```bash
mkdir dir                # 建目录
mkdir -p a/b/c           # -p 递归创建多层，且已存在时不报错 ← 脚本里必用

touch file               # 建空文件（本意是更新时间戳，副作用是文件不存在则创建）

cp src dst               # 复制
cp -r srcdir dstdir      # -r 递归，复制目录必须加

mv src dst               # 移动；同目录下移动 = 改名（Linux 没有单独的 rename 命令）
mv old.txt new.txt       # 重命名

rm file                  # 删文件
rm -r dir                # 递归删目录及其内容
rmdir dir                # 只能删【空】目录，非空会报错
```

### 关于 `rm` 的三句话

1. **没有回收站，删了就是删了。** `rm` 不是"移到废纸篓"，是真的解除链接。
2. `rm -rf` 是"递归 + 强制不问"，威力最大也最危险。`rm -rf /` 或 `rm -rf $VAR/`（当 `VAR` 为空时）能毁掉系统。
3. **保护习惯**：删之前先用 `ls` 或 `echo` 把同样的路径打一遍，确认目标正确再改成 `rm`。

`rmdir` 的存在意义就是它"删不动非空目录"——当你**确信**目录该是空的时，用它比 `rm -r` 安全。

---

## 5. 查文档：`--help` / `man` / `tldr`

```bash
ls --help        # 大多数程序支持，输出短，直接在终端滚一屏
man ls           # 完整手册。/关键词 搜索，n 下一个，q 退出
tldr ls          # ⭐ 首选：只给最常用的 5 种用法和例子
```

> Ubuntu 24.04 仓库里没有 `tldr`，装 `tealdeer`：
> `sudo apt install tealdeer && tldr --update`

**顺序建议**：`tldr` 看怎么用 → `--help` 确认参数名 → `man` 查细节。
新手直接读 `man` 只会被劝退，`man` 是给"知道命令干嘛、只是忘了参数"的人用的。

看不懂别人给的长命令时用 <https://explainshell.com>，会逐段拆解。

---

## 6. 终端快捷键（补充，提速最明显的部分）

| 快捷键 | 作用 |
|---|---|
| `Ctrl+L` | 清屏（等价于 `clear`，但更快，且不清除历史） |
| `Ctrl+C` | 发送 **SIGINT**，中断当前前台程序 |
| `Ctrl+D` | 发送 **EOF**（输入结束）。在空提示符下按 = 退出 shell |
| `Ctrl+A` / `Ctrl+E` | 光标跳到行首 / 行尾 |
| `Ctrl+U` / `Ctrl+K` | 删到行首 / 删到行尾 |
| `Ctrl+W` | 删掉光标前一个单词 |
| `Ctrl+R` | ⭐ 反向搜索历史命令，敲片段就能翻出以前的长命令 |
| `Tab` | 补全命令、路径。按两下列出所有候选 |
| `↑` / `↓` | 翻历史 |

**⚠️ 你笔记里的 `^C` 需要澄清**：在 `cat > file` 这类"等待你输入"的场景下，正确的结束方式是 **`Ctrl+D`（EOF，正常结束）**，而不是 `Ctrl+C`（强行中断）。`Ctrl+C` 也能退出来，但语义是"我不干了"，某些程序会因此丢弃已输入的内容。

`Ctrl+C` 和 `kill -9` 的区别留到 D11 讲信号时深入。

---

## 7. 流与重定向（本讲最重要的概念）⭐

### 7.1 每个程序默认有三条流

| 流 | 编号 | 默认连到 |
|---|---|---|
| **stdin**（标准输入） | 0 | 键盘 |
| **stdout**（标准输出） | 1 | 屏幕 |
| **stderr**（标准错误） | 2 | 屏幕 |

**重定向就是把流的两端重新接线。** 程序自己完全不知道自己在读写文件还是终端——这正是 Unix 哲学能成立的基础。

### 7.2 重定向操作符

```bash
echo hello > out.txt      # stdout 写入文件（覆盖！原内容清空）
echo world >> out.txt     # 追加，不覆盖
cat < out.txt             # 从文件读 stdin

command 2> err.txt        # 只重定向错误
command > out.txt 2>&1    # 输出和错误都进同一个文件（2>&1 = 让 2 号流去 1 号流所在的地方）
command &> out.txt        # 上一行的简写（bash/zsh 支持）
command > /dev/null 2>&1  # 全部丢弃，"我只关心它跑没跑成功"
```

> `/dev/null` 是一个特殊设备文件，写进去的一切都消失，俗称黑洞。

### 7.3 `cat file` 和 `cat < file` 的区别 ⭐

你笔记里两种都记了，它们**结果相同但机制完全不同**，这个区别值得记牢：

| 写法 | 谁打开文件 | cat 收到什么 |
|---|---|---|
| `cat file` | **cat 自己**，`file` 作为参数传给它 | 一个文件名，它自己去 open/read |
| `cat < file` | **shell**，在启动 cat 之前就把文件接到 stdin | cat 以为自己在读键盘 |

第二种写法里 cat 根本不知道文件的存在。这说明：**重定向是 shell 干的事，程序毫无察觉。** 记住这句话，7.5 的坑就自然理解了。

`cat` 不带任何参数时，读 stdin 写 stdout，所以：

```bash
cat > note.txt           # 敲内容，Ctrl+D 结束 → 快速造一个测试文件
cat                      # 变成复读机（读一行吐一行），Ctrl+D 退出
```

### 7.4 管道 `|`

```bash
命令A | 命令B            # 把 A 的 stdout 接到 B 的 stdin
```

管道是 Unix 哲学的具体体现：**每个程序只做一件事并做好，通过文本流互相拼接。**

你笔记里的例子：

```bash
curl --head --silent google.com | grep --ignore-case content-length
```

逐段拆解：

| 部分 | 作用 |
|---|---|
| `curl google.com` | 发 HTTP 请求 |
| `--head` | 只要响应头，不要网页正文（相当于 HEAD 请求） |
| `--silent` | 关掉进度条——**关键**：进度条会污染输出，管道场景几乎总要加 |
| `\|` | 把响应头交给下一个程序 |
| `grep --ignore-case xxx` | 不分大小写地筛出包含关键词的行 |

> **注意**：`--silent` 关的是进度条（进度条走的是 stderr），不是响应内容。很多命令都有类似的"安静模式"，做管道时先想想要不要加。

### 7.5 经典陷阱：`sudo` 配重定向必然失败 ⭐

```bash
sudo echo 3 > /sys/class/backlight/intel_backlight/brightness
# bash: /sys/...: Permission denied     ← 加了 sudo 还是拒绝！
```

**原因**：重定向是 **shell**（以你的普通用户身份）做的，它在启动 `echo` **之前**就要打开那个文件。`sudo` 只提升了 `echo` 的权限，而 `echo` 压根没碰过文件。

**解法一：用 `tee`**（`tee` 读 stdin，同时写文件和 stdout）

```bash
echo 3 | sudo tee /sys/class/backlight/intel_backlight/brightness
echo 3 | sudo tee -a file        # -a 相当于 >>（追加）
echo 3 | sudo tee file > /dev/null   # 不想让它回显到屏幕
```

**解法二：整条命令都在 root shell 里跑**

```bash
sudo sh -c 'echo 3 > /sys/.../brightness'
```

这个坑值得单独记一条，因为它会以各种形式反复出现（改 `/etc` 下的配置时最常见）。

---

## 8. root 与 `sudo`

**root** 是 UID 为 0 的超级用户，不受权限检查约束。提示符从 `$` 变成 `#` 就说明你是 root。

```bash
sudo 命令        # ⭐ 以 root 身份执行【这一条】命令，日常唯一推荐
sudo -i          # 开一个 root 的登录 shell（加载 root 的环境）
sudo su          # 切换成 root 用户，之后所有命令都是 root
sudo su - 用户名  # 切换成指定用户
exit             # 从 root shell 退回来
```

**为什么日常用 `sudo` 而不是长期待在 root**：

1. 一个手滑的 `rm -rf` 在普通用户下最多毁掉你的家目录，在 root 下毁掉系统
2. `sudo` 会记日志（`/var/log/auth.log`），出事能查
3. 强制你每次"提权"时停顿一秒，想一下"我真的需要 root 吗"

> `sudo` 的权限由 `/etc/sudoers` 控制，用 `visudo` 编辑（它会做语法检查，直接编辑改错会把自己锁在门外）。

---

## 9. `/sys` 与 backlight：Linux "一切皆文件"的实证

```
/proc    内核和进程的运行时信息（伪文件系统）
/sys     内核对象、设备驱动的接口（sysfs）
```

这两个目录里的"文件"**在硬盘上根本不存在**，是内核在你读取时现场生成的。它们的意义是：**把内核状态暴露成文件，于是 `cat`、`echo`、重定向这套工具链可以直接操作硬件。**

课上的屏幕亮度例子：

```bash
ls /sys/class/backlight/                       # 看有哪个背光设备
cd /sys/class/backlight/intel_backlight/
cat max_brightness                             # 读出最大值，比如 937
cat brightness                                 # 读出当前值
echo 500 | sudo tee brightness                 # 写入 → 屏幕亮度立刻变化
```

顺手可以逛的几个：

```bash
cat /proc/cpuinfo         # CPU 信息
cat /proc/meminfo         # 内存信息
cat /proc/uptime          # 开机时长
cat /sys/class/net/*/address   # 各网卡的 MAC 地址
```

> **WSL2 注意**：WSL 跑在虚拟机里，没有真实的显示设备，`/sys/class/backlight/` 通常是**空的**。这不是你操作错误。想练这个实验，可以改用 `/proc` 下的只读文件观察，或者在真机 Linux 上试。

---

## 10. 其他零散但有用的

### `tail` / `head`

```bash
head -n 10 file          # 前 10 行
tail -n 10 file          # 后 10 行
tail -n +2 file          # 从第 2 行开始到结尾（跳过表头，处理 CSV 常用）
tail -f /var/log/xxx.log # ⭐ -f = follow，实时追踪新增内容，看日志必用，Ctrl+C 退出
```

### `find`

你笔记里的 `sudo find -type` 应该是 `find` 的 `-type` 参数：

```bash
find . -name "*.txt"           # 当前目录递归找所有 .txt
find . -type d                 # 只找目录（d=directory）
find . -type f                 # 只找普通文件（f=file）
find . -type f -name "*.sh"    # 组合条件
find / -name "brightness" 2>/dev/null   # 全盘搜索，把权限报错丢进黑洞
find . -type f -mtime -7       # 7 天内修改过的文件
find . -name "*.tmp" -delete   # 找到并删除（危险，先不加 -delete 确认列表）
```

> `2>/dev/null` 在全盘 `find` 时几乎是标配，否则满屏 "Permission denied" 把结果淹没了。
> 加 `sudo` 则是为了让 find 能进入受限目录。

### `xdg-open`

```bash
xdg-open file.pdf        # 用系统默认程序打开文件，等价于图形界面双击
xdg-open .               # 用文件管理器打开当前目录
xdg-open https://...     # 用默认浏览器打开链接
```

它读 `~/.config/mimeapps.list` 决定用哪个程序。macOS 的对应命令是 `open`。

> **WSL2 里**：装了 `wslu` 后可以用 `wslview`，或者直接 `explorer.exe .` 用 Windows 资源管理器打开当前目录——这条在 WSL 里非常好使。

---

## 11. 速查表（打印/贴墙用）

```bash
# ——— 定位 ———
pwd                     我在哪
cd dir / cd .. / cd ~ / cd -
ls / ls -la / ls -lh / ls -lt

# ——— 文件 ———
mkdir -p a/b/c          递归建目录
touch f                 建空文件
cp -r src dst           复制(目录加 -r)
mv src dst              移动/改名
rm -r dir / rmdir dir   删除

# ——— 查看 ———
cat f                   全部输出
head -n 20 f            前20行
tail -f log             实时追踪
less f                  分页浏览(q 退出)

# ——— 查询 ———
type cmd                这是啥(builtin/alias/文件)
which cmd               在哪个路径
tldr cmd                最常用几种用法
cmd --help              快速参数表

# ——— 流 ———
>   覆盖写      >>  追加写      <   读入
2>  错误重定向  2>&1 错误并入输出   &>  全部
|   管道        /dev/null 黑洞
echo x | sudo tee f     ⭐ sudo 写文件的正确姿势

# ——— 权限 ———
chmod 755 script.sh     rwxr-xr-x 脚本/目录
chmod 644 note.md       rw-r--r-- 普通文件
chmod +x script.sh      加执行权限
sudo cmd                提权执行单条命令
```

---

## 12. 课后练习清单（Missing Semester 第 1 讲原题，建议全做）

- [ ] 确认当前 shell：`echo $SHELL`
- [ ] 在 `/tmp` 下新建目录 `missing`
- [ ] 查看 `touch` 的 man page
- [ ] 在 `missing` 里用 `touch` 创建文件 `semester`
- [ ] 用 `echo` 把 `#!/bin/sh` 和 `curl --head --silent https://missing.csail.mit.edu` 两行写进 `semester`
  （第一行用 `>`，第二行用 `>>`——想清楚为什么）
- [ ] 直接执行 `./semester`，观察报错 → 用 `ls -l` 看权限位，找出原因
- [ ] `chmod` 加执行权限后再跑通
- [ ] 对比 `./semester` 和 `sh semester` 的区别，想清楚为什么后者不需要执行权限
- [ ] 用 `|` 和 `>` 把 `semester` 的输出的**最后修改日期**写入家目录下的 `last-modified.txt`
- [ ] 逛一逛 `/sys`，找出你能读到的一个有趣的系统状态

---

## 13. 自测（答不上就是漏洞）

1. 我敲 `ls` 回车，系统是**按什么顺序**找到这个程序的？
2. `which` 和 `type` 有什么区别，为什么 `which cd` 查不到东西？
3. `cat file` 和 `cat < file` 在机制上有什么不同？
4. `>` 和 `>>` 分别在什么时候用？误用 `>` 会发生什么？
5. `2>&1` 是什么意思，为什么要写在 `> file` **后面**？
6. 为什么 `sudo echo 1 > /sys/xxx` 会失败？两种正确写法是什么？
7. `chmod 755` 具体给了谁什么权限？目录的 `x` 位是什么含义？
8. 一个文件我没有 `w` 权限，但我能删掉它吗？（提示：看目录）
9. `Ctrl+C` 和 `Ctrl+D` 在 `cat > file` 场景下有什么区别？
10. `/proc` 和 `/sys` 里的文件为什么在磁盘上不存在？

---

## 附：本讲遗留到后面的伏笔

| 概念 | 什么时候重逢 |
|---|---|
| `Ctrl+C` 背后的信号机制 | D11 进程与信号 → 第 4 月 CSAPP 第 8 章 |
| 正则表达式（`grep` 的 `-E`） | D9 grep 与正则 |
| shell 脚本的变量、循环、`$1` | D4 / D12 |
| `find` 的高级用法与 `xargs` | D10 文本处理 |
| SSH 与远程 | D26 |
