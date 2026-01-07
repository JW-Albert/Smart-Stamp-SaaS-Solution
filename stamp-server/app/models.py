"""
資料庫模型定義
注意：此程式只有唯讀權限（stamp_registry）和只寫權限（stamping_logs）
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
from datetime import datetime

Base = declarative_base()


class APIClient(Base):
    """API 客戶表（唯讀）"""
    __tablename__ = 'api_clients'
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    api_key = Column(String(255), unique=True, nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)


class StampRegistry(Base):
    """印章註冊表（唯讀）"""
    __tablename__ = 'stamp_registry'
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    fingerprint = Column(JSON, nullable=False)  # 存儲正規化指紋列表
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)


class StampPermission(Base):
    """印章權限表（唯讀）：綁定客戶與印章"""
    __tablename__ = 'stamp_permissions'
    
    id = Column(Integer, primary_key=True, index=True)
    client_id = Column(Integer, ForeignKey('api_clients.id'), nullable=False, index=True)
    stamp_id = Column(Integer, ForeignKey('stamp_registry.id'), nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)


class StampingLog(Base):
    """印章驗證日誌表（只寫）"""
    __tablename__ = 'stamping_logs'
    
    id = Column(Integer, primary_key=True, index=True)
    client_id = Column(Integer, nullable=False, index=True)
    stamp_id = Column(Integer, nullable=True, index=True)  # 如果驗證失敗則為 None
    status = Column(String(50), nullable=False)  # 'valid', 'invalid', 'error'
    fingerprint = Column(JSON, nullable=True)  # 記錄驗證時使用的指紋
    error_message = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=func.now(), nullable=False, index=True)

