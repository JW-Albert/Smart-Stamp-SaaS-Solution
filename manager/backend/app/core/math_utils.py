"""
數學核心模組：處理印章指紋計算
（與 stamp-server 邏輯完全一致）
"""
import math
from typing import List, Tuple


def calculate_centroid(points: List[Tuple[float, float]]) -> Tuple[float, float]:
    """
    計算點集合的質心
    
    Args:
        points: 點座標列表 [(x, y), ...]
    
    Returns:
        質心座標 (cx, cy)
    """
    if not points:
        raise ValueError("點列表不能為空")
    
    n = len(points)
    cx = sum(p[0] for p in points) / n
    cy = sum(p[1] for p in points) / n
    return (cx, cy)


def euclidean_distance(p1: Tuple[float, float], p2: Tuple[float, float]) -> float:
    """
    計算兩點之間的歐幾里得距離
    
    Args:
        p1: 第一個點 (x, y)
        p2: 第二個點 (x, y)
    
    Returns:
        距離值
    """
    return math.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2)


def get_normalized_fingerprint(points: List[Tuple[float, float]]) -> List[float]:
    """
    輸入 5 點座標，計算相對於質心的距離比例 (0.0~1.0) 並排序
    
    算法：
    1. 計算質心
    2. 計算每個點到質心的距離
    3. 找出最大距離作為正規化因子
    4. 將所有距離除以最大距離，得到 0.0~1.0 的比例
    5. 排序後返回
    
    Args:
        points: 5 個點座標 [(x, y), ...]，必須是 5 個點
    
    Returns:
        排序後的正規化距離列表 [0.0~1.0, ...]
    """
    if len(points) != 5:
        raise ValueError(f"必須提供 5 個點，但收到 {len(points)} 個")
    
    # 計算質心
    centroid = calculate_centroid(points)
    
    # 計算每個點到質心的距離
    distances = [euclidean_distance(point, centroid) for point in points]
    
    # 找出最大距離作為正規化因子
    max_distance = max(distances)
    
    if max_distance == 0:
        # 所有點都在同一位置，返回 [0.0, 0.0, 0.0, 0.0, 0.0]
        return [0.0] * 5
    
    # 正規化：將距離除以最大距離，得到 0.0~1.0 的比例
    normalized = [d / max_distance for d in distances]
    
    # 排序後返回
    normalized.sort()
    
    return normalized

