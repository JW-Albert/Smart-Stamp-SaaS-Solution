"""
Pydantic 模型定義
"""
from pydantic import BaseModel, Field
from typing import List, Tuple, Optional
from datetime import datetime


class CalibrateRequest(BaseModel):
    """校正請求模型"""
    name: str = Field(..., description="印章名稱")
    points: List[Tuple[float, float]] = Field(
        ...,
        description="5 個觸控點座標",
        min_items=5,
        max_items=5
    )
    description: Optional[str] = Field(None, description="印章描述")


class CalibrateResponse(BaseModel):
    """校正回應模型"""
    stamp_id: int
    name: str
    fingerprint: List[float]
    message: str


class ClientCreate(BaseModel):
    """建立客戶請求模型"""
    name: str = Field(..., description="客戶名稱")


class ClientResponse(BaseModel):
    """客戶回應模型"""
    id: int
    name: str
    api_key: str
    is_active: bool
    created_at: datetime


class PermissionCreate(BaseModel):
    """建立權限請求模型"""
    client_id: int = Field(..., description="客戶 ID")
    stamp_id: int = Field(..., description="印章 ID")


class PermissionResponse(BaseModel):
    """權限回應模型"""
    id: int
    client_id: int
    stamp_id: int
    is_active: bool
    created_at: datetime


class StampResponse(BaseModel):
    """印章回應模型"""
    id: int
    name: str
    fingerprint: List[float]
    description: Optional[str]
    created_at: datetime
    updated_at: datetime

