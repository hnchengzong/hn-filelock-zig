# hn-filelock-zig

![Zig](https://img.shields.io/badge/Zig-F7A41D?logo=zig&logoColor=white)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=archlinux&logoColor=white)

一个使用 Zig 编写的简单的文件加密解密工具。

## 编译与使用

```bash

zig build

# 生成的二进制文件路径：
zig-out/bin/hn_filelock_zig

# 使用方法
./hn_filelock_zig 文件... -e/-d -k 密钥 [-o 输出] [-m 方法] [-h]

# 参数说明
- -e：加密模式
- -d：解密模式
- -k 密钥：设置加密/解密密钥
- -o 输出：指定输出文件或目录
- -m 方法：指定加密算法（xor / add）
- -h：显示帮助信息

# 使用默认 xor 加密
./zig-out/bin/hn_filelock_zig ./test/1.txt -e -k key

# 使用 add 算法加密
./zig-out/bin/hn_filelock_zig ./test/1.txt -e -k key -m add

# 解密文件
./zig-out/bin/hn_filelockg_zig ./test/1.txt.filelock -d -k key -m add

# 查看帮助
./zig-out/bin/hn_filelock_zig -h

```

## AUR

`paru -S hn-filelock-zig-bin`

使用：

`hn-filelock --args`
