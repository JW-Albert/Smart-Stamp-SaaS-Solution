"""
安全性模組：處理 JWT 簽章與 API Key 驗證
"""
import os
import secrets
from datetime import datetime, timedelta
from typing import Optional
import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend


class SecurityManager:
    """安全管理器：處理 JWT 簽章與驗證"""
    
    def __init__(self, private_key_path: Optional[str] = None):
        """
        初始化安全管理器
        
        Args:
            private_key_path: RS256 私鑰檔案路徑。如果未提供，會自動生成（僅用於開發）
        """
        if private_key_path and os.path.exists(private_key_path):
            # 從檔案載入私鑰
            with open(private_key_path, 'rb') as f:
                self.private_key = serialization.load_pem_private_key(
                    f.read(),
                    password=None,
                    backend=default_backend()
                )
        else:
            # 開發模式：自動生成私鑰（生產環境應使用預先生成的密鑰對）
            print("警告：使用自動生成的私鑰（僅用於開發）")
            self.private_key = rsa.generate_private_key(
                public_exponent=65537,
                key_size=2048,
                backend=default_backend()
            )
    
    def sign_jwt(self, stamp_id: int, status: str = 'valid', expires_in_minutes: int = 60) -> str:
        """
        使用 RS256 私鑰簽署 JWT
        
        Args:
            stamp_id: 印章 ID
            status: 驗證狀態（預設 'valid'）
            expires_in_minutes: JWT 過期時間（分鐘）
        
        Returns:
            簽署後的 JWT 字串
        """
        # 生成 nonce
        nonce = secrets.token_urlsafe(16)
        
        # 建立 payload
        now = datetime.utcnow()
        payload = {
            'stamp_id': stamp_id,
            'status': status,
            'nonce': nonce,
            'iat': now,
            'exp': now + timedelta(minutes=expires_in_minutes)
        }
        
        # 使用 RS256 簽署
        token = jwt.encode(
            payload,
            self.private_key,
            algorithm='RS256'
        )
        
        return token
    
    def get_public_key_pem(self) -> str:
        """
        取得公鑰的 PEM 格式（用於分發給客戶端驗證）
        
        Returns:
            公鑰的 PEM 字串
        """
        public_key = self.private_key.public_key()
        pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        return pem.decode('utf-8')


def verify_api_key(api_key: str, db_session) -> Optional[dict]:
    """
    驗證 API Key 並返回客戶資訊
    
    Args:
        api_key: API Key 字串
        db_session: 資料庫 session
    
    Returns:
        客戶資訊字典，如果無效則返回 None
    """
    from app.models import APIClient
    
    # 從資料庫查詢 API Key
    client = db_session.query(APIClient).filter(
        APIClient.api_key == api_key,
        APIClient.is_active == True
    ).first()
    
    if not client:
        return None
    
    return {
        'client_id': client.id,
        'client_name': client.name,
        'api_key': client.api_key
    }

