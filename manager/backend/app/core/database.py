"""
資料庫連線配置（管理端使用 admin_dashboard 帳號，擁有完整 CRUD 權限）
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os

# 資料庫配置
DATABASE_URL = os.getenv(
    'DATABASE_URL',
    'mysql+pymysql://admin_dashboard:admin_pass@localhost/stamp_core_db?charset=utf8mb4'
)

# 建立引擎
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False
)

# Session 工廠
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


def get_db():
    """取得資料庫 session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

