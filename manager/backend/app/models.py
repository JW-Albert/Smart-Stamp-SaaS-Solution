"""
資料庫模型定義（管理端擁有完整 CRUD 權限）
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
import secrets
import hashlib

Base = declarative_base()


class APIClient(Base):
    """API 客戶表"""
    __tablename__ = 'api_clients'
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    api_key = Column(String(255), unique=True, nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)
    
    @staticmethod
    def generate_api_key() -> str:
        """生成新的 API Key"""
        # 生成隨機字串並進行 SHA256 雜湊
        random_str = secrets.token_urlsafe(32)
        api_key = f"sk_{hashlib.sha256(random_str.encode()).hexdigest()[:32]}"
        return api_key


class StampRegistry(Base):
    """印章註冊表"""
    __tablename__ = 'stamp_registry'
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    fingerprint = Column(JSON, nullable=False)  # 存儲正規化指紋列表
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)


class StampPermission(Base):
    """印章權限表：綁定客戶與印章"""
    __tablename__ = 'stamp_permissions'
    
    id = Column(Integer, primary_key=True, index=True)
    client_id = Column(Integer, ForeignKey('api_clients.id'), nullable=False, index=True)
    stamp_id = Column(Integer, ForeignKey('stamp_registry.id'), nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)

