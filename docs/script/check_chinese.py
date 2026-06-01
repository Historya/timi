#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
递归遍历文件夹，检查文本文件是否包含中文字符
✅ 支持：文件夹遍历 / 多编码自动识别
✅ 过滤：以 /// 开头的行（不统计这些行的中文）
✅ 跳过：图片、压缩包等二进制文件
"""
import os
import sys

# 中文字符 Unicode 范围
CHINESE_START = "\u4e00"
CHINESE_END = "\u9fff"

# 自动尝试编码
ENCODINGS = ["utf-8", "gbk", "gb2312", "gb18030"]

# 跳过的二进制文件后缀（可自行增删）
SKIP_SUFFIX = {
    ".exe", ".dll", ".bin", ".jpg", ".jpeg", ".png", ".gif", ".bmp",
    ".mp4", ".mp3", ".wav", ".zip", ".rar", ".7z", ".tar", ".gz",
    ".pdf", ".docx", ".xlsx", ".ico", ".svg", ".webp"
}

def has_chinese(text: str) -> bool:
    """判断一段文本是否包含中文字符"""
    for char in text:
        if CHINESE_START <= char <= CHINESE_END:
            return True
    return False

def check_single_file(file_path: str) -> tuple[bool, list]:
    """
    检查单个文件
    过滤规则：以 /// 开头的行，不检查中文
    :return: (是否含中文, 含中文的行号列表)
    """
    for enc in ENCODINGS:
        try:
            with open(file_path, "r", encoding=enc) as f:
                chinese_lines = []
                line_num = 0

                for line in f:
                    line_num += 1
                    stripped_line = line.strip()

                    # 🚀 核心过滤：跳过以 /// 开头的行
                    if stripped_line.startswith("///"):
                        continue

                    # 只检查非注释行的中文
                    if has_chinese(line):
                        chinese_lines.append(line_num)

                return len(chinese_lines) > 0, chinese_lines

        except (UnicodeDecodeError, PermissionError, OSError):
            continue

    # 所有编码都失败，视为无中文
    return False, []

def traverse(root_path: str):
    """递归遍历文件夹"""
    total = 0
    has_cn_files = 0

    if not os.path.exists(root_path):
        print(f"❌ 路径不存在：{root_path}")
        return

    print(f"🚀 开始扫描：{root_path}\n")

    for dirpath, _, filenames in os.walk(root_path):
        for filename in filenames:
            ext = os.path.splitext(filename)[1].lower()
            if ext in SKIP_SUFFIX:
                continue

            full_path = os.path.join(dirpath, filename)
            total += 1

            has_cn, lines = check_single_file(full_path)
            if has_cn:
                has_cn_files += 1
                print(f"✅ 含中文 | {full_path} | 有效行号：{lines}")

    # 统计结果
    print("\n" + "-" * 70)
    print(f"📊 扫描完成：")
    print(f"   总文本文件：{total} 个")
    print(f"   包含中文（过滤///注释后）：{has_cn_files} 个")
    print(f"   无中文文件：{total - has_cn_files} 个")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使用方法：")
        print(f"  python {sys.argv[0]} <文件/文件夹路径>")
        print("示例：")
        print(f"  python {sys.argv[0]} ./test")
        sys.exit(1)

    traverse(sys.argv[1])