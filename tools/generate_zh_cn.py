"""Generate a Simplified Chinese ARB from the upstream Traditional Chinese ARB.

Source: ViPER4Windows/lib/l10n/app_zh_TW.arb
Output: ViPER4Windows/lib/l10n/app_zh_CN.arb

Requires: pip install opencc-python-reimplemented
"""

import json
from pathlib import Path

import opencc

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "ViPER4Windows" / "lib" / "l10n" / "app_zh_TW.arb"
DST = ROOT / "ViPER4Windows" / "lib" / "l10n" / "app_zh_CN.arb"

PRE_REPLACEMENTS = {
    "把目前設定存成預設": "将当前设置保存为预设",
    "最後音量": "最终音量",
    "校正檔": "校正文件",
    "音場": "声场",
    "品質": "质量",
    "目前": "当前",
    "置中": "居中",
    "拉起": "提升",
    "重設": "重置",
    "等化器": "均衡器",
    "喇叭": "扬声器",
    "作用中的播放端點": "正在使用的播放端点",
    "作用中": "生效中",
    "未作用": "未生效",
    "找不到": "未找到",
    "最佳化": "优化",
    "影像": "声像",
    "效果聲": "效果声",
    "側聲道": "侧声道",
    "追蹤": "跟踪",
    "階數": "阶数",
    "模擬": "模拟",
    "取代": "替换",
    "識別碼": "ID",
    "檔案": "文件",
    "自訂": "自定义",
    "一般耳機": "普通耳机",
    "一般耳塞": "普通耳塞",
    "高階": "高端",
    "極致": "极致",
    "入門": "入门",
    "原聲": "原声",
    "搖滾": "摇滚",
    "嗎": "吗",
    "門檻": "阈值",
    "連線": "连接",
    "程式通訊": "进程通信",
    "共享記憶體": "共享内存",
    "重新開機": "重新启动",
    "開機時啟動": "开机自启",
    "＋": "+",
}

POST_REPLACEMENTS = {
    "缺省": "预设",
    "重新开机": "重新启动",
    "作用中": "生效中",
    "未作用": "未生效",
    "找不到": "未找到",
    "喇叭": "扬声器",
    "等化器": "均衡器",
    "覆蓋": "覆盖",
    "「": "“",
    "」": "”",
}


def apply_replacements(text: str, replacements: dict[str, str]) -> str:
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text


def main() -> None:
    converter = opencc.OpenCC("tw2sp")
    with SRC.open(encoding="utf-8") as handle:
        data = json.load(handle)

    data["@@locale"] = "zh_CN"

    for key, value in data.items():
        if key.startswith("@") or not isinstance(value, str):
            continue
        text = apply_replacements(value, PRE_REPLACEMENTS)
        text = converter.convert(text)
        text = apply_replacements(text, POST_REPLACEMENTS)
        data[key] = text

    DST.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote {DST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
