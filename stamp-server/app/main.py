"""
Smart Stamp 核心驗證伺服器
只做一件事：告訴客戶這個印章是否有效
"""
from fastapi import FastAPI, HTTPException, Depends, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Tuple, Optional
from sqlalchemy.orm import Session
import os

from app.core.database import get_core_db, get_business_db
from app.core.security import SecurityManager, verify_api_key
from app.core.math_utils import get_normalized_fingerprint, calculate_mse, calculate_max_error
from app.models import StampRegistry, StampPermission, StampingLog

# 初始化 FastAPI
app = FastAPI(
    title="Smart Stamp Verification Server",
    description="核心驗證伺服器 - 只負責驗證印章有效性",
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

# 初始化安全管理器
PRIVATE_KEY_PATH = os.getenv('PRIVATE_KEY_PATH', 'keys/private_key.pem')
security_manager = SecurityManager(private_key_path=PRIVATE_KEY_PATH)

# 驗證容差（可配置）
# MSE 容差：預設值 0.0001（更嚴格的驗證）
VERIFICATION_TOLERANCE_MSE = float(os.getenv('VERIFICATION_TOLERANCE_MSE', '0.0001'))
# 最大誤差容差：單一指紋值的最大允許誤差（預設 0.01，即 1%）
VERIFICATION_TOLERANCE_MAX = float(os.getenv('VERIFICATION_TOLERANCE_MAX', '0.01'))


# Pydantic 模型
class VerifyRequest(BaseModel):
    """驗證請求模型"""
    points: List[Tuple[float, float]] = Field(
        ...,
        description="5 個觸控點座標",
        min_items=5,
        max_items=5
    )


class VerifyResponse(BaseModel):
    """驗證回應模型"""
    status: str
    stamp_id: Optional[int] = None
    jwt_token: Optional[str] = None
    message: str


@app.get("/")
async def root():
    """健康檢查端點"""
    return {
        "service": "Smart Stamp Verification Server",
        "status": "running",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    """健康檢查"""
    return {"status": "healthy"}


@app.post("/api/v1/verify", response_model=VerifyResponse)
async def verify_stamp(
    request: VerifyRequest,
    x_api_key: str = Header(..., alias="X-API-Key", description="API Key"),
    http_request: Request = None,
    core_db: Session = Depends(get_core_db),
    business_db: Session = Depends(get_business_db)
):
    """
    驗證印章有效性
    
    流程：
    1. 驗證 API Key
    2. 將 5 點座標轉換為指紋
    3. 從資料庫查詢該客戶可用的印章指紋
    4. 比對指紋（MSE < tolerance）
    5. 若成功，簽發 JWT
    6. 記錄日誌
    """
    client_info = None
    matched_stamp = None
    error_message = None
    
    try:
        # 步驟 1: 驗證 API Key
        client_info = verify_api_key(x_api_key, core_db)
        if not client_info:
            raise HTTPException(
                status_code=403,
                detail="無效的 API Key"
            )
        
        # 步驟 2: 轉換為指紋
        try:
            fingerprint = get_normalized_fingerprint(request.points)
        except ValueError as e:
            raise HTTPException(
                status_code=400,
                detail=f"指紋計算失敗: {str(e)}"
            )
        
        # 步驟 3: 查詢該客戶可用的印章
        permissions = core_db.query(StampPermission).filter(
            StampPermission.client_id == client_info['client_id'],
            StampPermission.is_active == True
        ).all()
        
        if not permissions:
            error_message = "該客戶沒有可用的印章權限"
            raise HTTPException(
                status_code=403,
                detail=error_message
            )
        
        stamp_ids = [p.stamp_id for p in permissions]
        stamps = core_db.query(StampRegistry).filter(
            StampRegistry.id.in_(stamp_ids)
        ).all()
        
        # 步驟 4: 比對指紋
        best_match = None
        best_mse = float('inf')
        best_max_error = float('inf')
        
        for stamp in stamps:
            stored_fingerprint = stamp.fingerprint
            if not stored_fingerprint:
                continue
            
            mse = calculate_mse(fingerprint, stored_fingerprint)
            max_error = calculate_max_error(fingerprint, stored_fingerprint)
            
            # 同時考慮 MSE 和最大誤差
            if mse < best_mse:
                best_mse = mse
                best_max_error = max_error
                best_match = stamp
        
        # 步驟 5: 判斷是否匹配（必須同時滿足 MSE 和最大誤差條件）
        if best_match and best_mse < VERIFICATION_TOLERANCE_MSE and best_max_error < VERIFICATION_TOLERANCE_MAX:
            # 驗證成功：簽發 JWT
            jwt_token = security_manager.sign_jwt(
                stamp_id=best_match.id,
                status='valid'
            )
            
            # 記錄成功日誌
            log_entry = StampingLog(
                client_id=client_info['client_id'],
                stamp_id=best_match.id,
                status='valid',
                fingerprint=fingerprint,
                ip_address=http_request.client.host if http_request else None,
                user_agent=http_request.headers.get('user-agent') if http_request else None
            )
            business_db.add(log_entry)
            business_db.commit()
            
            return VerifyResponse(
                status="valid",
                stamp_id=best_match.id,
                jwt_token=jwt_token,
                message="印章驗證成功"
            )
        else:
            # 驗證失敗
            if best_match:
                error_message = f"指紋不匹配（MSE: {best_mse:.6f}, 最大誤差: {best_max_error:.6f}, MSE容差: {VERIFICATION_TOLERANCE_MSE}, 最大誤差容差: {VERIFICATION_TOLERANCE_MAX}）"
            else:
                error_message = "找不到匹配的印章"
            
            # 記錄失敗日誌
            log_entry = StampingLog(
                client_id=client_info['client_id'],
                stamp_id=None,
                status='invalid',
                fingerprint=fingerprint,
                error_message=error_message,
                ip_address=http_request.client.host if http_request else None,
                user_agent=http_request.headers.get('user-agent') if http_request else None
            )
            business_db.add(log_entry)
            business_db.commit()
            
            raise HTTPException(
                status_code=400,
                detail=error_message
            )
    
    except HTTPException:
        # 重新拋出 HTTP 異常
        raise
    
    except Exception as e:
        # 記錄錯誤日誌
        error_message = f"伺服器錯誤: {str(e)}"
        if client_info:
            log_entry = StampingLog(
                client_id=client_info['client_id'],
                stamp_id=None,
                status='error',
                error_message=error_message,
                ip_address=http_request.client.host if http_request else None,
                user_agent=http_request.headers.get('user-agent') if http_request else None
            )
            business_db.add(log_entry)
            business_db.commit()
        
        raise HTTPException(
            status_code=500,
            detail=error_message
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

