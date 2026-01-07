"""
資料庫連線配置
使用 verifier_app 帳號（只讀權限）
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
import os

# 資料庫配置
DATABASE_URL_CORE = os.getenv(
    'DATABASE_URL_CORE',
    'mysql+pymysql://verifier_app:verifier_pass@localhost/stamp_core_db?charset=utf8mb4'
)

DATABASE_URL_BUSINESS = os.getenv(
    'DATABASE_URL_BUSINESS',
    'mysql+pymysql://verifier_app:verifier_pass@localhost/app_business_db?charset=utf8mb4'
)

# 同步引擎（用於同步操作）
engine_core = create_engine(
    DATABASE_URL_CORE,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False
)

engine_business = create_engine(
    DATABASE_URL_BUSINESS,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False
)

# Session 工廠
SessionLocalCore = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine_core
)

SessionLocalBusiness = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine_business
)


def get_core_db():
    """取得核心資料庫 session（唯讀）"""
    db = SessionLocalCore()
    try:
        yield db
    finally:
        db.close()


def get_business_db():
    """取得業務資料庫 session（只寫）"""
    db = SessionLocalBusiness()
    try:
        yield db
    finally:
        db.close()

