"""
ベクトル処理ユーティリティ
ベクトルの次元数調整、パース処理などの共通処理
"""

import numpy as np
from typing import List, Tuple


VECTOR_DIMENSION = 1536


def adjust_dimension(embedding: np.ndarray, target_dim: int = VECTOR_DIMENSION) -> np.ndarray:
    """ベクトルの次元数を調整
    
    multilingual-e5-largeは1024次元を出力するが、データベースのvector型は1536次元に設定されているため、
    ゼロパディングで次元数を調整する。
    
    Args:
        embedding: 調整対象のベクトル
        target_dim: 目標次元数（デフォルト: 1536）
    
    Returns:
        次元数調整後のベクトル
    """
    embedding_dim = len(embedding)
    if embedding_dim == target_dim:
        return embedding
    
    if embedding_dim < target_dim:
        return np.pad(embedding, (0, target_dim - embedding_dim), 'constant')
    else:
        return embedding[:target_dim]


def parse_vector_string(vector_str: str) -> np.ndarray:
    """PostgreSQLのvector型文字列をnumpy配列に変換
    
    PostgreSQLのvector型は "[0.1,0.2,0.3,...]" 形式の文字列として返される。
    
    Args:
        vector_str: PostgreSQLのvector型文字列
    
    Returns:
        numpy配列
    """
    vector_str = vector_str.strip('[]')
    return np.array([float(x) for x in vector_str.split(',')], dtype=np.float32)


def ensure_same_dimension(embedding1: np.ndarray, embedding2: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """2つのベクトルの次元数を揃える
    
    Args:
        embedding1: 1つ目のベクトル
        embedding2: 2つ目のベクトル
    
    Returns:
        次元数を揃えた2つのベクトルのタプル
    """
    target_dim = max(len(embedding1), len(embedding2))
    return (
        adjust_dimension(embedding1, target_dim),
        adjust_dimension(embedding2, target_dim)
    )

