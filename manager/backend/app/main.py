"""
Smart Stamp 管理後台 - 後端 API
"""
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db, engine
from app.core.math_utils import get_normalized_fingerprint
from app.models import APIClient, StampRegistry, StampPermission, Base
from app.schemas import (
    CalibrateRequest, CalibrateResponse,
    ClientCreate, ClientResponse,
    PermissionCreate, PermissionResponse,
    StampResponse
)

# 初始化 FastAPI
app = FastAPI(
    title="Smart Stamp Management Dashboard",
    description="管理後台 API - 印章校正、客戶管理、權限管理",
    version="1.0.0"
)

# CORS 設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生產環境應限制特定域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    """啟動時建立資料表（如果不存在）"""
    Base.metadata.create_all(bind=engine)


@app.get("/")
async def root():
    """健康檢查端點"""
    return {
        "service": "Smart Stamp Management Dashboard",
        "status": "running",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    """健康檢查"""
    return {"status": "healthy"}


# ==================== 印章管理 ====================

@app.post("/admin/stamps/calibrate", response_model=CalibrateResponse)
async def calibrate_stamp(
    request: CalibrateRequest,
    db: Session = Depends(get_db)
):
    """
    印章校正：接收 5 點座標，計算指紋並儲存為新印章
    """
    try:
        # 計算指紋
        fingerprint = get_normalized_fingerprint(request.points)
        
        # 建立新印章
        stamp = StampRegistry(
            name=request.name,
            fingerprint=fingerprint,
            description=request.description
        )
        
        db.add(stamp)
        db.commit()
        db.refresh(stamp)
        
        return CalibrateResponse(
            stamp_id=stamp.id,
            name=stamp.name,
            fingerprint=fingerprint,
            message="印章校正成功"
        )
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"伺服器錯誤: {str(e)}")


@app.get("/admin/stamps", response_model=List[StampResponse])
async def list_stamps(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """列出所有印章"""
    stamps = db.query(StampRegistry).offset(skip).limit(limit).all()
    return stamps


@app.get("/admin/stamps/{stamp_id}", response_model=StampResponse)
async def get_stamp(
    stamp_id: int,
    db: Session = Depends(get_db)
):
    """取得單一印章資訊"""
    stamp = db.query(StampRegistry).filter(StampRegistry.id == stamp_id).first()
    if not stamp:
        raise HTTPException(status_code=404, detail="印章不存在")
    return stamp


@app.delete("/admin/stamps/{stamp_id}")
async def delete_stamp(
    stamp_id: int,
    db: Session = Depends(get_db)
):
    """刪除印章"""
    stamp = db.query(StampRegistry).filter(StampRegistry.id == stamp_id).first()
    if not stamp:
        raise HTTPException(status_code=404, detail="印章不存在")
    
    db.delete(stamp)
    db.commit()
    return {"message": "印章已刪除"}


# ==================== 客戶管理 ====================

@app.post("/admin/clients", response_model=ClientResponse)
async def create_client(
    request: ClientCreate,
    db: Session = Depends(get_db)
):
    """
    建立新客戶並生成 API Key
    """
    # 生成 API Key
    api_key = APIClient.generate_api_key()
    
    # 確保 API Key 唯一
    while db.query(APIClient).filter(APIClient.api_key == api_key).first():
        api_key = APIClient.generate_api_key()
    
    # 建立客戶
    client = APIClient(
        name=request.name,
        api_key=api_key,
        is_active=True
    )
    
    db.add(client)
    db.commit()
    db.refresh(client)
    
    return client


@app.get("/admin/clients", response_model=List[ClientResponse])
async def list_clients(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """列出所有客戶"""
    clients = db.query(APIClient).offset(skip).limit(limit).all()
    return clients


@app.get("/admin/clients/{client_id}", response_model=ClientResponse)
async def get_client(
    client_id: int,
    db: Session = Depends(get_db)
):
    """取得單一客戶資訊"""
    client = db.query(APIClient).filter(APIClient.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="客戶不存在")
    return client


@app.put("/admin/clients/{client_id}/toggle")
async def toggle_client_status(
    client_id: int,
    db: Session = Depends(get_db)
):
    """切換客戶啟用狀態"""
    client = db.query(APIClient).filter(APIClient.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="客戶不存在")
    
    client.is_active = not client.is_active
    db.commit()
    db.refresh(client)
    
    return {"message": f"客戶狀態已更新為 {'啟用' if client.is_active else '停用'}"}


# ==================== 權限管理 ====================

@app.post("/admin/permissions", response_model=PermissionResponse)
async def create_permission(
    request: PermissionCreate,
    db: Session = Depends(get_db)
):
    """
    綁定客戶與印章（建立權限）
    """
    # 檢查客戶是否存在
    client = db.query(APIClient).filter(APIClient.id == request.client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="客戶不存在")
    
    # 檢查印章是否存在
    stamp = db.query(StampRegistry).filter(StampRegistry.id == request.stamp_id).first()
    if not stamp:
        raise HTTPException(status_code=404, detail="印章不存在")
    
    # 檢查權限是否已存在
    existing = db.query(StampPermission).filter(
        StampPermission.client_id == request.client_id,
        StampPermission.stamp_id == request.stamp_id
    ).first()
    
    if existing:
        if existing.is_active:
            raise HTTPException(status_code=400, detail="權限已存在")
        else:
            # 重新啟用
            existing.is_active = True
            db.commit()
            db.refresh(existing)
            return existing
    
    # 建立新權限
    permission = StampPermission(
        client_id=request.client_id,
        stamp_id=request.stamp_id,
        is_active=True
    )
    
    db.add(permission)
    db.commit()
    db.refresh(permission)
    
    return permission


@app.get("/admin/permissions", response_model=List[PermissionResponse])
async def list_permissions(
    client_id: int = None,
    stamp_id: int = None,
    db: Session = Depends(get_db)
):
    """列出權限（可依客戶或印章過濾）"""
    from sqlalchemy import or_
    
    query = db.query(StampPermission)
    
    if client_id:
        query = query.filter(StampPermission.client_id == client_id)
    if stamp_id:
        query = query.filter(StampPermission.stamp_id == stamp_id)
    
    # 只返回啟用的權限
    query = query.filter(StampPermission.is_active == True)
    
    permissions = query.all()
    return permissions


@app.delete("/admin/permissions/{permission_id}")
async def delete_permission(
    permission_id: int,
    db: Session = Depends(get_db)
):
    """刪除權限（軟刪除：設為非啟用）"""
    permission = db.query(StampPermission).filter(StampPermission.id == permission_id).first()
    if not permission:
        raise HTTPException(status_code=404, detail="權限不存在")
    
    permission.is_active = False
    db.commit()
    
    return {"message": "權限已刪除"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)

